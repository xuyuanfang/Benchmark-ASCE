%************************************************************
% cal_model:   System stiffness & mass matrix calculation
%              for the Benchmark Problem of the 
%              ASCE Task Group on Structural Health Monitoring
%************************************************************
%  Note:
%  This function is a sub-function of datagen. However, it 
%  can also be called alone.
%************************************************************
%  [K,M,T,node,elem,prop]=cal_model(caseid,damageid);
% INput parameters:
%  caseid   =  Case index can be 1, 2, 3, 4 and 5 
%              correspoinding to CASE 1 to 5, respectively.
%  damageid =  Damage pattern index can be 0 to 7
%              0        -  undamage case
%              1 to 6   -  damage pattern 1 to 6
%              7        -  user define damage pattern
%
% OUTput parameters:
%  K        =  system stiffness matrix (transformed).
%  M        =  system mass matrix (transformed).
%  T        =  transformation matrix for the consideration
%              of rigid-floor effect.
%  node     =  node coordinates and constrains index.
%  elem     =  element connectivity and element group number.
%  prop     =  element group properties.
%
% See also DATAGEN, CAL_RESP, DRAW3D
%
% Example:
%  [K,M] = cal_model(1,0);
%  will calculate the system stiffness (K) and mass (M)
%  matrix for CASE 1 (caseid = 1) of the undamaged frame
%  (damageid = 0).
%

% Call:  chkbox2, chkboxdlg2
% Subfunction: gettheta, getNEP, call_T, frame3d, fe3d, tf3d,
%              mat2vec, one2zero, draw3d.
% by Paul Lam <paullam@ust.hk>, 18-Jan-2000
% modify 24-Jul-2000: support compelete damage of connection and add damage pattern 5
% modify 29-Mar-2001: add damage pattern 6
%************************************************************
function [K,M,T,node,elem,prop]=cal_model(caseid,damageid);
if nargin < 1, caseid=[];     end;
if nargin < 2, damageid=[];   end;
if isempty(caseid)==1,     error('caseid is missing ...');     end;
if isempty(damageid)==1,   error('damageid is missing ...');   end;

% ***** define StructID and USindx according to caseid *****
switch caseid
case 1, StructID=0; USindx=0; disp('12-DOF  with symmetrical mass matrix');
case 2, StructID=1; USindx=0; disp('120-DOF with symmetrical mass matrix');
case 3, StructID=0; USindx=0; disp('12-DOF  with symmetrical mass matrix');
case 4, StructID=0; USindx=1; disp('12-DOF  with UNsymmetircal mass');
case 5, StructID=1; USindx=1; disp('120-DOF with UNsymmetircal mass');
otherwise, error('caseid not exist ....');
end;

% ***** always use lump mass matrix *****
LumpID=1;

% ***** call internal function getNEP for structure information *****
[node,elem,prop,L,H]=getNEP;

% ***** calculation of theta according to different damage case *****
theta=ones(116,1);
switch damageid
case 0
   disp('undamage case');
case 1
   disp('damage pattern 1: all braces, 1-st story, break'); 
   theta([22:29])=0;
case 2
   disp('damage pattern 2: all braces, 1-st and 3-rd story, break');
   theta([22:29 80:87])=0;
case 3
   disp('damage pattern 3: 1 brace at 1-st story (element 24), break');
   theta(24)=0;
case 4
   disp('damage pattern 4: 1 brace at 1-st and 3-rd story (element 24 & 81), break');
   theta([24 81])=0;
case 5
   disp('damage pattern 5: 1 brace at 1-st and 3-rd story (element 24 & 81), break + unscrew left end of element 18 (at node 11)');
   theta([24 81])=0;
   elem(18,5)=1;
case 6
   disp('damage pattern 6: 1 brace at 1-st story (element 24), 1/3 cut in area');
   theta(24)=2/3;
case 7
   disp('user define damage pattern ...');
   draw3d(node,elem,0,1);
   theta=gettheta(node,elem);
   close
otherwise, error('damageid must be 0 to 5 ...');
end;

% ***** scale the Young's modulus of the elements according to theta *****
prop(:,5)=prop(:,5).*theta;

% ***** define the reference point for each story *****
pts=[
   L  L  H
   L  L  2*H
   L  L  3*H
   L  L  4*H
];

