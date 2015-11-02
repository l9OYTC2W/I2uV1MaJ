function show_image(img, slices, fig)
% FORMAT show_image(img, slices, fig)
%
% Shows slice by slice display of image 'img', either
% filename, vol struct (see spm_vol), or 3D matrix
%
% Optionally can specify vector of slices to display ('slices') and figure
% to display on ('fig')
% See slice_overlay for more details
%
% Matthew Brett 3/8/00
  
clear global SO
global SO
if nargin < 1
  img = spm_get(1, 'img', 'Image to display');
end
if nargin < 2
  slices = [];
end
if nargin < 3
  fig = [];
end
if ischar(img)
  img = spm_vol(img(1,:));
end
if isstruct(img)
  SO.img(1).vol = img;
else
  SO.img(1).vol = slice_overlay('matrix2vol',img);
end
SO.img(1).cmap = gray;
SO.figure = fig;
SO.slices = [];
slice_overlay;
  