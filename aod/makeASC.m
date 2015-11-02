function [timing] = makeASC(varargin)
%Eric Egolf
%Created for IOL CCNLAB
%Last Modified 8-20-02
%NOTE: This script is an adaption from a similar script written by Adrien  Desjardins for the UBC lab
	%--------------------------------------------------------------
	% This function returns the timing results from a circ log file according to various parameters(described below).
	% An Example function call: simpleMakeASC ( 'logfile','spts31a.log','TR',3,'subScans',4,'stim',[11;12;13;14],'firstCode',99,'timeWindow',timeWindow,'printResults','yes','outputFile','spts31a_targets','slices',30,'numScans',167);
	%----------------------------------------------------------------
	% Manditory Parameters:
	%	-logfile = This is the circ logfile that we are extracting data from
	%	-TR = TR time(3)
	%	-subScans = number of scans we subtract from due to magnetic instibility(4)
	%	-stim = The stim codes that we are intrested in([7])
	%	-firstCode = The stim code that tells us the experiment has started(99)
	%------------------------------------------------------------------
	% Optional Parameters: 
	%	-timeWindow = A structured array with fields; varnum, minTime, maxTime, isnot, outCode
	%		timeWindow only needs to be used when you are intrested in a stim code followed by another stim code
	%		the outCode is the followed by stim code.(ex timeWindow.outCode = 52) This script only uses
	%		fields, minTime,maxTime and outCode
	%	-printResults = Having this set to 'yes' displays on the screen the values of all the variables used. It is good to have
	%		it set to yes so you can make sure your input was correct
	%	-slices = The number of slices in one scan(30);
	%	-numScans = The total number of scans in an experiment
	%		(This number is only used by this script to determine what the expected number of total slices is, if it is not 
	%		used then the expected number of total scans is incorrect)
	%
	%-----------------------------------------------------------------------
	% OUTPUTS
	%	This function outputs 3 files. A .asc file a .diff file and an error.log file
	%	the .asc contains timing data, the .diff is output only if a timeWindow is specified and
	%	contains the difference between the outCode and the stim code. The outputFile parameter specifies
	%	where the .asc and .diff file will go. An error.log file is output in the directory where the function
	%	was called 
	%
	%-------------------------------------------
	%Marker for each time this function is called
	%-------------------------------------------
disp('*********************************************************************');
	
	
	
	
	
	%-------------------------------------------
	%initialize variables
	%-------------------------------------------
timeCounter= 1;
timeZero = 0;
numberOfScans=0;
numberOfStarts=0;
foundFirstCode=0;
timing = zeros(1,1);
bin= zeros(1,256);
printResults = 'no';
stimCodeFirst = 0;
eventCodeZero = 0;



	%-------------------------------------------
	%Pull out arguments from the varargin parameter
	%-------------------------------------------
if mod(nargin,2)
	error('Wrong number of input parameters!');
end

%num of scans to subtract
for i=1:2:nargin
	if strcmp('subScans',varargin{i})
		subScans = varargin{i+1};
		if ischar(subScans),subScans=str2num(subScans);end;
		break;
	end
end

%TR
for i=1:2:nargin
	if strcmp('TR',varargin{i})
		TR = varargin{i+1};
		if ischar(TR),TR=str2num(TR);end;
		break;
	end
end

%stim code
for i=1:2:nargin
	if strcmp('stim',varargin{i})
		stim = varargin{i+1};

	end
end

%firstCode
for i=1:2:nargin
	if strcmp(varargin{i},'firstCode')
		firstCode=varargin{i+1};
		if ischar(firstCode),firstCode=str2num(firstCode);end;
		break;
	end
end


%logfile
for i=1:2:nargin
	if strcmp(varargin{i},'logfile')
		logfile=varargin{i+1};
		if ~exist(logfile,'file')
			error('No such logfile');
		end
	
	end
end

%Time Window
timeWindow = [];
for i=1:2:nargin
	if strcmp(varargin{i},'timeWindow')
		timeWindow=varargin{i+1};
		break;
	end
end

