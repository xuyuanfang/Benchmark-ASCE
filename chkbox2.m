%************************************************************
% chkbox2:  Creat a check box window and let the user
%           to click on the check boxes.
%           (subfunction of chkboxdlg2)
%************************************************************
%  MUST be called by chkboxdlg2!!

% by Paul Lam <paullam@ust.hk>, 28-Jul-1999
%************************************************************
function chkbox2(action);
if nargin < 1, action='START'; end;
global chk_chkXSize chk_chkYSize chk_FigName chk_chkName chk_BName chk_OUTput chk_Bnum chk_chkDef

chkXSize=chk_chkXSize;
chkYSize=chk_chkYSize;
FigName=chk_FigName;
chkName=chk_chkName;
chkNumber=length(chkName);
BName=chk_BName;
chkDef=chk_chkDef;

if strcmp(action,'START')==1
   % ***** start to draw the check box figure *****
   FigXSize=chkXSize;
   FigYSize=chkYSize*(chkNumber+1);
   FigColor=[ 0.564705882352941 0.690196078431373 0.658823529411765 ];
   FigNumber=figure( ...
      'Name',FigName, ...
      'NumberTitle','off', ...
      'BackingStore','off', ...
      'Color',FigColor, ...
      'MenuBar','none');
   FigPos=get(FigNumber,'Position');
   FigPos(1)=FigPos(1)-(FigXSize-FigPos(3))/2;
   FigPos(2)=FigPos(2)-(FigYSize-FigPos(4));
   FigPos(3)=FigXSize;
   FigPos(4)=FigYSize;
   set(FigNumber,'Position',FigPos);
   Xsp=1/10;
   Ysp=1/(chkNumber+1)/10;
   Xsize=1-2*Xsp;
   Ysize=(1-(chkNumber+1)*2*Ysp)/(chkNumber+1);
   stX=Xsp;
   stY=1-Ysp-Ysize;
   % ***** the check boxes *****
   for i=1:chkNumber
      chkPos=[stX stY Xsize Ysize];
      chkHDL(i)=uicontrol( ...
         'Units','normalized', ...
         'String',char(chkName(i)), ...
         'Position',chkPos, ...
         'BackgroundColor',FigColor, ...
         'Value',chkDef(i), ...
         'Style','checkbox');
      stY=stY-2*Ysp-Ysize;
   end;
   for i=1:length(BName)
      callbackStr=[mfilename '(' num2str(i) '); uiresume;'];
      BHDL(i)=uicontrol( ...
         'Style','push', ...
         'Units','normalized', ...
         'Position',[stX stY (Xsize-2*Xsp)/2 Ysize], ...
         'String',char(BName(i)), ...
         'Callback',callbackStr);
      stX=stX+(Xsize-2*Xsp)/2+2*Xsp;
   end;
   set(FigNumber,'UserData',chkHDL);
   
   uiwait
   close
else
   chkHDL=get(gcf,'UserData');
   for i=1:chkNumber
      chk_OUTput(i)=get(chkHDL(i),'Value');
   end;
   chk_Bnum=action;
end;
