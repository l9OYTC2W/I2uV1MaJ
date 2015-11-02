function f=mc(x)
% mean correction
if isempty(x)
f=[];
else
f=x-ones(size(x,1),1)*mean(x);
end