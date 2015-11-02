function printTable(matrix,arg)
% prints file with matrix of numbers
if isempty(matrix),return,end;
if ischar(arg)
filename=arg;
fidw=fopen(filename,'w');
else
fidw=arg;
end
if fidw < 0,error(['Could not write to file!']),end;
[nx,ny]=size(matrix);
for ix=1:nx
for iy=1:ny
fprintf(fidw,'%6.3f\t',matrix(ix,iy));
end
fprintf(fidw,'\n');
end
