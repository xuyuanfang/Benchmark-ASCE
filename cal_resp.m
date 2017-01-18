%************************************************************
% cal_resp: Time domain response calculation
%           for the Benchmark Problem of the 
%				ASCE Task Group on Structural Health Monitoring
%************************************************************
%  Note:
%  Although this function can be called alone, it is better
%  to call it through datagen.
%************************************************************
%  [acc,force,time]=cal_resp(caseid,K,M,T,S,e,dt,Duration, ...
%                            SeedNum,noiselevel,methodid,Findx);
% INput parameters:
%  caseid   =  Case index can be 1, 2, 3, 4 and 5 
%              correspoinding to CASE 1 to 5, respectively.
%              [MUST given]
%  K        =  system stiffness matrix (transformed).
%              [MUST given]
%  M        =  system mass matrix (transformed).
%              [MUST given]
%  T        =  transformation matrix for the consideration
%              of rigid-floor effect.
%              [MUST given]
%  S        =  force intensity.
%              [default: interactive]
%  e        =  damping ratio.
%              If only one value is given, all modes assumed 
%              to have the same damping.
%              [default: interactive]
%  dt       =  time step size.
%              [default: interactive]
%  Duration =  time duration for analysis.
%              [default: interactive]
%  SeedNum  =  seed for random number generation.
%              [default: interactive]
%  noiselevel  noise level to be added for measurement noise
%              simulation.
%              [default: interactive]
%  methodid =  Response calculation method index (1, 2 or 3)
%              1  - lsim (you must have Sontrol Toolbox)
%              2  - Nigham-Jennings Algorithm
%                   (relatively slower when compared with lsim)
%              3  - FAST Nigham-Jennings Algorithm
%                   (you must have SimuLink)
%              [default: interactive]
%  Findx    =  Filter index = 1 or 0
%              1  -  use a filter to handle the direct
%                    pass-through problem.
%              0  -  no filter.
%
% OUTput parameters:
%  acc      =  simulated acceleration time-history.
%              It is a Nt by Nmdof array:
%              Nt    =  number of time steps
%              Nmdof =  number of measured dof
%              ==============================================
%              column number (x-coordinate, y-coordinate):
%              7 (   0, 2.5)  8 (1.25, 2.5)  9 ( 2.5, 2.5)
%              4 (   0,1.25)  5 (1.25,1.25)  6 ( 2.5,1.25)
%              1 (   0,   0)  2 (1.25,   0)  3 ( 2.5,   0)
%              ==============================================
%              for each floor, sensors are located at columns 
%              2, 6, 8 and 4.
%              acc(:,1)  - floor 1 of column 2 in x-direction
%              acc(:,2)  - floor 1 of column 6 in y-direction
%              acc(:,3)  - floor 1 of column 8 in x-direction
%              acc(:,4)  - floor 1 of column 4 in y-direction
%              acc(:,5)  - floor 2 of column 2 in x-direction
%              acc(:,6)  - floor 2 of column 6 in y-direction
%              acc(:,7)  - floor 2 of column 8 in x-direction
%              acc(:,8)  - floor 2 of column 4 in y-direction
%              acc(:,9)  - floor 3 of column 2 in x-direction
%              acc(:,10) - floor 3 of column 6 in y-direction
%              acc(:,11) - floor 3 of column 8 in x-direction
%              acc(:,12) - floor 3 of column 4 in y-direction
%              acc(:,13) - floor 4 of column 2 in x-direction
%              acc(:,14) - floor 4 of column 4 in y-direction
%              acc(:,15) - floor 4 of column 6 in x-direction
%              acc(:,16) - floor 4 of column 8 in y-direction
%  force    =  External loading time history
%              ==============================================
%              In CASE 1 to 2:
%              force(:,i) is the loading in the 
%              y-direction at the i-th floor for i = 1 to 4.
%              In CASE 3 to 5:
%              force(:,1) is the loading in the x-direction 
%              at the root; and 
%              force(:,2) is that in the y-direction.
%  time     =  the corresponding time axis.
%
% See also DATAGEN, CAL_MODEL
%

