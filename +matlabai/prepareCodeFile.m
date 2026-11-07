function result = prepareCodeFile(code, root)
if nargin<2,root=matlabai.dataRoot('runs');end
info=matlabai.codeFileInfo(code);
if isempty(strtrim(info.code)),error('MatlabAI:EmptyCode','没有可检查或运行的代码。');end
if info.isClass,error('MatlabAI:ClassFile','当前运行入口支持脚本和函数；classdef 类请另存为对应类名文件，在编辑器中管理。');end
if ~isfolder(root),mkdir(root);end
folder=tempname(root);mkdir(folder);
if ~info.isFunction
    [~,token]=fileparts(folder);
    info.name=matlab.lang.makeValidName(['ai_run_' token]);
end
filePath=fullfile(folder,[info.name '.m']);
file=fopen(filePath,'w','n','UTF-8');
if file<0,error('MatlabAI:SaveCode','无法保存代码文件：%s',filePath);end
cleanup=onCleanup(@() fclose(file));fprintf(file,'%s',info.code);clear cleanup
result=struct('path',filePath,'name',info.name,'executed',false, ...
    'requiredInputs',0,'isFunction',info.isFunction);
end
