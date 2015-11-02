function laterality2_gui

global csprefs;
global defaults;

addpath(pwd);
addpath('/opt/local/spm2/');

% jvm_status=version('-java');
% if strcmp(jvm_status,'Java is not enabled')
%     button=questdlg('Java is not enabled. CenterScripts emails will crash. Exit now?','No JVM','Yes','No','Yes');
%     if strcmp(button,'Yes')
%         exit;
%     end
% end

%prefs=spm_get(1,'*.m','Select laterality2 prefs file');
prefs = spm_select(1, '^.*\.m$', 'Select laterality2 prefs file');
[ppath pname] = fileparts(prefs);
addpath(ppath);
eval(pname);

if ~exist(fullfile(csprefs.spm_defaults_dir,'spm_defaults.m'))
    error('spm_defaults.m file specified in csprefs.spm_defaults_dir not found');
end

if ~defaults.analyze.flip
    error(sprintf('Your spm defaults.analyze.flip value is set to 0.\nThis error message is to ensure that your data really are in neurological format.\nIf this is true, you will have to edit laterality2_gui.m and make it compatible with neurological format data.'));
end

if isempty(csprefs.lat2_diff_prefix)
    error('csprefs.lat2_diff_prefix is empty');
end

if isempty(csprefs.lat2_Lact_prefix)
    error('csprefs.lat2_Lact_prefix is empty');
end

if isempty(csprefs.lat2_Ract_prefix)
    error('csprefs.lat2_Ract_prefix is empty');
end

%dirs=spm_get(-Inf,'','Select subject directories to process');
dirs = spm_select(Inf, 'dir', 'Select subject directories to process');

owd=pwd;
for i=1:size(csprefs.lat2_images,1)
    img=csprefs.lat2_images{i};
    for j=1:size(dirs,1)
        cd(deblank(dirs(j,:)));
        sub_img=cs_locate_files(img,1,1);
        v=spm_vol(sub_img);
        d=spm_read_vols(v);
        xdim=size(d,1);
        half=floor(xdim/2);
        Rdata=d(1:half,:,:);%assumes flipped
        Ldata=d(end:-1:end-half+1,:,:);%assumes flipped
        
        %create difference image
        d=zeros(size(d));
        d(1:half,:,:)=Rdata-Ldata;%assumes flipped
        d(end:-1:end-half+1,:,:)=Ldata-Rdata;%assumes flipped
        [pth nm ext]=fileparts(sub_img);
        v=rmfield(v,'private');
        v=rmfield(v,'descrip');
        v.fname=fullfile(pth,[csprefs.lat2_diff_prefix nm ext]);
        spm_write_vol(v,d);
        
        %create left image (L activation on L, L activation mirrored on R)
        d=zeros(size(d));
        d(1:half,:,:)=Ldata;
        d(end:-1:end-half+1,:,:)=Ldata;
        v.fname=fullfile(pth,[csprefs.lat2_Lact_prefix nm ext]);
        spm_write_vol(v,d);
        
        %create right image (R activation on R, R activation mirrored on L)
        d=zeros(size(d));
        d(1:half,:,:)=Rdata;
        d(end:-1:end-half+1,:,:)=Rdata;
        v.fname=fullfile(pth,[csprefs.lat2_Ract_prefix nm ext]);
        spm_write_vol(v,d);
        
        if j==1
            Ltot=Ldata;
            Rtot=Rdata;
        else
            Ltot=Ltot+Ldata;
            Rtot=Rtot+Rdata;
        end
    end
    
    Lmean=Ltot/j;
    Rmean=Rtot/j;
    
    Lmask=zeros(size(d));
    Rmask=zeros(size(d));
    Lmask(1:half,:,:)=Lmean;
    Lmask(end:-1:end-half+1,:,:)=Lmean;
    Rmask(1:half,:,:)=Rmean;
    Rmask(end:-1:end-half+1,:,:)=Rmean;
    
    cd(csprefs.exp_dir);
    mkdir(csprefs.lat2_mask_dir);
    cd(csprefs.lat2_mask_dir);
    
    d=zeros(size(d));
    d(1:half,:,:)=Rmean;%assumes flipped
    d(end:-1:end-half+1,:,:)=Lmean;%assumes flipped
    v.fname=fullfile(pwd,[csprefs.lat2_mask_prefix 'mean_' nm ext]);
    spm_write_vol(v,d);
    
    v.fname=fullfile(pwd,[csprefs.lat2_mask_prefix 'mask_Lp_Rp_' nm ext]);
    spm_write_vol(v,(Lmask>0)&(Rmask>0));
    
    v.fname=fullfile(pwd,[csprefs.lat2_mask_prefix 'mask_Lp_Rn_' nm ext]);
    spm_write_vol(v,(Lmask>0)&(Rmask<0));
    
    v.fname=fullfile(pwd,[csprefs.lat2_mask_prefix 'mask_Ln_Rp_' nm ext]);
    spm_write_vol(v,(Lmask<0)&(Rmask>0));
    
    v.fname=fullfile(pwd,[csprefs.lat2_mask_prefix 'mask_Ln_Rn_' nm ext]);
    spm_write_vol(v,(Lmask<0)&(Rmask<0));
end
    
cd(owd);