% Call:        NJ_integrator.MDL
% Subfunction: msuper, eigen, addnoise, sdofsys
%              njcoeff
% by Paul Lam <paullam@ust.hk>, 18-Jan-2000
%************************************************************
function [acc,force,time]=cal_resp(caseid,K,M,T,S,e,dt,Duration,SeedNum,noiselevel,methodid,Findx);
if nargin < 1,    caseid=[];     end;
if nargin < 2,    K=[];          end;
if nargin < 3,    M=[];          end;
if nargin < 4,    T=[];          end;
if nargin < 5,    S=[];          end;
if nargin < 6,    e=[];          end;
if nargin < 7,    dt=[];         end;
if nargin < 8,    Duration=[];   end;
if nargin < 9,    SeedNum=[];    end;
if nargin < 10,   noiselevel=[]; end;
if nargin < 11,   methodid=[];   end;
if nargin < 12,   Findx=[];      end;
ProgramName='ASCE Benchmark Problem: Response Calculation Program';

% ***** check for input parameters *****
menuid=0;
if isempty(caseid)==1,  error('caseid is missing ...');  end;
if isempty(K)==1,       error('K is missing ...');       end;
if isempty(M)==1,       error('M is missing ...');       end;
if isempty(T)==1,       error('T is missing ...');       end;
if isempty(e)==1,          e=0.01;              menuid=1; end;
if isempty(dt)==1,         dt=0.001;            menuid=1; end;
if isempty(Duration)==1,   Duration=40;         menuid=1; end;
if isempty(noiselevel)==1, noiselevel=10;       menuid=1; end;
if isempty(S)==1,          S=150;               menuid=1; end;
if isempty(SeedNum)==1,    SeedNum=123;         menuid=1; end;
if isempty(Findx)==1,      Findx=1;             menuid=1; end;

% ***** get methodid from the user *****
MethodID={
   'lsim (You MUST have Control Toolbox)'
   'Nigham-Jennings Algorithm (VERY SLOW)'
   'FAST Nigham-Jennings Algorithm (You MUST have SimuLink)'
   'QUIT'
};
if isempty(methodid)==1
   methodid=menu('Use what method in responses calculation?',MethodID);
   if methodid==4
      error('user cancel operation ...');
   end;
end;
if methodid~=1 & methodid~=2 & methodid~=3
   error('methodid must be 1, 2 or 3 ...');
end;

% ***** define forindx and Sindx accroding to caseid *****
switch caseid
case {1,2}
   disp('input at each floor in y-dir');
   forindx=[2 5 8 11]; Sindx=1;
case {3,4,5}
   disp('input at the roof parallel to diagonal');
   forindx=[10 11]; Sindx=1/(2)^0.5;
otherwise
   error('caseid must be 1 to 5 ...');
end;

% ***** if some input parameters are missing -> interactive input *****
if menuid==1
   ParameterID={
      'Damping ratio:'
      'Time step size:'
      'Time duration:'
      'Noise level:'
      'Force intensity:'
      'Seed number for force generation:'
      'Filter index:'
   };
   ParameterDef={
      num2str(e)
      num2str(dt)
      num2str(Duration)
      num2str(noiselevel)
      num2str(S)
      num2str(SeedNum)
      num2str(Findx)
   };
   answer=inputdlg(ParameterID,ProgramName,1,ParameterDef);
   if isempty(answer)~=1
      e=             str2num(char(answer(1)));
      dt=            str2num(char(answer(2)));
      Duration=      str2num(char(answer(3)));
      noiselevel=    str2num(char(answer(4)));
      S=             str2num(char(answer(5)));
      SeedNum=       round(str2num(char(answer(6))));
      Findx=         str2num(char(anser(7)));
   else
      error('user cancel operation ....');
   end;
end;

% ***** force and time generation *****
randn('state',SeedNum);
time=[0:dt:Duration]';
Nt=length(time);

if Findx==1
   filter_order = 6;
   filter_cutoff = 100; %Hz
   [filt_num,filt_den] = butter(filter_order,filter_cutoff*2*dt);
   Nt2=Nt+2*filter_order;
else
   Nt2=Nt;
end;

switch caseid
case {1,2}
   force=S*Sindx*randn(Nt2,length(forindx))./dt^0.5;
case {3,4,5}
   force=(S*Sindx*randn(Nt2,1)./dt^0.5)*[-1 1];
