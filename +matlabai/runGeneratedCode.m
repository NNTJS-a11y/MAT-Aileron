function result = runGeneratedCode(code, root)
% MATLAB function definitions require a source file, never direct eval text.
if nargin<2,result=matlabai.prepareCodeFile(code);else,result=matlabai.prepareCodeFile(code,root);end
filePath=result.path;name=result.name;folder=fileparts(filePath);
report=matlabai.checkCodeFile(filePath);
if ~report.ok
    error('MatlabAI:CodeSyntax','运行前检查未通过，未执行任何代码。文件：%s\n%s',filePath,report.summary);
end
previousFolder=pwd;previousPath=path;
environmentCleanup=onCleanup(@() restoreEnvironment(previousFolder,previousPath));
try
    if result.isFunction
        addpath(folder,'-begin');
        resolved=which(name);
        if ~strcmpi(resolved,filePath),error('MatlabAI:FunctionResolution','函数名称与已加载内容冲突，请在编辑器中手动运行：%s',filePath);end
        inputs=nargin(name);
        if inputs<0,inputs=-inputs-1;end
        result.requiredInputs=inputs;
        if inputs>0,return;end
        % feval avoids accidentally reading a base variable with the same name.
        evalin('base',sprintf('feval(''%s'');',name));
    else
        escaped=strrep(strrep(filePath,'\','/'),'''','''''');
        evalin('base',sprintf('run(''%s'');',escaped));
    end
    result.executed=true;
catch problem
    enriched=MException('MatlabAI:GeneratedExecution','代码文件已保留：%s\n\n%s',filePath,getReport(problem,'extended','hyperlinks','off'));
    enriched=addCause(enriched,problem);throw(enriched);
end
end

function restoreEnvironment(previousFolder,previousPath)
if isfolder(previousFolder),cd(previousFolder);end
path(previousPath);
end
