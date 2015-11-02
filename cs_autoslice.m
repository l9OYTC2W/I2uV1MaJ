function attachments=cs_autoslice
%% Function to do slice overlay using slover
%

global csprefs;
global cstemp;
global defaults;

sub_dir = pwd;
progFile = fullfile(pwd,'cs_progress.txt');
cs_log( ['Beginning cs_autoslice for ',pwd], progFile );

if ~isempty( csprefs.stats_dir_name )
    try
        cd( csprefs.stats_dir_name );
    catch
        error('No stats directory -- cs_autoslice is bailing out!');
    end
end

attachments={};
print_cmd='print -djpeg -painters -noui';
cstemp.con=[];

structVol = spm_vol(csprefs.autoslice_background);

cstemp.pval = csprefs.autoslice_p;

interpOrder = 0;
if isfield(csprefs, 'autoslice_interp')
    interpOrder = csprefs.autoslice_interp;
end

load(fullfile(pwd, 'SPM.mat'));

writeMask(sub_dir, print_cmd);


%% Initialise successfull contrasts
successFullContrasts = zeros(1, length(csprefs.autoslice_cons));
countCon = 0;

% Loop over required contrasts
for i = csprefs.autoslice_cons
    countCon = countCon + 1;
    if ~isempty(SPM.xCon(i).Vcon)
        current_con_file = SPM.xCon(i).Vcon(1).fname;
        if ~exist(current_con_file, 'file')
            continue;
        end
    else
        continue;
    end
    cstemp.con = i;
    [myspm, myxspm] = cs_getSPM;
    
    SO = [];
    
    % Structural
    SO.slices = csprefs.autoslice_slices;
    SO.img(1).vol = structVol;
    SO.img(1).prop = 1;
    SO.img(1).type = 'truecolor';
    SO.img(1).cmap = gray;
    %SO.img(1).range = [0, max(template_data(:))];
    SO.img(1).hold = interpOrder;
    SO.img(1).background = NaN;
    SO.img(1).outofrange = {1, 64};
    SO.img(1).nancol = 0;
    SO.cbar = [];
    
    
    % Blobs
    SO.img(2).vol = slover('blobs2vol', myxspm.XYZ, myxspm.Z, myxspm.M);
    SO.img(2).prop = 1;
    SO.img(2).type = 'split';
    SO.img(2).cmap = hot;
    SO.img(2).range = [min(myxspm.Z), max(myxspm.Z)];
    SO.img(2).hold = interpOrder;
    SO.img(2).background = NaN;
    SO.img(2).outofrange = {0, 64};
    SO.img(2).nancol = 0;
    
    SO.cbar = [SO.cbar, 2];
    
    %% Invoke slover
    checkAutoSlice = 1;
    try
        SO = slover(SO);
        paint(SO);
    catch
        checkAutoSlice = 0;
        fprintf('\n');
        disp(sprintf('Unable to create autoslice for image %s', current_con_file));
        fprintf('\n');
    end
    
    successFullContrasts(countCon) = checkAutoSlice;
    
    if (~checkAutoSlice)
        continue;
    end
    
    drawnow;
    
    aH1 = axes('parent', SO.figure, 'units', 'normalized', 'Position',[0.0460,0.9515,0.1,0.1],'Visible','off','Tag','SPMprintFootnote');
    text(0,0,sub_dir, 'parent', aH1);
    aH2 = axes('parent', SO.figure, 'units', 'normalized', 'Position',[0.0460,0.9315,0.1,0.1],'Visible','off','Tag','SPMprintFootnote');
    titleStr=[myspm.xCon(cstemp.con).name,', p<',num2str(csprefs.autoslice_p),', uncorrected'];
    text(0,0,titleStr, 'parent', aH2);
    
    %% Print to jpeg format
    print_name = sprintf('con_%.4d_%s.jpg', cstemp.con, myspm.xCon(cstemp.con).name);
    print_fig(SO, print_name, print_cmd);
    
    % Print to post script format
    print2_name = sprintf('con_%.4d_%s.ps', cstemp.con, myspm.xCon(cstemp.con).name);
    print_fig(SO, print2_name, 'print -dpsc2 -painters -noui');
    
    %% Capture frame
    try
        captured_frame = getframe(SO.figure);
    catch
        captured_frame.cdata = [];
    end
    
    %% Use Ghostscript and ImageMagick commands to handle the aspect ratio
    % problem on matlab without display
    if isempty(captured_frame.cdata)
        figPos = get(SO.figure, 'position');
        img_resolution(1) = 1100;
        img_resolution(2) = img_resolution(1)/(figPos(3)/figPos(4));
        img_resolution_str = [num2str(img_resolution(1)), 'x', num2str(img_resolution(2))];
        print_commands = ['gs -q -dNOPAUSE -dBATCH -sDEVICE=jpeg -r144 -sOutputFile=', print_name, ' ', print2_name, ...
            '; convert ', print_name, ' -depth 16 -resize ', img_resolution_str, '\! ', print_name];
        system(print_commands);
    end
    
    cs_log(['    file ',print_name,' created successfully'],progFile,1);
    if any(csprefs.autoslice_email_cons==cstemp.con)
        attachments{end+1}=fullfile(pwd,print_name);
    end
    
    clear SO;
    
