function callbackLoadComponentParams(obj)
% filepath = [pwd filesep 'StimControl' filesep 'paramfiles' filesep 'HardwareParams.json']; %TODO
% if isempty(filepath)
[file, location] = uigetfile([obj.h.path.setup.base filesep 'componentParams']);
filepath = [location filesep file];
% end
if isempty(filepath) || ~any(filepath)
    return
end

jsonStr = fileread(filepath);
jsonData = jsondecode(jsonStr);

for i = 1:length(jsonData)
    if length(jsonData) > 1
        hStruct = jsonData{i};
    else
        hStruct = jsonData;
    end        
    switch lower(hStruct.DEVICE)
        case 'camera'
            component = CameraComponent('ConfigStruct', hStruct, 'Initialise', false);
        case 'daq'
            component = DAQComponent('ConfigStruct', hStruct, 'Initialise', false);
        otherwise
            disp("Unsupported hardware type. Come back later.")
    end
    if contains(keys(obj.d.IDComponentMap), component.ComponentID) %todo this might not allow >1 piece of identical hardware - not currently a problem.
        existingComponent = obj.d.IDComponentMap{component.ComponentID};
        existingComponent.SetParams(component.ConfigStruct);
    else
        obj.d.Available{end+1} = component;
    end
end

% Refresh component data
tData = obj.d.AvailableHardwareTable.Data;
available = obj.d.Available;
for i = height(tData)+1:length(obj.d.Available)
    device = obj.d.Available{i};
    tData(end+1, :) = {class(device), device.ComponentID, device.GetStatus(), ~isempty(device.SessionHandle)};
    %TODO ADDITIONAL PREVIEW WINDOWS in CreatePanelSetupPreview AND START
    %PREVIEW IF INITIALISED
    obj.d.AvailableHardwareTable.Data = tData;
end
end