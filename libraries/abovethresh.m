% aboveThresh.m
% simple script to count voxels above a given threshold in a set of images
% by Adrien Desjardins
imageFiles=spm_get(Inf,'*.img','Please select images',pwd);
thresh=str2num(spm_input('Threshold:',1,'s'));
fprintf('----------------------------------------\n');
fprintf('Image | Number of Voxels Above Threshold\n')
fprintf('----------------------------------------\n');
for i=1:size(imageFiles)
	file=deblank2(imageFiles(i,:));
	image=readImage(file);	
	N=length(find(image > thresh));
	[s1 s2 s3]=parts(file);
	fprintf('%s\t\t%d\n',[s2 s3],N);
end
fprintf('----------------------------------------\n');
