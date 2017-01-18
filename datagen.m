%************************************************************
%  datagen: Acceleration Response Generation Program
%           for the Benchmark Problem of the 
%           ASCE Task Group on Structural Health Monitoring
%************************************************************
%  datagen(caseid,damageid,methodid,e,dt,Duration,noiselevel,S,SeedNum,outfilename,Findx);
%
%  If there is no input parameters given to the program, an 
%  interactive dialog box will show up for you to input them 
%  interactively. So, don't worry about input parameters and 
%  run the program by enter "datagen".
%
% INput parameters:
%  caseid   =  Case index can be 1, 2, 3, 4 and 5
%              correspoinding to CASE 1 to 5, respectively.
%  damageid =  Damage pattern index can be 0 to 7
%              0        -  undamaged case
%              1 to 6   -  damage pattern 1 to 6
%              7        -  user define damage pattern
%  methodid =  Response calculation method index (1, 2 or 3)
%              1  - lsim (you must have Sontrol Toolbox)
%              2  - Nigam-Jennings Algorithm
%                   (relatively slower when compared with lsim)
%              3  - FAST Nigam-Jennings Algorithm
%                   (you must have SimuLink)
%  e        =  damping ratio.
%  dt       =  time step size.
%  Duration =  time duration for analysis.
%  noiselevel  noise level to be added for measurement noise
%              simulation.
%  S        =  force intensity.
%  SeedNum  =  seed for random number generation.
%  outfilename output data file name.
%  Findx    =  Filter index = 0 or 1
%              1  -  use a filter to handle the direct
%                    pass-through problem. [default]
%              0  -  no filter
%              To use this filter, you MUST have the
%              Signal Processing Toolbox.
%
% OUTput parameters:
%  NO OUTput parameters, all calculated results are stored in
%  output data file with file name specified by the user.
%
% See also CAL_MODEL, CAL_RESP
%
% Example:
%  datagen;
%  will let u select the CASE number, damage pattern 
%  number and method of response calculation interactively.
%  After all the interactive input dialog boxes, the program
%  will simulate the structural response and save them in
%  a data file specified by you.
%

%************************************************************
% Meaning of variables in the output data file:
%  K        =  system stiffness matrix (transformed).
%  M        =  system mass matrix (transformed).
%  T        =  transformation matrix for the consideration
%              of rigid-floor effect.
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
%  elem     =  element connectivity and element group number.
%  force    =  external input time-history depends on caseid
%              ==============================================
%              In CASE 1 and 2, force(:,i) is the loading in 
%              y-direction at the i-th floor.
%              In CASE 3 to 5, force(:,1) is the loading in 
%              y-direction at the roof; force(:,2) is the 
%              loading in x-direction at the roof.
%  node     =  node coordinates and constrains index.
%  prop     =  element group properties.
%  time     =  the corresponding time axis.
%
% by Paul Lam <paullam@ust.hk>, 17-Jan-2000
% modify 24-Jul-2000: support compelete damage of connection and add damage pattern 5
% modify 29-Mar-2001: add damage pattern 6
%************************************************************
function datagen(caseid,damageid,methodid,e,dt,Duration,noiselevel,S,SeedNum,outfilename,Findx);
if nargin < 1,  caseid=[];      end;
if nargin < 2,  damageid=[];    end;
if nargin < 3,  methodid=[];    end;
if nargin < 4,  e=[];           end;
if nargin < 5,  dt=[];          end;
if nargin < 6,  Duration=[];    end;
if nargin < 7,  noiselevel=[];  end;
if nargin < 8,  S=[];           end;
if nargin < 9,  SeedNum=[];     end;
if nargin < 10, outfilename=[]; end;
if nargin < 11, Findx=[];       end;
ProgramName='ASCE Benchmark Problem: DATA Generation Program';
savelist='caseid damageid methodid acc time force K M T S e dt Duration SeedNum noiselevel outfilename node elem prop Findx';

% ***** get caseid from the user *****
CaseID={
   'CASE 1: 12-DOF  (symmetric),   load at all stories'
   'CASE 2: 120-DOF (symmetric),   load at all stories'
   'CASE 3: 12-DOF  (symmetric),   load at roof'
   'CASE 4: 12-DOF  (unsymmetric), load at roof'
   'CASE 5: 120-DOF (unsymmetric), load at roof'
   'QUIT'
};
if isempty(caseid)==1
   caseid=menu(ProgramName,CaseID);
   if caseid==6
      error('user cancel operation ...');
   end;
