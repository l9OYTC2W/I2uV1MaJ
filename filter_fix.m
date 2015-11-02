function filter_fix

global csprefs;


% csprefs.tr                    : TR for your experiment; in the ONRC, either 1.5 or 1.86
% csprefs.filter_pattern        : pattern for images to filter. Wildcards (*) and literals only. Usually if you want to filter your smoothed images,
%                                   you will use 's*.img'
% csprefs.cutoff_freq           : leave this at .25 unless you have a compelling reason not to
csprefs.tr                      = 1.5;
csprefs.filter_pattern          = 's*.img';
csprefs.cutoff_freq             = .25;



% USER SHOULD NOT HAVE TO CHANGE ANYTHING BEYOND THIS POINT

addpath('/denali/home/mrjohns/dev/center_scripts/');
addpath('/opt/local/spm2/');
spm fmri;
pause(2);

%dirs=spm_get(-Inf,'','Select directories of image to filter');
dirs = spm_select(Inf, 'dir', 'Select directories of image to filter');
if (isempty(dirs))
    error('No directories selected!');
end

for i=1:size(dirs,1)
    cs_filter(deblank(dirs(i,:)));
end

display('filter_fix script finished successfully!');