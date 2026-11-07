function info = codeFileInfo(code)
code=char(code);
code=strrep(strrep(code,sprintf('\r\n'),newline),sprintf('\r'),newline);
if ~isempty(code) && code(1)==char(65279),code(1)=[];end
lines=splitlines(string(code));
first=''; start=1; inComment=false;
for index=1:numel(lines)
    line=strtrim(char(lines(index)));
    if strcmp(line,'%{'),inComment=true;continue;end
    if strcmp(line,'%}'),inComment=false;continue;end
    if inComment || isempty(line) || startsWith(line,'%'),continue;end
    first=line;start=index;break;
end
isFunction=~isempty(regexp(first,'^function(?:\s|$)','once'));
name='ai_run';
if isFunction
    declaration=regexprep(char(strjoin(lines(start:end),newline)),'\.\.\.[^\r\n]*\r?\n',' ');
    match=regexp(declaration,'^\s*function\s+(?:(?:\[[^\]]*\]|[A-Za-z]\w*)\s*=\s*)?([A-Za-z]\w*)\s*(?:\(|;|%|\r|\n|$)','tokens','once');
    if isempty(match),error('MatlabAI:FunctionHeader','无法识别主函数名称，请检查 function 声明。');end
    name=match{1};
end
info=struct('code',code,'name',name,'isFunction',isFunction, ...
    'isClass',~isempty(regexp(first,'^classdef(?:\s|\(|$)','once')));
end
