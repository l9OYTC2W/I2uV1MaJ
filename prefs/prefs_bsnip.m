function prefs_bsnip(initGraphics)
% Along with spm_defaults.m, a wrapper for CenterScripts.
% For proper operation of CenterScripts, only this file and a copy of spm_defaults.m should have to be modified.

% All directory strings should end with slashes (only begin with a slash if it really is describing a location relative to root).

global csprefs;
global defaults;

csprefs.initGraphics = initGraphics;
if ~exist('initGraphics', 'var')
    initGraphics = 1;
end

%% %%%%%%%%%%%%%%%%
% PATH CHANGES HERE
%%%%%%%%%%%%%%%%%%%

% Inria Realign
addpath(fileparts(which('inria_realign.m')));

% Slice overlay
addpath(fileparts(which('display_slices.m')));

%% %%%%%%%%%%%%%%%%%%%%%%
% PROCESSING STEPS TO RUN
%%%%%%%%%%%%%%%%%%%%%%%%%
% indicate 1 to run that step, 0 not to run it

csprefs.run_dicom_convert       = 0;
csprefs.run_rename              = 1;
csprefs.run_discard             = 0;
csprefs.run_realign             = 1;
csprefs.run_slicetime           = 1;
csprefs.run_coregister          = 0;
csprefs.run_normalize           = 1;
csprefs.run_smooth              = 1;
csprefs.run_detrend             = 1;
csprefs.run_filter              = 0;
csprefs.run_despike             = 1;
csprefs.run_beh_matchup         = 0;
csprefs.run_reorient            = 0;
csprefs.run_stats               = 0;
% Added option to use SPM results button
csprefs.run_spm_results         = 0; 
csprefs.run_autoslice           = 0;
csprefs.run_deriv_boost         = 0; 
csprefs.run_segment             = 0; 

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
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
% csprefs.dummyscans            : Number of initial scans to discard. It
%                               checks for files with realignment pattern.
% csprefs.tr                    : very important: TR of scans, in seconds

csprefs.exp_dir                 = '/export/mialab/users/salman/data/SubjectData'; 
csprefs.logfile                 = '/export/mialab/users/salman/data/SubjectData/cs_log.txt'; 
csprefs.errorlog                = '/export/mialab/users/salman/data/SubjectData/cs_errorlog.txt'; 
csprefs.spm_defaults_dir        = '/export/mialab/users/salman/tools/spm12';
csprefs.scandir_regexp          = '(Chicago|Dallas|Detroit|Hartford)'; %'\<\d{8}_\d{6}_\d{8}\>';
csprefs.rundir_regexp           = '.*'; % Match decimal number exactly
csprefs.scandir_postpend        = ''; % Leave it as empty if subject directories don't have additional path like Study
csprefs.rundir_postpend         = ''; % Leave it as empty if run directories don't have additional path like Original/Nifti
csprefs.file_useregexp          = 0; % Option for using regular expressions for file pattern
csprefs.dummyscans              = 0; % Option for moving dummy scans to dummies directory. Only files with realignment pattern (csprefs.realign_pattern) will be moved.
csprefs.tr                      = 2;

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SETTINGS PERTAINING TO CS_BEH_MATCHUP
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% csprefs.beh_queue_dir         : directory where beh data is queued up
% csprefs.digits                : number of digits to match in files or folders within beh_queue_dir; this allows cs_beh_matchup to align the last n
%                                   digits of the longest string of digits in a filename with the last n digits of the scan directory name

csprefs.beh_queue_dir           = '/shasta/data1/aod_queue/';
csprefs.digits                  = [3,4];


%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SETTINGS PERTAINING TO CS_DICOM_CONVERT
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% csprefs.dicom.file_pattern - File pattern for dicom files.
%
% csprefs.dicom.format - Dicom files can be converted to 3D analyze, 3D
% Nifti or 4D Nifti files depending upon the format.
% Options are '3d_analyze', '3d_nifti' or '4d_nifti'
%
% csprefs.dicom.write_file_prefix - File prefix for naming the analyze or
% Nifti files that are written.
%
% csprefs.dicom.outputDir - Files converted from DICOM will be placed in
% this directory. 

