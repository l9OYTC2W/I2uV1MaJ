function cs_derivative_boost
% Module to incorporate variance from the temporal derivative of a regressor back into the beta image of the original regressor.
% Based on tempDeriv by Eric Egolf
% Assumes current working directory is sub directory

global csprefs;

%Save original subject directory and log progress
sub_dir=pwd;
progFile=fullfile(pwd,'cs_progress.txt');
cs_log( ['Beginning cs_derivative_boost for ',pwd], progFile );

%Try to change into stats directory
if ~isempty( csprefs.stats_dir_name )
    try
        cd( csprefs.stats_dir_name );
    catch
        error('No stats directory -- cs_derivative_boost is bailing out!');
    end
end

spmFile = dir('SPM.mat');
if ~isempty(spmFile)
    sP = load('SPM.mat');
    if isfield(sP.SPM, 'included_betas')
        included_betas = sP.SPM.included_betas;
    end
    [pathstr, fileN, extn] = fileparts(sP.SPM.Vbeta(1).fname);
    clear sP;
else
    error(['SPM.mat file is not present in directory: ', pwd]);
end

if (csprefs.stats_basis_func ~= 2)
    error('Basis function (csprefs.stats_basis_func) must be of order 2 in order to calculate derivative boosted images.');
end

if exist('included_betas', 'var')
    % Derivative boost numbers
    dboost_beta_nums = csprefs.dboost_beta_nums;
    included_db_betas = ones(1, length(dboost_beta_nums));
    displayStr = '';
    % Check betas
    for nB = 1:length(dboost_beta_nums)
        checkB = find(included_betas == dboost_beta_nums(nB));
        if isempty(checkB)
            included_db_betas(nB) = 0;
            displayStr = [displayStr, ' ', num2str(dboost_beta_nums(nB))];
        end
    end
    % End for checking betas

    beta_inds = find(included_db_betas == 1);

    if ~isempty(displayStr)
        disp(['Derivative boost cannot be calculated for betas ', displayStr]);
        fprintf('\n');
    end

    if ~isempty(beta_inds)
        dboost_beta_nums = dboost_beta_nums(beta_inds);
        csprefs.dboost_beta_nums = dboost_beta_nums;
    else
        return;
    end
end

outputDir = pwd;
t = csprefs.dboost_threshold;
boosted_names = '';

spm('CreateIntWin');
spm_progress_bar('Init',length(csprefs.dboost_beta_nums),'Boosting betas','Images completed');
pbar=0;
%Loop through each beta image specified for boosting; assume that beta image # plus 1 is the derivative image
for i=csprefs.dboost_beta_nums
    me_name=sprintf(['beta_%.4d', extn], i);
    der_name=sprintf(['beta_%.4d', extn], i+1);

    me_vol=spm_vol(me_name);
    der_vol=spm_vol(der_name);

    me_dat=spm_read_vols(me_vol);
    der_dat=spm_read_vols(der_vol);

    mag_dat=sqrt(me_dat.^2+der_dat.^2);     %Magnitude of main effect and derivative
    inds=find(abs(me_dat./der_dat)>t);      %Find voxels where ratio of main effect to derivative is above threshold
    diff=zeros(size(me_dat));               %Create difference matrix of where to apply boost effect...
    diff(inds)=mag_dat(inds).*sign(me_dat(inds))-me_dat(inds);   %... and fill with magnitude values at suprathreshold voxels

    %Save a temporary image so we can use spm_smooth to smooth the difference image
    temp_vol=rmfield(me_vol,{'descrip','private','n'});
    temp_vol.fname = 'dbtemp.img';
    spm_write_vol(temp_vol,diff);
    spm_smooth('dbtemp.img','dbtemp.img',csprefs.dboost_smooth_kernel);
    diff = spm_read_vols(spm_vol('dbtemp.img'));
    delete('dbtemp.img');
    delete('dbtemp.hdr');

    %Either write the boosted image over the original beta or to a new file as specified
    if csprefs.dboost_overwrite_beta
        out_vol=me_vol;
        out_vol.descrip = ['DERIVATIVE BOOSTED - ' out_vol.descrip];
        boosted_names=strvcat(boosted_names,me_name);
    elseif isempty(csprefs.dboost_file_prefix)
        error('No prefix defined in csprefs.dboost_file_prefix');
    else
        out_vol=rmfield(me_vol,{'descrip','private','n'});
        out_vol.fname = [csprefs.dboost_file_prefix me_name];
        boosted_names=strvcat(boosted_names,out_vol.fname);
    end
    spm_write_vol(out_vol,me_dat+diff);
    pbar=pbar+1;
    spm_progress_bar('Set',pbar);
end
spm_progress_bar('Clear');

dataType = out_vol.dt(1);

%Do any image calculations specified in prefs
if exist('included_betas', 'var')
    [csprefs.dboost_im_calcs, csprefs.dboost_im_names] = check_imcalcs(csprefs.dboost_im_calcs, csprefs.dboost_im_names, included_db_betas);
end

for i=1:length(csprefs.dboost_im_calcs)
    spm_imcalc_ui(boosted_names, fullfile(outputDir, csprefs.dboost_im_names{i}), csprefs.dboost_im_calcs{i}, {0, 0, dataType, 0});
end

% Autoslice
cs_db_autoslice;

%Log progress
cs_log( ['cs_derivative_boost completed for ',sub_dir],                                     progFile );
cs_log( ['    csprefs.dboost_overwrite_beta = ', num2str(csprefs.dboost_overwrite_beta)],   progFile, 1 );
cs_log( ['    csprefs.dboost_file_prefix = ', csprefs.dboost_file_prefix],                  progFile, 1 );
cs_log( ['    csprefs.dboost_beta_nums = ',mat2str(csprefs.dboost_beta_nums)],              progFile, 1 );
cs_log( ['    csprefs.dboost_threshold = ',num2str(csprefs.dboost_threshold)],              progFile, 1 );
cs_log( ['    csprefs.dboost_smooth_kernel = ',mat2str(csprefs.dboost_smooth_kernel)],      progFile, 1 );

%Remember to restore original subject directory
cd(sub_dir);


function [dboost_im_calcs, dboost_im_names] = check_imcalcs(dboost_im_calcs, dboost_im_names, included_db_betas)
% Check imcalcs

% Get tokens
tokens = regexpi(dboost_im_calcs, 'i(\d+)', 'tokens');
excludedBetas = find(included_db_betas == 0);
includeStr = ones(1, length(tokens));

% Loop over tokens
for i = 1:length(tokens)
    % Current tokens
    currentTokens = tokens{i};
    if isempty(currentTokens)
        includeStr(i) = 0;
        continue;
    end

    % Loop over image numbers
    for j = 1:length(currentTokens)

        % Current image number
        imageNo = cellfun(@str2num, currentTokens{j});

        if ~isempty(find(excludedBetas == imageNo))
            includeStr(i) = 0;
            break;
        end

        % Get imcalc string
        currentStr = dboost_im_calcs{i};

        % New image no.
        newImageNo = sum(included_db_betas(1:imageNo));
        newStr = ['i', num2str(newImageNo)];

        % Replace jth token with the new string
        currentStr = regexprep(currentStr, 'i(\d+)', newStr, j);
        dboost_im_calcs{i} = currentStr;

    end
    % End loop over image numbers
end
% End loop over image numbers

includeStr = (includeStr == 1);

% New im_calcs and im_names
dboost_im_calcs = dboost_im_calcs(includeStr);
dboost_im_names = dboost_im_names(includeStr);