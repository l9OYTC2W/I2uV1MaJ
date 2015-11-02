function listing=locate_file( filestr )
%--------------------------------------
% Given a full or partial filename, with or without wildcards, returns full pathname to a single file that fits criteria.
% If 0 or 2+ files are found, errors (although this behavior can be easily modified to fit other circumstances).
% NOTE: Still can't do wildcards in pathnames, ONLY in filenames.

[pth nm ext]=fileparts(filestr);
if ~isempty(pth)
    owd=pwd;
    cd(pth);
    targ_dir=pwd;
    cd(owd);
else
    targ_dir=pwd;
end

%listing=spm_get('files',targ_dir,[nm ext]);
listing = cs_list_files(targ_dir, [nm ext], 'fullpath');
if size(listing,1)==0
    error(['No files found that match: ',filestr]);
elseif size(listing,1)>1
    error(['Too many files found that match: ',filestr]);
end