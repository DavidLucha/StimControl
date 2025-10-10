function callbackLoadConfig(obj, src, event)
% Generic function for loading config files from various dropdowns in StimControl's Setup tab.
value = src.Value;
if strcmpi(src.Value, 'Auto')
    % do nothing - todo is this the expected behaviour?
    return
end

if src == obj.h.SessionSelectDropDown
    basePath = obj.path.sessionBase;
elseif src == obj.h.ComponentConfigDropDown
    basePath = obj.path.paramBase;
end

if strcmpi(src.Value, 'Browse...')
    % let the user select a file
    [file, location] = uigetfile([basePath filesep '*.json']);
    filepath = [location file];
    if isempty(filepath) || ~any(filepath)
        return
    end
else
    filepath = [basepath filesep src.Value];
end

if src == obj.h.SessionSelectDropDown
    %% Load session - NOT IMPLEMENTED
    return
elseif src == obj.h.ComponentConfigDropDown
    obj = LoadComponentConfig(obj, filepath);
end
end

%% LOAD COMPONENT CONFIG
function LoadComponentConfig(obj, filepath)
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
        existingComponent = obj.d.Available{obj.d.IDComponentMap{component.ComponentID}};
        existingComponent.SetParams(component.ConfigStruct);
    else
        obj.d.Available{end+1} = component;
    end
end
% Refresh component data in hardware table.
tData = obj.h.AvailableHardwareTable.Data;
available = obj.d.Available;
for i = height(tData)+1:length(obj.d.Available)
    device = obj.d.Available{i};
    tData(end+1, :) = {class(device), device.ComponentID, device.GetStatus(), ~isempty(device.SessionHandle)};
    %TODO ADDITIONAL PREVIEW WINDOWS in CreatePanelSetupPreview AND START
    %PREVIEW IF INITIALISED
    obj.h.AvailableHardwareTable.Data = tData;
end
end