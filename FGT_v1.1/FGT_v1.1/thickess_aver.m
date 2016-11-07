function average_thickness = thickess_aver(Xl, Yl, Xu, Yu)
% FGT - Fold Geometry Toolbox
%
% Original author:    Adamuszek
% Last committed:     $Revision: 133 $
% Last changed by:    $Author: schmid $
% Last changed date:  $Date: 2011-06-01 12:27:20 +0200 (Wed, 01 Jun 2011) $
%--------------------------------------------------------------------------
%
% Calculates the average thickness of the fold train.
%
% input  - x and y coordinates of the upper and lower fold interfaces
% output - average thickness value

% ARC LENGTH OF THE UPPER AND LOWER INTERFACE OF THE FOLD
Arc_lower           = sum(sqrt(diff(Xl).^2 + diff(Yl).^2));
Arc_upper           = sum(sqrt(diff(Xu).^2 + diff(Yu).^2));

% Average arc length of the fold
Average_arc         = (Arc_lower + Arc_upper)/2;

% Fold area
Fold_area           = polyarea([Xl Xu],[Yl Yu]);

% Average thickness
average_thickness   = Fold_area/Average_arc;