csprefs.dicom.file_pattern = '0000*.dcm';
csprefs.dicom.format = '3d_nifti';
csprefs.dicom.write_file_prefix = '';
csprefs.dicom.outputDir = ''; % Leave it as empty '' or [] if you want the files to be placed in the run directory


%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SETTINGS PERTAINING TO CS_RENAME
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% todo: For now this is full custom.



%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SETTINGS PERTAINING TO CS_DISCARD
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% csprefs.discard_timepoints    : 
% csprefs.keep_original         :

csprefs.discard_pattern         = 'S*.nii';
csprefs.discard_timepoints      = 10;
csprefs.keep_original           = 1;


%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SETTINGS PERTAINING TO CS_REORIENT
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 1. csprefs.reorient_pattern: Specify pattern for images to be re-oriented.
%
% 2. csprefs.reorient_vector: Affine transformation matrix will be obtained
% based on this vector.
%
%    csprefs.reorient_vector(1)  - x translation
%    csprefs.reorient_vector(2)  - y translation
%    csprefs.reorient_vector(3)  - z translation
%    csprefs.reorient_vector(4)  - x rotation about - {pitch} (radians)
%    csprefs.reorient_vector(5)  - y rotation about - {roll}  (radians)
%    csprefs.reorient_vector(6)  - z rotation about - {yaw}   (radians)
%    csprefs.reorient_vector(7)  - x scaling
%    csprefs.reorient_vector(8)  - y scaling
%    csprefs.reorient_vector(9)  - z scaling
%    csprefs.reorient_vector(10) - x affine
%    csprefs.reorient_vector(11) - y affine
%    csprefs.reorient_vector(12) - z affine
%
% 3. csprefs.write_reorient: 1 means write images otherwise specify 0.
% 
% Note: csprefs.write_reorient = 0 modifies the headers of the images
% whereas csprefs.write_reorient = 1 will write new set of images with
% prefix Re_

csprefs.reorient_pattern = 'S*.nii';
csprefs.reorient_vector = [0, 0, 0, 0, 0, 0, 1, 1, 1, 0, 0, 0]; 
csprefs.write_reorient = 0;


%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SETTINGS PERTAINING TO CS_REALIGN
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% csprefs.coregister            : whether to coregister (i.e., run inria_realign or spm_realign). 1 for yes, 0 for no
% csprefs.reslice               : whether to reslice (i.e., run spm_reslice). 1 for yes, 0 for no. Together, this and csprefs.coregister take the
%                                   place of the "Coregister and Reslice?" type dialog box in the GUI
% csprefs.use_inrialign         : whether to use INRIAlign. 1 for yes, 0 for no (if 0, use spm_realign instead)
% csprefs.realign_pattern       : specifies a pattern identifying which image files should be realigned. Literals and wildcards (*) only
% csprefs.inrialign_rho         : rho function for INRIAlign. Ignore if not using INRIAlign. Default is 'geman'; see inria_realign.m for further
%                                   explanation and other choices.
% csprefs.inrialign_cutoff      : cut-off distance for INRIAlign. Ignore if not using INRIAlign. Default is 2.5; see inria_realign.m for details
% csprefs.inrialign_quality     : quality value for INRIAlign. Value from 0 (fastest, low quality) to 1 (slowest, high quality). The equivalent value
%                                   for spm_realign is defined in spm_defaults.m
% csprefs.realign_fwhm          : size of smoothing kernel (mm) applied during realignment. Applies to both INRIAlign and spm_realign
% csprefs.realign_rtm           : whether to realign all images to the mean image. 1 for yes, 0 for no. Applies to both INRIAlign and spm_realign.
%                                   NOTE: APPARENTLY DOES NOT WORK FOR INRIALIGN.
% csprefs.realign_pw            : pathname to a weighting image for realignment. Leave at '' if you don't want to weight (...for our lives to be
%                                   over...). Might need some recoding to actually use this option... we're just going to assume it's blank for now.
% csprefs.reslice_write_imgs    : which resliced images to write. 0 = don't write any, 1 = write all but first image, 2 = write all
% csprefs.reslice_write_mean    : whether to write a mean image. 1 for yes, 0 for no
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%       SETTINGS IN SPM_DEFAULTS.M
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% There are three more flags for reslicing: mask (whether to mask out zero voxels in realigned images), interp (which interpolation method
% to use), and wrap, which I really don't know much about. These default to their settings in spm_defaults.m

