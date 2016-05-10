function cs_rename( directory, csprefs )
% custom rename routine

orig_dir=pwd;
cd(directory);
progFile=fullfile(orig_dir,'cs_progress.txt');
cs_log( ['Beginning cs_rename for ',directory], progFile );

% [status message] = system(['mmv ' pwd filesep 'S\*_00\*.nii ' pwd filesep 'S\#2.nii']);
% disp(message);

files_ = dir('*.nii');
% % BSNIP
% for j = 1:size(files_,1)
%     [t1 t2 t3] = fileparts(files_(j).name);
%     movefile([pwd filesep files_(j).name], [pwd filesep ['S' t2(end-2:end) '.nii']]);
% end;

% COBRE
for j = 1:size(files_,1)
    movefile([pwd filesep files_(j).name], [pwd filesep 'Fmri.nii']);
end;

cs_log( ['cs_rename completed for ',pwd] );

cd(orig_dir);