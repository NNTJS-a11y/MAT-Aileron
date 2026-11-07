function report = checkBlockCompatibility(plan)
% Read public metadata before creating any model or setting parameters.
catalog = matlabai.blockCatalog;
load_system('simulink');
report = struct('type', {}, 'path', {}, 'parameters', {});
for index = 1:numel(plan.blocks)
    block = plan.blocks{index};
    type = char(block.type);
    path = catalog.(type).path;
    try
        object = get_param(path, 'ObjectParameters');
        dialog = get_param(path, 'DialogParameters');
    catch problem
        error('MatlabAI:MissingBlock', '当前 MATLAB 无法加载模块 %s (%s)：%s', type, path, problem.message);
    end
    names = fieldnames(block.parameters);
    if strcmp(type, 'Sum'), names = [names; {'Inputs'}]; end
    if strcmp(type, 'PID'), names = [names; {'Controller'; 'Form'}]; end
    available = union(fieldnames(object), fieldnames(dialog));
    missing = setdiff(names, available);
    if ~isempty(missing)
        error('MatlabAI:BlockCompatibility', '当前版本模块 %s 不提供参数 %s。请将此错误交给助手调整方案。', type, strjoin(missing, ', '));
    end
    report(end+1) = struct('type', type, 'path', path, 'parameters', {names}); %#ok<AGROW>
end
end