csprefs.coregister              = 1;
csprefs.reslice                 = 1;
csprefs.use_inrialign           = 1;
csprefs.realign_pattern         = 'S*.nii';
csprefs.inrialign_rho           = 'geman';
csprefs.inrialign_cutoff        = 2.5;
csprefs.inrialign_quality       = 1.0;
csprefs.realign_fwhm            = 6;
%there is also some flag called 'sep' in both realign functions. I don't know what it does, hence I'm leaving it at default for now.
csprefs.realign_rtm             = 0;
csprefs.realign_pw              = '';
%INRIAlign has a 'hold' flag, spm_realign has an 'interp' flag... for right now I'm just leaving them alone. INRIAlign will use its defaults,
%spm_realign will use the value set in spm_defaults.m
csprefs.reslice_write_imgs      = 1;
csprefs.reslice_write_mean      = 1;


%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SETTINGS PERTAINING TO CS_COREGISTER
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 
% 1. csprefs.run_coreg: Runs coregister step if 1 is specified.
% 2. csprefs.run_reslice: Runs reslice step if 1 is specified
%
% Coregister Options:
%
% 1. csprefs.coreg.ref: Reference image used for coregister step. You can use
% full file path of the image.
% 2. csprefs.coreg.source: Source image used for coregister step. You can use
% full file path of the image.
% 3. csprefs.coreg.other_pattern: File pattern of other images used. (Optional)
%
% Reslice Options:
%
% 1. csprefs.coreg.write.ref: Reference image used for reslicing. Specify the reference file if you have 
% specified a value of 1 for csprefs.run_reslice. Source image and other
% images will be resliced using the reference image. After reslicing the
% new set of images have prefix r.
% 
% Note: Other options will be used from the spm_defaults file. For
% coregister step defaults.coreg.estimate structure will be used and for
% reslice step defaults.coreg.write structure will be used.

csprefs.run_coreg = 1;
csprefs.run_reslice = 1;
csprefs.coreg.ref = '/export/mialab/users/salman/tools/spm12/templates/EPI.nii'; 
csprefs.coreg.source = 's0*-0007*.img'; 
csprefs.coreg.other_pattern = 's0*.img'; % Leave '' if you don't specify other images
csprefs.coreg.write.ref = '/export/research/analysis/human/collaboration/olin/users/srinivas/testDicom/fsw050314990007.img';


%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SETTINGS PERTAINING TO CS_SLICETIME
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% csprefs.slicetime_pattern     : specifies a pattern identifying which image files should be slicetimed. Literals and wildcards (*) only
% csprefs.sliceorder		: Matlab matrix specifying order of slices acquired (just like you input it in the SPM GUI). Just remember to enclose
%                                   the matrix in square brackets, e.g. [ 1 3 5 7 9 2 4 6 8 10]
% NOTE: You could also use 'sequential' for sequential slices and
% 'interleaved' for interleaved slices.

% csprefs.refslice		: slice # to use as the "reference slice"; same as
                          % you input it in the SPM GUI or use character
                          % name 'middle' for middle slice, 'first' for
                          % first slice and 'last' for last slice

% csprefs.ta			: time of acquisition (TA). If you have a specific value in mind for this (like 1.9 or something), you can use that;

%                                   if, like most people, you just accept the default value in the GUI, you can specify the text string 'default' to

%                                   use the auto-calculated value (which is the time of one TR minus the time of one slice)


