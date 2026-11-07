function result = simulateModel(build, showPlot)
if nargin < 2, showPlot = true; end
if ~bdIsLoaded(build.model)
    error('MatlabAI:ClosedModel', '模型已关闭，请重新生成模型后仿真。');
end
output = sim(build.model, 'TimeOut', 60, 'ReturnWorkspaceOutputs', 'on');
signal = output.get('ai_signal');
if ~isa(signal, 'timeseries') || isempty(signal.Time)
    error('MatlabAI:NoSignal', '仿真没有返回时间序列，请检查输出信号。');
end
time = signal.Time(:);
values = reshape(signal.Data, numel(time), []);
if any(~isfinite(values), 'all')
    error('MatlabAI:Nonfinite', '仿真结果包含非有限值，请检查模型参数或稳定性。');
end
base = fullfile(build.folder, build.model);
save([base '_result.mat'], 'output', 'time', 'values');
table = array2table([time values]);
table.Properties.VariableNames = [{'Time'}, cellstr(compose('Output%d', 1:size(values,2)))];
writetable(table, [base '_result.csv']);
plotWindow = figure('Name', ['AI 仿真结果 · ' build.model], 'Visible', 'off');
cleanup = onCleanup(@() closeIfHidden(plotWindow, showPlot));
plot(time, values, 'LineWidth', 1.5);
grid on;
xlabel('Time (s)'); ylabel('Output');
title(['Simulink 输出 · ' char(build.plan.output)], 'Interpreter', 'none');
exportgraphics(plotWindow, [base '_plot.png']);
if showPlot, plotWindow.Visible = 'on'; end
summary = sprintf('仿真完成：%s\n时间：%.6g 至 %.6g 秒；记录 %d 个采样点。\n输出末值：%s\n输出最小值：%s\n输出最大值：%s\n结果目录：%s', ...
    build.model, time(1), time(end), numel(time), mat2str(values(end,:),6), ...
    mat2str(min(values,[],1),6), mat2str(max(values,[],1),6), build.folder);
sampleIndices = unique(round(linspace(1, numel(time), min(numel(time), 80))));
samples = struct('time', time(sampleIndices), 'values', values(sampleIndices,:), ...
    'note', '最多80个均匀索引采样点，不是完整仿真数据，不能用于精确性能指标计算。');
result = struct('summary', summary, 'time', time, 'values', values, 'samples', samples, ...
    'matPath', [base '_result.mat'], 'csvPath', [base '_result.csv'], 'plotPath', [base '_plot.png']);
end

function closeIfHidden(window, showPlot)
if ~showPlot && isgraphics(window), close(window); end
end
