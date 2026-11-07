function report = compatibilityReport(target)
profile = matlabai.compatibilityProfile(target);
requirements = {'uifigure','uigridlayout','uihtml','readcell','sheetnames','jsonencode','exportgraphics','codeIssues'};
available = cellfun(@(name) exist(name,'file') ~= 0 || exist(name,'builtin') ~= 0, requirements);
hasHTTP = ~isempty(meta.class.fromName('matlab.net.http.io.ContentConsumer')) && ...
    ~isempty(meta.class.fromName('matlab.net.http.ProgressMonitor'));
hasJava = usejava('jvm');
hasPDF=exist('extractFileText','file')~=0 || hasClass('org.apache.pdfbox.pdmodel.PDDocument') || hasClass('org.apache.pdfbox.Loader');
hasLegacyExcel=isfile(fullfile(fileparts(mfilename('fullpath')),'legacySpreadsheetBounds.m'));
hasSimulink = ~isempty(ver('simulink')) && license('test','Simulink');
blockStatus = '未安装或未授权 Simulink；对话及附件功能仍可使用';
if hasSimulink
    try
        catalog = matlabai.blockCatalog;
        types = fieldnames(catalog);
        blocks = cell(numel(types),1);
        for index=1:numel(types)
            type=types{index};
            blocks{index}=struct('type',type,'parameters',catalog.(type).parameters);
        end
        matlabai.checkBlockCompatibility(struct('blocks',{blocks}));
        blockStatus = sprintf('%d 类基础模块及参数存在（未执行仿真）',numel(types));
    catch problem
        blockStatus = ['检查未通过：' problem.message];
    end
end
missing = strjoin(requirements(~available),', ');
if isempty(missing), missing='无'; end
report = sprintf(['目标版本：%s\n当前实际运行：R%s\n统一程序基线：%s\n' ...
    '必备接口缺失：%s\nJava：%d；原生流式 HTTP 接口：%d\nSimulink：%s\n' ...
    '本报告检查当前安装环境，不模拟或认证目标版本。R2024a 已实机测试；其他版本待实机验证。'], ...
    target,version('-release'),profile.baseline,missing,hasJava,hasHTTP,blockStatus);
report=[report newline sprintf('PDF解析能力：%d；旧Excel预检能力：%d。实时脚本使用可选内部接口，失败会回退普通脚本。',hasPDF,hasLegacyExcel)];
try
    folder=matlabai.dataRoot;probe=tempname(folder);fid=fopen(probe,'w');
    if fid<0,error('MatlabAI:Writable','目录不可写');end
    fclose(fid);delete(probe);
    report=[report newline '数据目录可写：' folder];
catch problem
    report=[report newline '数据目录不可用：' problem.message];
end
end
function present=hasClass(name)
try,java.lang.Class.forName(name);present=true;catch,present=false;end
end
