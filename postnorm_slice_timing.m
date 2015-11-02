function postnorm_slice_timing(P, sliceimg_fname, nslices_orig, refslice, TR, TA)
% Heavily based on spm_slice_timing; see that for most details.
% This should only work on sequentially acquired data, so taking out the sliceorder parameter.
% However, adding nslices_orig b/c we can't be sure how many slices the original data had.
% Also replacing 'timing' parameter with TR and TA since that is more user-friendly (TA will be optional).

if nargin < 5,
    %Forget this GUI business. It's all parameters now. --MRJ
    error('postnorm_slice_timing: Not enough arguments!');
end;

if iscell(P),
	nsubjects = length(P);
else,
	nsubjects = 1;
	P = {P};
end;

Vin 	= spm_vol(P{1}(1,:));
%Since normalized images are resliced, nslices variable has been split into nslices_now and nslices_orig --MRJ
nslices_now	= Vin(1).dim(3);

if nargin<6
	TA = TR-TR/nslices_orig;
end

timing(2) = TR - TA;
timing(1) = TA / (nslices_orig -1);
factor = timing(1)/TR;

spm('Pointer','Watch')

%Read in data from slice template image --MRJ
sliceimg_data=spm_read_vols(spm_vol(sliceimg_fname));

for subj = 1:nsubjects
    task = ['Slice timing: working on session ' num2str(subj)];
    PP      = P{subj};
    Vin 	= spm_vol(PP);
    nimgo	= size(PP,1);
    nimg	= 2^(floor(log2(nimgo))+1);
    
    % create new header files
    Vout 	= Vin;
    for k=1:nimgo,
        [pth,nm,xt] = fileparts(deblank(Vin(k).fname));
        Vout(k).fname  = fullfile(pth,['b' nm xt]);
        %changing appended letter from 'a' to 'b', just to tell this apart from the original slicetiming --MRJ
        if isfield(Vout(k),'descrip'),
            desc = [Vout(k).descrip ' '];
        else,
            desc = '';
        end;
        Vout(k).descrip = [desc 'acq-fix ref-slice ' int2str(refslice)];
    end;
    Vout = spm_create_vol(Vout,'noopen');
    
    % Set up large matrix for holding image info
    % Organization is time by voxels
    slices = zeros([Vout(1).dim(1:2) nimgo]);
    stack  = zeros([nimg Vout(1).dim(1)]);
    
    spm('CreateIntWin');
    spm_progress_bar('Init',nslices_now,'Correcting acquisition delay','planes complete');
    
    % For loop to read data slice by slice do correction and write out
    % In analzye format, the first slice in is the first one in the volume.
    
    % Loop through POST-normalization slices to do processing --MRJ
    for k = 1:nslices_now,
        
        % Set up time acquired within slice order
        %shiftamount WAS scalar, going to have to make it a matrix now --MRJ
        vox_slices = sliceimg_data(:,:,k);  %get a slice of "original slice order" data from slice template image --MRJ
        vox_slices(vox_slices==0)=refslice; %e.g., no shift for voxels that weren't in original image --MRJ
        shiftamount  = (vox_slices - refslice) * factor;
        
        % Read in slice data
        B  = spm_matrix([0 0 k]);
        for m=1:nimgo,
            slices(:,:,m) = spm_slice_vol(Vin(m),B,Vin(1).dim(1:2),1);
        end;
        
        % set up shifting variables
        len     = size(stack,1);
        %new phi... IN 3-D!!! --MRJ
        %so before phi was size [1 len]... now it is size [len x y] where x and y are slice dimensions --MRJ
        phi     = zeros(len,size(shiftamount,1),size(shiftamount,2));
        
        % Check if signal is odd or even -- impacts how Phi is reflected
        %  across the Nyquist frequency. Opposite to use in pvwave.
        OffSet  = 0;
        if rem(len,2) ~= 0, OffSet = 1; end;
        
        % Phi represents a range of phases up to the Nyquist frequency
        % Shifted phi 1 to right.
        
        %This loop just changed to reflect new dimensionality of phi --MRJ
        for f = 1:len/2,
            phi(f+1,:,:) = -1*shiftamount*2*pi/(len/f);
        end;
        
        % Mirror phi about the center
        % 1 is added on both sides to reflect Matlab's 1 based indices
        % Offset is opposite to program in pvwave again because indices are 1 based
        
        %This used to be just one line; now loops through the various dimensions of phi --MRJ
        %fliplr in old line becomes flipud because phi values are column-oriented now, not row-oriented --MRJ
        for ctr1=1:size(phi,2)
            for ctr2=1:size(phi,3)
                phi(len/2+1+1-OffSet:len,ctr1,ctr2) = -flipud(phi(1+1:len/2+OffSet,ctr1,ctr2));
            end
        end
        
        % Transform phi to the frequency domain and take the complex transpose
        bigshifter = [cos(phi) + sin(phi)*sqrt(-1)];          %don't need to take complex transpose since we re-ordered and added dimensions --MRJ
        %shifter = shifter(:,ones(size(stack,2),1)); % Tony's trick         Don't need anymore; shifter is already multi-D. --MRJ
        
        % Loop over columns
        for i=1:Vout(1).dim(2),
            shifter=bigshifter(:,:,i); %just have to add this to change shifter for each set of voxels --MRJ
            % no algorithm changes beyond this point --MRJ
            
            % Extract columns from slices
            stack(1:nimgo,:) = reshape(slices(:,i,:),[Vout(1).dim(1) nimgo])';
            
            % fill in continous function to avoid edge effects
            for g=1:size(stack,2),
                stack(nimgo+1:end,g) = linspace(stack(nimgo,g),...
                    stack(1,g),nimg-nimgo)';
            end;
            
            % shift the columns
            stack = real(ifft(fft(stack,[],1).*shifter,[],1));
            
            % Re-insert shifted columns
            slices(:,i,:) = reshape(stack(1:nimgo,:)',[Vout(1).dim(1) 1 nimgo]);
        end;
        
        % write out the slice for all volumes
        for p = 1:nimgo,
            Vout(p) = spm_write_plane(Vout(p),slices(:,:,p),k);
        end;
        spm_progress_bar('Set',k);
    end;
    spm_progress_bar('Clear');
    Vout = spm_close_vol(Vout);
end

spm('Pointer');
return;
