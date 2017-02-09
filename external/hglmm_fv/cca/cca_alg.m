function [Wx, Wy, r] = cca_alg(X,Y,x,regfactor)

% CCA calculate canonical correlations
%
% [Wx Wy r] = cca(X,Y) where Wx and Wy contains the canonical correlation
% vectors as columns and r is a vector with corresponding canonical
% correlations. The correlations are sorted in descending order. X and Y
% are matrices where each column is a sample. Hence, X and Y must have
% the same number of columns.
%
% Example: If X is M*K and Y is N*K there are L=MIN(M,N) solutions. Wx is
% then M*L, Wy is N*L and r is L*1.
%
%
% � 2000 Magnus Borga, Link�pings universitet

% x was meant to allow non uniform regularization. when empty you
% just add the identify matrix as regularization, as is usually done 

if nargin<3
  x = ones(size(X,1),1);
elseif isempty(x)
  x = ones(size(X,1),1);
else
  x = x./norm(x)*sqrt(size(X,1));
end

if nargin<4
  global regfactor;
end

% --- Calculate covariance matrices ---
%fprintf('R');
z = [X;Y];
C = cov(z.');
clear z
C = double(C);
sx = size(X,1);
sy = size(Y,1);
Cxx = C(1:sx, 1:sx) + 10^(-8)*eye(sx);
opts.disp = 0;
if regfactor ~= 0
  Cxx = Cxx + diag(x)*(eigs(Cxx,1,'LM',opts)/regfactor);
end
  
Cxy = C(1:sx, sx+1:sx+sy);
Cyx = Cxy';
Cyy = C(sx+1:sx+sy, sx+1:sx+sy) + 10^(-8)*eye(sy);
if regfactor ~= 0
  Cyy = Cyy + eye(sy)*(eigs(Cyy,1,'LM',opts)/regfactor);
end

% --- Calcualte Wx and r ---

d = min(size(X,1),size(Y,1));

% Originally, used the following code:
% Mx = invCxx*Cxy*invCyy*Cyx
% if d<size(X,1)
%     opts.disp = 0;
%     [Wx,r] = eigs(Mx,d,'LM',opts); % Basis in X
% else
%     [Wx,r] = eig(Mx); % Basis in X
% end
% The problem is that Mx is not guaranteed to be symmetric and so the
% eigvenvalues can be complex (and they were, at times). Modified to the
% code below. This is the same, but solving for Rx*Wx instead of Wx guarantees 
% that the matrix Z is symmetric (and we ensure it by taking 0.5*(Z' + Z)).
Rx = chol(Cxx);
invRx = inv(Rx);
Z = invRx'*Cxy*(Cyy\Cyx)*invRx;
Z = 0.5*(Z' + Z);  % making sure that Z is a symmetric matrix
if d<size(X,1)
    opts.disp = 0;
    [Wx,r] = eigs(Z,d,'LM',opts); % Basis in X
else
    [Wx,r] = eig(Z);   % basis in h (X)
end
r(r<0)=0;   % Fix very small negatives
r = sqrt(real(r)); % as the original r we get is lamda^2
Wx = invRx * Wx;   % actual Wx values

% --- Sort correlations ---

V = fliplr(Wx);		% reverse order of eigenvectors
r = flipud(diag(r));	% extract eigenvalues anr reverse their orrer
[r,I]= sort((real(r)));	% sort reversed eigenvalues in ascending order
r = flipud(r);		% restore sorted eigenvalues into descending order
for j = 1:length(I)
  Wx(:,j) = V(:,I(j));  % sort reversed eigenvectors in ascending order
end
Wx = fliplr(Wx);	% restore sorted eigenvectors into descending order

% --- Calcualte Wy  ---

% See comment in the calculation of Wx above
Ry = chol(Cyy);
invRy = inv(Ry);
Z = invRy'*Cyx*(Cxx\Cxy)*invRy;
Z = 0.5*(Z' + Z);  % making sure that Z is a symmetric matrix
if d<size(Y,1)
    opts.disp = 0;
    [Wy,r] = eigs(Z,d,'LM',opts); % Basis in X
else
    [Wy,r] = eig(Z);   % basis in h (X)
end
r(r<0)=0;   % Fix very small negatives
r = sqrt(real(r)); % as the original r we get is lamda^2
Wy = invRy * Wy;   % actual Wy values

% --- Sort correlations ---

V = fliplr(Wy);		% reverse order of eigenvectors
r = flipud(diag(r));	% extract eigenvalues anr reverse their orrer
[r,I]= sort((real(r)));	% sort reversed eigenvalues in ascending order
r = flipud(r);		% restore sorted eigenvalues into descending order
for j = 1:length(I)
  Wy(:,j) = V(:,I(j));  % sort reversed eigenvectors in ascending order
end
Wy = fliplr(Wy);	% restore sorted eigenvectors into descending order

%Wy = invCyy*Cyx*Wx;     % Basis in Y
%Wy = Wy./repmat(sqrt(sum(abs(Wy).^2)),sy,1); % Normalize Wy

for i = 1:size(Wx,2),
   Wx(:,i) = Wx(:,i)./sqrt(Wx(:,i)'*Cxx*Wx(:,i));
end
for i = 1:size(Wy,2),
   Wy(:,i) = Wy(:,i)./sqrt(Wy(:,i)'*Cyy*Wy(:,i));
end

X = double(X);
XX = real(Wx'*X);
clear X

Y = double(Y);
YY = real(Wy'*Y);
clear Y

% calculate the correlation between rows (only diagonal)
% turns out much faster this way than using corr inside the for loop
signs = zeros(size(XX,1),1);
for i = 1:size(XX,1),
  if (norm(XX(i,:)) * norm(YY(i,:)))
      % Commented line below was replaced by calculating C2 outside the
      % loop
        signs(i) = sign(corr(XX(i,:)',YY(i,:)'));
  else
    signs(i) = 1;
  end
end

Wy = Wy*diag(signs);