% ***** call internal function cal_T to calculate the transformation matrix (T) *****
% ***** for the consideration of rigid-floor effect                             *****
T=cal_T(node,pts,StructID);

% ***** call frame3d to calculate the system stiffness and mass matrix  *****
% ***** (before transformation)                                         *****
[SysK,SysM]=frame3d(node,elem,prop,LumpID);

% ***** transform the system stiffness and mass matrix *****
K=T'*SysK*T;
M=T'*SysM*T;

% ***** add floor masses to the transformed system mass matrix *****
amval(1,:)=ones(1,4)*800;
amval(2,:)=ones(1,4)*600;
amval(3,:)=ones(1,4)*600;
if USindx==0
   % ***** symmetrical mass for CASE 1, 2 and 3 *****
   amval(4,:)=ones(1,4)*400;
elseif USindx==1
   % ***** unsymmetrical mass for CASE 4 and 5 *****
   amval(4,:)=[400 400 550 400];
else
   error('USindx error ....');
end;
dx=[L L -L -L]/2;
dy=[L -L -L L]/2;
dr=(dx.^2+dy.^2).^0.5;
% ***** addmatrix (12 by 12) is calculated for the consideration  *****
% ***** of floor masses                                           *****
for i=1:4
   addmatrix(1+(i-1)*3,1+(i-1)*3)= sum(amval(i,:));
   addmatrix(2+(i-1)*3,2+(i-1)*3)= sum(amval(i,:));
   addmatrix(3+(i-1)*3,3+(i-1)*3)= sum(amval(i,:)*(2*L^2/12))+sum(amval(i,:).*dr.^2);
   addmatrix(1+(i-1)*3,3+(i-1)*3)=-sum(amval(i,:).*dy);
   addmatrix(3+(i-1)*3,1+(i-1)*3)=-sum(amval(i,:).*dy);
   addmatrix(2+(i-1)*3,3+(i-1)*3)= sum(amval(i,:).*dx);
   addmatrix(3+(i-1)*3,2+(i-1)*3)= sum(amval(i,:).*dx);
end;

% ***** add addmatrix to the transformed system mass matrix *****
M(1:12,1:12)=M(1:12,1:12)+addmatrix;

% ***** remove very small elements in M *****
[Iindx,Jindx]=find(abs(M) < 1.e-10);
if isempty(Iindx)~=1
   for i=1:length(Iindx)
      M(Iindx(i),Jindx(i))=0;
   end;
end;
%************************************************************
% END of program cal_model!!
%************************************************************


%============================================================
% gettheta: get theta for the user define damage pattern 
%           interactively!
%============================================================
function theta=gettheta(node,elem);
if nargin < 2, error('not enough input parameters ...'); end;
theta=ones(116,1);
Choices={
   'Beams   4-th floor' '[97:108]'
   'Columns 4-th floor' '[88:96]'
   'Braces  4-th floor' '[109:116]'
   'Beams   3-rd floor' '[68:79]'
   'Columns 3-rd floor' '[59:67]'
   'Braces  3-rd floor' '[80:87]'
   'Beams   2-nd floor' '[39:50]'
   'Columns 2-nd floor' '[30:38]'
   'Braces  2-nd floor' '[51:58]'
   'Beams   1-st floor' '[10:21]'
   'Columns 1-st floor' '[1:9]'
   'Braces  1-st floor' '[22:29]'
   'Finished'           ''
};
BName={
   'Stop Input'
   'Continue'
};
chkout=0;
while chkout==0
   sel=menu('Locate damaged elements ...',Choices(:,1));
   if sel~=13
      vv=str2num(char(Choices(sel,2)));
      clear chkName
      for i=1:length(vv)
         chkName(i)={['element ' num2str(vv(i))]};
      end;
      [OUTput,Bnum]=chkboxdlg2(chkName,one2zero(theta(vv)),'Locate damaged elements',180,30,BName);
      theta(vv)=one2zero(OUTput);
      if Bnum==1
         chkout=1;
      end;
   else
      chkout=1;
   end;
   dmemberlist='';
   for i=1:length(theta)
      if theta(i)==0
         dmemberlist=[dmemberlist num2str(i) ' '];
      end;
   end;
   if isempty(dmemberlist)~=1
      disp(['damage at member ' dmemberlist]);
   end;
