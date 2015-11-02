function cs_coregister(directory)
% Run Coregister or Reslice or Coregister and Reslice
%

global csprefs;
global defaults;

orig_dir = pwd;
cd(directory);
progFile = fullfile(orig_dir,'cs_progress.txt');

cs_log( ['Beginning cs_coregister for ', pwd], progFile );
    
% Source image
[coregSourceImage] = check_file_path(csprefs.coreg.source, 'source');

if ~isempty(csprefs.coreg.other_pattern)
    % Other images used
    otherImages = cs_list_files(pwd, csprefs.coreg.other_pattern, 'fullpath');
else
    otherImages = '';
end

if ~isempty(otherImages)
    otherImages = cs_rename_4d_nifti(otherImages);
else
    otherImages = '';
end


% Coregister step
if (csprefs.run_coreg)

    % Reference image
    [coregRefImage] = check_file_path(csprefs.coreg.ref, 'reference');
    
    % Estimate options pulled from spm_defaults file
    eoptions = defaults.coreg.estimate;

    % The above code is from spm_config_coreg function
    x  = spm_coreg(coregRefImage, coregSourceImage, eoptions);

    M  = inv(spm_matrix(x));

    PO = strvcat(strvcat(coregSourceImage), strvcat(otherImages));

    MM = zeros(4,4,size(PO,1));

    for j=1:size(PO,1),
        MM(:,:,j) = spm_get_space(deblank(PO(j,:)));
    end;

    for j=1:size(PO,1),
        spm_get_space(deblank(PO(j,:)), M*MM(:,:,j));
    end;
    
    cs_log(['spm_coreg completed for ', pwd], progFile);

end

% Reslice step
if (csprefs.run_reslice)

    % Reference image
    [refImage] = check_file_path(csprefs.coreg.write.ref, 'reference');

    P = strvcat(strvcat(refImage), strvcat(strvcat(coregSourceImage), strvcat(otherImages)));
    
    % Reslice options used from spm_defaults
    flags.mask   = defaults.coreg.write.mask;
    flags.mean   = 0;
    flags.interp = defaults.coreg.write.interp;
    flags.which  = 1;
    flags.wrap   = defaults.coreg.write.wrap;

    spm_reslice(P, flags);
    
    cs_log(['spm_reslice completed for ', pwd], progFile);

end

cs_log( ['Ending cs_coregister for ', pwd], progFile );

cd(orig_dir);



function [files] = check_file_path(filePattern, optional)
% Form files from a file pattern and select only the first file

if exist('optional', 'var')
    optional = '';
end

% check if full file path is specified or it is a file on Matlab path
if (exist(filePattern, 'file') == 2)
    files = filePattern;
else
    files = cs_list_files(pwd, filePattern, 'fullpath');
end

if isempty(files)
    error(['Please check the file pattern: ', filePattern, ' for ', optional, ' image']);
end

% Add a number at the end for 4D Nifti files
files = cs_rename_4d_nifti(files);

if size(files, 1) > 1
    files = deblank(files(1, :));
end