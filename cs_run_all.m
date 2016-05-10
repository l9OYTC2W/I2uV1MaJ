function cs_run_all( prefs_filename, sub_dir )
% Function to run pre-processing and stats steps
%
% Inputs:
% 1. prefs_filename: Name of the preference file. This must be added on Matlab
% path
% 2. sub_dir - fullfile path of the subject directory to be processed.
%

tic
global csprefs;
global FILE_USEREGEXP;
global defaults;

start_dir = pwd;

addpath(fileparts(which('cs_run_all.m')));

if ( strcmp(prefs_filename(end-1:end), '.m') )
    prefs_filename = prefs_filename(1:end-2);
end

eval( prefs_filename );

if (exist(fullfile(csprefs.spm_defaults_dir, 'spm_defaults.m'), 'file') ~= 2)
    error('spm_defaults.m file specified in csprefs.spm_defaults_dir not found');
end

% If file_useregexp field exists use regular expression for files
if isfield(csprefs, 'file_useregexp')
    FILE_USEREGEXP = csprefs.file_useregexp;
end

cd(sub_dir);

sub_dir = pwd;

% Original subject directory
origSubDir = sub_dir;

% Get subject directory name
[pp, subNum] = fileparts(pwd);

% Scan directory postpend
scandir_postpend = '';
if (isfield(csprefs, 'scandir_postpend')) && (~isempty(csprefs.scandir_postpend))
    scandir_postpend = csprefs.scandir_postpend;
end

% Run directory postpend
rundir_postpend = '';
if (isfield(csprefs, 'rundir_postpend')) && (~isempty(csprefs.rundir_postpend))
    rundir_postpend = csprefs.rundir_postpend;
end

% Get subject directories and run directories
[sub_dir, good_im_dirs] = get_sub_dirs(sub_dir, scandir_postpend, csprefs.rundir_regexp, rundir_postpend);

runDicom = 0;
if isfield(csprefs, 'run_dicom_convert')
    if (csprefs.run_dicom_convert == 1)
        runDicom = 1;
    end
    
    if runDicom
        if isfield(csprefs.dicom, 'outputDir') && (~isempty(csprefs.dicom.outputDir))
            dicomOutputDir = csprefs.dicom.outputDir;
        end
    end
end


% Dicom conversion
if runDicom
    % Loop over subject directories
    for nSub = 1:length(sub_dir)
        
        subject_directory = sub_dir{nSub};
        
        cd(subject_directory);
        
        tempPath = strrep(subject_directory, origSubDir, '');
        
        im_dirs = good_im_dirs(nSub).dir;
        
        im_dirs = cs_eliminate_bad_runs(im_dirs);
        
        % Loop over image directories
        for i = 1:length(im_dirs)
            if exist('dicomOutputDir', 'var')
                csprefs.dicom.outputDir = fullfile(dicomOutputDir, subNum, tempPath, im_dirs{i});
            end
            cs_dicom_convert(im_dirs{i});
        end
        % End loop over image directories
    end
    % End for loop over subject directories
end


% Option for running pre-processing steps after dicom conversion
if (runDicom == 1) && ((csprefs.run_beh_matchup == 1) || (csprefs.run_reorient == 1) || (csprefs.run_realign == 1) ...
        || (csprefs.run_coregister == 1) || (csprefs.run_slicetime == 1) || (csprefs.run_normalize == 1) || ...
        (csprefs.run_smooth == 1) || (csprefs.run_filter == 1) || (csprefs.run_stats == 1) || ...
        (csprefs.run_autoslice == 1) || (csprefs.run_deriv_boost == 1) || (csprefs.run_segment == 1))
    
    if exist('dicomOutputDir', 'var')
        if ~strcmp(origSubDir, dicomOutputDir)
            [sub_dir, good_im_dirs] = get_sub_dirs(fullfile(dicomOutputDir, subNum), scandir_postpend, csprefs.rundir_regexp, rundir_postpend);
        end
    end   
end

% start parallel pool with 8 workers
if isempty( gcp('nocreate') )
    parpool('local', 8);
end

