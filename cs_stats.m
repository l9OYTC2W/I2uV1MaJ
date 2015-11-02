function cs_stats( dir_cells )
% Much of this is blatantly "adapted" from Karl Friston's template

%Get access to CenterScripts prefs and SPM defaults
global csprefs;
global defaults;

%These are constants... declared here match up with what SPM expects. Then we can just access each option below as, for example, basis_funcs{3} rather
%than having to get the string 'hrf (with time and dispersion derivatives)' verbatim every time.
basis_funcs={'hrf', 'hrf (with time derivative)', 'hrf (with time and dispersion derivatives)', 'Fourier set', 'Fourier set (Hanning)',...
    'Gamma functions', 'Finite Impulse Response' };
gnorm_options={'None', 'Scaling'};
autocorr_options={'none','AR(1) + w'};


% Check the field whether to read the onset files from the subject
% directories or run directories
if ~isfield(csprefs, 'stats_files_relative_path_sub')
    csprefs.stats_files_relative_path_sub = 1;
end
% End for checking the field


if ~isfield(csprefs, 'stats_beh_dir_name')
    csprefs.stats_beh_dir_name = 'beh';
end

[dir_cells, unappended_dirs] = cs_eliminate_bad_runs(dir_cells);

%Log progress
progFile=fullfile(pwd,'cs_progress.txt');
cs_log( ['Beginning cs_stats for ',pwd], progFile );

%If we are supposed to run a timing script, run it now.
%This will probably be taken out and modularized in CS 2.0
if csprefs.stats_make_asciis
    ascii_script = csprefs.stats_ascii_script;
    sub_dir = pwd;
    
    if (csprefs.stats_files_relative_path_sub)
        % Run ascii script only once
        behDirName = fullfile(sub_dir, csprefs.stats_beh_dir_name);
        runOnSetAsciiScript(behDirName, ascii_script);
        
    else
        % Run ascii script for each run
        for nDir = 1:length(unappended_dirs)
            behDirName = fullfile(sub_dir, unappended_dirs{nDir}, csprefs.stats_beh_dir_name);
            runOnSetAsciiScript(behDirName, ascii_script);
        end
        % End loop over number of run directories
    end
    
    cd(sub_dir);
end

%Try to determine whether or not run directories are ordered numerically. If so, CS will take that order into account later on. If not, the order in
%which they were originally listed (by default, alphabetically) will be the order to go into the design matrix.
runs_numbered=0;
for i=1:length(dir_cells)
    currentDir = dir_cells{i};
    temp = cs_list_files(fullfile(pwd, currentDir), csprefs.stats_pattern, 'fullpath');
    if isempty(temp)
        error('No files found for stats.');
    end
    statsP{i} = temp;
    clear temp;
    spmVol = spm_vol(statsP{i});
    nscans = length(spmVol);
    SPM.nscan(1,i)            = nscans;
    if ( (i~=1) && (runs_numbered==isempty(regexp(dir_cells{i},'\d'))) )
        error('Some runs seem to be numbered, some don''t -- this confuses cs_stats.');
    else
        runs_numbered=~isempty(regexp(dir_cells{i},'\d'));
    end
    clear spmVol;
end


%Plug in various settings from your csprefs.
SPM.xY.RT                           = csprefs.tr;
SPM.xY.P                            = strvcat(statsP);

%PREFS DETERMINE THESE
SPM.xBF.UNITS                       = csprefs.stats_beh_units;
SPM.xBF.Volterra                    = csprefs.stats_volterra + 1;
SPM.xBF.name                        = basis_funcs{csprefs.stats_basis_func};
SPM.xBF.T                           = defaults.stats.fmri.t;
SPM.xBF.T0                          = defaults.stats.fmri.t0;


SPM.xGX.iGXcalc                     = gnorm_options{csprefs.stats_global_fx+1};
SPM.xX.K.HParam                     = csprefs.stats_highpass_cutoff;
SPM.xVi.form                        = autocorr_options{csprefs.stats_serial_corr+1};


if (csprefs.stats_basis_func > 3)
    % Window length in seconds
    SPM.xBF.length = csprefs.stats_window_length;
    % Order of basis set
    SPM.xBF.order = csprefs.stats_order;
end