csprefs.slicetime_pattern	=   'rS*.nii';
csprefs.sliceorder              = [1:1:29];
csprefs.refslice                = 15;
csprefs.ta                      = 'default';


%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SETTINGS PERTAINING TO CS_NORMALIZE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% csprefs.determine_params      : whether to determine paramters (first step of normalization)
% csprefs.write_normalized      : whether to write normalized images (second step of normalization)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SETTINGS FOR PARAMETER ESTIMATION
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% csprefs.params_template       : image to use as template for paramter estimation. For fMRI, usually 'EPI.nii' somewhere. Although spm_normalize
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
csprefs.params_template         = '/export/mialab/users/salman/tools/spm12/toolbox/OldNorm/EPI.nii'; %'/opt/local/spm2/templates/EPI.mnc';
csprefs.params_pattern          = 'meanS*.nii';
csprefs.params_source_weight    = '';
csprefs.writenorm_pattern       = 'arS*.nii';
csprefs.writenorm_matname       = '';

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SETTINGS PERTAINING TO CS_SMOOTH
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% csprefs.smooth_kernel         : size of Gaussian smoothing kernel, in mm
% csprefs.smooth_pattern        : specifies a pattern identifying which image files should be smoothed. Literals and wildcards (*) only

csprefs.smooth_kernel           = [8 8 8];
csprefs.smooth_pattern          = 'warS*.nii';

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SETTINGS PERTAINING TO CS_DETREND
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% csprefs.detrend_pattern       : 

csprefs.detrend_pattern         = 'swarS*.nii';

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SETTINGS PERTAINING TO CS_FILTER
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% csprefs.filter_pattern        : pattern for images to filter. Wildcards (*) and literals only. If demand warrants, we can do this with regexp
%                                   instead, but I doubt it's necessary
% csprefs.cutoff_freq           : to be honest, I don't really know what this is

csprefs.filter_pattern          = 'tswarS*.nii';
csprefs.cutoff_freq             = .08;

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SETTINGS PERTAINING TO CS_DESPIKE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% csprefs.despike_bin           : 
% csprefs.despike_pattern       : 

csprefs.despike_bin             = '/export/mialab/users/salman/tools/center_scripts_v1.01/3dDespike';
csprefs.despike_pattern         = 'tswarS*.nii';


%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SETTINGS PERTAINING TO CS_STATS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% csprefs.stats_make_asciis     : whether to run a script generating ASCII timing files from the subject's behavioral data
% csprefs.stats_ascii_script    : if csprefs.stats_ascii_script is 1, then this should specify the path to a script that computes timings from
%                                 whatever sorts of files are in the subject's behavioral (csprefs.stats_beh_dir_name) directory. 
%                                 CenterScripts promises that the script will be run from the behavioral
%                                 (csprefs.stats_beh_dir_name) directory; everything else is up to the file you specify here.
% csprefs.stats_beh_dir_name    : Behavioral directory name. This will be
%                                 used when make ascii script is used.
%
% csprefs.stats_files_relative_path_sub: A value of 1 means onset and
%                                       duration files will be relative to
%                                       subject directory and a value of 0
%                                       means onset and duration files will
%                                       be relative to run directory.
%
% csprefs.stats_dir_name        : what to call the directory in which stats are run
% csprefs.stats_pattern         : pattern for images on which to run stats. Wildcards (*) and literals only. 
% csprefs.stats_beh_units       : whether ascii file timings are in scans or seconds. Should be either 'scans' or 'secs'; in the ONRC this should
%                                   usually be 'scans'.
% csprefs.stats_volterra        : corresponds to SPM GUI option "Model interactions (Volterra)." 1 for yes, 0 for no.
% csprefs.stats_basis_func      : which basis function to use. Usually canonical hemodynmaic response function (HRF) or HRF with time derivative.
%                                   Value should be a number. Here are the available options.
%                                   1-'hrf'
%                                   2-'hrf (with time derivative)'
%                                   3-'hrf (with time and dispersion derivatives)'
%                                   4-'Fourier set'
%                                   5-'Fourier set (Hanning)'
%                                   6-'Gamma functions'
%                                   7-'Finite Impulse Response'

