function cs_prefs_structural(initGraphics)
% Along with spm_defaults.m, a wrapper for CenterScripts.
% For proper operation of CenterScripts, only this file and a copy of spm_defaults.m should have to be modified.

% All directory strings should end with slashes (only begin with a slash if it really is describing a location relative to root).

global csprefs;
global defaults;

if ~exist('initGraphics', 'var')
    initGraphics = 1;
end


%%%%%%%%%%%%%%%%%%%%%%%%%
% PROCESSING STEPS TO RUN
%%%%%%%%%%%%%%%%%%%%%%%%%
% indicate 1 to run that step, 0 not to run it

csprefs.run_beh_matchup         = 0;
csprefs.run_dicom_convert       = 0;
csprefs.run_reorient            = 0;
csprefs.run_realign             = 0;
csprefs.run_coregister          = 0;
csprefs.run_slicetime           = 0;
csprefs.run_normalize           = 0;
csprefs.run_smooth              = 0;
csprefs.run_filter              = 0;
csprefs.run_stats               = 0;
csprefs.run_autoslice           = 0;
csprefs.run_deriv_boost         = 0; 
csprefs.run_segment             = 1; 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% GENERAL SETTINGS... FOR ALL CENTERSCRIPTS FUNCTIONS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% csprefs.exp_dir               : experimental directory
% csprefs.logfile               : name for CenterScripts logfile
% csprefs.errorlog              : name for CenterScripts error log
% csprefs.spm_dir               : where your SPM installation is located
% csprefs.spm_defaults_dir      : where to find the spm_defaults.m file
% csprefs.scandir_regexp        : Regular expression for getting scan or
                                % subject directories. Used only when
                                % cs_run_sub function is called.
% csprefs.rundir_regexp         : Regular expression for getting run
                                % directories
% csprefs.scandir_postpend      : Regular expression for getting path that
                                % will be appended to subject directories
% csprefs.rundir_postpend       : Regular expression for getting path that
                                % will be appended to run directories
% csprefs.file_useregexp        : Option for using regular expressions for
%                                 file pattern
% csprefs.dummyscans            : number of initial scans to discard
% csprefs.tr                    : very important: TR of scans, in seconds

csprefs.exp_dir                 = '/export/research/analysis/human/collaboration/olin/users/srinivas/testDicom/'; 
csprefs.logfile                 = '/export/research/analysis/human/collaboration/olin/users/srinivas/testDicom/cs_log.txt'; 
csprefs.errorlog                = '/export/research/analysis/human/collaboration/olin/users/srinivas/testDicom/cs_errorlog.txt'; 
csprefs.spm_defaults_dir        = '/export/apps/linux-x86/matlab/toolboxes/center_scripts_v1.0/';
csprefs.scandir_regexp          = '\w+'; %'\<\d{8}_\d{6}_\d{8}\>';
csprefs.rundir_regexp           = '\d';
csprefs.scandir_postpend        = '';
csprefs.rundir_postpend         = '';
csprefs.file_useregexp          = 0; % Option for using regular expressions for file pattern
csprefs.dummyscans              = 0;
csprefs.tr                      = 1.5;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SETTINGS PERTAINING TO CS_NORMALIZE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% csprefs.determine_params      : whether to determine paramters (first step of normalization)
% csprefs.write_normalized      : whether to write normalized images (second step of normalization)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SETTINGS FOR PARAMETER ESTIMATION
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% csprefs.params_template       : image to use as template for paramter estimation. For fMRI, usually 'EPI.mnc' somewhere. Although spm_normalize
%                                   allows multiple templates, this option is not implemented in cs_normalize
% csprefs.params_pattern        : name of image, or pattern identifying an image, to use for paramter estimation. Usually this is the mean image
%                                   created during realignment. If a pattern (using wildcards) is used, the pattern should only match one image in
%                                   each directory, or else an error will occur. This image needs to be in the directory passed to cs_normalize
% csprefs.params_source_weight  : name of image, or pattern identifying an image, to weight the source image during paramter estimation. Only need to
%                                   specify this if spm_defaults has "defaults.normalise.estimate.wtsrc" set to 1; otherwise, leave this at ''. If the
%                                   pattern matches more than one image, an error will occur. This image needs to be in the directory passed to cs_normalize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%       SETTINGS IN SPM_DEFAULTS.M
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% There are several more flags for parameter estimation: smosrc (size of Gaussian smoothing kernel in mm), smoref (size of smoothing kernel for
% template image), regtype (see spm_affreg), weight (pathname to image for weighting template image, or '' for no weighting of template), cutoff
% (affects how many basis functions are used), nits (number of  nonlinear iterations), and reg (amount of regularization). These all default to the
% values defined for them in spm_defaults.m
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SETTINGS FOR WRITING NORMALIZED IMAGES
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% csprefs.writenorm_pattern     : specifies a pattern identifying which image files should be normalized. Literals and wildcards (*) only
% csprefs.writenorm_matname     : name of Matlab file, or pattern identifying a Matlab file, containing paramters to apply to images. Only need to
%                                   specify this if you have csprefs.determine_params set to 0; otherwise, leave this at ''. If the pattern matches
%                                   more than one file, an error will occur. This file needs to be in the directory passed to cs_normalize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%       SETTINGS IN SPM_DEFAULTS.M
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% There are five more flags for writing normalized images: preserve (whether to preserve total units in output images), bb (bounding box), vox (voxel
% size of output images), interp (interpolation method), and wrap (??). These all default to the values defined for them in spm_defaults.m

csprefs.determine_params        = 1;
csprefs.write_normalized        = 1;
csprefs.params_template         = '/export/apps/linux-x86/matlab/toolboxes/spm5/templates/T1.nii';
csprefs.params_pattern          = '*.img';
csprefs.params_source_weight    = '';
csprefs.writenorm_pattern       = '*.img';
csprefs.writenorm_matname       = '';


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SETTINGS PERTAINING TO SEGEMENTATION
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
csprefs.segment.pattern = 'w*.img'; % file pattern 

% Grey matter
% Options are as follows:
% [0 0 0] means 'None'
% [0 0 1] means 'Native Space'
% [0 1 0] means 'Unmodulated Normalised'
% [1 0 0] means 'Modulated Normalised'
% [0 1 1] means 'Native + Unmodulated Normalised'
% [1 0 1] means 'Native + Modulated Normalised'
% [1 1 1] means 'Native + Modulated + Unmodulated'
% [1 1 0] means 'Modulated + Unmodulated Normalised'    
csprefs.segment.output.GM = [1, 1, 1]; 

% White Matter
% Options are the same as grey matter 
csprefs.segment.output.WM = [1, 1, 1]; 

% CSF
% Options are the same as grey matter
csprefs.segment.output.CSF = [1, 1, 1]; 

% Bias correction
% Options are as follows:
% 1 means 'Save Bias Corrected'
% 0 means 'Don''t Save Corrected'
csprefs.segment.output.biascor = 1;

% Clean up any partitions
% Options are as follows:
% 0 means 'Dont do cleanup'
% 1 means 'Light Clean'
% 2 means 'Thorough Clean'
csprefs.segment.output.cleanup = 0;

%%%%%%%%% End for specifying the parameters requd for segmentation %%%%%%


if initGraphics
    handles = spm('CreateIntWin'); %for progress bars
    set(handles, 'visible', 'on');
    spm_figure('Create','Graphics','Graphics','on');
    pause(1);
end
addpath(csprefs.spm_defaults_dir);
spm_defaults;