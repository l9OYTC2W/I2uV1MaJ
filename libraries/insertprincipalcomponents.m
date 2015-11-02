% This is a procedure to insert the first principal componenents of
% time series from regions specified by mask images. This script must
% be run separately for each session of data.
% by Adrien Desjardins

% text file with a list of mask images (one per line)
maskListFile='maskListFile.txt';

% text file with a list of voxels (one per line)
% these voxels should be noncerebral and contain
% e.g.
% [-4 8 16]
% [0 32 -64]
% [-32 8 16]

voxelListFile='voxelListFile.txt';

% directory containing image files from a particular session
direc='/wiesel/data2/nback_spm99/nb_2x/s02/nback2/';

% wildcard symbol that will uniquely specify image files of interest
% in the directory above, e.g. fsn*.img  
% note that *.img will usually not suffice because of the presence
% of mean images.
filefilter='fsn*.img';

% prefix for new files
prefix='pca';

%low-pass filter before performing PCA? 1=yes; 0=no
lowPass=1;
highPass=1;

% TR (seconds)
RT=3;
	
% if low-pass specified, need the following:

	% cutoff frequency (Hz)
	lowPassCutoff=0.15;
	
% if high-pass specified, need the following:

	% cutoff frequency (Hz)
	highPassCutoff=1/306;

% write out principal components to .mat file instead?
writeToMat=1;

scaleByStd=1;
            
%%%%%% no more changes needed after this %%%%

% plot components and time series as they are computed? 1=yes; 0=no
plotComponent=0;

% check existence of mask/voxel files
if ~exist(maskListFile)
	error('maskListFile does not exist!');
end

% read mask list
maskFiles=readFiles(maskListFile);
nmaskFiles=size(maskFiles,1);

if ~writeToMat
if ~exist(voxelListFile)
	error('voxelListFile does not exist!');
end

% read voxel list
voxels=readFiles(voxelListFile);

nvoxels=size(voxels,1);

% check numbers of masks and voxels
if nmaskFiles ~= nvoxels
	error('number of image masks must equal number of voxels!');
end
if nmaskFiles == 0
	error('no mask files specified!');
end
end

% loop over image masks
all_ts=[];
all_ots=[];
all_u1=[];
for vn=1:nmaskFiles

	% get voxel, mask, image files, and time series
	maskFile=deblank2(maskFiles(vn,:));
	imfiles=spm_get('Files',direc,filefilter);
	nimfiles=size(imfiles,1);
	timeSeries=getRegionalTimeSeries(direc,filefilter,maskFile);
	
        % keep copy of original time series in memory
        otimeSeries=timeSeries;
        
	% scale time series
	omean=mean(timeSeries);
	timeSeries=timeSeries./(ones(size(timeSeries,1),1)*mean(timeSeries));		
	
	% perform filtering if specified
     
        if lowPass
		[b a]=butter(5,lowPassCutoff/((1/RT)/2));
		timeSeries=filtfilt(b,a,timeSeries);
	end
        if highPass
		[b a]=butter(5,highPassCutoff/((1/RT)/2),'high');
		timeSeries=filtfilt(b,a,timeSeries);
	end
	
	ostd=std(timeSeries);
	if scaleByStd
		timeSeries=timeSeries./(ones(size(timeSeries,1),1)*ostd);
	end
	
	% perform pca on mean corrected data
	[u s v]=svds(timeSeries-ones(size(timeSeries,1),1)*mean(timeSeries));	
	
	% now add a constant to the first component
	% define this constant to be 1.5 times the global mean of (cerebral voxels of) the first image
   
   % scale factor for the first component (this will take care of the sign and magnitude)
   usf=mean(v)*diag(s);
   
   V=spm_vol(deblank2(imfiles(1,:)));
   GM=spm_global(V);			
 
   if scaleByStd
   	  scalefac=usf*mean(ostd)*mean(omean);
   else
   	  scalefac=usf*mean(omean);
   end
   ts=u(:,1)*scalefac + GM*1.5;
   
   % check vector sizes
   if length(ts) ~= nimfiles
      error('Wrong number of image files!');
   end   
   
   % add the time series to images or write out to a file
  
   if writeToMat
   	all_ts=[all_ts ts];
   	all_ots=[all_ots mean(otimeSeries')'];
   	all_u1=[all_u1 u(:,1)*scalefac];
   	str=['v1_' num2str(vn) '=v(:,1)' char(59)];
	eval(str);
   else
   voxel=num2str(voxels(vn,:));
   imind=image2voxel(deblank2(imfiles(1,:)),voxel);
   for in=1:nimfiles
      imfile=deblank2(imfiles(i,:))	
      [s1 s2 s3]=parts(imfile);
      nimfile=[s1 prefix s2 s3];
      if vn==1
         im=readImage(imfile);
      else
         im=readImage(nimfile);
      end
      im(imind)=ts(in);
      writeImage(im,nimfile,imfile);
   end	  
   end
   
end
if writeToMat
	save timeSeries all_u1 all_ts all_ots 
end