function writeImage(im,imName,similarImage)
imName=deblank2(imName);
similarImage=deblank2(similarImage);
[DIM,VOX,SCALE,TYPE,OFFSET,ORIGIN,DESCRIP]=spm_hread(similarImage);
type=spm_type(TYPE);
fid=fopen(imName,'w');
if fid < 0
   error('Could not write image!');
end
fwrite(fid,im,type);
fclose(fid);
copyHeader(similarImage,imName);

