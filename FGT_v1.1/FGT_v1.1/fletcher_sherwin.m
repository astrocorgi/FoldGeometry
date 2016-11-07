function [Lp2H, betaS, VRatio, Stretch] = Fletcher_and_Sherwin(power_law_layer, power_law_matrix)
% FGT - Fold Geometry Toolbox
%
% Original author:    Fletcher
% Last committed:     $Revision: 116 $
% Last changed by:    $Author: schmid $
% Last changed date:  $Date: 2011-05-05 11:31:06 +0200 (Thu, 05 May 2011) $
%--------------------------------------------------------------------------
%
% Generates contours of stretch and viscosity ratio for varying: prefered 
% wavelength to thickness ratio and relative bandwidth of the amplification
% spectrum.
%
% input:  - power law exponents of layer and matrix
% output: - prefered wavelenght (Lp2H)
%         - relative bandwidth of the amplification spectrum (betaS)
%         - grid data of viscosity ratio  values (VRatio)
%         - grid data of the stretch values (Stretch)

% Range
n           = 30;

% Define the variable
alp         = sqrt(1/power_law_layer);
bet         = sqrt(1-1/power_law_layer);
rd          = sqrt(power_law_layer-1);

% Ratio
rat         = sqrt(power_law_layer/power_law_matrix);
% Tested stretch range
ess         = linspace(0.4,0.95,n);
% Tested viscosity ratio range
rs          = logspace(0.3,2.5,n);
% Tested wavenumber range
kk0         = linspace(0.01,10,1000);

% Create a grid of strain and viscosity ratio values
[Stretch, VRatio]   = ndgrid(ess,rs);

% Initialization
Lp2H        = zeros(size(Stretch));     % Arc length to thickness ratio (Lp/h)
betaS       = zeros(size(Stretch));     % Relative bandwidth (b*)
amaxs       = zeros(size(Stretch));     % Amplification spectra

R           = 1./rs;

% Loop on S and R
for ii = 1:n
    
    S    = ess(ii);  % Choose a strain value
    tfin =-log(S);   
    dt   = tfin/100;
    t     = linspace(0,tfin-dt);
    k     = kk0'*exp(2*t);  % Evolution of wavenumber with time
    
    temp1 = (rd./(2*sin(bet*k)));
    temp2 = temp1.*(exp(alp*k)-1./exp(alp*k));
    temp3 = 2*temp1.*(exp(alp*k)+1./exp(alp*k));
    
    for jj = 1:n
        
        Q     = R(jj)*rat;
        denn  = (1-Q^2)-((1+Q^2).*temp2 + Q.*temp3);
        
        qqq   = 1-2*power_law_layer.*(1-R(jj))./denn;
        ks    = kk0*exp(2*tfin);
        lamps = sum(qqq,2).*dt;
        
        % Operate on amplification spectrum at shortening S
        amps                = exp(lamps');
        [amaxs(ii,jj),imax] = max(amps);
        Lp2H(ii,jj)         = 2*pi/ks(imax); % Find Lp/H
        
        % Find the relative bandwidth of the amplification spectrum
        if amaxs(ii,jj) < 2000
            left = amps(1:imax);
            rght = amps(imax:end);
            
            try 
                ksleft = interp1(left,ks(1:imax),  0.5*amaxs(ii,jj));
            catch
                betaS(ii,jj) = NaN;
            end
    
            try
                ksrhgt = interp1(rght,ks(imax:end),0.5*amaxs(ii,jj));
            catch
                betaS(ii,jj) = NaN;
            end
            
            betaS(ii,jj)   = abs(ksrhgt-ksleft)/ks(imax);
        else
            betaS(ii,jj) = NaN;
        end
        
    end
end