end;


%============================================================
% getNEP:   get the structural parameters NODE, ELE, and PROP.
%           The structure is defined in this function!!!
%============================================================
function [node,elem,prop,L,H]=getNEP;
% ***** L is the bay width, H is the story height *****
L=1.25; H=0.9;

% ***** node coordinates and node condition index*****
node=[
   0     0     0     0  0  0  0  0  0
   L     0     0     0  0  0  0  0  0
   2*L   0     0     0  0  0  0  0  0
   0     L     0     0  0  0  0  0  0
   L     L     0     0  0  0  0  0  0
   2*L   L     0     0  0  0  0  0  0
   0     2*L   0     0  0  0  0  0  0
   L     2*L   0     0  0  0  0  0  0
   2*L   2*L   0     0  0  0  0  0  0
   0     0     H     1  1  1  1  1  1
   L     0     H     1  1  1  1  1  1
   2*L   0     H     1  1  1  1  1  1
   0     L     H     1  1  1  1  1  1
   L     L     H     1  1  1  1  1  1
   2*L   L     H     1  1  1  1  1  1
   0     2*L   H     1  1  1  1  1  1
   L     2*L   H     1  1  1  1  1  1
   2*L   2*L   H     1  1  1  1  1  1
   0     0     2*H   1  1  1  1  1  1
   L     0     2*H   1  1  1  1  1  1
   2*L   0     2*H   1  1  1  1  1  1
   0     L     2*H   1  1  1  1  1  1
   L     L     2*H   1  1  1  1  1  1
   2*L   L     2*H   1  1  1  1  1  1
   0     2*L   2*H   1  1  1  1  1  1
   L     2*L   2*H   1  1  1  1  1  1
   2*L   2*L   2*H   1  1  1  1  1  1
   0     0     3*H   1  1  1  1  1  1
   L     0     3*H   1  1  1  1  1  1
   2*L   0     3*H   1  1  1  1  1  1
   0     L     3*H   1  1  1  1  1  1
   L     L     3*H   1  1  1  1  1  1
   2*L   L     3*H   1  1  1  1  1  1
   0     2*L   3*H   1  1  1  1  1  1
   L     2*L   3*H   1  1  1  1  1  1
   2*L   2*L   3*H   1  1  1  1  1  1
   0     0     4*H   1  1  1  1  1  1
   L     0     4*H   1  1  1  1  1  1
   2*L   0     4*H   1  1  1  1  1  1
   0     L     4*H   1  1  1  1  1  1
   L     L     4*H   1  1  1  1  1  1
   2*L   L     4*H   1  1  1  1  1  1
   0     2*L   4*H   1  1  1  1  1  1
   L     2*L   4*H   1  1  1  1  1  1
   2*L   2*L   4*H   1  1  1  1  1  1
];