% csprefs.stats_window_length and csprefs.stats_order are required when you enter csprefs.stats_basis_func a value greater than 3 

% csprefs.stats_window_length    : Window length in seconds
% csprefs.stats_order            : Order

% csprefs.stats_onset_files     : OK, here is where you need a LITTLE bit of Matlab knowledge. This is going to be a matrix of filenames. These
%                                   filenames can either be relative to each subject or session directory (i.e., 'beh/event1.asc' or 'run1/beh/event1.asc' or
%                                   whatnot), OR they can be absolute (i.e., '/shasta/data1/aod/event_always_thesame.asc') if the onsets don't change
%                                   between subjects. The number of rows in this matrix is the number of runs you have. If particular subjects did not
%                                   complete all runs, the script will take care of it if I) run directories are numbered (i.e. '1/' '2/' or 'run1/'
%                                   'run2/' or anything of the sort) or II) the run(s) they did complete are the first run(s). If your run directories
%                                   are NOT numbered AND the subject did not complete the FIRST run, you may need to reconfigure a prefs file for that
%                                   subject and run them manually. There should be as many filenames in each row as there are events in that run. If a
%                                   particular event does not occur in a run, it is OK for the file to be empty or nonexistent.
% csprefs.stats_duration_files  : same exact rules as above, with one addition: If you have short events, i.e., you want your events to all be
%                                   duration 0, then just enter this option as [] (the empty matrix) or 0. Otherwise, number of files etc. should match
%                                   up with the onset files.
% csprefs.stats_global_fx       : corresponds to the "Remove Global effects" option in the GUI. 1 for yes, 0 for no.
% csprefs.stats_highpass_cutoff : number of seconds for high-pass filter. Default is 128. Put 'Inf' (without quotes) for no filtering.
% csprefs.stats_serial_corr     : corresponds to the "Correct for serial correlations?" option in the GUI. 1 for yes, 0 for no.
% csprefs.stats_tcontrasts      : a matrix of contrasts that you would like to be created automatically. Each row is a contrast. Make sure there are
%                                   the right number of columns. If you have n runs per subject, you can either specify an entire contrast (all events
%                                   for n runs + n zeros at the end), just the numbers for the events in all runs (cs_stats will supply the trailing n
%                                   zeros), or just the numbers for the events in one run (cs_stats will replicate it n times and add n zeros at the
%                                   end).
% csprefs.stats_tcontrast_names : a cell array of strings specifying names for all of your contrasts. Obviously there should be the same number of
%                                   names as there are rows in
%                                   csprefs.stats_tcontrasts.

csprefs.stats_make_asciis       = 0;
csprefs.stats_ascii_script      = '/media/mrn/tools/center_scripts_v1.0/aod/cs_aod_asciis.m';
% Behavioural directory name
csprefs.stats_beh_dir_name      = 'behavioral';

% Added field to get the information regarding files relative path w.r.t subject directory.
% a. A value of 0 means onset and duration files are relative to session.
% b. A value of 1 means onset and duration files are relative to subject.
csprefs.stats_files_relative_path_sub = 0;


csprefs.stats_dir_name          = 'analysis/aod/stats';
csprefs.stats_pattern           = 'fswaS*run*.nii';
csprefs.stats_beh_units         = 'scans';
csprefs.stats_volterra          = 0;
csprefs.stats_basis_func        = 2;

% csprefs.stats_window_length and csprefs.stats_order are required when you
% enter csprefs.stats_basis_func a value greater than 3 
csprefs.stats_window_length     = 32;
csprefs.stats_order             = 2;

