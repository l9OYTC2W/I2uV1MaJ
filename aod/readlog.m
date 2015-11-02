function [event, code, time, flags] = readlog(infile);

%[event, code, time, flags] = readlog(infile) - read in data from ERPSS logfile
%
%Inputs
%  infile	pathname of input logfile
%
%Outputs
%  event	event codes
%  code		condition codes
%  time		time of events in seconds 
%  flags	flags
%
%  by Joseph Dien (2/99)
%  University of California, Davis
%  jdien@marzen.ucdavis.edu  


logFID = fopen(infile,'r','ieee-le');
if (logFID == -1)
        error(['Error opening logfile: ' infile]);
end;

fseek(logFID, 0, 'bof');
if (fread(logFID, 1, 'ushort') ~= 43605)	%check if data is big-endian
	fclose(logFID);
	logFID = fopen(infile,'r','ieee-be');
end;

fseek(logFID, 0, 'eof');
fsize = ftell(logFID);
fseek(logFID, 0, 'bof');

[lgh_s] = fread(logFID, 7, 'ushort');
lgh_tcomp = fread(logFID, 1, 'short');
speriod = fread(logFID, 1, 'long');
uctime = fread(logFID, 1, 'long');
[lgh_subdesc] = fread(logFID, 64, 'uchar');
[lgh_expdesc] = fread(logFID, 64, 'uchar');
[lgh_ename] = fread(logFID, 64, 'uchar');
[lgh_hname] = fread(logFID, 64, 'uchar');
[lgh_filedesc] = fread(logFID, 64, 'uchar');
[lgh_dummy] = fread(logFID, 168, 'uchar');
subdesc = setstr(lgh_subdesc);
filedesc = setstr(lgh_filedesc);
expdesc = setstr(lgh_expdesc);
ename = setstr(lgh_ename);
hname = setstr(lgh_hname);

event = [];
time = [];
flags = [];
code = [];

while (ftell(logFID) ~= fsize)
	event = [event; fread(logFID, 1, 'ushort')];
	time = [time; (fread(logFID, 1, 'long')/speriod)];
	flags = [flags; fread(logFID, 1, 'uchar')];
	code = [code; fread(logFID, 1, 'uchar')];
end;

fclose(logFID);
