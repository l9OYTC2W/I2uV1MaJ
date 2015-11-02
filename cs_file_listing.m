function files=cs_file_listing( dir_to_list )
% returns a cell array of all files and folders in a directory (excluding . and ..)

error('Outdated function cs_file_listing... use built-in Matlab commands instead.');

% if ( dir_to_list(end) ~= '/' )
%     dir_to_list(end+1) = '/';
% end
% 
% tfile=tempname;
% 
% eval(['!ls -1 ', dir_to_list, ' > ', tfile]);
% files=textread(tfile, '%s');
% %really files OR folders, but whatever
% eval(['!rm ',tfile]);