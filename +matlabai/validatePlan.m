function plan = validatePlan(plan)
require(isstruct(plan) && isscalar(plan), '方案必须是一个 JSON 对象。');
required = {'description', 'stopTime', 'blocks', 'connections', 'output'};
require(all(isfield(plan, required)), '方案缺少 description、stopTime、blocks、connections 或 output。');
require(isText(plan.description) && strlength(string(plan.description)) <= 4000, 'description 必须是简短文字。');
require(isnumeric(plan.stopTime) && isscalar(plan.stopTime) && isfinite(plan.stopTime) && ...
    plan.stopTime > 0 && plan.stopTime <= 3600, '仿真时长必须在 0 到 3600 秒之间。');
plan.blocks = cells(plan.blocks);
plan.connections = cells(plan.connections);
require(~isempty(plan.blocks) && numel(plan.blocks) <= 40, '模块数量必须在 1 到 40 之间。');
require(~isempty(plan.connections) && numel(plan.connections) <= 100, '连接数量必须在 1 到 100 之间。');
catalog = matlabai.blockCatalog;
ids = cell(1, numel(plan.blocks));
for index = 1:numel(plan.blocks)
    block = plan.blocks{index};
    require(isstruct(block) && isscalar(block) && all(isfield(block, {'id', 'type', 'parameters'})), '模块必须包含 id、type 和 parameters。');
    require(isText(block.id) && ~isempty(regexp(char(block.id), '^[A-Za-z][A-Za-z0-9_]{0,39}$', 'once')), '模块 id 只能使用英文字母、数字、下划线，且以字母开头。');
    require(~strcmpi(block.id, 'AI_Output'), 'AI_Output 为保留名称。');
    require(isText(block.type) && isfield(catalog, char(block.type)), '模块类型不在当前支持列表中。');
    require(isstruct(block.parameters) && isscalar(block.parameters), 'parameters 必须是 JSON 对象。');
    specification = catalog.(char(block.type)).parameters;
    names = fieldnames(block.parameters);
    for parameterIndex = 1:numel(names)
        name = names{parameterIndex};
        require(isfield(specification, name), ['不支持的参数：' char(block.type) '.' name]);
        value = block.parameters.(name);
        switch specification.(name)
            case 'scalar'
                require(isnumeric(value) && isreal(value) && isscalar(value) && isfinite(value), [name ' 必须是有限实数，不能是表达式。']);
            case 'vector'
                require(isnumeric(value) && isreal(value) && isvector(value) && ~isempty(value) && numel(value) <= 20 && all(isfinite(value)), [name ' 必须是有限实数数组，最多20个元素。']);
                if strcmp(name, 'Denominator'), require(any(value ~= 0), '传递函数分母不能全为零。'); end
                block.parameters.(name) = reshape(value, 1, []);
            case 'signs'
                require(isText(value) && ~isempty(regexp(char(value), '^[+-]{1,8}$', 'once')), 'Sum.Inputs 只能包含1到8个加减号。');
        end
    end
    ids{index} = char(block.id);
    plan.blocks{index} = block;
end
require(numel(unique(lower(string(ids)))) == numel(ids), '模块 id 不能重复（忽略大小写）。');
destinations = cell(1, numel(plan.connections));
for index = 1:numel(plan.connections)
    connection = plan.connections{index};
    require(isstruct(connection) && isscalar(connection) && all(isfield(connection, {'from', 'fromPort', 'to', 'toPort'})), '连接必须包含 from、fromPort、to 和 toPort。');
    require(isText(connection.from) && isText(connection.to), '连接端点必须是模块 id。');
    source = find(strcmp(ids, connection.from), 1);
    target = find(strcmp(ids, connection.to), 1);
    require(~isempty(source) && ~isempty(target), '连接引用了不存在的模块。');
    require(validPort(connection.fromPort) && connection.fromPort == 1 && ~strcmp(plan.blocks{source}.type, 'Scope'), '来源端口无效。');
    inputCount = numberInputs(plan.blocks{target});
    require(validPort(connection.toPort) && connection.toPort <= inputCount, '目标端口无效。');
    destination = sprintf('%s/%d', connection.to, connection.toPort);
    require(~any(strcmp(destinations, destination)), '同一个输入端口不能连接两次。');
    destinations{index} = destination;
end
for index = 1:numel(plan.blocks)
    for port = 1:numberInputs(plan.blocks{index})
        require(any(strcmp(destinations, sprintf('%s/%d', ids{index}, port))), ...
            sprintf('模块 %s 的输入端口 %d 没有连接。', ids{index}, port));
    end
end
require(isText(plan.output) && any(strcmp(ids, plan.output)), 'output 必须是现有模块的 id。');
outputIndex = find(strcmp(ids, plan.output), 1);
require(~strcmp(plan.blocks{outputIndex}.type, 'Scope'), 'output 必须选择有输出端口的模块，不能选择 Scope。');
end

function count = numberInputs(block)
count = 1;
if any(strcmp(block.type, {'Step','Constant','Sine'})), count = 0; end
if strcmp(block.type, 'Sum')
    count = 2;
    if isfield(block.parameters, 'Inputs'), count = numel(char(block.parameters.Inputs)); end
end
end

function result = isText(value)
result = (ischar(value) && isrow(value)) || (isstring(value) && isscalar(value) && ~ismissing(value));
end

function result = validPort(value)
result = isnumeric(value) && isscalar(value) && isfinite(value) && value >= 1 && value == fix(value);
end

function value = cells(value)
if isstruct(value), value = num2cell(value); end
require(iscell(value) && isvector(value), 'blocks 和 connections 必须是对象数组。');
value = reshape(value, 1, []);
end

function require(condition, message)
if ~condition, error('MatlabAI:Plan', '%s', message); end
end