% Loop over subject directories
for nSub = 1:length(sub_dir)
    
    subject_directory = sub_dir{nSub};
    
    cd(subject_directory);
    
    im_dirs = good_im_dirs(nSub).dir;
    
    % Find good runs
    im_dirs = cs_eliminate_bad_runs(im_dirs);
    
    if csprefs.run_beh_matchup
        cs_beh_matchup;
    end
    
    
    if csprefs.dummyscans > 0
        cs_dummies(subject_directory, im_dirs);
    end
    
    % Discard time points
    if isfield(csprefs, 'run_discard')
        if csprefs.run_discard
            parfor i = 1:length(im_dirs)
                cs_discard_timepoints(im_dirs{i}, csprefs);
            end
        end
    end
    
    % Rename
    if isfield(csprefs, 'run_rename')
        if csprefs.run_rename
            parfor i = 1:length(im_dirs)
                cs_rename(im_dirs{i}, csprefs);
            end
        end
    end
    
    % Reorientation
    if isfield(csprefs, 'run_reorient')
        if (csprefs.run_reorient)
            parfor i = 1:length(im_dirs)
                cs_reorient(im_dirs{i});
            end
        end
    end
    
    % Realign
    if csprefs.run_realign
        parfor i=1:length(im_dirs)
            cs_realign( im_dirs{i}, csprefs, defaults );
        end
    end
    
    % Slice time correction
    if isfield(csprefs,'run_slicetime') && csprefs.run_slicetime
        parfor i=1:length(im_dirs)
            cs_slicetime( im_dirs{i}, csprefs );
        end
    end
    
    % Coregister
    if isfield(csprefs, 'run_coregister') && csprefs.run_coregister
        for i = 1:length(im_dirs)
            cs_coregister(im_dirs{i});
        end
    end
    
    % Normalize
    if csprefs.run_normalize
        parfor i=1:length(im_dirs)
            cs_normalize( im_dirs{i}, csprefs, defaults );
        end
    end
    
    % Smoothing
    if csprefs.run_smooth
        parfor i=1:length(im_dirs)
            cs_smooth( im_dirs{i}, csprefs );
        end
    end
    
    % Detrending
    if csprefs.run_detrend
        parfor i=1:length(im_dirs)
            cs_detrend( im_dirs{i}, csprefs, defaults );
        end
    end
    
    % Filter
    if csprefs.run_filter
        parfor i=1:length(im_dirs)
            cs_filter( im_dirs{i}, csprefs );
        end
    end
    
    % Despike
    if csprefs.run_despike
        parfor i=1:length(im_dirs)
            cs_despike( im_dirs{i}, csprefs, defaults );
        end
    end
    
    % Stats
    if csprefs.run_stats
        cs_stats( im_dirs );
    end
    
    % Display Slices
    if isfield(csprefs,'run_autoslice') && csprefs.run_autoslice
        cs_autoslice;
    end
    
    % Derivative Boost
    if isfield(csprefs,'run_deriv_boost') && csprefs.run_deriv_boost
        cs_derivative_boost;
    end
    
    % Segment
    if isfield(csprefs, 'run_segment')
        if (csprefs.run_segment)
            for i=1:length(im_dirs)
                cs_segment( im_dirs{i} );
            end
        end
    end
    
    % Run SPM Results button
    if isfield(csprefs, 'run_spm_results') && csprefs.run_spm_results
        cs_spm_results;
    end
    
    folderize(sub_dir, im_dirs);
    
    cd(start_dir);
    cs_log(['CenterScripts ran successfully for ', subject_directory]);
    
end
% End loop over subject directories

cd(start_dir);

clear global FILE_USEREGEXP;
toc


function [sub_dir, good_im_dirs] = get_sub_dirs(sub_dir, subRegExpStr, sessRegExpStr, rundir_postpend)
% Get subject directories and the corresponding run directories

if ~isempty(subRegExpStr)
    % Sub-directories
    all_dirs = cs_list_dirs(sub_dir, 'fullpath');
    
    indices = regexp(all_dirs, subRegExpStr);
    indices = cs_good_cells(indices);
    all_dirs = all_dirs(indices);
    
    if isempty(all_dirs)
        error(['Cannot find sub-directories in directory ', sub_dir]);
    end
else
    all_dirs{1} = sub_dir;
end

% Loop over directories
checkDir = [];
good_im_dirs = repmat(struct('dir', {}), length(all_dirs), 1);
for nDir = 1:length(all_dirs)
    % Current directory
    currentDir = all_dirs{nDir};
    currentDirRegExp = convert_path_regexp(currentDir);
    % List run directories
    im_dirs = cs_list_dirs(currentDir, 'relative');
    
    if isempty(im_dirs)
        error(['Cannot find sub-directories in ', currentDir]);
    end
    
    % Match regular expression
    indices = regexp(im_dirs, sessRegExpStr);
    indices = cs_good_cells(indices);
    im_dirs = im_dirs(indices);
    if ~isempty(im_dirs)
        checkDir = [checkDir, nDir];
        % If run directory postpend exists
        if ~isempty(rundir_postpend)
            checkIm = [];
            for nIm = 1:length(im_dirs)
                currentIm = fullfile(currentDir, im_dirs{nIm});
                tempDirs = cs_recursive_subdir(currentIm);
                indices = regexp(tempDirs, rundir_postpend);
                indices = cs_good_cells(indices);
                tempDirs = tempDirs(indices);
                if ~isempty(tempDirs)
                    %tempDirs = tempDirs(1);
                    checkIm = [checkIm, nIm];
                    im_dirs(nIm) = {char(regexprep(tempDirs, currentDirRegExp, ''))};
                end
            end
            if ~isempty(checkIm)
                im_dirs = im_dirs(checkIm);
            end
        end
        % End for checking run directory postpend
        im_dirs = cellstr(char(im_dirs));
    end
    good_im_dirs(nDir).dir = im_dirs;
end
% End loop over directories


% Do error checking
sub_dir = all_dirs(checkDir);
good_im_dirs = good_im_dirs(checkDir);

if isempty(good_im_dirs)
    error('No scan directories found');
end