%SPM_FMRI_DESIGN SHOULD TAKE CARE OF THESE 4
% SPM.xBF.length     = 32.2;                      % length in seconds
% SPM.xBF.order      = 2;                 % order of basis set
% SPM.xBF.T          = 16;                        % number of time bins per scan
% SPM.xBF.T0         = 1;                 % first time bin (see slice timing)

%Check to see if non-zero durations are supposed to be modeled, and if so, if the user has specified the same number of durations as onsets.
if iscell(csprefs.stats_duration_files)
    do_dur = ~isempty(csprefs.stats_duration_files);
else
    if ( isempty(csprefs.stats_duration_files) || (csprefs.stats_duration_files==0) )
        do_dur=0;
    else
        error('csprefs.stats_duration_files should be either a cell matrix or 0.');
    end
end
if (do_dur && any( size(csprefs.stats_onset_files) ~= size(csprefs.stats_duration_files) ) )
    error('Number of specified onset and duration files do not match up.');
end


origDir = pwd;
my_onsets = csprefs.stats_onset_files;
my_durations = csprefs.stats_duration_files;


%Check correspondence between specified image files and specified behavioral/timing data.
%If the number of directories of image files matches the specified number of timing files, no problem.
%Give error if there are too many runs specified by images (i.e., not enough timing files for # of folders of images).
%On the other hand, if there are more timing files than folders of images, that probably means one or more runs were skipped. Take the best possible
%   guess (and if run folders are numbered, take that into account) as to which runs were included and which were skipped. Take the corresponding
%   timing files out of the model.
if length(dir_cells) > size(my_onsets,1)
    error('More directories specified for stats than are assigned behavioral data.');
elseif length(dir_cells) < size(my_onsets,1)
    if runs_numbered
        %count which one(s) are missing
        %NOTE: cs_stats will wig out if there are >9 runs per sub or if there are multiple digits in a run directory name
        for i=1:size(my_onsets,1)
            run_exists(i)=0;
            for j=1:length(dir_cells)
                if ~isempty(regexp(dir_cells{j},num2str(i)))
                    run_exists(i)=1;
                end
            end
        end
        if (length(find(run_exists)) ~= length(dir_cells))
            error('Run directories are supposed to be numbered, but numbers don''t match up.');
        end
        my_onsets(find(run_exists==0),:)=[];
        if do_dur
            my_durations(find(run_exists==0),:)=[];
        end
    else
        %assume sub. completed first n scans
        cs_log('WARNING: Subject does not appear to have all scan runs completed. Assuming first run(s) were the completed ones.');
        my_onsets((length(dir_cells)+1):end,:)=[];
        if do_dur
            my_durations((length(dir_cells)+1):end,:)=[];
        end
    end
end


%%% Check parameter and time modualtion variable %%%

doParametric = 0;
doTimeModulation = 0;

if isfield(csprefs, 'stats_parametric_modulation')
    if iscell(csprefs.stats_parametric_modulation) && ~isempty(csprefs.stats_parametric_modulation)
        if length(find(size(csprefs.stats_parametric_modulation) == size(csprefs.stats_onset_files))) ~= ...
                length(size(csprefs.stats_onset_files))
            error(['Please check the field csprefs.stats_parameteric_modulation as it does not match the ', ...
                'size of csprefs.stats_onset_files']);
        end
        doParametric = 1;
    end
end


if isfield(csprefs, 'stats_time_modulation')
    if iscell(csprefs.stats_time_modulation) && ~isempty(csprefs.stats_time_modulation)
        if length(find(size(csprefs.stats_time_modulation) == size(csprefs.stats_onset_files))) ~= ...
                length(size(csprefs.stats_onset_files))
            error(['Please check the field csprefs.stats_time_modulation as it does not match the ', ...
                'size of csprefs.stats_onset_files']);
        end
        doTimeModulation = 1;
    end
    
end

%%% End for checking parameter and time modulation %%%




%Actually creates the SPM design based on user's onset and duration files plus any user-specified covariates and/or parametric effects.
%If an onset file is not found, that event is not modeled.
ons_ok=zeros(size(my_onsets));
for i=1:size(my_onsets,1)
    first_u=1;
    % Change to session directory if the onset files are relative to
    % session
    if ~(csprefs.stats_files_relative_path_sub)
        cd(unappended_dirs{i});
    end
    % End for changing to session directory
    for j=1:size(my_onsets,2)
        
        %         if ~isempty(my_onsets{i,j})
        %             if ~exist(my_onsets{i,j}, 'file')
        %                 error(['Cannot find onset file ', my_onsets{i,j}]);
        %             end
        %         end
        
        try
            ons=spm_load(locate_file(my_onsets{i,j}));
            ons(1);
        catch
            %error(['Cannot find onset file ', my_onsets{i,j}]);
            continue;
        end
        
        ons_ok(i,j)=1;
        ons=ons(:);
        [pname fname]=fileparts(my_onsets{i,j});
        
        %% Modified (Dec 10, 2008)
        if do_dur
            if isnumeric(my_durations{i,j})
                dur = my_durations{i,j};
            else
                dur=spm_load(locate_file(my_durations{i,j}));
            end
            dur=dur(:);
        else
            dur = 0;
        end
        
        %         if do_dur
        %             dur=spm_load(locate_file(my_durations{i,j}));
        %             dur=dur(:);
        %         else
        %             dur=0;
        %         end
        
        
        %%% Added code to fix the onset timings %%%%%
        
        TR = SPM.xY.RT;
        
        num_scans = SPM.nscan;
        
        % Change the onset timings
        if strcmpi(SPM.xBF.UNITS, 'secs')
            num_scans = TR*num_scans;
        end
        
        if min(ons) > num_scans(i)
            warning(['Onset timings will be changed as they are not collected w.r.t zero as reference']);
            ons = ons - sum(num_scans(1:i-1));
        end
        
        %%%% End for changing the onset timings %%%%
        
        
        if first_u==1
            SPM.Sess(i).U(1).name       = {fname};
            SPM.Sess(i).U(1).ons        = ons;
            SPM.Sess(i).U(1).dur        = dur;
            first_u = 0;
        else
            SPM.Sess(i).U(end+1).name       = {fname};
            SPM.Sess(i).U(end).ons        = ons;
            SPM.Sess(i).U(end).dur        = dur;
        end
        
        
        % Initialise P and q1 for parameteric and time modulation
        P  = [];
        q1 = 0;
        
        
        chkNans = isnan(ons(:));
        
        
        %%%% Time Modulation %%%%
        if doTimeModulation
            
            if  (csprefs.stats_time_modulation{i, j} > 0)
                % time effects
                P(1).name = 'time';
                P(1).P    = (SPM.Sess(i).U(j).ons) * (TR);
                if isnumeric(csprefs.stats_time_modulation{i, j})
                    P(1).h    = csprefs.stats_time_modulation{i, j};
                else
                    P(1).h      = spm_load(locate_file(csprefs.stats_time_modulation{i, j}));
                end
                q1        = 1;
            end
            
        end
        %%% End for time modulation %%%
        
        
        %%%% Parametric modulation %%%%
        if doParametric
            temp_parameter = csprefs.stats_parametric_modulation{i, j};
            if ~isempty(temp_parameter)
                for q = 1:size(temp_parameter, 1)
                    % Parametric effects
                    q1 = q1 + 1;
                    P(q1).name = temp_parameter{q, 1};
                    %P(q1).P    = temp_parameter{q, 2}(:);
                    if isnumeric(temp_parameter{q, 2})
                        P(q1).P    = temp_parameter{q, 2}(:);
                    else
                        P(q1).P      = spm_load(locate_file(temp_parameter{q, 2}));
                    end
                    P(q1).P = P(q1).P(:);
                    chkNans = chkNans | isnan(P(q1).P);
                    P(q1).h    = temp_parameter{q, 3};
                end
            end
            clear temp_parameter;
        end
        %%%% End for parameteric modulation %%%%
        
        if isempty(P)
            P.name = 'none';
            P.h    = 0;
        end
        
        
        %% Remove trials that have Nans
        SPM.Sess(i).U(end).ons        = ons(chkNans==0);
        try
            SPM.Sess(i).U(end).dur        = dur(chkNans==0);
        catch
        end
        
        try
            for nParams = 1:length(P)
                if (~isempty(P(nParams).P))
                    P(nParams).P = P(nParams).P(chkNans==0);
                end
            end
        catch
        end
        
        SPM.Sess(i).U(end).P = P;
        
        clear P;
        
    end
    
    %user-specified covariates now supported!
    if (~isfield(csprefs,'stats_regressor_files') || isempty(csprefs.stats_regressor_files))
        SPM.Sess(i).C.C                 = [];
        SPM.Sess(i).C.name              = {};
    else
        regs=[];
        regfiles=csprefs.stats_regressor_files(i,:);
        for j=1:length(regfiles)
            regs=[regs, spm_load(locate_file(regfiles{j}))];
        end
        
        regnames=csprefs.stats_regressor_names(i,1:size(regs,2));
        SPM.Sess(i).C.C                 = regs;
        SPM.Sess(i).C.name              = regnames;
    end
    
    if (isfield(csprefs, 'other_regressor_files') && ~isempty(csprefs.other_regressor_files))
        
        if (i == 1)
            other_regressors = cell(1, size(my_onsets, 1));
        end
        
        regfiles = csprefs.other_regressor_files(i, :);
        regs = load_regress(regfiles);
        other_regressors{i} = regs;
        
        clear regs;
        
    end
    
    cd(origDir);
end




%Makes a directory for stats, if specified.
old_dir=pwd;
statsDir = [pwd, filesep, csprefs.stats_dir_name];
if ~isempty( csprefs.stats_dir_name )
    % Make a stats directory if it does not exist
    if (exist(statsDir, 'dir') ~= 7)
        mkdir(pwd, csprefs.stats_dir_name );
    end
    cd(statsDir);
end

try
    fprintf(1, 'A copy of spm_defaults.m file will be saved in directory: \n%s', pwd);
    copyfile(fullfile(csprefs.spm_defaults_dir, 'spm_defaults.m'), pwd);
catch
    disp(lasterr);
end

% Cleanup previous analysis files
prev_analysis_files = {'^mask\..{3}$','^ResMS\..{3}$','^RPV\..{3}$',...
    '^beta_.{4}\..{3}$','^con_.{4}\..{3}$','^ResI_.{4}\..{3}$',...
    '^ess_.{4}\..{3}$', '^spm\w{1}_.{4}\..{3}$'};

for i=1:length(prev_analysis_files)
    j = spm_select('List',pwd,prev_analysis_files{i});
    for k=1:size(j,1)
        spm_unlink(deblank(j(k,:)));
    end
end

% Configure design matrix
SPM = spm_fmri_spm_ui(SPM);

% Print postscript and Jpeg files
cs_spm_print('design_matrix.ps');
cs_spm_print('design_matrix.jpg');

% Explicit mask
if (isfield(csprefs, 'stats_explicit_mask') && ~isempty(csprefs.stats_explicit_mask))
    VMask = spm_vol(csprefs.stats_explicit_mask);
    SPM.xM.VM = VMask(1);
    clear VMask;
end

%% Add these regressors to the end of the design matrix
if (exist('other_regressors', 'var'))
    
    endT = 0;
    RM = cell(1, length(SPM.nscan));
    for nR = 1:length(SPM.nscan)
        startT = endT + 1;
        endT = endT + SPM.nscan(nR);
        if (~isempty(other_regressors{nR}))
            tmpR = zeros(sum(SPM.nscan), size(other_regressors{nR}, 2));
            tmpR(startT:endT, :) = other_regressors{nR};
            RM{nR} = tmpR;
            clear tmpR;
        end
    end
    
    RM = [RM{:}];
    if ~isempty(RM)
        RM_names = cellstr(strcat('Regressor', num2str((1:size(RM, 2))')))';
        SPM.xX.name(end+1:end+length(RM_names)) = RM_names;
        SPM.xX.X = [SPM.xX.X, RM];
    end
    
end

% Estimate parameters
SPM = spm_spm(SPM);


num_runs = size(my_onsets, 1);

% if doTimeModulation
%     order_time_modulation = SPM.Sess(1).U(1).P(1).h;
% else
%     order_time_modulation = 0;
% end

numBasisFunctions = size(SPM.xBF.bf, 2);


countTimeMod = 0;
if (doTimeModulation == 1)
    for i = 1:size(csprefs.stats_time_modulation, 1)
        for j = 1:size(csprefs.stats_time_modulation, 2)
            temp_parameter = csprefs.stats_time_modulation{i, j};
            if ~isempty(temp_parameter)
                countTimeMod = countTimeMod + (numBasisFunctions*temp_parameter);
            end
            clear temp_parameter;
        end
    end
end

contrastsLength = num_runs*size(my_onsets, 2)*numBasisFunctions;

countParamMod = 0;
if (doParametric == 1)
    for i = 1:size(csprefs.stats_parametric_modulation, 1)
        for j = 1:size(csprefs.stats_parametric_modulation, 2)
            temp_parameter = csprefs.stats_parametric_modulation{i, j};
            if ~isempty(temp_parameter)
                for q = 1:size(temp_parameter, 1)
                    countParamMod = countParamMod + (numBasisFunctions*temp_parameter{q, 3});
                end
            end
            clear temp_parameter;
        end
    end
end

contrastsLength = contrastsLength + countParamMod + countTimeMod;


if (isfield(csprefs,'stats_regressor_files') && ~isempty(csprefs.stats_regressor_files))
    
    countCovLen = 0;
    
    for n = 1:length(SPM.Sess)
        countCovLen = countCovLen + size(SPM.Sess(n).C.C, 2);
    end
    
    contrastsLength = contrastsLength + countCovLen;
end

contrastsLength = contrastsLength + num_runs;

if (exist('RM', 'var') && ~isempty(RM))
    contrastsLength = contrastsLength + size(RM, 2);
end


order_time_modulation = 0;

%Generate any specified T-contrasts (this code will likely be taken out and put into its own module soon).
%Try to make a guess at how many columns should be in contrasts (unless covariates/parameters are specified--those are too hard to figure out now),
%   and check that; if the basic contrast list is OK, take out any columns that were not modeled due to lack of onset files being provided, and then
%   run the SPM contrast generator.
con_length=size(csprefs.stats_tcontrasts,2);
if con_length>0
    %this next line is kludgy... fix better at some point.
    %has_params_or_covariates=(isfield(csprefs,'stats_param_names') && ~isempty(csprefs.stats_param_names)) || (isfield(csprefs,'stats_regressor_files') && ~isempty(csprefs.stats_regressor_files));
    has_params_or_covariates = (doParametric) || (doTimeModulation);
    one_run_cons = size(my_onsets, 2);
    
    if (numBasisFunctions == 2 )
        one_run_cons=one_run_cons*2;
    elseif(numBasisFunctions == 3 )
        one_run_cons=one_run_cons*3;
    end
    
    my_cons = csprefs.stats_tcontrasts;
    
    if (con_length < contrastsLength)
        if (con_length == one_run_cons)
            my_cons = repmat(my_cons, 1, num_runs);
        end
        my_cons = [my_cons, repmat(0, size(my_cons, 1), contrastsLength - size(my_cons, 2))];
    elseif (con_length > contrastsLength)
        error('Weird number of contrasts');
    end
    
    %     if (con_length == (num_runs*contrastsLength + num_runs)) || has_params_or_covariates
    %         my_cons = csprefs.stats_tcontrasts;
    %     elseif con_length == (num_runs*contrastsLength)
    %         my_cons = [csprefs.stats_tcontrasts, repmat(0, size(csprefs.stats_tcontrasts, 1), num_runs)];
    %     elseif con_length == one_run_cons
    %         my_cons = [repmat(csprefs.stats_tcontrasts, 1, num_runs), repmat(0, size(csprefs.stats_tcontrasts, 1), num_runs)];
    %     else
    %         error('Weird number of contrasts');
    %         %my_cons=csprefs.stats_tcontrasts;
    %     end
    
    excluded_betas = [];
    endInd = 0;
    startInd = 1;
    % Loop over sessions
    for ii = 1:size(ons_ok, 1)
        % Loop over conditions
        for jj = 1:size(ons_ok, 2)
            
            nparamToMultiply = 0;
            
            order_time_modulation = 0;
            
            if (has_params_or_covariates)
                try
                    currentParamCov = csprefs.stats_parametric_modulation{ii, jj};
                    currentParamCov = currentParamCov(:, 3);
                    currentParamCov = cell2mat(currentParamCov);
                    nparamToMultiply = sum(currentParamCov(:));
                catch
                end
                
                try
                    order_time_modulation = csprefs.stats_time_modulation{ii, jj};
                catch
                    %order_time_modulation = 0;
                end
                
            end
            
            if (isempty(nparamToMultiply))
                nparamToMultiply = 0;
            end
            
            endInd = endInd + numBasisFunctions*(1 + order_time_modulation +  nparamToMultiply);
            
            % Collect all excluded indices
            if (ons_ok(ii, jj) == 0)
                excluded_betas = [excluded_betas, startInd:endInd];
            end
            % End for collecting all excluded indices
            startInd = endInd + 1;
        end
        % End loop over conditions
        
        % Handle special when regressors are also specified
        if (isfield(csprefs,'stats_regressor_files') && ~isempty(csprefs.stats_regressor_files))
            endInd = endInd + size(SPM.Sess(ii).C.C, 2);
        end
        % End for handling special case when regressors are also specified
        
        startInd = endInd + 1;
    end
    % End loop over sessions
    
    % Included betas
    included_betas = ones(1, endInd + length(SPM.Sess));
    
    if ~isempty(excluded_betas)
        included_betas(excluded_betas) = 0;
    end
    
    included_betas = find(included_betas == 1);
    SPM.included_betas = included_betas;
    
    if all(ons_ok(:))
        check_cons = 0;
    else
        check_cons = 1;
    end
    
    % Initialise contrasts included
    countCon = 0;
    con_included = zeros(1, size(my_cons, 1));
    % Loop over contrasts
    for i = 1:size(my_cons,1)
        
        c = my_cons(i, :);
        
        if check_cons
            % Exclude contrasts that contain empty regressors
            if any(c(excluded_betas) ~= 0)
                continue;
            end
            c(excluded_betas) = [];
            % End for excluding contrasts that contain empty regressors
        end
        
        if isempty(c)
            continue;
        end
        
        % Contrasts included
        con_included(i) = 1;
        cname = csprefs.stats_tcontrast_names{i};
        tempCon = spm_FcUtil('Set', cname, 'T', 'c', c(:), SPM.xX.xKXs);
        countCon  = countCon + 1;
        %SPM.xCon(end+1)     = spm_FcUtil('Set',cname,'T','c',c(:),SPM.xX.xKXs);
        if countCon == 1
            field_names = fieldnames(tempCon);
            SPM.xCon = struct;
            for nF = 1:length(field_names)
                SPM.xCon = setfield(SPM.xCon, field_names{nF}, []);
            end
            SPM.xCon = repmat(tempCon, size(my_cons,1), 1);
        end
        SPM.xCon(i) = tempCon;
        clear tempCon;
        
    end
    % End loop over contrasts
    
    con_included = find(con_included ~= 0);
    
    
    if ((exist('con_included', 'var')) && (~isempty(con_included)))
        if ~isempty(excluded_betas)
            % Rename betas
            files = char(SPM.Vbeta.fname);
            Vb = spm_vol(files);
            data = spm_read_vols(Vb);
            delete 'beta*.img' 'beta*.hdr';
            
            for nB = 1:length(included_betas)
                Vb(nB).fname   = sprintf('beta_%04d.img', included_betas(nB));
                Vb(nB).descrip = sprintf('spm_spm:beta (%04d) - %s', included_betas(nB), SPM.xX.name{nB});
                spm_write_vol(Vb(nB), squeeze(data(:, :, :, nB)));
            end
            % End for renaming betas
            clear data;
            SPM.Vbeta = Vb;
        end
        spm_contrasts(SPM, con_included);
    else
        spm_contrasts(SPM);
    end
    
end

% if ((exist('con_included', 'var')) && (~isempty(con_included)))
%     if ~isempty(excluded_betas)
%         % Rename betas
%         files = str2mat(SPM.Vbeta.fname);
%         Vb = spm_vol(files);
%         data = spm_read_vols(Vb);
%         delete 'beta*.img' 'beta*.hdr';
%
%         for nB = 1:length(included_betas)
%             Vb(nB).fname   = sprintf('beta_%04d.img', included_betas(nB));
%             Vb(nB).descrip = sprintf('spm_spm:beta (%04d) - %s', included_betas(nB), SPM.xX.name{nB});
%             spm_write_vol(Vb(nB), squeeze(data(:, :, :, nB)));
%         end
%         % End for renaming betas
%         clear data;
%         SPM.Vbeta = Vb;
%     end
%     spm_contrasts(SPM, con_included);
% else
%     spm_contrasts(SPM);
% end


% Log successful completion of cs_stats
cs_log( ['cs_stats completed for ',old_dir],                                                progFile );
cs_log( ['    csprefs.stats_volterra = ', num2str(csprefs.stats_volterra)],                 progFile, 1 );
cs_log( ['    csprefs.stats_basis_func = ', SPM.xBF.name],                                  progFile, 1 );
cs_log( ['    csprefs.stats_global_fx = ', SPM.xGX.iGXcalc],                                progFile, 1 );
cs_log( ['    csprefs.stats_highpass_cutoff = ', num2str(csprefs.stats_highpass_cutoff)],   progFile, 1 );
cs_log( ['    csprefs.stats_serial_corr = ', SPM.xVi.form],                                 progFile, 1 );
cs_log( ['    defaults.stats.maxmem = ', num2str(defaults.stats.maxmem) ],                  progFile, 1 );
cs_log( ['    defaults.stats.maxres = ', num2str(defaults.stats.maxres) ],                  progFile, 1 );
cs_log( ['    defaults.stats.fmri.ufp = ', num2str(defaults.stats.fmri.ufp) ],              progFile, 1 );
cs_log( ['    defaults.stats.fmri.t = ', num2str(defaults.stats.fmri.t) ],                  progFile, 1 );
cs_log( ['    defaults.stats.fmri.t0 = ', num2str(defaults.stats.fmri.t0) ],                progFile, 1 );

cd( old_dir );

function listing=locate_file( filestr )
%--------------------------------------
% Given a full or partial filename, with or without wildcards, returns full pathname to a single file that fits criteria.
% If 0 or 2+ files are found, errors (although this behavior can be easily modified to fit other circumstances).
% NOTE: Still can't do wildcards in pathnames, ONLY in filenames.


[pth, nm, ext] = fileparts(filestr);

isWildCard = 0;
if (~isempty(pth))
    isWildCard = (exist(pth, 'dir') ~= 7);
end

if (isWildCard)
    
    setenv TERM dumb;
    
    listing = ls(filestr);
    listing = strread(listing, '%s', 'delimiter', '\t');
    %listing(isempty(listing)) = [];
    listing(cellfun('isempty', listing)) = [];
    if ~isempty(listing)
        listing = char(listing);
    else
        listing = '';
    end
    
else
    
    if ~isempty(pth)
        owd=pwd;
        cd(pth);
        targ_dir=pwd;
        cd(owd);
    else
        targ_dir=pwd;
    end
    
    %listing=spm_get('files',targ_dir,[nm ext]);
    
    listing = cs_list_files(targ_dir, [nm ext], 'fullpath');
    
end

if size(listing,1)==0
    error(['No files found that match: ',filestr]);
elseif size(listing,1)>1
    error(['Too many files found that match: ',filestr]);
end

function p=parse_params(i,j,ons)
%---------------------------

global csprefs;

pname=csprefs.stats_param_names{i,j};
porder=csprefs.stats_param_orders{i,j};
pfiles=csprefs.stats_param_files{i,j};

if isempty(pname) || (ischar(pname) && strcmp(lower(pname),'none'))
    p.name='none';
    p.h=0;
else
    if ~iscell(pname)
        pname={pname};
        porder={porder};
        pfiles={pfiles};
    end
    
    for k=1:length(pname)
        p(k).name=pname{k};
        if strcmp(p(k).name,'time')
            p(k).P=ons*csprefs.tr;
        else
            p(k).P=spm_load(locate_file(pfiles{k}));
            p(k).P=p(k).P(:);
        end
        p(k).h=porder{k};
    end
end


function runOnSetAsciiScript(behDirName, ascii_script)

try
    cd(behDirName);
catch
    if (exist(fullfile(pwd, 'pending.txt')) ~= 2)
        cs_log( 'Awaiting behavioral data', 'pending.txt', 1 );
    end
    error( ['No behavioral data yet in ',pwd] );
end
[scriptdir, ascii_script] = fileparts(ascii_script);
addpath(scriptdir);
eval(ascii_script);


function R = load_regress(files)
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
    
    R{nR} = tmp;
end

R = [R{:}];