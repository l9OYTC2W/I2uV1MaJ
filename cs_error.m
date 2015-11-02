function cs_error( csfile, sub, errstr )
%error handling for cs_run_all and cs_scan_and_run in one location

global csprefs;

cookie=0;

if strcmp(csfile,'cs_beh_matchup')
    email_subject='CenterScripts error';
    message='CenterScripts error during behavioral data matchup';
    if ~isempty(errstr)
        message=[message,sprintf('\n\nError message:\n%s',errstr)];
    end
    message=[message,sprintf('\n\nCurrent directory:\n%s',pwd)];
    cs_log( ['CenterScripts error in cs_beh_matchup; see ',csprefs.errorlog,' for details.'] );
elseif ~isempty(regexp(errstr,'No behavioral data yet'))
    email_subject='CenterScripts awaiting beh data';
    message=['CenterScripts still awaiting behavioral data for ',sub];
    cs_log( ['CenterScripts still awaiting behavioral data for ',sub] );
else
    email_subject='CenterScripts error';
    if ~isempty(csfile)
        message=['CenterScripts error in ',csfile];
    else
        message='CenterScripts general error';
    end
    if ~isempty(sub)
        message=[message,' while processing ',sub];
    end
    cs_log( [message,'; see ',csprefs.errorlog,' for details.'] );
    if ~isempty(errstr)
        message=[message,sprintf('\n\nError message:\n%s',errstr)];
    end
    message=[message,sprintf('\n\nCurrent directory:\n%s',pwd)];
    %cookie stuff here
    if ~isempty(sub)
        try
            old_dir=pwd;
            cd(sub);
            cs_log(['CenterScripts processing suspended until error is fixed; see ',csprefs.errorlog,' for full error information.'],'error.txt');
            cd(old_dir);
            cookie=1;
        end
    end
            
end

cs_log( [message,sprintf('\n\n')],csprefs.errorlog );

message=[message,sprintf('\n\nA copy of this error message has been logged in %s',csprefs.errorlog)];
if cookie
    message=[message,sprintf('\n\nAutomatic processing of this subject will be suspended until its error.txt file is removed')];
end

if isfield(csprefs,'sendmail')
%     if csprefs.sendmail
%         cs_email(csprefs.mailing_list,csprefs.smtp_server,csprefs.smtp_username,csprefs.smtp_password,csprefs.from_address,email_subject,csprefs.extended_from,message);
%     end
else
    cs_log( message,'mailtemp.txt' );
    eval(['!mail ',csprefs.mailing_list,' < mailtemp.txt']);
    eval(['!cat mailtemp.txt >> ',csprefs.mailfile]);
    delete('mailtemp.txt');
end