% ***** element connectivity and element group *****
elem=[
   1     10     4     1
   2     11     5     2
   3     12     6     3
   4     13     7     4
   5     14     8     5
   6     15     9     6
   7     16     4     7
   8     17     5     8
   9     18     6     9
   10    11     2    10
   11    12     3    11
   13    14     5    12
   14    15     6    13
   16    17     8    14
   17    18     9    15
   10    13     4    16
   13    16     7    17
   11    14     5    18
   14    17     8    19
   12    15     6    20
   15    18     9    21
   1     11    10    22
   11     3    12    23
   3     15    12    24
   15     9    18    25
   9     17    18    26
   17     7    16    27
   7     13    16    28
   13     1    10    29
   10    19    13    30
   11    20    14    31
   12    21    15    32
   13    22    16    33
   14    23    17    34
   15    24    18    35
   16    25    13    36
   17    26    14    37
   18    27    15    38
   19    20    11    39
   20    21    12    40
   22    23    14    41
   23    24    15    42
   25    26    17    43
   26    27    18    44
   19    22    13    45
   22    25    16    46
   20    23    14    47
   23    26    17    48
   21    24    15    49
   24    27    18    50
   10    20    19    51
   20    12    21    52
   12    24    21    53
   24    18    27    54
   18    26    27    55
   26    16    25    56
   16    22    25    57
   22    10    19    58
   19    28    22    59
   20    29    23    60
   21    30    24    61
   22    31    25    62
   23    32    26    63
   24    33    27    64
   25    34    22    65
   26    35    23    66
   27    36    24    67
   28    29    20    68
   29    30    21    69
   31    32    23    70
   32    33    24    71
   34    35    26    72
   35    36    27    73
   28    31    22    74
   31    34    25    75
   29    32    23    76
   32    35    26    77
   30    33    24    78
   33    36    27    79
   19    29    28    80
   29    21    30    81
   21    33    30    82
   33    27    36    83
   27    35    36    84
   35    25    34    85
   25    31    34    86
   31    19    28    87
   28    37    31    88
   29    38    32    89
   30    39    33    90
   31    40    34    91
   32    41    35    92
   33    42    36    93
   34    43    31    94
   35    44    32    95
   36    45    33    96
   37    38    29    97
   38    39    30    98
   40    41    32    99
   41    42    33   100
   43    44    35   101
   44    45    36   102
   37    40    31   103
   40    43    34   104
   38    41    32   105
   41    44    35   106
   39    42    33   107
   42    45    36   108
   28    38    37   109
   38    30    39   110
   30    42    39   111
   42    36    45   112
   36    44    45   113
   44    34    43   114
   34    40    43   115
   40    28    37   116
];
% additional columns to consider connection damage at two ends of the member
% 0 stands for NO damage;
% 1 stands for complete damage!! Transmit translational forces only but not rotational
elem(:,5:6)=0;

% ***** (1) column, (2) beam and (3) brace properties *****
% Iy  -  the moment of inertia in the strong axis
% Iz  -  the moment of inertia in the weak axis 
% J   -  the torsional constent
% A   -  the cross-sectional area
% E   -  the Young's Modulus 
% mbar-  the mass per unit length
Iy1   =1.97e-6;      Iz2   =1.22e-6;      Iy3   =0;
Iz1   =0.664e-6;     Iy2   =0.249e-6;     Iz3   =0;
J1    =8.01e-9;      J2    =3.82e-8;      J3    =0;
A1    =1.133E-3;     A2    =1.430E-3;     A3    =0.141E-3;
E1    =2.0e11;       E2    =E1;           E3    =E1;
mbar1 =7800*A1;      mbar2 =7800*A2;      mbar3 =7800*A3;
Io1   =Iy1+Iz1;      Io2   =Iy2+Iz2;      Io3   =0;
G1    =E1/2/(1+0.3); G2    =E2/2/(1+0.3); G3    =E3/2/(1+0.3);

