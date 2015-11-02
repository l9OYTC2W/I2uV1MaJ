function split2_display
%
% batch for slice_overlay.m
%
% Reproduces positive and negative overlays from the webpage
% http://www.mrc-cbu.cam.ac.uk/Imaging/display_slices.html
% Assumes you have the example images in the current directory

clear global SO
global SO

SO.img(1).vol = spm_vol('avg152T1.img');
SO.img(1).prop = 1;
SO.img(1).cmap = gray;
SO.img(2).vol = spm_vol('con_0010.img');
SO.img(2).range = [3 7.5];
SO.img(2).prop = Inf;
SO.img(2).cmap = hot;
SO.img(3).vol = spm_vol('con_0010.img');
SO.img(3).range = [-2 -4.8];
SO.img(3).prop = Inf;
SO.img(3).cmap = winter;

SO.cbar = [2 3];
SO.transform = 'axial';
SO.slices = -12:6:72;

slice_overlay

