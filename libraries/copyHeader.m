function copyHeader(img1,img2,customDescription,scale)
[s1 s2 s3]=parts(img2);
hfile2=[s1 s2 '.hdr'];
[DIM,VOX,SCALE,TYPE,OFFSET,ORIGIN,DESCRIP] = spm_hread(img1);
if nargin < 3
	customDescription=DESCRIP;
end
if nargin < 4
	scale=SCALE;
end
spm_hwrite(hfile2,DIM,VOX,scale,TYPE,OFFSET,ORIGIN,DESCRIP);


