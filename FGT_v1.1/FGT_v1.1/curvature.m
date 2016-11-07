function [Curve, Arc_length] = curvature(x_input,y_input,order)
% FGT - Fold Geometry Toolbox
%
% Original author:    Adamuszek
% Last committed:     $Revision: 135 $
% Last changed by:    $Author: martaada $
% Last changed date:  $Date: 2011-06-01 14:15:19 +0200 (Wed, 01 Jun 2011) $
%--------------------------------------------------------------------------
% 
% Calculates parametric curvature and arclength for a set of data points.
% The derivatives of the curvature are calculated by calculating 
% the derivatives of a second-order polynomial that locally interpolates 
% between parametrized 3, 5, or 7 data points. By choosing 3 points the 
% polynomial is fitted exactly, whereas two other options employ a 
% low-pass filter.
%
% input  - x and y fold coordinates
%        - number of points (3, 5, or 7) to which the polynomial is fitted
% output - parametric curvature 
%        - arclength


%% POLYNOMIAL APPROACH
%Calculating the arc length
Arc_length  = sqrt( (x_input(2:end)-x_input(1:end-1)).^2 + (y_input(2:end)-y_input(1:end-1)).^2 );
Arc_length  = [0 cumsum(Arc_length)];

%Calculating derivatives
[Dx1, Dx2] = polynomial_derivatives(Arc_length,x_input,order);
[Dy1, Dy2] = polynomial_derivatives(Arc_length,y_input,order);

%Calculating the curvature
Curve = (Dx1.*Dy2-Dy1.*Dx2)./((Dx1.^2+Dy1.^2).^1.5);
end

function [D1,D2] = polynomial_derivatives(x,y,order)

% Calculates derivatives of the polynomial
%
% input  - x and y coordinates of the data set
%        - number of points to which the polynomial is fitted (order)
% output - first and second derivatives (D1, D2) evaluated in the central
%          point. In case of the nodes that are close to the boundary, the 
%          polynomial is fitted to the marginal set of points and the 
%          derivatives calculated for the respective points

% Initialize the output
D1 = zeros(1,length(x));
D2 = zeros(1,length(x));

% Construct part of the Vandermonde matrix
V     	= zeros(order, 3);
V(:,3) 	= 1;

mid = (order+1)/2;

