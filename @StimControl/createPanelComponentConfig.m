function createPanelComponentConfig(obj, hPanel, ~, component);
% function createPanelThermode(obj,hPanel,~,idxThermode,nThermodes)
%     obj.h.(thermodeID).panel.params = uipanel(obj.h.fig,...
%         'CreateFcn',    {@obj.createPanelThermode,ii,length(obj.s)});

cp = component.GetComponentProperties();
if ~component.Abstract
    hPanel.Title = component.ID;
else
    hPanel.Title = cp.ID.default;
end

grid = uigridlayout(hpanel);
grid.RowHeight = {'1x', 23};
grid.ColumnWidth = {'1x', 100};

attributeRows = [];
valueRows = []
r = 1;

% if numeric, turn red if not met
% if categorical, set categories
% if neither, don't even stress it

for f = fields(cp)
    prop = cp(f);
    if ~component.Abstract
        vals = component.GetConfigStruct; %TODO DOES THIS ALWAYS WORK
    else
        vals = component.GetDefaultComponentStruct;
    end
    if ~prop.dependencies(vals(f))
        continue
    end
    attributeRows{1, r} = f;
    if ~isempty prop.allowable
        valueRows{1, r} = categorical(prop.allowable);
    else
        valueRows{1, r} = vals(f);
    end
end

tData =  table(attributeRows, valueRows, 'VariableNames', {'Attribute', 'Value'});
uit = uitable(grid, 'Data', tData, 'ColumnEditable', [false, true]);

% Specify table callback
uit.DisplayDataChangedFcn = @(src,event) updatePlot(src,ax);


function updatePlot(src,ax)
t = src.DisplayData;
lat = t.Latitude;
long = t.Longitude;
sz = t.MaxHeight;
bubblechart(ax,lat,long,sz)
end

function componentProperties = GetComponentProperties(obj)
    componentProperties = struct( ...
    ID = struct( ...
        default     = 'Dev1', ...
        allowable   = {daqlist().DeviceInfo.ID}, ... 
        validatefcn = @(x) true, ...
        dependencies= @(propStruct) true, ... 
        required    = @(propStruct) true, ...
        note        = ""), ...
    Rate = struct( ...
        default     = 1000, ...
        allowable   = {{}}, ... 
        validatefcn = @(x) isnumeric(x) && x > 0, ...
        dependencies= @(propStruct) true, ... 
        required    = @(propStruct) true, ...
        note        = "Sampling rate in Hz"), ...
    Vendor = struct( ...
        default     = 'ni', ...
        allowable   = {daqlist().DeviceInfo.Vendor.ID}, ... 
        validatefcn = @(x) true, ...
        dependencies= @(propStruct) true, ... 
        required    = @(propStruct) true, ...
        note        = "Used to initialise"), ...
    Model = struct( ...
        default     = '', ...
        allowable   = {daqlist().DeviceInfo.Model}, ... 
        validatefcn = @(x) true, ...
        dependencies= @(propStruct) true, ... 
        required    = @(propStruct) true, ...
        note        = "Distinguishes between multiple daqs with the same vendor") ...
   );
end

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
