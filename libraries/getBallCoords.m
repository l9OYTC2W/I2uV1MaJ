function coordlist=getBallCoords(voxel,radius,VOX,ORIGIN)

%%%%%

% This script returns coordinates in a spherical ROI centred at "voxel"
% of the form [x y z] with radius "radius".
% The values VOX and ORIGIN can be found using the command:
% [DIM,VOX,SCALE,TYPE,OFFSET,ORIGIN,DESCRIP] = spm_hread(P)
% where P is the name of the image file to which the ROI will be applied

% by Adrien Desjardins

%%%%%

if size(voxel,1)~= 1
	voxel=voxel';
end

corner=(1-ORIGIN).*VOX;
nums=(voxel-corner)./VOX;
nnums=round(nums);
nvoxel=nnums.*VOX+corner;

distance=radius*ones(1,3);
nmaxdist=(round(distance./VOX)+1).*VOX;

voxel0=nvoxel-nmaxdist;
voxel1=nvoxel+nmaxdist;

coordlist=[];
for x=voxel0(1):VOX(1):voxel1(1)
for y=voxel0(2):VOX(2):voxel1(2)
for z=voxel0(3):VOX(3):voxel1(3)
	vox=[x y z];
	diff=vox-voxel;
	if sqrt(sum(diff.^2)) <= radius		
		coordlist=[coordlist; [vox(1) vox(2) vox(3)]];
	end
end
end
end

