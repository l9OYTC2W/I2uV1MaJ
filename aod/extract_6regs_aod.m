%-----------------------------------------
	% Variables that can be modified to change subject or to change events
	%-----------------------------------------
	% ex
	% sub_list = str2mat('s14','s16');
	% events = str2mat('targets','novels');
	%-----------------------------------------
sub_list = str2mat('s117');
%sub_list = str2mat('s321','s326','s327','s328','s330','s332','s333','s349','s353','s355','s356','s358','s359','s368','s376','s378','s385','s389','s390');
events = str2mat('TRG_PR', 'NOV_OM','STD_OM','TRG_OM','NOV_PR','STD_PR');


	
	%-----------------------------------------
	% Variables that need to be modified for different experiments
	%-----------------------------------------
	% ex
	% num_of_runs = 2;
	% ex_dir = '/whitney/data2/ap3/';
	% experiment = 'ap3';      		used for the logfile naming convention
	% inputFile = 'audp3a2.cir';
	% images_located = 'p3s1'; 		used to find out how many scans there are
	%-----------------------------------------

num_of_runs = 2;
ex_dir = '/shasta/data4/aod_3t/';
experiment = 'ap3';
inputFile = 'aod.cir';
images_located = 'aods1';


	
	%-----------------------------------------
	% Other Parameters(only change if you know what you are doing)
	%-----------------------------------------
	% ex
	% TR = 3;
	% slices = 30;
	% printResults='yes';
	% firstCode = 99;
	% subScans = 4;
	%-----------------------------------------
TR = 1.5;
slices = 29;
printResults='yes';
firstCode = 99;
subScans = 6;	
	

	%-----------------------------------------
	%Gets number of subjects in list and number of events in list
	%-----------------------------------------
num_of_sub = size(sub_list);
num_of_sub = num_of_sub(1);
event_length = size(events);
event_length = event_length(1);


for i=1:num_of_sub
	
		%-------------------------------------------------------
		%Get subject number
		%Get number of scans for that subject
		%-------------------------------------------------------
	sub_num1 = strrep(sub_list(i,:),'s','')
	sub_num = sub_list(i,:);
	sub_dir = strcat(ex_dir,sub_num,'/beh/');
	disp(['sub_dir: ', sub_dir]);
	eval(['!rm ', sub_dir,'*.asc']); 
	scan_dir = strcat(ex_dir,sub_num,'/',images_located,'/');
	scan_listings = ['ls ' , scan_dir , images_located , '*.img | wc -l'];
	eval(scan_listings);
	numScans = 249;
		
	
	
	
		%-------------------------------------------------------
		%Find out what circ logfile to use
		%-------------------------------------------------------
	for k=1:num_of_runs
	
		switch k
			case 1
				letter = '1';
				letter1 = 'a';
			case 2
				letter = '2';
				letter1 = 'b';
			case 3
				letter = '3';
				letter1 = 'c';
			case 4
				letter = '4';
				letter1 = 'd';
			otherwise
				error('Script not made to handle that many blocks');
		end
		
		%--------------------------------------------
		%CHANGE LOGFILE NAMING CONVENTION HERE (it maybe necessary to change case statement above if letters are not used to denote runs)
		%---------------------------------------------
        logfile = [sub_dir,letter,'C',sub_num1,'AOD','.LOG'];   
		disp(logfile);
		
		
		
		
		
		
			%-------------------------------------------------------
			% Parse and Concatinate variables to pass informtion to makeASC script
			%-------------------------------------------------------
		for j=1:event_length
			event = deblank(events(j,:));
            outputFile = [sub_dir,event,'_',deblank(sub_num),'_', strrep(letter,'C',''),'.asc'];
			[varnum,timeWindow]=parseCirc(inputFile,event);
			if isempty(timeWindow)
				[timing] = makeASC_old ( 'logFile',logfile,'TR',TR,'inputFile',inputFile,'numSubtScans',subScans,'eventName',event,'stim',varnum,'firstCode',99,'printResults',printResults,'outputFile',outputFile,'slices',slices,'numScans',numScans,'noSlice', 'yes');
			else
				[timing] = makeASC_old ( 'logFile',logfile,'TR',TR,'inputFile',inputFile,'numSubtScans',subScans,'eventName',event,'stim',varnum,'firstCode',99,'printResults',printResults,'outputFile',outputFile,'slices',slices,'numScans',numScans, 'noSlice', 'yes', 'timeWindow',timeWindow);
			
			end
			
			timingLog = [event,letter,'.txt'];
			fid=fopen(timingLog,'a');
			strcat(timing,'\n');
			fprintf(fid,[logfile,'  ']);
			fprintf(fid,strcat(timing,'\n'));
			fclose(fid);
		end

		
	end
	listing = ['ls ',sub_dir];
	eval(listing);
end
%cd 

