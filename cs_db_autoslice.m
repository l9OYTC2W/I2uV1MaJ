function cs_db_autoslice

global csprefs;
sub_dir=pwd; 
t_threshold = 1.68;
structVol = spm_vol(csprefs.autoslice_background);

print_cmd='print -djpeg -painters -noui';
for i=1:length(csprefs.dboost_im_names)
    currentFile = csprefs.dboost_im_names{i};
    if ~exist(currentFile, 'file')
        continue;
    end
    [pp, titleName] = fileparts(currentFile);
    SO = [];

    % Structural
    SO.slices = csprefs.autoslice_slices;
    SO.img(1).vol = structVol;
    SO.img(1).prop = 1;
    SO.img(1).type = 'truecolor';
    SO.img(1).cmap = gray;
    %SO.img(1).range = [0, max(template_data(:))];
    SO.img(1).hold = 0;
    SO.img(1).background = NaN;
    SO.img(1).outofrange = {1, 64};
    SO.cbar = [];


    currentV = spm_vol(currentFile);
    data = spm_read_vols(currentV);

    % Blobs
    SO.img(2).vol = currentV;
    SO.img(2).prop = 1;
    SO.img(2).type = 'split';
    SO.img(2).cmap = hot;
    SO.img(2).range = [t_threshold, max(data(:))];
    SO.img(2).hold = 0;
    SO.img(2).background = NaN;
    SO.img(2).outofrange = {0, 64};

    SO.cbar = [SO.cbar, 2];

    % Invoke slover
    SO = slover(SO);
    paint(SO);

    pause(1);

    axes('Position',[0.0460,0.9515,0.1,0.1],'Visible','off','Tag','SPMprintFootnote');
    text(0,0,sub_dir);
    axes('Position',[0.0460,0.9315,0.1,0.1],'Visible','off','Tag','SPMprintFootnote');
    title = titleName;
    text(0,0,title);
    print_name = [titleName, '.jpg'];
    print_fig(SO, print_name, print_cmd); 
    clear SO;

end