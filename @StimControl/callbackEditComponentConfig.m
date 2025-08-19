function callbackEditComponentConfig(obj)

%% first, retrieve selected component from obj.
rowIndex = obj.h.AvailableHardwareTable.Selection;
selectedRow = obj.h.AvailableHardwareTable.Data(rowIndex,:);
componentData = obj.h.Available(rowIndex);

%% extract component from struct if necessary
if strcmp(class(componentData), 'struct')
    switch lower(componentData.type)
        case 'daq'
            component = DAQComponent('Initialise', false, 'Struct', componentData);
        case 'camera'
            component = CameraComponent('Initialise', false, 'Struct', componentData);
        otherwise
            return
    end
    componentData = rmfield(componentData, 'type');
    component.ConfigStruct = component.GetConfigStruct(componentData);
end

%% Pass handles for later use
obj.h.ComponentConfig.Component.Handle = component;
% obj.h.ComponentConfig.Component.Properties = component.ComponentProperties;

%% Enable confirmation and cancel buttons
obj.h.ConfirmConfigBtn.Enable = true;
obj.h.CancelConfigBtn.Enable = true;
    
%% Populate Config Table
if isfield(component.ConfigStruct, 'ID')
    obj.h.ComponentConfig.Label.Text = component.ConfigStruct.ID;
else
    obj.h.ComponentConfig.Label.Text = class(component);
end

attributeRows = [];
valueRows = [];

componentFields = fields(component.ComponentProperties);
rowcount = length(fields(component.ComponentProperties));
if ~component.Abstract
    vals = component.GetConfigStruct;
else
    vals = component.GetDefaultConfigStruct;
end

for f = 1:length(componentFields)
    prop = component.ComponentProperties.(componentFields{f});
    disp(prop)
    if ~prop(1).dependencies(vals)
        continue
    end
    attributeRows{end+1} = componentFields{f};
    if ~isempty(prop(1).allowable)
        if ischar(prop(1).allowable) || isstring(prop(1).allowable)
            allowable = {prop(:).allowable};
        elseif isnumeric(prop(1).allowable)
            allowable = [prop(:).allowable];
        end
        valueRows{end+1} = categorical(allowable, 'Protected', true);
    else
        valueRows{end+1} = vals.(componentFields{f});
    end
end
tData =  table(transpose(valueRows), ...
        'VariableNames', {class(component)}, ...
        'RowNames', attributeRows);
obj.h.ComponentConfig.Table.Data = tData;

end