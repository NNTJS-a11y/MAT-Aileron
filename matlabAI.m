function app = matlabAI
persistent instance starting
if ~isempty(starting)&&starting,app=[];return;end
if isempty(instance) || ~isvalid(instance) || ~isgraphics(instance.Window)
    starting=true;
    try
        if usejava('desktop')&&getpref('MatlabAI','StartupAnimation',true)
            instance = matlabai.launchAssistant();
        else
            instance = MatlabAIAssistant;
        end
    catch problem
        starting=false;rethrow(problem);
    end
    starting=false;
else
    activeSplash=findall(groot,'Tag','AileronStartupSplash');
    if strcmp(instance.Window.Visible,'off')&&~isempty(activeSplash)
        figure(activeSplash(1));
    else
        figure(instance.Window);
    end
end
app = instance;
end
