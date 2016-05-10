function cs_discard_timepoints( directory, csprefs )
% Performs despiking on all images in a directory.

orig_dir=pwd;
cd(directory);
progFile=fullfile(orig_dir,'cs_progress.txt');
cs_log( ['Beginning discard time points for ',directory], progFile );

% from DPARSFA_run.m written by YAN Chao-Gan
DirImg=dir( csprefs.discard_pattern );

if csprefs.keep_original == 1
    cs_log( ['Saving original images for ',directory], progFile );
    dest = [csprefs.exp_dir filesep 'original' filesep directory];
    mkdir(dest);
    copyfile( [csprefs.discard_pattern], dest );
end;

if length(DirImg) > 1  %3D .nii images.
    for j = 1:csprefs.discard_timepoints
        delete(DirImg(j).name);
    end;
elseif length(DirImg) == 1 % 4D image?
    Nii = nifti(DirImg(1).name);
    data_ = Nii.dat(:,:,:,csprefs.discard_timepoints+1:end);
    dat = file_array;
    dat.fname = DirImg(1).name;
    dat.dim = size(data_);
    if isfield(Nii,'dt')
        dat.dtype = Nii.dt(1);
    else
        dat.dtype = Nii.dat.dtype;
    end;

    dat.offset  = ceil(348/8)*8;

    NIfTIObject = nifti;
    NIfTIObject.dat = dat;
    NIfTIObject.mat = Nii.mat;
    NIfTIObject.mat0 = Nii.mat;
    NIfTIObject.descrip = Nii.descrip;

    if (isfield(Nii,'private'))
        try
            NIfTIObject.mat_intent = Nii.private.mat_intent;
            NIfTIObject.mat0_intent = Nii.private.mat0_intent;
            NIfTIObject.timing = Nii.private.timing;
        catch
        end
    end
    
    create(NIfTIObject);
    dat(:,:,:,:) = data_;
else
    error('No files found for discarding.');
end;

cs_log( ['Discard time points completed for ',pwd] );

cd(orig_dir);