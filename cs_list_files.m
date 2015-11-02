function files = cs_list_files(inputDir, filePattern, optional)
%% List files using the file pattern
%
% Input:
% 1. inputDir - Input directory
% 2. filePattern - File pattern
% 3. optional - Optional variable returns relative or full file path
%
% Ouput:
% files - files with the specified file pattern


% Use regular expression for files
global FILE_USEREGEXP;

files = '';

if ~exist('inputDir', 'var')
    error('Input directory is not specified for listing file pattern');
end

if ~exist('filePattern', 'var')
    filePattern = '*';
end

if ~exist('optional', 'var')
    optional = 'relative';
end

%% Don't use regular expression if empty
if isempty(FILE_USEREGEXP)
    FILE_USEREGEXP = 0;
end

%% Change directory to get inputdirectory name
oldDir = pwd;

cd(inputDir);

%% Handle nested file pattern
if (~FILE_USEREGEXP)
    [rel_dir, filePattern, extn] = fileparts(filePattern);
    filePattern = [filePattern, extn];
    if (~isempty(rel_dir))
        cd(rel_dir);
    end
end

inputDir = pwd;

cd(oldDir);
% End for changing directory

% List files using dir function
if ~FILE_USEREGEXP
    d = dir(fullfile(inputDir, filePattern));
else
    d = dir(inputDir);
end

isDirs = [d.isdir];

checkIndices = find(isDirs ~= 1);

if ~isempty(checkIndices)

    files = str2mat(d(checkIndices).name);

    if FILE_USEREGEXP
        % Use regular expression
        files = cellstr(str2mat(d(checkIndices).name));
        if ~ispc
            inds = regexp(files, filePattern);
        else
            inds = regexpi(files, filePattern);
        end
        inds = cs_good_cells(inds);
        if ~isempty(find(inds))
            files = str2mat(files(inds));
        else
            clear files;
            files = '';
            return;
        end
    end

    if ~strcmpi(optional, 'relative')

        if ~strcmp(inputDir(end), filesep)
            inputDir = [inputDir, filesep];
        end

        % Return full file path
        files = strcat(inputDir, files);

    end

end
