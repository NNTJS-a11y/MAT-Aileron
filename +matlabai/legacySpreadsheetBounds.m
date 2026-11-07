function bounds=legacySpreadsheetBounds(path)
% Read OLE/BIFF range metadata only. No Java JARs, Excel, or cell-grid allocation.
info=dir(path);
if isempty(info)||info.bytes>10*1024*1024,error('MatlabAI:ExcelSize','XLS文件不存在或超过10MB。');end
fid=fopen(path,'rb');if fid<0,error('MatlabAI:ExcelPreflight','无法读取XLS。');end
cleanup=onCleanup(@() fclose(fid));bytes=fread(fid,Inf,'*uint8')';
if numel(bytes)<512||~isequal(bytes(1:8),uint8([208 207 17 224 161 177 26 225]))
    error('MatlabAI:ExcelPreflight','非标准OLE格式XLS，请另存为XLSX。');
end
sectorSize=2^number(bytes,30,2);miniSize=2^number(bytes,32,2);
if ~ismember(sectorSize,[512 4096])||miniSize~=64,error('MatlabAI:ExcelPreflight','不支持的XLS存储格式。');end
fatCount=number(bytes,44,4);sectorCount=floor(numel(bytes)/sectorSize)-1;
if fatCount>sectorCount,error('MatlabAI:ExcelPreflight','XLS分配表损坏。');end
ids=numbers(bytes(77:512));ids=ids(ids<4294967290);
next=number(bytes,68,4);difatCount=number(bytes,72,4);
if difatCount>sectorCount,error('MatlabAI:ExcelPreflight','XLS扩展分配表损坏。');end
seen=[];
for index=1:difatCount
    if any(seen==next),error('MatlabAI:ExcelPreflight','XLS分配表循环。');end
    seen(end+1)=next; %#ok<AGROW>
    block=sector(next);values=numbers(block);next=values(end);
    values=values(1:end-1);ids=[ids values(values<4294967290)]; %#ok<AGROW>
end
if numel(ids)<fatCount,error('MatlabAI:ExcelPreflight','XLS分配表不完整。');end
fat=[];
for index=1:fatCount,fat=[fat numbers(sector(ids(index)))];end %#ok<AGROW>
directory=readChain(number(bytes,48,4),fat,bytes,sectorSize,sectorSize,Inf);
workbook=[];root=[];
for offset=0:128:numel(directory)-128
    nameLength=number(directory,offset+64,2);type=directory(offset+67);
    if nameLength<2||nameLength>64||mod(nameLength,2)~=0,continue;end
    name=native2unicode(directory(offset+1:offset+nameLength-2),'UTF-16LE');
    entry=struct('start',number(directory,offset+116,4),'size', ...
        number(directory,offset+120,4)+number(directory,offset+124,4)*2^32);
    if type==5,root=entry;end
    if type==2&&any(strcmpi(name,{'Workbook','Book'})),workbook=entry;end
end
if isempty(workbook)||workbook.size>10*1024*1024,error('MatlabAI:ExcelPreflight','XLS工作簿流无效。');end
if workbook.size<number(bytes,56,4)
    if isempty(root),error('MatlabAI:ExcelPreflight','XLS微型流缺失。');end
    miniFAT=numbers(readChain(number(bytes,60,4),fat,bytes,sectorSize,sectorSize,Inf));
    miniStream=readChain(root.start,fat,bytes,sectorSize,sectorSize,root.size);
    book=readChain(workbook.start,miniFAT,miniStream,miniSize,0,workbook.size);
else
    book=readChain(workbook.start,fat,bytes,sectorSize,sectorSize,workbook.size);
