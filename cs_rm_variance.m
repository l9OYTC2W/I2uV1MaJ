function cs_rm_variance (dirs)
%% Remove variance of defined regressors from the data
%

global csprefs;

progFile = fullfile(pwd, 'cs_progress.txt');

prefix = '';
try
    prefix = csprefs.rm_var_prefix;
catch
end

regress_files = csprefs.rm_var_regressors;

if (isempty(regress_files))
    error('No regressors specified');
end

if (~isfield(csprefs, 'rm_var_rmmean'))
    rm_mean = 0;
else
    rm_mean = csprefs.rm_var_rmmean;
end

if (numel(rm_mean) == 1)
    rm_mean = repmat(rm_mean, size(regress_files));
end

if ((size(rm_mean, 1) ~= size(regress_files, 1)) || (size(rm_mean, 2) ~= size(regress_files, 2)))
    error('Arrays csprefs.rm_var_regressors and csprefs.rm_var_rmmean must be of the same size');
end

for nDir = 1:length(dirs)
    
    directory = dirs{nDir};
    
    cs_log( ['Beginning cs_rm_variance for ', fullfile(pwd, directory)], progFile );
    
    P = cs_list_files(fullfile(pwd, directory), csprefs.rm_var_pattern, 'fullpath');
    
    if (isempty(P))
        error('No files found for removing variance');
    end
    
    rfiles = regress_files(nDir, :);
    R = load_regress(rfiles, rm_mean(nDir, :));
    
    if (isempty(R))
        continue;
    end
    
    % Get the volume
    V = spm_vol(P);
    
    if (length(V) ~= size(R, 1))
        error('Error:Timepoints', 'No. of timepoints (%d) doesn''t match the rows in regressors (%d) of run %s', length(V), size(R, 1), fullfile(pwd, directory));
    end
    
    handles = spm('CreateIntWin');
    set(handles, 'visible', 'on');
    spm_progress_bar('Init', V(1).dim(3), 'Removing variance ...', 'Slices completed');
    Vout = V;
    
    for nT = 1:length(Vout)
        Vout(nT).fname = prepend(V(nT).fname, prefix);
    end
    
    Vout = spm_create_vol(Vout);
    
    pinvR = pinv(R);
    
    % Loop over slices
    for nV = 1:V(1).dim(3)
        
        tmp = loadTC(V, nV);
        betas = pinvR*tmp;
        tmp = tmp - R*betas + eps;
        
        % Loop over time points
        for nT = 1:length(V)
            spm_write_plane(Vout(nT), reshape(tmp(nT, :), [V(1).dim(1), V(1).dim(2)]), nV);
        end
        
        spm_progress_bar('Set', nV);
        
        clear tmp;
        
    end
    
    clear Vout;
    
    spm_progress_bar('Clear');
    
    cs_log( ['cs_rm_variance completed for ', fullfile(pwd,directory)], progFile );
    
end


function PO = prepend(PI, pre)
[pth,nm,xt] = fileparts(deblank(PI));
PO             = fullfile(pth,[pre nm xt]);
return;

function R = load_regress(files, rm_mean)
%% Load regressors

R = cell(1, length(files));
for nR = 1:length(files)
    
    try
        if (isnumeric(files{nR}))
            tmp = files{nR};
        else
            tmp = spm_load(locate_file(files{nR}));
        end
        tmp(1);
    catch
        continue;
    end
    
    if (length(tmp) == numel(tmp))
        tmp = tmp(:);
    end
    
    if (rm_mean(nR) == 1)
        tmp = detrend(tmp, 0);
    end
    
    R{nR} = tmp;
end

R = [R{:}];

function tmp = loadTC(V, nV)
%% Load Timecourses for the given plane

tmp = zeros(length(V),  prod(V(1).dim(1:2)));
for nT = 1:length(V)
    dd = spm_slice_vol(V(nT), spm_matrix([0, 0, nV]), V(1).dim(1:2), 0);
    tmp(nT, :) = dd(:);
end