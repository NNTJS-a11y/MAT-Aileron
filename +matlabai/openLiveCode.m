function [document, fallback] = openLiveCode(code, opener)
% The internal bridge is optional. Always preserve generated code on failure.
if nargin < 2, opener = @(text) matlab.internal.liveeditor.openAsLiveCode(text); end
document = [];
fallback = false;
try
    opener(code);
catch
    document = matlab.desktop.editor.newDocument(code);
    fallback = true;
end
end
