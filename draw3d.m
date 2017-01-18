%************************************************************
% draw3d:   Draw the 3-D structure based on structure
%           information node and elem (from cal_model)
%************************************************************
%  draw3d(node,elem,Nindx,Eindx);
% INput parameters:
%  node     =  node coordinates and constrains index.
%  elem     =  element connectivity and element group number.
%  Nindx    =  node number display index, 1 for display
%  Eindx    =  element number display index, 1 for display
%
% NO OUTput parameter
%
% See also CAL_MODEL
%

% by Paul Lam <paullam@ust.hk>, 18-Jan-2000
%************************************************************
function draw3d(node,elem,Nindx,Eindx);
if nargin < 1, node=[];    end;
if nargin < 2, elem=[];    end;
if nargin < 3, Nindx=[];   end;
if nargin < 4, Eindx=[];   end;
if isempty(node)==1,    error('node is missing ...'); end;
if isempty(elem)==1,    error('elem is missing ...'); end;
if isempty(Nindx)==1,   Nindx=1;                         end;
if isempty(Eindx)==1,   Eindx=1;                         end;
ltele='b-';
ltfee='ro';
ltsp1='rs';
ltsp2='r^';
ltsp3='rx';
Rx=max(node(:,1))-min(node(:,1));
Ry=max(node(:,2))-min(node(:,2));
Rz=max(node(:,3))-min(node(:,3));
dx=Rx/50; dy=Ry/50; dz=Rz/50;
[nnum,DUM]=size(node);
[enum,DUM]=size(elem);
if ishold==0, hold on, hold_state=0;
else, hold_state=1; end;
for i=1:enum
	x=[node(elem(i,1),1) node(elem(i,2),1)];
	y=[node(elem(i,1),2) node(elem(i,2),2)];
	z=[node(elem(i,1),3) node(elem(i,2),3)];
	plot3(x,y,z,ltele);
	if Eindx==1
      h=text(sum(x)/2+dx,sum(y)/2+dy,sum(z/2)+dz,num2str(i));
		set(h,'Color','b');
	end;
end;
count=1;
for i=1:nnum
   [I,J]=find(elem(:,1:2)==i);
   if isempty(I)~=1
      pnode(count,:)=[i node(i,:)]; count=count+1;
   else
      disp(['node ' num2str(i) ' is a dummy node and is removed from the plot ...']);
   end;
end;
for i=1:count-1
   if sum(pnode(i,5:7))<3 & sum(pnode(i,8:10))<3
      plot3(pnode(i,2),pnode(i,3),pnode(i,4),ltsp1);
   elseif sum(pnode(i,5:7))<3 & sum(pnode(i,8:10))==3
      plot3(pnode(i,2),pnode(i,3),pnode(i,4),ltsp2);
   elseif sum(pnode(i,5:7))==3 & sum(pnode(i,8:10))<3
      plot3(pnode(i,2),pnode(i,3),pnode(i,4),ltsp3);
   elseif sum(pnode(i,5:7))==3 & sum(pnode(i,8:10))==3
      plot3(pnode(i,2),pnode(i,3),pnode(i,4),ltfee);
   end;
   if Nindx==1
      text(pnode(i,2)+dx,pnode(i,3)+dy,pnode(i,4)+dz,num2str(pnode(i,1)));
   end;
end;
if hold_state==0, hold off, end;
xlabel('x-axis'); ylabel('y-axis'); zlabel('z-axis');
axis equal
view(-25,20);
rotate3d on
