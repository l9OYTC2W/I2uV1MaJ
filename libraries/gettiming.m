function [] = getTiming(start_code, event_code, response_code, time_window, use_slice_code)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Author: Sean McGregor - September, 2001
%	 UBC NeuroImaging Lab
%	 smcgrego@physics.ubc.ca
%
%
% ***To use getTiming.m, copy the file from /opt/local/matlabScripts/libraries
%    into your working directory, edit the EDITABLE PARAMETERS section below, 
%    and save the file as the same name (getTiming.m).***
%
%
%INPUT: 	The following parameters are required as input to the function
%		getTiming.
%
%start_code:	the integer corresponding to the start time (ex: 99). 
%
%event_code:	the integer corresponding to the event of interest, defined in
%		the .CIR file (ex: 7).
%		
%response_code:	the integer corresponding to the response input, defined in the
%		.CIR file (ex: 53).
%
%time_window:	a matrix of two numbers defining the time interval (in seconds)
%		of an accepted response in the form [minTime maxTime]. For 
%		example, if responses between 100 and 1200 ms are to be accepted 
%		following the event of interest,then time_window should be set 
%		to [0.1 1.2].
%
%use_slice_code: a string containing either "yes" (or "y") or "no" (or "n"). Any
%		 upper or lower case combinations are accepted. If "yes", the 
%		 output variables will be slice code corrected. If "no", then the
%		 slice codes will not be used to correct for timing. 
%
%
%OUTPUT:	The following variables are saved in a .mat file called
%		"TimingVariables.mat". 
%
%timingVector_"Logfile": A matrix of one column, which contains the 
%			 timing vector (in sec) of the event of interest. The 
%	 		 "Logfile" part of the variable name indicates from which
%			 log file the data was calculated from.
% 
%intEvt_"Logfile":	A matrix containing two columns. Column one 
%			contains the event codes and response codes of interest, 
%			and column two contains the associated time stamps from
%			the log file (in sec). The "Logfile" part of the variable 
%			name indicates from which log file the data was calculated 
%			from.
%
%REACTION_TIME_"Logfile": a matrix of one column, containing the reaction 
%			  times. Reaction times are defined as the time 
%			  difference (in sec) between each successive pair 
%			  of event code and response code. The "Logfile" 
%			  part of the variable name indicates from which 
%			  log file the data was calculated from.
%
%		To load the variables into a matlab work space, ensure the 
%		matlab file is in the working directory, and type the command
%		"load TimingVariables" (without quotes) in the matlab prompt.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%% EDITABLE PARAMETERS - please edit the name of the file containing the 

%This textfile contains a list of .LOG files
%ex:	/broca/home/smcgrego/timing/G01_SZ04.LOG
%	/broca/home/smcgrego/timing/G01_SZ05.LOG
logFileList='logFileList.txt';
 
%%%%% END OF EDITABLE PARAMETERS


%%%%%no more changes needed after this line

%check to see if slice codes are used for timing
if strcmp(lower(use_slice_code),'yes') | strcmp(lower(use_slice_code),'y')
  use_slice_code=1;
elseif strcmp(lower(use_slice_code),'no') | strcmp(lower(use_slice_code),'n')
  use_slice_code=0;
else
  error('Invalid parameter %s. Please choose yes or no.\n',use_slice_code);
end

%return matrix of logfiles
if ~exist(logFileList)
  fprintf( '%s cannot be found. Please create the file first.\n',logFileList);
  return;
end
direcs=readFiles(logFileList);
s=size(direcs);   


%temporary read in one log file (change to loop of all log files later)
for i=1:s(1)

fprintf('Calculating timing vectors for log file %d ...\n',i);

%choose
logfile=deblank(direcs(i,:));

%read in the logfile
[event, code, time, flags] = readlog(logfile);

% define matrix for events and time for all events
a=[event,time];

%branch depending on whether or not slice codes are used in timing


