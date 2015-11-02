function intens=getVoxelIntensity(xyz,type,arg1,arg2,arg3)

% There are two ways to call this function:

% getVoxelIntensity(xyz,1,file,interp_type)
% xyz is a list of voxels, like xyz=[[0 0 0];[4 4 4];...;[8 4 10]];
% interp_type - 0: nearest neighbour, 1: trilinear (see spm_sample_vol for details)

% getVoxelIntensity(xyz,2,V,iM,interp_type)
% xyz is a list of voxels, like xyz=[[0 0 0];[4 4 4];...;[8 4 10]];

if isempty(xyz)
   intens=[];
   return;
end
if type==1 
	file=arg1;
	if ~exist(file)		
		error(['File ' file ' does not exist!']);
	end
	[DIM,VOX,SCALE,TYPE,OFFSET,ORIGIN,DESCRIP] = spm_hread(file);
	M=zeros(4); M([1 6 11 13:16])=[VOX -ORIGIN.*VOX 1]; iM=inv(M);
	rcp=iM*[xyz';ones(1,size(xyz,1))];
	V=spm_vol(file);
	intens=spm_sample_vol(V,rcp(1,:),rcp(2,:),rcp(3,:),arg2)';
else
	rcp=arg2*[xyz';ones(1,size(xyz,1))];
	intens=spm_sample_vol(arg1,rcp(1,:),rcp(2,:),rcp(3,:),arg3)';				
end	




