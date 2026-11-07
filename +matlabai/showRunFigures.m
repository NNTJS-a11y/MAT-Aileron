function windows=showRunFigures(result)
% Persistent raster views in the parent. Do not load figure callbacks from worker.
windows=gobjects(0);folder=fileparts(result.path);files=dir(fullfile(folder,'figure-*.png'));
for k=1:numel(files)
    if isempty(regexp(files(k).name,'^figure-[0-9]+\.png$','once')),continue;end
    file=fullfile(folder,files(k).name);info=imfinfo(file);
    if double(info.Width)*double(info.Height)>40000000
        warning('MatlabAI:PlotSize','图像过大，请从结果目录查看：%s',file);continue;
    end
    pixels=imread(file);
    window=figure('Name',['MAT Aileron · ' datestr(files(k).datenum,'HH:MM:SS') ' · ' result.name ' · ' files(k).name], ...
        'NumberTitle','off','Tag','MatAileronResultFigure','Color','white','Visible','off');
    ax=axes(window);image(ax,pixels);axis(ax,'image');axis(ax,'off');
    title(ax,'运行结果图像 · 保留至手动关闭（缩放查看为栅格图）','FontSize',10);
    setappdata(window,'MatAileronImagePath',file);
    window.Visible='on';windows(end+1)=window; %#ok<AGROW>
end
end
