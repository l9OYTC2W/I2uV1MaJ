function [dir_cells, unappended_dirs] = cs_eliminate_bad_runs(dir_cells)
% Eliminate bad run directories. Uses relative path for directories w.r.t
% subject directory

appendString = cell(length(dir_cells), 1);
dirs = cell(length(dir_cells), 1);

for nDir = 1:length(dir_cells)
    inds = regexp(dir_cells{nDir}, ['\', filesep]);
    if ~isempty(inds)
        dirs{nDir} = dir_cells{nDir}(1:inds(1)-1);
        appendString{nDir} = dir_cells{nDir}(inds(1):end);
    else
        dirs{nDir} = dir_cells{nDir};
        appendString{nDir} = '';
    end
end

clear dir_cells;

% Find good runs
[dir_cells, dirs_included] = findGoodRuns(dirs, '(.+_V\d+_R\d+).*(_\d+)');
unappended_dirs = dir_cells;

appendString = appendString(dirs_included);

for nDir = 1:length(dir_cells)
    dir_cells{nDir} = fullfile(dir_cells{nDir}, appendString{nDir});
end



function [dirs, inds] = findGoodRuns(dirs, regExp_pattern)
% find good runs

[startInd, endInd, extents] = regexpi(dirs, regExp_pattern);

% Find good cells
inds = cs_good_cells(startInd);

if ~isempty(find(inds ~= 0))
    
    selDirs = dirs(inds);
    extents = extents(inds);
    
    dirNames = cell(length(selDirs), 1);
    run_num = zeros(length(selDirs), 1);
    % Get directory names and run numbers
    for nDir = 1:length(selDirs)
        extInd = extents{nDir}{1};
        dirNames{nDir} = selDirs{nDir}(extInd(1, 1):extInd(1, 2));        
        run_num(nDir) = str2num(selDirs{nDir}(extInd(2, 1)+1:extInd(2, 2)));
    end
    % End for getting directory names and run numbers
    
    unique_dirNames = unique(dirNames);
    
    for nU = 1:length(unique_dirNames)
        checkInd = strmatch(unique_dirNames{nU}, dirNames, 'exact'); 
        if length(checkInd) > 1
            [max_num, maxInd] = max(run_num(checkInd));
            inds(checkInd) = 0;
            inds(checkInd(maxInd)) = 1;
        end
    end
    
    % Good run directories
    dirs = dirs(inds);
    
else
    inds = ones(1, length(dirs));    
end

% Convert inds vector to logical
inds = (inds ~= 0);