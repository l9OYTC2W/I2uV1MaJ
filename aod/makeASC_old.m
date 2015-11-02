function [minDiffSliceTime,maxDiffSliceTime,oevent,otime]=makeASC_old(varargin)

% makeASC is a function creates a .asc timing file from CIRC input and output files
% it is invoked using the syntax:
% [minDiffSliceTime,maxDiffSliceTime,event,time]=readEvents('var1',val1,'var2',val2,...)
% Here 'var1', 'var2', etc. are parameter names. The possible names as follows. Default 
% values are given in brackets.
%
%%%%%%%%%%%%%%%%%%%%%% the following are required: %%%%%%%%%%%%%%%%%%%%%%%%%
%
%		'numScans' 		number of scans before subtraction of the first few
%							- required (no default)
%
%		'eventName'		name of event of interest - required (no default) 
%
%		'logFile'		CIRC LOG file - required (no default)
%
%		'inputFile'		CIRC input file - required (no default)
%
%%%%%%%%%%%%%%%%%%%%%% the following are optional: %%%%%%%%%%%%%%%%%%%%%%%%%
%
% 		'numSlices'		number of slices per scan - required (29)
%
%		'outputFile'	name of .asc timing file - required (<eventName>.asc)
%
%		'numSubtScans'	number of scans to subtract from timing (4)
%
%		'sliceCode'		code sent every time a slice is collected (1)
%
%		'firstCode'		code of first event (99)
%
%		'numSessions'	number of sessions (1)
%
%		'noSlice'   	either 'yes' or 'no' - if 'yes' is chosen, timing will be
%							determined purely from the time stamp in the log file, not
%							from the slice codes. ('no')
%
%		'firstCodeNum'	If 'noSlice','yes' is selected, the default starting point
%							in each session is the last first code in that session. If
%							'noSlice','no' is selected, the starting point in each session
%							is the first slice code before the first "first code". In either
%							case, if there are more than one first codes, makeASC will
%							be print them out. If you'd like to specify a different starting
%							point, say, the second first code printed in the list, use
%							'firstCodeNum','2'. Otherwise, do not include this option.
%
%		'TR'				repetition time - this is only necessary
%							if 'noSlice','yes' is selected (3)
%
%%%%%%%%%%%%%%%%%%%%%% directions and comments: %%%%%%%%%%%%%%%%%%%%%%%%%
%
% Examples:
% [mindt,maxdt]=readEvents('eventName','newhit','logFile','s01_enc.log','inputFile','explmem.cir');
% [mindt,maxdt]=readEvents('numScans',315,'eventName','newhit','logFile','s01_enc.log','inputFile','explmem.cir','outputFile','newhit.asc')
%
% The examples above would create the timing file 'newhit.asc'. It is important to
% check the minimum and maxmimum time differences between slice codes. They should
% usually both be close to 0.1. We have occasionally encountered large differences
% (greater than 90) - such log files should probably not be used. To do this, type
% fprintf('Maximum difference: %g, Minimum difference: %g\n',maxdt,mindt);
% 
% by Adrien Desjardins
% November 2000
% UBC Neuroimaging Lab
% 
%%%%%%%%%%%%%%%%%%% no further changes needed %%%%%%%%%%%%%%%

minDiffSliceTime=[];
maxDiffSliceTime=[];
eventNum=[];
event=[];
time=[];

if mod(nargin,2)
   error('Wrong number of input parameters!');
end

% number of slices per scan
numSlices=29;
for i=1:2:nargin
   if strcmp(varargin{i},'numSlices')
      numSlices=varargin{i+1};
      if ischar(numSlices),numSlices=str2num(numSlices);end;
      break;
   end
end

% total number of scans
numScans='';
for i=1:2:nargin
   if strcmp(varargin{i},'numScans')
      numScans=varargin{i+1};
      if ischar(numScans),numScans=str2num(numScans);end;
      break;
   end
end

numSubtScans=4;
for i=1:2:nargin
   if strcmp(varargin{i},'numSubtScans')
      numSubtScans=varargin{i+1};
      if ischar(numSubtScans),numSubtScans=str2num(numSubtScans);end;
      break;
   end
end

% slice code
sliceCode=1;
for i=1:2:nargin
   if strcmp(varargin{i},'sliceCode')
      sliceCode=varargin{i+1};
      if ischar(sliceCode),sliceCode=str2num(sliceCode);end;
      break;
   end
end

% TR
TR=3;
for i=1:2:nargin
   if strcmp(varargin{i},'TR')
      TR=varargin{i+1};
      if ischar(TR),TR=str2num(TR);end;
      break;
   end
end

% first code
firstCode=99;
for i=1:2:nargin
   if strcmp(varargin{i},'firstCode')
      firstCode=varargin{i+1};
      if ischar(firstCode),firstCode=str2num(firstCode);end;
      break;
   end
end

useCustomFirstCodeIndex=0;
for i=1:2:nargin
   if strcmp(varargin{i},'firstCodeNum')
      useCustomFirstCodeIndex=1;
      cfci=varargin{i+1};
      if ischar(cfci),cfci=str2num(cfci);end;
      break;
   end
