function T = thermal2d(ELEM2NODE, Phases, GCOORD, D, Bc_ind, Bc_val, nip)
% THERMAL2D Two dimensional finite element thermal problem solver of MILAMIN

%   Part of MILAMIN: MATLAB-based FEM solver for large problems, Version 1.0
%   Copyright (C) 2007, M. Dabrowski, M. Krotkiewski, D.W. Schmid
%   University of Oslo, Physics of Geological Processes
%   http://milamin.org

%==========================================================================
% MODEL INFO
%==========================================================================
nnod         = size(GCOORD,2);
nnodel       = size(ELEM2NODE,1);
nel          = size(ELEM2NODE,2);

%==========================================================================
% CONSTANTS
%==========================================================================
ndim         =   2;
nelblo       = 760;

%==========================================================================
% BLOCKING PARAMETERS (nelblo must be < nel)
%==========================================================================
nelblo       = min(nel, nelblo);
nblo         = ceil(nel/nelblo);

%==========================================================================
% PREPARE INTEGRATION POINTS & DERIVATIVES wrt LOCAL COORDINATES
%==========================================================================
[IP_X, IP_w] = ip_triangle;                   
[N dNdu]     = shp_deriv_triangle(IP_X);   

%==========================================================================
% DECLARE VARIABLES (ALLOCATE MEMORY)
%==========================================================================
K_all        = zeros(nnodel*(nnodel+1)/2,nel); 
Rhs          = zeros(nnod,1);

%==========================================================================
% INDICES EXTRACTING LOWER PART
%==========================================================================
indx_l       = tril(ones(nnodel)); indx_l = indx_l(:); indx_l = indx_l==1;


%==================================================================
% DECLARE VARIABLES (ALLOCATE MEMORY)
%==================================================================
K_block     = zeros(nelblo,nnodel*(nnodel+1)/2);
invJx       = zeros(nelblo, ndim);
invJy       = zeros(nelblo, ndim);
il          = 1;
iu          = nelblo;

%==================================================================
% i) BLOCK LOOP - MATRIX COMPUTATION
%==================================================================
for ib = 1:nblo
    %==============================================================
    % ii) FETCH DATA OF ELEMENTS IN BLOCK
    %==============================================================
    ECOORD_x = reshape( GCOORD(1,ELEM2NODE(:,il:iu)), nnodel, nelblo);
    ECOORD_y = reshape( GCOORD(2,ELEM2NODE(:,il:iu)), nnodel, nelblo);
    ED       = reshape(D(Phases(il:iu)),nelblo,1);
    
    %==============================================================
    % iii) INTEGRATION LOOP
    %==============================================================
    K_block(:)  = 0;
    for ip=1:nip
        %==========================================================
        % iv) LOAD SHAPE FUNCTIONS DERIVATIVES FOR INTEGRATION POINT
        %==========================================================
        dNdui       = dNdu{ip};
        
        %==========================================================
        % v) CALCULATE JACOBIAN, ITS DETERMINANT AND INVERSE
        %==========================================================
        Jx          = ECOORD_x'*dNdui;
        Jy          = ECOORD_y'*dNdui;
        detJ        = Jx(:,1).*Jy(:,2) - Jx(:,2).*Jy(:,1);
        
        invdetJ     = 1.0./detJ;
        invJx(:,1)  = +Jy(:,2).*invdetJ;
        invJx(:,2)  = -Jy(:,1).*invdetJ;
        invJy(:,1)  = -Jx(:,2).*invdetJ;
        invJy(:,2)  = +Jx(:,1).*invdetJ;
        
        %==========================================================
        % vi) DERIVATIVES wrt GLOBAL COORDINATES
        %==========================================================
        dNdx        = invJx*dNdui';
        dNdy        = invJy*dNdui';
        
        %==========================================================
        % vii) NUMERICAL INTEGRATION OF ELEMENT MATRICES
        %==========================================================
        weight      = IP_w(ip)*detJ.*ED;
        
        indx = 1;
        for i = 1:nnodel
            for j = i:nnodel
                K_block(:,indx)  =   K_block(:,indx) + ...
                    (dNdx(:,i).*dNdx(:,j)+ dNdy(:,i).*dNdy(:,j)).*weight;
                indx = indx + 1;
            end
        end
    end
    %==============================================================
    % ix) WRITE DATA INTO GLOBAL STORAGE
    %==============================================================
    K_all(:,il:iu)	= K_block';
    
    %==============================================================
    % READJUST START, END AND SIZE OF BLOCK. REALLOCATE MEMORY
    %==============================================================
    il  = il+nelblo;
    if(ib==nblo-1)
        nelblo 	= nel-iu;
        K_block	= zeros(nelblo, nnodel*(nnodel+1)/2);
        invJx   = zeros(nelblo, ndim);
        invJy   = zeros(nelblo, ndim);
    end
    iu  = iu+nelblo;
