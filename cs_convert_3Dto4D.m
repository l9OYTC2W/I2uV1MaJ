function cs_convert_3Dto4D(inputFiles, outputFileName)
% Function to convert 3D data to 4D image. The following code is used from
% spm_config_3Dto4D
%
% Inputs:
% 1. inputFiles - 3D file names
% 2. outputFileName - 4D file name


if ~isstruct(inputFiles)
    disp('Getting volume information from 3D data...');
    V    = spm_vol(inputFiles);
    disp('Done getting volume information from 3D data...');
else
    V = inputFiles;
end

ind  = cat(1,V.n);
N    = cat(1, V.private);

mx   = -Inf;
mn   = Inf;
for i=1:numel(V),
    dat      = V(i).private.dat(:,:,:,ind(i,1),ind(i,2));
    dat      = dat(isfinite(dat));
    mx       = max(mx,max(dat(:)));
    mn       = min(mn,min(dat(:)));
end;

sf         = max(mx,-mn)/32767;
ni         = nifti;
ni.dat     = file_array(outputFileName, [V(1).dim numel(V)], 'INT16-BE',0,sf,0);
ni.mat     = N(1).mat;
ni.mat0    = N(1).mat;
ni.descrip = '4D image';
disp(['Writing 4D file: ', outputFileName]);
create(ni);
for i=1:size(ni.dat,4),
    ni.dat(:,:,:,i) = N(i).dat(:,:,:,ind(i,1),ind(i,2));
    spm_get_space([ni.dat.fname ',' num2str(i)], V(i).mat);
end;
disp('Done writing 4D file');
