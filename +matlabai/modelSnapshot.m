function text = modelSnapshot
if isempty(ver('simulink')), error('MatlabAI:Simulink', '没有安装 Simulink。'); end
model = bdroot;
if isempty(model) || isequal(model, 0) || strcmp(get_param(model, 'BlockDiagramType'), 'library')
    error('MatlabAI:Model', '请先打开一个 Simulink 模型。');
end
paths = find_system(model, 'SearchDepth', 1, 'Type', 'Block');
if numel(paths) > 80, error('MatlabAI:ModelSize', '当前顶层模型超过80个模块，请先选择一个较小模型。'); end
catalog = matlabai.blockCatalog;
load_system('simulink');
types = fieldnames(catalog);
blocks = cell(1, numel(paths));
for index = 1:numel(paths)
    path = paths{index};
    reference = get_param(path, 'ReferenceBlock');
    type = get_param(path, 'BlockType');
    parameters = struct;
    for typeIndex = 1:numel(types)
        entry = catalog.(types{typeIndex});
        if strcmp(reference, entry.path) || strcmp(type, get_param(entry.path, 'BlockType'))
            names = fieldnames(entry.parameters);
            for parameterIndex = 1:numel(names)
                try
                    parameters.(names{parameterIndex}) = get_param(path, names{parameterIndex});
                catch
                end
            end
            break;
        end
    end
    blocks{index} = struct('path', path, 'blockType', type, 'reference', reference, ...
        'parameters', parameters, 'ports', get_param(path, 'Ports'));
end
lineHandles = find_system(model, 'FindAll', 'on', 'SearchDepth', 1, 'Type', 'line');
targetsByLine = arrayfun(@(line) get_param(line, 'DstPortHandle'), lineHandles, 'UniformOutput', false);
connections = cell(1, sum(cellfun(@numel, targetsByLine)));
connectionCount = 0;
for index = 1:numel(lineHandles)
    source = get_param(lineHandles(index), 'SrcPortHandle');
    targets = targetsByLine{index};
    if source <= 0, continue; end
    for targetIndex = 1:numel(targets)
        if targets(targetIndex) <= 0, continue; end
        connectionCount = connectionCount + 1;
        connections{connectionCount} = struct('from', get_param(source, 'Parent'), ...
            'fromPort', get_param(source, 'PortNumber'), ...
            'to', get_param(targets(targetIndex), 'Parent'), ...
            'toPort', get_param(targets(targetIndex), 'PortNumber'));
    end
end
connections = connections(1:connectionCount);
snapshot = struct('model', model, 'stopTime', get_param(model, 'StopTime'), ...
    'solver', get_param(model, 'Solver'), 'blocks', {blocks}, 'connections', {connections}, ...
    'note', '只读取顶层结构，不包含子系统内部；重新生成时创建新模型，不原地修改。');
text = jsonencode(snapshot);
if numel(text) > 40000, error('MatlabAI:ModelSize', '模型快照超过40,000字符，请缩小模型。'); end
end