end
bounds=struct('name',{},'rows',{},'columns',{});sheets=struct('name',{},'offset',{});
offset=0;
while offset+4<=numel(book)
    id=number(book,offset,2);length=number(book,offset+2,2);first=offset+4;
    if first+length>numel(book),error('MatlabAI:ExcelPreflight','XLS记录不完整。');end
    if id==47,error('MatlabAI:ExcelPreflight','不支持加密XLS。');end
    if id==133&&length>=8&&book(first+6)==0
        count=double(book(first+7));wide=bitand(book(first+8),1)~=0;
        if 8+count*(1+wide)>length,error('MatlabAI:ExcelPreflight','XLS工作表名称异常。');end
        raw=book(first+9:first+8+count*(1+wide));
        if wide,name=native2unicode(raw,'UTF-16LE');else,name=char(raw);end
        sheets(end+1)=struct('name',name,'offset',number(book,first,4)); %#ok<AGROW>
    end
    offset=first+length;
    if id==10,break;end
end
if isempty(sheets)||numel(sheets)>20,error('MatlabAI:ExcelSheets','XLS工作表数量不支持。');end
for index=1:numel(sheets)
    offset=sheets(index).offset;found=false;rows=1;columns=1;
    while offset+4<=numel(book)
        id=number(book,offset,2);length=number(book,offset+2,2);first=offset+4;
        if first+length>numel(book),error('MatlabAI:ExcelPreflight','XLS工作表记录损坏。');end
        if id==512
            if length>=14,rows=max(rows,number(book,first+4,4));columns=max(columns,number(book,first+10,2));
            elseif length>=10,rows=max(rows,number(book,first+2,2));columns=max(columns,number(book,first+6,2));
            else,error('MatlabAI:ExcelPreflight','XLS范围记录无效。');end
            rows=max(1,rows);columns=max(1,columns);
            if rows>5000||columns>100||rows*columns>50000,error('MatlabAI:ExcelSize','XLS预检范围超过5000行、100列或50,000格。');end
            found=true;
        elseif ismember(id,[6 513 515 516 517 638 189 190 253 214 520])&&length>=6
            % Check actual cells/ROW too; a damaged DIMENSIONS record may lie.
            rows=max(rows,number(book,first,2)+1);
            columns=max(columns,number(book,first+2,2)+1);
            if ismember(id,[189 190]),columns=max(columns,number(book,first+length-2,2)+1);end
            if id==520,columns=max(columns,number(book,first+4,2));end
        end
        if rows>5000||columns>100||rows*columns>50000
            error('MatlabAI:ExcelSize','XLS实际单元格或格式范围超限。');
        end
        offset=first+length;if id==10,break;end
    end
    if ~found,error('MatlabAI:ExcelPreflight','XLS范围缺失，请另存为XLSX。');end
    bounds(end+1)=struct('name',sheets(index).name,'rows',rows,'columns',columns); %#ok<AGROW>
end
    function value=sector(id)
        first=(id+1)*sectorSize;
        if id<0||id>=sectorCount||first+sectorSize>numel(bytes),error('MatlabAI:ExcelPreflight','XLS扇区越界。');end
        value=bytes(first+1:first+sectorSize);
    end
end
function value=number(bytes,offset,count)
if offset<0||offset+count>numel(bytes),error('MatlabAI:ExcelPreflight','XLS字段越界。');end
value=sum(double(bytes(offset+1:offset+count)).*256.^(0:count-1));
end
function value=numbers(bytes)
if mod(numel(bytes),4)~=0,error('MatlabAI:ExcelPreflight','XLS分配表长度无效。');end
value=double(reshape(bytes,4,[]));value=sum(value.*(256.^(0:3))',1);
end
function value=readChain(id,fat,source,size,base,wanted)
parts={};seen=false(1,numel(fat));total=0;
while id~=4294967294
    if id<0||id>=numel(fat)||seen(id+1),error('MatlabAI:ExcelPreflight','XLS流越界或循环。');end
    seen(id+1)=true;first=base+id*size;
    if first+size>numel(source),error('MatlabAI:ExcelPreflight','XLS流不完整。');end
    parts{end+1}=source(first+1:first+size);total=total+size; %#ok<AGROW>
    if total>12*1024*1024,error('MatlabAI:ExcelSize','XLS元数据流过大。');end
    id=fat(id+1);
end
value=[parts{:}];
if isfinite(wanted)
    if wanted>numel(value),error('MatlabAI:ExcelPreflight','XLS流长度不完整。');end
    value=value(1:wanted);
end
end