%printResults
for i=1:2:nargin
	if strcmp(varargin{i},'printResults')
		printResults=varargin{i+1};
		break;
	end
end

%outputFile
outputFile = 'temp.asc';
outputFile2= 'temp.diff';
for i=1:2:nargin
	if strcmp(varargin{i},'outputFile')
		outputFile=varargin{i+1};
		outputFile2= strcat(outputFile,'.diff');
		outputFile=strcat(outputFile,'.asc');
		break;
	end
end

%slices
slices=30;
for i=1:2:nargin
	if strcmp(varargin{i},'slices')
		slices=varargin{i+1};
		if ischar(slices),slices=str2num(slices);end;
		break;
	end
end

%number of scans
numScans=194;
for i=1:2:nargin
	if strcmp(varargin{i},'numScans')
		numScans=varargin{i+1};
		if ischar(numScans),numScans=str2num(numScans);end;
		break;
	end
end



	%-------------------------------------------
	%Make sure all nesesary arguments were extracted from varargin
	%-------------------------------------------
if isempty(subScans)
	error('Must specify number of scans to subtract');
end
if isempty(TR)
	error('Must specify TR');
end
if isempty(stim)
	error('Must specify stim codes');
end
if isempty(firstCode)
	error('Must specify firstCode');
end
if isempty(logfile)
	error('Must specify log file');
end
if isempty(timeWindow);
	disp('No Time Window Specified');
else
	disp('Timing Window Specified');
end








	%---------------------------------------------
	%The function call to read log extracts information from the circ logfile
	%--------------------------------------------
[event, code, time, flags] = readlog(logfile);




	%---------------------------------------------
	%This code cycles through all the event codes and extracts timing information
	%Since matrix's can't be zero indexed, a zero event code is ignored, this
	%is noted in the error.log
	%--------------------------------------------	
for i=1:size(event)
	if event(i) == 0
		eventCodeZero = 1;
	else
		bin(event(i)) = bin(event(i)) + 1;
	
		
		if (event(i) == firstCode) & (foundFirstCode==0)		
			timeZero=time(i);
			foundFirstCode = 1;
		end
	
			%---------------------------------
			%If we find a matching stim code in events
			%---------------------------------
		if find(event(i) == stim)
			if foundFirstCode==0
				stimCodeFirst = 1;
			end
				%------------------------------------------
				%Different Proceedures for having a timeWindow and not having a timeWindow
				%------------------------------------------
			if (isempty(timeWindow))
				timing(timeCounter)=round(( ( (time(i) - timeZero ) - (subScans*TR) ) / TR)*10000)/10000;
				timeCounter=timeCounter+1;		
			else
			
				for j=i:size(event)
					if(find(event(j) == timeWindow.outCode))
						if ( ((time(j)-time(i))*1000) <= timeWindow.maxTime)  &  ( ((time(j)-time(i))*1000) >= timeWindow.minTime )
							timing(timeCounter)=round(( ( (time(i) - timeZero ) - (subScans*TR) ) / TR)*10000)/10000;
							timingDiffSec(timeCounter)=  round( (time(j)-time(i))*10000)/10000;
							timingDiffScans(timeCounter)=round(( (time(j) - time(i)) / TR)*10000)/10000;
							timeCounter=timeCounter+1;
						end	
						break;
					%if
					end
				%for
				end	
			%if else	
			end
		%if
		end
	%if
	end	
%for
end





	%---------------------------------------------
	%This Block of Code Displays information and parameters that pertain to the logfile and the 
	%timing extracted from the logfile. It is mostly for use as a diagnostic tool. 
	%--------------------------------------------



