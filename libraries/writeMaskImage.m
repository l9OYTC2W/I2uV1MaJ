function check=writeMaskImage(voxels,filename,similarImage)

%%%%% function to create a mask image, given a list of voxels and a similar image

if ~exist(similarImage)
   check=0;
   return
end

[DIM,VOX,SCALE,TYPE,OFFSET,ORIGIN,DESCRIP] = spm_hread(similarImage);

roi_im=zeros(prod(DIM),1);
roi_im(voxel2image(similarImage,voxels))=1;
fid=fopen(filename,'w');
if fid < 0
	check=0;
	return;
end
fwrite(fid,roi_im,spm_type(TYPE));
fclose(fid);

copyHeader(similarImage,filename); 
check=1;