function [Tu,Tl,Pu,Pl] = thickness(Xu,Yu,Xl,Yl,Iu,Il)
% FGT - Fold Geometry Toolbox
% 
% Original author:    Adamuszek
% Last committed:     $Revision: 135 $
% Last changed by:    $Author: martaada $
% Last changed date:  $Date: 2011-06-01 14:15:19 +0200 (Wed, 01 Jun 2011) $
%--------------------------------------------------------------------------
% 
% Calculates the local thicknesses of the fold train.
%
% input  - x and y coordinates of upper and lower fold interfaces (Xu, Yu,
%          Xl, Yl)
%        - position of inflection points on the upper and lower interfaces
%         (Iu, Il)
% output - thickness of an individal fold calculated based on the
%          position of the inflection points on the upper and lower
%          interfaces (Tu, Tl)
%        - contours of each fold, where fold train is divided based on the
%          position of the inflection points on the upper and lower 
%          interfaces (Pu, Pl)

tol = 5e-6; % tolerace value

% Find and delete points that too close to each other
delu = 1;
while ~isempty(delu)
    delu     = find(sqrt(diff(Xu).^2+diff(Yu).^2)<tol);
    Xu(delu) = [];
    Yu(delu) = [];
    
    % Update the positions of inflection points
    for i = 1:length(delu)
        Iu(Iu>delu(i)) = Iu(Iu>delu(i))-1;
        if find(Iu == delu(i)==1)
            Iu(Iu==delu(i)) = Iu(Iu==delu(i))+1;
        end
    end
end

% Find and delete points that too close to each other
dell = 1;
while ~isempty(dell)
    dell     = find(sqrt(diff(Xl).^2+diff(Yl).^2)<tol);
    Xl(dell) = [];
    Yl(dell) = [];
    
    % Update the positions of inflection points
    for i = 1:length(dell)
        Il(Il>dell(i)) = Il(Il>dell(i))-1;
        if find(Il == dell(i)==1)
            Iu(Il==dell(i)) = Il(Il==dell(i))+1;
        end
    end
end
% Initialize the output
Tu = zeros(1,length(Iu)-1);
Tl = zeros(1,length(Il)-1);

% One array of points
X  = [Xl fliplr(Xu)];
Y  = [Yl fliplr(Yu)];

% Input to mesh generator
n    = length(X);
node = [X', Y'];
edge = [1:n; [2:n,1]]';

hdata.hmax     = 0.5;
options.output = false;

warning('off', 'MATLAB:tsearch:DeprecatedFunction')
warning('off', 'MATLAB:delaunayn:DuplicateDataPoints')

% Create mesh
[GCOORD,ELEM2NODE,t] = mesh2d(node,edge,hdata,options);

% Transform data
GCOORD    = GCOORD';
ELEM2NODE = ELEM2NODE';

nel    = size(ELEM2NODE,2);
nnode  = size(GCOORD,2);
Phases = ones(nel,1);

% Define tringle's segments
EE    = [[ELEM2NODE(1,:);ELEM2NODE(2,:)], [ELEM2NODE(1,:);ELEM2NODE(3,:)], [ELEM2NODE(2,:);ELEM2NODE(3,:)]];
EE    = sort(EE,1);
K     = sparse(EE(1,:)',EE(2,:)',ones(size(EE,2),1));

% Find boundary segments - segments that are not sheared between two triangles
[a,b]     = find(K==1);
bdry_segm = [a,b];

% -------------------------------------------------------------------------
% find boundaries (segments and nodes)
% -------------------------------------------------------------------------
% initialize output variables
node_order = {};    % node list for every boundary found
segs_order = {};    % segment list for every boundary found
nsegs = 0;          % total number of segments
nbdrs = 1;          % number of boundaries found

% create connectivity graph for boundary nodes - full structure
Sgraph = sparse([bdry_segm(:,1) bdry_segm(:,2)], [bdry_segm(:,2) bdry_segm(:,1)], ...
    [1:size(bdry_segm,1) 1:size(bdry_segm,1)]);

while length(bdry_segm)~=0
    
    % start with first available boundary node id
    nid = bdry_segm(1,1);
    
    % find boundary nodes connected to node nid
    % gaimc, http://www.mathworks.com/matlabcentral/fileexchange/24134
    bnodes = dfs(Sgraph,nid)';
    [bnodes perm] = sort(bnodes);
    bnodes = perm(sum(bnodes==-1)+1:end);

    % bioinformatics toolbox
    % bnodes = graphtraverse(Sgraph, nid, 'METHOD', 'DFS');
    
    % find segments to which bnodes belong
    bsegs = triu(Sgraph(bnodes,bnodes));
    bsegs = full(bsegs(bsegs>0));
    
    % remove visited segments from boundary segment list
    bdry_segm(bsegs-nsegs,:) = [];
    
    % store results
    node_order{nbdrs} = bnodes;
    segs_order{nbdrs} = bsegs';
    nsegs = nsegs + length(bsegs);
    nbdrs = nbdrs+1;
end
% -------------------------------------------------------------------------

order = node_order{1};

