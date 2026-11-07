function [messages, retained, omitted, estimate] = buildMessages(system, history, user, budget)
% Byte count is a deliberately conservative estimate, not a provider tokenizer.
if nargin<4,budget=getpref('MatlabAI','ContextTokenBudget',128000);end
if ~isscalar(budget) || ~isfinite(budget) || budget<4096
    error('MatlabAI:ContextBudget','上下文预算必须至少为4096。');
end
retained=history;omitted=0;
while true
    messages=[{system},retained,{user}];
    estimate=sum(cellfun(@cost,messages));
    if estimate<=budget,break;end
    if isempty(retained)
        error('MatlabAI:ContextBudget','本轮必要内容保守估计%d token，超过预算%d。请精简附件或在工作区设置中按服务实际限制调整预算；不会截断附件或代码。',estimate,budget);
    end
    % Discard whole old exchanges; never split a user/assistant pair.
    count=min(2,numel(retained));retained(1:count)=[];omitted=omitted+count;
end
end
function count=cost(message)
count=numel(unicode2native(char(message.content),'UTF-8'))+16;
end
