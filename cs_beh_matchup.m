function cs_beh_matchup

global csprefs;

progFile=fullfile(pwd,'cs_progress.txt');
cs_log( ['Beginning cs_beh_matchup for ',pwd], progFile );

digits_list=sort(csprefs.digits);
digits_list=digits_list(end:-1:1);

% replaced by function cs_file_listing
% eval(['!ls -1 ', csprefs.beh_queue_dir, ' > ', csprefs.beh_queue_dir, '.file_listing_temp.txt']);
% listing=[csprefs.beh_queue_dir,'.file_listing_temp.txt'];
% files=textread(listing, '%s');
% %really files OR folders, but whatever
% eval(['!rm ',csprefs.beh_queue_dir,'.file_listing_temp.txt']);

% beh_files=cs_file_listing(csprefs.beh_queue_dir);
beh_files=dir(csprefs.beh_queue_dir);
beh_files={beh_files(:).name};
inds=find(~strcmp(beh_files(:),'.') & ~strcmp(beh_files(:),'..'));
beh_files={beh_files{inds}};
if ( isempty(beh_files) )
    return;
end

for i=1:length(beh_files)
    myfile=beh_files{i};
    [starts ends]=regexp(myfile,'\d+');
    if (isempty(starts))
        cs_log(['Non-fatal error: File/folder ',myfile,' in behavioral queue does not contain a number string for matchup.']);
        continue;
    end
    sizes=ends-starts+1;
    maxsize=max(sizes);
    if ( length(find(sizes==maxsize)) > 1 )
        cs_log(['Non-fatal error: File/folder ',myfile,' in behavioral queue contains multiple numerical tokens of the same length.']);
        continue;
    end
    
    dig_to_match=find(digits_list<=maxsize);
    if ( isempty(dig_to_match) )
        cs_log(['Non-fatal error: File/folder ',myfile,' in behavioral queue does not contain enough contiguous digits for matchup.']);
        continue;
    end
    
    dig_to_match=digits_list(dig_to_match(1));
    queue_num_str=myfile( (ends(find(sizes==maxsize)) - dig_to_match + 1 ):(ends(find(sizes==maxsize))) );
    
%     scan_listing=str2mat(cs_file_listing(csprefs.exp_dir));
%     scan_listing_ind=regexp(scan_listing,csprefs.scandir_regexp);
%     for j=1:length(scan_listing_ind)
%         scan_listing_ok(j)=~isempty(scan_listing_ind{j});
%     end
%     scan_listing=scan_listing(find(scan_listing_ok),:);

    scan_listing=dir(csprefs.exp_dir);
	inds=find([scan_listing(:).isdir]);
	scan_listing={scan_listing(inds).name};
	inds=regexp(scan_listing,csprefs.scandir_regexp);
	inds=cs_good_cells(inds);
	scan_listing=str2mat(scan_listing{find(inds)});
    
    scan_listing_match=[];
    for j=1:size(scan_listing,1)
        [starts ends]=regexp(scan_listing(j,:),'\d+');
        if (isempty(starts))
            continue;
        end
        sub_num=scan_listing(j,starts(end):ends(end));
        if (strcmp(sub_num((end - dig_to_match + 1):end),queue_num_str))
            scan_listing_match=[scan_listing_match;j];
        end
    end
    
    if ( isempty(scan_listing_match) )
        cs_log(['Non-fatal error: File/folder ',myfile,' in behavioral queue did not find matching scan folder.']);
        continue;
    elseif ( length(scan_listing_match) > 1 )
        cs_log(['Non-fatal error: File/folder ',myfile,' in behavioral queue found multiple matching scan folders.']);
        continue;
    end
    
    full_myfile=fullfile(csprefs.beh_queue_dir,myfile);
    full_scan_listing=fullfile(csprefs.exp_dir,scan_listing(scan_listing_match,:));
    new_full_myfile=fullfile(csprefs.exp_dir,deblank(scan_listing(scan_listing_match,:)),myfile);
    full_beh=fullfile(csprefs.exp_dir,deblank(scan_listing(scan_listing_match,:)),'beh');
    eval(['!mv ',full_myfile,' ',full_scan_listing]);
    disp(['!ln -s ',new_full_myfile,' ',full_beh]);
    eval(['!ln -s ',new_full_myfile,' ',full_beh]);
end