function image=readImage(P)

%%%%%

% This function reads the image specified by the file name "P"
% into the 1-D array image.
%
% by Adrien Desjardins

%%%%%
P=deblank2(P);
if ~exist(P,'file')
	error(['file ' P ' does not exist!']);
end
[DIM,VOX,SCALE,TYPE,OFFSET,ORIGIN,DESCRIP] = spm_hread(P);
if strcmp(computer,'PCWIN')
   fid=fopen(P,'r','ieee-be');
else
   fid=fopen(P,'r');
end
image=fread(fid,prod(DIM),spm_type(TYPE))*SCALE;
fclose(fid);		