end
% End loop over contrasts

clear cstemp;

%% Form Autoslice string
autoSliceCon = csprefs.autoslice_cons;
successFullContrasts = (successFullContrasts == 1);
autoSliceCon(successFullContrasts == 0) = [];
autoSliceConStr = '';
if ~isempty(autoSliceCon)
    autoSliceConStr = mat2str(autoSliceCon);
end

if ~isempty(autoSliceConStr)
    
    cs_log( ['cs_autoslice completed for ',sub_dir],                                            progFile );
    cs_log( ['    csprefs.autoslice_cons = ', autoSliceConStr],                                 progFile, 1 );
    cs_log( ['    csprefs.autoslice_p = ', num2str(csprefs.autoslice_p)],                       progFile, 1 );
    cs_log( ['    csprefs.autoslice_background = ', csprefs.autoslice_background],               progFile, 1 );
    cs_log( ['    csprefs.autoslice_slices = ', mat2str(csprefs.autoslice_slices)],              progFile, 1 );
    % cs_log( ['    csprefs.autoslice_email_cons = ', mat2str(csprefs.autoslice_email_cons)],      progFile, 1 );
    
end

cd(sub_dir);


function writeMask(sub_dir, print_cmd)

global csprefs;

SO = [];

% Structural
SO.slices = csprefs.autoslice_slices;

% Blobs
SO.img(1).vol = spm_vol('mask.img');
SO.img(1).prop = 1;
SO.img(1).type = 'split';
SO.img(1).cmap = hot;
SO.img(1).range = [0, 1];
SO.img(1).hold = 0;
SO.img(1).background = NaN;
SO.img(1).outofrange = {0, 64};
SO.img(1).nancol = 0;

SO.cbar = [];

SO = slover(SO);
paint(SO);


drawnow;

aH1 = axes('parent', SO.figure, 'units', 'normalized', 'Position',[0.0460,0.9515,0.1,0.1],'Visible','off','Tag','SPMprintFootnote');
text(0,0,sub_dir, 'parent', aH1);
aH2 = axes('parent', SO.figure, 'units', 'normalized', 'Position',[0.0460,0.9315,0.1,0.1],'Visible','off','Tag','SPMprintFootnote');
titleStr='Mask';
text(0,0,titleStr, 'parent', aH2);


%% Print to jpeg format
print_name = 'mask.jpg';
print_fig(SO, print_name, print_cmd);

% Print to post script format
print2_name = 'mask.ps';
print_fig(SO, print2_name, 'print -dpsc2 -painters -noui');

%% Capture frame
try
    captured_frame = getframe(SO.figure);
catch
    captured_frame.cdata = [];
end

%% Use Ghostscript and ImageMagick commands to handle the aspect ratio
% problem on matlab without display
if isempty(captured_frame.cdata)
    figPos = get(SO.figure, 'position');
    img_resolution(1) = 1100;
    img_resolution(2) = img_resolution(1)/(figPos(3)/figPos(4));
    img_resolution_str = [num2str(img_resolution(1)), 'x', num2str(img_resolution(2))];
    print_commands = ['gs -q -dNOPAUSE -dBATCH -sDEVICE=jpeg -r144 -sOutputFile=', print_name, ' ', print2_name, ...
        '; convert ', print_name, ' -depth 16 -resize ', img_resolution_str, '\! ', print_name];
    system(print_commands);
end