function c = polynomial_fit(x,y,n)
% FGT - Fold Geometry Toolbox
%
% Original author:    Adamuszek
% Last committed:     $Revision: 127 $
% Last changed by:    $Author: martaada $
% Last changed date:  $Date: 2011-05-30 17:21:35 +0200 (Mon, 30 May 2011) $
%--------------------------------------------------------------------------
%
% Fits a polynomial to data points.
%
% input  - x and y coordinates of the points
%        - order of the polynomial (n)
% output - coefficients of the polynomial (c)

x = x(:);
y = y(:);

% Construct Vandermonde matrix.
V           = zeros(length(x), n+1);
V(:,n+1)    = 1;
for j = n:-1:1
   V(:,j) = x.*V(:,j+1);
end

% Solve least squares problem.
[Q,R]   = qr(V,0);
c       = R\(Q'*y);
c       = c.';
