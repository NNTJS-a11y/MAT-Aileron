portableRoot = fileparts(mfilename('fullpath'));
addpath(portableRoot);
installMatlabAI;
fprintf('安装完成。请保留本文件夹；打开MATLAB后输入 Aileron 唤起助手，不再自动打开。\n');
clear portableRoot
