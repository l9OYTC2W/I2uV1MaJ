function cs_rename( directory, csprefs )
% custom rename routine

orig_dir=pwd;
cd(directory);
progFile=fullfile(orig_dir,'cs_progress.txt');
cs_log( ['Beginning cs_rename for ',directory], progFile );

[status message] = system(['mmv ' pwd filesep 'S\*_00\*.nii ' pwd filesep 'S\#2.nii']);
disp(message);
cs_log( ['cs_rename completed for ',pwd] );

cd(orig_dir);