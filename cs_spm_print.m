function cs_spm_print(fileName)
% Use spm print function

return;

global defaults;

% Store old value
uiPrint = defaults.ui.print;

[pathstr, fName, extn] = fileparts(fileName);

figHandle = spm_figure('FindWin','Graphics');

%% Capture frame
try
    captured_frame = getframe(figHandle(1));
catch
    captured_frame.cdata = [];
end

psToJpg = 0;
if strcmpi(extn, '.jpg') || strcmpi(extn, '.jpeg')
    if (~isempty(captured_frame.cdata))
        % JPEG file
        defaults.ui.print   = struct('opt', {{'-djpeg', '-append'}},'append', true, 'ext', '.jpg');
    else
        psToJpg = 1;
        defaults.ui.print   = struct('opt', {{'-dpsc2', '-append'}}, 'append', true, 'ext', '.ps');
    end
elseif strcmpi(extn, '.ps')
    % Postscript file
    defaults.ui.print   = struct('opt', {{'-dpsc2', '-append'}}, 'append', true, 'ext', '.ps');
end

if (psToJpg)
    psFile =  fullfile(pathstr, [fName, '.ps']);
    if (exist(psFile, 'file'))
        delete(psFile);
    end
    spm_print(psFile);
else
    spm_print(fileName);
end

if (psToJpg)
    figPos = get(figHandle(1), 'position');
    img_resolution(1) = 1100;
    img_resolution(2) = img_resolution(1)/(figPos(3)/figPos(4));
    img_resolution_str = [num2str(img_resolution(1)), 'x', num2str(img_resolution(2))];
    print_commands = ['gs -q -dNOPAUSE -dBATCH -sDEVICE=jpeg -r144 -sOutputFile=', fileName, ' ', fullfile(pathstr, [fName, '.ps']), ...
        '; convert ', fileName, ' -depth 16 -resize ', img_resolution_str, '\! ', fileName];
    system(print_commands);
end

% Assign old value
defaults.ui.print = uiPrint;