% ***** element properties for different element group *****
prop=[
   % 1st floor - columns
   Iz1 Iy1 J1 A1 E1 mbar1 Io1 G1
   Iz1 Iy1 J1 A1 E1 mbar1 Io1 G1
   Iz1 Iy1 J1 A1 E1 mbar1 Io1 G1
   Iz1 Iy1 J1 A1 E1 mbar1 Io1 G1
   Iz1 Iy1 J1 A1 E1 mbar1 Io1 G1
   Iz1 Iy1 J1 A1 E1 mbar1 Io1 G1
   Iz1 Iy1 J1 A1 E1 mbar1 Io1 G1
   Iz1 Iy1 J1 A1 E1 mbar1 Io1 G1
   Iz1 Iy1 J1 A1 E1 mbar1 Io1 G1
   % 1st floor - beams
   Iz2 Iy2 J2 A2 E2 mbar2 Io2 G2
   Iz2 Iy2 J2 A2 E2 mbar2 Io2 G2
   Iz2 Iy2 J2 A2 E2 mbar2 Io2 G2
   Iz2 Iy2 J2 A2 E2 mbar2 Io2 G2
   Iz2 Iy2 J2 A2 E2 mbar2 Io2 G2
   Iz2 Iy2 J2 A2 E2 mbar2 Io2 G2
   Iz2 Iy2 J2 A2 E2 mbar2 Io2 G2
   Iz2 Iy2 J2 A2 E2 mbar2 Io2 G2
   Iz2 Iy2 J2 A2 E2 mbar2 Io2 G2
   Iz2 Iy2 J2 A2 E2 mbar2 Io2 G2
   Iz2 Iy2 J2 A2 E2 mbar2 Io2 G2
   Iz2 Iy2 J2 A2 E2 mbar2 Io2 G2
   % 1st floor - braces
   Iz3 Iy3 J3 A3 E3 mbar3 Io3 G3
   Iz3 Iy3 J3 A3 E3 mbar3 Io3 G3
   Iz3 Iy3 J3 A3 E3 mbar3 Io3 G3
   Iz3 Iy3 J3 A3 E3 mbar3 Io3 G3
   Iz3 Iy3 J3 A3 E3 mbar3 Io3 G3
   Iz3 Iy3 J3 A3 E3 mbar3 Io3 G3
   Iz3 Iy3 J3 A3 E3 mbar3 Io3 G3
   Iz3 Iy3 J3 A3 E3 mbar3 Io3 G3
   % 2nd floor - columns
   Iz1 Iy1 J1 A1 E1 mbar1 Io1 G1
   Iz1 Iy1 J1 A1 E1 mbar1 Io1 G1
   Iz1 Iy1 J1 A1 E1 mbar1 Io1 G1
   Iz1 Iy1 J1 A1 E1 mbar1 Io1 G1
   Iz1 Iy1 J1 A1 E1 mbar1 Io1 G1
   Iz1 Iy1 J1 A1 E1 mbar1 Io1 G1
   Iz1 Iy1 J1 A1 E1 mbar1 Io1 G1
   Iz1 Iy1 J1 A1 E1 mbar1 Io1 G1
   Iz1 Iy1 J1 A1 E1 mbar1 Io1 G1
   % 2nd floor - beams
   Iz2 Iy2 J2 A2 E2 mbar2 Io2 G2
   Iz2 Iy2 J2 A2 E2 mbar2 Io2 G2
   Iz2 Iy2 J2 A2 E2 mbar2 Io2 G2
   Iz2 Iy2 J2 A2 E2 mbar2 Io2 G2
   Iz2 Iy2 J2 A2 E2 mbar2 Io2 G2
   Iz2 Iy2 J2 A2 E2 mbar2 Io2 G2
   Iz2 Iy2 J2 A2 E2 mbar2 Io2 G2
   Iz2 Iy2 J2 A2 E2 mbar2 Io2 G2
   Iz2 Iy2 J2 A2 E2 mbar2 Io2 G2
   Iz2 Iy2 J2 A2 E2 mbar2 Io2 G2
   Iz2 Iy2 J2 A2 E2 mbar2 Io2 G2
   Iz2 Iy2 J2 A2 E2 mbar2 Io2 G2
   % 2nd floor braces
   Iz3 Iy3 J3 A3 E3 mbar3 Io3 G3
   Iz3 Iy3 J3 A3 E3 mbar3 Io3 G3
   Iz3 Iy3 J3 A3 E3 mbar3 Io3 G3
   Iz3 Iy3 J3 A3 E3 mbar3 Io3 G3
   Iz3 Iy3 J3 A3 E3 mbar3 Io3 G3
   Iz3 Iy3 J3 A3 E3 mbar3 Io3 G3
   Iz3 Iy3 J3 A3 E3 mbar3 Io3 G3
   Iz3 Iy3 J3 A3 E3 mbar3 Io3 G3
   % 3rd floor columns
   Iz1 Iy1 J1 A1 E1 mbar1 Io1 G1
   Iz1 Iy1 J1 A1 E1 mbar1 Io1 G1
   Iz1 Iy1 J1 A1 E1 mbar1 Io1 G1
   Iz1 Iy1 J1 A1 E1 mbar1 Io1 G1
   Iz1 Iy1 J1 A1 E1 mbar1 Io1 G1
   Iz1 Iy1 J1 A1 E1 mbar1 Io1 G1
   Iz1 Iy1 J1 A1 E1 mbar1 Io1 G1
   Iz1 Iy1 J1 A1 E1 mbar1 Io1 G1
   Iz1 Iy1 J1 A1 E1 mbar1 Io1 G1
   % 3rd floor beams
   Iz2 Iy2 J2 A2 E2 mbar2 Io2 G2
   Iz2 Iy2 J2 A2 E2 mbar2 Io2 G2
   Iz2 Iy2 J2 A2 E2 mbar2 Io2 G2
   Iz2 Iy2 J2 A2 E2 mbar2 Io2 G2
   Iz2 Iy2 J2 A2 E2 mbar2 Io2 G2
   Iz2 Iy2 J2 A2 E2 mbar2 Io2 G2
   Iz2 Iy2 J2 A2 E2 mbar2 Io2 G2
   Iz2 Iy2 J2 A2 E2 mbar2 Io2 G2
   Iz2 Iy2 J2 A2 E2 mbar2 Io2 G2
   Iz2 Iy2 J2 A2 E2 mbar2 Io2 G2
   Iz2 Iy2 J2 A2 E2 mbar2 Io2 G2
   Iz2 Iy2 J2 A2 E2 mbar2 Io2 G2
   % 3rd floor braces
   Iz3 Iy3 J3 A3 E3 mbar3 Io3 G3
   Iz3 Iy3 J3 A3 E3 mbar3 Io3 G3
   Iz3 Iy3 J3 A3 E3 mbar3 Io3 G3
   Iz3 Iy3 J3 A3 E3 mbar3 Io3 G3
   Iz3 Iy3 J3 A3 E3 mbar3 Io3 G3
   Iz3 Iy3 J3 A3 E3 mbar3 Io3 G3
   Iz3 Iy3 J3 A3 E3 mbar3 Io3 G3
   Iz3 Iy3 J3 A3 E3 mbar3 Io3 G3
   % 4th floor columns
   Iz1 Iy1 J1 A1 E1 mbar1 Io1 G1
   Iz1 Iy1 J1 A1 E1 mbar1 Io1 G1
   Iz1 Iy1 J1 A1 E1 mbar1 Io1 G1
   Iz1 Iy1 J1 A1 E1 mbar1 Io1 G1
   Iz1 Iy1 J1 A1 E1 mbar1 Io1 G1
   Iz1 Iy1 J1 A1 E1 mbar1 Io1 G1
   Iz1 Iy1 J1 A1 E1 mbar1 Io1 G1
   Iz1 Iy1 J1 A1 E1 mbar1 Io1 G1
   Iz1 Iy1 J1 A1 E1 mbar1 Io1 G1
   % 4th floor beams
   Iz2 Iy2 J2 A2 E2 mbar2 Io2 G2
   Iz2 Iy2 J2 A2 E2 mbar2 Io2 G2
   Iz2 Iy2 J2 A2 E2 mbar2 Io2 G2
   Iz2 Iy2 J2 A2 E2 mbar2 Io2 G2
   Iz2 Iy2 J2 A2 E2 mbar2 Io2 G2
   Iz2 Iy2 J2 A2 E2 mbar2 Io2 G2
   Iz2 Iy2 J2 A2 E2 mbar2 Io2 G2
   Iz2 Iy2 J2 A2 E2 mbar2 Io2 G2
   Iz2 Iy2 J2 A2 E2 mbar2 Io2 G2
   Iz2 Iy2 J2 A2 E2 mbar2 Io2 G2
   Iz2 Iy2 J2 A2 E2 mbar2 Io2 G2
   Iz2 Iy2 J2 A2 E2 mbar2 Io2 G2
   % 4th floor braces
   Iz3 Iy3 J3 A3 E3 mbar3 Io3 G3
   Iz3 Iy3 J3 A3 E3 mbar3 Io3 G3
   Iz3 Iy3 J3 A3 E3 mbar3 Io3 G3
   Iz3 Iy3 J3 A3 E3 mbar3 Io3 G3
   Iz3 Iy3 J3 A3 E3 mbar3 Io3 G3
   Iz3 Iy3 J3 A3 E3 mbar3 Io3 G3
   Iz3 Iy3 J3 A3 E3 mbar3 Io3 G3
   Iz3 Iy3 J3 A3 E3 mbar3 Io3 G3
];


