function result = methodSummary(answer)
% Only summarize user-visible content. Provider reasoning_content is never read.
answer=strrep(strrep(char(answer),sprintf('\r\n'),newline),sprintf('\r'),newline);
lines=splitlines(string(answer));
parts={};body={};prose={};active=false;inFence=false;marker='';found=false;complete=false;
for index=1:numel(lines)
    line=char(lines(index));trimmed=strtrim(line);
    if active
        if strcmp(trimmed,'</model_summary>')
            active=false;complete=true;
        else
            parts{end+1}=line; %#ok<AGROW>
        end
        continue;
    end
    if ~inFence && strcmp(trimmed,'<model_summary>')
        active=true;found=true;continue;
    end
    body{end+1}=line; %#ok<AGROW>
    if ~inFence
        token=regexp(line,'^\s*(`{3,}|~{3,})[^\r\n]*$','tokens','once');
        if ~isempty(token),inFence=true;marker=token{1};continue;end
        prose{end+1}=line; %#ok<AGROW>
    elseif ~isempty(regexp(line,['^\s*' marker(1) '{' num2str(numel(marker)) ',}\s*$'],'once'))
        inFence=false;
    end
end
state='missing';text='本轮尚未提供模型与算法说明。生成代码时，助手会要求同时说明模型、假设、算法和验证方法。';
if found
    text=strtrim(strjoin(parts,newline));
    if active || ~complete
        state='partial';
    elseif isempty(text)
        state='missing';text='模型返回了空的方法说明，请继续要求补充模型、假设和算法依据。';
    else
        state='structured';
    end
elseif ~isempty(prose)
    fallback=strtrim(strjoin(prose,newline));
    if ~isempty(fallback) && ~startsWith(fallback,'{') && ~startsWith(fallback,'[')
        text=['本轮未按结构提供方法摘要，以下为回复中的说明文字，请核对是否足够：' newline newline fallback];
        state='fallback';
    end
end
if numel(text)>12000
    text=[text(1:12000) newline '（此栏仅展示前12,000字符，完整回复见对话区。）'];
end
if active || ~found,bodyText=answer;else,bodyText=strjoin(body,newline);end
result=struct('text',text,'state',state,'body',bodyText);
end
