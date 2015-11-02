function str=deblank2(instr)

%%%%%

% This script removes blanks and tabs at the beginning and end of the string "instr"
% by Adrien Desjardins

%%%%%

if isempty(instr)
	str=[];
	return
end
temp1=deblank(instr);
if isempty(temp1)
	str=[];
	return
end
temp2=deblank(temp1(length(temp1):-1:1));
if isempty(temp2)
	str=[];
	return
end
str=temp2(length(temp2):-1:1);

% remove tabs
tind=1;
while tind(1) == 1
   tind=findstr(char(9),str);
   if isempty(tind)
      tind=0;
   else
      if length(str) > 1
         str=str(2:length(str));
      else
         str=[];
      end      
   end;
end