% Size of the onset files cell array is number of sessions by conditions. Session relative paths will be used if 
% csprefs.stats_files_relative_path_sub is set to 0.
csprefs.stats_onset_files       = {'behavioral/TRG_PR_1_noslice.asc', 'behavioral/NOV_OM_1_noslice.asc', 'behavioral/STD_OM_1_noslice.asc' ;
                                   'behavioral/TRG_PR_2_noslice.asc', 'behavioral/NOV_OM_2_noslice.asc', 'behavioral/STD_OM_2_noslice.asc' };

csprefs.stats_duration_files    = 0;


%%%%%%% Time and parametric modulation %%%%%

% If you are not using time modulation then set
% csprefs.stats_time_modulation = 0 or csprefs.stats_time_modulation = {};
% Otherwise specify a cell array of size number of sessions by conditions.
% Where the order of time modulation is as follows:
%
% 0 - No Time modulation
% 1 - 1st order
% 2 - 2nd order
% 3 - 3rd order
% 4 - 4th order
% 5 - 5th order
% 6 - 6th order

% Example is given in commented section.
%csprefs.stats_time_modulation = {1, 1, 1; 1, 1, 1};

csprefs.stats_time_modulation = 0;


% If you are not using parametric modulation then set
% csprefs.stats_parametric_modulation = 0 or csprefs.csprefs.stats_parametric_modulation = {};
% Otherwise specify a cell array of size number of sessions by conditions.
% Example is given below:

% For each parameter each condition the values are given as follows:
% {parameter_name, parameter_vector, polynomial expansion}
% a. Parameter_name - 'Targets'
% b. parameter_vector must be of the same length as the onset timings for that condition like [1:23]. 
% c. polynomial expansion - Options are as follows:
% 1 - 1st order
% 2 - 2nd order
% 3 - 3rd order
% 4 - 4th order
% 5 - 5th order
% 6 - 6th order

% Example is given in commented section:
%csprefs.stats_parametric_modulation = {{'Targets', [1:23], 1}, {'Novels', [1:23], 1}, {'Standards', [1:184], 1}; ...
%                                      {'Targets', [1:24], 1}, {'Novels', [1:23], 1}, {'Standards', [1:185], 1}};

csprefs.stats_parametric_modulation = 0;

%%% End for entering parameters for time and parameteric modulation %%%


% csprefs.stats_regressor_files   = { 'rp*.txt';
%                                     'rp*.txt'  };
%                                 
% csprefs.stats_regressor_names   = { 'x1' 'y1' 'z1' 'pitch1' 'roll1' 'yaw1';
%                                     'x2' 'y2' 'z2' 'pitch2' 'roll2' 'yaw2'};                                
%                               

% csprefs.other_regressor_files = {'beh_sm/regress1_run1.asc';
%                                  'beh_sm/regress1_run2.asc'};

csprefs.stats_global_fx         = 0;

csprefs.stats_highpass_cutoff   = 128;
csprefs.stats_serial_corr       = 0;

% Contrast matrix will be of size number of contrasts by number of
% regressors. Number of regressors is equal to (Number of sessions * Number
% of basis_functions * Number of conditions * (1 + order of time modulation + polynomial
% order of parametric modulation)) + Number of sessions

%                                   t  d  n  d  s  d  t  d  n  d  s  d  0  0
csprefs.stats_tcontrasts        = [ 1  0  0  0 -1  0  1  0  0  0 -1  0  0  0;
    0  0  1  0 -1  0  0  0  1  0 -1  0  0  0;
    1  0  0  0  0  0  1  0  0  0  0  0  0  0;
    0  0  1  0  0  0  0  0  1  0  0  0  0  0;
    0  0  0  0  1  0  0  0  0  0  1  0  0  0;
    1  0  0  0  0  0  0  0  0  0  0  0  0  0;
    0  0  1  0  0  0  0  0  0  0  0  0  0  0;
    0  0  0  0  1  0  0  0  0  0  0  0  0  0;
    1  0  0  0 -1  0  0  0  0  0  0  0  0  0;
    0  0  1  0 -1  0  0  0  0  0  0  0  0  0;
    0  0  0  0  0  0  1  0  0  0  0  0  0  0;
    0  0  0  0  0  0  0  0  1  0  0  0  0  0;
    0  0  0  0  0  0  0  0  0  0  1  0  0  0;
    0  0  0  0  0  0  1  0  0  0 -1  0  0  0;
    0  0  0  0  0  0  0  0  1  0 -1  0  0  0    ];
