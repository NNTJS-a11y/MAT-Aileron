function profile=providerProfile(value)
% Public provider defaults, not a user's saved configuration.
value=char(value);
if isempty(value),value='custom';end
if startsWith(value,'https://')||startsWith(value,'http://')
    if ~isempty(regexp(value,'^https://api\.deepseek\.com/','once')),value='deepseek';
    elseif ~isempty(regexp(value,'^https://ark\.cn-beijing\.volces\.com/','once')),value='doubao';
    elseif ~isempty(regexp(value,'^https://api\.openai\.com/','once')),value='openai';
    else,value='custom';end
end
profile=struct('id',value,'endpoint','','model','','keyEnvironment','');
switch value
    case 'deepseek'
        profile.endpoint='https://api.deepseek.com/chat/completions';
        profile.model='deepseek-flash';
        profile.keyEnvironment='DEEPSEEK_API_KEY';
    case 'doubao'
        profile.endpoint='https://ark.cn-beijing.volces.com/api/v3/chat/completions';
        % User must choose a model or inference endpoint enabled in their Ark account.
        profile.keyEnvironment='ARK_API_KEY';
    case 'openai'
        profile.endpoint='https://api.openai.com/v1/chat/completions';
        profile.keyEnvironment='OPENAI_API_KEY';
    case 'custom'
    otherwise
        error('MatlabAI:Provider','Unknown API provider.');
end
end
