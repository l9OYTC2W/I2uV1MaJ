function imageFiles=loadFileList(direc_list_file,impattern,nsess,nscans)
% this function returns a structure containing a list of files
% for each session
% where:
% direc_list_file is the full path to a text file
% impattern is a wildcard like 'fsn*.img'
% nsess is the number of sessions
% nscans is a vector of length nsess with the number scans in each session
% imageFiles can be accessed as, e.g., imageFiles(session).file(1,:)

if ~exist(direc_list_file,'dir')   
   imDirecs=readFiles(direc_list_file);
else
   imDirecs=direc_list_file;
end
nimDirecs=length(imDirecs(:,1));
for i=1:nimDirecs
   str=fullfile(imDirecs(i,:),'/');
   if i==1
      temp=str;
   else
      temp=str2mat(temp,str);
   end
end
imDirecs=temp;
if nimDirecs ~= nsess
   error(['Number of directories and sessions (' num2str(nimDirecs) ') must be equal!']);
end
for sn=1:nsess
   nexpected=nscans(sn);
   direc=deblank2(imDirecs(sn,:));
   [imfiles,temp]=spm_list_files(direc,impattern);
   if isempty(imfiles)
      nfound=0;
   else
      nfound=length(imfiles(:,1));
   end
   if nfound ~= nexpected
      error(sprintf('Found %d files for directory %s but expected %d',nfound,direc,nexpected));
   end
   imfiles=[char(ones(size(imfiles,1),1)*direc) imfiles];
   if sn==1
      imageFiles=struct('file',imfiles);
   else
      imageFiles=[imageFiles struct('file',imfiles)];
   end
end	
