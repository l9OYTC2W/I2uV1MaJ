function coordlist=getBoxCoords(voxel,distance,VOX,ORIGIN)

%%%%%

% This script returns coordinates in a box ROI centered about "voxel"
% of the form [x y z] and "distance" of the form [xw yw zw].
% "distance" defines the half-widths of the box. A distance of [0 0 0]
% is valid - only "voxel" will be returned.
% The values VOX and ORIGIN can be found using the command:
% [DIM,VOX,SCALE,TYPE,OFFSET,ORIGIN,DESCRIP] = spm_hread(P)
% where P is the name of the image file to which the ROI will be applied.

% by Adrien Desjardins

%%%%%

if size(voxel,1)~= 1
	voxel=voxel';
end

voxel1=voxel+distance;
voxel0=voxel-distance;

corner=(1-ORIGIN).*VOX;

nums=(voxel0-corner)./VOX;
nnums=ceil(nums);
voxel0=nnums.*VOX+corner;

nums=(voxel1-corner)./VOX;
nnums=floor(nums);
voxel1=nnums.*VOX+corner;

coordlist=[];
for x=voxel0(1):VOX(1):voxel1(1)
for y=voxel0(2):VOX(2):voxel1(2)
for z=voxel0(3):VOX(3):voxel1(3)
	vox=[x y z];
	coordlist=[coordlist; [vox(1) vox(2) vox(3)]];
end
end
end
