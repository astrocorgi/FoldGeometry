function [X, Y, Arclength, Curvature, Inflection, Hinge, Fold_arclength, Wavelength, Amplitude] = curve_analysis(X, Y, window_size, small_area, method_hinge, order)
% FGT - Fold Geometry Toolbox
%
% Original author:    Adamuszek
% Last committed:     $Revision: 131 $
% Last changed by:    $Author: martaada $
% Last changed date:  $Date: 2011-05-31 21:12:38 +0200 (Tue, 31 May 2011) $
%--------------------------------------------------------------------------
%
% For a fold interface defines: arclength, curvature, position of inflection 
% points and hinges, fold arclength, and various definitions of wavelength 
% and amplitude.
%
% input  - x and y fold coordinates
%        - window size
%        - value of the 'small area' filter
%        - method of identifying hinges (method_hinge)
%        - number of points based on which the curvature is calculated (order)
% output - modified and smoothed x and y fold coordinates
%        - arclength
%        - curvature
%        - position of inflection points (Inflection)
%        - position of hinges (Hinge)
%        - fold arc length
%        - four definitions of wavelength
%        - three definitions of amplitude

%% INITIALIZE OUTPUT
Wavelength      = [];
Amplitude       = [];
Hinge.Index     = [];
X.Full          = X.Norm;
Y.Full          = Y.Norm;

%% CURVATURE
%  Calculate curvature
[Curvature.Ori, Arclength.Ori] = curvature(X.Norm, Y.Norm, order);

%  Working copy of original
Arclength.Full      = Arclength.Ori;

%  Smooth curvature
Curvature.Full      = smooth_gaussian(Arclength.Ori, Curvature.Ori, window_size);

%% INFLECTION POINTS
%% - CROSSING SEGMENTS
%    Add points on segments that go through 0
Ind     = find( (Curvature.Full(1:end-1).*Curvature.Full(2:end)) < 0 );
for i=1:length(Ind)
    %  Arclength location of intersection (0 curvature)
    arclength           = interp1(Curvature.Full(Ind(i):Ind(i)+1), Arclength.Full(Ind(i):Ind(i)+1), 0);
    
    %  Add point where required
    Arclength.Full     	= [Arclength.Full, arclength];
    X.Full              = [X.Full, interp1(Arclength.Full(Ind(i):Ind(i)+1), X.Full(Ind(i):Ind(i)+1), arclength)];
    Y.Full              = [Y.Full, interp1(Arclength.Full(Ind(i):Ind(i)+1), Y.Full(Ind(i):Ind(i)+1), arclength)];
    Curvature.Full      = [Curvature.Full, 0];
end

%    Sort
[Arclength.Full, Ind]   = sort(Arclength.Full);
X.Full                  = X.Full(Ind);
Y.Full                  = Y.Full(Ind);
Curvature.Full          = Curvature.Full(Ind);

%    Find potential inflection points
Inflection              = find(Curvature.Full==0);

%% - SMALL AREAS
%    Find and remove 'small areas' in curvature-arclength space
Area = zeros(1, length(Inflection)-1);
for i=1:length(Inflection)-1
    Area(i)	= polyarea( Arclength.Full(Inflection(i):Inflection(i+1)), Curvature.Full(Inflection(i):Inflection(i+1)));
end

%    Setting points in 'small areas' to 0
Ind = find(Area<small_area*max(Area));
for i = Ind
    Curvature.Full(Inflection(i):Inflection(i+1)) = 0;
end

%% - TRUE INFLECTION POINTS
Inad            = diff(Curvature.Full==0);
Positive        = find(Inad==+1)+1;
Negative        = find(Inad==-1);

Inflection      = zeros(size(Curvature.Full));

if Curvature.Full(1)==0
    Negative(1)     = [];
    Inflection(1)   = 1;
end

if Curvature.Full(end)==0
    Positive(end)   = [];
    Inflection(end) = 1;
end

Sign_change     = Curvature.Full(Positive-1).*Curvature.Full(Negative+1)<0;

for i=find(Sign_change)
    if Positive(i)==Negative(i)
        Inflection(Positive(i))     = 1;
    else
        arclength   = (Arclength.Full(Positive(i)) + Arclength.Full(Negative(i)))/2;
        
        Arclength.Full     	= [Arclength.Full, arclength];
        X.Full              = [X.Full, interp1(Arclength.Full(Positive(i):Negative(i)), X.Full(Positive(i):Negative(i)), arclength)];
        Y.Full              = [Y.Full, interp1(Arclength.Full(Positive(i):Negative(i)), Y.Full(Positive(i):Negative(i)), arclength)];
        Curvature.Full      = [Curvature.Full, 0];
        Inflection          = [Inflection, 1];
    end
end

%    Sort
[Arclength.Full, Ind]   = sort(Arclength.Full);
X.Full                  = X.Full(Ind);
Y.Full                  = Y.Full(Ind);
Curvature.Full          = Curvature.Full(Ind);
Inflection              = find(Inflection(Ind));

