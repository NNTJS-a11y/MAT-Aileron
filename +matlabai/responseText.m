function answer = responseText(response)
if ~isstruct(response) || ~isfield(response, 'choices') || isempty(response.choices)
    error('MatlabAI:Response', '服务没有返回 choices，请检查是否为 Chat Completions API 地址。');
end
choices = response.choices;
if iscell(choices), choice = choices{1}; else, choice = choices(1); end
if isfield(choice,'finish_reason') && ~isempty(choice.finish_reason) && ~strcmp(choice.finish_reason,'stop')
    error('MatlabAI:IncompleteResponse','服务返回的回复未正常完成（%s）。未将其作为可运行代码；请分步请求或调整服务输出限制。',char(string(choice.finish_reason)));
end
if ~isfield(choice, 'message') || ~isfield(choice.message, 'content') || ...
        ~(ischar(choice.message.content) || isstring(choice.message.content)) || isempty(choice.message.content)
    error('MatlabAI:Response', '服务未返回文本内容，可能被拒绝或响应格式不兼容。');
end
answer = char(choice.message.content);
end
