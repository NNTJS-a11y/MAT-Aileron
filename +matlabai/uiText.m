function text=uiText(text,language)
% Translate application-owned UI labels, preserving user content and IDs.
if nargin<2,language=getpref('MatlabAI','Language','zh');end
persistent pairs
if isempty(pairs)
    pairs={
        '工作区设置','Workspace settings'; '结果与会话目录','Results and session folder';
        '选择目录…','Choose folder…'; '程序目录可保持只读；迁移目录不会删除旧结果','The application folder may be read-only. Moving data preserves old results.';
        '上下文预算','Context budget'; '运行超时（秒）','Run timeout (seconds)'; '本地会话保存','Save sessions locally';
        '保存草稿、附件文字与历史（不含密钥）','Save drafts, file text and history (excluding keys)';
        '预算使用UTF-8字节数作保守token估计，需按服务实际限制设置。','UTF-8 bytes provide a conservative token estimate. Use your service limits.';
        '关闭保存会删除当前目录的恢复与历史记录；旧目录记录需自行清理。结果不删除。','Disabling persistence deletes recovery and history in the current folder. Results are retained. Clean old folders separately.';
        '模式','Mode'; 'MATLAB 对话','MATLAB Chat'; 'Simulink 建模仿真','Simulink Modeling';
        '方案通过后自动建模并仿真','Build and simulate approved plans';
        '目标版本','Target release'; '兼容自检','Check compatibility';
        '对话与运行记录','Conversation & run log'; '展开记录','Show log'; '收起记录','Hide log';
        '添加附件','Add files'; '预览附件','Preview'; '移除所选','Remove selected'; '清空附件','Clear files';
        '发送当前编辑器脚本','Include active editor script';
        '勾选移除','Select'; '附件名称','File name'; '文字数','Characters';
        '描述需求，例如：根据附件 Word/PDF 说明建模，或分析 Excel 数据并绘图','Describe a task, e.g. analyze an Excel file or model a system from a Word/PDF document';
        '发送','Send'; '停止生成','Stop'; '分析结果 / 修复','Analyze / Repair'; '新对话','New chat';
        'MATLAB 代码预览（可编辑）','MATLAB code preview (editable)';
        '代码 / JSON预览','Code / JSON'; '模型与算法说明','Model & algorithm';
        '方法摘要用于人工审阅；尚未经独立验证','Method summary for review; not independently validated';
        '展开说明','Expand'; '新建脚本','New script'; '新建实时脚本','New live script';
        '显示在命令窗口','Show in Command Window'; '检查代码','Check code'; '查看方法说明','View method';
        '运行代码…','Run code…'; 'PID 示例（免 API）','PID demo (no API)';
        '生成 Simulink 模型','Build Simulink model'; '生成并仿真','Build & simulate'; '读取当前模型','Read current model';
        '就绪 · 密钥不写入配置文件','Ready · API keys are not saved to configuration files';
        '工作区','Workspace'; '启动动画','Startup animation'; '工作区设置…','Workspace settings…';
        '恢复上次会话','Restore last session'; '导出完整对话…','Export conversation…';
        '查看最近运行图像','View recent plots'; '清理检查缓存…','Clear check cache…';
        '显示/收起历史侧栏','Toggle history sidebar'; '保存当前任务到历史','Save task to history';
        '历史任务','Task history'; '搜索历史任务（回车）','Search tasks (Enter)';
        '暂无历史','No history'; '暂无匹配历史','No matching tasks';
        '搜索/选择只定位，点击引用才会用于本轮。','Select to browse. Click Reference to use in the next request.';
        '预览所选','Preview'; '引用所选','Reference'; '清除引用','Clear reference'; '删除历史','Delete history';
        '本轮附带历史附件','Include historical files'; '本轮追溯上游步骤','Include upstream steps';
        '当前未引用历史','No history referenced'; '新任务','New task';
        'API设置','API Settings'; 'API 地址','API endpoint'; '模型名称','Model name';
        '模型服务','Model provider'; '自定义兼容接口','Custom compatible API'; '豆包（火山方舟）','Doubao (Volcengine Ark)';
        '支持 DeepSeek / 豆包（火山方舟）/ OpenAI 兼容接口。','Supports DeepSeek / Doubao (Ark) / OpenAI-compatible APIs.';
        '豆包请填写已开通的 Model ID 或推理接入点 ID；切换服务会清空密钥。','Doubao needs an enabled Model ID or endpoint ID. Switching providers clears the key.';
        '取消','Cancel'; '保存设置','Save settings'; '确定','OK'; '保存','Save'; '删除','Delete';
        '兼容 OpenAI / DeepSeek Chat Completions 接口。','Supports OpenAI-compatible Chat Completions APIs.';
        '地址和模型会记住；密钥仅留在本次会话，或从环境变量读取。','Endpoint and model are saved locally. Keys stay in memory or environment variables.';
        'API设置已更新 · 密钥仅保留在本次会话','API settings updated · key kept in this session only';
        '先勾选附件行前面的方框，再点击此按钮；只移除打勾的附件，不删除原文件','Check file rows, then click Remove selected. Original files are preserved.';
        '预览第一个打勾的附件；没有打勾时预览点击的附件行','Preview the first checked file, or the selected row if none is checked.';
        '仅展开或收起显示，不会清空对话、错误或运行记录','Show or hide the log while retaining conversations, errors and run records.';
        '勾选方框后点击“移除所选”。勾选仅用于移除；保留在列表中的全部附件都会随发送上传文字。','Check rows to remove files. Text from all remaining files is included when sending.';
        'API地址无效','Invalid API endpoint'; '模型名称为空','Missing model name';
        '请填写完整HTTPS API地址；本机服务可使用localhost HTTP。','Enter a complete HTTPS endpoint. Local services may use localhost HTTP.';
        '请填写服务商提供的模型名称。','Enter the model name provided by your API service.';
        '操作失败','Operation failed'; 'AI 请求失败','AI request failed'; '建模 / 仿真失败','Build / simulation failed';
        '启动动画已关闭','Startup animation disabled'; '启动动画已开启，下次新开助手时生效','Startup animation enabled for the next new assistant window';
        '当前运行 ','Running '; ' · 选择只设置兼容目标，不切换软件',' · Target affects compatibility, not the installed MATLAB';
        'MATLAB 代码预览 · 数学建模 / 数据分析 / Excel填表','MATLAB preview · Modeling / Data analysis / Spreadsheets';
        'Simulink JSON方案预览（可编辑）','Simulink JSON plan (editable)';
        '对话与运行记录 · 有','Conversation & run log · '; '条新记录',' new entries';
        '正在接收回复 · 已收到','Receiving response · '; '字符',' characters';
        '附件已清空','Files cleared'; '就绪','Ready'; '未发送','Not sent';
        '附件已就绪','Files ready'; '等待结果','Generating…';
        '欢迎使用 MAT Aileron。点击右上角“API设置”配置服务。','Welcome to MAT Aileron. Open API Settings to configure your service.';
        '发送时，对话及选中的附件/脚本将传给该服务。','Sending shares the conversation and included files/scripts with your configured service.';
        'Simulink 模式可生成基础控制/信号模型并仿真；PID 示例无需 API。','Simulink mode supports basic control/signal models and simulation. The PID demo needs no API.';
        '生成代码后，在此查看：目标、模型与公式、假设、算法、计算流程、验证方法及本轮改动。','Review the objective, model, equations, assumptions, algorithm, checks and changes after generation.';
    };
end
if iscell(text)
    text=cellfun(@(s) matlabai.uiText(s,language),text,'UniformOutput',false);return;
end
if ~(ischar(text)||isstring(text)),return;end
wasString=isstring(text);text=char(text);
if strcmp(language,'en'),from=1;to=2;else,from=2;to=1;end
% Exact labels first, then application-generated composite status strings.
index=find(strcmp(text,pairs(:,from)),1);
if ~isempty(index),text=pairs{index,to};
elseif strcmp(language,'en')
    for index=1:size(pairs,1)
        if numel(pairs{index,1})>3,text=strrep(text,pairs{index,1},pairs{index,2});end
    end
end
if wasString,text=string(text);end
end
