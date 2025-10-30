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
elseif src == obj.h.ComponentMapDropDown
    basePath = obj.path.componentMaps;
end

if strcmpi(src.Value, 'Browse...')
    % let the user select a file
    [file, location] = uigetfile([basePath filesep '*.json']);
    filepath = [location file];
    if isempty(filepath) || ~any(filepath)
        return
    end
else
    filepath = [basePath filesep src.Value];
end
    
if src == obj.h.SessionSelectDropDown
    obj = LoadSessionConfig(obj, filepath);
elseif src == obj.h.ComponentConfigDropDown
    obj = LoadComponentConfig(obj, filepath);
elseif src == obj.h.ComponentMapDropDown
    obj = LoadComponentProtocolMap(obj, filepath);
end
% todo change display a la protocolSelect
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

%% LOAD COMPONENT-PROTOCOL MAP
function obj = LoadComponentProtocolMap(obj, filepath)
    txt = fileread(filepath);
    data = jsondecode(txt);
    obj.pids = [];
    for rowName = fields(data)'
        rowName = rowName{:};
        d = data.(rowName);
        if height(d) > 1
            d = d';
        end
        obj.pids.(rowName) = d;
    end
    % TODO REMOVE ROWS FOR NON-INITIALISED HARDWARE?
end

%% LOAD SESSION CONFIG
function obj = LoadSessionConfig(obj, filepath)
    txt = fileread(filepath);
    data = jsondecode(txt);
    obj = loadSessionHelper(obj, data, 'componentParams', obj.path.paramBase, @LoadComponentConfig);
    obj = loadSessionHelper(obj, data, 'activeHardware', '', '');
    obj = loadSessionHelper(obj, data, 'componentProtocolMap', obj.path.componentMaps, @LoadComponentProtocolMap);
    obj = loadSessionHelper(obj, data, 'protocol', obj.path.sessionBase, '');
end

function obj = loadSessionHelper(obj, data, fieldName, defaultPath, fcnHandle)
    if ~isfield(data, fieldName) || all(strcmpi(data.(fieldName), 'none')) || all(strcmpi(data.(fieldName), ''))
        return
    end
    if strcmpi(fieldName, 'activeHardware')
        %TODO ACTIVE HARDWARE - SET FOR 'ALL' TOO
    else
        if contains(data.(fieldName), filesep)
            filepath = data.(fieldName);
        else
            filepath = [defaultPath filesep data.(fieldName)];
        end
    
        if strcmpi(fieldName, 'protocol')
            %TODO UNTESTED
            obj.callbackLoadProtocol(obj.h.SessionSelectDropDown, filepath);
        else
            obj = fcnHandle(obj, filepath);
        end
    end
end