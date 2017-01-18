%************************************************************
% chkboxdlg2:  Check box dialog.
%              VERSION 2: Allow user to define two buttons 
%              other than 'Ok' and 'Cancel'.
%************************************************************
%  [OUTput,Bnum] = chkboxdlg2(chkName,chkDef,FigName, ...
%                           chkXSize,chkYSize,BName);
% INput parameters:
%  chkName  =  a cell vector of check box name
%  chkDef   =  a vector with the same dimension as chkName,
%              with element 1 (default check) and 0
%              (default not check).
%  FigName  =  a string for the name of the check box dialog
%              [default: 'Check Dialog Box']
%  chkXSize =  the X-size of each chkbox in pixes 
%              [default: 300]
%  chkYSize =  the Y-size of each chkbox in pixes
%              [default: 60]
%  BName    =  a two elements cell variable consists of the 
%              user define button names 
%              [default: {'OK' 'Cancel'}]
% OUTput parameters:
%  OUTput   =  a vector to show which box(es) is/are checked.
%              1 for checked and 0 for not.
%  Bnum     =  button number 
%
% See also CHKBOXDLG, CHKBOX2
%
% Example:
%  [A,B]=chkboxdlg2({'Chk 1' 'Chk 2' 'Chk 3'},[1 0 1],'Testing',[],[],{'Button 1' 'Button 2'})
%  will produce a checkbox with three items 'Chk 1', 'Chk 2' 
%  and 'Chk 3' with 'Chk 1' and 'Chk 3' are checked. 
%

% Call chkbox2
% by Paul Lam <paullam@ust.hk>, 28-Jul-1999
%************************************************************
function [OUTput,Bnum]=chkboxdlg2(chkName,chkDef,FigName,chkXSize,chkYSize,BName);
if nargin < 1, chkName=[]; end;
if nargin < 2, chkDef=[];  end;
if nargin < 3, FigName=[]; end;
if nargin < 4, chkXSize=[]; end;
if nargin < 5, chkYSize=[]; end;
if nargin < 6, BName=[]; end;
clear global chk_chkXSize chk_chkYSize chk_FigName chk_chkName chk_BName chk_OUTput chk_Bnum chk_chkDef
global chk_chkXSize chk_chkYSize chk_FigName chk_chkName chk_BName chk_OUTput chk_Bnum chk_chkDef

if isempty(chkName)==1, errorbox('chkName is missing ...'); end;
chkNumber=length(chkName);
if isempty(chkDef)==1, chkDef=zeros(1,chkNumber); end;
if isempty(FigName)==1, FigName='Check Dialog Box'; end;
if isempty(chkXSize)==1, chkXSize=300; end;
if isempty(chkYSize)==1, chkYSize=60; end;
if isempty(BName)==1
   BName={'OK' 'Cancel'};
end;

chk_chkXSize=chkXSize;
chk_chkYSize=chkYSize;
chk_FigName=FigName;
chk_chkName=chkName;
chk_BName=BName;
chk_chkDef=chkDef;
chkbox2;
OUTput=chk_OUTput;
Bnum=chk_Bnum;