%% HINGE
%  Between two inflection points there is one hinge
inflection_no           = length(Inflection);
Hinge.Index             = zeros(1, inflection_no-1);

switch method_hinge
    case 1
        %  Find point of maximum curvature between two inflection points
        for i=1:inflection_no-1
            [Dummy, hinge_ind]	= max(abs(Curvature.Full(Inflection(i):Inflection(i+1))));
            Hinge.Index(i)      = hinge_ind+Inflection(i)-1;
        end
        
    case 2
        %  Fit second order polynom to data between inflection points and
        %  find maximum
        Hinge.Poly_Arc = [];
        Hinge.Poly_Cur = [];
        
        for i=1:inflection_no-1
            %  Fit polynomial
            Hinge_Poly          = polynomial_fit( Arclength.Full(Inflection(i):Inflection(i+1)), Curvature.Full(Inflection(i):Inflection(i+1)), 2);
            
            %  Evaluate on arclength coordinates
            Curvature_poly      = polyval(Hinge_Poly, Arclength.Full(Inflection(i):Inflection(i+1)));
            Hinge.Poly_Arc      = [Hinge.Poly_Arc NaN Arclength.Full(Inflection(i):Inflection(i+1))];
            Hinge.Poly_Cur      = [Hinge.Poly_Cur NaN Curvature_poly];
            
            %  Find extremum
            %             [Dummy, hinge_ind]	= max(Curvature_poly.*sign(sum(Curvature.Full(Inflection(i):Inflection(i+1)))));
            [Dummy, hinge_ind]	= max(-Curvature_poly.*sign(Hinge_Poly(1)));
            Hinge.Index(i)      = hinge_ind+Inflection(i)-1;
        end
end

%% FOLD_ARCLENGTH
% Calculate the fold arc length between two neighbouring inflection points
if inflection_no > 1
    Fold_arclength      = diff(Arclength.Full(Inflection));
else
    Fold_arclength = NaN;
end

%% WAVELENGTH
%  1 - Distance between adjacent inflection points
Wavelength(1).Name  = 'Ramsay and Huber (1987)';

if inflection_no > 1
    Wavelength(1).Value = 2*sqrt(diff(X.Full(Inflection)).^2+diff(Y.Full(Inflection)).^2);
else
    Wavelength(1).Value = NaN;
end

%  2 - Distance between alternating hinges
Wavelength(2).Name  = 'van der Pluijm and Marshak (2004)';
% The amplitude can be calculated only for fold train that contains at least three folds
if length(Hinge.Index) > 2
    Wavelength(2).Value = sqrt( (X.Full(Hinge.Index(3:end))- X.Full(Hinge.Index(1:end-2))).^2 + (Y.Full(Hinge.Index(3:end)) - Y.Full(Hinge.Index(1:end-2))).^2 );
else
    Wavelength(2).Value = NaN;
end

%  In case of only one measurement and the presence of three
%  folds, the value is assign to all the folds
if length(Wavelength(2).Value) == 1
    Wavelength(2).Value = Wavelength(2).Value*ones(1,3);
end
%  In case of two wavelenght values and the presence of four folds, the
%  first wavelength value is assign to the first and third fold,
%  whereas the second value to second and fourth fold
if length(Wavelength(2).Value) == 2
    Wavelength(2).Value = [Wavelength(2).Value(1) Wavelength(2).Value(2) Wavelength(2).Value(1) Wavelength(2).Value(2)];
end
%  In case of three wavelength values, the two measurements that are
%  calculated from one hinge are averaged
if length(Wavelength(2).Value) > 2
    Wavelength(2).Value = [Wavelength(2).Value(1:2) (Wavelength(2).Value(1:end-2)+Wavelength(2).Value(2:end-1))/2  Wavelength(2).Value(end-1:end)];
end

% 3 - Quarter wavlength, Hudleston (1973), done below together with the
%     corresponding amplitude

% 4 - Distance between alternating inflection points
Wavelength(4).Name  = 'Price and Cosgrove (1990)';
if length(Inflection) > 2
    Wavelength(4).Value = sqrt( (X.Full(Inflection(3:end))-X.Full(Inflection(1:end-2))).^2 + (Y.Full(Inflection(3:end))-Y.Full(Inflection(1:end-2))).^2);
    
    %  Average the values for one fold
    Wavelength(4).Value = [Wavelength(4).Value(1) (Wavelength(4).Value(1:end-1)+Wavelength(4).Value(2:end))/2 Wavelength(4).Value(end)];
else
    Wavelength(4).Value = NaN;
end

%% AMPLITUDE
%  1 - Distance between the median line and the extremity of the folds
%  PP stands for projected point
Amplitude(1).Name   = 'Ramsay and Huber (1987)';

