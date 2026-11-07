function response = request(endpoint, payload, key, onText, shouldStop)
if nargin >= 4 && payload.stream
    if nargin < 5, shouldStop = @() false; end
    headers = [matlab.net.http.field.ContentTypeField('application/json'), ...
        matlab.net.http.HeaderField('Accept', 'text/event-stream')];
    if ~isempty(key), headers(end+1) = matlab.net.http.HeaderField('Authorization', ['Bearer ' key]); end
    message = matlab.net.http.RequestMessage('post', headers, matlab.net.http.MessageBody(payload));
    consumer = matlabai.ChatStreamConsumer(onText, shouldStop);
    monitor = matlabai.ChatProgressMonitor(shouldStop);
    options = matlab.net.http.HTTPOptions('ConnectTimeout', 15, 'ResponseTimeout', 90, ...
        'DataTimeout', 60, 'MaxRedirects', 0, 'UseProgressMonitor', true, 'ProgressMonitorFcn', @() monitor);
    uri = matlab.net.URI(endpoint);
    if any(strcmpi(char(uri.Host), {'localhost','127.0.0.1'})), options.UseProxy = false; end
    try
        result = message.send(uri, options, consumer);
    catch problem
        if shouldStop(), error('MatlabAI:Cancelled', '已停止生成；未提交不完整回复或执行建模。'); end
        rethrow(problem);
    end
    if shouldStop(), error('MatlabAI:Cancelled', '已停止生成。'); end
    if double(result.StatusCode) ~= 200
        detail = result.Body.Data;
        if isstruct(detail), detail = jsonencode(detail); else, detail = char(string(detail)); end
        detail = detail(1:min(numel(detail),1500));
        error('MatlabAI:HTTP', 'API 返回 HTTP %d：%s', double(result.StatusCode), detail);
    end
    if ~consumer.Parser.SawEvent
        response = jsondecode(native2unicode(consumer.Raw, 'UTF-8'));
        text = matlabai.responseText(response);
        limits = matlabai.responseLimits;
        if numel(text) > limits.textCharacters
            error('MatlabAI:StreamSize', '回复正文超过500,000字符，请分步生成。');
        end
        onText(text);
        return;
    end
    consumer.Parser.validate();
    response = struct('choices', struct('message', struct('content', consumer.Parser.Text)));
    return;
end
options = weboptions('MediaType', 'application/json', 'ContentType', 'json', 'Timeout', 90);
if ~isempty(key), options.HeaderFields = {'Authorization', ['Bearer ' key]}; end
response = webwrite(endpoint, payload, options);
end
