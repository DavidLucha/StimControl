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
    obj.h.Available{end+1} = component;
end

% Refresh component data
tData = obj.h.AvailableHardwareTable.Data;
available = obj.h.Available;
for i = height(tData)+1:length(obj.h.Available)
    device = obj.h.Available{i};
    switch class(device)
        case 'DAQComponent'
            deviceID = strcat(device.ConfigStruct.Vendor, '.', device.ConfigStruct.ID, '.', device.ConfigStruct.Model);
        case 'CameraComponent'
            deviceID = strcat(device.ConfigStruct.Adaptor, '.', device.ConfigStruct.ID);
    end
    tData(end+1, :) = {class(device), deviceID, 'Not Initialised', false};
    obj.h.AvailableHardwareTable.Data = tData;
end
end