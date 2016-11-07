function fgt(Action)
% FGT - Fold Geometry Toolbox
%
% Original author:    Schmid
% Last committed:     $Revision: 136 $
% Last changed by:    $Author: martaada $
% Last changed date:  $Date: 2011-06-25 20:02:43 +0200 (Sat, 25 Jun 2011) $
%--------------------------------------------------------------------------

%% INPUT CHECK
if nargin==0
    Action = 'initialize';
end

%% FIND GUI
fgt_gui_handle = findobj(0, 'tag', 'fgt_gui_handle');

switch lower(Action)
    case 'initialize'
        %% INITIALIZE
        
        %  Add current path
        addpath(pwd);
        
        %  Assert that mesh2d is installed
        assert_install('mesh2d.m', 'mesh2d', 'MESH2D - Automatic Mesh Generation by Darren Engwirda', 'http://www.mathworks.com/matlabcentral/fileexchange/25555-mesh2d-automatic-mesh-generation?controller=file_infos&download=true');
       
        %  Assert that gaim is installed
        assert_install('dfs.m', 'gaimc', 'gaimc : Graph Algorithms In Matlab Code by David Gleich', 'http://www.mathworks.com/matlabcentral/fileexchange/24134-gaimc-graph-algorithms-in-matlab-code?controller=file_infos&download=true');
        
        %  Assert that selfintersect is installed
        assert_install('selfintersect.m', 'selfintersect', 'Fast and Robust Self-Intersections by Antoni J. Canós', 'http://www.mathworks.com/matlabcentral/fileexchange/13351-fast-and-robust-self-intersections?controller=file_infos&download=true');
   
        %  Delete figure if it already exists
        if ~isempty(fgt_gui_handle)
            delete(fgt_gui_handle);
        end
        
        %  Figure Setup
        Screensize      = get(0, 'ScreenSize');
        x_res           = Screensize(3);
        y_res           = Screensize(4);
        frac            = 10;
        
        fgt_gui_handle = figure(...
            'Units', 'pixels','pos', round([x_res/frac y_res/frac x_res/frac*(frac-2)  y_res/frac*(frac-2)]),...
            'Name', 'Fold Geometry Toolbox by M. Adamuszek, D. W. Schmid, & M. Dabrowski', 'tag', 'fgt_gui_handle',...
            'NumberTitle', 'off', 'ToolBar', 'none',  'DockControls', 'off','MenuBar', 'none', ...
            'Color', get(0, 'DefaultUipanelBackgroundColor'),...
            'Units', 'Pixels', ...
            'WindowButtonDownFcn', @(a,b) fgt('step_1_load'), ...
            'Renderer', 'zbuffer'); %zbuffer so that contour plots work
        
        %  File
        h1  = uimenu('Parent',fgt_gui_handle, 'Label','File');
        %  Load
        uimenu('Parent',h1, 'Label', 'Load Data', ...
            'Callback', @(a,b) fgt('step_1_load'), 'Separator','off', 'enable', 'on', 'Accelerator', 'L');
        %  Save
        uimenu('Parent',h1, 'Label', 'Save Data', ...
            'Callback', @(a,b) fgt('save'), 'Separator','off', 'enable', 'on', 'Accelerator', 'S');
        %  Export
        uimenu('Parent',h1, 'Label', 'Export Data', ...
            'Callback', @(a,b) fgt('export_workspace'), 'Separator','off', 'enable', 'on', 'Accelerator', 'E');
        %  Exit
        uimenu('Parent',h1, 'Label', 'Exit', ...
            'Callback', @(a,b) close(gcf), 'Separator','off', 'enable', 'on', 'Accelerator', 'Q');

        %  Help
        h1  = uimenu('Parent',fgt_gui_handle, 'Label','Help');
        uimenu('Parent',h1, 'Label', 'Help', ...
            'Callback', @(a,b) fgt('help'), 'Separator','off', 'enable', 'on', 'Accelerator', 'H');
        
        %  Default Uicontrol Size
        DefaultUicontrolPosition = get(0, 'DefaultUicontrolPosition');
        b_height                 = DefaultUicontrolPosition(4);
        b_width                  = DefaultUicontrolPosition(3);
        
        %  Gap
        gap                    	= 5;
        
        %  Save default sizes in figure
        setappdata(fgt_gui_handle, 'b_height', b_height);
        setappdata(fgt_gui_handle, 'b_width',  b_width);
        setappdata(fgt_gui_handle, 'gap',      gap);
        
        %  Lower Part is 4 buttons heigh + gap, upper part rest
        lpanel_height          	= 4*b_height + 4*gap + 3*gap;
        
        %  Uipanel Top
        Position_fig          	= get(fgt_gui_handle, 'Position');
        fgt_upanel_top          = uipanel('Parent', fgt_gui_handle, 'Tag', 'fgt_upanel_top',     'Title', 'Fold Geometry Toolbox', 'Units', 'Pixels', 'Position', [gap, lpanel_height+gap, Position_fig(3)-2*gap, Position_fig(4)-lpanel_height-gap]);
        
        % Uipanel Comment
        fgt_upanel_comment     	= uipanel('Parent', fgt_gui_handle, 'Tag', 'fgt_upanel_comment', 'Title', 'Comment',               'Units', 'Pixels', 'Position', [gap, gap, Position_fig(3)/5*3-1.5*gap, lpanel_height]);
        
        % Uipanel Controls
        fgt_upanel_control     	= uipanel('Parent', fgt_gui_handle, 'Tag', 'fgt_upanel_control', 'Title', 'Controls',              'Units', 'Pixels', 'Position', [Position_fig(3)/5*3+gap, gap, Position_fig(3)/5*2-2*gap, lpanel_height]);
        
        % Add Comment Field
        uicontrol('Parent', fgt_upanel_comment, 'style', 'edit', 'HorizontalAlignment', 'Left', ...
            'tag', 'uc_comment',...
            'callback',  @(a,b) fgt('comment'), ....
            'Units', 'normalized', 'Position', [0 0 1 1], ...
            'BackGroundColor', 'w', ...
            'Max', 2, 'Min', 0); %Enables multi lines
        
        % Set Units to Normalized - Resizing
        units_normalized;
        
        % Put FGT into step_1 mode
        fgt('step_1');
        
    case 'save'
        %  Get data
        Fold    = getappdata(fgt_gui_handle, 'Fold');
        
        if isempty(Fold)
            warndlg('No data to save!', 'Fold Geometry Toolbox');
            return;
        end
        
        [Filename, Pathname] = uiputfile(...
            {'*.mat'},...
            'Save as');
        
        if ~(length(Filename)==1 && Filename==0)
            save([Pathname, Filename], 'Fold');
        end
        
    case 'export_workspace'
        %  Get data
        Fold        = getappdata(fgt_gui_handle, 'Fold');
        
        % Export into workspace
        checkLabels = {'Save data named:'};
        varNames    = {'Fold'};
        items       = {Fold};
        export2wsdlg(checkLabels,varNames,items,...
            'Save FGT Data to Workspace');
        
    case 'help'
        %% HELP
        
        %  Determine where help system is
        Path_fgt        = which('fgt.m');
        Index           = findstr(filesep, Path_fgt);
        Path_fgt_help   = [Path_fgt(1:Index(end)), 'help', filesep, 'index.html'];
        
        web(Path_fgt_help, '-browser');
        
    case 'comment'
        %% COMMENT
        %  Update comment field of Fold
        Comment             = get(gco, 'String');
        Fold                = getappdata(fgt_gui_handle, 'Fold');
        Fold(1).Comment     = Comment;
        setappdata(fgt_gui_handle, 'Fold', Fold);
        
    case 'step_1'
        %% STEP_1
        
        % Put FGT into step_1 mode
        setappdata(fgt_gui_handle, 'mode', 1);
        set(fgt_gui_handle,'windowbuttonmotionfcn',[]);
        
        %  Delete all axes that may exist
        delete(findobj(fgt_gui_handle, 'type', 'axes'));
        
        %  Find and update top panel
        fgt_upanel_top  =  findobj(fgt_gui_handle, 'tag', 'fgt_upanel_top');
        set(fgt_upanel_top, 'Title', 'Input Data');
        
        %  Setup new axes
        axes('Parent', fgt_upanel_top);
        box on;
        
        %  Find the control panel
        fgt_upanel_control  = findobj(fgt_gui_handle, 'Tag', 'fgt_upanel_control');
        
        %  Delete all children
        uc_handles   = findobj(fgt_upanel_control, 'Type', 'uicontrol');
        delete(uc_handles);
        
        %  Default sizes
        b_height    = getappdata(fgt_gui_handle, 'b_height');
        b_width     = getappdata(fgt_gui_handle, 'b_width');
        gap         = getappdata(fgt_gui_handle, 'gap');
        
        %  Size of panel
        set(fgt_upanel_control, 'Units', 'Pixels');
        Position    = get(fgt_upanel_control, 'Position');
        
        %  Next Button
        uicontrol('Parent', fgt_upanel_control, 'style', 'pushbutton', 'String', 'Next', ...
            'tag', 'next', ...
            'callback', @(a,b) fgt('step_1_next'), ... %Digitization may be going on
            'position', [Position(3)-gap-b_width, gap, b_width, b_height], ...
            'enable', 'off');
        
        %  Load Button
        uicontrol('Parent', fgt_upanel_control, 'style', 'pushbutton', 'String', 'Load', ...
            'callback',  @(a,b) fgt('step_1_load'), ...
            'position', [Position(3)-gap-b_width, 2*gap+b_height, b_width, b_height]);
        
        % Set Units to Normalized - Resizing
        units_normalized;
        
        %  Update GUI in case we already have data (Back...)
        Fold    = getappdata(fgt_gui_handle, 'Fold');
        if ~isempty(Fold)
            fgt('step_1_update_gui');
        end
        
    case 'step_1_update_gui'
        %% - step_1_update_gui

        %  Activate next button
        set(findobj(fgt_gui_handle, 'tag', 'next'), 'enable', 'on');

        %  Get data
        Fold    = getappdata(fgt_gui_handle, 'Fold');
        
        %  Check if fold has comment data
        if ~isfield(Fold, 'Comment') || isempty(Fold(1).Comment)
            Fold(1).Comment    = 'Leave your comments here';
        end
        set(findobj(fgt_gui_handle, 'tag', 'uc_comment'), 'String', Fold(1).Comment);
        
        %  Find plotting axes
        achse   = findobj(fgt_gui_handle, 'type', 'axes');
        set(fgt_gui_handle, 'CurrentAxes', achse);
        cla(achse, 'reset');
        hold(achse, 'on');
        
        if ~isfield(Fold, 'PICTURE')
            %  SVG or MAT
             % Check if fold self intersects
             for fold = 1:length(Fold)
                 
                 [x0, y0, segments] = selfintersect( [Fold(fold).Face(1).X.Ori fliplr(Fold(fold).Face(2).X.Ori) Fold(fold).Face(1).X.Ori(1)] , [Fold(fold).Face(1).Y.Ori fliplr(Fold(fold).Face(2).Y.Ori) Fold(fold).Face(1).Y.Ori(1)] );
                 
                 if length(x0)>0
                     
                     % Flip data of one fold interface
                     Fold(fold).Face(2).X.Ori = fliplr(Fold(fold).Face(2).X.Ori);
                     Fold(fold).Face(2).Y.Ori = fliplr(Fold(fold).Face(2).Y.Ori);
                     
                     [x0, y0, segments] = selfintersect( [Fold(fold).Face(1).X.Ori fliplr(Fold(fold).Face(2).X.Ori)] , [Fold(fold).Face(1).Y.Ori fliplr(Fold(fold).Face(2).Y.Ori)] );
                     
                     % Save data
                     setappdata(fgt_gui_handle, 'Fold', Fold);
                     
                     if length(x0)>0
                         warndlg('The fold interface self intersects.', 'Next not possible!', 'modal');
                         break;
                     end
                     
                 end
             end
            
            %  Plot
            for i=1:length(Fold)
                fh  = fill([Fold(i).Face(1).X.Ori fliplr(Fold(i).Face(2).X.Ori)], [Fold(i).Face(1).Y.Ori fliplr(Fold(i).Face(2).Y.Ori)], 'k');
                set(fh, 'EdgeColor', [0 0 0], 'FaceColor', [.5 .5 .5]);
            end
            axis(achse, 'equal');
            box on;
            zoom(fgt_gui_handle, 'off');
            
        else
            % PICTURE
            % Need to flip image for normal axes convention
            image([1, size(Fold.PICTURE,2)], [1, size(Fold.PICTURE,1)], flipdim(Fold.PICTURE, 1), 'Parent', achse);
            set(achse,  'YDir', 'normal');
            box(achse,  'on');
            axis(achse, 'equal');
            axis(achse, 'tight');
            zoom(fgt_gui_handle, 'off');
            title(achse, {'Digitize even number of fold interfaces with at least 7 points each.', '(Return = Done, Delete = Remove Point, +/- = Zoom In/Out, Spacebar+Mouse Move = Pan, Escape = Discard Digitization)'})
            
            % Already digitized layers
            for fold=1:length(Fold)
                if isfield(Fold(fold), 'Face')
                    for face=1:length(Fold(fold).Face)
                        plot( Fold(fold).Face(face).X.Ori, Fold(fold).Face(face).Y.Ori, 'LineStyle', '-', 'Color', 'k', 'Marker', 'o', 'MarkerEdgeColor', 'k', 'MarkerFaceColor', 'w');
                    end
                end
            end
            
            mode    = 1;
            fold    = length(Fold);
            if isfield(Fold(fold), 'Face')
                face    = length(Fold(fold).Face);
            else
                face    = 0;
            end
            while mode==1 && isfield(Fold, 'PICTURE') % It could be that we are back in mode 1 but have loaded non-picture data
                [X,Y, Status]   = dwsdt();
               
                % It is possible that the Next button was pressed and the
                % GUI is on the second page
                % Only process if still on first page
                mode = getappdata(fgt_gui_handle, 'mode');
                
                if mode == 1
                    if ~isempty(X) && strcmp(Status, 'Done')
                        % Add new interface
                        face = face + 1;
                        if face>2
                            face    = 1;
                            fold    = fold+1;
                        end

                        Fold(fold).Face(face).X.Ori = X;
                        Fold(fold).Face(face).Y.Ori = Y;
                        
                        %  Adding more points requires recalculation of NIP
                        %  Empty corresponding variable 
                        if isfield(Fold(1).Face(1), 'WindowSizes')                            
                            Fold(1).Face(1).WindowSizes = [];
                        end
                        
                        %  Appdate Storage
                        setappdata(fgt_gui_handle, 'Fold', Fold);
                        
                        %  Plot the
                        hold on;
                        plot(X,Y, 'LineStyle', '-', 'Color', 'k', 'Marker', 'o', 'MarkerEdgeColor', 'k', 'MarkerFaceColor', 'w');
                        
                         % Check if fold self intersects
                        if face == 2
                            for fold = 1:length(Fold)
                                [x0, y0, segments] = selfintersect( [Fold(fold).Face(1).X.Ori fliplr(Fold(fold).Face(2).X.Ori)] , [Fold(fold).Face(1).Y.Ori fliplr(Fold(fold).Face(2).Y.Ori)] );
                                if length(x0)>0
                                    warndlg('The fold interface self intersects. Please digitize the fold once more.', 'Error!', 'modal');
                                    Fold = rmfield(Fold, 'Face');
                                    setappdata(fgt_gui_handle, 'Fold', Fold);
                                    fgt('step_1_update_gui');
                                    break;
                                end
                            end
                        end
                        
                    elseif strcmp(Status, 'Abort')
                        % Remove all previously digitized data
                        if isfield(Fold, 'Face')
                            Fold = rmfield(Fold, 'Face');
                            setappdata(fgt_gui_handle, 'Fold', Fold);
                            fgt('step_1_update_gui');
                            break;
                        end                        
                        
                    end                    
                end                
            end
        end
        

    case 'step_1_load'
        %% - step_1_load
        
        %   Check if FGT in mode 1 - otherwise put it there
        if ~(getappdata(fgt_gui_handle, 'mode')==1)
            fgt('step_1');
        end
        
        %  Load in files
        [filename, pathname] = uigetfile({'*.mat;*.svg;*.jpg;*.png', 'FGT Input Files'},'Pick a file');
        
        if length(filename)==1 && filename==0
            return;
        end
  
        try
            switch filename(end-2:end)
                case 'mat'
                    Input_data  = load([pathname,filename]);
                    Fold        = Input_data.Fold;
                    
                case 'svg'
                    Fold        = load_fgt_svg([pathname,filename]);
                    
                otherwise
                    % Picture Format
                    Fold.PICTURE    = imread([pathname,filename]);
            end
        catch err
            errordlg(err.message, 'Fold Load Error');
            return;
        end
        
        %  Write data into storage
        setappdata(fgt_gui_handle, 'Fold', Fold);
        
        %  Non-Picture stuff
        if ~isfield(Fold, 'PICTURE')
            % Normalize data and initialize rest
            norminitialize_fold_structure;
        
            %    Enforce finish of digitization
            dwsdt('Finish');
            
            % Set figure into normal mode (non-picture), 
            % case we are coming back from picture digitization 
            set(fgt_gui_handle, 'WindowButtonDownFcn', []);
            set(fgt_gui_handle, 'Pointer', 'arrow');
        end
       
         %  Set the possible values of nodes used for curvature calculations
        setappdata(fgt_gui_handle, 'Order', [3,5,7]);
        
        %  Update GUI
        fgt('step_1_update_gui');
                
        %  Deactivate WindowButtonDownFcn
        set(fgt_gui_handle, 'WindowButtonDownFcn', []);
        
    case 'step_1_next'
        %% - step_1_next
        %    This is required because the GUI may be in digitization mode
        
        %    Enforce finish of digitization
        dwsdt('Finish');
        
        % Check if enough interfaces are digitized
        Fold    = getappdata(fgt_gui_handle, 'Fold');
        if length(Fold)>0 && isfield(Fold, 'Face') && length(Fold(end).Face)==2
            norminitialize_fold_structure;
        else
            warndlg('Digitize at least one fold train with two interfaces.', 'Next not possible!', 'modal'); 
            return;
        end
        
        % Make sure that every interface has 7 points
        for fold=1:length(Fold)
            for face=1:2
                if length(Fold(fold).Face(face).X.Ori)<7
                    warndlg('Every fold interface must consist of at least 7 points.', 'Next not possible!', 'modal');
                    return;
                end
            end
        end
              
        % Put Pointer Back 
        set(fgt_gui_handle, 'Pointer', 'arrow');
        
        % Next Panel
        fgt('step_2');
        
    case 'step_2'
        %% STEP_2
        
        % Put FGT into step_2 mode
        setappdata(fgt_gui_handle, 'mode', 2);
        
        %  Delete all axes that may exist
        delete(findobj(fgt_gui_handle, 'type', 'axes'));
        
        %  Setup new axes
        fgt_upanel_top  = findobj(fgt_gui_handle, 'tag', 'fgt_upanel_top');
        set(fgt_upanel_top, 'Title', 'Hinge & Inflection Points');
        
        %Fold
        uc_1            = uicontainer('Parent', fgt_upanel_top, 'Units', 'Normalized', 'Position', [0.0 1/2 2/3 1/2]);
        axes('Parent', uc_1, 'tag', 'axes_1');
        box on;
        
        %Curvature
        uc_2            = uicontainer('Parent', fgt_upanel_top, 'Units', 'Normalized', 'Position', [0.0 0/2 2/3 1/2]);
        axes('Parent', uc_2, 'tag', 'axes_2');
        box on;
        
        %CLICK
        uc_3            = uicontainer('Parent', fgt_upanel_top, 'Units', 'Normalized', 'Position', [2/3 0 1/3 1]);
        axes('Parent', uc_3, 'tag', 'axes_3');
        box on;
        
        %  Find the control panel
        fgt_upanel_control  = findobj(fgt_gui_handle, 'Tag', 'fgt_upanel_control');
        
        % Delete all children
        uc_handles   = findobj(fgt_upanel_control, 'Type', 'uicontrol');
        delete(uc_handles);
        
        %  Default sizes
        b_height    = getappdata(fgt_gui_handle, 'b_height');
        b_width     = getappdata(fgt_gui_handle, 'b_width');
        gap         = getappdata(fgt_gui_handle, 'gap');
        
        % Size of panel
        set(fgt_upanel_control, 'Units', 'Pixels');
        Position    = get(fgt_upanel_control, 'Position');
        
        %  Create an 'Up' and a 'Down' button
        if isempty(getappdata(fgt_gui_handle, 'buttonUp'))
            
            % Load the button icon
            icon        = fullfile(matlabroot,'/toolbox/matlab/icons/greenarrowicon.gif');
            [cdata,map] = imread(icon);
            
            % Convert white pixels into a transparent background and black
            map(map(:,1)+map(:,2)+map(:,3)==3) = NaN;
            % Convert into 3D RGB-space
            buttonDown          = ind2rgb(cdata',map);
            buttonDown(:,:,1)   = buttonDown(:,:,2);
            buttonDown(:,:,3)   = buttonDown(:,:,2);
            buttonUp            = ind2rgb(flipud(cdata'),map);
            buttonUp(:,:,1)     = buttonUp(:,:,2);
            buttonUp(:,:,3)     = buttonUp(:,:,2);
            
            setappdata(fgt_gui_handle, 'buttonUp',   buttonUp);
            setappdata(fgt_gui_handle, 'buttonDown', buttonDown);
        end
        
        
        % FOLD SELECTION
        % Default fold number
        fold = 1;
        setappdata(fgt_gui_handle, 'fold_number', fold);
        
        %  Get button icons
        buttonUp         = getappdata(fgt_gui_handle, 'buttonUp');
        buttonDown       = getappdata(fgt_gui_handle, 'buttonDown');
        
        % Text
        uicontrol('Parent', fgt_upanel_control, 'style', 'text', 'String', 'Fold', ...
            'position', [Position(2)+gap, 4*gap+3*b_height-2, b_height, b_height]);
        
        % Up Button
        uicontrol('Parent', fgt_upanel_control, 'style', 'pushbutton',...
            'cdata',buttonUp,'units','pixels',...
            'tag','fold_number_up',...
            'callback',  @f_number, ...
            'position', [Position(2)+gap, 3*gap+2*b_height, b_height, b_height],...
            'enable', 'off');
        
        % Down Button
        uicontrol('Parent', fgt_upanel_control, 'style', 'pushbutton',...
            'cdata',buttonDown,'units','pixels',...
            'tag','fold_number_down',...
            'callback',  @f_number, ...
            'position', [Position(2)+gap, 1*gap,            b_height, b_height],...
            'enable', 'off');
        % Set fold number
        uicontrol('Parent', fgt_upanel_control, 'style', 'text', 'String',num2str(fold),...
            'position', [Position(2)+gap, 2*gap+1*b_height,  b_height, b_height]);
        
        
        % INTERFACE SELECTION
        % Default fold number
        face = 1;
        setappdata(fgt_gui_handle, 'face_number', face);
        
        % Text
        uicontrol('Parent', fgt_upanel_control, 'style', 'text', 'String', 'Face', ...
            'position', [Position(2)+3*gap+b_height, 4*gap+3*b_height-2, b_height+gap, b_height]);
        
        % Up Button
        uicontrol('Parent', fgt_upanel_control, 'style', 'pushbutton',...
            'cdata',buttonUp,'units','pixels',...
            'tag','face_number_up',...
            'tooltipstring','Upper Interface',...
            'callback',  @f_number, ...
            'position', [Position(2)+3*gap+b_height, 3*gap+2*b_height, b_height, b_height],...
            'enable', 'off');
        
        % Down Button
        uicontrol('Parent', fgt_upanel_control, 'style', 'pushbutton',...
            'cdata',buttonDown,'units','pixels',...
            'tag','face_number_down',...
            'tooltipstring','Lower Interface',...
            'callback',  @f_number, ...
            'position', [Position(2)+3*gap+b_height, 1*gap,   b_height, b_height],...
            'enable', 'off');
        
        % Set face number
        uicontrol('Parent', fgt_upanel_control, 'style', 'text', 'String',num2str(face),...
            'position', [Position(2)+3*gap+b_height, 2*gap+1*b_height,  b_height, b_height]);
        
        
        %  Get Data
        Fold        = getappdata(fgt_gui_handle, 'Fold');
        
        % HINGE METHOD
        % Text
        uicontrol('Parent', fgt_upanel_control, 'style', 'text', 'String', 'Hinge', ...
            'position', [Position(3)-2*gap-2*b_width, 2*gap+b_height, b_width, b_height]);
        
        % Button
        ibutton = sprintf('1-curvature extreme\n2-polynomial extreme');
        uicontrol('Parent', fgt_upanel_control, 'style', 'popupmenu', 'String', {'1';'2'}, 'value', Fold(1).hinge_method, ...
            'callback',  @(a,b)  fgt('step_2_update_gui'), ...
            'tag', 'step_2_hinge', ...
            'tooltipstring', ibutton,...
            'position', [Position(3)-gap-b_width, 2*gap+b_height, b_width, b_height]);
        
        
        % 'SMALL AREAS'
        % Text
        uicontrol('Parent', fgt_upanel_control, 'style', 'text', 'String', 'Small area (%)', ...
            'position', [Position(3)-8*gap-2*b_width, 3*gap+2*b_height, b_width+6*gap, b_height]);
        
        % Button
        uicontrol('Parent', fgt_upanel_control, 'style', 'edit', 'String', num2str(Fold(1).fraction*100), ...
            'callback',  @(a,b)  fgt('step_2_update_gui'), ...
            'tag', 'step_2_small_area_fraction', ...
            'tooltipstring', 'Must be in interval 0..100',...
            'position', [Position(3)-gap-b_width, 3*gap+2*b_height, b_width, b_height]);
        
        
        % 'ORDER'
        % Text
        uicontrol('Parent', fgt_upanel_control, 'style', 'text', 'String', 'Order', ...
            'position', [Position(3)-3*gap-2*b_width, 4*gap+3*b_height, b_width, b_height]);
        
        % Button
        Order = getappdata(fgt_gui_handle,'Order');
        uicontrol('Parent', fgt_upanel_control, 'style', 'popupmenu', 'String', {'3';'5';'7'}, 'value', find(Fold(1).order == Order), ...
            'callback',  @(a,b)  fgt('step_2_update_gui'), ...
            'tag', 'step_2_order', ...
            'tooltipstring', 'Number of nodes needed for curvature calculation',...
            'position', [Position(3)-gap-b_width, 4*gap+3*b_height, b_width, b_height]);
        
        
        % ZOOM ON
        % Button
        izoom = sprintf('Mark the checkbox to activate zoom\nTo zoom in - click in the picture or use the mouse scroll\nTo zoom out - double click or use the mouse scroll');
        uicontrol('Parent', fgt_upanel_control, 'style', 'checkbox', 'String', 'Zoom on', 'Value', 0,...
            'callback',  @fgt_zoom, ...
            'tag', 'step_2_zoomon', ...
            'tooltipstring', izoom,...
            'position', [Position(2)+4*gap+2*b_height, gap, 2*b_width, b_height]);
        zoom off;
        
        % Back Button
        uicontrol('Parent', fgt_upanel_control, 'style', 'pushbutton', 'String', 'Back', ...
            'callback',  @(a,b) fgt('step_1'), ...
            'position', [Position(3)-2*gap-2*b_width, gap, b_width, b_height]);
        
        % Next Button
        uicontrol('Parent', fgt_upanel_control, 'style', 'pushbutton', 'String', 'Next', ...
            'tag', 'next', ...
            'callback',  @(a,b) fgt('step_3'), ...
            'position', [Position(3)-gap-b_width, gap, b_width, b_height], ...
            'enable', 'off');
        
        % Set Units to Normalized - Resizing
        units_normalized;
        
        %  Update GUI
        fgt('step_2_update_gui');
    
    
    case 'step_2_update_gui'
        %% - step_2_update_gui
        
        %  Get Data
        Fold        = getappdata(fgt_gui_handle, 'Fold');
        fold    	= getappdata(fgt_gui_handle, 'fold_number');
        face    	= getappdata(fgt_gui_handle, 'face_number');
        Order       = getappdata(fgt_gui_handle, 'Order');
        
        %  Read data
        hinge_method    = get(findobj(fgt_gui_handle, 'tag', 'step_2_hinge'),  'value');
        fraction        = str2double(get(findobj(fgt_gui_handle, 'tag', 'step_2_small_area_fraction'),  'string'))/100;
        order           = Order(get(findobj(fgt_gui_handle, 'tag', 'step_2_order'),  'value'));
                
        % Minimum size
        if fraction > 1 || fraction < 0
            eh = errordlg('Value of the fraction has to be in range from 0 to 100', 'FGT - Error', 'modal');
            uiwait(eh);
        end
        
        % Set a flag if the curvature needs to be (re)calculated
        flag = 0;
        if ~isfield(Fold(1).Face(1),'WindowSizes') || isempty(Fold(1).Face(1).WindowSizes)
            flag = 1;
        elseif Fold(1).fraction ~= fraction
            flag = 1;
        elseif Fold(1).order ~= order
            flag = 1;
        end
            
        % Assign new valuess to the structure
        Fold(1).hinge_method    = hinge_method;
        Fold(1).fraction        = fraction;
        Fold(1).order           = order;
        
        
        % Set that thickness needs to be recalculated
        if flag == 1
            setappdata(fgt_gui_handle, 'Thickness_calculation', 1);
        else
            setappdata(fgt_gui_handle, 'Thickness_calculation', 0);
        end
        
        if flag == 1
            
            %  Calculate Effect of Filter Width
            h = waitbar(0,'Calculate the NIP-FW diagram.');
            hw=findobj(h,'Type','Patch');
            set(hw,'EdgeColor',[0.5 0.5 0.5],'FaceColor',[0.4 0.4 0.4])
            for i = 1:length(Fold)
                for j = 1:2
                    [Fold(i).Face(j).WindowSizes, Fold(i).Face(j).NIP] = window_size(Fold(i).Face(j).X.Norm, Fold(i).Face(j).Y.Norm, Fold(1).fraction, size(Fold,2), i, j, Fold(1).order);
                end
            end
            close(h)
        end
        
        %  FILTER WIDTH PLOT (NIP-WW)
        achse  = findobj(fgt_gui_handle, 'tag', 'axes_3');
        
        %  Only plot if this axes is empty, i.e. the data was not plotted yet
        if flag == 1 || isempty(get(achse,'Children'))
            cla(achse);
            hold(achse, 'on');
            
            for i = 1:length(Fold)
                % Plot analysis of the curvature without smoothing
                plot(Fold(i).Face(1).WindowSizes, Fold(i).Face(1).NIP.Ori, 'o', 'MarkerSize', 5, 'MarkerEdgeColor', 'k', 'MarkerFaceColor', 'b', 'Parent', achse);
                plot(Fold(i).Face(2).WindowSizes, Fold(i).Face(2).NIP.Ori, 'o', 'MarkerSize', 5, 'MarkerEdgeColor', 'k', 'MarkerFaceColor', 'r', 'Parent', achse);
                
                % Plot anaysis of the smoothed curvature
                plot(Fold(i).Face(1).WindowSizes, Fold(i).Face(1).NIP.Smoothed, '-b', 'Parent', achse);
                plot(Fold(i).Face(2).WindowSizes, Fold(i).Face(2).NIP.Smoothed, '-r', 'Parent', achse);
            end
            
            set(achse, 'xscale', 'log');
            axis(achse, 'square');
            xlabel(achse, 'Filter Width')
            ylabel(achse, '# Inflection Points')
            box(achse, 'on');
            legend(achse, {'U1','L1','U2','L2'}, 'Location', 'NorthEast');
            
            %  Add Clicker
            set(achse, 'ButtonDownFcn',  @(a,b) fgt('step_2_set_filter_width'));
            
            %  Add Line
            handle_line       = plot([Fold(1).filter_width, Fold(1).filter_width], get(achse, 'YLim'), '--k', 'parent', achse);
            
            % Title
            handle_title    = title(achse, ['NIP-FW diagram. Filter Width: ', num2str(Fold(1).filter_width)]);
            
            % Store for Update
            setappdata(achse, 'handle_line',  handle_line);
            setappdata(achse, 'handle_title', handle_title);
            
        else
            % Update NIP-WW
            handle_line     = getappdata(achse, 'handle_line');
            handle_title    = getappdata(achse, 'handle_title');
            
            set(handle_line,  'XData',  [Fold(1).filter_width, Fold(1).filter_width]);
            set(handle_title, 'String', ['NIP-FW diagram. Filter Width: ', num2str(Fold(1).filter_width)]);
            
            % Set that thickness needs to be recalculated
            setappdata(fgt_gui_handle, 'Thickness_calculation', 1);
            
        end
        
        % CURVATURE ANALYSIS
        for i=1:length(Fold)
            for j=1:2
                [Fold(i).Face(j).X, Fold(i).Face(j).Y, Fold(i).Face(j).Arclength, Fold(i).Face(j).Curvature, Fold(i).Face(j).Inflection, Fold(i).Face(j).Hinge, ...
                    Fold(i).Face(j).Fold_arclength, Fold(i).Face(j).Wavelength, Fold(i).Face(j).Amplitude] = ...
                    curve_analysis(Fold(i).Face(j).X, Fold(i).Face(j).Y, Fold(1).filter_width, Fold(1).fraction, Fold(1).hinge_method,Fold(1).order);
            end
        end
        
        %  ARCLENGTH-CURVATURE PLOT
        achse  = findobj(fgt_gui_handle, 'tag', 'axes_2');
        set(fgt_gui_handle, 'CurrentAxes', achse);
        delete(allchild(achse));
        
        %  Remove potential marker point handle
        if ~isempty(getappdata(achse, 'point_h2'))
            rmappdata(achse, 'point_h2');
        end
        hold on;
        
        % Activate mouse over function
        set(fgt_gui_handle,'windowbuttonmotionfcn', @(a,b) mouseover);
        
        Legend_flag = logical([1 1 0 0 0]);
        
        %  Original
        plot(Fold(fold).Face(face).Arclength.Ori, Fold(fold).Face(face).Curvature.Ori, 'Color',[0.7 0.7 0.7]);
        
        %  Smooth
        plot(Fold(fold).Face(face).Arclength.Full, Fold(fold).Face(face).Curvature.Full, 'k');
        
        %  Hinge
        if Fold(1).hinge_method == 1
            plot(Fold(fold).Face(face).Arclength.Full(Fold(fold).Face(face).Hinge.Index), Fold(fold).Face(face).Curvature.Full(Fold(fold).Face(face).Hinge.Index), 'ob','MarkerSize',4);
            Legend_flag(3)  = [];
        end
        if Fold(1).hinge_method == 2
            plot(Fold(fold).Face(face).Hinge.Poly_Arc, Fold(fold).Face(face).Hinge.Poly_Cur,'g');
            Legend_flag(3)  = ~isempty(Fold(fold).Face(face).Hinge.Poly_Arc);
            plot(Fold(fold).Face(face).Arclength.Full(Fold(fold).Face(face).Hinge.Index), Fold(fold).Face(face).Curvature.Full(Fold(fold).Face(face).Hinge.Index), 'ob','MarkerSize',4);
        end
        
        Legend_flag(4)  = ~isempty(Fold(fold).Face(face).Hinge.Index);
        
        %  Inflection
        plot(Fold(fold).Face(face).Arclength.Full(Fold(fold).Face(face).Inflection), Fold(fold).Face(face).Curvature.Full(Fold(fold).Face(face).Inflection), 'or','MarkerSize',4);
        Legend_flag(5)  = ~isempty(Fold(fold).Face(face).Inflection);
        
        
        Legende = {'Original' 'Smoothed' 'Polynomial' 'Hinge' 'Inflection'};
        Title   = {'First Interface', 'Second Interface'};
        
        title(Title{face});
        xlabel('Arc length');
        ylabel('Curvature');
        
        xlim([0 max(abs(Fold(fold).Face(face).Arclength.Ori))]);
        ylim([-max(abs(Fold(fold).Face(face).Curvature.Ori)) max(abs(Fold(fold).Face(face).Curvature.Ori))]);
        legend(Legende(Legend_flag),'Orientation','Horizontal','Location', 'SouthEast');
        box on;
        grid on;
        
        
        %  HINGE & INFLECTION POINTS ON FOLD
        achse  = findobj(fgt_gui_handle, 'tag', 'axes_1');
        set(fgt_gui_handle, 'CurrentAxes', achse);
        delete(allchild(achse));
      
        %  Remove potential marker point handle
        if ~isempty(getappdata(achse, 'point_h1'))
            rmappdata(achse, 'point_h1');
        end        
      
        hold on;
        
        %  Fold
        for i=1:length(Fold)
            fh  = fill([Fold(i).Face(1).X.Norm fliplr(Fold(i).Face(2).X.Norm)], [Fold(i).Face(1).Y.Norm fliplr(Fold(i).Face(2).Y.Norm)], 'k');
            set(fh, 'EdgeColor', [0.9 0.9 0.9], 'FaceColor', [.97 .97 .97]);
        end
        
        %  Face
        other_face          = [1 2];
        other_face(face)    = [];
        plot(Fold(fold).Face(face).X.Full,       Fold(fold).Face(face).Y.Full,       'Color','k');
        plot(Fold(fold).Face(other_face).X.Full, Fold(fold).Face(other_face).Y.Full, 'Color',[0.7 0.7 0.7]);
        
        for i = 1:length(Fold)
            for j=1:2
                %  Hinge
                plot(Fold(i).Face(j).X.Full(Fold(i).Face(j).Hinge.Index), Fold(i).Face(j).Y.Full(Fold(i).Face(j).Hinge.Index), 'o','MarkerSize',2,'Color',[0.2 0.2 0.2]);
                
                %  Inflection
                plot(Fold(i).Face(j).X.Full(Fold(i).Face(j).Inflection), Fold(i).Face(j).Y.Full(Fold(i).Face(j).Inflection), 'o','MarkerSize',2,'Color',[0.5 0.5 0.5]);
            end
        end
        
        %  Hinge
        plot(Fold(fold).Face(face).X.Full(Fold(fold).Face(face).Hinge.Index), Fold(fold).Face(face).Y.Full(Fold(fold).Face(face).Hinge.Index), 'ob','MarkerSize',3);
        %  Inflection
        plot(Fold(fold).Face(face).X.Full(Fold(fold).Face(face).Inflection), Fold(fold).Face(face).Y.Full(Fold(fold).Face(face).Inflection), 'or','MarkerSize',3);
        
        axis equal;
        box on;
        
        
        %  Update data
        setappdata(fgt_gui_handle, 'Fold', Fold);
        
        %  Activate next button
        set(findobj(fgt_gui_handle, 'tag', 'next'), 'enable', 'on');
        
        % Deactivete fold buttons
        set(findobj(fgt_gui_handle, 'tag', 'fold_number_up'),   'enable', 'off');
        set(findobj(fgt_gui_handle, 'tag', 'fold_number_down'), 'enable', 'off');
        
        % Activatie fold number button
        if fold < size(Fold,2)
            fold_number = ['Fold number ',num2str(fold+1)];
            set(findobj(fgt_gui_handle, 'tag', 'fold_number_up'), 'enable', 'on','tooltipstring',fold_number);
        end
        if fold > 1
            fold_number = ['Fold number ',num2str(fold-1)];
            set(findobj(fgt_gui_handle, 'tag', 'fold_number_down'), 'enable', 'on','tooltipstring',fold_number);
        end
        
        % Activate appropreate face button
        if face > 1
            set(findobj(fgt_gui_handle, 'tag', 'face_number_up'),   'enable', 'on' );
            set(findobj(fgt_gui_handle, 'tag', 'face_number_down'), 'enable', 'off');
        else
            set(findobj(fgt_gui_handle, 'tag', 'face_number_down'), 'enable', 'on' );
            set(findobj(fgt_gui_handle, 'tag', 'face_number_up'),   'enable', 'off');
        end
        
        % Set Units to Normalized - Resizing
        units_normalized;
        
    case 'step_2_set_filter_width'
        %% - step_2_set_filter_width
        CURRENT_POINT = get(gca,'CurrentPoint');
        
        %  Update Data
        Fold                    = getappdata(fgt_gui_handle, 'Fold');
        Fold(1).filter_width    = CURRENT_POINT(1);
        setappdata(fgt_gui_handle, 'Fold', Fold);
        
        fgt('step_2_update_gui');
        
        
    case 'step_3'
        %% STEP_3
        
        % Put FGT into step_3 mode
        setappdata(fgt_gui_handle, 'mode', 3);
        set(fgt_gui_handle,'windowbuttonmotionfcn',[]);
        
        %  Delete all axes that may exist
        delete(findobj(fgt_gui_handle, 'type', 'axes'));
        
        %  Setup new axes
        fgt_upanel_top  = findobj(fgt_gui_handle, 'tag', 'fgt_upanel_top');
        set(fgt_upanel_top, 'Title', 'Amplitude & Wavelength');
        
        uc_1            = uicontainer('Parent', fgt_upanel_top, 'Units', 'Normalized', 'Position', [0.0 0.5 0.5 0.5]);
        axes('Parent', uc_1, 'tag', 'axes_1');
        box on;
        
        uc_2            = uicontainer('Parent', fgt_upanel_top, 'Units', 'Normalized', 'Position', [0.5 0.5 0.5 0.5]);
        axes('Parent', uc_2, 'tag', 'axes_2');
        box on;
        
        uc_3            = uicontainer('Parent', fgt_upanel_top, 'Units', 'Normalized', 'Position', [0.0 0.0 0.5 0.5]);
        axes('Parent', uc_3, 'tag', 'axes_3');
        box on;
        
        uc_4            = uicontainer('Parent', fgt_upanel_top, 'Units', 'Normalized', 'Position', [0.5 0.0 0.5 0.5]);
        axes('Parent', uc_4, 'tag', 'axes_4');
        box on;
        
        %  Find the control panel
        fgt_upanel_control  = findobj(fgt_gui_handle, 'Tag', 'fgt_upanel_control');
        
        % Delete all children
        uc_handles   = findobj(fgt_upanel_control, 'Type', 'uicontrol');
        delete(uc_handles);
        
        %  Default sizes
        b_height    = getappdata(fgt_gui_handle, 'b_height');
        b_width     = getappdata(fgt_gui_handle, 'b_width');
        gap         = getappdata(fgt_gui_handle, 'gap');
        
        % Size of panel
        set(fgt_upanel_control, 'Units', 'Pixels');
        Position    = get(fgt_upanel_control, 'Position');
        
        %  Get button icons
        buttonUp         = getappdata(fgt_gui_handle, 'buttonUp');
        buttonDown       = getappdata(fgt_gui_handle, 'buttonDown');
        
        % FOLD SELECTION
        % Default fold number
        fold = 1;
        setappdata(fgt_gui_handle, 'fold_number', fold);
        
        % Text
        uicontrol('Parent', fgt_upanel_control, 'style', 'text', 'String', 'Fold', ...
            'position', [Position(2)+gap, 4*gap+3*b_height-2, b_height, b_height]);
        
        % Up Button
        uicontrol('Parent', fgt_upanel_control, 'style', 'pushbutton',...
            'cdata',buttonUp,'units','pixels',...
            'tag','fold_number_up',...
            'callback',  @f_number, ...
            'position', [Position(2)+gap, 3*gap+2*b_height, b_height, b_height],...
            'enable', 'off');
        
        % Down Button
        uicontrol('Parent', fgt_upanel_control, 'style', 'pushbutton',...
            'cdata',buttonDown,'units','pixels',...
            'tag','fold_number_down',...
            'callback',  @f_number, ...
            'position', [Position(2)+gap, 1*gap,            b_height, b_height],...
            'enable', 'off');
        
        % Set fold number
        uicontrol('Parent', fgt_upanel_control, 'style', 'text', 'String',num2str(fold),...
            'position', [Position(2)+gap, 2*gap+1*b_height,  b_height, b_height]);
        
        
        % AMPLITUDE METHOD
        % Text
        uicontrol('Parent', fgt_upanel_control, 'style', 'text', 'String', 'Amplitude', ...
            'position', [Position(3)-4*gap-4*b_width, 2*gap+b_height-2, b_width, b_height]);
        
        % Button
        uicontrol('Parent', fgt_upanel_control, 'style', 'popupmenu', 'String', {'1';'2';'3'}, 'value', 1, ...
            'callback',  @(a,b)  fgt('step_3_update_gui'), ...
            'tag', 'step_3_amplitude', ...
            'position', [Position(3)-3*gap-3*b_width, 2*gap+b_height, b_width, b_height]);
        
        % WAVELENGTH METHOD
        % Text
        uicontrol('Parent', fgt_upanel_control, 'style', 'text', 'String', 'Wavelength', ...
            'position', [Position(3)-2*gap-2*b_width, 2*gap+b_height-2, b_width, b_height]);
        
        % Button
        uicontrol('Parent', fgt_upanel_control, 'style', 'popupmenu', 'String', {'1';'2';'3';'4'}, 'value', 1, ...
            'callback',  @(a,b)  fgt('step_3_update_gui'), ...
            'tag', 'step_3_wavelength', ...
            'position', [Position(3)-gap-b_width, 2*gap+b_height, b_width, b_height]);
        
        % ZOOM ON
        % Button
        uicontrol('Parent', fgt_upanel_control, 'style', 'checkbox', 'String', 'Zoom on', 'Value', 0,...
            'callback',   @fgt_zoom, ...
            'tag', 'step_3_zoomon', ...
            'position', [Position(2)+4*gap+2*b_height, gap, 2*b_width, b_height]);
        zoom off;
        
        
        % AXIS EQUAL
        % Axis equal button
        uicontrol('Parent', fgt_upanel_control, 'style', 'checkbox', 'String', 'Axis equal', 'Value', 1,...
            'callback',  @(a,b) fgt('step_3_update_gui'), ...
            'tag', 'step_3_axisequal', ...
            'position', [Position(2)+6*gap+2*b_height+b_width, gap, 2*b_width, b_height]);
        
        
        % Back Button
        uicontrol('Parent', fgt_upanel_control, 'style', 'pushbutton', 'String', 'Back', ...
            'callback',  @(a,b) fgt('step_2'), ...
            'position', [Position(3)-2*gap-2*b_width, gap, b_width, b_height]);
        
        % Next Button
        uicontrol('Parent', fgt_upanel_control, 'style', 'pushbutton', 'String', 'Next', ...
            'tag', 'next', ...
            'callback',  @(a,b) fgt('step_4'), ...
            'position', [Position(3)-gap-b_width, gap, b_width, b_height], ...
            'enable', 'off');
        
        %  Update GUI
        fgt('step_3_update_gui');
        
    case 'step_3_update_gui'
        %% - step_3_update_gui
        
        %  Get data
        Fold    = getappdata(fgt_gui_handle, 'Fold');
        fold    = getappdata(fgt_gui_handle, 'fold_number');
        
        %  Read data
        amplitude_method    = get(findobj(fgt_gui_handle, 'tag', 'step_3_amplitude'),  'value');
        wavelength_method   = get(findobj(fgt_gui_handle, 'tag', 'step_3_wavelength'), 'value');
        axis_equal          = get(findobj(fgt_gui_handle, 'tag', 'step_3_axisequal'),  'value');
        
        %  AMPLITUDE
        for face=1:2
            if face==1
                achse  = findobj(fgt_gui_handle, 'tag', 'axes_1');
            else
                achse  = findobj(fgt_gui_handle, 'tag', 'axes_3');
            end
            
            set(fgt_gui_handle, 'CurrentAxes', achse);
            delete(allchild(achse));
            hold on;
            
            % Set axis equal
            if axis_equal == 1
                axis equal
            else
                axis normal
            end
            
            if face==1
                title({['Amplitude after ',num2str(Fold(fold).Face(face).Amplitude(amplitude_method).Name)]...
                    [' First interface \color{blue}    A=',num2str(mean([Fold(fold).Face(face).Amplitude(amplitude_method).Value]),3 )]});
            else
                title({'   '...
                    [' Second interface \color{blue}    A=',num2str(mean([Fold(fold).Face(face).Amplitude(amplitude_method).Value]),3 )]});
            end
            
            if isempty(Fold(fold).Face(face).Amplitude)
                error('At least 2 inflection points have to be defined on each layer in order to calculate amplitude and wavelength')
            end
            
            
            %  Fold
            for i=1:length(Fold)
                fh  = fill([Fold(i).Face(1).X.Norm fliplr(Fold(i).Face(2).X.Norm)], [Fold(i).Face(1).Y.Norm fliplr(Fold(i).Face(2).Y.Norm)], 'k');
                set(fh, 'EdgeColor', [0.9 0.9 0.9], 'FaceColor', [.97 .97 .97]);
            end
            %  Plot analyzed interface
            plot(Fold(fold).Face(face).X.Full, Fold(fold).Face(face).Y.Full, '-k');
            
            %  Hinge
            plot(Fold(fold).Face(face).X.Full(Fold(fold).Face(face).Hinge.Index), Fold(fold).Face(face).Y.Full(Fold(fold).Face(face).Hinge.Index), 'ob','MarkerSize',3);
            
            %  Inflection
            plot(Fold(fold).Face(face).X.Full(Fold(fold).Face(face).Inflection), Fold(fold).Face(face).Y.Full(Fold(fold).Face(face).Inflection), 'or','MarkerSize',3);
            
            
            if amplitude_method==1
                
                plot(...
                    [Fold(fold).Face(face).X.Full(Fold(fold).Face(face).Inflection(1:end-1))', Fold(fold).Face(face).Amplitude(1).PP(1,:)']', ...
                    [Fold(fold).Face(face).Y.Full(Fold(fold).Face(face).Inflection(1:end-1))', Fold(fold).Face(face).Amplitude(1).PP(2,:)']', ...
                    ':k');
                
                plot(...
                    [Fold(fold).Face(face).X.Full(Fold(fold).Face(face).Inflection(2:end))', Fold(fold).Face(face).Amplitude(1).PP(1,:)']', ...
                    [Fold(fold).Face(face).Y.Full(Fold(fold).Face(face).Inflection(2:end))', Fold(fold).Face(face).Amplitude(1).PP(2,:)']', ...
                    ':k');
                
                plot(...
                    [Fold(fold).Face(face).X.Full(Fold(fold).Face(face).Amplitude(1).Index)', Fold(fold).Face(face).Amplitude(1).PP(1,:)']', ...
                    [Fold(fold).Face(face).Y.Full(Fold(fold).Face(face).Amplitude(1).Index)', Fold(fold).Face(face).Amplitude(1).PP(2,:)']', ...
                    'b');
                
            end
            
            if amplitude_method==2
                
                plot(...
                    [Fold(fold).Face(face).X.Full(Fold(fold).Face(face).Inflection(1:end-1))', Fold(fold).Face(face).Amplitude(2).PP(1,:)']', ...
                    [Fold(fold).Face(face).Y.Full(Fold(fold).Face(face).Inflection(1:end-1))', Fold(fold).Face(face).Amplitude(2).PP(2,:)']', ...
                    ':k');
                
                plot(...
                    [Fold(fold).Face(face).X.Full(Fold(fold).Face(face).Inflection(2:end))', Fold(fold).Face(face).Amplitude(2).PP(1,:)']', ...
                    [Fold(fold).Face(face).Y.Full(Fold(fold).Face(face).Inflection(2:end))', Fold(fold).Face(face).Amplitude(2).PP(2,:)']', ...
                    ':k');
                
                plot(...
                    [Fold(fold).Face(face).X.Full(Fold(fold).Face(face).Hinge.Index)', Fold(fold).Face(face).Amplitude(2).PP(1,:)']', ...
                    [Fold(fold).Face(face).Y.Full(Fold(fold).Face(face).Hinge.Index)', Fold(fold).Face(face).Amplitude(2).PP(2,:)']', ...
                    'b');
                
            end
            
            if amplitude_method==3
                
                plot(...
                    [Fold(fold).Face(face).Amplitude(3).PP(1,1:2:end-1)', Fold(fold).Face(face).Amplitude(3).PP(1,2:2:end)']', ...
                    [Fold(fold).Face(face).Amplitude(3).PP(2,1:2:end-1)', Fold(fold).Face(face).Amplitude(3).PP(2,2:2:end)']', ...
                    ':k');
                
                plot(...
                    [Fold(fold).Face(face).X.Full(Fold(fold).Face(face).Inflection(1:end-1))', Fold(fold).Face(face).Amplitude(3).PP(1,1:2:end)']', ...
                    [Fold(fold).Face(face).Y.Full(Fold(fold).Face(face).Inflection(1:end-1))', Fold(fold).Face(face).Amplitude(3).PP(2,1:2:end)']', ...
                    'b');
                
                plot(...
                    [Fold(fold).Face(face).X.Full(Fold(fold).Face(face).Inflection(2:end))', Fold(fold).Face(face).Amplitude(3).PP(1,2:2:end)']', ...
                    [Fold(fold).Face(face).Y.Full(Fold(fold).Face(face).Inflection(2:end))', Fold(fold).Face(face).Amplitude(3).PP(2,2:2:end)']', ...
                    'b');
                
            end
            
        end
        
        %  WAVELENGTH
        for face=1:2
            
            if face==1
                achse  = findobj(fgt_gui_handle, 'tag', 'axes_2');
            else
                achse  = findobj(fgt_gui_handle, 'tag', 'axes_4');
            end
            
            set(fgt_gui_handle, 'CurrentAxes', achse);
            delete(allchild(achse));
            hold on;
            
            % Set axis equal
            if axis_equal == 1
                axis equal
            else
                axis normal
            end
            
            if face==1
                title({['Wavelength after ',num2str(Fold(fold).Face(face).Wavelength(wavelength_method).Name)]...
                    [' First interface  \color{red}   W=', num2str( mean([Fold(fold).Face(face).Wavelength(wavelength_method).Value]),3 )]});
            else
                title({'   '...
                    [' Second interface  \color{red}   W=',num2str(mean([Fold(fold).Face(face).Wavelength(wavelength_method).Value]),3 )]});
            end
            
            
            %  Fold
            for i=1:length(Fold)
                fh  = fill([Fold(i).Face(1).X.Norm fliplr(Fold(i).Face(2).X.Norm)], [Fold(i).Face(1).Y.Norm fliplr(Fold(i).Face(2).Y.Norm)], 'k');
                set(fh, 'EdgeColor', [0.9 0.9 0.9], 'FaceColor', [.97 .97 .97]);
            end
            %  Plot analyzed interface
            plot(Fold(fold).Face(face).X.Full, Fold(fold).Face(face).Y.Full, '-k');
            
            %  Hinge
            plot(Fold(fold).Face(face).X.Full(Fold(fold).Face(face).Hinge.Index), Fold(fold).Face(face).Y.Full(Fold(fold).Face(face).Hinge.Index), 'ob','MarkerSize',3);
            
            %  Inflection
            plot(Fold(fold).Face(face).X.Full(Fold(fold).Face(face).Inflection), Fold(fold).Face(face).Y.Full(Fold(fold).Face(face).Inflection), 'or','MarkerSize',3);
            
            if wavelength_method==1 
                plot(...
                    [Fold(fold).Face(face).X.Full(Fold(fold).Face(face).Inflection(1:end-1))', Fold(fold).Face(face).X.Full(Fold(fold).Face(face).Inflection(2:end))']', ...
                    [Fold(fold).Face(face).Y.Full(Fold(fold).Face(face).Inflection(1:end-1))', Fold(fold).Face(face).Y.Full(Fold(fold).Face(face).Inflection(2:end))']', ...
                    '-r');
            end
            
            if wavelength_method==2
                plot(...
                    [Fold(fold).Face(face).X.Full(Fold(fold).Face(face).Hinge.Index(1:end-2))', Fold(fold).Face(face).X.Full(Fold(fold).Face(face).Hinge.Index(3:end))']', ...
                    [Fold(fold).Face(face).Y.Full(Fold(fold).Face(face).Hinge.Index(1:end-2))', Fold(fold).Face(face).Y.Full(Fold(fold).Face(face).Hinge.Index(3:end))']', ...
                    'r');
                
            end
            
            if wavelength_method==3
                plot(...
                    [Fold(fold).Face(face).X.Full(Fold(fold).Face(face).Inflection(1:end-1))', Fold(fold).Face(face).Wavelength(3).PP(1,1:2:end)']', ...
                    [Fold(fold).Face(face).Y.Full(Fold(fold).Face(face).Inflection(1:end-1))', Fold(fold).Face(face).Wavelength(3).PP(2,1:2:end)']', ...
                    ':k');
                plot(...
                    [Fold(fold).Face(face).X.Full(Fold(fold).Face(face).Inflection(2:end))', Fold(fold).Face(face).Wavelength(3).PP(1,2:2:end)']', ...
                    [Fold(fold).Face(face).Y.Full(Fold(fold).Face(face).Inflection(2:end))', Fold(fold).Face(face).Wavelength(3).PP(2,2:2:end)']', ...
                    ':k');
                plot(...
                    [Fold(fold).Face(face).Wavelength(3).PP(1,1:2:end-1)', Fold(fold).Face(face).Wavelength(3).PP(1,2:2:end)']', ...
                    [Fold(fold).Face(face).Wavelength(3).PP(2,1:2:end-1)', Fold(fold).Face(face).Wavelength(3).PP(2,2:2:end)']', ...
                    'r');
            end
            
            if wavelength_method==4
                plot(...
                    [Fold(fold).Face(face).X.Full(Fold(fold).Face(face).Inflection(1:end-2))', Fold(fold).Face(face).X.Full(Fold(fold).Face(face).Inflection(3:end))']', ...
                    [Fold(fold).Face(face).Y.Full(Fold(fold).Face(face).Inflection(1:end-2))', Fold(fold).Face(face).Y.Full(Fold(fold).Face(face).Inflection(3:end))']', ...
                    '-r');
                
            end
        end
        
        %  Update data
        setappdata(fgt_gui_handle, 'Fold', Fold);
        
        %  Activate next button
        set(findobj(fgt_gui_handle, 'tag', 'next'), 'enable', 'on');
        
        % Deactivete fold buttons
        set(findobj(fgt_gui_handle, 'tag', 'fold_number_up'),   'enable', 'off');
        set(findobj(fgt_gui_handle, 'tag', 'fold_number_down'), 'enable', 'off');
        
        % Activatie fold number button
        if fold < size(Fold,2)
            fold_number = ['Fold number ',num2str(fold+1)];
            set(findobj(fgt_gui_handle, 'tag', 'fold_number_up'), 'enable', 'on','tooltipstring',fold_number);
        end
        if fold > 1
            fold_number = ['Fold number ',num2str(fold-1)];
            set(findobj(fgt_gui_handle, 'tag', 'fold_number_down'), 'enable', 'on','tooltipstring',fold_number);
        end
        
        % Set Units to Normalized - Resizing
        units_normalized;
        
    case 'step_4'
        %% STEP_4
        
        % Put FGT into step_4 mode
        setappdata(fgt_gui_handle, 'mode', 4);
        
        %  Delete all axes that may exist
        delete(findobj(fgt_gui_handle, 'type', 'axes'));
        
        %  Setup new axes
        fgt_upanel_top  = findobj(fgt_gui_handle, 'tag', 'fgt_upanel_top');
        set(fgt_upanel_top, 'Title', 'Thickness');
        
        uc_1            = uicontainer('Parent', fgt_upanel_top, 'Units', 'Normalized', 'Position', [0.0 0.5 0.7 0.5]);
        axes('Parent', uc_1, 'tag', 'axes_1');
        box on;
        
        uc_2            = uicontainer('Parent', fgt_upanel_top, 'Units', 'Normalized', 'Position', [0.7 0.5 0.3 0.5]);
        axes('Parent', uc_2, 'tag', 'axes_2');
        box on;
        
        uc_3            = uicontainer('Parent', fgt_upanel_top, 'Units', 'Normalized', 'Position', [0.0 0.0 0.7 0.5]);
        axes('Parent', uc_3, 'tag', 'axes_3');
        box on;
        
        uc_4            = uicontainer('Parent', fgt_upanel_top, 'Units', 'Normalized', 'Position', [0.7 0.0 0.3 0.5]);
        axes('Parent', uc_4, 'tag', 'axes_4');
        box on;
        
        %  Find the control panel
        fgt_upanel_control  = findobj(fgt_gui_handle, 'Tag', 'fgt_upanel_control');
        
        % Delete all children
        uc_handles   = findobj(fgt_upanel_control, 'Type', 'uicontrol');
        delete(uc_handles);
        
        %  Default sizes
        b_height    = getappdata(fgt_gui_handle, 'b_height');
        b_width     = getappdata(fgt_gui_handle, 'b_width');
        gap         = getappdata(fgt_gui_handle, 'gap');
        
        %  Size of panel
        set(fgt_upanel_control, 'Units', 'Pixels');
        Position    = get(fgt_upanel_control, 'Position');
        
        %  Get button icons
        buttonUp         = getappdata(fgt_gui_handle, 'buttonUp');
        buttonDown       = getappdata(fgt_gui_handle, 'buttonDown');
        
        % FOLD SELECTION
        % Default fold number
        fold = 1;
        setappdata(fgt_gui_handle, 'fold_number', fold);
        
        % Text
        uicontrol('Parent', fgt_upanel_control, 'style', 'text', 'String', 'Fold', ...
            'position', [Position(2)+gap, 4*gap+3*b_height-2, b_height, b_height]);
        
        % Up Button
        uicontrol('Parent', fgt_upanel_control, 'style', 'pushbutton',...
            'cdata',buttonUp,'units','pixels',...
            'tag','fold_number_up',...
            'callback',  @f_number, ...
            'position', [Position(2)+gap, 3*gap+2*b_height, b_height, b_height],...
            'enable', 'off');
        
        % Down Button
        uicontrol('Parent', fgt_upanel_control, 'style', 'pushbutton',...
            'cdata',buttonDown,'units','pixels',...
            'tag','fold_number_down',...
            'callback',  @f_number, ...
            'position', [Position(2)+gap, 1*gap,            b_height, b_height],...
            'enable', 'off');
        
        % Set fold number
        uicontrol('Parent', fgt_upanel_control, 'style', 'text', 'String',num2str(fold),...
            'position', [Position(2)+gap, 2*gap+1*b_height,  b_height, b_height]);
        
        % ZOOM ON
        % Button
        uicontrol('Parent', fgt_upanel_control, 'style', 'checkbox', 'String', 'Zoom on', 'Value', 0,...
            'callback',   @fgt_zoom, ...
            'tag', 'step_4_zoomon', ...
            'position', [Position(2)+4*gap+2*b_height, gap, 2*b_width, b_height]);
        zoom off;
        
        
        % Back Button
        uicontrol('Parent', fgt_upanel_control, 'style', 'pushbutton', 'String', 'Back', ...
            'callback',  @(a,b) fgt('step_3'), ...
            'position', [Position(3)-2*gap-2*b_width, gap, b_width, b_height]);
        
        % Next Button
        uicontrol('Parent', fgt_upanel_control, 'style', 'pushbutton', 'String', 'Next', ...
            'tag', 'next', ...
            'callback',  @(a,b) fgt('step_5'), ...
            'position', [Position(3)-gap-b_width, gap, b_width, b_height], ...
            'enable', 'off');
        
        %  Update GUI
        fgt('step_4_update_gui');
        
    case 'step_4_update_gui'
        %% - step_4_update_gui
        
        %  Get data
        Fold        = getappdata(fgt_gui_handle, 'Fold');
        fold        = getappdata(fgt_gui_handle, 'fold_number');
        flag        = getappdata(fgt_gui_handle, 'Thickness_calculation');
        
        if flag == 1 || isfield(Fold(1).Thickness.Local(1),'Value')==0
            % Calculate thickness: average thicknesses, local thicknesses, and average local thicknesses
            h = helpdlg('Calculating thickness - please be patient.', 'FGT - Thickness Calculation');
            for i = 1:length(Fold)
                
                % Calculate average thickness
                Fold(i).Thickness.Average	= thickess_aver(Fold(i).Face(1).X.Full,          Fold(i).Face(1).Y.Full,...
                    fliplr(Fold(i).Face(2).X.Full),  fliplr(Fold(i).Face(2).Y.Full));
                
                % Calculate local thickness
                [Fold(i).Thickness.Local(1).Value,       Fold(i).Thickness.Local(2).Value, ...
                 Fold(i).Thickness.Local(1).Polygon,     Fold(i).Thickness.Local(2).Polygon] = ...
                    thickness(Fold(i).Face(1).X.Full,    Fold(i).Face(1).Y.Full, ...
                              Fold(i).Face(2).X.Full,    Fold(i).Face(2).Y.Full,...
                              Fold(i).Face(1).Inflection,Fold(i).Face(2).Inflection);
                
            end
            delete(h);
            
            % Average local thickness
            for i = 1:length(Fold)
                for j = 1:2
                    Fold(i).Thickness.Local(j).Average = mean( Fold(i).Thickness.Local(j).Value );
                end
            end
            
            % Change the flag, so the thickness is not recalculated
            setappdata(fgt_gui_handle, 'Thickness_calculation', 0);
        end
        
        for j = 1:2
            % Ploting the thickness on the fold with the equal distance along
            % the upper interface
            
            if j ==1
                achse  = findobj(fgt_gui_handle, 'tag', 'axes_1');
            else
                achse  = findobj(fgt_gui_handle, 'tag', 'axes_3');
            end
            
            set(fgt_gui_handle, 'CurrentAxes', achse);
            delete(allchild(achse));
            hold on;
            axis equal;
            
            %  Fold
            for i=1:length(Fold)
                %  Plot fold
                fh  = fill([Fold(i).Face(1).X.Full fliplr(Fold(i).Face(2).X.Full)], [Fold(i).Face(1).Y.Full fliplr(Fold(i).Face(2).Y.Full)], 'k');
                set(fh, 'EdgeColor', [0.9 0.9 0.9], 'FaceColor', [.97 .97 .97]);
            end
            
            % Loop over the fold parts
            for k = 1:length(Fold(fold).Thickness.Local(j).Polygon)
                
                % Extract data
                Polygons = Fold(fold).Thickness.Local(j).Polygon{k};
                
                % Fill the fold with different colours
                if ismember(k,j:2:size(Fold(fold).Thickness.Local(j).Polygon,2))
                    fh  = fill(Polygons(1,:),Polygons(2,:), 'k');
                    set(fh, 'EdgeColor', [0.1 0.1 0.1], 'FaceColor', [.8 .8 .8]);
                else
                    fh  = fill(Polygons(1,:),Polygons(2,:), 'k');
                    set(fh, 'EdgeColor', [0.1 0.1 0.1], 'FaceColor', [.5 .5 .5]);
                end
            end
               
            % Plot inflection points
            i = 1:length(Fold);
            i(fold) = [];
            for i = i
                for k = 1:2
                    plot(Fold(i).Face(k).X.Full(Fold(i).Face(k).Inflection), Fold(i).Face(k).Y.Full(Fold(i).Face(k).Inflection), 'or','MarkerSize',1);
                end
            end
            for k = 1:2
                plot(Fold(fold).Face(k).X.Full(Fold(fold).Face(k).Inflection), Fold(fold).Face(k).Y.Full(Fold(fold).Face(k).Inflection), 'or','MarkerSize',3);
            end
            
            if j == 1
                title('Fold division based on first interface inflection poitns')
            else
                title('Fold division based on second interface inflection poitns')
            end
            
            % Thickness histogram
            if j == 1
                achse  = findobj(fgt_gui_handle, 'tag', 'axes_2');
            else
                achse  = findobj(fgt_gui_handle, 'tag', 'axes_4');
            end
            
            set(fgt_gui_handle, 'CurrentAxes', achse);
            delete(allchild(achse));
            hold on;
            
            % Histogram plot
            bar(Fold(fold).Thickness.Local(j).Value,'FaceColor',[0.7 0.7 0.7],'EdgeColor','k','BarWidth',0.5);
            xlabel('Fold number')
            ylabel('Thickness')
            title(['Mean local thickness:  ',num2str(Fold(fold).Thickness.Local(j).Average,3),'  Average thickness:  ',num2str(Fold(fold).Thickness.Average,3)])
            xlim([0 length(Fold(fold).Thickness.Local(j).Value)+1])
            ylim([0 1.2*max(Fold(fold).Thickness.Local(j).Value)])
            
        end
        
        % Activate mouse over function
        set(fgt_gui_handle,'windowbuttonmotionfcn', @(a,b) mouseover_thickness);
            
        %  Update data
        setappdata(fgt_gui_handle, 'Fold', Fold);
        
        %  Activate next button
        set(findobj(fgt_gui_handle, 'tag', 'next'), 'enable', 'on');
        
        % Deactivete fold buttons
        set(findobj(fgt_gui_handle, 'tag', 'fold_number_up'),   'enable', 'off');
        set(findobj(fgt_gui_handle, 'tag', 'fold_number_down'), 'enable', 'off');
        
        % Activatie fold number button
        if fold < size(Fold,2)
            fold_number = ['Fold number ',num2str(fold+1)];
            set(findobj(fgt_gui_handle, 'tag', 'fold_number_up'), 'enable', 'on','tooltipstring',fold_number);
        end
        if fold > 1
            fold_number = ['Fold number ',num2str(fold-1)];
            set(findobj(fgt_gui_handle, 'tag', 'fold_number_down'), 'enable', 'on','tooltipstring',fold_number);
        end
        
        units_normalized;
        
    case 'step_5'
        %% STEP_5
        
        % Put FGT into step_5 mode
        setappdata(fgt_gui_handle, 'mode', 5);
        set(fgt_gui_handle,'windowbuttonmotionfcn',[]);
        
        %  Delete all axes that may exist
        delete(findobj(fgt_gui_handle, 'type', 'axes'));
        
        %  Setup new axes
        fgt_upanel_top  = findobj(fgt_gui_handle, 'tag', 'fgt_upanel_top');
        set(fgt_upanel_top, 'Title', 'Viscosity Ratio');
        
        uc_1            = uicontainer('Parent', fgt_upanel_top, 'Units', 'Normalized', 'Position', [0.00 0.66 0.33 0.33]);
        axes('Parent', uc_1, 'tag', 'axes_1');
        box on;
        
        uc_2            = uicontainer('Parent', fgt_upanel_top, 'Units', 'Normalized', 'Position', [0.00 0.33 0.33 0.33]);
        axes('Parent', uc_2, 'tag', 'axes_2');
        box on;
        
        uc_3            = uicontainer('Parent', fgt_upanel_top, 'Units', 'Normalized', 'Position', [0.00 0.00 0.33 0.33]);
        axes('Parent', uc_3, 'tag', 'axes_3');
        box on;
        
        uc_4            = uicontainer('Parent', fgt_upanel_top, 'Units', 'Normalized', 'Position', [0.33 0.66 0.33 0.33]);
        axes('Parent', uc_4, 'tag', 'axes_4');
        box on;
        
        uc_5            = uicontainer('Parent', fgt_upanel_top, 'Units', 'Normalized', 'Position', [0.33 0.33 0.33 0.33]);
        axes('Parent', uc_5, 'tag', 'axes_5');
        box on;
        
        uc_6            = uicontainer('Parent', fgt_upanel_top, 'Units', 'Normalized', 'Position', [0.33 0.00 0.33 0.33]);
        axes('Parent', uc_6, 'tag', 'axes_6');
        box on;
        
        uc_7            = uicontainer('Parent', fgt_upanel_top, 'Units', 'Normalized', 'Position', [0.66 0.66 0.33 0.33]);
        axes('Parent', uc_7, 'tag', 'axes_7');
        box on;
        
        uc_8            = uicontainer('Parent', fgt_upanel_top, 'Units', 'Normalized', 'Position', [0.66 0.33 0.33 0.33]);
        axes('Parent', uc_8, 'tag', 'axes_8');
        box on;
        
        uc_9            = uicontainer('Parent', fgt_upanel_top, 'Units', 'Normalized', 'Position', [0.66 0.00 0.33 0.33]);
        axes('Parent', uc_9, 'tag', 'axes_9');
        box on;
        
        %  Find the control panel
        fgt_upanel_control  = findobj(fgt_gui_handle, 'Tag', 'fgt_upanel_control');
        
        % Delete all children
        uc_handles   = findobj(fgt_upanel_control, 'Type', 'uicontrol');
        delete(uc_handles);
        
        %  Default sizes
        b_height    = getappdata(fgt_gui_handle, 'b_height');
        b_width     = getappdata(fgt_gui_handle, 'b_width');
        gap         = getappdata(fgt_gui_handle, 'gap');
        
        % Size of panel
        set(fgt_upanel_control, 'Units', 'Pixels');
        Position    = get(fgt_upanel_control, 'Position');
        
        % Get button icons
        buttonUp         = getappdata(fgt_gui_handle, 'buttonUp');
        buttonDown       = getappdata(fgt_gui_handle, 'buttonDown');
        
        
        % FOLD SELECTION
        % Default fold number
        fold = 1;
        setappdata(fgt_gui_handle, 'fold_number', fold);
        
        % Text
        uicontrol('Parent', fgt_upanel_control, 'style', 'text', 'String', 'Fold', ...
            'position', [Position(2)+gap, 4*gap+3*b_height-2, b_height, b_height]);
        
        % Up Button
        uicontrol('Parent', fgt_upanel_control, 'style', 'pushbutton',...
            'cdata',buttonUp,'units','pixels',...
            'tag','fold_number_up',...
            'callback',  @f_number, ...
            'position', [Position(2)+gap, 3*gap+2*b_height, b_height, b_height],...
            'enable', 'off');
        
        % Down Button
        uicontrol('Parent', fgt_upanel_control, 'style', 'pushbutton',...
            'cdata',buttonDown,'units','pixels',...
            'tag','fold_number_down',...
            'callback',  @f_number, ...
            'position', [Position(2)+gap, 1*gap,            b_height, b_height],...
            'enable', 'off');
        
        % Set fold number
        uicontrol('Parent', fgt_upanel_control, 'style', 'text', 'String',num2str(fold),...
            'position', [Position(2)+gap, 2*gap+1*b_height,  b_height, b_height]);
        
        
        %  Get data
        Fold        = getappdata(fgt_gui_handle, 'Fold');
        
        % POISSON and STRETCH RATIOS
        % Poisson ratio
        % Text
        uicontrol('Parent', fgt_upanel_control, 'style', 'text', 'String', 'nu','HorizontalAlignment','left', ...
            'position', [Position(3)-4*gap-4*b_width, 4*gap+3*b_height-2, b_width, b_height]);
        
        % Edit
        if isfield(Fold,'poisson')==0
            uicontrol('Parent', fgt_upanel_control, 'style', 'edit', 'String', '0.25',...
                'callback',  @(a,b)  fgt('step_5_update_gui'), ...
                'tooltipstring','Poisson ratio',...
                'tag', 'step_5_poisson', ...
                'position', [Position(3)-3*gap-3*b_width, 4*gap+3*b_height, b_width, b_height]);
        else
            uicontrol('Parent', fgt_upanel_control, 'style', 'edit', 'String', num2str(Fold(1).poisson),...
                'callback',  @(a,b)  fgt('step_5_update_gui'), ...
                'tooltipstring','Poisson ratio',...
                'tag', 'step_5_poisson', ...
                'position', [Position(3)-3*gap-3*b_width, 4*gap+3*b_height, b_width, b_height]);
        end
        
        % Stetching ratio
        % Text
        uicontrol('Parent', fgt_upanel_control, 'style', 'text', 'String', 'S','HorizontalAlignment','left', ...
            'position', [Position(3)-2*gap-2*b_width, 4*gap+3*b_height-2, b_width, b_height]);
        
        % Edit
        if isfield(Fold,'poisson')==0
            uicontrol('Parent', fgt_upanel_control, 'style', 'edit', 'String', '1', ...
                'callback',  @(a,b)  fgt('step_5_update_gui'), ...
                'tag', 'step_5_stretch', ...
                'tooltipstring','Stretching ratio',...
                'position', [Position(3)-gap-b_width, 4*gap+3*b_height, b_width, b_height]);
        else
            uicontrol('Parent', fgt_upanel_control, 'style', 'edit', 'String', num2str(Fold(1).stretch), ...
                'callback',  @(a,b)  fgt('step_5_update_gui'), ...
                'tag', 'step_5_stretch', ...
                'tooltipstring','Stretching ratio',...
                'position', [Position(3)-gap-b_width, 4*gap+3*b_height, b_width, b_height]);
        end
        
        % POWER LAW EXPONENTS
        % Text
        uicontrol('Parent', fgt_upanel_control, 'style', 'text', 'String', 'Power Law of: ','HorizontalAlignment','right', ...
            'position', [Position(3)-6*gap-6*b_width, 3*gap+2*b_height-2, 2*b_width, b_height]);
        
        % Power Law for layer
        % Text
        uicontrol('Parent', fgt_upanel_control, 'style', 'text', 'String', 'Layer','HorizontalAlignment','left', ...
            'position', [Position(3)-4*gap-4*b_width, 3*gap+2*b_height-2, b_width, b_height]);
        % Edit
        if isfield(Fold,'power_law_layer')==0
            uicontrol('Parent', fgt_upanel_control, 'style', 'edit', 'String', '1',...
                'callback',  @(a,b)  fgt('step_5_update_gui'), ...
                'tag', 'step_5_power_law_layer', ...
                'tooltipstring','Power law exponent of layer',...
                'position', [Position(3)-3*gap-3*b_width, 3*gap+2*b_height, b_width, b_height]);
        else
            uicontrol('Parent', fgt_upanel_control, 'style', 'edit', 'String', num2str(Fold(1).power_law_layer,3),...
                'callback',  @(a,b)  fgt('step_5_update_gui'), ...
                'tag', 'step_5_power_law_layer', ...
                'tooltipstring','Power law exponent of layer',...
                'position', [Position(3)-3*gap-3*b_width, 3*gap+2*b_height, b_width, b_height]);
        end
        
        % Power Law for matrix
        % Text
        uicontrol('Parent', fgt_upanel_control, 'style', 'text', 'String', 'Matrix','HorizontalAlignment','left', ...
            'position', [Position(3)-2*gap-2*b_width, 3*gap+2*b_height-2, b_width, b_height]);
        
        % Edit
        if isfield(Fold,'power_law_matrix')==0
            uicontrol('Parent', fgt_upanel_control, 'style', 'edit', 'String', '1', ...
                'callback',  @(a,b)  fgt('step_5_update_gui'), ...
                'tag', 'step_5_power_law_matrix', ...
                'tooltipstring','Power law exponent of matrix',...
                'position', [Position(3)-gap-b_width, 3*gap+2*b_height, b_width, b_height]);
        else
            uicontrol('Parent', fgt_upanel_control, 'style', 'edit', 'String', num2str(Fold(1).power_law_matrix,3), ...
                'callback',  @(a,b)  fgt('step_5_update_gui'), ...
                'tag', 'step_5_power_law_matrix', ...
                'tooltipstring','Power law exponent of matrix',...
                'position', [Position(3)-gap-b_width, 3*gap+2*b_height, b_width, b_height]);
        end
        
        % THICKNESS METHOD
        % Text
        uicontrol('Parent', fgt_upanel_control, 'style', 'text', 'String', 'Thickness','HorizontalAlignment','left', ...
            'position', [Position(3)-2*gap-2*b_width, 2*gap+b_height-2, b_width, b_height]);
        
        % Button
        uicontrol('Parent', fgt_upanel_control, 'style', 'popupmenu', 'String', {'1';'2'}, 'value', 1, 'HorizontalAlignment','center', ...
            'callback',  @(a,b)  fgt('step_5_update_gui'), ...
            'tag', 'step_5_thickness', ...
            'position', [Position(3)-gap-b_width, 2*gap+b_height, b_width, b_height]);
        
        
        % Back Button
        uicontrol('Parent', fgt_upanel_control, 'style', 'pushbutton', 'String', 'Back', ...
            'callback',  @(a,b) fgt('step_4'), ...
            'position', [Position(3)-2*gap-2*b_width, gap, b_width, b_height]);
        
        % Next Button
        uicontrol('Parent', fgt_upanel_control, 'style', 'pushbutton', 'String', 'Next', ...
            'tag', 'next', ...
            'callback',  @(a,b) fgt('step_6'), ...
            'position', [Position(3)-gap-b_width, gap, b_width, b_height], ...
            'enable', 'off');
        
        units_normalized;
        
        %  Update GUI
        fgt('step_5_update_gui');
        
    case 'step_5_update_gui'
        %% - step_5_update_gui
        
        %  Get Data
        Fold    = getappdata(fgt_gui_handle, 'Fold');
        fold    = getappdata(fgt_gui_handle, 'fold_number');
        
        %  Read data
        thickness_method       	    = get(findobj(fgt_gui_handle, 'tag', 'step_5_thickness'),        'value');  
        Fold(1).power_law_layer  	= str2double(get(findobj(fgt_gui_handle, 'tag', 'step_5_power_law_layer'),  'string'));
        Fold(1).power_law_matrix  	= str2double(get(findobj(fgt_gui_handle, 'tag', 'step_5_power_law_matrix'), 'string'));
        Fold(1).poisson           	= str2double(get(findobj(fgt_gui_handle, 'tag', 'step_5_poisson'),          'string'));
        Fold(1).stretch           	= str2double(get(findobj(fgt_gui_handle, 'tag', 'step_5_stretch'),          'string'));
        
        % Display warning messages if necessary
        if Fold(1).poisson > 0.5 || Fold(1).poisson < -1
            eh = errordlg('The Poisson''s ratio of an isotropic, linear elastic material cannot be less than -1.0 nor greater than 0.5.', 'FGT - Error', 'modal');
            uiwait(eh);
        end
        if Fold(1).stretch < 0
            eh = errordlg('The streching ratio cannot be less than 0.', 'FGT - Error', 'modal');
            uiwait(eh);
        end
        
        % Equations
        Equations = {'$$\frac{L}{h} = 2 \pi \sqrt[3]{\frac{\mu_l}{6 \mu_m}} $$',...
            '$$\frac{L}{h} = 2 \pi \sqrt[3]{\frac{E_l}{6 E_m}} $$',...
            '$$\frac{L}{h} = \pi \sqrt{\frac{E_l}{P (1- \nu_l^2)}} $$',...
            '$$\frac{L}{h} = 2 \pi \sqrt[3]{\frac{N \mu_l}{6 \mu_m}} $$',...
            '',...
            '$$\frac{L}{h} = 2 \pi \sqrt[3]{\frac{\mu_l}{6 \mu_m} \frac{S_x^2(S_x^2+1)}{2}} $$',...
            '$$\frac{L}{h} = 2 \pi \sqrt[3]{\frac{\mu_l}{6 \mu_m} \frac{\sqrt{n_m}}{n_l}} $$',...
            '$$\frac{\mu_l}{\mu_m} = \frac{1+e^{2 \frac{\pi h}{L_d}} \sqrt{ \frac{1-2\frac{\pi h}{L_d}}{1+2\frac{\pi h}{L_d}}} }{1-e^{2\frac{\pi h}{L_d}} \sqrt{ \frac{1-2\frac{\pi h}{L_d}}{1+2\frac{\pi h}{L_d}}}} $$',...
            '$$\frac{\mu_l}{\mu_m} = \frac{1+cosh(2 \frac{\pi h}{L_d})-2k_d sinh(2\frac{\pi h}{L_d})}{2\frac{\pi h}{L_d} cosh(2\frac{\pi h}{L_d})-sinh(2\frac{\pi h}{L_d})} $$'};
        
        % Unknown ratio
        Unknown = {'$$ \frac{\mu_l}{\mu_m} = $$',...
            '$$ \frac{E_l}{E_m} = $$',...
            '$$ \frac{E_l}{P} = $$',...
            '$$ \frac{\mu_l}{\mu_m} = $$',...
            '',...
            '$$ \frac{\mu_l}{\mu_m} = $$',...
            '$$ \frac{\mu_l}{\mu_m} = $$',...
            '$$ \frac{\mu_l}{\mu_m} = $$',...
            '$$ \frac{\mu_l}{\mu_m} = $$'};
        
        % Authors
        Authors = {'Linear viscous (Biot, 1961)',...
            'Linear elastic (Currie et al., 1962)',...
            'Visco-elastic (Biot, 1961)',...
            'Multilayer linear viscous (Biot, 1965)',...
            ''...
            'Thickening correction (Sherwin and Chapple, 1968)',...
            'Non-linear viscous (Fletcher, 1974)',...
            'Thick plate, no slip bc. (Fletcher, 1977)',...
            'Thick plate, free slip bc. (Fletcher, 1977)'};
        
        
       % Calculate an average arc length
        Arclength = mean(2*[(Fold(fold).Face(1).Arclength.Full(Fold(fold).Face(1).Inflection(2:end))-Fold(fold).Face(1).Arclength.Full(Fold(fold).Face(1).Inflection(1:end-1)))...
                            (Fold(fold).Face(2).Arclength.Full(Fold(fold).Face(2).Inflection(2:end))-Fold(fold).Face(2).Arclength.Full(Fold(fold).Face(2).Inflection(1:end-1)))]);
                   
        % Define thickness
        if thickness_method == 1
            Thickness   = mean([Fold(fold).Thickness.Local(1).Value Fold(fold).Thickness.Local(2).Value]);
        end
        if thickness_method == 2
            Thickness   = Fold(fold).Thickness.Average;
        end
        
        % Calculate the unknown ratio
        kd        = pi*Thickness./Arclength;
        Solutions = [...
            6*(Arclength./(2*pi*Thickness)).^3; ...
            6*(Arclength./(2*pi*Thickness)).^3; ...
            (Arclength./(pi*Thickness)).^2*(1-Fold(1).poisson^2);...
            (6/size(Fold,2))*(Arclength./(2*pi*Thickness)).^3;...
            NaN*ones(1,max([length(Arclength),length(Thickness)]));...
            12*(Arclength./(2*pi*Thickness)).^3/( (Fold(1).stretch)^2 * (Fold(1).stretch^2 + 1) );...
            6*(Arclength./(2*pi*Thickness)).^3*Fold(1).power_law_layer/sqrt(Fold(1).power_law_matrix);...
            abs( 1+exp(2*kd).* sqrt( (1-2*kd)./(1+2*kd) ) ./( 1-exp(2*kd).* sqrt( (1-2*kd)./(1+2*kd) ) ));...
            ( 1+cosh(2*kd)-2*kd.*sin(2*kd) )./( 2*kd.*cosh(2*kd)-sinh(2*kd) )];
        
        
        for i = [1:4, 6:9];
            % Remove Imaginary Numbers
            Solution            = Solutions(i,imag(Solutions(i,:))==0);
            
            achse  = findobj(fgt_gui_handle, 'tag', ['axes_',num2str(i)]);
            set(fgt_gui_handle, 'CurrentAxes', achse);
            delete(allchild(achse));
            hold(achse, 'on');
            
            % Display equation and solution to the equation 
            text('position',[.5 .6], 'fontsize',12,'HorizontalAlignment','Center',...
                'interpreter','latex','string',Equations{i}, 'parent', achse);
            text('position',[.5 .2], 'fontsize',12,'HorizontalAlignment','Center',...
                'interpreter','latex','string',[Unknown{i},num2str(mean(Solution),'%2.1f')], ...
                'parent', achse);
            
            set(achse, 'XTick', [], 'YTick', []);
            title(achse, [Authors{i}]);
            
        end
        
        %  5. Fold
        achse  = findobj(fgt_gui_handle, 'tag', 'axes_5');
        set(fgt_gui_handle, 'CurrentAxes', achse);
        hold on;
        
        for j=1:length(Fold)
            fh  = fill([Fold(j).Face(1).X.Norm fliplr(Fold(j).Face(2).X.Norm)], [Fold(j).Face(1).Y.Norm fliplr(Fold(j).Face(2).Y.Norm)], 'k');
            set(fh, 'EdgeColor', [0.9 0.9 0.9], 'FaceColor', [.97 .97 .97]);
        end
        fh  = fill([Fold(fold).Face(1).X.Norm fliplr(Fold(fold).Face(2).X.Norm)], [Fold(fold).Face(1).Y.Norm fliplr(Fold(fold).Face(2).Y.Norm)], 'k');
        set(fh, 'EdgeColor', [0 0 0], 'FaceColor', [.5 .5 .5]);
        title(['Average L/h:  ', num2str(mean(Arclength./Thickness),'%2.2f')]);
        axis equal;
        axis on;
        set(gca,'XTick',[],'YTick',[])
        zoom off;
        
        %  Update data
        setappdata(fgt_gui_handle, 'Fold', Fold);
        
        %  Activate next button
        set(findobj(fgt_gui_handle, 'tag', 'next'), 'enable', 'on');
        
        % Deactivete fold buttons
        set(findobj(fgt_gui_handle, 'tag', 'fold_number_up'),   'enable', 'off');
        set(findobj(fgt_gui_handle, 'tag', 'fold_number_down'), 'enable', 'off');
        
        % Activatie fold number button
        if fold < size(Fold,2)
            fold_number = ['Fold number ',num2str(fold+1)];
            set(findobj(fgt_gui_handle, 'tag', 'fold_number_up'), 'enable', 'on','tooltipstring', fold_number);
        end
        if fold > 1
            fold_number = ['Fold number ',num2str(fold-1)];
            set(findobj(fgt_gui_handle, 'tag', 'fold_number_down'), 'enable', 'on','tooltipstring', fold_number);
        end
        
        units_normalized;

    case 'step_6'
        %% STEP_6
        
        % Put FGT into step_6 mode
        setappdata(fgt_gui_handle, 'mode', 6);
        set(fgt_gui_handle,'windowbuttonmotionfcn',[]);
        
        %  Delete all axes that may exist
        delete(findobj(fgt_gui_handle, 'type', 'axes'));
        
        %  Setup new axes
        fgt_upanel_top  = findobj(fgt_gui_handle, 'tag', 'fgt_upanel_top');
        set(fgt_upanel_top, 'Title', 'Strain & Viscosity Ratio');
        
        uc_1            = uicontainer('Parent', fgt_upanel_top, 'Units', 'Normalized', 'Position', [0.0 0.0 0.5 1]);
        axes('Parent', uc_1, 'tag', 'axes_1');
        box on;
        
        uc_2            = uicontainer('Parent', fgt_upanel_top, 'Units', 'Normalized', 'Position', [0.5 0.0 0.5 1]);
        axes('Parent', uc_2, 'tag', 'axes_2');
        box on;
        
        %  Find the control panel
        fgt_upanel_control  = findobj(fgt_gui_handle, 'Tag', 'fgt_upanel_control');
        
        % Delete all children
        uc_handles   = findobj(fgt_upanel_control, 'Type', 'uicontrol');
        delete(uc_handles);
        
        %  Default sizes
        b_height    = getappdata(fgt_gui_handle, 'b_height');
        b_width     = getappdata(fgt_gui_handle, 'b_width');
        gap         = getappdata(fgt_gui_handle, 'gap');
        
        % Size of panel
        set(fgt_upanel_control, 'Units', 'Pixels');
        Position    = get(fgt_upanel_control, 'Position');
        
        %  Get data
        Fold        = getappdata(fgt_gui_handle, 'Fold');
        
        % RAY C. FLETCHER AND JO-ANN SHERWIN METHOD
        
        % Text
        uicontrol('Parent', fgt_upanel_control, 'style', 'text', 'String', 'Power Law of: ','HorizontalAlignment','left', ...
            'position', [Position(3)-6*gap-6*b_width, 3*gap+2*b_height-2, 2*b_width, b_height]);
        
        % Power Law of layer
        % Text
        uicontrol('Parent', fgt_upanel_control, 'style', 'text', 'String', 'Layer','HorizontalAlignment','left', ...
            'position', [Position(3)-4*gap-4*b_width, 3*gap+2*b_height-2, b_width, b_height]);
        
        % Edit
        uicontrol('Parent', fgt_upanel_control, 'style', 'edit', 'String', num2str(Fold(1).power_law_layer,3),...
            'callback',  @(a,b)  fgt('step_6_update_gui'), ...
            'tag', 'step_6_power_law_layer', ...
            'position', [Position(3)-3*gap-3*b_width, 3*gap+2*b_height, b_width, b_height]);
        
        % Power Law of matrix
        % Text
        uicontrol('Parent', fgt_upanel_control, 'style', 'text', 'String', 'Matrix','HorizontalAlignment','left', ...
            'position', [Position(3)-2*gap-2*b_width, 3*gap+2*b_height-2, b_width, b_height]);
        
        % Edit
        uicontrol('Parent', fgt_upanel_control, 'style', 'edit', 'String', num2str(Fold(1).power_law_matrix,3), ...
            'callback',  @(a,b)  fgt('step_6_update_gui'), ...
            'tag', 'step_6_power_law_matrix', ...
            'position', [Position(3)-gap-b_width, 3*gap+2*b_height, b_width, b_height]);
        
        
        % STEFAN M. SCHMALHOLZ & YURI Y. PODLADCHIKOV METHOD
        
        % AMPLITUDE METHOD
        % Text
        uicontrol('Parent', fgt_upanel_control, 'style', 'text', 'String', 'Amplitude','HorizontalAlignment','left', ...
            'position', [Position(3)-6*gap-6*b_width, 2*gap+b_height-2, b_width, b_height]);
        
        % Button
        uicontrol('Parent', fgt_upanel_control, 'style', 'popupmenu', 'String', {'1';'2';'3'}, 'value', 1, ...
            'callback',  @(a,b)  fgt('step_6_update_gui'), ...
            'tag', 'step_6_amplitude', ...
            'position', [Position(3)-5*gap-5*b_width, 2*gap+b_height, b_width, b_height]);
        
        % WAVELENGTH METHOD
        % Text
        uicontrol('Parent', fgt_upanel_control, 'style', 'text', 'String', 'Wavelength','HorizontalAlignment','left', ...
            'position', [Position(3)-4*gap-4*b_width, 2*gap+b_height-2, b_width, b_height]);
        
        % Button
        uicontrol('Parent', fgt_upanel_control, 'style', 'popupmenu', 'String', {'1';'2';'3';'4'}, 'value', 1, ...
            'callback',  @(a,b)  fgt('step_6_update_gui'), ...
            'tag', 'step_6_wavelength', ...
            'position', [Position(3)-3*gap-3*b_width, 2*gap+b_height, b_width, b_height]);
        
        % THICKNESS METHOD
        % Text
        uicontrol('Parent', fgt_upanel_control, 'style', 'text', 'String', 'Thickness','HorizontalAlignment','left', ...
            'position', [Position(3)-2*gap-2*b_width, 2*gap+b_height-2, b_width, b_height]);
        
        % Button
        uicontrol('Parent', fgt_upanel_control, 'style', 'popupmenu', 'String', {'1';'2'}, 'value', 1, ...
            'callback',  @(a,b)  fgt('step_6_update_gui'), ...
            'tag', 'step_6_thickness', ...
            'position', [Position(3)-gap-b_width, 2*gap+b_height, b_width, b_height]);
        
        % Back Button
        uicontrol('Parent', fgt_upanel_control, 'style', 'pushbutton', 'String', 'Back', ...
            'callback',  @(a,b) fgt('step_5'), ...
            'position', [Position(3)-2*gap-2*b_width, gap, b_width, b_height]);
        
        % Next Button
        uicontrol('Parent', fgt_upanel_control, 'style', 'pushbutton', 'String', 'Next', ...
            'tag', 'next', ...
            'callback',  @(a,b) fgt('step_6'), ...
            'position', [Position(3)-gap-b_width, gap, b_width, b_height], ...
            'enable', 'off');
        
        units_normalized;
        
        %  Update GUI
        fgt('step_6_update_gui');
        
    case 'step_6_update_gui'
        %% - step_6_update_gui
        
        %  Get Data
        Fold    = getappdata(fgt_gui_handle, 'Fold');
        
        %  Read data
        amplitude_method    = get(findobj(fgt_gui_handle, 'tag', 'step_6_amplitude'),        'value');
        wavelength_method   = get(findobj(fgt_gui_handle, 'tag', 'step_6_wavelength'),       'value');
        thickness_method    = get(findobj(fgt_gui_handle, 'tag', 'step_6_thickness'),        'value');
        Fold(1).power_law_layer 	= str2double(get(findobj(fgt_gui_handle, 'tag', 'step_6_power_law_layer'),  'string'));
        Fold(1).power_law_matrix  	= str2double(get(findobj(fgt_gui_handle, 'tag', 'step_6_power_law_matrix'), 'string'));
        
        
        % RAY C. FLETCHER AND JO-ANN SHERWIN METHOD
        % Calculate contours for viscosity ratio and strain plot
        Fold(1).power_law_layer  = max([1.0001, Fold(1).power_law_layer]);
        Fold(1).power_law_matrix = max([1.0001, Fold(1).power_law_matrix]);
        
        %  Update data
        setappdata(fgt_gui_handle, 'Fold', Fold);
        
        %  Calculate strain and viscosity ratio
        [lohs,bees,RRR,SSS] = fletcher_sherwin(Fold(1).power_law_layer, Fold(1).power_law_matrix);
        
        % Plotting
        
        % Set axes
        achse  = findobj(fgt_gui_handle, 'tag', 'axes_1');
        set(fgt_gui_handle, 'CurrentAxes', achse);
        
        delete(allchild(achse));
        hold on;
        grid on;
        axis square;
        
        % Define and plot the viscosity ratio contours
        rcon = [10:10:100 150 200];
        [C,h]  = contour(lohs,bees,RRR,rcon,'k');
        text_handle = clabel(C,h);
        set(text_handle,'BackgroundColor',[1 1 1],'Color','k')
        
        % Define and plot the strain contours
        escon = [0.1:0.1:0.9 0.95];
        [C,h] = contour(lohs,bees,SSS,escon,'b');
        text_handle = clabel(C,h);
        set(text_handle,'BackgroundColor',[1 1 1],'Color','b')
        
        %Limit axes
        axis([2 17 0.5 3.0])
        
        xlabel('L_P/H');
        ylabel('{\beta}^*');
        title('Fletcher & Sherwin (1978)')
        
        
        % STEFAN M. SCHMALHOLZ & YURI Y. PODLADCHIKOV METHOD
        
        %  Generate plot
        
        % Load numerical data
        Vis = load('schmalholz_podladchikov.mat');
        
        % Set axes
        achse  = findobj(fgt_gui_handle, 'tag', 'axes_2');
        set(fgt_gui_handle, 'CurrentAxes', achse);
        
%         delete(allchild(achse));
        hold on;
        
        % Plot viscosity contours
        % The actual data is plotted with the plot statement below. The
        % contour labels are generated with a low resolution (fast) data
        % grid of the same data. Of this only the labels are needed and
        % therfor they are copyied with the copyobj and assigned to the
        % axes. The original countours and their labels are then deleted.
        [co ch] = contour(Vis.XX,Vis.YY,Vis.ZZ,[10 10, 25 25, 50 50, 100 100, 250 250],'-w');
        cc = clabel(co,ch,'LabelSpacing',150, 'BackgroundColor','w','Color','k');
        plot(Vis.H2L_num10, Vis.A2L_num10, '-k',...
            Vis.H2L_num25, Vis.A2L_num25, '-k',...
            Vis.H2L_num50, Vis.A2L_num50, '-k',...
            Vis.H2L_num100,Vis.A2L_num100,'-k',...
            Vis.H2L_num250,Vis.A2L_num250,'-k');
        copyobj(cc,gca);
        delete(ch);
        
        % Plot strain contours
        [co ch] = contour(Vis.H2L_map,Vis.A2L_map,Vis.Strain_map',[0.10,0.20,0.30,0.40,0.50,0.60,0.65,0.70], '-b');
        clabel(co,ch,'LabelSpacing',150, 'BackgroundColor','w','Color','b');
        
        % Limit Axis
        axis([0 0.7 0 0.9])
        
        axis square;
        grid on;
        xlabel('H / \lambda')
        ylabel('A / \lambda')
        title('Schmalholz & Podladchikov (2001)')
        
        %  Plot FGT data points
        for fold = 1:length(Fold)
            
            achse  = findobj(fgt_gui_handle, 'tag', 'axes_1');
            set(fgt_gui_handle, 'CurrentAxes', achse);
            
            % UPPER
            %  Arc length between the two neighbouring inflection points of
            %  the upper and lower interface
            Arc_upper = 2*(Fold(fold).Face(1).Arclength.Full(Fold(fold).Face(1).Inflection(2:end))-Fold(fold).Face(1).Arclength.Full(Fold(fold).Face(1).Inflection(1:end-1)));
            Arc_lower = 2*(Fold(fold).Face(2).Arclength.Full(Fold(fold).Face(2).Inflection(2:end))-Fold(fold).Face(2).Arclength.Full(Fold(fold).Face(2).Inflection(1:end-1)));
            
            %  Calculate data distribution
            L2H_upper     = mean(Arc_upper./Fold(fold).Thickness.Local(1).Value);
            L2H_lower     = mean(Arc_lower./Fold(fold).Thickness.Local(2).Value);
            delta_upper   = std(Arc_upper./Fold(fold).Thickness.Local(1).Value)/mean(Arc_upper./Fold(fold).Thickness.Local(1).Value);
            delta_lower   = std(Arc_lower./Fold(fold).Thickness.Local(2).Value)/mean(Arc_lower./Fold(fold).Thickness.Local(2).Value);
            betas_upper   = 5.3*delta_upper.^2 + 1.1*delta_upper;
            betas_lower   = 5.3*delta_lower.^2 + 1.1*delta_lower;

            %  Plot points on the diagram
            h1 = plot(L2H_upper,betas_upper,'o','MarkerSize',10,'MarkerEdgeColor','k','MarkerFaceColor','r');
                 plot(L2H_lower,betas_lower,'o','MarkerSize',10,'MarkerEdgeColor','k','MarkerFaceColor','r');
            
            %  Plot data
            achse  = findobj(fgt_gui_handle, 'tag', 'axes_2');
            set(fgt_gui_handle, 'CurrentAxes', achse);
            
            for face = 1:2
                
                if amplitude_method == 1
                    Amplitude   = Fold(fold).Face(face).Amplitude(1).Value;
                elseif amplitude_method == 2
                    Amplitude   = Fold(fold).Face(face).Amplitude(2).Value;
                else
                    Amplitude   = Fold(fold).Face(face).Amplitude(3).Value;
                end
                
                if wavelength_method ==1
                    Wavelength = Fold(fold).Face(face).Wavelength(1).Value;
                elseif wavelength_method ==2
                    Wavelength = Fold(fold).Face(face).Wavelength(2).Value;
                elseif wavelength_method ==3
                    Wavelength = Fold(fold).Face(face).Wavelength(3).Value;
                else
                    Wavelength = Fold(fold).Face(face).Wavelength(4).Value;
                end
                
                if thickness_method == 1
                    Thickness   = Fold(fold).Thickness.Local(face).Value;
                else
                    Thickness   = Fold(fold).Thickness.Average;
                end
                
                % All values
                h2(1) = plot(Thickness./Wavelength, Amplitude./Wavelength,...
                        'o','MarkerSize',7,'MarkerEdgeColor','k','MarkerFaceColor','b');
                % Mean values
                h2(2) = plot(mean(Thickness./Wavelength), mean(Amplitude./Wavelength),...
                        'o','MarkerSize',10,'MarkerEdgeColor','k','MarkerFaceColor','r');                
            end
        end
        
        % Legend
        achse  = findobj(fgt_gui_handle, 'tag', 'axes_1');
        set(fgt_gui_handle, 'CurrentAxes', achse);
        
        % Add two fake lines to the plot so that not the standard contour
        % symbol is used in the legend
        ll(1)   = plot([0 0], [0 0], '-b');
        ll(2)   = plot([0 0], [0 0], '-k');
        
        % Together with the last two plot statements this can be used to
        % make the legend
        legend([ll, h1],'Stretch', 'Viscosity Ratio', 'Data');
        
        % Legend
        achse  = findobj(fgt_gui_handle, 'tag', 'axes_2');
        set(fgt_gui_handle, 'CurrentAxes', achse);
              
        % Add two fake lines to the plot so that not the standard contour
        % symbol is used in the legend
        ll(1)   = plot([0 0], [0 0], '-b');
        ll(2)   = plot([0 0], [0 0], '-k');
        
        % Together with the last two plot statements this can be used to
        % make the legend
        legend([ll, h2],'Shortening', 'Viscosity Ratio', 'Data1', 'Data2');
end

%% fun assert_install
    function assert_install(Checkfile, Subdir, Description, Url)
        % Make sure required Matlab File Exchange (FEX) components are
        % installed
        if ~exist(Checkfile, 'file')
            if ~exist(Subdir, 'dir')
                % The package has not been downloaded and unzipped yet
                yes = 'Yes - Install package';
                no = 'No - Do not install';
                userchoice = questdlg(['FGT requires ' Description, ' from the Matlab File Exchange. ', 'Shall FGT download and install this for you?'], 'FGT: Missing Component', yes, no, yes);
                
                % Handle response
                switch userchoice
                    case yes
                        [f,status] = urlwrite(Url, [Subdir, '.zip']);
                        
                        if status==0
                            uiwait(warndlg({'No connection to Matlab File Exchange, or package does not exist under the link any longer.', ...
                                'Failed to install ', Description} , ...
                                'Package cannot be downloaded', ...
                                'modal'));
                        end
                        
                        % Unzip 
                        unzip([Subdir, '.zip'], Subdir);
                        
                        % Remove File
                        delete([Subdir, '.zip']);
                        
                    otherwise
                        %Oh well, then it will not work
                end
            end
            
            % Add the subdirectories to the path
            subdir_add([pwd, filesep, Subdir]);
            
            % Make sure that Checkfile is now on the path
            if ~exist(Checkfile, 'file')
                uiwait(warndlg({[Checkfile, ' is still not on path.'] 'Failed to install package.' ['Try to install ', Description, ' manually.']}, ...
                    'Package not installed', ...
                    'modal'));
            end
        end            
    end

%% fun subdir_add
    function subdir_add(Subdir)
        % Add this subdirectory
        addpath(Subdir);
        
        % Check if subdirectories exist - Recursion
        Files   = dir(Subdir);
        for ff=1:length(Files)
            if Files(ff).isdir && ~strcmp(Files(ff).name, '.') && ~strcmp(Files(ff).name, '..')
                subdir_add([Subdir, filesep, Files(ff).name])                
            end
        end
    end

%% fun norminitialize_fold_structure
    function norminitialize_fold_structure()
        
        % Get Data
        Fold    = getappdata(fgt_gui_handle, 'Fold');
        
        %  Find the arc length of the fold's first interface
        Arc_length  = sqrt( (Fold(1).Face(1).X.Ori(2:end)-Fold(1).Face(1).X.Ori(1:end-1)).^2 + (Fold(1).Face(1).Y.Ori(2:end)-Fold(1).Face(1).Y.Ori(1:end-1)).^2 );
        Arc_length  = [0 cumsum(Arc_length)];
        
        Shift   = Fold(1).Face(1).X.Ori(1);
            
        %  Normalize the fold
        for i = 1:length(Fold)
            for j = 1:2
                Fold(i).Face(j).X.Norm = (Fold(i).Face(j).X.Ori - Shift)/Arc_length(end);
                Fold(i).Face(j).Y.Norm = (Fold(i).Face(j).Y.Ori        )/Arc_length(end);
            end
        end
        
        %  Set Default Filter Width if not exist
        if isfield(Fold(1),'filter_width') == 0
            Fold(1).filter_width        = 0.01;
        end
        
        %  Set Default Fraction
        if isfield(Fold(1),'fraction') == 0
            Fold(1).fraction            = 0.10;
        end
        
        %  Set Default Hinge Method
        if isfield(Fold(1),'hinge_method') == 0
            Fold(1).hinge_method        = 1;
        end
        
        %  Set the numer of nodes used for curvature calculations
        if isfield(Fold(1),'order') == 0
            Fold(1).order               = 3;
        end
        
        % Put Data
        setappdata(fgt_gui_handle, 'Fold', Fold);
    end

%% fun units_normalized
    function units_normalized
        % For the layout pixel untis are used. For the resizing to work
        % normalized has to be used
        % 'tag', 'fgt_gui_handle'
        Ui  = findobj(0, 'type', 'uipanel', '-or', 'type', 'uicontrol');
        %set(fgt_gui_handle, 'Unit', 'normalized');
        set(Ui, 'Unit', 'normalized');
        
    end

%% fun fgt_zoom
    function fgt_zoom(obj, event_obj)
        zoom_status     = {'off', 'on'};
        zoom(fgt_gui_handle, zoom_status{get(obj,'value')+1});
    end

%% fun f_number
    function f_number(obj, event_obj)
        % Gets currently active fold interface
        
        % Get data
        fold    = getappdata(fgt_gui_handle, 'fold_number');
        face    = getappdata(fgt_gui_handle, 'face_number');
        
        %  Find the control panel
        fgt_upanel_control  = findobj(fgt_gui_handle, 'Tag', 'fgt_upanel_control');
        
        %  Default sizes
        b_height    = getappdata(fgt_gui_handle, 'b_height');
        gap         = getappdata(fgt_gui_handle, 'gap');
        
        % Size of panel
        set(fgt_upanel_control, 'Units', 'Pixels');
        Position    = get(fgt_upanel_control, 'Position');
        
        if strcmp(get(gco,'Tag'),'fold_number_up')
            fold    = fold + 1;
        elseif strcmp(get(gco,'Tag'),'fold_number_down')
            fold    = fold - 1;
        elseif strcmp(get(gco,'Tag'),'face_number_up')
            face    = face - 1;
        elseif strcmp(get(gco,'Tag'),'face_number_down')
            face    = face + 1;
        end
        
        setappdata(fgt_gui_handle, 'fold_number', fold);
        setappdata(fgt_gui_handle, 'face_number', face);
        
        % Get fgt step mode
        mode = getappdata(fgt_gui_handle, 'mode');
        
        % Set fold or face number
        if mode == 2
            uicontrol('Parent', fgt_upanel_control, 'style', 'text', 'String',num2str(fold),...
                'position', [Position(2)+gap, 2*gap+1*b_height,  b_height, b_height]);
            uicontrol('Parent', fgt_upanel_control, 'style', 'text', 'String',num2str(face),...
                'position', [Position(2)+3*gap+b_height, 2*gap+1*b_height,  b_height, b_height]);
        else
            uicontrol('Parent', fgt_upanel_control, 'style', 'text', 'String',num2str(fold),...
                'position', [Position(2)+gap, 2*gap+1*b_height,  b_height, b_height]);
        end
        
        % Go back to the proper step mode
        fgt(['step_',num2str(mode),'_update_gui']);
        
    end

%%  fun mouseover
    function mouseover()
        
        % Need to make sure that root unit is pixels
        set(0, 'Units', 'Pixels');
        
        % Handles to the two axes
        axes_1      = findobj(fgt_gui_handle, 'tag', 'axes_1');
        axes_2      = findobj(fgt_gui_handle, 'tag', 'axes_2');
        
        % Get pointer location w.r.t. Curvature-Arclength plot (axes_2)
        Screen_xy 	= get(0,'PointerLocation');
        Figure_xy  	= getpixelposition(fgt_gui_handle);
        Axes_xy    	= getpixelposition(axes_2, true);
        Xlim        = get(axes_2, 'XLim');
        Ylim        = get(axes_2, 'YLim');
        axes_x      = Screen_xy(1) - Axes_xy(1) - Figure_xy(1);
        axes_x      = axes_x/Axes_xy(3)*(Xlim(2)-Xlim(1)) + Xlim(1);
        axes_y      = Screen_xy(2) - Axes_xy(2) - Figure_xy(2);
        axes_y      = axes_y/Axes_xy(4)*(Ylim(2)-Ylim(1)) + Ylim(1);
        
        % Plot - only if pointer inside axes_2
        if Xlim(1)<axes_x && axes_x<Xlim(2) && Ylim(1)<axes_y && axes_y<Ylim(2)
          
            % Get fold data
            Fold  	= getappdata(fgt_gui_handle, 'Fold');
            fold  	= getappdata(fgt_gui_handle, 'fold_number');
            face   	= getappdata(fgt_gui_handle, 'face_number');
            
            % Define the exact point on the x-y and curvature-arc length
            % plots for the pointer position
            xy_x   = interp1(Fold(fold).Face(face).Arclength.Full, Fold(fold).Face(face).X.Full, axes_x);
            xy_y   = interp1(Fold(fold).Face(face).Arclength.Full, Fold(fold).Face(face).Y.Full, axes_x);
            
            ac_y   = interp1(Fold(fold).Face(face).Arclength.Full, Fold(fold).Face(face).Curvature.Full, axes_x);
            
            % Try to get handels to the marker points
            point_h1= getappdata(axes_1, 'point_h1');
            point_h2= getappdata(axes_2, 'point_h2');
            
            % Plot marker points - move if already exist
            if isempty(point_h1)
                % Plot marker points
                point_h1 = plot(  xy_x, xy_y, 'Parent', axes_1, 'Marker','o','MarkerFaceColor','y','MarkerSize',6,'MarkerEdgeColor','k');
                point_h2 = plot(axes_x, ac_y, 'Parent', axes_2, 'Marker','o','MarkerFaceColor','y','MarkerSize',6,'MarkerEdgeColor','k');
              
                % Store handles
                setappdata(axes_1, 'point_h1', point_h1);
                setappdata(axes_2, 'point_h2', point_h2);                
            else
                % Move marker points
                set(point_h1, 'XData', xy_x,   'YData', xy_y);
                set(point_h2, 'XData', axes_x, 'YData', ac_y);
            end            
        end
    end

%%  fun mouseover_thickness
    function mouseover_thickness()
        
        % Need to make sure that root unit is pixels
        set(0, 'Units', 'Pixels');
        
        % Handles to the four axes
        axes_1      = findobj(fgt_gui_handle, 'tag', 'axes_1');
        axes_2      = findobj(fgt_gui_handle, 'tag', 'axes_2');
        axes_3      = findobj(fgt_gui_handle, 'tag', 'axes_3');
        axes_4      = findobj(fgt_gui_handle, 'tag', 'axes_4');
        
        % Get pointer location w.r.t. Thickness plot (axes_2 and axes_4)
        Screen_xy 	= get(0,'PointerLocation');
        Figure_xy  	= getpixelposition(fgt_gui_handle);
        
        Axes_xy2   	= getpixelposition(axes_2, true);
        Axes_xy4   	= getpixelposition(axes_4, true);
        
        Xlim2       = get(axes_2, 'XLim');
        Ylim2       = get(axes_2, 'YLim');
        Xlim4       = get(axes_4, 'XLim');
        Ylim4       = get(axes_4, 'YLim');
        
        axes_x2     = Screen_xy(1) - Axes_xy2(1) - Figure_xy(1);
        axes_x2     = axes_x2/Axes_xy2(3)*(Xlim2(2)-Xlim2(1)) + Xlim2(1);
        axes_y2     = Screen_xy(2) - Axes_xy2(2) - Figure_xy(2);
        axes_y2     = axes_y2/Axes_xy2(4)*(Ylim2(2)-Ylim2(1)) + Ylim2(1);
        
        axes_x4     = Screen_xy(1) - Axes_xy4(1) - Figure_xy(1);
        axes_x4     = axes_x4/Axes_xy4(3)*(Xlim4(2)-Xlim4(1)) + Xlim4(1);
        axes_y4     = Screen_xy(2) - Axes_xy4(2) - Figure_xy(2);
        axes_y4     = axes_y4/Axes_xy4(4)*(Ylim4(2)-Ylim4(1)) + Ylim4(1);
        
        % Plot - only if pointer inside axes_2
        if Xlim2(1)<axes_x2 && axes_x2<Xlim2(2) && Ylim2(1)<axes_y2 && axes_y2<Ylim2(2)
          
            % Get fold data
            Fold  	= getappdata(fgt_gui_handle, 'Fold');
            fold  	= getappdata(fgt_gui_handle, 'fold_number');
            
            % Point on interface that is closest to pointer x (arclength) position
            [dummy, indx]   = min(abs( axes_x2 - [1:length(Fold(fold).Thickness.Local(1).Value)] ));
            
            % Try to get handels 
            fill_h2 = getappdata(axes_1, 'fill_h2');
            bar_h2  = getappdata(axes_2, 'bar_h2');
            
            % Fill bar and fold - move if already exist
            if isempty(bar_h2)
                
                % Plot marked bar
                bar_h2 = bar(indx,Fold(fold).Thickness.Local(1).Value(indx),'Parent', axes_2,'FaceColor','y','EdgeColor','k','BarWidth',0.5);
                
                %Fill the marked fold
                P        = Fold(fold).Thickness.Local(1).Polygon{indx};
                fill_h2  = fill(P(1,:),P(2,:),'y','Parent', axes_1);
                
                % Store handles
                setappdata(axes_1, 'fill_h2', fill_h2);  
                setappdata(axes_2, 'bar_h2' , bar_h2);   
                
            else
                % Move the highlighted bar
                set(bar_h2, 'XData', indx, 'YData', Fold(fold).Thickness.Local(1).Value(indx));
                
                 %Move the highlighted fold
                P = Fold(fold).Thickness.Local(1).Polygon{indx};
                set(fill_h2, 'XData', P(1,:), 'YData', P(2,:));
            end     
        end
        
        % Plot - only if pointer inside axes_4
        if Xlim4(1)<axes_x4 && axes_x4<Xlim4(2) && Ylim4(1)<axes_y4 && axes_y4<Ylim4(2)
          
            % Get fold data
            Fold  	= getappdata(fgt_gui_handle, 'Fold');
            fold  	= getappdata(fgt_gui_handle, 'fold_number');
            
            % Point on interface that is closest to pointer x (arclength) position
            [dummy, indx]   = min(abs( axes_x4 - [1:length(Fold(fold).Thickness.Local(2).Value)] ));
            
            % Try to get handels to the marker points
            fill_h4 = getappdata(axes_3, 'fill_h4');
            bar_h4  = getappdata(axes_4, 'bar_h4');
            
            % Plot marker points - move if already exist
            if isempty(bar_h4)
                
                % Plot marked bar
                bar_h4 = bar(indx, Fold(fold).Thickness.Local(2).Value(indx), 'Parent', axes_4, 'FaceColor','y', 'EdgeColor','k', 'BarWidth',0.5);
                
                %Fill the marked fold
                P        = Fold(fold).Thickness.Local(2).Polygon{indx};
                fill_h4  = fill(P(1,:),P(2,:),'y','Parent', axes_3);
                
                % Store handles
                setappdata(axes_3, 'fill_h4', fill_h4);  
                setappdata(axes_4, 'bar_h4' , bar_h4);   
                
            else
                % Move the highlighted bar
                set(bar_h4, 'XData', indx, 'YData', Fold(fold).Thickness.Local(2).Value(indx));
                
                 %Move the highlighted fold
                P = Fold(fold).Thickness.Local(2).Polygon{indx};
                set(fill_h4, 'XData', P(1,:), 'YData', P(2,:));
            end     
        end
    end
end