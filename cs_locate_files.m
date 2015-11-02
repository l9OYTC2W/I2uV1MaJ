function listing=cs_locate_files( filestr, n_min, n_max )
% Given a full or partial filename, with or without wildcards, returns full pathnames of files that fit criteria.
% Wildcards (asterisks) are permissible in both pathnames and filenames, but no other special characters.
% n_min and n_max are optional arguments; if provided, an error will be given if the number of files found is less than n_min or more than n_max.

if nargin<3
    n_max=Inf;
end

if nargin<2
    n_min=-Inf;
end

owd=pwd;
try
	[pth nm ext]=fileparts(filestr);
	if isempty(pth)
        %listing=spm_get('files',pwd,[nm ext]);
        temp = dir(fullfile(pwd, [nm, ext]));
        listing = strcat(pwd, filesep, str2mat(temp.name));
        clear temp;
	elseif isempty(findstr('*',pth))
        cd(pth);
        %listing=spm_get('files',pwd,[nm ext]);
        temp = dir(fullfile(pwd, [nm, ext]));
        listing = strcat(pwd, filesep, str2mat(temp.name));
        clear temp;
        cd(owd);
	else
        %Remember: in order to understand recursion, one must first understand recursion.
        %Probably not the best way of doing this, but simplest to understand.
        %NOTE: This loop is platform independent only in the sense that it will only parse Windows paths correctly in Windows, and Unix paths in Unix.
        %   (This should not be a problem for any normal usage, but FYI Windows will not parse a '/usr/local/center_scripts' type path correctly.)
        pth_stack={};
        pth_remainder=pth;
        while ~isempty(pth_remainder)
            [a b]=fileparts(pth_remainder);
            if isempty(b)
                pth_stack{end+1}=a;
                pth_remainder='';
            else
                pth_stack{end+1}=b;
                pth_remainder=a;
            end
        end
        %At this point, pth_stack should be a list of subdirectories, with the last element being either the root directory or the first subdirectory
        %relative to the current one.
        while isempty(findstr('*',pth_stack{end}))
            cd(pth_stack{end});
            pth_stack(end)=[];
        end
        %Now we should be in a directory with a wildcarded directory as the last entry in pth_stack; we don't care what else is in pth_stack now.
        dlist=dir(pth_stack{end});
        dlist=dlist([dlist.isdir]);
        pth_stack(end)=[];
        listing='';
        if ~isempty(dlist)
            for i=1:length(dlist)
                listing=strvcat(listing,cs_locate_files(fullfile(pwd,dlist(i).name,pth_stack{end:-1:1},[nm ext])));
            end     %recursion for loop
        end %if statement for empty pattern matches
    end %big if/elseif statement for number and placement of wildcards
catch
    listing='';
end
cd(owd);

if size(listing,1)>n_max
    error('cs_locate_files: Number of files found is greater than n_max');
end

if size(listing,1)<n_min
    error('cs_locate_files: Number of files found is fewer than n_min');
end