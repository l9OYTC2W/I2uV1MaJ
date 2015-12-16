function cs_detrend( directory )
% Performs despiking on all images in a directory.

global csprefs;
global defaults;

V = cs_list_files(fullfile(pwd, directory), csprefs.detrend_pattern, 'fullpath');
if (isempty(V))
    error('No files found for detrending.');
end

orig_dir=pwd;
cd(directory);
progFile=fullfile(orig_dir,'cs_progress.txt');
cs_log( ['Beginning cs_detrend for ',directory], progFile );

% from DPARSFA_run.m written by YAN Chao-Gan
if ~exist('CUTNUMBER','var')
    CUTNUMBER = 10;
end

% todo handle img or compressed files
FileList={};
for j=1:length(V)
    FileList{j,1} = V(j,:);
end

fprintf('\nReading images from "%s" etc.\n', FileList{1});

% todo handle 4D files

% Read NIfTI file Based on SPM's nifti
VolumeIndex = 'all';
[pathstr, name, ext] = fileparts(FileList{1});

Nii  = nifti(FileList{1});
V = spm_vol(FileList{1});

Data = double(Nii.dat);
Header = V(1);
Header.fname=FileList{1};

if sum(sum(Header.mat(1:3,1:3)-diag(diag(Header.mat(1:3,1:3)))~=0))==0 % If the image has no rotation (no non-diagnol element in affine matrix), then transform to RPI coordination.
    if Header.mat(1,1)>0 %R
        Data = flipdim(Data,1);
        Header.mat(1,:) = -1*Header.mat(1,:);
    end
    if Header.mat(2,2)<0 %P
        Data = flipdim(Data,2);
        Header.mat(2,:) = -1*Header.mat(2,:);
    end
    if Header.mat(3,3)<0 %I
        Data = flipdim(Data,3);
        Header.mat(3,:) = -1*Header.mat(3,:);
    end
end
temp = inv(Header.mat)*[0,0,0,1]';
Header.Origin = temp(1:3)';

VoxelSize = sqrt(sum(Header.mat(1:3,1:3).^2));

Data = zeros([size(Data),length(FileList)]);
if prod([size(Data),length(FileList),8]) < 1024*1024*1024 %If data is with two many volumes, then it will be converted to the format 'single'.
    for j=1:length(FileList)
        [DataTemp] = y_ReadRPI(FileList{j});
        Data(:,:,:,j) = DataTemp;
    end
else
    Data = single(Data);
    for j=1:length(FileList)
        [DataTemp] = y_ReadRPI(FileList{j});
        Data(:,:,:,j) = single(DataTemp);
    end
end

[nDim1 nDim2 nDim3 nDimTimePoints]=size(Data);

AllVolume=reshape(Data,[],nDimTimePoints)';
theMean=mean(AllVolume);
SegmentLength = ceil(size(AllVolume,2) / CUTNUMBER);
fprintf('\n\t Detrend working.\tWait...');
for iCut=1:CUTNUMBER
    if iCut~=CUTNUMBER
        Segment = (iCut-1)*SegmentLength+1 : iCut*SegmentLength;
    else
        Segment = (iCut-1)*SegmentLength+1 : size(AllVolume,2);
    end
    
    AllVolume(:,Segment) = detrend(AllVolume(:,Segment));
    
    fprintf('.');
end

AllVolume = AllVolume + repmat(theMean, [nDimTimePoints, 1]);
AllVolume = reshape(AllVolume', [nDim1, nDim2, nDim3, nDimTimePoints]);

Header.pinfo = [1;0;0];
Header.dt = [16,0];

OutName = fullfile( pathstr, [ defaults.detrend.prefix strrep(csprefs.detrend_pattern, '*', directory) ] );
[pathstr, name, ext] = fileparts(OutName);

dat = file_array;
dat.fname = OutName;
dat.dim   = size(AllVolume);
if isfield(Header,'dt')
    dat.dtype  = Header.dt(1);
else % If data type is defined by the nifti command
    dat.dtype  = Header.dat.dtype;
end

dat.offset  = ceil(348/8)*8;

NIfTIObject = nifti;
NIfTIObject.dat = dat;
NIfTIObject.mat = Header.mat;
NIfTIObject.mat0 = Header.mat;
NIfTIObject.descrip = Header.descrip;

if (isfield(Header,'private'))
    try
        NIfTIObject.mat_intent = Header.private.mat_intent;
        NIfTIObject.mat0_intent = Header.private.mat0_intent;
        NIfTIObject.timing = Header.private.timing;
    catch
    end
end


create(NIfTIObject);
dat(:,:,:,:)=Data;

cd(orig_dir);