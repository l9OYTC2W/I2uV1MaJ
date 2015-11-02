function [str1,str2,str3]=parts(file)

file=deblank2(file);
if isempty(file)
	str1=[];
	str2=[];
	str3=[];
end

ind=findstr(filesep,file);
if isempty(ind)
	str1=file;
	str2=[];		
else
	lind=ind(length(ind));
	str1=file(1:lind);
	if lind == length(file)
		str2=[];
	else
		str2=file(lind+1:length(file));	
	end
end

if isempty(str2) & ~isempty(str1)
	str2=str1;
	str1=[];
end
ind=findstr('.',str2);
if isempty(ind) | length(str2)==1 
	str3=[];
else
	lind=ind(length(ind));
	str3=str2(lind:length(str2));	
	if lind==1
		str2=[];
	else
		str2=str2(1:lind-1);
	end		
end


	
