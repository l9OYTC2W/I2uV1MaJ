function str=lastPart(file)

% this function is now replaced by parts.m

ind=findstr(filesep,file);
if isempty(ind)
	str=file;
	return
end
ind=ind(ind ~= length(ind));
if isempty(ind)
	str=file;
	return	
else
	str=file((ind(length(ind))+1):length(file));	
end
	
	
