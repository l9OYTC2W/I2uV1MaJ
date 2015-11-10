function cs_run_sub(prefs_files)
% Run center scripts on subjects
%
% Input:
% prefs_files - cell array of preference file names
%

% Get the spm file location
spm5File = which('spm.m');

if exist(spm5File, 'file') ~= 2
    error('SPM doesn''t exist on the Matlab path');
end

% Get the SPM version
spmVersion = spm('ver');

if ~strcmpi(spmVersion, 'spm5')
%     error(['This version of center scripts works only with spm5']);
end

if ~exist('prefs_files', 'var')
    error(['Preferences file/files is/are not specified']);
end

if ~iscell(prefs_files)
    prefs_files = cellstr(prefs_files);
end

% Loop over preference files
for ii = 1:length(prefs_files)

    [pp, prefs_filename] = fileparts(prefs_files{ii});

    try
        eval([prefs_filename, '(0)']); % Don't initialize Graphics
    catch
        eval([prefs_filename]);
    end

    global csprefs;

    sub_dir = csprefs.exp_dir; % Experimental directory

    %allDirs = dir(sub_dir); % all directories

    %inds = find([allDirs.isdir] == 1);

    %subDirs = cellstr(str2mat(allDirs(inds).name));
    
    subDirs = cs_list_dirs(sub_dir, 'relative');    
    
    if ~isempty(subDirs)
        [inds] = regexp(subDirs, csprefs.scandir_regexp);           
        inds = cs_good_cells(inds); % find the dirs matching the regular expression        
        subDirs = {subDirs{find(inds)}};
    end

    if isempty(subDirs)
        error(['Cannot find subject directories in directory ', sub_dir]);
    end

    % Run cs_run_all script
    for nn = 1:length(subDirs)
        subDirs{nn} = fullfile(sub_dir, subDirs{nn});
        cs_run_all(prefs_filename, subDirs{nn});
        drawnow;
    end
    clear global csprefs;
    clear global defaults;
    clear subDirs;

end
% End loop over preference files