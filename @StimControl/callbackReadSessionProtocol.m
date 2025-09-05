function callbackReadSessionProtocol(obj)
% todo if empty
[file, location] = uigetfile([obj.path.protocolBase filesep '*.stim'], 'Select protocol');

[p, g] = readProtocol([location file]);
obj.p = p;
obj.g = g;
obj.idxStim = 1;

% TODO figure out if mapping stage is necessary and don't ask if not
[file, location] = uigetfile([obj.path.componentMaps filesep '*.csv'], 'Select Stimulus Map');
tab = readtable([location file]);

% reset previous
obj.h.ComponentProtocols = dictionary;
obj.h.ProtocolComponents = dictionary;

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
            obj.h.ComponentProtocols(componentID) = {};
        end
        obj.h.ComponentProtocols(componentID) = [obj.h.ComponentProtocols(componentID), tab{lineNum,1}{:}];
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