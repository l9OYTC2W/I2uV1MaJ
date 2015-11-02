function str=headerFile(file)
	if length(file) < 4
		str=[];
		return
	end
	tailstr=file(length(file)-3:length(file));
	if ~strcmp(tailstr,'.img')
		str=[];
		return
	else
		str=[file(1:(length(file)-4)) '.hdr'];
	end