end;

if Findx==1
   force = filter(filt_num,filt_den,force);
   force = force(Nt2-Nt+1:end,:);
end;

% ***** responses calculation *****
ACC=msuper(K,M,e,force,dt,forindx,methodid);

% ***** select the measured dofs from the calculated responses *****
dofv=[7 32 43 20 61 86 97 74 115 140 151 128 169 194 205 182];
acc=(T(dofv,:)*ACC')';

% ***** add noise to the calculated response *****
acc=addnoise(acc,noiselevel);

%************************************************************
% END of program cal_resp!!
%************************************************************


%============================================================
% msuper:   Time domain response calculation by the method of
%           modal superposition.
%============================================================
function ACC=msuper(K,M,e,force,dt,mdof,methodid);
if nargin < 7, error('not enough input parameters ...'); end;

% ***** input parameters dimension check *****
Ndof=length(K);
Sofe=size(e);
if max(Sofe)==1
   e=e.*ones(Ndof,1);
end;
if min(Sofe)~=1
   error('e can NOT be a matrix ...');
end;
[SofT,Sof2]=size(force);
if Sof2~=length(mdof)
   error('force dimension error ...');
end;

% ***** de-couple equation of motion *****
[eigval,eigvec]=eigen(K,M);
fi=eigvec(mdof,:)'*force';
mi=eigvec'*M*eigvec;
ki=eigvec'*K*eigvec;

% ***** calculation N SDOF system *****
h=waitbar(0,'Time history calculating ....');
if methodid==1
   % ***** use lsim for the calculation *****
   for i=1:Ndof
      waitbar(i/Ndof);
      k=ki(i,i);
      m=mi(i,i);
      c=2*e(i)*eigval(i)^0.5;
      f(2,:)=fi(i,:);
      A=[0 1;-k/m -c/m];
      B=[1 0; 0 1/m];
      C=[-k/m -c/m];
      D=[0 1/m];
      oldwarn=warning; warning('off');                  %eaj, no resampling warnings, 5/19/01
      [Y,X]=lsim(A,B,C,D,f',[0:length(fi(i,:))-1]'*dt); %eaj, add ', 5/19/01
      warning(oldwarn);                                 %eaj, no resampling warnings, 5/19/01
      am(i,:)=Y';
   end;
elseif methodid==2
   % ***** call sdofsys (using Nigham-Jennings algorithm) for the calculation *****
   for i=1:Ndof
      waitbar(i/Ndof);
      [x,xd,xdd]=sdofsys((ki(i,i)/mi(i,i))^0.5,e(i),fi(i,:),dt,0);
      am(i,:)=xdd;
   end;
elseif methodid==3
   % ***** call sdofsys (using FAST Nigham-Jennings algorithm) for the calculation *****
   for i=1:Ndof
      waitbar(i/Ndof);
      [x,xd,xdd]=sdofsys((ki(i,i)/mi(i,i))^0.5,e(i),fi(i,:),dt,1);
      am(i,:)=xdd;
   end;
end;
close(h);
% ***** combine N SDOF system response to get overall response *****
clear x xd X Y force f
ACC=(eigvec*am)';



%============================================================
% eigen: Calculate the eigenvalue and eigenvector of a set of
%        given K and M.
%============================================================
function [evalue,evector]=eigen(K,M);
[V,D]=eig(inv(M)*K);
[evalue,indx]=sort(diag(D));
evector=V(:,indx);
MM=evector'*M*evector;
if min(diag(MM))<=0, error('mode shape calculation error!!'); end;
for i=1:length(K)
   evector(:,i)=evector(:,i)./MM(i,i)^0.5;
end;


%============================================================
% addnoise: Add noise to a matrix.
%============================================================
function Xt=addnoise(Xt,nl);
[a,b]=size(Xt);
if a < b
   Xt=Xt';
   [a,b]=size(Xt);
   transp=1;
else
   transp=0;
end;
% ***** calculate the rms of responses from all sensors
% ***** and use only the max one for all sensors.
for i=1:b
   rms(i)=(sum(Xt(:,i).^2)/a)^0.5;
end;
mrms=max(rms);
for i=1:b
   RdNoise=randn(a,1);
   RdNoise=RdNoise./std(RdNoise);
	Xt(:,i)=Xt(:,i)+nl/100*mrms.*RdNoise;
end;
if transp==1, Xt=Xt'; end;


%============================================================
% sdofsys:  calculation of time domain response for a sdof 
%           system.
%============================================================
%  SLindx   =  SimuLink index = 1 or 0
%              1  -  use SimuLink to speedup the Nigham-Jennings
%                    integration.
%              0  -  no speedup -> very very slow!!
%============================================================
function [x,xd,xdd]=sdofsys(w,e,force,dt,SLindx);
if nargin < 5, error('not enough input parameters ...'); end;
Soff=size(force);
Nt=max(Soff);
[TA,TB]=njcoeff(e,w,dt);
if SLindx==1
   time=[0:length(force)-1]'.*dt;
   U=[force' [force(2:end) 0]'];
   OPTIONS=simset('SrcWorkspace','current');
   [TOUT,X,Y]=sim('NJ_integrator',[],OPTIONS);
   x=X(:,1)'; xd=X(:,2)';
   clear TOUT X Y clear U clear time
else
   x(1)=0;
   xd(1)=0;
   for i=1:Nt-1
      x(i+1) =TA(1,1)*x(i)+TA(1,2)*xd(i)+TB(1,1)*force(i)+TB(1,2)*force(i+1);
      xd(i+1)=TA(2,1)*x(i)+TA(2,2)*xd(i)+TB(2,1)*force(i)+TB(2,2)*force(i+1);
   end;
end;
xdd=force-2*e*w*xd-w^2*x;


%============================================================
% njcoeff: Nigham-Jennings coeff. calculation for SDOF 
%          system responses calculation.
%============================================================
function [TA,TB]=njcoeff(d,w,dt);
if nargin < 3, error('not enough input parameters ...'); end;
% ***** start calcultion *****
if d > 1
   dw=d*w;
   a1=-dw+(d^2-1)^0.5*w;
	a2=-dw-(d^2-1)^0.5*w;
	a12=a1^2;
	a22=a2^2;
	a1a2=a1*a2;
	ea1=exp(a1*dt);
	ea2=exp(a2*dt);
	ad=a1-a2;
	adt=ad*dt;
	TA(1,1)=(a1*ea2-a2*ea1)/ad;
	TA(1,2)=(ea1-ea2)/ad;
	TA(2,1)=-a1a2*(ea1-ea2)/ad;
	TA(2,2)=(a1*ea1-a2*ea2)/ad;
	TB(1,1)=1/ad*(ea1/a1-ea2/a2)+1/adt*(1/a12-ea1/a12-1/a22+ea2/a22);
	TB(1,2)=1/ad*(-1/a1+1/a2)+1/adt*(-1/a12+ea1/a12+1/a22-ea2/a22);
	TB(2,1)=-(a1-a1*ea2-a2+a2*ea1-a1a2*dt*(ea1-ea2))/(a1a2*adt);
	TB(2,2)=-(-a1+a1*ea2+a2-a2*ea1)/(a1a2*adt);
else
	dw=d*w;
	d2=d^2;
	a0=exp(-dw*dt);
	a1=w*(1-d2)^0.5;
	ad1=a1*dt;
	a2=sin(ad1);
	a3=cos(ad1);
	w2=w^2;
	a4=(2*d2-1)/w2;
	a5=d/w;
	a6=2*a5/w2;
	a7=1/w2;
	a8=(a1*a3-dw*a2)*a0;
	a9=-(a1*a2+dw*a3)*a0;
	a10=a8/a1;
	a11=a0/a1;
	a12=a11*a2;
	a13=a0*a3;
	a14=a10*a4;
	a15=a12*a4;
	a16=a6*a13;
	a17=a9*a6;
	TA(1,1)=a0*(dw*a2/a1+a3);
	TA(1,2)=a12;
	TA(2,1)=a10*dw+a9;
	TA(2,2)=a10;
	TB(1,1)=(-a15-a16+a6)/dt-a12*a5-a7*a13;
	TB(1,2)=(a15+a16-a6)/dt+a7;
	TB(2,1)=(-a14-a17-a7)/dt-a10*a5-a9*a7;
	TB(2,2)=(a14+a17+a7)/dt;
end;
