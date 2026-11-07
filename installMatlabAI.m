function installMatlabAI(folder)
root = fileparts(mfilename('fullpath'));
if nargin<1
    folders = strsplit(userpath, pathsep);
    folder = folders{1};
end
if isempty(folder)
    error('MatlabAI:Userpath', 'MATLAB userpath 为空，请先设置 userpath。');
end
if ~isfolder(folder), mkdir(folder); end
startup = fullfile(folder, 'startup.m');
existing = '';
if isfile(startup), existing = fileread(startup); end
marker = '% BEGIN MATLAB_AI_ASSISTANT';
escapedRoot = strrep(root, '''', '''''');
block = sprintf(['%s\n%% Register the Aileron command only; never launch the assistant here.\ntry\n    addpath(''%s'');\n' ...
    'catch matlabAIStartupError\n    warning(''MatlabAI:Startup'', ''%%s'', matlabAIStartupError.message);\nend\n' ...
    '%% END MATLAB_AI_ASSISTANT\n'], marker, escapedRoot);
if contains(existing, marker)
    pattern = '(?m)^% BEGIN MATLAB_AI_ASSISTANT\r?\n[\s\S]*?^% END MATLAB_AI_ASSISTANT\r?\n?';
    [first, last] = regexp(existing, pattern, 'start', 'end');
    if isempty(first)||numel(strfind(existing,marker))~=numel(first)
        error('MatlabAI:StartupBlock', '启动块不完整，请先检查 startup.m。');
    end
    updated=existing;
    for index=numel(first):-1:1
        replacement='';if index==1,replacement=block;end
        updated=[updated(1:first(index)-1),replacement,updated(last(index)+1:end)];
    end
else
    updated = [existing, newline, block];
end
if ~strcmp(existing, updated)
    if isfile(startup)
        backup = [startup '.matlab-ai-' char(datetime('now', 'Format', 'yyyyMMddHHmmssSSS')) '.bak'];
        copyfile(startup, backup);
    end
    file = fopen(startup, 'w', 'n', 'UTF-8');
    if file < 0, error('MatlabAI:Install', '无法写入 %s', startup); end
    closeFile = onCleanup(@() fclose(file));
    fprintf(file, '%s', updated);
    clear closeFile
end
addpath(root);
fprintf('已注册 Aileron 命令：%s\n打开 MATLAB 不会自动打开助手，需要时输入 Aileron。\n', startup);
end
