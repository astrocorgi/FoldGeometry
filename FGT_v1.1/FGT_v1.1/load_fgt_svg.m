function Fold = load_fgt_svg(xmlfile)
% FGT - Fold Geometry Toolbox
%
% Original author:    Krotkiewski
% Last committed:     $Revision: 135 $
% Last changed by:    $Author: martaada $
% Last changed date:  $Date: 2011-06-01 14:15:19 +0200 (Wed, 01 Jun 2011) $
%--------------------------------------------------------------------------
%
% Converts *.svg files to *.mat data.
% 
% input  - *.svg file generated in Adobe Illustrator (xmlfile)
% output - fold data stored in a matlab stucture - Fold


% Open the file
fd      = fopen(xmlfile, 'r');
if fd == -1
    error(['could not open file ' xmlfile]);
    return;
end

% Read data
fseek(fd, 0, 1);
fs   = ftell(fd);
fseek(fd, 0, -1);
data = fread(fd, fs, 'uint8=>char')';

% Identify number of layers and find starting and ending indexes
[start_layer_idx, end_layer_idx] = regexp(data, '<(\g id=").*?>.*?</\g>');
if isempty(start_layer_idx)
    nlayers = 1;
else
    nlayers = size(start_layer_idx,2);
end

% Count number of folds
count = 0;

for j = 1:nlayers
    
    % Extract data for each layer
    if isempty(start_layer_idx)
        data_layer = data;
    else
        data_layer = data(start_layer_idx(j):end_layer_idx(j));
    end
    
    % Extract data for the lines
    [start_idx, end_idx] = regexp(data_layer, '<polyline fill=[^>]+/>');
    
    if isempty(start_idx)
        continue;
    end
    
    % Change form string to a vector
    paths = {};
    for p = 1:length(start_idx)
        pdata    = data_layer(start_idx(p):end_idx(p));
        [tokens] = regexp(pdata, 'points=\"([^\"]+)\"', 'tokens');
        
        if isempty(tokens)
            error('No data found in path');
            return;
        end
        
        pdata = [tokens{1}{1}];
        [tokens] = regexp(pdata, '([^ ]+)', 'tokens');
        paths{p} = [];
        
        for i=1:length(tokens)
            paths{p} = [paths{p}; str2num(tokens{i}{1})];
        end
        
    end
    
    % Assign the data to faces in the fold
    count      = count + 1;
    fold_up    = paths{1};
    fold_dn    = paths{2};
    Fold(count).Face(1).X.Ori = fold_up(:,1:2:end)';
    Fold(count).Face(1).Y.Ori = fold_up(:,2:2:end)';
    Fold(count).Face(2).X.Ori = fold_dn(:,1:2:end)';
    Fold(count).Face(2).Y.Ori = fold_dn(:,2:2:end)';
    
end

