function postnorm_slicetiming_gui

global csprefs;

addpath(pwd);
addpath('/opt/local/spm2/');

%prefs=spm_get(1,'*.m','Select study''s original cs_prefs file');
prefs = spm_select(1, '^.*\.m$', 'Select study''s original cs_prefs file');
[ppath pname] = fileparts(prefs);
addpath(ppath);
eval(pname);

button='Select different prefs';
if isfield(csprefs,'slicetime_pattern')
    button=questdlg(['Use slicetiming prefs from ',pname,'?'],'Use existing prefs?','Use these prefs','Select different prefs','Use these prefs');
end

if strcmp(button, 'Select different prefs')
	%prefs=spm_get(1,'*.m','Select slicetiming prefs file');
    prefs = spm_select(1, '^.*\.m$', 'Select slicetiming prefs file');
	[ppath pname] = fileparts(prefs);
	addpath(ppath);
	eval(pname);
end

if ~exist(fullfile(csprefs.spm_defaults_dir,'spm_defaults.m'))
    error('spm_defaults.m file specified in csprefs.spm_defaults_dir not found');
end

%slice_img=spm_get(1,'*.img','Select slice template image');
slice_img = spm_select(1, 'Image', 'Select slice template image');
%dirs=spm_get(-Inf,'','Select subject directories to process');
dirs = spm_select(Inf, 'dir', 'Select subject directories to process');
[si_pth si_nm si_ext]=fileparts(slice_img);
slice_vol=spm_vol(slice_img);

csprefs.determine_params=0;
csprefs.write_normalized=1;
csprefs.writenorm_pattern=[si_nm si_ext];
csprefs.writenorm_matname='mean*_sn.mat';
csprefs.slicetime_nslices=slice_vol.dim(3);

owd=pwd;
for i=1:size(dirs,1)
    sub_dir=deblank(dirs(i,:));
    im_dirs=dir(sub_dir);
	inds=find([im_dirs(:).isdir]);
	im_dirs={im_dirs(inds).name};
	inds=regexp(im_dirs,csprefs.rundir_regexp);
	inds=cs_good_cells(inds);
	im_dirs={im_dirs{find(inds)}};
    
    cd(sub_dir);
    
    if ( isempty( im_dirs ) )
        error(['No scan directories found in ',sub_dir]);
    end

    for i=1:length(im_dirs)
        copyfile(slice_img,im_dirs{i});
        copyfile(fullfile(si_pth,[si_nm '.hdr']),im_dirs{i});
        cs_normalize( im_dirs{i} );
        delete(fullfile(im_dirs{i},[si_nm '.img']));
        delete(fullfile(im_dirs{i},[si_nm '.hdr']));
        wslice_img=cs_locate_files(fullfile(im_dirs{i},['w' si_nm '.img']));
        if size(wslice_img,1) ~= 1
            error('Found more than one normalized slice template image');
        end
        files=cs_locate_files(fullfile(im_dirs{i},csprefs.slicetime_pattern));
        for i=size(files,1):-1:1
            if strcmp(deblank(files(i,:)),wslice_img)
                files(i,:)=[];
            end
        end
        if isempty(files)
            error(['No files found for slicetiming in ',im_dirs{i}]);
        end
        
        if (~isfield(csprefs,'csprefs.slicetime_ta') || isempty(csprefs.csprefs.slicetime_ta))
            postnorm_slice_timing(files,wslice_img, csprefs.slicetime_nslices, csprefs.slicetime_refslice, csprefs.tr);
        else
            postnorm_slice_timing(files,wslice_img, csprefs.slicetime_nslices, csprefs.slicetime_refslice, csprefs.tr, csprefs.slicetime_ta);
        end
    end
end

cd(owd);