end

% event of interest
eventName='';
for i=1:2:nargin
   if strcmp(varargin{i},'eventName')
      eventName=varargin{i+1};
      break;
   end
end

% LOG file
logFile='';
for i=1:2:nargin
   if strcmp(varargin{i},'logFile')
      logFile=varargin{i+1};
      break;
   end
end

% output file
outputFile='';
for i=1:2:nargin
   if strcmp(varargin{i},'outputFile')
      outputFile=varargin{i+1};
      break;
   end
end

% input file
inputFile='';
for i=1:2:nargin
   if strcmp(varargin{i},'inputFile')
      inputFile=varargin{i+1};
      break;
   end
end

% calculate timing without slice codes (old method)?
noSlice='no';
for i=1:2:nargin
   if strcmp(varargin{i},'noSlice')
      noSlice=varargin{i+1};
      break;
   end
end
if strcmp(upper(noSlice),'YES')
   noSlice=1;
else
   noSlice=0;
end

% force only one run?
numSessions=1;
for i=1:2:nargin
   if strcmp(varargin{i},'numSessions')
      numSessions=varargin{i+1};
      if ischar(numSessions),numSessions=str2num(numSessions);end;
      break;
   end
end

if isempty(eventName)
   error('Must specify event name!');
end
if isempty(numSlices)
   error('Must specify number of slices!');
end
if isempty(numScans)
   error('Must specify number of scans!');
end
if isempty(logFile)
   error('Must specify log file!');
end
if isempty(inputFile)
   error('Must specify input file!');
end
if isempty(outputFile)
   outputFile=[eventName '.asc'];
end

% print welcome message
fprintf('\n* * * makeASC - version 1.7\n\n');

% parse circ file
if ~exist(inputFile,'file')
   error('Input file does not exist!');
end
fprintf('Parsing input file...');
[eventNum,timeWindow]=parseCirc(inputFile,eventName);
fprintf('done.\n');
if isempty(eventNum)
   error('Could not find event of interest!');
end

% check whether event and time were entered as parameters
event=[];
for i=1:2:nargin
   if strcmp(varargin{i},'event')
      event=varargin{i+1};
      break;
   end
end
time=[];
for i=1:2:nargin
   if strcmp(varargin{i},'time')
      time=varargin{i+1};
      break;
   end
end
if isempty(time) | isempty(event)
   fprintf('Reading log file...');
   [event, code, time, flags] = readlog(logFile);
   fprintf('done.\n');
end
oevent=event;
otime=time;

% expected number of slices
expectedSL=numSlices*numScans;

if numSessions > 1
   
   if length(time) < 2
      error('too few time points!');
   end      	
   
   % find maximum time differences - used to find sessional cut-offs
   [tmp1,tmp2]=sort(otime(2:length(otime))-otime(1:(length(otime)-1)));
   sessInds=tmp2(length(tmp2):-1:1);
   sessInds=[0;sessInds];
   sessInds(1:numSessions)=sort(sessInds(1:numSessions));
end

