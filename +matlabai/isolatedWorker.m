function isolatedWorker(configPath)
% Called only by the dedicated -batch child MATLAB.
loaded=load(configPath,'config');config=loaded.config;
folder=fileparts(configPath);source=config.source;
outcome=struct('ok',false,'executed',false,'requiredInputs',0,'error','');
try
    % User startup scripts may populate base even in batch mode.
    % Clear that child-only workspace before executing the generated source.
    evalin('base','clearvars');
    set(groot,'defaultFigureVisible','off');
    addpath(fileparts(source.path),'-begin');
    if source.isFunction
        inputs=nargin(source.name);if inputs<0,inputs=-inputs-1;end
        outcome.requiredInputs=inputs;
        if inputs==0,evalin('base',sprintf('feval(''%s'');',source.name));outcome.executed=true;end
    else
        escaped=strrep(source.path,'''','''''');
        evalin('base',sprintf('run(''%s'');',escaped));outcome.executed=true;
    end
    % Restore package path after generated code may have changed it.
    addpath(config.root);
    workspacePath=strrep(fullfile(folder,'workspace.mat'),'''','''''');
    try
        evalin('base',sprintf('save(''%s'');',workspacePath));
    catch problem
        fprintf('工作区保存未完成：%s\n',problem.message);
    end
    figures=findall(groot,'Type','figure');
    for index=1:numel(figures)
        drawnow;
        try
            exportgraphics(figures(index),fullfile(folder,sprintf('figure-%d.png',index)));
        catch problem
            fprintf('图像导出失败：%s\n',problem.message);
        end
        try,savefig(figures(index),fullfile(folder,sprintf('figure-%d.fig',index)));catch,end
    end
    outcome.ok=true;
catch problem
    outcome.error=getReport(problem,'extended','hyperlinks','off');
end
save(fullfile(folder,'status.mat'),'outcome');
end
