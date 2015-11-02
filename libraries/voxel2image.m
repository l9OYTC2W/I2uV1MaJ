function imagelist=voxel2image(imageFileName,voxellist)

%%%%%

% This function is the inverse of image2voxel

%%%%%

[DIM,VOX,SCALE,TYPE,OFFSET,ORIGIN,DESCRIP] = spm_hread(imageFileName);
n=length(voxellist(:,1));
corner=(1-ORIGIN).*VOX;
nums=(voxellist-ones(n,1)*corner)./(ones(n,1)*VOX);
temp=(ones(n,1)*[1 DIM(1) DIM(1)*DIM(2)]).*nums;
imagelist=sum(temp')'+1;
