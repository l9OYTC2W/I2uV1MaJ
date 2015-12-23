function cs_despike( directory, csprefs, defaults )
% Performs despiking on all images in a directory.

V = cs_list_files(fullfile(pwd, directory), csprefs.despike_pattern, 'fullpath');
if (isempty(V))
    error('No files found for despiking.');
end

orig_dir=pwd;
cd(directory);
progFile=fullfile(orig_dir,'cs_progress.txt');
cs_log( ['Beginning cs_despike for ',directory], progFile );

[path, folder] = fileparts(directory);

if size(V,1) > 1
    % convert 3D images to one 4D file
    disp('Converting 3D data to 4D image.');
    output_4d = fullfile( path, strrep(csprefs.despike_pattern, '*', [folder '_4d']) );
    cs_convert_3Dto4D( V, output_4d );
else
    output_4d = fullfile(V);
end

output_despike = fullfile( path, [ defaults.despike.prefix strrep(csprefs.despike_pattern, '*', folder) ] );
[status, message] = system( [csprefs.despike_bin ' -nomask -prefix ' output_despike ' ' output_4d] );
disp(message);
if status > 0
    error('3dDespike failed.');
end

cd(orig_dir);