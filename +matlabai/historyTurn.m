function pair = historyTurn(prompt, answer)
% Full code and attachments are supplied once in the latest input, not history.
summary=matlabai.methodSummary(answer);
text=regexprep(summary.body,'(?ms)^\s*(`{3,}|~{3,})[^\r\n]*\r?\n.*?^\s*\1\s*$','[本轮代码/方案见当前预览，历史不重复嵌入全文]');
if startsWith(strtrim(summary.body),'{')
    try
        matlabai.decodePlan(summary.body);
        text='[本轮完整建模方案见当前预览，历史不重复嵌入全文]';
    catch
    end
end
if strcmp(summary.state,'structured')
    text=[text newline '模型与算法摘要：' newline summary.text];
end
if numel(text)>12000,text=[text(1:12000) newline '[较早回复已精简；完整内容见对话记录]'];end
pair={struct('role','user','content',char(prompt)),struct('role','assistant','content',text)};
end
