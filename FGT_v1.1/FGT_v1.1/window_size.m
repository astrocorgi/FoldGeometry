function [Window_sizes, NIP] = window_size(X, Y, small_area, fold_number, fold, face, order)
% FGT - Fold Geometry Toolbox
%
% Original author:    Adamuszek
% Last committed:     $Revision: 131 $
% Last changed by:    $Author: martaada $
% Last changed date:  $Date: 2011-05-31 21:12:38 +0200 (Tue, 31 May 2011) $
%--------------------------------------------------------------------------
%
% Produces a NIP-FW (Number of Inflection Points - Filter Width) diagram.
% 
% input  - x and y coordinates of the data points
%        - value of the 'small area' filter (small_area)
%        - total number of folds (fold_number)
%        - current number of fold (fold)
%        - current number of interface (face)
%        - number of points based on which the curvature is calculated (3, 5, or 7)


% Calculate curvature
[Curvature_ori, Arclength_ori]  = curvature(X, Y, order);

% Minimum and maximum window sizes
window_min    	= min(diff(Arclength_ori));
window_max     	= max(Arclength_ori);
window_growth   = window_max;

% Number of windows for which number of inflection points would be calculated
n              	= 30;
reduction_size	= (window_max/window_min)^(1/n);

% Initialization
% NIP stands for a number of inflection points
NIP.Ori          = zeros(1,n);
NIP.Smoothed     = zeros(1,n);
Window_sizes     = zeros(1,n);

for i = 1:n;
    
    % Computations take place here
    waitbar((i+(2*fold-2+face-1)*n )/(n*2*fold_number))

    % Smooth curvature
    Curvature_smoothed  = smooth_gaussian(Arclength_ori, Curvature_ori, window_growth);
    
    % Curvature analysis without smoothing
    NIP.Ori(i)          = length(find( (Curvature_smoothed(1:end-1).*Curvature_smoothed(2:end)) <= 0 ));
    
    % Analysis of smoothed curvature
    NIP.Smoothed(i)     = fast_curve_analysis(Curvature_smoothed, Arclength_ori, small_area);
    
    % Decreasing the window size
    window_growth       = window_growth/reduction_size;
    Window_sizes(i)     = window_growth;
end

end


function NumberOfInflectionPoints = fast_curve_analysis(Curvature, Arclength, small_area)
% Defines number of inflection points of the smoothed interface with 'small
% areas' removed.
%
% input  - curvature
%        - arclenght
%        - value of the 'small area' filter
% output - number of inflection points


%% INFLECTION POINTS
% CROSSING SEGMENTS
%    Add points on segments that go through 0
Ind     = find( (Curvature(1:end-1).*Curvature(2:end)) < 0 );

for i=1:length(Ind)    
    %  Arclength location of intersection (0 curvature)
    arclength       = interp1(Curvature(Ind(i):Ind(i)+1), Arclength(Ind(i):Ind(i)+1), 0);
    
    %  Add point where required
    Arclength     	= [Arclength, arclength];
    Curvature       = [Curvature, 0];
end

%    Sort 
[Arclength, Ind]   = sort(Arclength);
Curvature          = Curvature(Ind);

%    Find potential inflection points
Inflection         = find(Curvature==0);

%% - SMALL AREAS
%    Find and remove 'small areas' in curvature-arclength space
Area = zeros(1, length(Inflection)-1);
for i=1:length(Inflection)-1
     Area(i)        = polyarea( Arclength(Inflection(i):Inflection(i+1)), Curvature(Inflection(i):Inflection(i+1)));
end

%    Setting points in 'small areas' to 0
Ind = find(Area<small_area*max(Area));
for i = Ind
    Curvature(Inflection(i):Inflection(i+1)) = 0; 
end

%% - TRUE INFLECTION POINTS
%    Find points where curvature changes from non-zero to zero value and from 
%    zero to non-zero value
Inad            = diff(Curvature==0);
Positive        = find(Inad==+1)+1;
Negative        = find(Inad==-1);

Inflection      = zeros(size(Curvature));

%    Mark an inflection point if curvature on the edges is equal to zero
if Curvature(1)     ==0
    Negative(1)     = [];
    Inflection(1)   = 1;
end

if Curvature(end)   ==0
    Positive(end)   = [];
    Inflection(end) = 1;
end

%    Find points where curvature changes its sign
Sign_change     = Curvature(Positive-1).*Curvature(Negative+1)<0;

%    Determine inflection points
for i = find(Sign_change)
    if Positive(i)==Negative(i)        
        Inflection(Positive(i))     = 1;
    else
        Inflection     = [Inflection, 1];
    end
end

%    Find Inflection points
NumberOfInflectionPoints    = length(find(Inflection));

end