% loop over sessions
for rn=1:numSessions
   
   if numSessions > 1            
      
      fprintf('\nSession %d...\n',rn);
      
      % get remaining events
      
      if rn==numSessions
         lastInd=length(oevent);
      else
         lastInd=sessInds(rn+1);
      end
      
      event=oevent((sessInds(rn)+1):lastInd);
      time=otime((sessInds(rn)+1):lastInd);      
      
   end     
   
   % find first "sliceCode" before "firstCode"
   
   cind=find(event==firstCode);
   if isempty(cind)
      if noSlice
         sind=1;
      else	 
         error('Could not determine first code!');
      end         	
   else      
      
      if length(cind) > 1
         fprintf('%d instances of the first code (%d) found in this session at times:\n',length(cind),firstCode);
         for ci=1:length(cind)
            fprintf('\t%g\n',time(cind(ci)));
         end                  
      else
         fprintf('One instance of the first code (%d) found in this session.\n',firstCode);
      end
      
      if noSlice
         if useCustomFirstCodeIndex
            if cfci > 0 & cfci <= length(cind)
               fprintf(['Using first code number ' num2str(cfci) ' as the starting point.\n']);
					sind=cind(cfci);               
            else
               error('First code number is out of range!');
            end            
         else
            sind=cind(length(cind));
            if length(cind) > 1
            	fprintf('Using the last one (t = % g) as the starting point.\n',time(sind));
				end
         end                        
      else 
         if useCustomFirstCodeIndex
            if cfci > 0 & cfci <= length(cind)
               fprintf(['Using first code number ' num2str(cfci) '.\n']);
					sind=cind(cfci);               
            else
               error('First code number is out of range!');
            end            
         else
            fprintf('Using first code number 1.\n');
	         cind=cind(1);      
   	      sind=[];
         end           
         while cind > 1
            cind=cind-1;
            if event(cind) == sliceCode
               sind=cind;
               break;
            end   
         end         
         if isempty(sind)
            error('Could not determine slice code before first code!')      
         end         
         fprintf('Using the first slice code before the first one (t = % g) as the starting point.\n',time(sind));         
      end      
   end                     
   time=time(sind:length(time));
   event=event(sind:length(event));
   
   if ~noSlice 
      
      % check number of slice codes      
      indsSL=find(event==sliceCode);
      countedNumSlicesCodes=length(indsSL);
      
      % timing difference
      timeSL=time(indsSL);
      if length(timeSL) < 2
         error('Too few time points!');
      end
      timeDiff=timeSL(2:length(timeSL))-timeSL(1:(length(timeSL)-1));
      
      minDiffSliceTime=min(timeDiff);
      maxDiffSliceTime=max(timeDiff);
      
      if length(indsSL) > expectedSL
         fprintf('Warning! Too many slice codes: expected %d but found %d. Proceeding anyway...\n',expectedSL,countedNumSlicesCodes);
      elseif length(indsSL) < expectedSL
         fprintf('Warning! Expected %d slice codes but found %d. Proceeding anyway...\n',expectedSL,countedNumSlicesCodes);
      else      
         fprintf('Expected number of slice codes found (%d).\n',expectedSL);
      end
      
      % number slices and scans      
      numSL=[];
      numSC=[];
      for sn=0:numScans-1
         numSL=[numSL;[0:numSlices-1]'];
         numSC=[numSC;sn*ones(numSlices,1)];
      end
      tempinds=1:min(expectedSL,length(indsSL));
      temp=zeros(length(event),1)*NaN; temp(indsSL(tempinds))=numSL(tempinds); numSL=temp;
      temp=zeros(length(event),1)*NaN; temp(indsSL(tempinds))=numSC(tempinds); numSC=temp;
      
   end
   
   % find events of interest
   indsEV=[];
   for en=1:length(eventNum)
      indsEV=[indsEV;find(event==eventNum(en))];
   end
   if isempty(indsEV)
      error(['Event ' num2str(eventName) ' not found!']);
   end
   indsEV=sort(indsEV);
   
   % check timing conditions
   filtindsEV=[];
   if ~isempty(timeWindow)
      for in=1:length(indsEV)
         ind=indsEV(in);      
         t=0;
         t0=time(ind);
         outFound=0;
         while ind < length(event) & t < timeWindow.maxTime
            ind=ind+1;
            t=time(ind)-t0;
            % check time window			         
            if t >= timeWindow.minTime/1000 & t <= timeWindow.maxTime/1000
               if event(ind) == timeWindow.outCode,outFound=1;end;
            end         
         end
         if timeWindow.isnot,outFound=~outFound;end;
         if outFound,filtindsEV=[filtindsEV;indsEV(in)];end;      
      end
      indsEV=filtindsEV;
      if isempty(indsEV)
          indsEV= [ ];
         %error(['Event ' num2str(eventNum) ' not found after filtering!']);
      end
   end
   
   % create output file name
   if numSessions > 1
      [s1 s2 s3]=parts(outputFile);
      outFile=[s1 s2 '_run' num2str(rn) s3];   
   else
      outFile=outputFile;
   end      
   
   if noSlice
      % search for event without use of slice codes      
      tradTiming=[];      
      for en=1:length(indsEV)
         ind=indsEV(en);
         tradTiming=[tradTiming;(time(ind)-time(1)-numSubtScans*TR)/TR];
      end
      [s1 s2 s3]=parts(outFile);
      outFile=[s1 s2 '_noslice' s3];
      
      % write output file (no slice codes)
      fprintf('Writing file...');
      fidw=fopen(outFile,'w');
      if fidw < 0
         error('Could not open output file!');
      end
      for tn=1:length(tradTiming);
         fprintf(fidw,'%.3f ',tradTiming(tn));
      end
      fclose(fidw);
      fprintf(['wrote ' outFile '.\n']);         
      
   else                  
      % find slices
      timing=[];
      tradTiming=[];            
      for en=1:length(indsEV)
         ind=indsEV(en);
         % find nearest slices in time
         cind=indsEV(en);
         sind=[];
         while cind > 1
            cind=cind-1;
            if event(cind)==sliceCode
               sind=cind;
               break;
            end      
         end
         cind=indsEV(en);
         lind=[];
         while cind < length(event)
            cind=cind+1;
            if event(cind)==sliceCode
               lind=cind;
               break;
            end      
         end
         if isempty(sind) | isempty(lind)
            error('Could not find nearest slice!');
         end
         
         % interpolate
         interpSL=numSL(sind)+(numSL(lind)-numSL(sind))*(time(ind)-time(sind))/(time(lind)-time(sind));
         % slice code sent when RF pulse is applied, so add 0.5 to interpolate towards middle of slice
         tscans=numSC(sind)+(interpSL+0.5)/numSlices-numSubtScans;
         timing=[timing;tscans];   
      end
      
      fprintf('Writing file...');
      fidw=fopen(outFile,'w');
      if fidw < 0
         error('Could not open output file!');
      end
      for tn=1:length(timing);
         fprintf(fidw,'%.3f ',timing(tn));
      end
      fclose(fidw);
      fprintf(['wrote ' outFile '.\n']);      
   end
end
