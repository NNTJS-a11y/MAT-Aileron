function content = readAttachment(path)
info = dir(path);
if isempty(info) || info.isdir, error('MatlabAI:File', '附件不存在或不是文件。'); end
if info.bytes > 10 * 1024 * 1024, error('MatlabAI:FileSize', '单个附件不能超过10 MB。'); end
[~, ~, extension] = fileparts(path);
switch lower(extension)
    case {'.m', '.txt', '.md', '.csv', '.tsv', '.json'}
        content = string(fileread(path));
    case '.docx'
        content = matlabai.readWord(path);
    case '.doc'
        error('MatlabAI:LegacyWord', '旧版 .doc 请先在 Word 或 WPS 中另存为 .docx，然后添加。');
    case {'.xlsx', '.xls', '.xlsm'}
        content = matlabai.readSpreadsheet(path);
    case '.pdf'
        content = matlabai.readPDF(path);
    otherwise
        error('MatlabAI:FileType', '暂不支持此文件类型。');
end
if strlength(strtrim(content)) == 0
    error('MatlabAI:EmptyFile', '没有提取到文本，图片或扫描件请先转换为文字。');
end
if strlength(content) > 40000
    error('MatlabAI:TextSize', '附件提取文本超过40,000字符，请拆分文档或减少表格数据后添加；未自动截断。');
end
end
