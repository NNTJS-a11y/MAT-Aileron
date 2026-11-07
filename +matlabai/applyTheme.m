function applyTheme(window)
% Public MATLAB UI properties only; no dependency on private desktop CSS.
base=[245 245 247]/255;ink=[29 29 31]/255;muted=[110 110 115]/255;
window.Color=base;
objects=findall(window);
for index=1:numel(objects)
    item=objects(index);
    if isprop(item,'FontName'),item.FontName='Segoe UI';end
    if isa(item,'matlab.ui.control.Label')
        item.FontColor=muted;
    elseif isa(item,'matlab.ui.control.Button')
        item.BackgroundColor=[1 1 1];item.FontColor=ink;item.FontSize=12;
    elseif isa(item,'matlab.ui.control.TextArea')
        item.BackgroundColor=[1 1 1];item.FontColor=ink;
        if strcmp(item.Tag,'CodePreview'),item.FontName='Consolas';item.FontSize=13;
        else,item.FontSize=13;end
    elseif isa(item,'matlab.ui.control.EditField') || isa(item,'matlab.ui.control.DropDown')
        item.BackgroundColor=[1 1 1];item.FontColor=ink;
    elseif isa(item,'matlab.ui.container.GridLayout')
        item.BackgroundColor=base;
        if isa(item.Parent,'matlab.ui.container.Panel') || isa(item.Parent,'matlab.ui.container.Tab')
            item.BackgroundColor=[1 1 1];
        end
    elseif isa(item,'matlab.ui.container.Panel')
        item.BackgroundColor=[1 1 1];item.BorderType='none';
    elseif isa(item,'matlab.ui.container.Tab')
        item.BackgroundColor=[1 1 1];
    elseif isa(item,'matlab.ui.control.Table')
        item.BackgroundColor=[1 1 1;248/255 250/255 253/255];item.FontSize=12;
    end
end
buttons=findall(window,'-isa','matlab.ui.control.Button');
for index=1:numel(buttons)
    button=buttons(index);
    if any(strcmp(button.Text,{'发送','保存设置'}))
        button.BackgroundColor=[0 113 227]/255;button.FontColor=[1 1 1];button.FontWeight='bold';
    elseif strcmp(button.Text,'运行代码…') || strcmp(button.Tag,'ConversationToggle')
        button.BackgroundColor=[232 242 255]/255;button.FontColor=[0 100 205]/255;
    elseif any(strcmp(button.Text,{'停止生成','移除所选'}))
        button.FontColor=[180 65 65]/255;
    end
end
end
