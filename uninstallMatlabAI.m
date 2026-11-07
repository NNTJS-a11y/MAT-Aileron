function uninstallMatlabAI
folders = strsplit(userpath, pathsep);
startup = fullfile(folders{1}, 'startup.m');
if ~isfile(startup), return; end
existing = fileread(startup);
updated = regexprep(existing, '(?m)^% BEGIN MATLAB_AI_ASSISTANT\r?\n[\s\S]*?^% END MATLAB_AI_ASSISTANT\r?\n?', '');
if strcmp(existing, updated), return; end
copyfile(startup, [startup '.before-uninstall-' char(datetime('now', 'Format', 'yyyyMMddHHmmssSSS')) '.bak']);
file = fopen(startup, 'w', 'n', 'UTF-8');
if file < 0, error('MatlabAI:Uninstall', '无法写入启动脚本。'); end
closeFile = onCleanup(@() fclose(file));
fprintf(file, '%s', updated);
fprintf('已移除 Aileron 命令的自动路径注册，下次启动生效。\n');
end
