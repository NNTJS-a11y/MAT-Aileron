function content = readPDF(path)
try
    document = javaMethod('load', 'org.apache.pdfbox.pdmodel.PDDocument', java.io.File(path));
catch problem
    % PDFBox 3 moved load() from PDDocument to Loader.
    try
        document = javaMethod('loadPDF', 'org.apache.pdfbox.Loader', java.io.File(path));
    catch loaderProblem
        if exist('extractFileText', 'file') == 2
            content = string(extractFileText(path));
            if strlength(strtrim(content)) == 0
                error('MatlabAI:PDFScan', 'PDF 没有可提取文字，请先进行 OCR。');
            end
            if strlength(content) > 40000
                error('MatlabAI:TextSize', 'PDF 提取文本超过40,000字符，请拆分后添加。');
            end
            return;
        end
        error('MatlabAI:PDF', '无法打开 PDF，可能加密、损坏或缺少解析接口。PDFBox 2：%s；PDFBox 3：%s', problem.message, loaderProblem.message);
    end
end
closeDocument = onCleanup(@() document.close());
if ~document.getCurrentAccessPermission().canExtractContent()
    error('MatlabAI:PDFPermission', '此 PDF 不允许提取文本，请使用有权限的未加密副本。');
end
pages = document.getNumberOfPages();
if pages > 200, error('MatlabAI:PDFPages', 'PDF 超过200页，请拆分后添加。'); end
stripper = javaObject('org.apache.pdfbox.text.PDFTextStripper');
stripper.setSortByPosition(true);
parts = strings(pages, 1);
totalCharacters = 0;
hasText = false;
for index = 1:pages
    stripper.setStartPage(index);
    stripper.setEndPage(index);
    pageText = strtrim(string(char(stripper.getText(document))));
    hasText = hasText || strlength(pageText) > 0;
    parts(index) = string(sprintf('[PDF 第%d页]', index)) + newline + pageText;
    totalCharacters = totalCharacters + strlength(parts(index)) + 1;
    if totalCharacters > 40000
        error('MatlabAI:TextSize', 'PDF 提取文本超过40,000字符，请拆分后添加；未自动截断。');
    end
end
if ~hasText
    error('MatlabAI:PDFScan', 'PDF 没有可提取文字，可能是扫描件或图片，请先在 Word/WPS 等工具中进行 OCR。');
end
content = strjoin(parts, newline);
end
