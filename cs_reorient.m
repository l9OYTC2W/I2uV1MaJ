function cs_reorient(directory)
% Reorientation step. After reorientation if images are to be written they
% will be prepended with Re_

global csprefs;

% Get the original directory
origDir = pwd;

cd(directory);

% Get the same files used for realign
files = cs_list_files(pwd, csprefs.reorient_pattern, 'fullpath');

if isempty(files)
    error('No files found for reorientation.');
end

% Fix 4D Nifti data if possible
cs_fix_data(files);

% Rename 4D nifti files to contain numbers at the end of the file
files = cs_rename_4d_nifti(files);

if isfield(csprefs, 'reorient_vector')
    P = csprefs.reorient_vector;
    if length(P) ~= 12
        error('Error:Reorient', ...
            ['Length of vector csprefs.reorient_vector must be 12. ', ...
            '\nCheck the length of vector csprefs.reorient_vector in preference file']);
    end
else
    P = [0 0 0 0 0 0 1 1 1 0 0 0]; % no change in orientation...
end

[R] = spm_matrix(P);
%R(3) = .5;

progFile = fullfile(origDir, 'cs_progress.txt');

cs_log( ['Beginning cs_reorient for ', pwd], progFile );


if ~(csprefs.write_reorient)
    
    spm('CreateIntWin');
    spm_progress_bar('Init', size(files, 1), 'Reorienting images', 'Headers Written');
    % Loop over file names
    for ii = 1:size(files, 1)
        fileName = deblank(files(ii, :));
        M = spm_get_space(fileName);
        M = R*M;
        spm_get_space(fileName, M);
        spm_progress_bar('Set', ii);
        clear fileName;
    end
    % end loop over filenames
    
else
    
    V = spm_vol(files);
    
    spm('CreateIntWin');
    spm_progress_bar('Init', length(V), 'Reorienting images', 'Files Written');
    
    % Fix the orientation
    for i = 1:length(V)
        M = V(i).mat; % Get orientation
        M = R*M; % change the orientation
        % Option for writing images
        data = spm_read_vols(V(i));
        V(i).mat = M; % fixed orientation
        [pathstr, newImg, extn] = fileparts(V(i).fname);
        if isempty(pathstr)
            pathstr = pwd;
        end
        V(i).fname = fullfile(pathstr, ['Re_', newImg, extn]);
        
        spm_write_vol(V(i), data);
        spm_progress_bar('Set', i);
        
    end
    
end

cs_log( ['Ending cs_reorient for ', pwd], progFile );

cd(origDir);
