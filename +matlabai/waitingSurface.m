function surface = waitingSurface(generator)
% Static numerical membrane geometry; lighting alone is animated in the UI.
if nargin<1,generator=@() membrane(1,12);end
kind='membrane';
try
    z=generator();
catch
    % A decorative feature must never prevent the assistant from opening.
    [a,b]=meshgrid(linspace(-1,1,25));
    z=(1-a.^2).*(1-b.^2);z(a>0 & b>0)=0;
    kind='fallback';
end
n=size(z,1);
[x,y]=meshgrid(linspace(-1,1,n));
scale=max(abs(z(:)));
if scale>0,z=z/scale;end
faces=zeros((n-1)^2,4);count=0;
for row=1:n-1
    for column=1:n-1
        indices=[sub2ind([n n],row,column),sub2ind([n n],row,column+1), ...
            sub2ind([n n],row+1,column+1),sub2ind([n n],row+1,column)];
        if ~any(abs(z(indices))>1e-10),continue;end
        count=count+1;faces(count,:)=indices;
    end
end
surface=struct('vertices',[x(:),y(:),z(:)],'faces',faces(1:count,:),'kind',kind);
end
