function cs_slicetime( directory, csprefs )

orig_dir=pwd;

cd(directory);

files = cs_list_files(pwd, csprefs.slicetime_pattern, 'fullpath');

if (isempty(files))
    
    error('No files found for slice timing.');
    
end


progFile=fullfile(orig_dir,'cs_progress.txt');

cs_log( ['Beginning cs_slicetime for ',pwd], progFile );


sliceorder = csprefs.sliceorder;
refslice = csprefs.refslice;

% Options for slice order are sequential or interleaved when using
% character array
if (ischar(sliceorder))
    
    tmpV = spm_vol([deblank(files(1, :)), ',1']);
    vox_dims = tmpV(1).dim(3);
    
    if (strcmpi(sliceorder, 'interleaved'))
        sliceorder = [(1:2:vox_dims), (2:2:vox_dims)];
    else
        sliceorder = (1:vox_dims);
    end
    
end

nslices=length(sliceorder);

% Options for reference slice are middle or first when using character
% array
if (ischar(refslice))
    if (strcmpi(refslice, 'first'))
        refslice = sliceorder(1);
    elseif (strcmpi(refslice, 'last'))
        refslice = sliceorder(end);
    else
        refslice = sliceorder(ceil(nslices/2));
    end
end


if ischar(csprefs.ta)
    
    TA=csprefs.tr-(csprefs.tr/nslices);
    
else
    
    TA=csprefs.ta;
    
end



timing(1) = TA / (nslices -1);

timing(2) = csprefs.tr - TA;

spm_slice_timing(files, sliceorder, refslice, timing);



cs_log( ['spm_slice_timing completed for ',pwd],                                            progFile );

cs_log( ['    sliceorder = ', mat2str(sliceorder) ],                                progFile, 1 );

cs_log( ['    refslice = ', num2str(refslice) ],                                    progFile, 1 );

cs_log( ['    timing(1) = ', num2str(timing(1)) ],                                          progFile, 1 );

cs_log( ['    timing(2) = ', num2str(timing(2)) ],                                          progFile, 1 );



cd(orig_dir);