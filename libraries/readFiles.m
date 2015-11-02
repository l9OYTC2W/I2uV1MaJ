function files=readFiles(list_file)
if ~exist(list_file,'file')
	error(['Cannot find or read from ' list_file]);
end
fid=fopen(list_file);
c=0;
files=[];
while 1
   line = fgetl(fid);
   if ~isstr(line), break, end
   if ~isempty(deblank(line))
   if c==0 
      files=line;
      c=1;
   else
      files=str2mat(files,line);
   end
   end
end
files=deblankList(files);
fclose(fid);

