function report = checkCodeFile(filePath)
% Public MATLAB analyzer, factory severity, no execution or automatic math edits.
try
    analysis=codeIssues(filePath,'CodeAnalyzerConfiguration','factory');
    issues=analysis.Issues;
    if isprop(analysis,'SuppressedIssues') && ~isempty(analysis.SuppressedIssues)
        suppressed=analysis.SuppressedIssues;
        common=intersect(issues.Properties.VariableNames,suppressed.Properties.VariableNames,'stable');
        issues=[issues(:,common);suppressed(:,common)];
    end
    errors=issues(strcmpi(string(issues.Severity),'error'),:);
catch problem
    error('MatlabAI:AnalyzerUnavailable','无法完成MATLAB代码检查，未运行代码。文件：%s\n%s',filePath,problem.message);
end
lines=strings(min(height(errors),20),1);
for index=1:numel(lines)
    lines(index)=sprintf('第%d行，第%d列 [%s]：%s',errors.LineStart(index), ...
        errors.ColumnStart(index),string(errors.CheckID(index)),string(errors.Description(index)));
end
if isempty(lines)
    summary=sprintf('本机 R%s 静态检查通过，无 error 级问题；另有%d条提示。尚未执行，不代表算法或数据结果正确。',version('-release'),height(issues));
else
    summary=char(strjoin(lines,newline));
    if height(errors)>20,summary=[summary newline sprintf('另有%d条错误未列出。',height(errors)-20)];end
end
apiMessages=matlabai.apiUsageChecks(fileread(filePath));
if ~isempty(apiMessages)
    if isempty(errors),summary='MATLAB接口使用检查未通过（语法分析未报告语法错误）：';end
    summary=[summary newline strjoin(apiMessages,newline)];
end
report=struct('ok',isempty(errors)&&isempty(apiMessages),'summary',summary,'path',filePath, ...
    'errorCount',height(errors)+numel(apiMessages),'issueCount',height(issues)+numel(apiMessages));
end
