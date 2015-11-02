function cs_mean_image

global csprefs;

files=cs_locate_files(csprefs.meanimage_pattern);
if (isempty(files))
    error('No files found for cs_mean_image.');
end

outname=csprefs.meanimage_result;
disp('Averaging files: ');
disp(files);
spm_imcalc_ui(files,outname,'mean(X)',{1,0,4,1});

%-----------------------
function f=fullpath( d )
%Outdated now but leaving in the file b/c, hey, you never know

owd=pwd;
cd(d);
f=pwd;
cd(owd);