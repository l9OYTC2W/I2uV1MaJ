function Z=r2Z(r,N)
%%%%%
% implementation of Fisher Z-tranform for correlations
% with the null hypothesis of zero correlation
%
% see http://eksl-www.cs.umass.edu/eis/pages/techniques/r-to-z-desc.html
% for details
%
% by Adrien Desjardins
% Feb 8, 2001
%%%%%

% Check input
inds=find(r > 1);
if ~isempty(inds)
   error('Correlations must lie strictly between -1 and 1!');
end
inds=find(abs(r)==1);
if ~isempty(inds)
	r(inds)=NaN;
end
if N <= 3
   error('Must have N > 3!');
end
Z=0.5*log((1+r)./(1-r))*sqrt(N-3);
Z(find(isnan(Z)))=Inf;