if inflection_no > 1
    for i = 1:inflection_no-1
        [Distance, PP]     = dist_p2line([X.Full(Inflection(i)); Y.Full(Inflection(i))],[X.Full(Inflection(i+1)); Y.Full(Inflection(i+1))], [X.Full(Inflection(i):Inflection(i+1)); Y.Full(Inflection(i):Inflection(i+1))]);
        
        [Dummy, ind]                = max(Distance);
        Amplitude(1).Value(i)	= Distance(ind);
        Amplitude(1).Index(i)	= ind+Inflection(i)-1;
        Amplitude(1).PP(:,i)   	= PP(:,ind);
    end
else
    Amplitude(1).Value  = NaN*ones(1, inflection_no-1);
    Amplitude(1).Index  = NaN*ones(1, inflection_no-1);
    Amplitude(1).PP     = NaN*ones(2, inflection_no-1);
end

%  2 - Shortest distance between the hinge and median line
%  PP stands for projected point
Amplitude(2).Name   = 'Park (1997)';
if inflection_no > 1
    [Amplitude(2).Value, Amplitude(2).PP]   = dist_p2line([X.Full(Inflection(1:end-1)); Y.Full(Inflection(1:end-1))],[X.Full(Inflection(2:end)); Y.Full(Inflection(2:end))], [X.Full(Hinge.Index); Y.Full(Hinge.Index)]);
else
    Amplitude(2).Value = NaN;
    Amplitude(2).PP    = NaN;
end

%  3 - Quarter wavelength
Amplitude(3).Name   = 'Hudleston (1973)';
Wavelength(3).Name  = 'Hudleston (1973)';


if inflection_no > 1
    Amplitude(3).Value  = NaN*ones(1, 2*length(Hinge.Index));
    Amplitude(3).PP     = NaN*ones(2, 2*length(Hinge.Index));
    
    Wavelength(3).Value = NaN*ones(1, 2*length(Hinge.Index));
           
    % Find a distance between hinge and line cutting middle points of the segments next to the hinge
    [Vec_dummy, Vec_PP]   = dist_p2line(...
        [(X.Full(Hinge.Index)+X.Full(Hinge.Index-1))/2; (Y.Full(Hinge.Index)+Y.Full(Hinge.Index-1))/2], ...
        [(X.Full(Hinge.Index)+X.Full(Hinge.Index+1))/2; (Y.Full(Hinge.Index)+Y.Full(Hinge.Index+1))/2], ...
        [ X.Full(Hinge.Index);   Y.Full(Hinge.Index)]);
    Vec = [ X.Full(Hinge.Index); Y.Full(Hinge.Index)]- Vec_PP;
    
    %  Left inflection point
    [Amplitude(3).Value(1:2:end), Amplitude(3).PP(:,1:2:end)]   = dist_p2line(...
        [(X.Full(Hinge.Index)+X.Full(Hinge.Index-1))/2 + Vec(1,:); (Y.Full(Hinge.Index)+Y.Full(Hinge.Index-1))/2 + Vec(2,:)], ...
        [(X.Full(Hinge.Index)+X.Full(Hinge.Index+1))/2 + Vec(1,:); (Y.Full(Hinge.Index)+Y.Full(Hinge.Index+1))/2 + Vec(2,:)], ...
        [ X.Full(Inflection(1:end-1));  Y.Full(Inflection(1:end-1))]);
    
    Wavelength(3).Value(1:2:end)    = 4*sqrt( (Amplitude(3).PP(1,1:2:end)-X.Full(Hinge.Index)).^2 + (Amplitude(3).PP(2,1:2:end)-Y.Full(Hinge.Index)).^2);
    
    %  Right inflection point
    [Amplitude(3).Value(2:2:end), Amplitude(3).PP(:,2:2:end)]   = dist_p2line(...
        [(X.Full(Hinge.Index)+X.Full(Hinge.Index-1))/2 + Vec(1,:); (Y.Full(Hinge.Index)+Y.Full(Hinge.Index-1))/2 + Vec(2,:)], ...
        [(X.Full(Hinge.Index)+X.Full(Hinge.Index+1))/2 + Vec(1,:); (Y.Full(Hinge.Index)+Y.Full(Hinge.Index+1))/2 + Vec(2,:)], ...
        [ X.Full(Inflection(2:end));   Y.Full(Inflection(2:end))]);
    
    %  Average value of one fold
    Amplitude(3).Value = (Amplitude(3).Value(1:2:end) + Amplitude(3).Value(2:2:end))/2;
    
    Wavelength(3).Value(2:2:end)    = 4*sqrt( (Amplitude(3).PP(1,2:2:end)-X.Full(Hinge.Index)).^2 + (Amplitude(3).PP(2,2:2:end)-Y.Full(Hinge.Index)).^2);
    
    %  Average value of one fold
    Wavelength(3).Value = (Wavelength(3).Value(1:2:end) + Wavelength(3).Value(2:2:end))/2;
    
    %  Make sure that Wavelength also contains projected point (PP) info.
    %  Redundant but consistent
    Wavelength(3).PP    = Amplitude(3).PP;
else
    Amplitude(3).Value  = NaN;
    Amplitude(3).PP     = NaN;
    Wavelength(3).Value = NaN;
    Wavelength(3).PP    = NaN;
end

end