function callbackLoadProtocol(obj, src, event)
% Load a protocol file. Maps protocol inputs/outputs to hardware components.
% and updates GUI to allow trial start.
% eventually this will be more intelligent and able to handle ambiguity, but for now
% the mapping files need to be perfectly aligned to the protocol.
obj.status = 'loading';
obj.updateDateTime; % update the datetime for component savepaths

if src ~= obj.h.protocolSelectDropDown
    % not implemented.
    return
end

if strcmpi(src.Value, 'Browse...')
    warning("This will cause problems if you choose something outside the default protocol base path, " + ...
        "switch off, then switch back to it through the dropdown. Be careful!");
    [filename, dir] = uigetfile([obj.path.protocolBase filesep '*.stim'], 'Select protocol');
    if filename == 0
        src.Value = '';
    end
    obj.path.SessionProtocolFile = [dir filename];
    experimentID = strsplit(filename, '.');
    obj.experimentID = experimentID{1};     % todo this will cause problems later on 
                                            % because the base protocol path isn't being updated 
                                            % (this is on purpose so the path 
                                            % to all the other protocol files
                                            % doesn't get screwy but it's
                                            % on the list to fix)
elseif ~strcmpi(src.Value, '')
    obj.experimentID = src.Value;
    obj.path.SessionProtocolFile = [obj.path.protocolBase filesep src.Value '.stim'];
end

if strcmpi(src.Value, '')
    obj.h.trialInformationScroller.Value = '';
    obj.h.trialInformationScroller.FontColor = 'black';
    obj.trialNum = 0;
    return
end

[p, g] = readProtocol(obj.path.SessionProtocolFile);
obj.p = p;
obj.g = g;
obj.idxStim = 1;
obj.trialNum = 1;

% TODO figure out if mapping stage is necessary and don't ask if not
% TODO this is mostly for debugging anyway. Get rid of it when you're done
% here.
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

% refresh information scroller
obj.h.trialInformationScroller.Value = '';

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
        % TODO detect if channel already exists? maybe remove all old
        % channels
        component.CreateChannels([], obj.d.ComponentProtocols{k});
    end
end

%% calculate estimated time + rest time
protocolTotalTimeSecs = ((obj.g.dPause(1) + ((sum([obj.p.tPre]) + sum([obj.p.tPost]))/1000))*obj.g.nProtRep) - obj.g.dPause(1);
protocolTimeMins = floor(protocolTotalTimeSecs/60);
protocolTimeSecs = ceil(protocolTotalTimeSecs - (60*protocolTimeMins));
obj.h.protocolTimeEstimate.Text = sprintf('0:00 / %d:%d', protocolTimeMins, protocolTimeSecs);
obj.h.trialInformationScroller.Value = '';
obj.h.trialInformationScroller.FontColor = 'black';

obj.updateDateTime;

%% Load first trial
obj.callbackLoadTrial(src, event);

%% update status (GUI updates handled in here)
obj.status = 'ready';
end