function [allfiles,directories,numFiles]=getFiles(matfile,impattern)
if nargin == 0 
	% default values
	P = spm_get(1, 'SPM.mat','Please select SPM.mat file');
	load(P);
	impattern=spm_input('image pattern',1,'s');
else
	load(matfile);
end
nsess=length(Sess);
numFiles=zeros(1,length(Sess));
c=0;
for i=1:nsess
	file=VY(c+1).fname;	
	c=c+length(Sess{i}.row);
	[direc,temp]=parts(file);
	[files,temp]=spm_list_files(direc,impattern);
	if isempty(files)
           error('No files match criteria!');
        end 
        files=[char(ones(size(files,1),1)*direc) files];       
        numFiles(i)=size(files,1);
	if i==1 
		directories=direc;
		allfiles=files;
	else
		directories=str2mat(directories,direc);
		allfiles=str2mat(allfiles,files);
	end
end
