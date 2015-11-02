function cs_spm_results
%% Batch script for SPM Results button
%

%% Load defaults
global csprefs;

% Old directory
sub_dir = pwd;
progFile = fullfile(sub_dir, 'cs_progress.txt');
cs_log(['Beginning cs_spm_results for ', sub_dir], progFile);

if ~isempty(csprefs.spm_results.stats_dir_name)
    try
        cd(csprefs.spm_results.stats_dir_name);
    catch
        error('Error:cs_spm_results_err', 'No stats directory present');
    end
end

stats_dir_name = pwd;

%% SPM Mat file name
spmMatFileName = fullfile(stats_dir_name, 'SPM.mat');

%% Output directory
spmResultsDir = csprefs.spm_results.output_dir;
if ~isempty(spmResultsDir)
    if (~exist(spmResultsDir, 'dir'))
        mkdir(spmResultsDir);
    end
else
    spmResultsDir = pwd;
end

cd(spmResultsDir);

%% Print results. Options are 0 and 1
printResults = csprefs.spm_results.print;

%% Contrasts Included
con_included = csprefs.spm_results.con;
con_included = convert_to_cell(con_included);
numContrastQueries = length(con_included);

max_con = max(cellfun(@max, con_included));

%% Threshold description. Options are {'FWE','FDR','none'}
thresh_desc = csprefs.spm_results.threshdesc;
thresh_desc = convert_to_cell(thresh_desc, numContrastQueries, 'csprefs.spm_results.threshdesc');

%% P threshold
thresh = csprefs.spm_results.thresh;
thresh = convert_to_cell(thresh, numContrastQueries, 'csprefs.spm_results.thresh');

%% Extent voxels
extentVoxels = csprefs.spm_results.extent;
extentVoxels = convert_to_cell(extentVoxels, numContrastQueries, 'csprefs.spm_results.extent');

%% Mask
mask = repmat({[]}, 1, numContrastQueries);
if (isfield(csprefs.spm_results, 'mask') && ~isempty(csprefs.spm_results.mask) && ...
        ~isempty(csprefs.spm_results.mask.contrasts))
    
    %% Mask information
    mask_contrasts = csprefs.spm_results.mask.contrasts;
    
    print_err(length(mask_contrasts), numContrastQueries, 'csprefs.spm_results.mask.contrasts')
    
    %% Mask threshold
    mask_thresh = csprefs.spm_results.mask.thresh;
    mask_thresh = convert_to_cell(mask_thresh, numContrastQueries, 'csprefs.spm_results.mask.thresh');
    
    %% Mask Type
    mask_type = csprefs.spm_results.mask.mtype;
    mask_type = convert_to_cell(mask_type, numContrastQueries, 'csprefs.spm_results.mask.mtype');
    
    %% Mask information
    for nM = 1:length(mask)
        temp = mask_contrasts{nM};
        if ~isempty(temp)
            mask{nM} = struct('contrasts', temp, 'thresh', mask_thresh{nM}, 'mtype', mask_type{nM});
        end
    end
end

%% Contrasts to include
load(spmMatFileName);

if (~isfield(SPM, 'xCon') || isempty(SPM.xCon))
    error('Error:cs_spm_results_err', 'You need to setup contrasts inorder to use this script');
end

if (max_con > length(SPM.xCon))
    error('Error:cs_spm_results_err', 'Maximum value in contrast vector (%d) exceeds the number of contrasts (%d)\n', ...
        max_con, length(SPM.xCon));
end

%% Create jobs data structure
jobs{1}.stats{1}.results.spmmat{1} = spmMatFileName;
jobs{1}.stats{1}.results.print = printResults;
jobs{1}.stats{1}.results.conspec = struct('threshdesc', [], 'thresh', [], 'extent', [], 'mask', []);

%% Loop over contrasts
for nCon = 1:numContrastQueries
    
    current_con = con_included{nCon};
    current_con = current_con(1);
    
    if ~isempty(SPM.xCon(current_con).Vcon)
        current_con_file = fullfile(stats_dir_name, SPM.xCon(current_con).Vcon(1).fname);
        current_con_name = SPM.xCon(current_con).name;
        if ~exist(current_con_file, 'file')
            error('Error:cs_spm_results_err', 'Contrast file %s doesn''t exist', current_con_file);
        end
    else
        continue;
    end
    
    %% Set jobs cell array
    current_thresh_desc = get_thresh_desc(thresh_desc{nCon});
    jobs{1}.stats{1}.results.conspec(1).threshdesc = current_thresh_desc;
    jobs{1}.stats{1}.results.conspec(1).thresh = thresh{nCon};
    jobs{1}.stats{1}.results.conspec(1).extent = extentVoxels{nCon};
    jobs{1}.stats{1}.results.conspec(1).mask = [];
    
    %% Contrasts information
    jobs{1}.stats{1}.results.conspec(1).titlestr = current_con_name;
    jobs{1}.stats{1}.results.conspec(1).contrasts = current_con;
    
    drawnow;
    
    try
        
        %% Run spm job
        spm_jobman('run', jobs);
        
        %% Run autoslice
        autoslice5;
        
        %% Print image files
        
        % Jpeg
        jpg_file_name = fullfile(spmResultsDir, (sprintf('con_%.4d_%s.jpg', current_con, current_con_name)));
        print_cmd = 'print -djpeg -painters -noui';
        slice_overlay('print', jpg_file_name, print_cmd);
        
        %cs_spm_print(jpg_file_name);
        
        % Postscript
        print_cmd = 'print -dpsc2 -painters -noui';
        ps_file_name = fullfile(spmResultsDir, (sprintf('con_%.4d_%s.ps', current_con, current_con_name)));
        slice_overlay('print', ps_file_name, print_cmd);
        %cs_spm_print(ps_file_name);
        
        cs_log(['File ', jpg_file_name, ' created successfully'], progFile, 1);
        cs_log(['File ', ps_file_name, ' created successfully'], progFile, 1);
        
    catch
        
    end
    
end
%% End loop over contrasts

% Log successful completion of cs_spm_results
cs_log(['cs_spm_results completed for ', sub_dir], progFile);


%% Change back to old directory
cd(sub_dir);



function a = convert_to_cell(a, b, name_var)
%% Convert to cell

if (~exist('b', 'var'))
    b = [];
end

if (~exist('name_var', 'var'))
    name_var = [];
end

% Convert to cell
if ~iscell(a)
    if isnumeric(a)
        a = a(:);
        a = num2cell(a);
    else
        a = cellstr(a);
    end
end

% Replicate a if possible
if (~isempty(b) && (length(a) == 1))
    a = repmat(a, b, 1);
end

if ~isempty(name_var)
    print_err(length(a), b, name_var);
end


function thresh_desc = get_thresh_desc(thresh_desc)
%% Get threshold description

if strcmpi(thresh_desc, 'fwe')
    thresh_desc = 'FWE';
elseif strcmpi(thresh_desc, 'fdr')
    thresh_desc = 'FDR';
elseif strcmpi(thresh_desc, 'none')
    thresh_desc = 'none';
else
    error('Error:cs_spm_results_err', 'You need to give correct threshold description.');
end

function print_err(a, b, name_var)
%% Print error message

if (a ~= b)
    error('Error:cs_spm_results_err', ['Length of vector ', name_var, ' (%d) must equal the', ...
        ' no of contrast queries (%d)\n'], a, b);
end
