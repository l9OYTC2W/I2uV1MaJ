function newlist=deblankList(list)

%%%%%

% This script removes blank lines from the string array "list"

% by Adrien Desjardins

%%%%%

if isempty(list)
	newlist=[];
	return;
end
n=size(list,1);
first=1;
for i=1:n
   if ~isempty(deblank(list(i,:)))
      if first	
         tlist=list(i,:);
         first=0;			
      else
         tlist=str2mat(tlist,list(i,:));
      end
   end
end
newlist=tlist;