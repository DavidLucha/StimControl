function callbackLoadProtocol(obj, src, event)
if src ~= obj.h.protocolSelectDropDown
    % not implemented.
    return
end

if strcmpi(src.Value, 'Browse...')
    [filename, dir] = uigetfile([obj.path.protocolBase filesep '*.stim'], 'Select protocol');
    if filename == 0
        return
    end
    obj.path.SessionProtocolFile = [dir filename];
else
    obj.experimentID = src.Value;
    obj.path.SessionProtocolFile = [obj.path.protocolBase filesep src.Value];
end
[p, g] = readProtocol(obj.path.SessionProtocolFile);
obj.p = p;
obj.g = g;
obj.idxStim = 1;
obj.trialNum = 1;

% TODO figure out if mapping stage is necessary and don't ask if not
if ~isfield(obj.path, 'ComponentMapFile') ||  isempty(obj.path.ComponentMapFile) %TODO OR CHANGED
    [filename, dir] = uigetfile([obj.path.componentMaps filesep '*.csv'], 'Select Stimulus Map');
    if filename == 0
        return
    end
    obj.path.ComponentMapFile = [dir filename];
end

tab = readtable(obj.path.ComponentMapFile);

% reset previous if value changed
obj.d.ComponentProtocols = configureDictionary('string', 'cell');
obj.d.ProtocolComponents = configureDictionary('string', 'cell');

% for i = 1:length(fields(obj.p))
%     %TODO MAKE THIS WORK - ACCOUNT FOR 'AnaA' and 'AnaB' in map but only
%     %Ana in protocol. For now, this isn't supported. Just get it exactly
%     %right.
%     subProtocols = fields(obj.p);
%     subProtocolName = subProtocols{i};
%     if ~any(contains(tab.ProtocolName, subProtocolName))
%         % many things in the table can be mapped to the same protocol target 
%         % -e.g. 'Ana' in protocol can be mapped to multiple analog outputs ('AnaA' and 'AnaB')
%         % but we need to make sure this is the case and it's not just missing
%         protNameTokens = regexp(subProtocolName, '^[A-z]+[A-Z]?$', 'once', 'tokens');
%         protNamePrefix = protNameTokens{1};
%         if ~any(contains(tab.ProtocolName, protNamePrefix))
%             error("No mapping provided for sub-protocol %s", subProtocolName);
%         end
%         for i = 1:length(tab.ProtocolName)
%             if contains(tab.ProtocolName{i}, protNamePrefix)
%                 % duplicate? todo from here.
%             end
%         end
%     end
% end

for lineNum = 1:height(tab)
    if ~any(contains(fields(p), tab{lineNum, 1}))
        % ignore rows without associated protocol labels
        continue
    end
    % fill out assigned ProtocolComponents
    targetComponentIDs = tab{lineNum,2:end};
    components = {};
    for i = 1:length(targetComponentIDs)
        if isempty(targetComponentIDs{i})
            continue
        end
        componentID = targetComponentIDs{i};
        component = obj.d.IDComponentMap{componentID};
        components{end+1} = component;
        if isempty(obj.d.ComponentProtocols) || ~isKey(obj.d.ComponentProtocols, componentID)
            obj.d.ComponentProtocols(componentID) = {cellstr(tab{lineNum,1}{:})};
        else
            tmp = obj.d.ComponentProtocols{componentID};
            tmp{end+1} = tab{lineNum,1}{:};
            obj.d.ComponentProtocols{componentID} = tmp;
        end
        idx = obj.d.IDidxMap(componentID);
        if ~obj.d.Active(idx)
            % mark components as active
            obj.h.AvailableHardwareTable.Data(idx,'Enable') = {true};
            obj.d.Active(idx) = true;
        end
        if isempty(component.SessionHandle)
            % initialise session if not already initialised
            if isa(component, DAQComponent)
                component.InitialiseSession('ChannelConfig', false);
            else
                component.InitialiseSession();
            end
            % component.StartPreview();
        end
    end
    obj.d.ProtocolComponents(tab{lineNum,1}{:}) = {components};
end
% TODO THROW ERROR IF ALL PARTS OF PROTOCOL AREN'T SUFFICIENTLY MAPPED

ks = keys(obj.d.ComponentProtocols);
for i = 1:length(ks)
    % do protocol-specific initialisation per device
    k = ks{i};
    component = obj.d.IDComponentMap{k};
    if isa(component, 'DAQComponent')
        % TODO CAMERA INPUT VS OUTPUT CHANNEL TYPE SWITCHER
        component.CreateChannels([], obj.d.ComponentProtocols{k});
    end
end

%% GUI updates
% obj.h.
% enable start/stop button
end