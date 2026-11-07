function [options, actual] = releaseOptions
actual = ['R' version('-release')];
options = {'自动（当前 MATLAB）'};
for year = 2023:2026
    options{end+1} = sprintf('R%da', year);
    options{end+1} = sprintf('R%db', year);
end
if ~any(strcmp(options, actual)), options{end+1} = actual; end
end
