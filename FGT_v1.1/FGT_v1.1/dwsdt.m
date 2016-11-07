function [X, Y, Status]  = dwsdt(varargin)
% FGT - Fold Geometry Toolbox
%
% Original author:    Schmid
% Last committed:     $Revision: 76 $
% Last changed by:    $Author: martaada $
% Last changed date:  $Date: 2011-02-21 13:35:01 +0100 (ma, 21 feb 2011) $
%--------------------------------------------------------------------------
%
% DWSDT - Digitization Tool
%
% Points are set by left clicking.
% The digitization is finished when any of the following are pressed:
% return, enter, escape, any mouse buttong but left, mouse double click
%
% Allows for
%  zoom in (+), zoom out (-), pan (space bar + mouse movement)
%
% Similar to Image Toolbox getpts, from which part of the design was taken.
%
% 2011-04-20, Dani Schmid

%% GLOBAL VARIABLES
global dwsdt_fig dwsdt_ax dwsdt_line

%% DEAL WITH INPUT ARGUMENTS
if ((nargin >= 1) && (ischar(varargin{1})))
    % Callback invocation: 'KeyPress', 'FirstButtonDown', or
    % 'ButtonDown'.
    feval(varargin{:});
    return;
end

if (nargin < 1)
    dwsdt_ax = gca;
    dwsdt_fig = ancestor(dwsdt_ax, 'figure');
else
    if (~ishghandle(varargin{1}))
        eid = 'dwsdt:expectedHandle';
        error(eid, '%s', 'First argument is not a valid handle');
    end
    
    switch get(varargin{1}, 'Type')
        case 'figure'
            dwsdt_fig = varargin{1};
            dwsdt_ax = get(dwsdt_fig, 'CurrentAxes');
            if (isempty(dwsdt_ax))
                dwsdt_ax = axes('Parent', dwsdt_fig);
            end
            
        case 'axes'
            dwsdt_ax = varargin{1};
            dwsdt_fig = ancestor(dwsdt_ax, 'figure');
            
        otherwise
            eid = 'dwsdt:expectedFigureOrAxesHandle';
            error(eid, '%s', 'First argument should be a figure or axes handle');
            
    end
end

%% PUT FIGURE AND AXES INTO DIGITIZING MODE
%  Bring target figure forward
figure(dwsdt_fig);

%  Remember initial figure state
state = uisuspend(dwsdt_fig);

%  Set up initial callbacks for initial stage
set(dwsdt_fig, ...
    'WindowButtonDownFcn', @(a,b) dwsdt('ButtonDown'), ...
    'KeyPressFcn',         @(a,b) dwsdt('KeyPress'), ...
    'Pointer',             'cross');

%  Store original size of axes
setappdata(dwsdt_ax, 'Xlim', get(dwsdt_ax, 'XLim'));
setappdata(dwsdt_ax, 'Ylim', get(dwsdt_ax, 'YLim'));

%% CREATE LINE OBJECT
dwsdt_line = line('Parent', dwsdt_ax, ...
    'XData', [], ...
    'YData', [], ...
    'Visible', 'on', ...
    'Clipping', 'off', ...
    'LineStyle', '-', ...
    'Color', 'r', ...
    'Marker', 'o', ...
    'MarkerEdgeColor', 'k', ...
    'MarkerFaceColor', 'none');

%% WAITFOR ON dwsdt_line
%  Note: In newer releases of Matlab this try-catch statement is basically
%  obsolete as it was designed to catch CTRL-C, but this does not work
%  anymore since MATLAB 6.5 (R13).
%  Works for figure closure.
errCatch = 0;
try
    waitfor(dwsdt_line, 'UserData');
catch err
    errCatch=1;
end

%% FINISH
%  After waitfor, if dwsdt_line is still valid
%  and its UserData is 'Done', then the user
%  completed the digitization.
%  If not, the user interrupted the action,
%  perhaps by a Ctrl-C in the command window or by closing the figure.

if errCatch==1
    Status      = err.message;
    X           = [];
    Y           = [];
    
elseif ~exist('dwsdt_line', 'var') || ~ishghandle(dwsdt_line)
    Status      = 'Line object disappeared';
    X           = [];
    Y           = [];
    
elseif strcmp(get(dwsdt_line, 'UserData'), 'Done')
    Status      = 'Done';
    X           = get(dwsdt_line, 'XData');
    Y           = get(dwsdt_line, 'YData');

else
    Status      = 'Abort';
    X           = [];
    Y           = [];

end

% Delete the line object
if ishghandle(dwsdt_line)
    delete(dwsdt_line);
end

% Restore the figure state
if ishghandle(dwsdt_fig)
    uirestore(state);
end

% Clean up the global workspace
clear global dwsdt_fig dwsdt_ax dwsdt_line

end

%% - fun KeyPress
function KeyPress

global dwsdt_fig dwsdt_ax dwsdt_line

