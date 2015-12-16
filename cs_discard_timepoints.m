function cs_discard_timepoints( directory )
% Performs despiking on all images in a directory.

global csprefs;
global defaults;

orig_dir=pwd;
cd(directory);
progFile=fullfile(orig_dir,'cs_progress.txt');
cs_log( ['Beginning discard time points for ',directory], progFile );

% from DPARSFA_run.m written by YAN Chao-Gan
DirImg=dir('*.nii');
                
if length(DirImg)>1  %3D .nii images.
    for j = 1:csprefs.discard_timepoints
        delete(DirImg(j).name);
    end
end

cd(orig_dir);