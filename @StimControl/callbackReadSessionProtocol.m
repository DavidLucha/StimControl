function callbackReadSessionProtocol(obj)
if ~isfield(obj.path, 'SessionProtocolFile') || isempty(obj.path.SessionProtocolFile) %TODO OR CHANGED
    [filename, dir] = uigetfile([obj.path.protocolBase filesep '*.stim'], 'Select protocol');
    obj.path.SessionProtocolFile = [dir filename];
end
[p, g] = readProtocol(obj.path.SessionProtocolFile);
obj.p = p;
obj.g = g;
obj.idxStim = 1;

% TODO figure out if mapping stage is necessary and don't ask if not
if ~isfield(obj.path, 'ComponentMapFile') ||  isempty(obj.path.ComponentMapFile) %TODO OR CHANGED
    [filename, dir] = uigetfile([obj.path.componentMaps filesep '*.csv'], 'Select Stimulus Map');
    obj.path.ComponentMapFile = [dir filename];
end

tab = readtable(obj.path.ComponentMapFile);

% reset previous if value changed
obj.h.ComponentProtocols = configureDictionary('string', 'cell');
obj.h.ProtocolComponents = configureDictionary('string', 'cell');

for lineNum = 1:height(tab)
    % fill out assigned ProtocolComponents
    componentIDs = tab{lineNum,2:end};
    components = {};
    for i = 1:length(componentIDs)
        componentID = componentIDs{i};
        component = obj.h.IDComponentMap(componentID);
        component = component{:};
        components{end+1} = component;
        if isempty(obj.h.ComponentProtocols) || ~isKey(obj.h.ComponentProtocols, componentID)
            obj.h.ComponentProtocols(componentID) = {cellstr(tab{lineNum,1}{:})};
        else
            tmp = obj.h.ComponentProtocols(componentID);
            tmp = tmp{:};
            tmp{end+1} = tab{lineNum,1}{:};
            obj.h.ComponentProtocols(componentID) = {tmp};
        end
        idx = obj.h.IDidxMap(componentID);
        if ~obj.h.Active{idx}
            % activate components that aren't active already
            obj.h.AvailableHardwareTable.Data(idx,'Enable') = {true};
            obj.h.Active{idx} = true;
            component.InitialiseSession();
            % component.StartPreview();
        end
    end
    obj.h.ProtocolComponents(tab{lineNum,1}{:}) = {components};
end
end