if strcmp(printResults,'yes')
	disp(' ');
	disp('Number of Slices');
	disp(slices);
	disp('FirstCode found at time');
	disp(timeZero);	
	disp('Num of Scans to Subtract');
	disp(subScans);
	disp('TR Time =')
	disp(TR);
	disp('Stim Codes are');
	disp(stim);
	disp('First Code =');
	disp(firstCode);
	disp('Log File is');
	disp(logfile);
	disp(' ');
	disp('Output File is');
	disp(outputFile);
	disp(' ');
	totalSlices=slices*numScans;
	line = ['Total number of slices(Should be ', int2str(totalSlices) ,')'];
	disp(line);
	disp(bin(66));
	disp('Number of first codes(Should be 1)')
	disp(bin(firstCode));
	disp(' ');
	
		%Displays summary of logfile
	disp('Stim Code Summary for Logfile');
	for i=1:256
		if bin(i) > 0
			line = [int2str(i),'      ',int2str(bin(i))];
			disp(line);
		end
	end
	disp(' ');
end



	%------------------------------------------------
	%Format Timing
	%Print to files
	%------------------------------------------------
timing = strrep(mat2str(timing),']','');
timing = strrep(timing,'[','');
disp('Timing is');
disp(timing);
disp(' ');

fid=fopen(outputFile,'w');
fprintf(fid,timing);
fclose(fid);

if ~isempty(timeWindow)
	timingDiffScans = strrep( mat2str(timingDiffScans) ,']','');
	timingDiffScans = strrep( timingDiffScans , '[' , '' );
	disp('Followed By Code is');
	disp(timeWindow.outCode);
	disp('Max time window is');
	disp(timeWindow.maxTime);
	disp('Min time window is');
	disp(timeWindow.minTime);
	disp('Actual difference between event and code is');
	disp(timingDiffScans);
	
	fid=fopen(outputFile2,'w');
	fprintf(fid,timingDiffScans);
	fclose(fid);
end
	

	
	
	
	
	
	
	%------------------------------------------------
	%Display Warning Messages and save them to error.log
	%------------------------------------------------
errors=0;
errorStatus = '';
if stimCodeFirst == 1	
	disp(' ');
	disp('!!!!!!!!!!!!!!!!!WARNING!!!!!!!!!!!');
	disp('Found Stim code before first code, manualy check circ log file');
	disp(' ');
	
	errorStatus = strcat(errorStatus,'*****Stim Codes found before firstcode, manualy check cir log file\n');		
	errors = 1;

end
if eventCodeZero == 1	
	disp(' ');
	disp('!!!!!!!!!!!!!!!!!WARNING!!!!!!!!!!!');
	disp('Event Code Zero found in circ log file, but not used');
	disp(' ');
	
	errorStatus= strcat(errorStatus,'*****Event Code Zero found in circ log file, but not used\n');		
	errors =1;

end
if(bin(firstCode) > 1)
	disp(' ');
	disp('!!!!!!!!!!!!!!!!!WARNING!!!!!!!!!!!');
 	disp('There are more than one start codes for this logfile');
 	disp('The timing data will be output with the assumption that the first code is the correct one.');
 	disp('It is strongly recomended that you double check the results by hand');
	disp(' ');
	
	errorStatus= strcat(errorStatus,'*****There are more than one start codes in logfile,(actual number_', int2str(bin(firstCode)),')\n');
	errors=1;

end
if(bin(66) ~= totalSlices)
	disp(' ');
	disp('!!!!!!!!!!!!!!!!WARNING!!!!!!!!!!!!!!!');
	disp('The expected number of slices does not match the actual number of slices');
	disp('This could be for a number of reasons');
	disp('1. It is off by one slice. Then it is vapp''s refresh rate(Nothing to worry about)'); 
	disp('2. The are no slice codes. Then the first start code was used(Nothing to worry about)');
	disp('3. There are many more or less slice codes than expected(Manually check circ logfile)');
	disp(' ');
	if abs(totalSlices - bin(66)) > 1
		
		errorStatus= strcat(errorStatus,'*****Number of actual slice codes does not match number of expected slice codes(found_', int2str(bin(66)), ' expected_',int2str(totalSlices),')\n');
		errors=1;
	end
end

if errors == 1
	fid=fopen('error.log','a');
	line = ['\n*********\nEvent ', outputFile,'\n'];
	fprintf(fid,line);
	fprintf(fid,errorStatus);
	fclose(fid);
end


