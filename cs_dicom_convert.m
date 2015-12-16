function cs_dicom_convert(directory)
% Convert dicom files to 3D Analyze, 3D Nifti or 4D Nifti images
% It is recommended that Dicom files be converted to 3D analyze or 3D nifti
% files

global csprefs;

if ~isfield(csprefs.dicom, 'outputDir')
    csprefs.dicom.outputDir = [];
end

orig_dir = pwd;
cd(directory);

runDirectory = pwd;

% Output directory
if isempty(csprefs.dicom.outputDir)
    outDir = pwd;
else
    outDir = csprefs.dicom.outputDir;
    if exist(outDir, 'dir') ~= 7
        mkdir(outDir);
    end
end

% Check if progress file can be created or not
try
    progFile = fullfile(orig_dir, 'cs_progress.txt');
    cs_log(['Beginning cs_dicom_convert for ', runDirectory], progFile );
catch
    disp(lasterr);
    fprintf('\n');
    try
        sessRegExpStr = ['(', csprefs.rundir_regexp, ')'];

        if (isfield(csprefs, 'rundir_postpend')) && (~isempty(csprefs.rundir_postpend))
            sessRegExpStr = [sessRegExpStr, '\', filesep, '(', csprefs.rundir_postpend, ')'];
        else
            if ~strcmp(sessRegExpStr(end), '$')
                sessRegExpStr = [sessRegExpStr, '$'];
            end
        end

        tempSubDir = regexprep(outDir, sessRegExpStr, '');

        progFile = fullfile(tempSubDir, 'cs_progress.txt');

        cs_log(['Beginning cs_dicom_convert for ', runDirectory], progFile );

    catch

    end

end
% End for checking progress file

% Read dicom files
files = cs_list_files(runDirectory, csprefs.dicom.file_pattern, 'fullpath');

if isempty(files)
    error('No dicom files found. Check field file_pattern field in structure csprefs.dicom');
end

% Add spm5 on top of path
addpath(fileparts(which('spm.m')));

% Change to output directory
cd(outDir);

disp('Reading dicom headers ...');

% Read dicom header
hdr = spm_dicom_headers(files);

% Get the image format nii or analyze
imageFormat = csprefs.dicom.format;

filePrefix = csprefs.dicom.write_file_prefix;

% Check the image format
if strcmpi(imageFormat, '3d_analyze')
    imFormat = 'img';
    imName = '3D Analyze';
else
    imFormat = 'nii';
    if strcmpi(imageFormat, '3d_nifti')
        imName = '3D Nifti';
    else
        imName = '4D Nifti';
    end
end

opts = 'all';
disp(['Converting dicom files to ', imName, ' images']);
spm_dicom_convert(hdr, opts, 'flat', imFormat);


[images, guff]     = select_tomographic_images(hdr);
[spect, images]    = select_spectroscopy_images(images);
[mosaic,standard] = select_mosaic_images(images);

% Check if series ID is no the same
seriesID = cell(length(hdr), 1);
for nn = 1:length(hdr)
    seriesID{nn} = hdr{nn}.SeriesInstanceUID;
end

seriesID = unique(seriesID);

if (strcmp(opts,'all') || strcmp(opts,'standard')) && ~isempty(standard)

    temp = sort_into_volumes(hdr);

    if length(seriesID) > 1

        % Make the series instance id same
        if length(temp) > 1

            for nn = 1:length(temp)
                fileNames{nn} = getfilelocation(temp{nn}{1}, 'flat', 's', imFormat);
            end

            deleteFiles(fileNames, imFormat);

            clear fileNames;

            disp('Making series instance id same ...');
            for nn = 1:length(hdr)
                if nn == 1
                    seriesInstanceID = hdr{nn}.SeriesInstanceUID;
                end
                hdr{nn}.SeriesInstanceUID = seriesInstanceID;
            end

            disp(['Converting dicom files to ', imName, ' images']);
            spm_dicom_convert(hdr, opts, 'flat', imFormat);
            [images, guff]     = select_tomographic_images(hdr);
            [spect, images]    = select_spectroscopy_images(images);
            [mosaic,standard] = select_mosaic_images(images);

        end

    end

end

if (strcmp(opts,'all') || strcmp(opts,'mosaic')) && ~isempty(mosaic),
    % Initialise file names
    fileNames = cell(1, length(hdr));
    %convert_mosaic(mosaic,root_dir,format);
    for nn = 1:length(hdr)
        fileNames{nn} = getfilelocation(hdr{nn}, 'flat', 'f', imFormat);
    end
end;

if (strcmp(opts,'all') || strcmp(opts,'standard')) && ~isempty(standard),
    %convert_standard(standard,root_dir,format);

    if length(temp) > 1
        hdr = sort_into_volumes(hdr);
    else
        hdr = temp;
    end

    clear temp;

    for nn = 1:length(hdr)
        fileNames{nn} = getfilelocation(hdr{nn}{1}, 'flat', 's', imFormat);
    end

    %fileNames{1} = getfilelocation(hdr{1}, 'flat', 's', imFormat);
end;

if (strcmp(opts,'all') || strcmp(opts,'spect')) && ~isempty(spect),
    %convert_spectroscopy(spect,root_dir,format);
    %fileNames{1} = getfilelocation(hdr{1}, 'flat', 'S', imFormat);
    for nn = 1:length(hdr)
        fileNames{nn} = getfilelocation(hdr{nn}, 'flat', 'S', imFormat);
    end
end;

% Rename if the files are in analyze format
if strcmpi(imageFormat, '3d_analyze')

    VF = spm_vol(str2mat(fileNames));
    data = spm_read_vols(VF);

    for nn = 1:length(VF)
        fileIndex = returnFileIndex(nn);
        newFileName = [outDir, filesep, filePrefix, '_', fileIndex, '.img'];
        VF(nn).fname = newFileName;
        spm_write_vol(VF(nn), squeeze(data(:, :, :, nn)));
    end

    clear data;

elseif strcmpi(imageFormat, '3d_nifti')

    VF = spm_vol(str2mat(fileNames));
    data = spm_read_vols(VF);

    for nn = 1:length(VF)
        fileIndex = returnFileIndex(nn);
        newFileName = [outDir, filesep, filePrefix, '_', fileIndex, '.nii'];
        VF(nn).fname = newFileName;
        spm_write_vol(VF(nn), squeeze(data(:, :, :, nn)));
    end

    clear data;

else

    % Convert to 4D nifti file
    fileNames = str2mat(fileNames);
    newFileName = fullfile(outDir, [filePrefix, '.nii']);
    % Convert 3D To 4D
    cs_convert_3Dto4D(fileNames, newFileName);
    fileNames = cellstr(fileNames);

end
% End for renaming files

drawnow;
deleteFiles(fileNames, imFormat);

try
    cs_log(['Ending cs_dicom_convert for ', runDirectory], progFile );
catch
end

cd(orig_dir);


%%%%%%%%%%%% Required Sub-functions from SPM5 %%%%%%%%%%%%%%
function fname = getfilelocation(hdr,root_dir,prefix,format)

if nargin < 3
    prefix = 'f';
end;
if strcmp(root_dir, 'flat')
    % Standard SPM5 file conversion
    %-------------------------------------------------------------------
    if checkfields(hdr,'SeriesNumber','AcquisitionNumber')
        if checkfields(hdr,'EchoNumbers')
            fname = sprintf('%s%s-%.4d-%.5d-%.6d-%.2d.%s', prefix, strip_unwanted(hdr.PatientID),...
                hdr.SeriesNumber, hdr.AcquisitionNumber, hdr.InstanceNumber,...
                hdr.EchoNumbers, format);
        else
            fname = sprintf('%s%s-%.4d-%.5d-%.6d.%s', prefix, strip_unwanted(hdr.PatientID),...
                hdr.SeriesNumber, hdr.AcquisitionNumber, ...
                hdr.InstanceNumber, format);
        end;
    else
        fname = sprintf('%s%s-%.6d.%s',prefix, ...
            strip_unwanted(hdr.PatientID),hdr.InstanceNumber, format);
    end;

    fname = fullfile(pwd,fname);
    return;
end;

% more fancy stuff - sort images into subdirectories
if ~isfield(hdr,'ProtocolName')
    if isfield(hdr,'SequenceName')
        hdr.ProtocolName = hdr.SequenceName;
    else
        hdr.ProtocolName='unknown';
    end;
end;
if ~isfield(hdr,'SeriesDescription')
    hdr.SeriesDescription = 'unknown';
end;
if ~isfield(hdr,'EchoNumbers')
    hdr.EchoNumbers = 0;
end;

m = sprintf('%02d', floor(rem(hdr.StudyTime/60,60)));
h = sprintf('%02d', floor(hdr.StudyTime/3600));
studydate = sprintf('%s_%s-%s', datestr(hdr.StudyDate,'yyyy-mm-dd'), ...
    h,m);
serdes = strrep(strip_unwanted(hdr.SeriesDescription),...
    strip_unwanted(hdr.ProtocolName),'');
protname = sprintf('%s%s_%.4d',strip_unwanted(hdr.ProtocolName), ...
    serdes, hdr.SeriesNumber);
switch root_dir
    case 'date_time',
        root = pwd;
        dname = fullfile(root, studydate, protname);
    case 'patid',
        dname = fullfile(pwd, strip_unwanted(hdr.PatientID), ...
            protname);
    case 'patid_date',
        dname = fullfile(pwd, strip_unwanted(hdr.PatientID), ...
            studydate, protname);
    case 'patname',
        dname = fullfile(pwd, strip_unwanted(hdr.PatientsName), ...
            strip_unwanted(hdr.PatientID), ...
            protname);
    otherwise
        error('unknown file root specification');
end;
if ~exist(dname,'dir'),
    mkdir_rec(dname);
end;

switch root_dir
    case 'date_time',
        fname = sprintf('%s%s-%.5d-%.5d-%d.%s', prefix, studydate, ...
            hdr.AcquisitionNumber,hdr.InstanceNumber, ...
            hdr.EchoNumbers,format);
    case {'patid', 'patid_date', 'patname'},
        fname = sprintf('%s%s-%.5d-%.5d-%d.%s', prefix, strip_unwanted(hdr.PatientID), ...
            hdr.AcquisitionNumber,hdr.InstanceNumber, ...
            hdr.EchoNumbers,format);
end;

fname = fullfile(dname, fname);

%_______________________________________________________________________

%_______________________________________________________________________


%_______________________________________________________________________
function clean = strip_unwanted(dirty)
msk = find((dirty>='a'&dirty<='z') | (dirty>='A'&dirty<='Z') |...
    (dirty>='0'&dirty<='9') | dirty=='_');
clean = dirty(msk);
return;
%_______________________________________________________________________

%_______________________________________________________________________
function ok = checkfields(hdr,varargin)
ok = 1;
for i=1:(nargin-1),
    if ~isfield(hdr,varargin{i}),
        ok = 0;
        break;
    end;
end;
return;
%_______________________________________________________________________


%_______________________________________________________________________
function [images,guff] = select_tomographic_images(hdr)
images = {};
guff   = {};
for i=1:length(hdr),
    if ~checkfields(hdr{i},'Modality') || ~(strcmp(hdr{i}.Modality,'MR') ||...
            strcmp(hdr{i}.Modality,'PT') || strcmp(hdr{i}.Modality,'CT'))
        disp(['Cant find appropriate modality information for "' hdr{i}.Filename '".']);
        guff = {guff{:},hdr{i}};
    elseif ~(checkfields(hdr{i},'StartOfPixelData','SamplesPerPixel',...
            'Rows','Columns','BitsAllocated','BitsStored','HighBit','PixelRepresentation')||isfield(hdr{i},'Private_7fe1_0010')),
        disp(['Cant find "Image Pixel" information for "' hdr{i}.Filename '".']);
        guff = {guff{:},hdr{i}};
    elseif ~(checkfields(hdr{i},'PixelSpacing','ImagePositionPatient','ImageOrientationPatient')||isfield(hdr{i},'Private_0029_1210')),
        disp(['Cant find "Image Plane" information for "' hdr{i}.Filename '".']);
        guff = {guff{:},hdr{i}};
    elseif ~checkfields(hdr{i},'PatientID','SeriesNumber','AcquisitionNumber','InstanceNumber'),
        disp(['Cant find suitable filename info for "' hdr{i}.Filename '".']);
        if ~isfield(hdr{i},'SeriesNumber')
            disp('Setting SeriesNumber to 1');
            hdr{i}.SeriesNumber=1;
            images = {images{:},hdr{i}};
        end;
        if ~isfield(hdr{i},'AcquisitionNumber')
            disp('Setting AcquisitionNumber to 1');
            hdr{i}.AcquisitionNumber=1;
            images = {images{:},hdr{i}};
        end;
        if ~isfield(hdr{i},'InstanceNumber')
            disp('Setting InstanceNumber to 1');
            hdr{i}.InstanceNumber=1;
            images = {images{:},hdr{i}};
        end;
    else
        images = {images{:},hdr{i}};
    end;
end;
return;
%_______________________________________________________________________

%_______________________________________________________________________
function [mosaic,standard] = select_mosaic_images(hdr)
mosaic   = {};
standard = {};
for i=1:length(hdr),
    if ~checkfields(hdr{i},'ImageType','CSAImageHeaderInfo') ||...
            isfield(hdr{i}.CSAImageHeaderInfo,'junk') ||...
            isempty(read_AcquisitionMatrixText(hdr{i})) ||...
            isempty(read_NumberOfImagesInMosaic(hdr{i}))
        standard = {standard{:},hdr{i}};
    else
        mosaic = {mosaic{:},hdr{i}};
    end;
end;
return;
%_______________________________________________________________________

%_______________________________________________________________________
function [spect,images] = select_spectroscopy_images(hdr)
spectsel  = zeros(1,numel(hdr));
for i=1:length(hdr),
    if isfield(hdr{i},'SOPClassUID')
        spectsel(i) = strcmp(hdr{i}.SOPClassUID,'1.3.12.2.1107.5.9.1');
    end;
end;
spect = hdr(logical(spectsel));
images= hdr(~logical(spectsel));
return;
%_______________________________________________________________________

%_______________________________________________________________________
function n = read_NumberOfImagesInMosaic(hdr)
str = hdr.CSAImageHeaderInfo;
val = get_numaris4_val(str,'NumberOfImagesInMosaic');
n   = sscanf(val','%d');
if isempty(n), n=[]; end;
return;
%_______________________________________________________________________

%_______________________________________________________________________
function dim = read_AcquisitionMatrixText(hdr)
str = hdr.CSAImageHeaderInfo;
val = get_numaris4_val(str,'AcquisitionMatrixText');
dim = sscanf(val','%d*%d')';
if length(dim)==1,
    dim = sscanf(val','%dp*%d')';
end;
if isempty(dim), dim=[]; end;
return;
%_______________________________________________________________________

%_______________________________________________________________________
function val = get_numaris4_val(str,name)
name = deblank(name);
val  = {};
for i=1:length(str),
    if strcmp(deblank(str(i).name),name),
        for j=1:str(i).nitems,
            if  str(i).item(j).xx(1),
                val = {val{:} str(i).item(j).val};
            end;
        end;
        break;
    end;
end;
val = strvcat(val{:});
return;
%_______________________________________________________________________

%_______________________________________________________________________
function val = get_numaris4_numval(str,name)
val1 = get_numaris4_val(str,name);
for k = 1:size(val1,1)
    val(k)=str2num(val1(k,:));
end;
return;
%_______________________________________________________________________


%_______________________________________________________________________
function vol = sort_into_volumes(hdr)

%
% First of all, sort into volumes based on relevant
% fields in the header.
%

vol{1}{1} = hdr{1};
for i=2:length(hdr),
    orient = reshape(hdr{i}.ImageOrientationPatient,[3 2]);
    xy1    = hdr{i}.ImagePositionPatient*orient;
    match  = 0;
    if isfield(hdr{i},'CSAImageHeaderInfo')
        ice1 = sscanf( ...
            strrep(get_numaris4_val(hdr{i}.CSAImageHeaderInfo,'ICE_Dims'), ...
            'X', '-1'), '%i_%i_%i_%i_%i_%i_%i_%i_%i')';
        dimsel = logical([1 1 1 1 1 1 0 0 1]);
    else
        ice1 = [];
    end;
    for j=1:length(vol),
        orient = reshape(vol{j}{1}.ImageOrientationPatient,[3 2]);
        xy2    = vol{j}{1}.ImagePositionPatient*orient;
        dist2  = sum((xy1-xy2).^2);

        % This line is a fudge because of some problematic data that Bogdan,
        % Cynthia and Stefan were trying to convert.  I hope it won't cause
        % problems for others -JA
        dist2 = 0;

        if strcmp(hdr{i}.Modality,'CT') && ...
                strcmp(vol{j}{1}.Modality,'CT') % Our CT seems to have shears in slice positions
            dist2 = 0;
        end;
        if ~isempty(ice1) && isfield(vol{j}{1},'CSAImageHeaderInfo')
            % Replace 'X' in ICE_Dims by '-1'
            ice2 = sscanf( ...
                strrep(get_numaris4_val(vol{j}{1}.CSAImageHeaderInfo,'ICE_Dims'), ...
                'X', '-1'), '%i_%i_%i_%i_%i_%i_%i_%i_%i')';
            if ~isempty(ice2)
                identical_ice_dims=all(ice1(dimsel)==ice2(dimsel));
            else
                identical_ice_dims = 0; % have ice1 but not ice2, ->
                % something must be different
            end,
        else
            identical_ice_dims = 1; % No way of knowing if there is no CSAImageHeaderInfo
        end;
        try
            match = hdr{i}.SeriesNumber            == vol{j}{1}.SeriesNumber &&...
                hdr{i}.Rows                        == vol{j}{1}.Rows &&...
                hdr{i}.Columns                     == vol{j}{1}.Columns &&...
                sum((hdr{i}.ImageOrientationPatient - vol{j}{1}.ImageOrientationPatient).^2)<1e-5 &&...
                sum((hdr{i}.PixelSpacing            - vol{j}{1}.PixelSpacing).^2)<1e-5 && ...
                identical_ice_dims && dist2<1e-3;
            if (hdr{i}.AcquisitionNumber ~= hdr{i}.InstanceNumber)|| ...
                    (vol{j}{1}.AcquisitionNumber ~= vol{j}{1}.InstanceNumber)
                match = match && (hdr{i}.AcquisitionNumber == vol{j}{1}.AcquisitionNumber);
            end;
            % For raw image data, tell apart real/complex or phase/magnitude
            if isfield(hdr{i},'ImageType') && isfield(vol{j}{1}, ...
                    'ImageType')
                match = match && strcmp(hdr{i}.ImageType, ...
                    vol{j}{1}.ImageType);
            end;
            if isfield(hdr{i},'SequenceName') && isfield(vol{j}{1}, ...
                    'SequenceName')
                match = match && strcmp(hdr{i}.SequenceName, ...
                    vol{j}{1}.SequenceName);
            end;
            if isfield(hdr{i},'SeriesInstanceUID') && isfield(vol{j}{1}, ...
                    'SeriesInstanceUID')
                match = match && strcmp(hdr{i}.SeriesInstanceUID, ...
                    vol{j}{1}.SeriesInstanceUID);
            end;
            if isfield(hdr{i},'EchoNumbers')  && isfield(vol{j}{1}, ...
                    'EchoNumbers')
                match = match && hdr{i}.EchoNumbers == ...
                    vol{j}{1}.EchoNumbers;
            end;
        catch
            match = 0;
        end
        if match
            vol{j}{end+1} = hdr{i};
            break;
        end;
    end;
    if ~match,
        vol{end+1}{1} = hdr{i};
    end;
end;

%
% Secondly, sort volumes into ascending/descending
% slices depending on .ImageOrientationPatient field.
%

vol2 = {};
for j=1:length(vol),
    orient = reshape(vol{j}{1}.ImageOrientationPatient,[3 2]);
    proj   = null(orient');
    if det([orient proj])<0, proj = -proj; end;

    z      = zeros(length(vol{j}),1);
    for i=1:length(vol{j}),
        z(i)  = vol{j}{i}.ImagePositionPatient*proj;
    end;
    [z,index] = sort(z);
    vol{j}    = vol{j}(index);
    if length(vol{j})>1,
        % dist      = diff(z);
        if any(diff(z)==0)
            tmp = sort_into_vols_again(vol{j});
            vol{j} = tmp{1};
            vol2 = {vol2{:} tmp{2:end}};
        end;
    end;
end;
vol = {vol{:} vol2{:}};
for j=1:length(vol),
    if length(vol{j})>1,
        orient = reshape(vol{j}{1}.ImageOrientationPatient,[3 2]);
        proj   = null(orient');
        if det([orient proj])<0, proj = -proj; end;
        z      = zeros(length(vol{j}),1);
        for i=1:length(vol{j}),
            z(i)  = vol{j}{i}.ImagePositionPatient*proj;
        end;
        [z,index] = sort(z);
        dist      = diff(z);
        if sum((dist-mean(dist)).^2)/length(dist)>1e-4,
            fprintf('***************************************************\n');
            fprintf('* VARIABLE SLICE SPACING                          *\n');
            fprintf('* This may be due to missing DICOM files.         *\n');
            if checkfields(vol{j}{1},'PatientID','SeriesNumber','AcquisitionNumber','InstanceNumber'),
                fprintf('*    %s / %d / %d / %d \n',...
                    deblank(vol{j}{1}.PatientID), vol{j}{1}.SeriesNumber, ...
                    vol{j}{1}.AcquisitionNumber, vol{j}{1}.InstanceNumber);
                fprintf('*                                                 *\n');
            end;
            fprintf('*  %20.4g                           *\n', dist);
            fprintf('***************************************************\n');
        end;
    end;
end;
%dcm = vol;
%save('dicom_headers.mat','dcm');
return;
%_______________________________________________________________________


%_______________________________________________________________________
function vol2 = sort_into_vols_again(volj)
if ~isfield(volj{1},'InstanceNumber'),
    fprintf('***************************************************\n');
    fprintf('* The slices may be all mixed up and the data     *\n');
    fprintf('* not really usable.  Talk to your physicists     *\n');
    fprintf('* about this.                                     *\n');
    fprintf('***************************************************\n');
    vol2 = {volj};
    return;
end;

fprintf('***************************************************\n');
fprintf('* The AcquisitionNumber counter does not appear   *\n');
fprintf('* to be changing from one volume to another.      *\n');
fprintf('* Another possible explanation is that the same   *\n');
fprintf('* DICOM slices are used multiple times.           *\n');
%fprintf('* Talk to your MR sequence developers or scanner  *\n');
%fprintf('* supplier to have this fixed.                    *\n');
fprintf('* The conversion is having to guess how slices    *\n');
fprintf('* should be arranged into volumes.                *\n');
if checkfields(volj{1},'PatientID','SeriesNumber','AcquisitionNumber'),
    fprintf('*    %s / %d / %d\n',...
        deblank(volj{1}.PatientID), volj{1}.SeriesNumber, ...
        volj{1}.AcquisitionNumber);
end;
fprintf('***************************************************\n');

z      = zeros(length(volj),1);
t      = zeros(length(volj),1);
d      = zeros(length(volj),1);
orient = reshape(volj{1}.ImageOrientationPatient,[3 2]);
proj   = null(orient');
if det([orient proj])<0, proj = -proj; end;

for i=1:length(volj),
    z(i)  = volj{i}.ImagePositionPatient*proj;
    t(i)  = volj{i}.InstanceNumber;
end;
% msg = 0;
[t,index] = sort(t);
volj      = volj(index);
z         = z(index);
msk       = find(diff(t)==0);
if any(msk),
    % fprintf('***************************************************\n');
    % fprintf('* These files have the same InstanceNumber:       *\n');
    % for i=1:length(msk),
    %    [tmp,nam1,ext1] = fileparts(volj{msk(i)}.Filename);
    %    [tmp,nam2,ext2] = fileparts(volj{msk(i)+1}.Filename);
    %    fprintf('* %s%s = %s%s (%d)\n', nam1,ext1,nam2,ext2, volj{msk(i)}.InstanceNumber);
    % end;
    % fprintf('***************************************************\n');
    index = [true ; diff(t)~=0];
    t     = t(index);
    z     = z(index);
    d     = d(index);
    volj  = volj(index);
end;

%if any(diff(sort(t))~=1), msg = 1; end;
[z,index] = sort(z);
volj      = volj(index);
t         = t(index);
vol2      = {};
while ~all(d),
    i  = find(~d);
    i  = i(1);
    i  = find(z==z(i));
    [t(i),si] = sort(t(i));
    volj(i)   = volj(i(si));
    for i1=1:length(i),
        if length(vol2)<i1, vol2{i1} = {}; end;
        vol2{i1} = {vol2{i1}{:} volj{i(i1)}};
    end;
    d(i) = 1;
end;

msg = 0;
if any(diff(sort(t))~=1), msg = 1; end;
if ~msg,
    len = length(vol2{1});
    for i=2:length(vol2),
        if length(vol2{i}) ~= len,
            msg = 1;
            break;
        end;
    end;
end;
if msg,
    fprintf('***************************************************\n');
    fprintf('* There are missing DICOM files, so the the       *\n');
    fprintf('* resulting volumes may be messed up.             *\n');
    if checkfields(volj{1},'PatientID','SeriesNumber','AcquisitionNumber'),
        fprintf('*    %s / %d / %d\n',...
            deblank(volj{1}.PatientID), volj{1}.SeriesNumber, ...
            volj{1}.AcquisitionNumber);
    end;
    fprintf('***************************************************\n');
end;
return;
%_______________________________________________________________________



function [fileIndex] = returnFileIndex(numberFiles)
% function that returns the file index naming

% check index
if numberFiles < 10
    fileIndex = ['000', num2str(numberFiles)];
elseif numberFiles < 100
    fileIndex = ['00', num2str(numberFiles)];
elseif numberFiles < 1000
    fileIndex = ['0', num2str(numberFiles)];
else
    fileIndex = num2str(numberFiles);
end
% end for checking


function deleteFiles(fileNames, imFormat)
% Delete files

fileNames = str2mat(fileNames);
[pathstr, fileN, extn] = fileparts(deblank(fileNames(1, :)));

if ~isempty(pathstr)
    [pos] = findstr(fileNames(1, :), filesep);
    fileNames = fileNames(:, pos(end) + 1:end);
end

try
    % Make file summary
    if strcmpi(imFormat, 'img')
        [prefix1, indices_prefix] = cs_spm_get('fileSummary', fileNames);
        hdrFiles = strcat(fileNames(:, 1:end-3), 'hdr');
        [prefix2, indices_prefix] = cs_spm_get('fileSummary', hdrFiles);
        fileNames = str2mat(prefix1, prefix2);
    else
        [fileNames, indices_prefix] = cs_spm_get('fileSummary', fileNames);
    end

catch
end

fileNames = strcat(pathstr, filesep, fileNames);

fileNames = cellstr(fileNames);

for ii = 1:length(fileNames)
    currentFile = fileNames{ii};
    commandStr = ['rm "', currentFile, '"'];
    [status, message] = system(commandStr);
    if status == 1
        delete(currentFile);
    end
    drawnow;
end