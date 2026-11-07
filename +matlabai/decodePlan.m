function plan = decodePlan(answer)
summary=matlabai.methodSummary(answer);
answer=summary.body;
blocks = regexp(char(answer), '(?mi)^\s*```json[^\S\r\n]*\r?\n([\s\S]*?)^\s*```[^\S\r\n]*$', 'tokens');
if isempty(blocks)
    raw = strtrim(char(answer));
else
    if numel(blocks) ~= 1, error('MatlabAI:Plan', '请让模型仅返回一个 JSON 方案。'); end
    raw = blocks{1}{1};
end
try
    decoded = jsondecode(raw);
catch
    error('MatlabAI:Plan', '当前内容不是有效的 Simulink JSON 方案。数学建模竞赛、Excel分析和填表请使用“MATLAB 对话”，生成代码后点击“运行代码…”；控制/信号系统建模请先发送需求并等待完整 JSON 方案。');
end
plan = matlabai.validatePlan(decoded);
end
