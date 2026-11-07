function messages=apiUsageChecks(code)
% Conservative checks for known MATLAB API mistakes; no code rewriting.
source=maskLiterals(char(code));messages={};
if ~isempty(regexp(source,'(?m)^\s*function\s+(?:(?:\[[^\r\n]*?\]|[A-Za-z]\w*)\s*=\s*)?vander\s*\(','once'))|| ...
        ~isempty(regexp(source,'(?<![\w.])vander\s*=','once'))|| ...
        ~isempty(regexp(source,'(?m)^\s*function[^\r\n]*\([^\)\r\n]*(?<!\w)vander(?!\w)','once'))
    return; % Explicit local function/variable may intentionally use that name.
end
starts=regexp(source,'(?<![\w.])vander\s*\(','start');
for start=starts
    opening=start+find(source(start:end)=='(',1)-1;depth=1;comma=false;closing=[];
    for k=opening+1:numel(source)
        c=source(k);
        if any(c=='([{'),depth=depth+1;
        elseif any(c==')]}')
            depth=depth-1;if depth==0,closing=k;break;end
        elseif c==','&&depth==1,comma=true;
        end
    end
    if isempty(closing)||~comma,continue;end
    tail=strtrim(source(closing+1:end));if startsWith(tail,'='),continue;end
    line=1+nnz(source(1:start)==newline);
    messages{end+1}=sprintf(['第%d行 [VANDER_INPUTS]：MATLAB vander只接受一个输入向量，不能写vander(x,p)。' ...
        '三次拟合可用polyfit(x(:),y(:),3)，或显式构造A=x(:).^(p:-1:0)后做最小二乘。' ...
        '请修改或点击“分析结果 / 修复”；不会自动改动数学模型。'],line); %#ok<AGROW>
end
end
function out=maskLiterals(code)
out=code;k=1;n=numel(code);
while k<=n
    if code(k)=='%'
        last=find(code(k:end)==newline,1);if isempty(last),last=n;else,last=k+last-2;end
        if k<n&&code(k+1)=='{'
            ending=strfind(code(k+2:end),'%}');
            if isempty(ending),last=n;else,last=k+ending(1)+2;end
        end
        range=k:last;out(range(code(range)~=newline))=' ';k=last+1;
    elseif code(k)=='"'||code(k)==''''
        quote=code(k);
        if quote==''''&&k>1&&(~isspace(code(k-1)))&& ...
                (~isempty(regexp(code(k-1),'[\w\)\]\}.]','once')))
            k=k+1;continue; % transpose, not a character literal
        end
        start=k;k=k+1;
        while k<=n
            if code(k)==quote
                if k<n&&code(k+1)==quote,k=k+2;continue;end
                k=k+1;break;
            end
            k=k+1;
        end
        range=start:k-1;out(range(code(range)~=newline))=' ';
    else,k=k+1;
    end
end
end