end

%==========================================================================
% ix) CREATE TRIPLET FORMAT INDICES
%==========================================================================
indx_j = repmat(1:nnodel,nnodel,1); indx_i = indx_j';
indx_i = tril(indx_i); indx_i = indx_i(:); indx_i = indx_i(indx_i>0);
indx_j = tril(indx_j); indx_j = indx_j(:); indx_j = indx_j(indx_j>0);

K_i = ELEM2NODE(indx_i,:); K_i = K_i(:); 
K_j = ELEM2NODE(indx_j,:); K_j = K_j(:);

indx       = K_i < K_j;
tmp        = K_j(indx);
K_j(indx)  = K_i(indx);
K_i(indx)  = tmp;

%==========================================================================
% x) CONVERT TRIPLET DATA TO SPARSE MATRIX
%==========================================================================
K_all  = K_all(:);
K      = sparse(K_i, K_j, K_all);
clear K_i K_j K_all;

%==========================================================================
% BOUNDARY CONDITIONS
%==========================================================================
Free        = 1:nnod;
Free(Bc_ind)= [];
% TMP         = K(:,Bc_ind) + cs_transpose(K(Bc_ind,:));
TMP         = K(:,Bc_ind) + K(Bc_ind,:)';
Rhs         = Rhs -  TMP*Bc_val';  
K           = K(Free,Free);

%==========================================================================
% REORDERING
%==========================================================================
perm = amd(K);

%==========================================================================
% FACTORIZATION - ideally L = lchol(K, perm)
%==========================================================================
% K = cs_transpose(K);
% K = cs_symperm(K,perm);
% K = cs_transpose(K);
[L,s,perm] = chol(K,'lower','vector');
% L = chol(K,'lower');
Lt = L';
%==========================================================================
% SOLVE
%==========================================================================
T             = zeros(nnod,1);
T(Bc_ind)     = Bc_val;
% T(Free(perm)) = cs_ltsolve(L,cs_lsolve(L,Rhs(Free(perm))));
T(Free(perm)) = Lt\(L\Rhs(Free(perm)));

end

function [ipx, ipw] = ip_triangle
%IP_TRIANGLE Integration rules (points & weights) for triangular elements

%   Part of MILAMIN: MATLAB-based FEM solver for large problems, Version 1.0
%   Copyright (C) 2007, M. Dabrowski, M. Krotkiewski, D.W. Schmid
%   University of Oslo, Physics of Geological Processes
%   http://milamin.org

% see e.g.: 
% Dunavant, D. A. 1985. High-Degree efficient symmetrical Gaussian quadrature rules for the triangle. Int. J. Numer. Methods Eng. 21, 6, 1129--1148.

ipx(1,1) = 1/6;
ipx(1,2) = 1/6;
ipx(2,1) = 2/3;
ipx(2,2) = 1/6;
ipx(3,1) = 1/6;
ipx(3,2) = 2/3;

ipw(1) = 1/6;
ipw(2) = 1/6;
ipw(3) = 1/6;
end

function [N2, dNdu2] = shp_deriv_triangle(ipx2)

%   Part of MILAMIN: MATLAB-based FEM solver for large problems, Version 1.0
%   Copyright (C) 2007, M. Dabrowski, M. Krotkiewski, D.W. Schmid
%   University of Oslo, Physics of Geological Processes
%   http://milamin.org

nip2  = size(ipx2,1);
N2    = cell(nip2,1);
dNdu2 = cell(nip2,1);

for i=1:nip2
    eta2 = ipx2(i,1);
    eta3 = ipx2(i,2);
    eta1 = 1-eta2-eta3;
    
    SHP   = [eta1; ...
             eta2; ...
             eta3];
    DERIV = [-1 1 0; ...   %w.r.t eta2
             -1 0 1];      %w.r.t eta3
    N2{i} = SHP;
    dNdu2{i} = DERIV';
    
end
end