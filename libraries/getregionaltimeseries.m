function [timeSeries,numVoxels,numThreshVoxels,Tscores]=getRegionalTimeSeries(direc,filefilter,maskImage,activationImage,threshold);

timeSeries=[];
numVoxels=[];
numThreshVoxels=[];
Tscores=[];

% note: activationImage and threshold are both optional

%/wiesel/data2/nback_spm99/nb_2x/s01/nback1

% get list of files
if ~exist(direc,'dir')
	error('Directory does not exist!');
end
[files,direcs]=spm_list_files(direc,filefilter);
numfiles=size(files,1);
if (numfiles == 0)
	error('No images found!');
end
fprintf('Found %d files.\n',numfiles);

% read mask image (and activation image if specified)
maskim=readImage(maskImage);

if nargin > 3
   actim=readImage(activationImage);
end
if nargin < 5
   thresh=0;
else
   thresh=threshold;
end

maskinds=find(maskim ~= 0);
numVoxels=length(maskinds);
if nargin > 3
	maskinds=find(maskim ~= 0 & actim > thresh);
end
numThreshVoxels=length(maskinds);
if numThreshVoxels==0
   timeSeries=[];
   return;
end

Tscores=actim(maskinds);
voxels=image2voxel(maskImage,maskinds);

% now get time series
timeSeries=zeros(numfiles,numThreshVoxels);
fprintf('Reading images...');
for fn=1:numfiles
	file=fullfile(direc,deblank2(files(fn,:)));
	timeSeries(fn,:)=getVoxelIntensity(voxels,1,file,0)';
end
fprintf('done.\n');
