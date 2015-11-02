function [lines,numLines]=readLines(infile,removeBlanks)

%%%%%

% This function reads lines from a text file and stores them in the
% string array "lines".
% syntax: [lines,numLines]=readLines(filename)
%%%%%

if ~exist(infile,'file')
   error(['File ' infile ' does not exist!']);
end
fid=fopen(infile);
c=0;
lines=[];
while 1
   line = fgetl(fid);
   if ~isstr(line), break, end
   if ~isempty(deblank(line))
      if c==0 
         lines=line;
         c=1;
      else
         lines=str2mat(lines,line);
      end
   end
end
fclose(fid);
numLines=size(lines,1);

