function cs_log( str, file, nodate )

if ( nargin < 2 )
    file='/export/mialab/users/salman/BSNIP/SubjectData_spm12/cs_log.txt';
end

if ( nargin < 3 )
    nodate=0;
end

newline = sprintf('\n');

if ( str(end) ~= newline(1) )
    str(end+1) = newline(1);
end

if ~nodate
    str=[datestr(now),' -- ',str];
end

disp(str(1:end-1));
myfid=fopen(file,'a');
if ( myfid == -1 )
    error( ['Call to fopen() with filename ',file,' failed.'] );
end

fprintf(myfid,'%s',str);
fclose(myfid);