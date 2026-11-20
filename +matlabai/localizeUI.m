function localizeUI(window)
% Bind translated display properties without changing callbacks or stored IDs.
if isempty(window)||~isgraphics(window),return;end
objects=findall(window);
for index=1:numel(objects)
    object=objects(index);
    properties={'Text','Title','Tooltip','Placeholder','ColumnName'};
    if isa(object,'matlab.ui.Figure'),properties{end+1}='Name';end
    if isa(object,'matlab.ui.control.ListBox')&&isequal(object.ItemsData,{'none'})
        properties{end+1}='Items';
    end
    if isa(object,'matlab.ui.control.DropDown')&&~isempty(object.ItemsData)
        properties{end+1}='Items';
    end
    for item=1:numel(properties)
        property=properties{item};
        if ~isprop(object,property),continue;end
        key=['AileronLanguage_' property];
        if ~isappdata(object,key)
            setappdata(object,key,object.(property));
            metadata=findprop(object,property);
            if metadata.SetObservable
                listener=addlistener(object,property,'PostSet',@(~,~) update(object,property,key));
                setappdata(object,[key '_listener'],listener);
            end
        end
        render(object,property,key);
    end
end
end
function update(object,property,key)
if ~isgraphics(object)||isappdata(object,'AileronTranslating'),return;end
setappdata(object,key,object.(property));render(object,property,key);
end
function render(object,property,key)
if ~isgraphics(object),return;end
setappdata(object,'AileronTranslating',true);
cleanup=onCleanup(@() finish(object));
object.(property)=matlabai.uiText(getappdata(object,key));
end
function finish(object)
if isgraphics(object)&&isappdata(object,'AileronTranslating'),rmappdata(object,'AileronTranslating');end
end
