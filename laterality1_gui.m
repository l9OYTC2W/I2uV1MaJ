function laterality1_gui

global csprefs;

addpath(pwd);
addpath('/opt/local/spm2/');

% jvm_status=version('-java');
% if strcmp(jvm_status,'Java is not enabled')
%     button=questdlg('Java is not enabled. CenterScripts emails will crash. Exit now?','No JVM','Yes','No','Yes');
%     if strcmp(button,'Yes')
%         exit;
%     end
% end

%prefs=spm_get(1,'*.m','Select laterality1 prefs file');
prefs = spm_select(1, '^.*\.m$', 'Select laterality1 prefs file');
[ppath pname] = fileparts(prefs);
addpath(ppath);
eval(pname);

if ~exist(fullfile(csprefs.spm_defaults_dir,'spm_defaults.m'))
    error('spm_defaults.m file specified in csprefs.spm_defaults_dir not found');
end

%dirs=spm_get(-Inf,'','Select subject directories to process');
dirs = spm_select(Inf, 'dir', 'Select subject directories to process');

owd=pwd;
for i=1:size(dirs,1)
    sub_dir=deblank(dirs(i,:));
    im_dirs=dir(sub_dir);
	inds=find([im_dirs(:).isdir]);
	im_dirs={im_dirs(inds).name};
	inds=regexp(im_dirs,csprefs.rundir_regexp);
	inds=cs_good_cells(inds);
	im_dirs={im_dirs{find(inds)}};
    
    if ( isempty( im_dirs ) )
        error(['No scan directories found in ',sub_dir]);
    end
    
    cd(sub_dir);
    if csprefs.run_mean_image
        cs_mean_image;
    end
    
    if csprefs.run_normalize
        cs_normalize(sub_dir);
    end
end

cd(owd);