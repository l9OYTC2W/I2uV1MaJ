function cs_gui

spm_defaults;
global csprefs;

csprefs.gui=1;
addpath(pwd);
%addpath('/opt/local/spm2/');

jvm_status=version('-java');
if strcmp(jvm_status,'Java is not enabled')
    button=questdlg('Java is not enabled. CenterScripts emails will crash. Exit now?','No JVM','Yes','No','Yes');
    if strcmp(button,'Yes')
        exit;
    end
end

%prefs=spm_get(1,'*.m','Select prefs file');

prefs = spm_select(1, '^.*\.m$', 'Select prefs file');

[ppath pname] = fileparts(prefs);

addpath(ppath);

dirs = spm_select(Inf, 'dir', 'Select subject directories to process');

for i=1:size(dirs,1)
    cs_run_all(pname,deblank(dirs(i,:)));
end

rmfield(csprefs,'gui');