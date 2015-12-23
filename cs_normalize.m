function cs_normalize( directory, csprefs, defaults )
% Performs spatial normalization on all images in a directory.

orig_dir=pwd;
cd(directory);
progFile=fullfile(orig_dir,'cs_progress.txt');
cs_log( ['Beginning cs_normalize for ',pwd], progFile );

% Check if the template file is on Matlab path or not
if exist(csprefs.params_template, 'file') ~= 2
    error(['Template image: ', csprefs.params_template ' for parameter estimation doesn''t exist']);
end

if ispc
    delimiter = ['\', filesep];
else
    delimiter = filesep;
end

subN = strread(orig_dir, '%s', 'delimiter', delimiter);
runN = strread(directory, '%s', 'delimiter', delimiter);

if length(subN) > 1
    subNumber = subN{end-1};
else
    subNumber = subN{end};
end

if (csprefs.determine_params)
    VG                          = csprefs.params_template;
    %VF = spm_get('files',pwd,csprefs.params_pattern);
    VF = cs_list_files(pwd, csprefs.params_pattern, 'fullpath');
    clear temp;
    if (size(VF,1) ~= 1 )
        error( 'Incorrect # of files specified by csprefs.params_pattern' );
    end
    [path filename] = fileparts(VF);

    if isfield(csprefs,'params_matname') && ~isempty(csprefs.params_matname)
        matname                     = fullfile(path,csprefs.params_matname);
    else
        matname                     = fullfile(path,[filename '_sn.mat']);
    end

    VWG                         = defaults.old.normalise.estimate.weight;
    if (strcmp(csprefs.params_source_weight,''))
        VWF                         = '';
    else
        %VWF                         =   spm_get('files',pwd,csprefs.params_source_weight);
        VWF = cs_list_files(pwd, csprefs.params_source_weight, 'fullpath');
        clear temp;
        if (size(VWF,1) ~= 1 )
            error( 'Incorrect # of files specified by csprefs.params_source_weight' );
        end
    end
    flags                       = defaults.old.normalise.estimate;

    spm_normalise( VG,VF,matname,VWG,VWF,flags );

    % Print postscript and Jpeg files
    cs_spm_print([subNumber, '_normalization_', runN{1}, '.ps']);
    cs_spm_print([subNumber, '_normalization_', runN{1}, '.jpg']);

    cs_log( ['spm_normalise completed for ',pwd],                                               progFile );
    cs_log( ['    VG = ', VG ],                                                                 progFile, 1 );
    cs_log( ['    VF = ', VF ],                                                                 progFile, 1 );
    cs_log( ['    matname = ', matname ],                                                       progFile, 1 );
    cs_log( ['    VWG = ', VWG ],                                                               progFile, 1 );
    cs_log( ['    VWF = ', VWF ],                                                               progFile, 1 );
    cs_log( ['    flags.smosrc = ', num2str(flags.smosrc) ],                                    progFile, 1 );
    cs_log( ['    flags.smoref = ', num2str(flags.smoref) ],                                    progFile, 1 );
    cs_log( ['    flags.regtype = ', flags.regtype ],                                           progFile, 1 );
    cs_log( ['    flags.weight = ', flags.weight ],                                             progFile, 1 );
    cs_log( ['    flags.cutoff = ', num2str(flags.cutoff) ],                                    progFile, 1 );
    cs_log( ['    flags.nits = ', num2str(flags.nits) ],                                        progFile, 1 );
    cs_log( ['    flags.reg = ', num2str(flags.reg) ],                                          progFile, 1 );
    cs_log( ['    flags.wtsrc = ', num2str(flags.wtsrc) ],                                      progFile, 1 );

end

if (csprefs.write_normalized)
    %    V                           = spm_get('files',pwd,csprefs.writenorm_pattern);
    %V                           = cs_locate_files(csprefs.writenorm_pattern);
    V = cs_list_files(pwd, csprefs.writenorm_pattern, 'fullpath');
    if (isempty(V))
        error('No files found for normalization.');
    end

    if ~(csprefs.determine_params)
        %matname                 =  spm_get('files',pwd,csprefs.writenorm_matname);
        matname = cs_list_files(pwd, csprefs.writenorm_matname, 'fullpath');
        clear temp;
        if (size(matname,1) ~= 1 )
            error( 'Incorrect # of files specified by csprefs.writenorm_matname' );
        end
    end
    flags                       = defaults.old.normalise.write;

    spm_write_sn( V,matname,flags );

    cs_log( ['spm_write_sn completed for ',pwd],                                                progFile );
    cs_log( ['    matname = ', matname ],                                                       progFile, 1 );
    cs_log( ['    flags.preserve = ', num2str(flags.preserve) ],                                progFile, 1 );
    cs_log( ['    flags.bb = ', mat2str(flags.bb) ],                                            progFile, 1 );
    cs_log( ['    flags.vox = ', mat2str(flags.vox) ],                                          progFile, 1 );
    cs_log( ['    flags.interp = ', num2str(flags.interp) ],                                    progFile, 1 );
    cs_log( ['    flags.wrap = ', mat2str(flags.wrap) ],                                        progFile, 1 );

end

%!rm wmean*;
%delete('w*mean*');

cd(orig_dir);