for i = mid:length(x)-mid+1
    
    if order == 3
        X = x(i-1:i+1);
        Y = y(i-1:i+1);
    elseif order == 5
        X = x(i-2:i+2);
        Y = y(i-2:i+2);
    elseif order == 7
        X = x(i-3:i+3);
        Y = y(i-3:i+3);
    end
    
    % Construct the other part of the Vandermonde matrix
    V(:,2) = X'.*V(:,3);
    V(:,1) = X'.*V(:,2);
    
    % Solve least squares problem
    [Q,R]   = qr(V,0);
    p       = R\(Q'*Y');
    
    % Fit data to polynomial
    Y  = V*p;
    
    % Extract 3 points from the row
    if order == 3
        Xd = X;
        Yd = Y;
    elseif order ==5
        Xd = X([1,3,5]);
        Yd = Y([1,3,5]);
    elseif order == 7
        Xd  = X([1,4,7]);
        Yd  = Y([1,4,7]);
    end
    
    % Calculate differences
    Dl = diff(Xd(1:end-1));
    Du = diff(Xd(2:end));
    
    % Calculate derivatives
    D1(i) = -Yd(1:end-2).*Du./(Dl.*(Dl+Du)) -Yd(2:end-1).*(Dl-Du)./(Dl.*Du) +Yd(3:end).*Dl./((Dl+Du).*Du);
    D2(i) =    2*Yd(1:end-2)./(Dl.*(Dl+Du))        -2*Yd(2:end-1)./(Dl.*Du)   +2*Yd(3:end)./((Dl+Du).*Du);
    
    % Boundary nodes, 3 point-case
    if i == 2 && order == 3
        
        % Extract 3 points from the row
        Xd  = X([1,2,3]);
        Yd  = Y([1,2,3]);
        
        % Calculate differences
        Dl = diff(Xd(1:end-1));
        Du = diff(Xd(2:end));
        
        % Calculate derivatives for the first point
        D1(1) = -Yd(1).*(2*Dl+Du)./(Dl.*(Dl+Du))  +Yd(2).*(Dl+Du)./(Dl.*Du)   -Yd(3).*Dl       ./((Dl+Du).*Du);

        D2(1) =  2*Yd(1)./(Dl.*(Dl+Du))        -2*Yd(2)./(Dl.*Du)   +2*Yd(3)./((Dl+Du).*Du);
        
    end
    
    % Boundary nodes, 5 point-case
    if i == 3 && order == 5
        
        % Extract 3 points from the row (1,2,3) to calculate derivativers for two first points
        Xd  = X([1,2,3]);
        Yd  = Y([1,2,3]);
        
        % Calculate differences
        Dl = diff(Xd(1:end-1));
        Du = diff(Xd(2:end));
        
        % Calculate derivatives
        D1(1) = -Yd(1).*(2*Dl+Du)./(Dl.*(Dl+Du))  +Yd(2).*(Dl+Du)./(Dl.*Du)   -Yd(3).*Dl       ./((Dl+Du).*Du);
        D1(2) = -Yd(1).*Du       ./(Dl.*(Dl+Du))  -Yd(2).*(Dl-Du)./(Dl.*Du)   +Yd(3).*Dl       ./((Dl+Du).*Du);
        
        D2([1 2]) =  2*Yd(1)./(Dl.*(Dl+Du))        -2*Yd(2)./(Dl.*Du)   +2*Yd(3)./((Dl+Du).*Du);
        
    end
    
    % Boundary nodes, 7 point-case
    if i == 4 && order == 7
        
        % Extract 3 points from the row (1,2,3) to calculate derivativers for two first points
        Xd  = X([1,2,3]);
        Yd  = Y([1,2,3]);
        
        % Calculate differences
        Dl = diff(Xd(1:end-1));
        Du = diff(Xd(2:end));
        
        % Calculate derivatives
        D1(1) = -Yd(1).*(2*Dl+Du)./(Dl.*(Dl+Du))  +Yd(2).*(Dl+Du)./(Dl.*Du)   -Yd(3).*Dl       ./((Dl+Du).*Du);
        D1(2) = -Yd(1).*Du       ./(Dl.*(Dl+Du))  -Yd(2).*(Dl-Du)./(Dl.*Du)   +Yd(3).*Dl       ./((Dl+Du).*Du);
        
        % Extract 3 points from the row (2,3,4) to calculate derivativers for the third point
        Xd  = X([2,3,4]);
        Yd  = Y([2,3,4]);
        
        % Calculate differences
        Dl = diff(Xd(1:end-1));
        Du = diff(Xd(2:end));
        
        % Calculate derivatives
        D1(3) =  -Yd(1).*Du       ./(Dl.*(Dl+Du))  -Yd(2).*(Dl-Du)./(Dl.*Du)   +Yd(3).*Dl       ./((Dl+Du).*Du);
        
        D2([1 2 3]) =  2*Yd(1)./(Dl.*(Dl+Du))        -2*Yd(2)./(Dl.*Du)   +2*Yd(3)./((Dl+Du).*Du);
        
    end
    
    % Boundary nodes, 3 point-case
    if i == length(x)-1 && order == 3
        
        % Extract 3 points from the row
        Xd  = X([1,2,3]);
        Yd  = Y([1,2,3]);
        
        % Calculate differences
        Dl = diff(Xd(1:end-1));
        Du = diff(Xd(2:end));
        
        % Calculate derivatives
        D1(length(x))   =  Yd(1).*Du       ./(Dl.*(Dl+Du))  -Yd(2).*(Dl+Du)./(Dl.*Du)   +Yd(3).*(Dl+2*Du)./((Dl+Du).*Du);
        
        D2(length(x))   =  2*Yd(1)./(Dl.*(Dl+Du))        -2*Yd(2)./(Dl.*Du)   +2*Yd(3)./((Dl+Du).*Du);
        
    end
    
    % Boundary nodes, 5 point-case
    if i == length(x)-2 && order == 5
        
        % Extract 3 points from the row
        Xd  = X([3,4,5]);
        Yd  = Y([3,4,5]);
        
        % Calculate differences
        Dl = diff(Xd(1:end-1));
        Du = diff(Xd(2:end));
        
        % Calculate derivatives
        D1(length(x)-1) = -Yd(1).*Du       ./(Dl.*(Dl+Du))  -Yd(2).*(Dl-Du)./(Dl.*Du)   +Yd(3).*Dl       ./((Dl+Du).*Du);
        D1(length(x))   =  Yd(1).*Du       ./(Dl.*(Dl+Du))  -Yd(2).*(Dl+Du)./(Dl.*Du)   +Yd(3).*(Dl+2*Du)./((Dl+Du).*Du);
        
        D2([length(x)-1, length(x)]) =  2*Yd(1)./(Dl.*(Dl+Du))  -2*Yd(2)./(Dl.*Du)   +2*Yd(3)./((Dl+Du).*Du);
        
    end
    
    % Boundary nodes, 7 point-case
    if i == length(x)-3 && order == 7
        
        % Extract 3 points from the row (4,5,6) to calculate derivativers for the third to last point
        Xd  = X([4,5,6]);
        Yd  = Y([4,5,6]);
        
        % Calculate differences
        Dl = diff(Xd(1:end-1));
        Du = diff(Xd(2:end));
        
        D1(length(x)-2) = -Yd(1).*Du       ./(Dl.*(Dl+Du))  -Yd(2).*(Dl-Du)./(Dl.*Du)   +Yd(3).*Dl       ./((Dl+Du).*Du);
        
        % Extract 3 points from the row (5,6,7) to calculate derivativers for two last points
        Xd  = X([5,6,7]);
        Yd  = Y([5,6,7]);
        
        % Calculate differences
        Dl = diff(Xd(1:end-1));
        Du = diff(Xd(2:end));
        
        % Calculate derivatives
        D1(length(x)-1) = -Yd(1).*Du       ./(Dl.*(Dl+Du))  -Yd(2).*(Dl-Du)./(Dl.*Du)   +Yd(3).*Dl       ./((Dl+Du).*Du);
        D1(length(x))   =  Yd(1).*Du       ./(Dl.*(Dl+Du))  -Yd(2).*(Dl+Du)./(Dl.*Du)   +Yd(3).*(Dl+2*Du)./((Dl+Du).*Du);
        
        D2([length(x)-2, length(x)-1, length(x)]) =  2*Yd(1)./(Dl.*(Dl+Du)) -2*Yd(2)./(Dl.*Du)   +2*Yd(3)./((Dl+Du).*Du);
        
    end
    
end

end