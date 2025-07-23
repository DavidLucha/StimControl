function createPanelSessionSetup(obj, hPanel, ~)

% set panel position
hPanel.Title = 'Session Setup';
hPanel.Layout.Row = [2 3];
hPanel.Layout.Column = 1;

grid = uigridlayout(hPanel);
grid.RowHeight = {'1x', '0.01x', 22, 22};
grid.ColumnWidth = {100, 23, 23, 100, 23, 23, 100, 23, '1x', 90};
grid.RowSpacing = 2;

%% create component table
uit = uitable('Parent', grid);
uit.Layout.Row = 1;
uit.Layout.Column = [1 length(grid.ColumnWidth)];
uit.ColumnSortable = true;
uit.SelectionType = 'row';
uit.Data = obj.callbackPopulateHardwareTable();
uit.ColumnEditable = [false false true false true];
obj.h.hardwareTable = uit;

%% create hardware config select
ccCol = 1;
componentConfigSelect = uidropdown(grid, ...
    'Editable', 'on', 'Items', getFilesList(obj.path.paramBase, '.json'), ...
    'ValueChangedFcn', @obj.callbackLoadParams);
componentConfigSelect.Layout.Row = length(grid.RowHeight);
componentConfigSelect.Layout.Column = ccCol;
obj.h.componentConfigDropDown = componentConfigSelect;

createConfigBtn = uibutton(grid, ...
    'ButtonPushedFcn', @obj.callbackCreateParams, ...
    'Text', '+');
createConfigBtn.Layout.Row = length(grid.RowHeight);
createConfigBtn.Layout.Column = ccCol + 1;

configLabel = uilabel(grid, 'Text', 'Hardware Config');
configLabel.Layout.Row = length(grid.RowHeight) - 1;
configLabel.Layout.Column = [ccCol ccCol+1];

%% create StimControl session select
scCol = 4;
sessionSelect = uidropdown(grid, ...
    'Editable', 'on', 'Items', getFilesList(obj.path.sessionBase, '.json'), ...
    'ValueChangedFcn', @obj.callbackLoadSession);
sessionSelect.Layout.Row = length(grid.RowHeight);
sessionSelect.Layout.Column = scCol;
obj.h.componentConfigDropDown = sessionSelect;

saveSessionBtn = uibutton(grid, ...
    'ButtonPushedFcn', @obj.callbackSaveSession, ...
    'Text', '+');
saveSessionBtn.Layout.Row = length(grid.RowHeight);
saveSessionBtn.Layout.Column = scCol + 1;

sessionLabel = uilabel(grid, 'Text', 'Session Config');
sessionLabel.Layout.Row = length(grid.RowHeight) - 1;
sessionLabel.Layout.Column = [scCol scCol+1];

%% Create BasePath select
bpCol = 7;
basePathSelect = uidropdown(grid, ...
    'Editable', 'on', 'Items', getFilesList(obj.path.dirData, ''), ... %TODO THIS IS WRONG
    'ValueChangedFcn', @obj.callbackChangeBasePath);
basePathSelect.Layout.Row = length(grid.RowHeight);
basePathSelect.Layout.Column = bpCol;
obj.h.componentConfigDropDown = basePathSelect;

browseBasePathBtn = uibutton(grid, ...
    'ButtonPushedFcn', @obj.callbackNewBasePath, ...
    'Text', '+');
browseBasePathBtn.Layout.Row = length(grid.RowHeight);
browseBasePathBtn.Layout.Column = bpCol + 1;

basePathLabel = uilabel(grid, 'Text', 'SavePath');
basePathLabel.Layout.Row = length(grid.RowHeight) - 1;
basePathLabel.Layout.Column = [bpCol bpCol+1];


%% create component edit button
editHardwareConfigBtn = uibutton(grid, ...
    'WordWrap', 'on', 'Text', 'Edit Selected Component', ...
    'ButtonPushedFcn',@obj.callbackEditHardwareConfig);
editHardwareConfigBtn.Layout.Row = [length(grid.RowHeight) - 1, length(grid.RowHeight)];
editHardwareConfigBtn.Layout.Column = length(grid.ColumnWidth);

end