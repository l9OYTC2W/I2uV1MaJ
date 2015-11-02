function cs_dummies( scan_dir, dirlist)

global csprefs;

% dirlist=dir(scan_dir);
% dirs=find([dirlist(:).isdir]);
% dirlist={dirlist(dirs).name};

% % dirlist = cs_list_dirs(scan_dir, 'relative');
% %
% % dirs = regexp(dirlist, csprefs.rundir_regexp);
% % dirs = cs_good_cells(dirs);
% % dirlist = {dirlist{find(dirs)}};

realignPattern = csprefs.realign_pattern;

for i = 1:length(dirlist)
    run_dir = dirlist{i};
    files = cs_list_files(fullfile(scan_dir, run_dir), realignPattern, 'fullpath');
    dummy_dir = fullfile(scan_dir, run_dir, 'dummies');
    if ~exist(dummy_dir, 'dir')
        mkdir(dummy_dir);
    end

    if size(files, 1) > 1
        for j = 1:csprefs.dummyscans
            numstr = '0000';
            jstr = num2str(j);
            numstr( (5-length(jstr)):end ) = jstr;
            %mvstr=['!mv ',fullfile(scan_dir,run_dir),'/*',numstr,'.* ',dummy_dir];
            %mvstr = fullfile(scan_dir,run_dir, [filesep, '*', numstr, '.*']);
            mvstr = fullfile(scan_dir,run_dir, [filesep, '*', numstr, '.*']);
            fileList = dir(mvstr);
            if ~isempty(fileList)
                movefile(mvstr, dummy_dir);
            end
            clear fileList;
        end

    else

        try
            % Read Nifti file
            [pathstr, fName, extn] = fileparts(files);
            if strcmpi(extn, '.nii')
                hdr = spm_read_hdr(files);
            else
                hdr = spm_read_hdr(fullfile(pathstr, [fName, '.hdr']));
            end
            nFiles = hdr.dime.dim(5);

            if nFiles < csprefs.dummyscans
                error('Error:DummyScans', 'Dummy scans (%s) exceed the number of images (%s)', ...
                    num2str(csprefs.dummyscans), num2str(nFiles));
            end

            if nFiles > 1
                V = spm_vol(files);      
                
                disp(['Moving first ', num2str(csprefs.dummyscans), ' dummy scans to dummies directory ...']);
                fprintf('\n');

                % Write dummy scans to dummies directory
                [pathstr, fileN, extn] = fileparts(deblank(files));
                outputFileName = fullfile(dummy_dir, [fileN, extn]);
                cs_convert_3Dto4D(V(1:csprefs.dummyscans), outputFileName);

                dirName = fullfile(scan_dir, run_dir, 'temp_nifti');
                if (exist(dirName, 'dir') ~= 7)
                    mkdir(dirName);
                end
                
                % Write dummy scans to dummies directory
                outputFileName = fullfile(dirName, [fileN, extn]);
                cs_convert_3Dto4D(V(csprefs.dummyscans + 1:end), outputFileName);
                movefile(fullfile(dirName, '*'), fullfile(scan_dir, run_dir));
                rmdir(dirName);
                fprintf('\n');

            end

        catch
            disp(lasterr);
        end

    end
end
