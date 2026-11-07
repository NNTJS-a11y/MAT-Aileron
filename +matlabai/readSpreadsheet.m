function content = readSpreadsheet(path)
bounds=matlabai.spreadsheetBounds(path);
[~, ~, extension] = fileparts(path);
if ~strcmpi(extension, '.xls')
    archive = java.util.zip.ZipFile(java.io.File(path));
    cleanup = onCleanup(@() archive.close());
    entries = archive.entries();
    expandedBytes = 0;
    while entries.hasMoreElements()
        entry = entries.nextElement();
        if entry.getSize() < 0, error('MatlabAI:ExcelSize', '工作簿解压大小未知，无法安全读取。'); end
        expandedBytes = expandedBytes + double(entry.getSize());
        if expandedBytes > 25 * 1024 * 1024, error('MatlabAI:ExcelSize', '工作簿解压后超过25 MB，请精简后添加。'); end
    end
    clear cleanup
end
sheets = sheetnames(path);
if numel(sheets) > 20, error('MatlabAI:ExcelSheets', '工作簿超过20个工作表，请拆分后添加。'); end
parts = strings(numel(sheets), 1);
totalCharacters = 0;
hasData = false;
for sheetIndex = 1:numel(sheets)
    match=find(strcmp({bounds.name},char(sheets(sheetIndex))),1);
    if isempty(match),error('MatlabAI:ExcelPreflight','工作表无法预检，未读取部分内容。');end
    extent=bounds(match);column=extent.columns;letters='';
    while column>0
        letters=[char(65+mod(column-1,26)) letters]; %#ok<AGROW>
        column=floor((column-1)/26);
    end
    range=sprintf('A1:%s%d',letters,extent.rows);
    data = readcell(path, 'Sheet', sheets(sheetIndex), 'Range', range, 'UseExcel', false);
    [rows, columns] = size(data);
    if numel(data) > 50000 || rows > 5000 || columns > 100
        error('MatlabAI:ExcelSize', '工作表“%s”过大；每表最多5000行、100列、50,000个单元格，请拆分。', sheets(sheetIndex));
    end
    lines = strings(rows + 2, 1);
    lines(1) = sprintf('[Excel 工作表：%s；范围含%d行、%d列]', sheets(sheetIndex), rows, columns);
    lines(2) = strjoin(["行号", compose('列%d', 1:columns)], sprintf('\t'));
    for rowIndex = 1:rows
        values = strings(1, columns);
        for columnIndex = 1:columns
            value = data{rowIndex, columnIndex};
            if isempty(value) || (isscalar(value) && ismissing(value)), continue; end
            value = string(value);
            values(columnIndex) = replace(replace(replace(join(value(:), ', '), sprintf('\r'), ''), newline, '\n'), sprintf('\t'), '\t');
        end
        hasData = hasData || any(strlength(values) > 0);
        lines(rowIndex + 2) = strjoin([string(rowIndex), values], sprintf('\t'));
        totalCharacters = totalCharacters + strlength(lines(rowIndex + 2)) + 1;
        if totalCharacters > 40000, error('MatlabAI:TextSize', 'Excel 提取文本超过40,000字符，请减少数据后添加；未自动截断。'); end
    end
    parts(sheetIndex) = strjoin(lines, newline);
    totalCharacters = totalCharacters + strlength(lines(1)) + strlength(lines(2)) + 2;
end
if ~hasData, error('MatlabAI:EmptyFile', '工作簿没有可读取的数据。'); end
content = "[Excel：读取各表已有单元格值，不执行宏、不重算公式；空字段表示空单元格。]" + newline + strjoin(parts, newline + string(newline));
end
