function root = dataRoot(kind)
% User-writable data, never mixed into the portable program directory.
root=getpref('MatlabAI','DataRoot',fullfile(prefdir,'MAT-Aileron'));
if nargin>0,root=fullfile(root,kind);end
if ~isfolder(root)
    [ok,message]=mkdir(root);
    if ~ok,error('MatlabAI:DataRoot','无法创建数据目录：%s\n%s',root,message);end
end
end
