function result = buildModel(plan, folder, showModel)
if nargin < 3, showModel = true; end
plan = matlabai.validatePlan(plan);
if isempty(ver('simulink')) || ~license('test', 'Simulink')
    error('MatlabAI:Simulink', '需要安装并授权 Simulink。');
end
if ~isfolder(folder), mkdir(folder); end
[~, token] = fileparts(tempname(folder));
model = matlab.lang.makeValidName(['ai_' token]);
while bdIsLoaded(model) || exist(model, 'file')
    [~, token] = fileparts(tempname(folder));
    model = matlab.lang.makeValidName(['ai_' token]);
end
catalog = matlabai.blockCatalog;
matlabai.checkBlockCompatibility(plan);
new_system(model);
try
    set_param(model, 'StopTime', num2str(plan.stopTime, 17), 'Solver', 'ode45', ...
        'MaxStep', num2str(min(0.05, plan.stopTime / 100), 17), 'ReturnWorkspaceOutputs', 'on');
    for index = 1:numel(plan.blocks)
        block = plan.blocks{index};
        position = [80 + mod(index-1, 5)*160, 80 + floor((index-1)/5)*130, ...
            160 + mod(index-1, 5)*160, 130 + floor((index-1)/5)*130];
        path = [model '/' char(block.id)];
        add_block(catalog.(char(block.type)).path, path, 'Position', position);
        if strcmp(block.type, 'Sum'), set_param(path, 'Inputs', '++'); end
        if strcmp(block.type, 'PID'), set_param(path, 'Controller', 'PID', 'Form', 'Parallel'); end
        names = fieldnames(block.parameters);
        for parameterIndex = 1:numel(names)
            value = block.parameters.(names{parameterIndex});
            if isnumeric(value), value = mat2str(value, 17); else, value = char(value); end
            set_param(path, names{parameterIndex}, value);
        end
    end
    for index = 1:numel(plan.connections)
        connection = plan.connections{index};
        add_line(model, sprintf('%s/%d', connection.from, connection.fromPort), ...
            sprintf('%s/%d', connection.to, connection.toPort), 'autorouting', 'on');
    end
    add_block('simulink/Sinks/To Workspace', [model '/AI_Output'], ...
        'VariableName', 'ai_signal', 'SaveFormat', 'Timeseries', 'MaxDataPoints', '100000', ...
        'Position', [950 80 1050 120]);
    add_line(model, [char(plan.output) '/1'], 'AI_Output/1', 'autorouting', 'on');
    % Layout is cosmetic; keep a valid model if an older layout engine fails.
    try
        Simulink.BlockDiagram.arrangeSystem(model);
    catch problem
        warning('MatlabAI:Layout', '自动布局未完成，保留基础布局：%s', problem.message);
    end
    set_param(model, 'SimulationCommand', 'update');
    modelPath = fullfile(folder, [model '.slx']);
    save_system(model, modelPath);
    planPath = fullfile(folder, [model '.json']);
    file = fopen(planPath, 'w', 'n', 'UTF-8');
    if file < 0, error('MatlabAI:SavePlan', '无法保存建模方案。'); end
    cleanup = onCleanup(@() fclose(file));
    fprintf(file, '%s', jsonencode(plan, 'PrettyPrint', true));
    clear cleanup
    if showModel, open_system(model); end
    result = struct('model', model, 'path', modelPath, 'folder', folder, 'plan', plan);
catch problem
    close_system(model, 0);
    rethrow(problem);
end
end