key = get(dwsdt_fig, 'CurrentCharacter');
switch key
    case {char(8), char(127)}  % delete and backspace keys
        X = get(dwsdt_line, 'XData');
        Y = get(dwsdt_line, 'YData');
        switch length(X)
            case 0
                % nothing to do
            otherwise
                % remove last point
                set(dwsdt_line, ...
                    'XData', X(1:end-1), ...
                    'YData', Y(1:end-1));
        end
        
    case {char(13), char(3)}   % enter, return keys
        % return control to line after waitfor
        set(dwsdt_line, 'UserData', 'Done');

    case char(27)   % escape key
        % return control to line after waitfor
        set(dwsdt_line, 'UserData', 'Abort');
    
    case '+'
        zoom(dwsdt_fig, 2);
        
    case '-'
        zoom(dwsdt_fig, .5);
        
    case ' '
        % PAN
        
        % Figure out if zoom is active
        % 'not sure how this is done best, I have not found a way to query
        % the zoom state. Hence, query xlim and ylim.
        Xlim        = get(dwsdt_ax, 'XLim');
        Ylim        = get(dwsdt_ax, 'YLim');
        Xlim_ori    = getappdata(dwsdt_ax, 'Xlim');
        Ylim_ori    = getappdata(dwsdt_ax, 'Ylim');
        
        if all(Xlim==Xlim_ori) && all(Ylim==Ylim_ori)
            % No zoom -> nothing to do
            return;
        else
            % Deactivate the drawing modus
            set(dwsdt_fig, ...
                'WindowButtonDownFcn', [], ...
                'KeyPressFcn',         []);
            
            % Activate Panning
            set(dwsdt_fig, 'WindowButtonMotionFcn', @(a,b) dwsdt('Pan'));
            
            % Release Function
            set(dwsdt_fig, 'KeyReleaseFcn', @(a,b) dwsdt('PanStop'));
            
        end
end
end

%% - fun Pan
function Pan

global  dwsdt_ax

% Reference Point
Point_reference     = getappdata(dwsdt_ax, 'Point_reference');

% Current Point
Point_current       = get(dwsdt_ax, 'CurrentPoint');
Point_current       = Point_current(1,1:2);

if isempty(Point_reference)
    % Store Reference Point
    setappdata(dwsdt_ax, 'Point_reference', Point_current);
else
    % Movement
    Move                = -Point_current+Point_reference;
    
    % Axes Limits
    Xlim        = get(dwsdt_ax, 'XLim');
    Ylim        = get(dwsdt_ax, 'YLim');
    Xlim_ori    = getappdata(dwsdt_ax, 'Xlim');
    Ylim_ori    = getappdata(dwsdt_ax, 'Ylim');
    
    % Limit the move
    if Move(1)>0
        Move(1)     = min(Xlim_ori(2)-Xlim(2), Move(1));
    else
        Move(1)     = max(Xlim_ori(1)-Xlim(1), Move(1));
    end
    
    if Move(2)>0
        Move(2)     = min(Ylim_ori(2)-Ylim(2), Move(2));
    else
        Move(2)     = max(Ylim_ori(1)-Ylim(1), Move(2));
    end
    
    % Adjust Limits
    set(dwsdt_ax, 'XLim', Xlim+Move(1), 'YLim', Ylim+Move(2));
end

end

%% - fun PanStop
function PanStop

global dwsdt_fig dwsdt_ax

% Remove Reference Point
setappdata(dwsdt_ax, 'Point_reference', []);

% Deactivate Mouse follow
set(dwsdt_fig, 'WindowButtonMotionFcn', []);

% Key Release not required any longer
set(dwsdt_fig, 'KeyReleaseFcn', []);

% Activate the standard digitizing callbacks
set(dwsdt_fig, ...
    'WindowButtonDownFcn', @(a,b) dwsdt('ButtonDown'), ...
    'KeyPressFcn',         @(a,b) dwsdt('KeyPress'));
end

%% - fun ButtonDown
function ButtonDown

global dwsdt_fig dwsdt_ax dwsdt_line

selectionType = get(dwsdt_fig, 'SelectionType');
if strcmp(selectionType, 'normal')
    % Normal single click
    
    % Get current point
    Point   = get(dwsdt_ax, 'CurrentPoint');
    Point   = Point(1,1:2);
    
    % Previous points
    X       = get(dwsdt_line, 'XData');
    Y       = get(dwsdt_line, 'YData');
    
    % Check if new point is identical to previous one
    if ~isempty(X) && X(end)==Point(1) && Y(end)==Point(2)
        return
    end
    
    set(dwsdt_line, 'XData', [X Point(1)], 'YData', [Y Point(2)]);
    
elseif strcmp(selectionType, 'open')
    % Double click - simply ingore, may be unintentional
    
else
    % Other than left mouse button or some key combo - Done
    dwsdt('Finish');
end
end

function Finish

global dwsdt_line

% This function may be called from the outside to abort possible
% digitization action - check if line object actually exists
if ishghandle(dwsdt_line)
    set(dwsdt_line, 'UserData', 'Done');
end
end