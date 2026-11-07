classdef StartupPresentation < handle
    % Optional, nonmodal startup surface. Its failure must never block the app.
    properties (SetAccess=private)
        Window = []
        Component = []
    end
    properties (Access=private)
        Watchdog = []
        GateTimer = []
        TargetWindow = []
        PaintedClock = []
        ReadyClock = []
        FadeClock = []
        ReadyToShow = false
        Closing = false
    end
    methods
        function splash=StartupPresentation(timeout,source)
            if nargin<1,timeout=12;end
            if nargin<2,source=fullfile(fileparts(fileparts(mfilename('fullpath'))),'startup-animation-native.html');end
            try
                screen=get(groot,'ScreenSize');width=min(720,max(400,screen(3)-80));height=min(460,max(300,screen(4)-120));
                splash.Window=uifigure('Name','MAT Aileron','Tag','AileronStartupSplash', ...
                    'Position',[max(10,(screen(3)-width)/2) max(30,(screen(4)-height)/2) width height], ...
                    'Color',[245 245 247]/255,'Resize','off','Visible','off','WindowStyle','normal', ...
                    'CloseRequestFcn',@(~,~) splash.close(),'DeleteFcn',@(~,~) splash.close(), ...
                    'WindowKeyPressFcn',@(~,event) splash.keyPressed(event));
                layout=uigridlayout(splash.Window,[1 1],'Padding',[0 0 0 0]);
                splash.Component=uihtml(layout,'HTMLSource',source,'Data',struct('ready',false), ...
                    'DataChangedFcn',@(~,~) splash.browserEvent());
                splash.Watchdog=timer('Name','MatAileronStartupWatchdog','ExecutionMode','singleShot', ...
                    'StartDelay',timeout,'TimerFcn',@(~,~) splash.close());
                start(splash.Watchdog);splash.Window.Visible='on';drawnow;
            catch problem
                splash.close();rethrow(problem);
            end
        end
        function ready(splash,targetWindow)
            if nargin>1,splash.TargetWindow=targetWindow;end
            if splash.Closing
                splash.showTarget();return;
            end
            if ~splash.ReadyToShow,splash.ReadyClock=tic;end
            splash.ReadyToShow=true;
            if ~isempty(splash.Component)&&isgraphics(splash.Component)
                if ~isempty(splash.Watchdog)&&isvalid(splash.Watchdog)
                    stop(splash.Watchdog);splash.Watchdog.StartDelay=8;start(splash.Watchdog);
                end
                figure(splash.Window);
                splash.Component.Data=struct('ready',true);
                if isempty(splash.GateTimer)
                    splash.GateTimer=timer('Name','MatAileronStartupHold','ExecutionMode','fixedSpacing', ...
                        'Period',.1,'StartDelay',.1,'BusyMode','drop','TimerFcn',@(~,~) splash.advance());
                    start(splash.GateTimer);
                end
            end
        end
        function close(splash)
            if splash.Closing,return;end
            splash.Closing=true;
            if ~isempty(splash.GateTimer)&&isvalid(splash.GateTimer)
                splash.GateTimer.TimerFcn=[];stop(splash.GateTimer);delete(splash.GateTimer);
            end
            splash.GateTimer=[];
            if ~isempty(splash.Watchdog)&&isvalid(splash.Watchdog)
                splash.Watchdog.TimerFcn=[];stop(splash.Watchdog);delete(splash.Watchdog);
            end
            splash.Watchdog=[];window=splash.Window;splash.Window=[];splash.Component=[];
            if ~isempty(window)&&isgraphics(window)
                window.CloseRequestFcn=[];window.DeleteFcn=[];delete(window);
            end
            splash.showTarget();
        end
        function delete(splash)
            splash.close();
        end
    end
    methods (Access=private)
        function browserEvent(splash)
            if isempty(splash.Component)||~isgraphics(splash.Component),return;end
            data=splash.Component.Data;
            if ~isstruct(data)||~isfield(data,'action'),return;end
            switch data.action
                case 'painted'
                    if isempty(splash.PaintedClock),splash.PaintedClock=tic;end
                case 'skip'
                    splash.close();
                case 'finished'
                    % A stale/early web callback cannot bypass the native hold.
                    if ~isempty(splash.FadeClock)&&toc(splash.FadeClock)>=.65,splash.close();end
            end
        end
        function advance(splash)
            if splash.Closing||~splash.ReadyToShow||isempty(splash.PaintedClock),return;end
            if isempty(splash.FadeClock)
                if toc(splash.PaintedClock)<3||toc(splash.ReadyClock)<3,return;end
                splash.FadeClock=tic;
                if ~isempty(splash.Component)&&isgraphics(splash.Component)
                    splash.Component.Data=struct('ready',true,'fade',true);
                end
            elseif toc(splash.FadeClock)>=.65
                splash.close();
            end
        end
        function showTarget(splash)
            if ~isempty(splash.TargetWindow)&&isgraphics(splash.TargetWindow)
                splash.TargetWindow.Visible='on';
            end
        end
        function keyPressed(splash,event)
            if strcmp(event.Key,'escape'),splash.close();end
        end
    end
end
