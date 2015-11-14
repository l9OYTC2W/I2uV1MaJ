function cs_despike( directory )
% Performs despiking on all images in a directory.

global csprefs;
global defaults;

orig_dir=pwd;
cd(directory);
progFile=fullfile(orig_dir,'cs_progress.txt');
cs_log( ['Beginning cs_despike for ',directory], progFile );

V = cs_list_files(pwd, csprefs.despike_pattern, 'fullpath');
if (isempty(V))
    error('No files found for despiking.');
end

[path, folder] = fileparts(directory);
output_4d = fullfile( path, strrep(csprefs.despike_pattern, '*', [folder '_4d']) );
output_despike = fullfile( path, [ defaults.despike.prefix strrep(csprefs.despike_pattern, '*', folder) ] );

cs_convert_3Dto4D( V, output_4d );

disp('Starting 3dDespike')
[status, message] = system( [csprefs.despike_bin ' -nomask -prefix ' output_despike ' ' output_4d] );
disp(message);
if status > 0
    error('3dDespike failed.');
end

cd(orig_dir);