function app=launchAssistant(factory,splashFactory)
% Shared launch logic, with injectable factories for offline lifecycle tests.
if nargin<1,factory=@(visibility) MatlabAIAssistant([],visibility);end
if nargin<2,splashFactory=@() matlabai.StartupPresentation();end
splash=[];
try
    splash=splashFactory();
catch problem
    warning('MatlabAI:StartupAnimation','启动动画不可用，继续打开助手：%s',problem.message);
end
try
    app=factory('off');
catch problem
    if ~isempty(splash),splash.close();end
    rethrow(problem);
end
if ~isempty(splash)
    try,splash.ready(app.Window);catch,splash.close();app.Window.Visible='on';end
else
    app.Window.Visible='on';
end
end