% Define the fold boundaries
stop = find(GCOORD(1,:) == Xu(1)   & GCOORD(2,:) == Yu(1));
etop = find(GCOORD(1,:) == Xu(end) & GCOORD(2,:) == Yu(end));
sbot = find(GCOORD(1,:) == Xl(1)   & GCOORD(2,:) == Yl(1));
ebot = find(GCOORD(1,:) == Xl(end) & GCOORD(2,:) == Yl(end));

% Find the first node of the upper interface
shift = find(order == stop);
if shift ~= 1
    order = [order(shift:end), order(1:shift-1)];
end
top = order(find(order==stop):find(order==etop));

% Check if the direction of order is clockwise
tes = find( GCOORD(1,:) == Xu(2) & GCOORD(2,:) == Yu(2) );
if ismember(tes,top) == 0;
    order = [order(1) fliplr(order(2:end))];
    top   = order(find(order==stop):find(order==etop));
end

% Fold boundaries
left = order(find(order==etop):find(order==ebot));
bot  = fliplr(order(find(order==ebot):find(order==sbot)));
rght = [order(find(order==sbot):end) order(1)];

% Boundary conditions
Bc_ind = [left rght];
Bc_val = [1*ones(size(left)) 0*ones(size(rght))];

% Solving laplace equation
T   = thermal2d(ELEM2NODE, Phases, GCOORD, 1, Bc_ind, Bc_val, 3);

% Define temperature on the upper and lower interface
Ttop = T(top);
Tbot = T(bot);

% Reevaluate fold coordinates and inflection points (since new points were added)
Xl2 = GCOORD(1,bot); Yl2 = GCOORD(2,bot);
Xu2 = GCOORD(1,top); Yu2 = GCOORD(2,top);
Iu2 = zeros(size(Iu));
Il2 = zeros(size(Il));
for i = 1:length(Iu)
    Iu2(i) = find(GCOORD(1,top) == Xu(Iu(i)) & GCOORD(2,top) == Yu(Iu(i)));
end
for i = 1:length(Il)
    Il2(i) = find(GCOORD(1,bot) == Xl(Il(i)) & GCOORD(2,bot) == Yl(Il(i)));
end

% Define the arc lenght of upper and lower interface
Arc_lower = [0 cumsum(sqrt(diff(Xl2).^2+diff(Yl2).^2))];
Arc_upper = [0 cumsum(sqrt(diff(Xu2).^2+diff(Yu2).^2))];

% Define the corresponding points on the lower interface
Al = interp1(Tbot, Arc_lower', Ttop(Iu2));
Xll= interp1(Arc_lower, Xl2, Al);
Yll= interp1(Arc_lower, Yl2, Al);

 for i = 1:length(Iu)-1
    
    Pu{i} = [Xu2(Iu2(i):Iu2(i+1)), Xll(i+1) fliplr(Xl2((Arc_lower>Al(i)& Arc_lower<Al(i+1)))) Xll(i) ; ...
             Yu2(Iu2(i):Iu2(i+1)), Yll(i+1) fliplr(Yl2((Arc_lower>Al(i)& Arc_lower<Al(i+1)))) Yll(i) ];
    
    Au(i) = polyarea([Xu2(Iu2(i):Iu2(i+1)), Xll(i+1) fliplr(Xl2((Arc_lower>Al(i)& Arc_lower<Al(i+1)))) Xll(i) ] ,...
                     [Yu2(Iu2(i):Iu2(i+1)), Yll(i+1) fliplr(Yl2((Arc_lower>Al(i)& Arc_lower<Al(i+1)))) Yll(i) ]);
    
	% Calculate the arc length of fold train
    a1 = Arc_upper(Iu2(i+1)) - Arc_upper(Iu2(i));
    a2 = Al(i+1) - Al(i);
    
    % Calculate the thickness (divide the fold area by the average arc length)
    Tu(i) = Au(i)/((a1+a2)/2);

end

% Define the corresponding points on the upper interface
Au = interp1(Ttop, Arc_upper, Tbot(Il2));
Xuu= interp1(Arc_upper, Xu2, Au);
Yuu= interp1(Arc_upper, Yu2, Au);

for i = 1:length(Il)-1
    
    Pl{i} = [Xl2(Il2(i):Il2(i+1)), Xuu(i+1) fliplr(Xu2((Arc_upper>Au(i)& Arc_upper<Au(i+1)))) Xuu(i) ; ...
             Yl2(Il2(i):Il2(i+1)), Yuu(i+1) fliplr(Yu2((Arc_upper>Au(i)& Arc_upper<Au(i+1)))) Yuu(i) ];
    
    Al(i) = polyarea([Xl2(Il2(i):Il2(i+1)), Xuu(i+1) fliplr(Xu2((Arc_upper>Au(i)& Arc_upper<Au(i+1)))) Xuu(i) ] ,...
                     [Yl2(Il2(i):Il2(i+1)), Yuu(i+1) fliplr(Yu2((Arc_upper>Au(i)& Arc_upper<Au(i+1)))) Yuu(i) ]);
    
    % Calculate the arc length of fold train
    a1 = Arc_lower(Il2(i+1)) - Arc_lower(Il2(i));
    a2 = Au(i+1) - Au(i);
    
    % Calculate the thickness (divide the fold area by the average arc length)
    Tl(i) = Al(i)/((a1+a2)/2);

end
          
