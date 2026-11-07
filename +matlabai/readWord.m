function content = readWord(path)
archive = java.util.zip.ZipFile(java.io.File(path));
closeArchive = onCleanup(@() archive.close());
entry = archive.getEntry('word/document.xml');
if isempty(entry), error('MatlabAI:Docx', 'DOCX 缺少正文。'); end
if entry.getSize() > 5 * 1024 * 1024 || entry.getSize() < 0
    error('MatlabAI:DocxSize', 'DOCX 正文过大或大小未知，请拆分文档。');
end
stream = archive.getInputStream(entry);
closeStream = onCleanup(@() stream.close());
factory = javax.xml.parsers.DocumentBuilderFactory.newInstance();
factory.setFeature('http://apache.org/xml/features/disallow-doctype-decl', true);
factory.setFeature('http://xml.org/sax/features/external-general-entities', false);
factory.setFeature('http://xml.org/sax/features/external-parameter-entities', false);
factory.setNamespaceAware(true);
document = factory.newDocumentBuilder().parse(stream);
bodies = document.getElementsByTagNameNS('http://schemas.openxmlformats.org/wordprocessingml/2006/main', 'body');
if bodies.getLength() == 0, error('MatlabAI:Docx', 'DOCX 没有正文区域。'); end
children = bodies.item(0).getChildNodes();
parts = strings(children.getLength(), 1);
for index = 1:children.getLength()
    node = children.item(index - 1);
    name = char(node.getLocalName());
    if strcmp(name, 'tbl')
        parts(index) = tableText(node);
    elseif strcmp(name, 'p') || strcmp(name, 'sdt')
        parts(index) = nodeText(node);
    end
end
content = strjoin(parts(strlength(strtrim(parts)) > 0), newline);
end

function text = tableText(node)
rows = node.getChildNodes();
lines = strings(rows.getLength(), 1);
for rowIndex = 1:rows.getLength()
    row = rows.item(rowIndex - 1);
    if ~strcmp(char(row.getLocalName()), 'tr'), continue; end
    children = row.getChildNodes();
    cells = strings(children.getLength(), 1);
    count = 0;
    for cellIndex = 1:children.getLength()
        cellNode = children.item(cellIndex - 1);
        if ~strcmp(char(cellNode.getLocalName()), 'tc'), continue; end
        count = count + 1;
        cells(count) = replace(strtrim(nodeText(cellNode)), newline, ' / ');
    end
    lines(rowIndex) = strjoin(cells(1:count), sprintf('\t'));
end
text = "[Word 表格：各列以制表符分隔]" + newline + strjoin(lines(strlength(lines) > 0), newline);
end

function text = nodeText(node)
name = char(node.getLocalName());
if strcmp(name, 't')
    text = string(char(node.getTextContent()));
    return;
end
if strcmp(name, 'tab'), text = string(sprintf('\t')); return; end
if any(strcmp(name, {'br', 'cr'})), text = string(newline); return; end
children = node.getChildNodes();
parts = strings(children.getLength(), 1);
for index = 1:children.getLength()
    parts(index) = nodeText(children.item(index - 1));
end
text = join(parts, '');
if strcmp(name, 'p'), text = text + newline; end
end
