function Sfcn_DrawDrivingScene(block)
setup(block);
end
function setup(block) %runs at t=0 i/o definitions
block.SetSimViewingDevice(true);

%dialog parameters
block.NumDialogPrms = 2;
block.DialogPrmsTunable = {'Nontunable','Nontunable'}; %can change during simulation
%[ControlTs,L]

%register number of ports
block.NumInputPorts = 3;
block.NumOutputPorts = 2;

%setup port properties to be inherited or dynamic
block.SetPreCompInpPortInfoToDynamic;

%Register the properties of the input ports
%Enable
block.InputPort(1).Complexity     ='Real';
block.InputPort(1).DataTypeId     =-1;
block.InputPort(1).Dimensions     =1;
block.InputPort(1).SamplingMode   ='Sample';
%State
block.InputPort(2).Complexity     ='Real';
block.InputPort(2).DataTypeId     =-1;
block.InputPort(2).Dimensions     =5;
block.InputPort(2).SamplingMode   ='Sample';
%Time
block.InputPort(3).Complexity     ='Real';
block.InputPort(3).DataTypeId     =-1;
block.InputPort(3).Dimensions     =1;
block.InputPort(3).SamplingMode   ='Sample';

%Register the properties of the output ports
%button
block.OutputPort(1).Dimensions       = 1;
block.OutputPort(1).SamplingMode = 'Sample';
block.OutputPort(1).DatatypeID  = 0;
%trigger
block.OutputPort(2).Dimensions       = 1;
block.OutputPort(2).SamplingMode = 'Sample';
block.OutputPort(2).DatatypeID  = 0;

%Register sample time
ControlTs=block.DialogPrm(1).Data;
block.SampleTimes = [ControlTs 0]; %[discrete time, offset]

%specify block simStateCompliace
block.SimStateCompliance = 'HasNoSimState';

%register functions
block.RegBlockMethod('InitializeConditions',    @InitializeConditions);
block.RegBlockMethod('Start',                   @Start);
block.RegBlockMethod('Terminate',               @Terminate);
block.RegBlockMethod('Outputs',                 @Outputs);
block.RegBlockMethod('CheckParameters',         @CheckPrms);
block.RegBlockMethod('ProcessParameters',       @ProcessPrms);
end
function ProcessPrms(block) %runs on every dt (Wasnt checked!)
  block.AutoUpdateRuntimePrms;
end
function InitializeConditions(block) %runs on t=0 and when susbystem is enabled
Enable=block.InputPort(1).Data(1);
if ~Enable, return, end

%check if figute exists and valid. if not - reset it
UserData=get(gcbh,'UserData');
if isempty(UserData) %first time simulation is activated
     SetupFigAndUserData(block);
elseif ~ishghandle(UserData.Fig) %figure was deleted
    SetupFigAndUserData(block);
else %figure exists, just clear it and start a new
    SetupFigAndUserData(block,UserData.Fig); %reset figure
end
end
function Outputs(block) %runs on every dt
UserData=get(gcbh,'UserData');
if ~ishghandle(UserData.Fig)
     UserData=SetupFigAndUserData(block); %set figure to a new start
end
%General inputs
x=block.InputPort(2).Data(1);
y=block.InputPort(2).Data(2);
% v=block.InputPort(2).Data(3);
theta=block.InputPort(2).Data(4);
% delta=block.InputPort(2).Data(5);

%fix limits
L=block.DialogPrm(2).Data;
xlim(UserData.Axes,10*L*[-1,1]+x);  ylim(UserData.Axes,10*L*[-1,1]+y);

%update Physics
R=makehgtform('zrotate',theta);
T=makehgtform('translate',[x,y,0]);
UserData.hCarTransform.Matrix=T*R;
addpoints(UserData.hPastLine,x,y);

%Update time text
Time=block.InputPort(3).Data(1);
UserData.hTime.String=sprintf('Time %g[s]',Time);

%outputs - keystrkes
CurrentChar=UserData.Fig.CurrentCharacter;
if ~isempty(CurrentChar)
    block.OutputPort(1).Data=double(CurrentChar);
    block.OutputPort(2).Data=1;
    UserData.Fig.CurrentCharacter=char(0);
else
    block.OutputPort(1).Data=0;
    block.OutputPort(2).Data=0;
end


drawnow limitrate
end
%% Auxiliary functions
function UserData=SetupFigAndUserData(block,varargin)
if nargin<2 %figure was not provided in input
    %Create figure
    FigName='OnlyPhysics';
    Fig = figure(...
        'Name',              FigName,...
        'NumberTitle',        'off',...
        'IntegerHandle',     'off',...
        'Color',             [1,1,1],...
        'MenuBar',           'figure',...
        'ToolBar',           'auto',...
        'HandleVisibility',   'callback',...
        'Resize',            'on',...
        'visible',           'on');
    
    %Create Axes
    Axes=axes(Fig);
    hold(Axes,'on'); grid(Axes,'on'); axis(Axes,'manual')
    Axes.DataAspectRatio=[1,1,1];
    L=block.DialogPrm(2).Data; 
    xlim(Axes,10*L*[-1,1]);  ylim(Axes,10*L*[-1,1]);
    xlabel(Axes,'[m]'); ylabel(Axes,'[m]');
else %figure was provided in input
    Fig=varargin{1};
    Axes=findobj(Fig,'type','axes');
    cla(Axes);
end

%Initalize Drawing
x=block.InputPort(2).Data(1);
y=block.InputPort(2).Data(2);
v=block.InputPort(2).Data(3);
theta=block.InputPort(2).Data(4);
delta=block.InputPort(2).Data(5);
L=block.DialogPrm(2).Data; 

hCarTransform=hgtransform(Axes);
DrawCar(hCarTransform,L/2,L);
hPastLine=animatedline(Axes,0,0,'linewidth',2,'color','r');

%Initalize text for time
xtext=0.9*Axes.XLim(1)+0.1*Axes.XLim(2);
ytext=0.1*Axes.YLim(1)+0.9*Axes.YLim(2);
hTime=text(Axes,xtext,ytext,'');
%% Storing handles to "figure" and block "UserData"
UserData.Fig = Fig;
UserData.Axes = Axes;
UserData.hCarTransform = hCarTransform;
UserData.hPastLine=hPastLine;
UserData.hTime = hTime;

%Store in both figure and block
set(gcbh,'UserData',UserData);
end
function GraphicHandles=DrawCar(Parent,W,L)
        purple=[0.5,0,0.5];
        yellow=[1,0.8,0];
        t=linspace(0,2*pi,7);
        t=t(1:end-1);
        r=W/6; %lights raidus
        
        %Draw carBody
        x_body=[-L/2, L/2, L/2, -L/2];
        y_body=[-W/2, -W/2, W/2, W/2];
        cgh=patch('Parent',Parent,'XData',x_body,'YData',y_body,'facecolor',purple);
        
        %Draw right light
        x_rl=r*cos(t)+L/2;
        y_rl=r*sin(t)+W/4;
        rlh=patch('Parent',Parent,'XData',x_rl,'YData',y_rl,'facecolor',yellow);
        
        %Draw left light
        x_ll=r*cos(t)+L/2;
        y_ll=r*sin(t)-W/4;
        llh=patch('Parent',Parent,'XData',x_ll,'YData',y_ll,'facecolor',yellow);
        
        GraphicHandles=[cgh,rlh,llh];
end
%% Unused fcns
function Terminate(block)
end
function Start(block)
Enable=block.InputPort(1).Data(1);
if ~Enable, return, end


end
function CheckPrms(block)
  %can check validity of parameters here
end

