function [coordlist,numcoords]=getImageCoords(imagefilename)

%%%%%

% This script returns the coordinates (coordlist) and number of coordinates
% (numcoords) associated with an image mask

%%%%%

[DIM,VOX,SCALE,TYPE,OFFSET,ORIGIN,DESCRIP] = spm_hread(imagefilename);
fid=fopen(imagefilename);
im=fread(fid,DIM(1)*DIM(2)*DIM(3),spm_type(TYPE));
fclose(fid);

nonzero=find(im > 0);

% convert to voxels;
sl=DIM(1)*DIM(2);
zvox=floor((nonzero-1)/sl)+1;
temp2=rem(nonzero-1,sl);
xvox=rem(temp2,DIM(1))+1;
yvox=floor(temp2/DIM(1))+1;

voxelsizex=VOX(1);
voxelsizey=VOX(2);
voxelsizez=VOX(3);

xvoxp=(xvox-ORIGIN(1))*VOX(1);
yvoxp=(yvox-ORIGIN(2))*VOX(2);
zvoxp=(zvox-ORIGIN(3))*VOX(3);

coordlist=[xvoxp yvoxp zvoxp];
numcoords=size(coordlist,1);