%============================================================
% cal_T: Calculate the transformation matrix T
%        for the consideration of the rigid-floor effect.
%============================================================
function T=cal_T(node,pts,StructID);
if nargin < 3, error('not enough input parameters ...'); end;
D1num=sum(sum(node(:,4:6)));
[Pnum,Pdim]=size(pts);
Tcount=1;
addnum=Pnum*3+1;
for i=1:Pnum
   indx=find(node(:,3)==pts(i,3));
   vv=[1+(i-1)*3:i*3];
   for j=1:length(indx)
      if node(indx(j),4)==1
         T(Tcount,vv)=[1 0 pts(i,2)-node(indx(j),2)];
         Tcount=Tcount+1;
      end;
      if node(indx(j),5)==1
         T(Tcount,vv)=[0 1 -(pts(i,1)-node(indx(j),1))];
         Tcount=Tcount+1;
      end;
      if node(indx(j),6)==1
         if StructID==1
            T(Tcount,addnum)=1;
         end;
         Tcount=Tcount+1; addnum=addnum+1;
      end;
      if node(indx(j),7)==1
         if StructID==1
            T(Tcount,addnum)=1;
         end;
         Tcount=Tcount+1; addnum=addnum+1;
      end;
      if node(indx(j),8)==1
         if StructID==1
            T(Tcount,addnum)=1;
         end;
         Tcount=Tcount+1; addnum=addnum+1;
      end;
      if node(indx(j),9)==1
         T(Tcount,vv)=[0 0 1];
         Tcount=Tcount+1;
      end;
   end;
