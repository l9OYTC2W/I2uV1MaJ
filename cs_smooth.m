function cs_smooth( directory )
% Performs smoothing on images in a directory.

global csprefs;

progFile=fullfile(pwd,'cs_progress.txt');
cs_log( ['Beginning cs_smooth for ',fullfile(pwd,directory)], progFile );

P = cs_list_files(fullfile(pwd, directory), csprefs.smooth_pattern, 'fullpath');

if (isempty(P))
    error('No files found for smoothing');
end

S                               = csprefs.smooth_kernel;

% Get the volume
V = spm_vol(P);

spm('CreateIntWin');
spm_progress_bar('Init', length(V), 'Smoothing images', 'Volumes completed');

for i=1:length(V)
    p = V(i).fname; % file name
    Q = prepend(p, 's');
    newV = V(i);
    newV.fname = Q;
    %spm_smooth(p, Q, S);
    spm_smooth(V(i), newV, S);
    clear newV;
    spm_progress_bar('Set', i);
end


cs_log( ['spm_smooth completed for ',fullfile(pwd,directory)],                          progFile );
cs_log( ['    S = ', mat2str(S)],                                                       progFile, 1 );


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% THE FOLLOWING IS BLATANTLY "ADAPTED" (STOLEN) FROM SPM_WRITE_SN     %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function PO = prepend(PI,pre)
[pth,nm,xt] = fileparts(deblank(PI));
PO             = fullfile(pth,[pre nm xt]);
return;