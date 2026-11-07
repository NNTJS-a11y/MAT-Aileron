function result = runIsolatedCode(code, shouldStop, timeout, onStatus)
% Separate MATLAB process, not an OS security sandbox. No shell interpolation.
if nargin<2,shouldStop=@() false;end
if nargin<3,timeout=getpref('MatlabAI','RunTimeoutSeconds',300);end
if nargin<4,onStatus=@(~) [];end
validateattributes(timeout,{'numeric'},{'scalar','finite','positive'});
result=matlabai.prepareCodeFile(code);
report=matlabai.checkCodeFile(result.path);
if ~report.ok,error('MatlabAI:CodeSyntax','未启动运行：%s',report.summary);end
folder=fileparts(result.path);
result.workspacePath=fullfile(folder,'workspace.mat');
result.logPath=fullfile(folder,'process.log');
config=struct('source',result,'root',fileparts(fileparts(mfilename('fullpath'))));
configPath=fullfile(folder,'job.mat');save(configPath,'config');
escapedRoot=strrep(config.root,'''','''''');escapedConfig=strrep(configPath,'''','''''');
expression=sprintf('addpath(''%s'');matlabai.isolatedWorker(''%s'');',escapedRoot,escapedConfig);
executable=fullfile(matlabroot,'bin','matlab');
% Launch the actual executable on Windows, not the bin launcher wrapper.
% This ensures destroyForcibly targets the MATLAB doing the computation.
if ispc,executable=fullfile(matlabroot,'bin','win64','MATLAB.exe');end
args=java.util.ArrayList;args.add(executable);
args.add('-batch');args.add(expression);
builder=java.lang.ProcessBuilder(args);builder.directory(java.io.File(folder));
builder.redirectErrorStream(true);builder.redirectOutput(java.io.File(result.logPath));
try
    process=builder.start();
catch problem
    error('MatlabAI:WorkerStart','独立MATLAB未能启动：%s。未在主工作区回退执行。',problem.message);
end
cleanup=onCleanup(@() stopProcess(process));
clock=tic;onStatus('独立MATLAB正在启动；启动时间计入超时，可点击停止运行');
while process.isAlive()
    drawnow;pause(0.1);
    if shouldStop()
        error('MatlabAI:RunCancelled','已停止独立运行。已写出的文件不会回滚；源文件与日志：%s',folder);
    end
    if toc(clock)>timeout
        error('MatlabAI:RunTimeout','独立运行超过%.0f秒（含启动）已终止。源文件与日志：%s',timeout,folder);
    end
end
status=fullfile(folder,'status.mat');
if process.exitValue()~=0 || ~isfile(status)
    error('MatlabAI:WorkerFailed','独立进程异常退出或没有结果。可能缺少可用许可，请查看日志：%s',result.logPath);
end
loaded=load(status,'outcome');outcome=loaded.outcome;
if ~outcome.ok,error('MatlabAI:GeneratedExecution','%s\n源文件及日志：%s',outcome.error,folder);end
result.executed=outcome.executed;result.requiredInputs=outcome.requiredInputs;
end
function stopProcess(process)
try
    if process.isAlive()
        % Kill descendants when the Java runtime exposes ProcessHandle (Java 9+).
        try
            descendants=process.descendants().iterator();
            while descendants.hasNext(),child=descendants.next();child.destroyForcibly();end
        catch
        end
        process.destroyForcibly();
        process.waitFor(5,java.util.concurrent.TimeUnit.SECONDS);
    end
catch
end
end
