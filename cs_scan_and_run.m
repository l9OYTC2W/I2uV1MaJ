function cs_scan_and_run( prefs_file )

global csprefs;

start_dir=pwd;

addpath(fileparts(which('cs_scan_and_run')));

% find and run cs_prefs file
[pth nm ext] = fileparts( prefs_file );
addpath(pth);
eval(nm);
if ~exist(fullfile(csprefs.spm_defaults_dir,'spm_defaults.m'))
    error('spm_defaults.m file specified in csprefs.spm_defaults_dir not found');
end

%find subject directories and their dates of last modification
cd(csprefs.exp_dir);
listing=dir(csprefs.exp_dir);
inds=find([listing(:).isdir]);
sub_dirs={listing(inds).name};
dates={listing(inds).date};
inds=regexp(sub_dirs,csprefs.scandir_regexp);
inds=cs_good_cells(inds);
sub_dirs={sub_dirs{find(inds)}};
dates={dates{find(inds)}};

%get today's date
today=datevec(date);
today=today(1:3);

%really only have to run this once for all subs
try
	if ( csprefs.run_beh_matchup )
		cs_beh_matchup;
	end
catch
    err=lasterr;
    cs_error( 'cs_beh_matchup','',err );
end
    
for i=1:length(sub_dirs)
    attach={};
    cd(csprefs.exp_dir);
    stats_only=0;
    try
        sub=sub_dirs{i};
        mod=datevec(dates{i});
        mod=mod(1:3);
        if (all(today==mod)) %don't process folders created/modified today -- might still be downloading
            continue;
        end
        
        cd(sub);
        sub=pwd; %make sure we have full pathname
        
        %once in subject's directory, check for folders of images
        im_dirs=dir(sub);
		inds=find([im_dirs(:).isdir]);
		im_dirs={im_dirs(inds).name};
		inds=regexp(im_dirs,csprefs.rundir_regexp);
		inds=cs_good_cells(inds);
		im_dirs={im_dirs{find(inds)}};

        if (exist(fullfile(sub,'error.txt')))
            %don't try processing until error is cleared manually
            continue;
        elseif (exist(fullfile(sub,'pending.txt')) == 2)
            %must be waiting on beh data            
            if ( csprefs.run_stats  )
                stats_only=1;
                cs_stats( im_dirs );
                delete(fullfile(sub,'pending.txt'));
                if ( isfield(csprefs,'run_autoslice') && csprefs.run_autoslice )
                    attach=cs_autoslice;
                end
                
                if ( isfield(csprefs,'run_deriv_boost') && csprefs.run_deriv_boost )
                    cs_derivative_boost;
                end
            end
        elseif (exist(fullfile(sub,'cs_progress.txt')))
            %assume either everything is done or something went wrong
            continue;
        else
            %The check here was moved from right above the big if statement here... not sure if this is exactly the right place for it, but it'll do
            %until the next version of CS. Gets rid of multiple error messages of this type when auto-processing, though.
            if ( isempty( im_dirs ) )
                error(['No scan directories found in ',sub]);
            end
            
            %apparently no processing done yet
            if ( csprefs.dummyscans > 0 )
                cs_dummies( sub );
            end
            
            if ( csprefs.run_realign )
                for i=1:length(im_dirs)
                    cs_realign( im_dirs{i} );
                end
            end
            
            if ( csprefs.run_normalize )
                for i=1:length(im_dirs)
                    cs_normalize( im_dirs{i} );
                end
            end
            
            if ( csprefs.run_smooth )
                for i=1:length(im_dirs)
                    cs_smooth( im_dirs{i} );
                end
            end
            
            if ( csprefs.run_filter )
                for i=1:length(im_dirs)
                    cs_filter( im_dirs{i} );
                end
            end
            
			if ( csprefs.run_stats  )
                cs_stats( im_dirs );
                if ( isfield(csprefs,'run_autoslice') && csprefs.run_autoslice )
                    attach=cs_autoslice;
                end
                
                if ( isfield(csprefs,'run_deriv_boost') && csprefs.run_deriv_boost )
                    cs_derivative_boost;
                end
            end

        end
        
        cs_log(['CenterScripts ran successfully for ',sub]);
        if isfield(csprefs,'sendmail')
%             if csprefs.sendmail
%                 cs_email(csprefs.mailing_list,csprefs.smtp_server,csprefs.smtp_username,csprefs.smtp_password,csprefs.from_address,'CenterScripts successful run',csprefs.extended_from,['CenterScripts ran successfully for ',sub],attach);
%             end
        else
            cs_log(['CenterScripts ran successfully for ',sub],'mailtemp.txt');
            eval(['!mail ',csprefs.mailing_list,' < mailtemp.txt']);
            eval(['!cat mailtemp.txt >> ',csprefs.mailfile]);
            delete('mailtemp.txt');
        end
    catch
        beh_err='No behavioral data yet';
        err=lasterr;
        if stats_only && ~isempty(regexp(err,beh_err))
            continue;
        else
            cs_error('',sub,err);
        end
    end %try/catch statement
end %for loop thru subs

cd(start_dir);