function cs_filter( directory, csprefs )

%Adapted from filter_Images by Adrien Desjardins

progFile=fullfile(pwd,'cs_progress.txt');
cs_log( ['Beginning cs_filter for ',fullfile(pwd,directory)], progFile );

if isempty(which('butter.m'))
    error('Need signal processing toolbox to do filtering');
end

if csprefs.cutoff_freq_low
    [bfilter_high, afilter_high]=butter(5,csprefs.cutoff_freq_low/((1/csprefs.tr)/2));
end
if csprefs.cutoff_freq_high
    [bfilter_low, afilter_low]=butter(5,csprefs.cutoff_freq_high/((1/csprefs.tr)/2));
end

files = cs_list_files(fullfile(pwd, directory), csprefs.filter_pattern, 'fullpath');

if (isempty(files))
    error('No files found for filtering.');
end

%numfiles=size(files,1);

vol=spm_vol(files);
numfiles = length(vol);
handles = spm('CreateIntWin');
set(handles, 'visible', 'on');
spm_progress_bar('Init',vol(1).dim(3),'Filtering images','Slices completed');

data=zeros(vol(1).dim(1),vol(1).dim(2),numfiles);

%%% Initialising whole brain data
newData = zeros(vol(1).dim(1),vol(1).dim(2), vol(1).dim(3), numfiles);

for slice = 1:(vol(1).dim(3))
    %read slice by slice
    for i = 1:numfiles
        data(:,:,i) = spm_slice_vol(vol(i),spm_matrix([0 0 slice]),vol(i).dim(1:2),0);
    end

    %%%%% do filtering here
    for x=1:(vol(1).dim(1))
        for y=1:(vol(1).dim(2))
            if csprefs.cutoff_freq_low
                data(x,y,:)=filtfilt(bfilter_high,afilter_high,data(x,y,:));
            end
            if csprefs.cutoff_freq_high
                data(x,y,:)=filtfilt(bfilter_low,afilter_low,data(x,y,:));
            end
        end
    end

    newData(:, :, slice, :) = data;

    spm_progress_bar('Set',slice);
end

warning off all;
%% Writing filtered images
for i=1:numfiles
    %vol(i).fname = prepend(vol(i).fname,'f');
    newVol = vol(i);
    newVol.fname = prepend(newVol.fname, 'f');
    spm_write_vol(newVol, squeeze(newData(:, :, :, i)));
end

warning on;

spm_progress_bar('Clear');

cs_log( ['cs_filter completed for ',fullfile(pwd,directory)],                           progFile );

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% THE FOLLOWING ARE BLATANTLY "ADAPTED" (STOLEN) FROM SPM_WRITE_SN     %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function VO = make_hdr_struct(V)
VO          = V;
VO.fname    = prepend(V.fname,'f');
VO.descrip  = ['filtered with love by cs_filter'];
return;

%_______________________________________________________________________
function PO = prepend(PI,pre)
[pth,nm,xt] = fileparts(deblank(PI));
PO             = fullfile(pth,[pre nm xt]);
return;