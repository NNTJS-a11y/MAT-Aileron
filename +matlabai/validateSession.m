function session=validateSession(session)
required={'history','attachments','prompt','code','transcript','mode','target','method','methodState','feedback','snapshot'};
if ~isstruct(session) || ~isscalar(session) || ~all(isfield(session,required))
    error('MatlabAI:SessionFormat','会话字段不完整。');
end
for name={'prompt','code','transcript','method','methodState','feedback','snapshot','mode','target'}
    value=session.(name{1});
    if ~(ischar(value) && (isrow(value)||isempty(value))) && ~(isstring(value)&&isscalar(value))
        error('MatlabAI:SessionFormat','会话文字字段无效。');
    end
    session.(name{1})=char(value);
end
history=session.history;
if isempty(history),history={};elseif isstruct(history),history=num2cell(history);end
if ~iscell(history) || mod(numel(history),2)~=0 || numel(history)>1000
    error('MatlabAI:SessionFormat','历史消息结构无效。');
end
for index=1:numel(history)
    item=history{index};role='user';if mod(index,2)==0,role='assistant';end
    if ~isstruct(item)||~isscalar(item)||~all(isfield(item,{'role','content'}))||~strcmp(item.role,role)||~ischar(item.content)
        error('MatlabAI:SessionFormat','历史消息格式无效。');
    end
end
session.history=reshape(history,1,[]);
files=session.attachments;
if isempty(files),files=struct('name',{},'text',{});end
if ~isstruct(files)||numel(files)>10||~all(isfield(files,{'name','text'}))
    error('MatlabAI:SessionFormat','附件结构无效。');
end
total=0;
for index=1:numel(files)
    if ~ischar(files(index).name)||~ischar(files(index).text)||numel(files(index).text)>40000
        error('MatlabAI:SessionFormat','附件文字无效。');
    end
    total=total+numel(files(index).text);
end
if total>80000,error('MatlabAI:SessionFormat','附件文字超限。');end
session.attachments=reshape(files,1,[]);
end