end;
if caseid > 5 | caseid < 1
    error('caseid must be 1, 2, 3, 4 or 5');
end;
disp(['Selected CASE = ' char(CaseID(caseid))]);

% ***** get damageid from the user *****
DamageID={
   'Undamaged case'
   'Damage pattern 1: all braces of 1-st story are broken'
   'Damage pattern 2: all braces of 1-st and 3-rd story are broken'
   'Damage pattern 3: 1 brace on 1 side of 1-st story is broken'
   'Damage pattern 4: 1 brace on 1 side of 1-st and 3-rd story are broken'
   'Damage pattern 5: pattern 4 + unscrew the left end of element 18'
   'Damage pattren 6: area of 1 brace on 1 side of 1-st story is reduced to 2/3'
   'User define damage case'
   'QUIT'
};
if isempty(damageid)==1
   damageid=menu(ProgramName,DamageID)-1;
   if damageid==8
      error('user cancel operation ...');
   end;
end;
if damageid > 7 | damageid < 0
   error('damageid msut be 0, 1, 2, 3, 4, 5, 6 or 7');
end;
disp(['Selected Damage Pattern = ' char(DamageID(damageid+1))]);

% ***** get methodid from the user *****
MethodID={
   'lsim (You MUST have Control Toolbox)'
   'Nigam-Jennings Algorithm (VERY SLOW)'
   'FAST Nigam-Jennings Algorithm (You MUST have SimuLink)'
   'QUIT'
};
if isempty(methodid)==1
   methodid=menu('Use what method in response calculation?',MethodID);
   if methodid==4
      error('user cancel operation ...');
   end;
end;
if methodid~=1 & methodid~=2 & methodid~=3
   error('methodid must be 1, 2 or 3 ...');
end;
disp(['Selected Method = ' char(MethodID(methodid))]);

% ***** other important parameters *****
menuindx=0;
if isempty(e)==1,             e=0.01;                    menuindx=1; end;
if isempty(dt)==1,            dt=0.001;                  menuindx=1; end;
if isempty(Duration)==1,      Duration=40;               menuindx=1; end;
if isempty(noiselevel)==1,    noiselevel=10;             menuindx=1; end;
if isempty (S)==1,            S=150;                     menuindx=1; end;
if isempty(SeedNum)==1,       SeedNum=123;               menuindx=1; end;
if isempty(Findx)==1,         Findx=1;                   menuindx=1; end;
if isempty(outfilename)==1,   outfilename='DATAfile';    menuindx=1; end;
if menuindx==1
   ParameterID={
      'Damping ratio:'
      'Time step size:'
      'Time duration:'
      'Noise level:'
      'Force intensity:'
      'Seed number for force generation:'
      'Filter index:'
      'OUTput DATA file name:'
   };
   ParameterDef={
      num2str(e)
      num2str(dt)
      num2str(Duration)
      num2str(noiselevel)
      num2str(S)
      num2str(SeedNum)
      num2str(Findx)
      outfilename
   };
   answer=inputdlg(ParameterID,ProgramName,1,ParameterDef);
   if isempty(answer)~=1
      e=             str2num(char(answer(1)));
      dt=            str2num(char(answer(2)));
      Duration=      str2num(char(answer(3)));
      noiselevel=    str2num(char(answer(4)));
      S=             str2num(char(answer(5)));
      SeedNum=       round(str2num(char(answer(6))));
      Findx=         str2num(char(answer(7)));
      outfilename=   char(answer(8));
   else
      error('user cancel operation ....');
   end;
end;

% ***** call cal_model to form the system stiffness and mass matrix *****
disp('Model formation in progress ...');
[K,M,T,node,elem,prop]=cal_model(caseid,damageid);

% ***** call cal_resp to calculate time domain response *****
disp('Time-domain response calculation in progress ...');
[acc,force,time]=cal_resp(caseid,K,M,T,S,e,dt,Duration,SeedNum,noiselevel,methodid,Findx);

% ***** save data *****
disp(['save data to ' outfilename]);
eval(['save ' outfilename ' ' savelist]);
disp(['Thank you for using ''' ProgramName '''!']);
%************************************************************
% END of main program datagen!!
%************************************************************
