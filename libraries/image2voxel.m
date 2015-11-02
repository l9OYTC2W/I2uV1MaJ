function voxellist=image2voxel(imageFileName,imageIndices,mm)

%%%%%

% This function returns image indices associated with a given voxel list
% It is the inverse of the function voxel2image. "Image indices" are
% the indices of the image in its one-dimensional form, as read in by
% the "readImage" function.
% 
% mm is optional; 1=mm; 0=voxel coords

%%%%%

[DIM,VOX,SCALE,TYPE,OFFSET,ORIGIN,DESCRIP] = spm_hread(imageFileName);
fid=fopen(imageFileName);
im=fread(fid,DIM(1)*DIM(2)*DIM(3),spm_type(TYPE));
fclose(fid);

if size(imageIndices,1)==1
   imageIndices=imageIndices';
end

% convert to voxels;
sl=DIM(1)*DIM(2);
zvox=floor((imageIndices-1)/sl)+1;
temp2=rem(imageIndices-1,sl);
xvox=rem(temp2,DIM(1))+1;
yvox=floor(temp2/DIM(1))+1;

if nargin == 2 | (nargin == 3 & mm)  
   xvoxp=(xvox-ORIGIN(1))*VOX(1);
   yvoxp=(yvox-ORIGIN(2))*VOX(2);
   zvoxp=(zvox-ORIGIN(3))*VOX(3);   
   voxellist=[xvoxp yvoxp zvoxp];   
else
   voxellist=[xvox yvox zvox];   
end
