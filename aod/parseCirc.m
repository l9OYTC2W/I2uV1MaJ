function [varnum,timeWindow]=parseCirc(infile,varname);

% function to read circ input files
% by Adrien Desjardins

% for i=1:nlines,fprintf('%d: %s\n',i,lines(i,:)),end
% for i=1:size(tlines,1),fprintf('%d: %s\n',i,tlines(i,:)),end

% read entire file into memory
[lines,nlines]=readLines(infile);
if ~nlines
   error('Empty input file!');
end
% ignore all comments
tlines=[];
for ln=1:nlines
   line=deblank2(lines(ln,:));     
   cind=findstr('#',line);
   if ~isempty(cind)
      if cind(1)==1
         line=[];
      else
         line=line(1:cind(1)-1);
      end      
   end   
   if ~isempty(line)
      if isempty(tlines)
         tlines=line;
      else
         tlines=str2mat(tlines,line);
      end 
   end
end
lines=tlines;
nlines=size(lines,1);
if nlines==0
   error('No non-commented lines in input file!');
end

% look for name
lnum=[];
for ln=1:nlines
   line=deblank2(lines(ln,:));  
   if isempty(findstr('var',line))
      ind1=findstr(varname,line);
      ind2=findstr('=',line);
      if length(ind1) & length(ind2)==1
         if ind1(1)==1
            if strcmp(varname,deblank2(line(1:(ind2-1))))
               lnum=ln;
            end            
         end      
      end         
   end
end
if isempty(lnum)
   error(['Could not find variable ' varname '!']);
end

% find nearest line with definition
ln=lnum;
dln=[];
while ln > 1
   ln=ln-1;
   line=deblank2(lines(ln,:));
   ind=findstr('.{',line);
   if length(ind)
      dln=ln;
      break;
   end   
end
if isempty(dln)   
   error('Could not find definition for variable!');
end

%%%%% parse definition line
% find:
% 	- varnum: code for variable
%	- timeWindow: struct
dline=deblank2(lines(dln,:));
cbind=findstr('}',dline);
obind=findstr('}',dline);
colind=findstr(':',dline);
% make sure syntax is OK
if isempty(cbind) | isempty(colind)
   error('Bad syntax in definition line,1!');
end
if cbind(1) < colind(1)
   error('Bad syntax in definition line,2!');
end   
if length(obind) ~= length(cbind)
   error('Bad syntax in definition line,3!');
end
nlist=dline((colind(1)+1):(cbind(1)-1));
indlist=findstr(char(59),nlist);
nlist(indlist)=' ';
varnum=str2num(nlist);
if isempty(varnum)
   error('Bad syntax in definition line,4!');
end   
if length(obind) == 1
   timeWindow=[];
else
   dline=dline((cbind(1)+1):length(dline));   
   ltind=findstr('<',dline);
   gtind=findstr('>',dline);
   ddind=findstr('..',dline);
   if ~(length(ltind) == 1 & length(gtind) == 1 & length(ddind)==1)
      error('Bad syntax in definition line!,5');   
   end
   if ~(ltind < ddind & ddind < gtind)
      error('Bad syntax in definition line!,6');   
   end
   isnot=findstr('~',dline);
   if length(isnot) > 1
      error('Bad syntax in definition line!,7');    
   end
   if isnot
      outCode=str2num(dline((isnot+1):(length(dline)-1)));
   else
      outCode=str2num(dline((gtind+1):(length(dline)-1)));  
   end
   isnot=length(isnot);
   minTime=str2num(dline((ltind+1):(ddind-1)));
   maxTime=str2num(dline((ddind+2):(gtind-1)));
   if ~(~isempty(minTime) & ~isempty(maxTime) & ~ isempty(outCode))
      error('Bad syntax in definition line!,8');   
   end   
   timeWindow=struct('varnum',varnum,'minTime',minTime,'maxTime',maxTime,'isnot',isnot,'outCode',outCode);
end