if use_slice_code	%use slice codes in timing correction

  fprintf('Performing time correction using slice codes.\n');

  %find the start time
  start=find(event==start_code);
  if event(start+1)==1
    start=start+1;
    starttime=time(start(1));
  else
    %no slice code found
    starttime=time(start(1));
    fprintf('No slice code found. Using start code time.\n');
  end
  
  %identify indices with slice codes immediately after event of interest 
  tempind=find(event==event_code);
  tempind2=find(event(tempind+1)==1);
  tempind(tempind2)=tempind(tempind2)+1;
  tempind3=find(event==response_code);
  tempind=[tempind; tempind3];
  ind=sort(tempind);
  
  %make new matrix b using slice codes if present from ind
  b=a(ind,:);
  
  %find all event codes followed immediately by the desired response code within time window
  bcode=b(:,1);
  bcodeind=find((bcode(1:(length(bcode)-1))==event_code | bcode(1:(length(bcode)-1))==1) & bcode(2:length(bcode))==response_code);
 
  %Times with using slice codes
  b(bcodeind,:);
  
  %%%%%
  %creates index for both event and response codes
  bcodeind2=bcodeind+1;
  bcodeind3=[bcodeind;bcodeind2];
  bcodeind3=sort(bcodeind3);
  
else	%do not use slice codes in timing

  %find the start time
  start=find(event==start_code);
  starttime=time(start(1));

  % identify and remove the slice codes 
  %make new matrix b that does not include slice codes
  ind=find(event~=1);
  b=a(ind,:);

  %find all event codes followed immediately by the desired response code within time window
  bcode=b(:,1);
  bcodeind=find(bcode(1:(length(bcode)-1))==event_code & bcode(2:length(bcode))==response_code);
			
  %Times without using slice codes
  b(bcodeind,:);

  %%%%%
  %creates index for both event and response codes
  bcodeind2=bcodeind+1;
  bcodeind3=[bcodeind;bcodeind2];
  bcodeind3=sort(bcodeind3);
  
end

  %define matrix intEvt for events and times of event/responses of interest
  intEvt=b(bcodeind3,:);

  %check that reaction times fall within time window
  intEvtind=find((intEvt(2:2:(length(intEvt)),2)-intEvt(1:2:(length(intEvt)-1),2) >= time_window(1)) & ...
			(intEvt(2:2:(length(intEvt)),2)-intEvt(1:2:(length(intEvt)-1),2) <= time_window(2)) );
  intEvtind=intEvtind*2;
  intEvtind=sort([intEvtind; intEvtind-1]);
  intEvt=intEvt(intEvtind,:);
  if isempty(intEvt)
    error('No reaction times fall with the time window.');
  end
  
  %Calculate Timing Vector
  time1=intEvt(1:2:length(intEvt),2);
  timingVector=((time1-12)-starttime)/3;

  %calculate Reaction Time
  REACTION_TIME = zeros(length(intEvt),1);
  REACTION_TIME=intEvt(2:length(intEvt),2)-intEvt(1:length(intEvt)-1,2);
  REACTION_TIME=REACTION_TIME(1:2:length(REACTION_TIME));



%save variables with Log File identifiers
[dir file]=parts(logfile);
RTstring=['REACTION_TIME_' file];
iEstring=['intEvt_' file];
tvstring=['timingVector_' file];
%assignin('base',RTstring,REACTION_TIME);
%assignin('base',iEstring,intEvt);
eval([RTstring ' = REACTION_TIME']);
eval([iEstring ' = intEvt']);
eval([tvstring ' = timingVector']);
clear REACTION_TIME;
clear intEvt;
clear intEvtind;
clear timingVector;

fprintf('Timing vectors for log file %d completed.\n',i);

end

%save all timing variables to TimingVariables.mat file
save TimingVariables REACTION_TIME* intEvt* timingVector*
fprintf('Program completed. Timing vectors saved to TimingVariables.mat file.\n');

