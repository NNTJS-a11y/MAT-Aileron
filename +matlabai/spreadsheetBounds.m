function bounds = spreadsheetBounds(path)
% Inspect actual cell coordinates before asking readcell to allocate a grid.
[~,~,extension]=fileparts(path);
bounds=struct('name',{},'rows',{},'columns',{});
if strcmpi(extension,'.xls')
    bounds=matlabai.legacySpreadsheetBounds(path);
else
    archive=java.util.zip.ZipFile(java.io.File(path));closeArchive=onCleanup(@() archive.close());
    entries=archive.entries();expanded=0;sheetCount=0;
    extents=struct('path',{},'rows',{},'columns',{});
    while entries.hasMoreElements()
        entry=entries.nextElement();size=double(entry.getSize());expanded=expanded+size;
        if size<0 || expanded>25*1024*1024,error('MatlabAI:ExcelSize','解压大小未知或超过25MB。');end
        name=char(entry.getName());
        if isempty(regexp(name,'^xl/worksheets/[^/]+\.xml$','once')),continue;end
        sheetCount=sheetCount+1;
        if sheetCount>20,error('MatlabAI:ExcelSheets','工作簿超过20个工作表。');end
        stream=archive.getInputStream(entry);scanner=java.util.Scanner(stream,'UTF-8');
        closeScanner=onCleanup(@() scanner.close());scanner.useDelimiter('\A');
        xml='';if scanner.hasNext(),xml=char(scanner.next());end
        clear closeScanner
        % Deliberately includes formatted cells: a huge sparse sheet is rejected.
        cellTags=regexp(xml,'<(?:[A-Za-z_][\w.-]*:)?c(?=[\s/>])','start');
        if numel(cellTags)>50000,error('MatlabAI:ExcelSize','工作表单元格记录超过50,000个。');end
        cells=regexp(xml,'<(?:[A-Za-z_][\w.-]*:)?c(?=\s)[^>]*\sr\s*=\s*["'']([A-Za-z]+)([0-9]+)["'']','tokens');
        if numel(cells)~=numel(cellTags)
            error('MatlabAI:ExcelPreflight','存在无法定位的单元格，未读取部分数据。请在Excel/WPS中另存为标准XLSX。');
        end
        maxRow=1;maxColumn=1;
        for index=1:numel(cells)
            letters=upper(cells{index}{1});column=0;
            for letter=letters,column=column*26+double(letter)-64;end
            maxRow=max(maxRow,str2double(cells{index}{2}));maxColumn=max(maxColumn,column);
            check(maxRow,maxColumn);
        end
        extents(end+1)=struct('path',name,'rows',maxRow,'columns',maxColumn); %#ok<AGROW>
    end
    % Resolve workbook relationships; do not assume physical sheet file order.
    workbook=xmlDocument(archive,'xl/workbook.xml');
    relationships=xmlDocument(archive,'xl/_rels/workbook.xml.rels');
    rels=relationships.getElementsByTagNameNS('*','Relationship');
    sheets=workbook.getElementsByTagNameNS('*','sheet');
    for index=0:sheets.getLength()-1
        sheet=sheets.item(index);name=char(sheet.getAttribute('name'));
        id=char(sheet.getAttributeNS('http://schemas.openxmlformats.org/officeDocument/2006/relationships','id'));
        target='';
        for relIndex=0:rels.getLength()-1
            rel=rels.item(relIndex);
            if strcmp(char(rel.getAttribute('Id')),id),target=char(rel.getAttribute('Target'));break;end
        end
        if startsWith(target,'/'),target=target(2:end);else,target=['xl/' target];end
        match=find(strcmp({extents.path},target),1);
        if isempty(match),continue;end % Chart sheets are not data worksheets.
        bounds(end+1)=struct('name',name,'rows',extents(match).rows,'columns',extents(match).columns); %#ok<AGROW>
    end
end
if isempty(bounds),error('MatlabAI:ExcelPreflight','没有可定位的工作表，请另存为标准XLSX。');end
end
function check(rows,columns)
if rows>5000 || columns>100 || rows*columns>50000
    error('MatlabAI:ExcelSize','读取前预检发现表格范围过大（含格式单元格）：最多5000行、100列、50,000格。请删除多余行列或拆分。');
end
end

function document=xmlDocument(archive,name)
entry=archive.getEntry(name);
if isempty(entry)||entry.getSize()<0||entry.getSize()>1024*1024
    error('MatlabAI:ExcelPreflight','工作簿目录缺失或异常，请另存为标准XLSX。');
end
stream=archive.getInputStream(entry);cleanup=onCleanup(@() stream.close());
factory=javax.xml.parsers.DocumentBuilderFactory.newInstance();
factory.setFeature('http://apache.org/xml/features/disallow-doctype-decl',true);
factory.setFeature('http://xml.org/sax/features/external-general-entities',false);
factory.setFeature('http://xml.org/sax/features/external-parameter-entities',false);
factory.setNamespaceAware(true);
document=factory.newDocumentBuilder().parse(stream);
end