for nDir = 1:length(sub_dir)
    if isempty(good_im_dirs(nDir).dir)
        error('Error:ImageDirectories', ['No scan directories found for directory:\n %s'], sub_dir{nDir});
    end
end

% End for doing error checking


function regExpStr = convert_path_regexp(sub_dir)
% Convert full file path to regular expression

regExpStr = '';

if ~ispc
    % Separate subject directory into strings using file separator as delimiter
    myStr = strread(sub_dir, '%s', 'delimiter', filesep);
else
    myStr = strread(sub_dir, '%s', 'delimiter', '\\');
end


for nStr = 1:length(myStr)
    regExpStr = [regExpStr, myStr{nStr}, '\', filesep];
end

function folderize(sub_dir, im_dirs)

global csprefs;
global defaults;

% Realign
if csprefs.run_realign
    cs_log('Moving realigned images', 'cs_progress.txt');
    parfor i=1:length(im_dirs)
        dest = folderizeDestination(sub_dir, im_dirs{i}, csprefs, '1.realigned');
        mkdir(dest);
        movefile( [im_dirs{i} filesep defaults.realign.write.prefix csprefs.realign_pattern], dest );
        movefile( [im_dirs{i} filesep 'sq_rp_F*.txt'], dest );
        movefile( [im_dirs{i} filesep 'rp_F*.txt'], dest );
        movefile( [im_dirs{i} filesep 'meanF*'], dest );
    end
end

% Slice time correction
if csprefs.run_slicetime
    cs_log('Moving slice time corrected images', 'cs_progress.txt');
    parfor i=1:length(im_dirs)
        dest = folderizeDestination(sub_dir, im_dirs{i}, csprefs, '2.slicetimed');
        mkdir(dest);
        movefile( [im_dirs{i} filesep defaults.slicetiming.prefix csprefs.slicetime_pattern], dest );
    end
end

% Normalize
if csprefs.run_normalize
    cs_log('Moving normalized images', 'cs_progress.txt');
    parfor i=1:length(im_dirs)
        dest = folderizeDestination(sub_dir, im_dirs{i}, csprefs, '3.normalized');
        mkdir(dest);
        movefile( [im_dirs{i} filesep defaults.normalise.write.prefix csprefs.writenorm_pattern], dest );
    end
end

% Smoothing
if csprefs.run_smooth
    cs_log('Moving smoothed images', 'cs_progress.txt');
    parfor i=1:length(im_dirs)
        dest = folderizeDestination(sub_dir, im_dirs{i}, csprefs, '4.smoothed');
        mkdir(dest);
        movefile( [im_dirs{i} filesep defaults.smooth.prefix csprefs.smooth_pattern], dest );
    end
end

% Detrending
if csprefs.run_detrend
    cs_log('Moving detrended images', 'cs_progress.txt');
    parfor i=1:length(im_dirs)
        dest = folderizeDestination(sub_dir, im_dirs{i}, csprefs, '5.detrended');
        mkdir(dest);
        movefile( [im_dirs{i} filesep defaults.detrend.prefix strrep(csprefs.detrend_pattern, '*', im_dirs{i})], [im_dirs{i} filesep defaults.detrend.prefix strrep(csprefs.detrend_pattern, '*', 'fMRI')] );
        movefile( [im_dirs{i} filesep defaults.detrend.prefix strrep(csprefs.detrend_pattern, '*', 'fMRI')], dest );
    end
end

% Filter
if csprefs.run_filter
    cs_log('Moving filtered images', 'cs_progress.txt');
    parfor i=1:length(im_dirs)
        dest = folderizeDestination(sub_dir, im_dirs{i}, csprefs, '6.filtered');
        mkdir(dest);
        movefile( [im_dirs{i} filesep 'f' strrep(csprefs.filter_pattern, '*', im_dirs{i})], [im_dirs{i} filesep 'f' strrep(csprefs.filter_pattern, '*', 'fMRI')] );
        movefile( [im_dirs{i} filesep 'f' strrep(csprefs.filter_pattern, '*', 'fMRI')], dest );
    end
end

% Despike
if csprefs.run_despike
    cs_log('Moving despiked images', 'cs_progress.txt');
    parfor i=1:length(im_dirs)
        dest = folderizeDestination(sub_dir, im_dirs{i}, csprefs, '7.despiked');
        mkdir(dest);
        movefile( [im_dirs{i} filesep defaults.despike.prefix strrep(csprefs.despike_pattern, '*', im_dirs{i})], [im_dirs{i} filesep defaults.despike.prefix strrep(csprefs.despike_pattern, '*', 'fMRI')] );
        movefile( [im_dirs{i} filesep defaults.despike.prefix strrep(csprefs.despike_pattern, '*', 'fMRI')], dest );
    end
end

function str = folderizeDestination(sub_dir, im_dir, csprefs, step)
% % BSNIP
% str = strsplit(im_dir, '_');
% str = str(end);
% [t1 t2] = fileparts(sub_dir{1});
% str = [csprefs.exp_dir filesep step filesep t2 filesep str{1}];

% COBRE
str = [csprefs.exp_dir filesep step filesep im_dir];


