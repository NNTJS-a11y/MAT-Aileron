function value = sessionStore(action, value)
% JSON only: no credentials, executable MAT objects, or automatic code execution.
folder=matlabai.dataRoot('sessions');file=fullfile(folder,'latest.json');
switch action
    case 'save'
        value.schema=1;
        raw=jsonencode(value);
        if numel(unicode2native(raw,'UTF-8'))>12*1024*1024,error('MatlabAI:SessionSize','会话大于12MB，未保存。');end
        temporary=[tempname(folder) '.json'];
        cleanup=onCleanup(@() removeTemporary(temporary));
        fid=fopen(temporary,'w','n','UTF-8');
        if fid<0,error('MatlabAI:SessionWrite','无法保存会话。');end
        closeFile=onCleanup(@() fclose(fid));fprintf(fid,'%s',raw);clear closeFile
        [ok,message]=movefile(temporary,file,'f');
        if ~ok,error('MatlabAI:SessionWrite','会话保存失败：%s',message);end
    case 'load'
        value=[];if ~isfile(file),return;end
        info=dir(file);if info.bytes>12*1024*1024,error('MatlabAI:SessionSize','会话文件过大。');end
        value=jsondecode(fileread(file));
        if ~isstruct(value) || ~isscalar(value) || ~isfield(value,'schema') || value.schema~=1
            error('MatlabAI:SessionFormat','不支持的会话格式。');
        end
    case 'delete'
        if isfile(file),delete(file);end
        value=[];
    otherwise,error('MatlabAI:SessionAction','未知会话操作。');
end
end
function removeTemporary(file)
if isfile(file),delete(file);end
end