csprefs.stats_tcontrast_names   = { 'targets_vs_std_baseline';
    'novels_vs_std_baseline';
    'targets_vs_baseline';
    'novels_vs_baseline';
    'standards_vs_baseline';
    'targets_run1';
    'novels_run1';
    'standards_run1';
    'targets_vs_standards_run1';
    'novels_vs_standards_run1';
    'targets_run2';
    'novels_run2';
    'standards_run2';
    'targets_vs_standards_run2';
    'novels_vs_standards_run2';
    };


%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SETTINGS PERTAINING TO CS_SPM_RESULTS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% -- csprefs.spm_results.stats_dir_name: Stats directory. 
% -- csprefs.spm_results.output_dir:   Output directory to place the contrasts
% results.
% -- csprefs.spm_results.print: Print Glass Brain and cluster results
% -- csprefs.spm_results.con: Contrast numbers to include in a cell array.
% The no. of rows is the number of contrast queries.
% -- csprefs.spm_results.threshdesc: Threshold description. Options are
% 'FWE','FDR','none'.
% -- csprefs.spm_results.thresh: P value threshold
% -- csprefs.spm_results.extent: Extent voxels
% -- Mask parameters: If you don't want to use mask, set csprefs.spm_results.mask to empty like csprefs.spm_results.mask = []; 
%    -- csprefs.spm_results.mask.contrasts - Contrasts
%    -- csprefs.spm_results.mask.thresh - Threshold
%    -- csprefs.spm_results.mask.mtype - Mask type
% --  

% Stats directory
csprefs.spm_results.stats_dir_name = 'stats';
% Ouput directory to place your results
csprefs.spm_results.output_dir = 'contrasts';
% Print glass brain SPM results to postscript file
csprefs.spm_results.print = 0;
% Contrast vector. This is a cell array. The number of rows is number of
% contrast queries.
csprefs.spm_results.con = [1, 2, 3];
% Threshold description. % Options are FWE','FDR' and 'none'. The number of
% rows must match the no. of rows of csprefs.spm_results.con.
csprefs.spm_results.threshdesc = {'none'; 'FDR';  'FWE'};
% P-value threshold for contrasts. The vector length must match the no.
% of rows of csprefs.spm_results.con.
csprefs.spm_results.thresh = [0.0001; 0.05; 0.001];
% Extent voxels. The vector length must match the no. of rows of
% csprefs.spm_results.con.
csprefs.spm_results.extent = [0; 0; 0];

% -- Mask parameters
% If you don't want to use mask, set csprefs.spm_results.mask or csprefs.spm_results.mask.contrasts to empty like
% csprefs.spm_results.mask = [] or csprefs.spm_results.mask.contrasts = []. However, if you want to use mask specify
% those in csprefs.spm_results.mask data structure.
csprefs.spm_results.mask.contrasts = {[], [], []}; %.contrasts = [];
% P value threshold. 
csprefs.spm_results.mask.thresh  = [0.05; 0.01; 0.001];

% Mask type. Options are labels 0 and 1
% a. 0 - Inclusive
% b. 1 - 'Exclusive'
csprefs.spm_results.mask.mtype = 0;

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SETTINGS PERTAINING TO CS_AUTOSLICE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% csprefs.autoslice_cons        : vector of contrast numbers (e.g. [4:6,9,10]) to autoslice
% csprefs.autoslice_p           : p value (uncorrected only, for now) at which to show contrasts
% csprefs.autoslice_background  : absolute pathname of image to serve as the background for the autoslices... most likely some sort of anatomical
% csprefs.autoslice_slices      : vector of z coordinates (in mm) at which to show slices (i.e. for [-40:4:72], shows slices every 4 mm from z=-40 up
%                                   to z=72)
% csprefs.autoslice_email_cons  : vector of contrast numbers to email out. Can be any subset of csprefs.autoslice_cons, including the empty matrix []

