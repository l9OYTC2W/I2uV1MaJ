function cs_aod_asciis
%generates ASCII files of timings for all .LOG files in the current directory

global csprefs;
events = str2mat('TRG_PR','NOV_OM','STD_OM');

addpath(fileparts(which('cs_aod_asciis')));

%P=spm_get('files',pwd,'*.LOG');

P = cs_list_files(pwd, '*.LOG', 'fullpath');

if isempty(P)
    error( 'No .LOG files found in beh directory' );
end

for i=1:size(P,1)
    [a b c]=fileparts(deblank(P(i,:)));
    logfile=[b c];
    goodlog=0;
    for j=1:2
        if length(logfile)>1 && strcmp(logfile(2),'C')  %pre-s1000
            if strcmp( num2str(j),logfile(1) )
                goodlog=1;
                for k=1:size(events,1)
                    event=deblank(events(k,:));
                    outfile=[event,'_',num2str(j),'.asc'];
                    makeASC_old('logFile',logfile,'TR',csprefs.tr,'inputFile','aod.cir','numSubtScans',csprefs.dummyscans,...
                        'eventName',event,'firstCode',99,'outputFile',outfile,'numSlices',29,'numScans',255,'noSlice','yes' );
                end %loop thru event types
                break;
            end %if statement testing run #
        else                                            %post-s1000
            if length(logfile)>7 && strcmp( num2str(j),logfile(8) )
                goodlog=1;
                for k=1:size(events,1)
                    event=deblank(events(k,:));
                    outfile=[event,'_',num2str(j),'.asc'];
                    makeASC_old('logFile',logfile,'TR',csprefs.tr,'inputFile','aod.cir','numSubtScans',csprefs.dummyscans,...
                        'eventName',event,'firstCode',99,'outputFile',outfile,'numSlices',29,'numScans',255,'noSlice','yes' );
                end %loop thru event types
                break;
            end %if statement testing run #
        end     %if statement testing s1000-ness
    end %loop thru digits 1-2 (aka possible run #s)
    if ~goodlog
        cs_log( ['cs_aod_asciis says: Useless .LOG file? Filename=',P(i,:)] );
    end
end %loop thru .LOG files