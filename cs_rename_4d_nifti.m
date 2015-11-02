function files = cs_rename_4d_nifti(files)
% For 4d nifti files rename the files by adding a number at the end

firstFile = deblank(files(1, :));
[pathstr, fileN, extn] = fileparts(firstFile);
if (size(files, 1) == 1) & strcmpi(extn, '.nii')
    [hdr] = spm_read_hdr(firstFile);
    numFiles = hdr.dime.dim(5);
    newFiles = repmat(struct('name', []), numFiles, 1);
    for nn = 1:numFiles
        newFiles(nn).name = [firstFile, ',', num2str(nn)];
    end
    clear files;
    files = str2mat(newFiles.name);
    clear newFiles;
end