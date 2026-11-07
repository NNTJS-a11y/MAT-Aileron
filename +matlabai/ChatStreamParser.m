classdef ChatStreamParser < handle
    properties (SetAccess = private)
        Text = ''
        Done = false
        FinishReason = ''
        SawEvent = false
    end
    properties (Access = private)
        Buffer = uint8([])
        EventLines = {}
        OnText
        Bytes = 0
    end
    methods
        function parser = ChatStreamParser(onText)
            if nargin < 1, onText = []; end
            parser.OnText = onText;
        end
        function feed(parser, bytes)
            parser.Bytes = parser.Bytes + numel(bytes);
            limits = matlabai.responseLimits;
            if parser.Bytes > limits.wireBytes
                error('MatlabAI:StreamSize', '本次流式传输超过32 MB（含协议及推理数据）。请按子问题分步生成；当前不完整回复不会执行。');
            end
            parser.Buffer = [parser.Buffer, reshape(uint8(bytes),1,[])];
            while true
                ending = find(parser.Buffer == 10, 1);
                if isempty(ending), break; end
                line = native2unicode(parser.Buffer(1:ending-1), 'UTF-8');
                parser.Buffer(1:ending) = [];
                if ~isempty(line) && line(end) == char(13), line(end) = []; end
                parser.line(line);
            end
        end
        function finish(parser)
            if ~isempty(parser.Buffer)
                parser.line(native2unicode(parser.Buffer, 'UTF-8'));
                parser.Buffer = uint8([]);
            end
            parser.dispatch();
        end
        function validate(parser)
            if strcmp(parser.FinishReason, 'length')
                error('MatlabAI:IncompleteStream', '回复因长度限制被截断，未执行代码或建模。请缩小需求后重试。');
            end
            if ~isempty(parser.FinishReason) && ~strcmp(parser.FinishReason,'stop')
                error('MatlabAI:IncompleteStream','服务未正常完成正文（%s）；未执行代码或建模。',parser.FinishReason);
            end
            if ~parser.Done && ~strcmp(parser.FinishReason, 'stop')
                error('MatlabAI:IncompleteStream', '流式连接提前结束，回复不完整，未执行建模。请重试。');
            end
            if isempty(strtrim(parser.Text)), error('MatlabAI:EmptyStream', '模型没有返回可显示的正文。'); end
        end
    end
    methods (Access = private)
        function line(parser, text)
            if isempty(text)
                parser.dispatch();
            elseif startsWith(text, 'data:')
                value = text(6:end);
                if startsWith(value, ' '), value(1) = []; end
                parser.EventLines{end+1} = value;
            end
        end
        function dispatch(parser)
            if isempty(parser.EventLines), return; end
            data = strjoin(parser.EventLines, newline);
            parser.EventLines = {};
            parser.SawEvent = true;
            if strcmp(strtrim(data), '[DONE]'), parser.Done = true; return; end
            if parser.Done, return; end
            event = jsondecode(data);
            if isfield(event, 'error')
                error('MatlabAI:StreamAPI', '%s', jsonencode(event.error));
            end
            if ~isfield(event, 'choices') || isempty(event.choices), return; end
            choices = event.choices;
            if iscell(choices), choice = choices{1}; else, choice = choices(1); end
            if isfield(choice, 'finish_reason') && ~isempty(choice.finish_reason)
                parser.FinishReason = char(string(choice.finish_reason));
            end
            if isfield(choice, 'delta') && isfield(choice.delta, 'content') && ~isempty(choice.delta.content)
                parser.Text = [parser.Text, char(string(choice.delta.content))];
                limits = matlabai.responseLimits;
                if numel(parser.Text) > limits.textCharacters
                    error('MatlabAI:StreamSize', '回复正文超过500,000字符。请让模型用代码生成数据表，避免逐行输出全部数据；当前不完整回复不会执行。');
                end
                if ~isempty(parser.OnText), parser.OnText(parser.Text); end
            end
        end
    end
end