csprefs.autoslice_cons          = [6, 7, 11, 12];
csprefs.autoslice_p             = .05;
csprefs.autoslice_background    = '/media/mrn/tools/spm5/canonical/single_subj_T1.nii'; %'/opt/local/spm2/canonical/single_subj_T1.mnc';
% Interpolation scheme:
% 0 - Zero-order hold (nearest neighbour).
% 1 - First-order hold (trilinear interpolation).
% 2->127     Higher order Lagrange (polynomial) interpolation using
%            different holds (second-order upwards).
% -127 - -1   Different orders of sinc interpolation.
csprefs.autoslice_interp        = 0; 
csprefs.autoslice_slices        = [-40:4:72];
csprefs.autoslice_email_cons    = [8,9,12];


%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SETTINGS PERTAINING TO CS_DERIVATIVE_BOOST
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% csprefs.dboost_overwrite_beta : whether or not to overwrite the original beta images (alternative is to create new images). 1 to overwrite, 0 to
%                                   create new ones
% csprefs.dboost_file_prefix    : if creating new files, what to prefix the new files with. If you chose to overwrite the old betas, you can leave
%                                   this set to the empty string; it will be ignored anyway
% csprefs.dboost_beta_nums      : which beta images to apply a derivative boost to, as numbered by SPM (e.g., [1, 3] will boost 'beta_0001.img' and
%                                   'beta_0003.img')
% csprefs.dboost_threshold      : minimum ratio of main effect to derivative required to perform the boost. Default is 1, meaning the boost will be
%                                   applied anywhere that the main effect is at least as big as the derivative effect
% csprefs.dboost_smooth_kernel  : size of smoothing kernel to apply to the derivative boost effect, in mm
% csprefs.dboost_im_calcs       : any additional image calculations to make on your boosted images. In effect you are calculating new contrasts
%                                   manually. This uses SPM's ImCalc syntax, where you specify several images and use i1,i2,i3,etc. to refer to them.
%                                   So, i1+i2 creates the sum of the first and second images. Here, i1,i2,etc. will refer to the boosted images in the
%                                   order you specified them in csprefs.dboost_beta_nums... so if csprefs.dboost_beta_nums is [1, 3, 5], then i1
%                                   refers to the boosted form of 'beta_0001.img', i2 refers to the boosted 'beta_0003.img', and so on.
% csprefs.dboost_im_names       : names for the output images of each of the calculations specified in csprefs.dboost_im_calcs. The number of strings
%                                   in csprefs.dboost_im_calcs and csprefs.dboost_im_names should match up, one name per calculation.

csprefs.dboost_overwrite_beta   = 0;
csprefs.dboost_file_prefix      = 'db_';
%                                  t  n  s  t  n  s
%                                  i1 i2 i3 i4 i5 i6
csprefs.dboost_beta_nums        = [1, 3, 5, 7, 9, 11];
csprefs.dboost_threshold        = 1;
csprefs.dboost_smooth_kernel    = [12 12 12];
csprefs.dboost_im_calcs         = { '(i1+i4)/2';
    '(i2+i5)/2';
    '(i3+i6)/2';
    '(i1+i4)/2-(i3+i6)/2';
    '(i2+i5)/2-(i3+i6)/2';
    };
csprefs.dboost_im_names         = { 'db_targets_mean.img';
    'db_novels_mean.img';
    'db_standards_mean.img';
    'db_targets_vs_standards.img';
    'db_novels_vs_standards.img';
    };



%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SETTINGS PERTAINING TO SEGEMENTATION
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
csprefs.segment.pattern = 'w*.nii'; % file pattern 

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
csprefs.segment.output.WM = [0, 0, 1]; 

% CSF
% Options are the same as grey matter
csprefs.segment.output.CSF = [0, 0, 0]; 

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