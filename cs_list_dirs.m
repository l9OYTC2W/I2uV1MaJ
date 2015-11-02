function subDirs = cs_list_dirs(inputDir, filePath)
% List sub directories
%
% Input:
% 1. inputDir - Input directory
% 2. filePath - filePath variable will return relative or fullpath
%
% Ouput:
% subDirs - Sub directories relative to the input directory.

if ~exist('inputDir', 'var')
    error(['Input directory is not specified for listing directories']);
end

if ~exist('filePath', 'var')
    filePath = 'relative';
end

% List files using dir function
d = dir(inputDir);

isDirs = ([d.isdir] == 1);

d = d(isDirs);

% exclude the current directory and its root directory
ind1 = strmatch('.', str2mat(d.name), 'exact');
ind2 = strmatch('..', str2mat(d.name), 'exact');

ind = [ind1 ind2];

CheckOne = ones(length(d), 1);

CheckOne(ind) = 0;

tempVec = find(CheckOne ~= 0);

if ~isempty(tempVec)

    subDirs = str2mat(d(tempVec).name);

    % filePath variable will return full path
    if ~strcmpi(filePath, 'relative')
        if ~strcmp(inputDir(end), filesep)
            inputDir = [inputDir, filesep];
        end

        % Return full path
        subDirs = strcat(inputDir, subDirs);
    end
    
    subDirs = cellstr(subDirs);

else

    subDirs = {};

end