end;


%============================================================
% frame3d: Assemble the system stiffness and mass matrix.
%============================================================
function [SysK,SysM]=frame3d(node,elem,prop,LumpID);
if nargin < 4, error('not enough input parameters ...'); end;
[nnum,nn]=size(node);
[enum,ee]=size(elem);
[pnum,pp]=size(prop);
DOFnum=sum(sum(node(:,4:9)));
Ks=zeros(6*nnum); Ms=zeros(6*nnum);
v1=[1:6]; v2=[7:12];
for i=1:enum
   % ***** calculate the element length *****
   L=sum((node(elem(i,1),1:3)-node(elem(i,2),1:3)).^2).^0.5;
   % ***** calculate the element local stiffness and mass matrix *****
   [Ke,Me]=fe3d( ...
      prop(elem(i,4),1), ...
      prop(elem(i,4),2), ...
      prop(elem(i,4),3), ...
      prop(elem(i,4),4), ...
      L, ...
      prop(elem(i,4),5), ...
      prop(elem(i,4),6), ...
      prop(elem(i,4),7), ...
      prop(elem(i,4),8), ...
      LumpID);
   if elem(i,5)==1
      u1=[1:3 7:12];
      u2=[4:6];
   end;
   if elem(i,6)==1
      u1=[1:9];
      u2=[10:12];
   end;
   if elem(i,5)==1 | elem(i,6)==1
      K11=Ke(u1,u1); K12=Ke(u1,u2); K21=Ke(u2,u1); K22=Ke(u2,u2);
      Knew=K11-K12*inv(K22)*K21;
      Ke=zeros(12);
      Ke(u1,u1)=Knew;
   end;
   % ***** calculate the element transformation matrix *****
   T=tf3d_geradin(node(elem(i,1),1:3),node(elem(i,2),1:3),node(elem(i,3),1:3));
   % ***** calculate the element global stiffness and mass matrix *****
   Kt=T'*Ke*T; Mt=T'*Me*T;
   % ***** assemble the system stiffness matrix *****
   DOFi=elem(i,1)*6-5; vi=[DOFi:DOFi+5];
   DOFj=elem(i,2)*6-5; vj=[DOFj:DOFj+5];
   Ks(vi,vi)=Kt(v1,v1)+Ks(vi,vi);
   Ks(vj,vj)=Kt(v2,v2)+Ks(vj,vj);
   Ks(vi,vj)=Kt(v1,v2)+Ks(vi,vj);
   Ks(vj,vi)=Kt(v2,v1)+Ks(vj,vi);
   % ***** assemble the system mass matrix *****
	Ms(vi,vi)=Mt(v1,v1)+Ms(vi,vi);
	Ms(vj,vj)=Mt(v2,v2)+Ms(vj,vj);
	Ms(vi,vj)=Mt(v1,v2)+Ms(vi,vj);
	Ms(vj,vi)=Mt(v2,v1)+Ms(vj,vi);
end;
Kvec=mat2vec(node(:,4:9));
indx=find(Kvec==1);
SysK=Ks(indx,indx);
SysM=Ms(indx,indx);


