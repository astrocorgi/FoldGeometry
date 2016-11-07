function Y = smooth_gaussian(x, y, swindow)
% FGT - Fold Geometry Toolbox
%
% Original author:    Adamuszek
% Last committed:     $Revision: 131 $
% Last changed by:    $Author: martaada $
% Last changed date:  $Date: 2011-05-31 21:12:38 +0200 (Tue, 31 May 2011) $
%--------------------------------------------------------------------------
%
% Smooths a function using a Gaussian filter. 
%
% input  - x and y coordinates of fold data
%        - window size (swindow)
% output - smoothed y values

if swindow ~= 0
    
    sigma   = 1;
    Y       = zeros(1, length(x));
    coeff1  = 1/(sigma*sqrt(2*pi));
    coeff2  = (6/swindow).^2/(2*sigma^2);
    
    for i = 1:length(x)
        
        % Select points in the window
        Selection   = x>=x(i)-swindow/2 & x<=x(i)+swindow/2;
        
        % Calculate weights
        Weights     = coeff1*exp(-(x(Selection)-x(i)).^2*coeff2);
        
        % Calculate the value for each point
        Y(i)        = y(Selection)*Weights'/sum(Weights);
    end
    
else
    Y = y;
end

end
