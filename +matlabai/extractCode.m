function [code, note] = extractCode(answer)
% Parse fences as pairs: never mistake another language's closing fence for an opener.
summary=matlabai.methodSummary(answer);
answer=summary.body;
lines=splitlines(string(answer));
blocks={}; active=false; accepted=false; buffer={}; marker=''; note='';
for index=1:numel(lines)
    line=char(lines(index));
    if ~active
        token=regexp(line,'^\s*(`{3,}|~{3,})([^\r\n]*)$','tokens','once');
        if ~isempty(token)
            active=true;marker=token{1};
            accepted=any(strcmpi(strtrim(token{2}),{'','matlab','m'}));buffer={};
        end
    elseif ~isempty(regexp(line,['^\s*' marker(1) '{' num2str(numel(marker)) ',}\s*$'],'once'))
        if accepted,blocks{end+1}=strtrim(strjoin(buffer,newline));end %#ok<AGROW>
        active=false;buffer={};
    elseif accepted
        buffer{end+1}=line; %#ok<AGROW>
    end
end
code='';
if active && accepted
    note='MATLAB代码块未闭合，可能被截断；未替换原代码。请要求返回完整代码块。';return;
end
if isempty(blocks)
    note='回复未包含完整MATLAB代码块，原代码保留。需要运行时请要求返回完整的 ```matlab 代码块。';return;
end
isFunction=false(size(blocks));
for index=1:numel(blocks)
    try
        info=matlabai.codeFileInfo(blocks{index});isFunction(index)=info.isFunction;
    catch
        % Keep malformed source visible so the analyzer/repair flow can explain it.
        isFunction(index)=false;
    end
end
% Separate helper-function blocks belong after all script fragments for older releases.
if any(~isFunction) && any(isFunction)
    blocks=[blocks(~isFunction),blocks(isFunction)];
    note='已合并脚本片段，并将独立函数片段放到末尾；请检查这些片段是否属于同一程序。';
elseif numel(blocks)>1
    note='已合并多个代码块；如果是不同备选方案或独立文件，请要求AI返回一个完整入口文件。';
end
code=strjoin(blocks,[newline newline]);
end
