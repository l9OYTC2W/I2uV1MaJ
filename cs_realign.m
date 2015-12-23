function cs_realign( directory, csprefs, defaults )

orig_dir=pwd;
cd(directory);

files = cs_list_files(pwd, csprefs.realign_pattern, 'fullpath');

if (isempty(files))
    error('No files found for realignment.');
end

% Fix 4D Nifti data if possible
cs_fix_data(files);

progFile=fullfile(orig_dir,'cs_progress.txt');
cs_log( ['Beginning cs_realign for ',pwd], progFile );

if ispc
    delimiter = ['\', filesep];
else
    delimiter = filesep;
end

subN = strread(orig_dir, '%s', 'delimiter', delimiter);
runN = strread(directory, '%s', 'delimiter', delimiter);

if length(subN) > 1
    subNumber = subN{end-1};
else
    subNumber = subN{end};
end

realignment_txtFile = [spm_str_manip(prepend(deblank(files(1, :)),'rp_'),'s') '.txt'];
sq_realignment_txtFile = [spm_str_manip(prepend(deblank(files(1, :)),'sq_rp_'),'s') '.txt'];

if (csprefs.coregister)
    flags_coreg.fwhm            = csprefs.realign_fwhm;
    if(csprefs.realign_rtm)
        flags_coreg.rtm         = csprefs.realign_rtm;
    end
    if (~strcmp(csprefs.realign_pw,''))
        flags_coreg.PW              = csprefs.realign_pw;
    end
    
    if (csprefs.use_inrialign)
        flags_coreg.rho_func    = csprefs.inrialign_rho;
        flags_coreg.cutoff      = csprefs.inrialign_cutoff;
        flags_coreg.quality     = csprefs.inrialign_quality;
        
        % Rename 4D nifti files to contain numbers at the end of the file
        files = cs_rename_4d_nifti(files);
        
        inria_realign( files, flags_coreg );
        
        % Print postscript and Jpeg files
        cs_spm_print([subNumber, '_realignment_', runN{1}, '.ps']);
        cs_spm_print([subNumber, '_realignment_', runN{1}, '.jpg']);
        
        cs_log( ['INRIAlign completed for ',pwd],                                               progFile );
        cs_log( ['    flags_coreg.fwhm = ', num2str(flags_coreg.fwhm)],                         progFile, 1 );
        cs_log( ['    flags_coreg.rtm exists? = ', num2str(exist('flags_coreg.rtm')) ],         progFile, 1 );
        cs_log( ['    flags_coreg.PW  exists? = ', num2str(exist('flags_coreg.PW'))  ],         progFile, 1 );
        cs_log( ['    flags_coreg.rho_func = ', flags_coreg.rho_func ],                         progFile, 1 );
        cs_log( ['    flags_coreg.cutoff = ', num2str(flags_coreg.cutoff) ],                    progFile, 1 );
        cs_log( ['    flags_coreg.quality = ', num2str(flags_coreg.quality) ],                  progFile, 1 );
        
    else
        flags_coreg.quality     = defaults.realign.estimate.quality;
        flags_coreg.interp      = defaults.realign.estimate.interp;
        
        spm_realign( files, flags_coreg );
        
        % Print postscript and Jpeg files
        cs_spm_print([subNumber, '_realignment_', runN{1}, '.ps']);
        cs_spm_print([subNumber, '_realignment_', runN{1}, '.jpg']);
        
        cs_log( ['spm_realign completed for ',pwd],                                             progFile );
        cs_log( ['    flags_coreg.fwhm = ', num2str(flags_coreg.fwhm)],                         progFile, 1 );
        cs_log( ['    flags_coreg.rtm exists? = ', num2str(exist('flags_coreg.rtm')) ],         progFile, 1 );
        cs_log( ['    flags_coreg.PW  exists? = ', num2str(exist('flags_coreg.PW'))  ],         progFile, 1 );
        cs_log( ['    flags_coreg.quality = ', num2str(flags_coreg.quality) ],                  progFile, 1 );
        cs_log( ['    flags_coreg.interp = ', num2str(flags_coreg.interp) ],                    progFile, 1 );
    end
    
    re_params = load(realignment_txtFile);
    
    sq_params = re_params.^2;
    
    save(sq_realignment_txtFile, 'sq_params', '-ascii');
end


if (csprefs.reslice)
    flags_reslice.which         = csprefs.reslice_write_imgs;
    flags_reslice.mean          = csprefs.reslice_write_mean;
    flags_reslice.mask          = defaults.realign.write.mask;
    flags_reslice.interp        = defaults.realign.write.interp;
    flags_reslice.wrap          = defaults.realign.write.wrap;
    
    spm_reslice( files, flags_reslice );
    
    cs_log( ['spm_reslice completed for ',pwd],                                                 progFile );
    cs_log( ['    flags_reslice.which = ', num2str(flags_reslice.which) ],                      progFile, 1 );
    cs_log( ['    flags_reslice.mean = ', num2str(flags_reslice.mean) ],                        progFile, 1 );
    cs_log( ['    flags_reslice.mask = ', num2str(flags_reslice.mask) ],                        progFile, 1 );
    cs_log( ['    flags_reslice.interp = ', num2str(flags_reslice.interp) ],                    progFile, 1 );
    cs_log( ['    flags_reslice.wrap = ', mat2str(flags_reslice.wrap) ],                        progFile, 1 );
end

cd(orig_dir);


%_______________________________________________________________________
function PO = prepend(PI,pre)
[pth,nm,xt] = fileparts(deblank(PI));
PO             = fullfile(pth,[pre nm xt]);
return;
%_______________________________________________________________________