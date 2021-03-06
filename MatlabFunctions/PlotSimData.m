%% Initalize

IMUdt=0.01; %from simulation
GPSdt=0.1; %from simulation
T=simout.Ground_Truth.x.Time(end); %max simulation time seconds
IMUtime=0:IMUdt:T; %shortest time in system - we will run on it. same as ground truth_time

%assumes LeftCones and RightCones is already in base workspace as it is required
%to run the simulation

%% Create graphic objects
Fig = figure(...
    'NumberTitle',        'off',...
    'units',            'normalized',...
    'Color',             [1,1,1]);

%Create Scene Axes
SceneAxes=axes(...
    'position',     [0.25,0.1,0.9,0.75],... %[Left,Buttom,Height,Width]
    'parent',       Fig);
hold(SceneAxes,'on'); grid(SceneAxes,'on'); axis(SceneAxes,'manual');
SceneAxes.DataAspectRatio=[1,1,1];

TimeAxes=axes(...
    'Parent',       Fig,...
    'position',     [0,0.7,0.2,0.2],... %[Left,Buttom,Height,Width]
    'NextPlot',     'add',...
    'Xtick',        [],...
    'Ytick',        [],...
    'Xcolor',       'none',...
    'Ycolor',       'none',...
    'XLim',          [-2,2],...
    'YLim',          [-2,2]);

%plot cones
LeftColor=[0,0,1]; %blue
RightColor=[0.9,0.9,0]; %yellow
ConeEdgeColor=[0.5,0.5,0];
Msize=4;
plot(SceneAxes,LeftCones(:,1),LeftCones(:,2),'color',LeftColor,...
    'linewidth',1,'marker','o','linestyle','-','markersize',...
    Msize,'markerfacecolor',LeftColor,'markeredgecolor',ConeEdgeColor);
plot(SceneAxes,RightCones(:,1),RightCones(:,2),'color',RightColor,...
    'linewidth',1,'marker','o','linestyle','-','markersize',...
    Msize,'markerfacecolor',RightColor,'markeredgecolor',ConeEdgeColor);

hSeenCones=scatter(SceneAxes,0,0,50,'m');

%TimeAxes
DrawClock(TimeAxes);
hTimeTxt=text(TimeAxes,-1,2,'');

%% plot
 for t=IMUtime
    IMUidx=fix(t/IMUdt)+1;
    
    %plot ground truth
    x_gt=simout.Ground_Truth.x.Data(IMUidx);
    y_gt=simout.Ground_Truth.y.Data(IMUidx);
    plot(SceneAxes,x_gt,y_gt,'og','markerfacecolor','g','MarkerSize',2);
    
    %gps measurements
    if mod(t,GPSdt)==0
        GPSidx=fix(t/GPSdt)+1;
        x_meas=simout.Measurements.x.Data(GPSidx);
        y_meas=simout.Measurements.y.Data(GPSidx);
        plot(SceneAxes,x_meas,y_meas,'or','markerfacecolor','r','MarkerSize',4);
    end
    
    %seen cones
    LC_Seen=simout.Cones.LeftConesSeen.Data(IMUidx,:);
    RC_Seen=simout.Cones.RightConesSeen.Data(IMUidx,:);
    hSeenCones.XData=[LeftCones(LC_Seen,1);RightCones(RC_Seen,1)];
    hSeenCones.YData=[LeftCones(LC_Seen,2);RightCones(RC_Seen,2)];
    
    xlim(SceneAxes,[x_gt-30,x_gt+30]); ylim(SceneAxes,[y_gt-30,y_gt+30])
    hTimeTxt.String=sprintf('Time %g[s]',t);
    
    pause(IMUdt/100);
    drawnow limitrate;
end

axis(SceneAxes,'auto');
%% functions

function hClock=DrawClock(Parent)
t=linspace(0,2*pi,16);
hCircle=plot(cos(t),sin(t),'linewidth',2,'color','k','Parent',Parent);
hSmallLine=plot([0,0.5*cos(pi/3)],[0,0.5*sin(pi/3)],'linewidth',2,'color','k','Parent',Parent);
hBigLine=plot([0,cos(pi/2)],[0,sin(pi/2)],'linewidth',2,'color','k','Parent',Parent);
hClock=[hCircle,hSmallLine,hBigLine];
end