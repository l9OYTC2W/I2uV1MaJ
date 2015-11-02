function c = cool(m)
%COOL   Shades of cyan and magenta color map.
%   COOL(M) returns an M-by-3 matrix containing a "cool" colormap.
%   COOL, by itself, is the same length as the current colormap.
%
%   For example, to reset the colormap of the current figure:
%
%             colormap(cool)
%
%   See also HSV, GRAY, HOT, BONE, COPPER, PINK, FLAG, 
%   COLORMAP, RGBPLOT.

%   C. Moler, 8-19-92.
%   Copyright (c) 1984-98 by The MathWorks, Inc.
%   $Revision: 5.3 $  $Date: 1997/11/21 23:33:41 $

if nargin < 1, m = size(get(gcf,'colormap'),1); end
black=13;
r = (0:m-1)'/max(m-1,1);
c_temp1 = [1-r r ones(m,1)];
c = [zeros(black,3); c_temp1];



