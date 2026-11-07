function value = previewText(text, limit)
if nargin<2,limit=24000;end
text=char(text);
if numel(text)>limit
    text=['[长回复显示末尾预览；完整内容将在完成后保留，工作区菜单可导出记录]' newline text(end-limit+1:end)];
end
value=cellstr(splitlines(string(text)));
end
