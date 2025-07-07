function createPanelComponentConfig(obj, component);

obj.h.fig = uifigure(...
    'Position',         [200 200 900 648], ...
    'Units',            'Pixels', ...
    'Name',             component.ID, ...
    'GraphicsSmoothing','on');


% 
% obj.h.mainGrid = uigridlayout(obj.h.fig);
% obj.h.mainGrid.RowHeight = {'1x', 200, 100};
% obj.h.mainGrid.ColumnWidth = {'1x', 200, 100};
% 
% % set panel position
% hPanel.Title = 'Hardware';
% hPanel.Layout.Row = 2;
% hPanel.Layout.Column = 1;
% hPanel.Scrollable = "on";
% 
% grid = uigridlayout(hPanel);
% grid.RowHeight = {23, 23, '1x'};
% grid.ColumnWidth = {'1x', 100};
% 
% % create buttons
% viewHardwareOutputBtn = uibutton(grid);
% viewHardwareOutputBtn.Layout.Row = 1;
% viewHardwareOutputBtn.Layout.Column = 2;
% viewHardwareOutputBtn.ButtonPushedFcn = @obj.callbackViewHardwareOutput;
% viewHardwareOutputBtn.Text = 'View Output';
% 
% editHardwareConfigBtn = uibutton(grid);
% editHardwareConfigBtn.Layout.Row = 2;
% editHardwareConfigBtn.Layout.Column = 2;
% editHardwareConfigBtn.ButtonPushedFcn = @obj.callbackEditHardwareConfig;
% editHardwareConfigBtn.Text = 'Load Params';
% 
% % create table
% uit = uitable('Parent', grid, 'ColumnName', {'Type', 'ID', 'StatusLight', 'Status'});
% uit.Layout.Row = [1 3];
% uit.Layout.Column = 1;
% uit.ColumnSortable = true;
% uit.SelectionType = 'row';
% uit.Data = obj.callbackPopulateHardwareTable;
% obj.h.hardwareTable = uit;
