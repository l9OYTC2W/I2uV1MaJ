function cs_segment(directory)
% Run Segementation step

global csprefs;
global defaults;

% Add this for spm8
% VBM Preprocessing defaults
if (~isfield(defaults.preproc, 'fudge'))
    defaults.preproc.fudge = 5;
end

if (~isfield(defaults.preproc, 'output'))
    defaults.preproc.output.GM      = [0 0 1];
    defaults.preproc.output.WM      = [0 0 1];
    defaults.preproc.output.CSF     = [0 0 0];
    defaults.preproc.output.biascor = 1;
    defaults.preproc.output.cleanup = 0;
end


orig_dir = pwd;
cd(directory);
progFile = fullfile(orig_dir,'cs_progress.txt');
cs_log( ['Beginning cs_segment for ', pwd], progFile );

files = cs_list_files(pwd, csprefs.segment.pattern, 'fullpath');

if isempty(files)
    error('No files found for segmentation.');
end

% Output
output = csprefs.segment.output;

% VBM Preprocessing defaults
opts.tpm = cellstr(defaults.preproc.tpm); % Prior probability maps
opts.ngaus = defaults.preproc.ngaus; % Gaussians per class
opts.warpreg = defaults.preproc.warpreg; % Warping Regularisation
opts.warpco = defaults.preproc.warpco; % Warp Frequency Cutoff
opts.biasreg = defaults.preproc.biasreg; % Bias regularisation
opts.biasfwhm = defaults.preproc.biasfwhm; % Bias FWHM
opts.regtype = defaults.preproc.regtype; % Affine Regularisation
opts.samp = defaults.preproc.samp; % Sampling distance

if isfield(defaults.preproc, 'msk')
    opts.msk = {defaults.preproc.msk}; % Mask
else
    opts.msk = {''};
end

filesN = cell(size(files, 1), 1);

for nn = 1:length(filesN)
    filesN{nn} = [deblank(files(nn, :)), ',1'];
end

job.output = output;
job.opts = opts;

for i = 1:length(filesN)
    job.data = filesN(i);
    execute(job);
end

cs_log( ['Ending cs_segment for ', pwd], progFile );

cd(orig_dir);



%------------------------------------------------------------------------
function execute(job)

job.opts.tpm = char(job.opts.tpm{:});
if isfield(job.opts,'msk'),
    job.opts.msk = char(job.opts.msk{:});
end;

greyMatterFile = fullfile(fileparts(which('spm.m')), 'apriori', 'grey.nii');

res           = spm_preproc(job.data{1},job.opts);
[sn(1),isn]   = spm_prep2sn(res);
[pth,nam,ext] = spm_fileparts(job.data{i});
savefields(fullfile(pth, [nam '_seg_sn.mat']), sn(1));
savefields(fullfile(pth, [nam '_seg_inv_sn.mat']), isn);

spm_preproc_write(sn, job.output);
try
    spm_check_registration(char(greyMatterFile, fullfile(pth, ['c1', nam, extn])));
    cs_spm_print(fullfile(pth, [nam, '.ps']));
    cs_spm_print(fullfile(pth, [nam, '.jpg']));
catch
end

return;
%------------------------------------------------------------------------

%------------------------------------------------------------------------
function savefields(fnam,p)
if length(p)>1, error('Can''t save fields.'); end;
fn = fieldnames(p);
if numel(fn)==0, return; end;
for i=1:length(fn),
    eval([fn{i} '= p.' fn{i} ';']);
end;
if spm_matlab_version_chk('7') >= 0
    save(fnam,'-V6',fn{:});
else
    save(fnam,fn{:});
end;

return;
%------------------------------------------------------------------------

%------------------------------------------------------------------------
function vf = vfiles(job)
opts  = job.output;
sopts = [opts.GM;opts.WM;opts.CSF];
vf    = cell(numel(job.data),2);
for i=1:numel(job.data),
    [pth,nam,ext] = spm_fileparts(job.data{i});
    vf{i,1} = fullfile(pth,[nam '_seg_sn.mat']);
    vf{i,2} = fullfile(pth,[nam '_seg_inv_sn.mat']);
    j       = 3;
    if opts.biascor,
        vf{i,j} = fullfile(pth,['m' nam ext ',1']);
        j       = j + 1;
    end;
    for k1=1:3,
        if sopts(k1,3),
            vf{i,j} = fullfile(pth,[  'c', num2str(k1), nam, ext, ',1']);
            j       = j + 1;
        end;
        if sopts(k1,2),
            vf{i,j} = fullfile(pth,[ 'wc', num2str(k1), nam, ext, ',1']);
            j       = j + 1;
        end;
        if sopts(k1,1),
            vf{i,j} = fullfile(pth,['mwc', num2str(k1), nam, ext, ',1']);
            j       = j + 1;
        end;
    end;
end;
vf = vf(:);
