function timings=cs_eprime_asciis( file, event, outputfile, convertToNumeric)


if (~exist('outputfile', 'var'))
    outputfile = '';
end

if (~exist('convertToNumeric', 'var'))
    convertToNumeric = 1;
end

if event(end)~=':'
    event(end+1)=':';
end

file = deblank(file);

myfid=fopen(file);
if myfid==-1
    error(['cs_eprime_asciis could not open file',file]);
end

timings = {};
myline=fgetl(myfid);
linenum=1;
while ischar(myline)
    if ~isempty(regexp(myline,event))
        %f=sscanf(myline,'%*s%f');
        f = strtrim(regexprep(myline, event, ''));
        timings{end + 1} = f;
        %         if length(f)==1
        %             timings{end + 1} = f;
        %         elseif length(f)>1
        %             error(['Error? Perhaps... more than one numeric value found in line ',num2str(linenum)]);
        %         end
    end

    myline=fgetl(myfid);
    linenum=linenum+1;
end

fclose(myfid);

timings = char(timings);

if (convertToNumeric == 1)
    timings = str2num(timings);
    timings = timings(:)';
end

if (~isempty(outputfile))
    dlmwrite(outputfile,timings,'\t');
end