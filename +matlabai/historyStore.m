function value=historyStore(action,value)
% Separate text-only records and a small searchable index. No code is loaded.
folder=matlabai.dataRoot('history');indexPath=fullfile(folder,'index.json');
index=struct('id',{},'title',{},'created',{},'search',{});
if isfile(indexPath)
    index=readJSON(indexPath,8*1024*1024);
    if isempty(index),index=struct('id',{},'title',{},'created',{},'search',{});end
    if ~isstruct(index)||~all(isfield(index,{'id','title','created','search'}))||numel(index)>2000
        error('MatlabAI:HistoryFormat','历史索引损坏，未加载。');
    end
    index=reshape(index,1,[]);
    for k=1:numel(index)
        validateId(index(k).id);
        if ~ischar(index(k).title)||~ischar(index(k).created)||~ischar(index(k).search)
            error('MatlabAI:HistoryFormat','历史索引字段无效。');
        end
    end
end
switch action
    case 'list',value=index;
    case 'get'
        validateId(value);file=fullfile(folder,[value '.json']);
        value=readJSON(file,12*1024*1024);validateRecord(value);
    case 'put'
        validateRecord(value);
        entry=struct('id',value.id,'title',value.title,'created',value.created, ...
            'search',[value.prompt newline value.answer(1:min(end,2000))]);
        entry.search=entry.search(1:min(end,1000));
        match=find(strcmp({index.id},value.id));index(match)=[];
        if numel(index)>=2000,error('MatlabAI:HistoryCapacity','历史已达2000条，请导出并整理历史目录。');end
        writeJSON(fullfile(folder,[value.id '.json']),value,12*1024*1024);
        index=[entry index];writeJSON(indexPath,index,8*1024*1024);
    case 'delete'
        validateId(value);file=fullfile(folder,[value '.json']);
        index(strcmp({index.id},value))=[];writeJSON(indexPath,index,8*1024*1024);
        if isfile(file),delete(file);end
    case 'clear'
        records=dir(fullfile(folder,'h_*.json'));
        for k=1:numel(records)
            [~,id]=fileparts(records(k).name);validateId(id);
            file=fullfile(folder,records(k).name);delete(file);
        end
        if isfile(indexPath),delete(indexPath);end
        value=[];
    otherwise,error('MatlabAI:HistoryAction','未知历史操作。');
end
end
function validateRecord(record)
fields={'id','title','created','prompt','answer','code','mode','target','feedback','attachments'};
if ~isstruct(record)||~isscalar(record)||~all(isfield(record,fields)),error('MatlabAI:HistoryFormat','历史记录字段不完整。');end
validateId(record.id);
for name=fields(2:end-1)
    if ~ischar(record.(name{1})),error('MatlabAI:HistoryFormat','历史文字字段无效。');end
end
files=record.attachments;
if isempty(files),return;end
if ~isstruct(files)||~all(isfield(files,{'name','text'}))||numel(files)>10,error('MatlabAI:HistoryFormat','历史附件无效。');end
for k=1:numel(files)
    if ~ischar(files(k).name)||~ischar(files(k).text)||numel(files(k).text)>40000,error('MatlabAI:HistoryFormat','历史附件文字无效。');end
end
end
function validateId(id)
if ~ischar(id)||isempty(regexp(id,'^h_[A-Za-z0-9_]{1,80}$','once')),error('MatlabAI:HistoryId','历史标识无效。');end
end
function value=readJSON(file,limit)
info=dir(file);if isempty(info)||info.bytes>limit,error('MatlabAI:HistoryFormat','历史文件不存在或过大。');end
value=jsondecode(fileread(file));
end
function writeJSON(file,value,limit)
raw=jsonencode(value);
if numel(unicode2native(raw,'UTF-8'))>limit,error('MatlabAI:HistorySize','历史记录过大，未保存。');end
temp=[tempname(fileparts(file)) '.json'];cleanup=onCleanup(@() discard(temp));
fid=fopen(temp,'w','n','UTF-8');if fid<0,error('MatlabAI:HistoryWrite','历史无法写入。');end
close=onCleanup(@() fclose(fid));fprintf(fid,'%s',raw);clear close
[ok,message]=movefile(temp,file,'f');if ~ok,error('MatlabAI:HistoryWrite','%s',message);end
end
function discard(file)
if isfile(file),delete(file);end
end