%============================================================
% fe3d: Formation of the element stiffness and mass matrix.
%============================================================
function [K,M]=fe3d(Iz,Iy,J,A,L,E,mbar,Io,G,LumpID);
if nargin < 10, error('not enough input parameters ...'); end;
K11=[
   E*A/L       0              0              0              0              0  
   0           12*E*Iz/L^3    0              0              0              6*E*Iz/L^2
   0           0              12*E*Iy/L^3    0              -6*E*Iy/L^2    0
   0           0              0              G*J/L          0              0
   0           0              -6*E*Iy/L^2    0              4*E*Iy/L       0
   0           6*E*Iz/L^2     0              0              0              4*E*Iz/L
];
K21=[
   -E*A/L      0              0              0              0              0  
   0           -12*E*Iz/L^3   0              0              0              -6*E*Iz/L^2
   0           0              -12*E*Iy/L^3   0              6*E*Iy/L^2     0
   0           0              0              -G*J/L         0              0
   0           0              -6*E*Iy/L^2    0              2*E*Iy/L       0
   0           6*E*Iz/L^2     0              0              0              2*E*Iz/L
];
K22=[
   E*A/L       0              0              0              0              0  
   0           12*E*Iz/L^3    0              0              0              -6*E*Iz/L^2
   0           0              12*E*Iy/L^3    0              6*E*Iy/L^2     0
   0           0              0              G*J/L          0              0
   0           0              6*E*Iy/L^2     0              4*E*Iy/L       0
   0           -6*E*Iz/L^2    0              0              0              4*E*Iz/L
];
K=[
   K11   K21'
   K21   K22
];
if LumpID==0
   M11=[
      140      0        0        0        0        0
      0        156      0        0        0        22*L
      0        0        156      0        -22*L    0
      0        0        0        140*Io/A 0        0
      0        0        -22*L    0        4*L^2    0
      0        22*L     0        0        0        4*L^2
   ];
   M21=[
      70       0        0        0        0        0
      0        54       0        0        0        13*L
      0        0        54       0        -13*L    0
      0        0        0        70*Io/A  0        0
      0        0        13*L     0        -3*L^2   0
      0        -13*L    0        0        0        -3*L^2
   ];
   M22=[
      140      0        0        0        0        0
      0        156      0        0        0        -22*L
      0        0        156      0        22*L     0
      0        0        0        140*Io/A 0        0
      0        0        22*L     0        4*L^2    0
      0        -22*L    0        0        0        4*L^2
   ];
   M=[
      M11   M21'
      M21   M22
   ].*(mbar*L/420);
else
   M=[1 1 1 Io/A 0 0 1 1 1 Io/A 0 0].*(mbar*L/2);
   M=diag(M);
end;


%============================================================
% tf3d: Formation of the element transformation matrix.
%============================================================
function T=tf3d_geradin(pti,ptj,ptk);
if nargin < 3, error('not enough input parameters ...'); end;
d2=ptj-pti;
d3=ptk-pti;
ex=d2./norm(d2);
ez=cross(d2,d3);
ez=ez./norm(ez);
ey=cross(ez,ex);
T1=[
   ex(1) ex(2) ex(3)
   ey(1) ey(2) ey(3)
   ez(1) ez(2) ez(3)
];
v=1:3;
for i=1:4
   vv=v+(i-1)*3;
   T(vv,vv)=T1;
end;

%============================================================
% mat2vec:  Rearrange a matrix to a vector.
%============================================================
function xout=mat2vec(xin)
if nargin < 1, error('not enough input parameters ...'); end;
[nrow,ncol]=size(xin);
xout=[];
for i=1:nrow
   xout = [xout xin(i,1:ncol)];
end


%============================================================
% one2zero:  Switching between 0 and 1.
%============================================================
function OUTput=one2zero(INput);
if nargin < 1, error('not enough input parameters ...'); end;
OUTput=INput;
[I0,J0]=find(INput==0);
[I1,J1]=find(INput==1);
for i=1:length(I0), OUTput(I0(i),J0(i))=1; end;
for i=1:length(I1), OUTput(I1(i),J1(i))=0; end;


%============================================================
% draw3d:  Draw the 3-D structure.
%============================================================
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
