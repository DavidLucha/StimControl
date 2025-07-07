function createPanelFileControl(obj,hPanel,~)

%set panel position
hPanel.Title = 'File Interfacing';
hPanel.Layout.Row = 3;
hPanel.Layout.Column = [1 2];

%set up grid layout
grid = uigridlayout(hPanel);
grid.RowHeight = {'1x', '1x'};
grid.ColumnWidth = {'5x', 100, '1x', '5x', 100, '1x', '5x', 100};

%% set up params section
paramsDropDown = uidropdown(grid);
paramsDropDown.Layout.Row = [1 2];
paramsDropDown.Layout.Column = 1;
paramsDropDown.Items = getFilesList(obj.path.paramBase, '.json');
paramsDropDown.Editable = "on";
obj.h.paramsDropDown = paramsDropDown;

paramsLoadBtn = uibutton(grid);
paramsLoadBtn.Layout.Row = 1;
paramsLoadBtn.Layout.Column = 2;
paramsLoadBtn.ButtonPushedFcn = @obj.callbackLoadParams;
paramsLoadBtn.Text = 'Load Params';

paramsCreateBtn = uibutton(grid);
paramsCreateBtn.Layout.Row = 2;
paramsCreateBtn.Layout.Column = 2;
paramsCreateBtn.ButtonPushedFcn = @obj.callbackCreateParams;
paramsCreateBtn.Text = 'Create Params';

%% set up protocol section
protocolDropDown = uidropdown(grid);
protocolDropDown.Layout.Row = [1 2];
protocolDropDown.Layout.Column = 4;
protocolDropDown.Items = getFilesList(obj.path.protocolBase, '.stim');
protocolDropDown.Editable = "on";
obj.h.protocolDropDown = protocolDropDown;

protocolLoadBtn = uibutton(grid);
protocolLoadBtn.Layout.Row = 1;
protocolLoadBtn.Layout.Column = 5;
protocolLoadBtn.ButtonPushedFcn = @obj.callbackLoadProtocol;
protocolLoadBtn.Text = 'Load Protocol';

protocolCreateBtn = uibutton(grid);
protocolCreateBtn.Layout.Row = 2;
protocolCreateBtn.Layout.Column = 5;
protocolCreateBtn.ButtonPushedFcn = @obj.callbackCreateProtocol;
protocolCreateBtn.Text = 'Create Protocol';

%% set up general section
savepathDropDown = uidropdown(grid);
savepathDropDown.Layout.Row = 1;
savepathDropDown.Layout.Column = 7;
savepathDropDown.Items = getFilesList(obj.path.sessionBase, '.json');
savepathDropDown.Editable = "on";

savepathSelectBtn = uibutton(grid);
savepathSelectBtn.Layout.Row = 1;
savepathSelectBtn.Layout.Column = 8;
savepathSelectBtn.ButtonPushedFcn = @obj.callbackSelectSavePath;
savepathSelectBtn.Text = 'Select SavePath';

lastSessionLoadBtn = uibutton(grid);
lastSessionLoadBtn.Layout.Row = 2;
lastSessionLoadBtn.Layout.Column = 7;
lastSessionLoadBtn.ButtonPushedFcn = @obj.callbackLoadSession;
lastSessionLoadBtn.Text = 'Load Session';

saveSessionBtn = uibutton(grid);
saveSessionBtn.Layout.Row = 2;
saveSessionBtn.Layout.Column = 8;
saveSessionBtn.ButtonPushedFcn = @obj.callbackSaveSession;
saveSessionBtn.Text = 'Save Session';
