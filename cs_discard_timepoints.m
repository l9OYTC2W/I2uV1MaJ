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
end

if length(DirImg)>1  %3D .nii images.
    for j = 1:csprefs.discard_timepoints
        delete(DirImg(j).name);
    end
end

cs_log( ['Discard time points completed for ',pwd] );

cd(orig_dir);