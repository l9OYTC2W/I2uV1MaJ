function cs_normalize( directory )
% Performs spatial normalization on all images in a directory.

global csprefs;

defaults = spm_get_defaults;

spm_jobman('initcfg');

orig_dir = pwd;
cd (directory);
progFile = fullfile(orig_dir, 'cs_progress.txt');
cs_log( ['Beginning cs_normalize for ', pwd], progFile );

% Check if the template file is on Matlab path or not
if exist(csprefs.params_template, 'file') ~= 2
    error(['Template image: ', csprefs.params_template ' for parameter estimation doesn''t exist']);
end

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


%% Load normalization job MAT file
csPath = fileparts(which('cs_gui.m'));
load(fullfile(csPath, 'cs_normalize'));

if (~exist('matlabbatch', 'var'))
    error('Normalization batch file cs_normalize.mat does not exist');
end

if (csprefs.determine_params)
    %% Get params
    VG = csprefs.params_template;
    VF = cs_list_files(pwd, csprefs.params_pattern, 'fullpath');
    if (size(VF, 1) ~= 1 )
        error( 'Incorrect # of files specified by csprefs.params_pattern' );
    end
    [path, filename] = fileparts(VF);
    
    %% Set source and tpm
    est = matlabbatch{1}.spm.spatial.normalise.estwrite;
    est.subj.vol = {VF};
    est.subj.resample = {VF};
    est.eoptions.tpm = {VG};
    % est = rmfield(est, 'woptions');
    % matlabbatch{1}.spm.spatial.normalise = rmfield(matlabbatch{1}.spm.spatial.normalise, 'estwrite');
    matlabbatch{1}.spm.spatial.normalise.estwrite = est;
    
    %% Run normalization
    spm_jobman('run', matlabbatch);
    
    % Deformation fields file
    def_file = spm_file(char(matlabbatch{1}.spm.spatial.normalise.estwrite.subj.vol), 'prefix','y_', 'ext','.nii');
    
    spm_figure('clear','Graphics');
    
    %% Print postscript and Jpeg files
    normFiles = cs_rename_4d_nifti(VF);
    [pth, nam, extn] = fileparts(deblank(normFiles(1,:)));
    filesToChkReg = char(VG, fullfile(pth, ['w', nam, extn]));
    spm_check_registration(filesToChkReg);
    cs_spm_print([subNumber, '_normalization_', runN{1}, '.ps']);
    cs_spm_print([subNumber, '_normalization_', runN{1}, '.jpg']);
    
    cs_log( ['spm_normalise completed for ', pwd], progFile );
    cs_log( ['    VG = ', VG ], progFile, 1 );
    cs_log( ['    VF = ', VF ], progFile, 1 );
    
end

if (csprefs.write_normalized)
    
    load(fullfile(csPath, 'cs_normalize'));
    
    %% Get files to be normalized
    V = cs_list_files(pwd, csprefs.writenorm_pattern, 'fullpath');
    if (isempty(V))
        error('No files found for normalization.');
    end
    
    if (~csprefs.determine_params)
        def_file = cs_list_files(pwd, csprefs.writenorm_defname, 'fullpath');
        if (isempty(def_file))
            error( 'Enter deformation fields file in csprefs.writenorm_defname' );
        end
    end
    
    %% Setup batch structure
    matlabbatch{1}.spm.spatial.normalise.estwrite.subj.resample = {V};
    writeF = matlabbatch{1}.spm.spatial.normalise.estwrite;
    writeF = rmfield(writeF, 'eoptions');
    writeF.subj = rmfield(writeF.subj, 'vol');
    writeF.subj.def = {def_file};
    matlabbatch{1}.spm.spatial.normalise = rmfield(matlabbatch{1}.spm.spatial.normalise, 'estwrite');
    matlabbatch{1}.spm.spatial.normalise.write = writeF;
    
    %% Set defaults
    try
        matlabbatch{1}.spm.spatial.normalise.write.woptions.bb = defaults.normalise.write.bb;
    catch
    end
    
    try
        matlabbatch{1}.spm.spatial.normalise.write.woptions.vox = defaults.normalise.write.vox;
    catch
    end
    
    try
        matlabbatch{1}.spm.spatial.normalise.write.woptions.interp = defaults.normalise.write.interp;
    catch
    end
    
    %% Write normalized files
    spm_jobman('run', matlabbatch);
    
    cs_log( ['spm_write_sn completed for ', pwd], progFile);
    cs_log( ['    deformations file = ', def_file ], progFile, 1 );
    cs_log( ['    flags.bb = ', mat2str(defaults.normalise.write.bb) ], progFile, 1 );
    cs_log( ['    flags.vox = ', mat2str(defaults.normalise.write.vox) ], progFile, 1 );
    cs_log( ['    flags.interp = ', num2str(defaults.normalise.write.interp) ], progFile, 1 );
    
end


cd(orig_dir);