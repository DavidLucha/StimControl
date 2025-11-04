function callbackLoadProtocol(obj, src, event)
% Load a protocol file. Maps protocol inputs/outputs to hardware components.
% and updates GUI to allow trial start.
% eventually this will be more intelligent and able to handle ambiguity, but for now
% the mapping files need to be perfectly aligned to the protocol.
obj.indicateLoading('Loading protocol');
obj.updateDateTime; % update the datetime for component savepaths

if src == obj.h.SessionSelectDropDown
    %TODO TEST
    obj.path.SessionProtocolFile = event;
    experimentID = strsplit(event, filesep);
    experimentID = experimentID{end};
    experimentID = strsplit(experimentID, '.');
    obj.experimentID = experimentID{1}; %todo as below this may cause issues later

elseif src ~= obj.h.protocolSelectDropDown
    % not implemented.
    return
elseif strcmpi(src.Value, 'Browse...')
    warning("This will cause problems if you choose something outside the default protocol base path, " + ...
        "switch off, then switch back to it through the dropdown. Be careful!");
    [filename, dir] = uigetfile([obj.path.protocolBase], 'Select protocol');
    if filename == 0
        src.Value = '';
        return
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
    obj.path.SessionProtocolFile = [obj.path.protocolBase filesep src.Value];

elseif strcmpi(src.Value, '')
    obj.h.trialInformationScroller.Value = '';
    obj.h.trialInformationScroller.FontColor = 'black';
    if ~isempty(obj.p)
        obj.trialNum = 0;
    end
    return
end

if ~isfile(obj.path.SessionProtocolFile)
    obj.warnMsg('Protocol file not found. Passive mode enabled.');
    %TODO MAKE SURE START TRIAL IS DISABLED HERE
    obj.status = 'no protocol loaded';
    return
end

if contains(obj.path.SessionProtocolFile, '.qst')
    % legacy considerations
    [p, g] = readQSTParameters(obj.path.SessionProtocolFile);
elseif contains(obj.path.SessionProtocolFile, '.stim')
    % current format
    [p, g] = readProtocol(obj.path.SessionProtocolFile);
else
    error("Unsupported file format. Supported formats: .qst, .stim");
end

createChans = isempty(obj.p);

obj.p = p;
obj.g = g;
obj.idxStim = 1;
obj.trialNum = 1;

cpMap = obj.pids;

allTargets = fields([obj.p(:).params]);
% Construct appropriate trial for each device
deviceTargets = [];
activeComponents = obj.d.Available(logical(obj.d.Active));
for di = 1:sum(obj.d.Active)
    deviceTargets.(activeComponents{di}.ConfigStruct.ProtocolID) = [];
end
for fi = 1:length(allTargets)
    targetName = allTargets{fi};
    if ~isfield(obj.pids, targetName)
        error("No connected device found for stimulus target %s", targetName);
    end
    componentIDs = obj.pids.(targetName);
    for ci = 1:length(componentIDs)
        componentID = componentIDs(ci);
        deviceTargets.(componentIDs(ci)) = [deviceTargets.(componentIDs(ci)) string(targetName)];
    end
end
obj.d.componentTargets = deviceTargets;

if createChans
    % first time loading a trial. Initialise.
    for i = 1:length(obj.d.Available)
        if ~obj.d.Active(i) || ~isa(obj.d.Available{i}, 'DAQComponent')
            continue
        end
        comp = obj.d.Available{i};
        fprintf("Creating channels for %s...\n", comp.ConfigStruct.ProtocolID);
        obj.d.Available{i} = comp.InitialiseSession('ActiveDeviceIDs', obj.d.ActiveIDs);
    end
end

% for di = 1:sum(obj.d.Active)
%     component = activeComponents{di};
%     component.LoadTrialFromParams(blah)
%     deviceParams.(activeComponents(di).ProtocolID) = [];
% end

% refresh information scroller
obj.h.trialInformationScroller.Value = '';

%% calculate estimated time + rest time
protocolTotalTimeSecs = ((obj.g.dPause(1) + (sum(([obj.p.tPre] + [obj.p.tPost]).*[obj.p.nRuns])))*obj.g.nProtRuns) - obj.g.dPause(1);
protocolTimeMins = floor(protocolTotalTimeSecs/60);
protocolTimeSecs = ceil(protocolTotalTimeSecs - (60*protocolTimeMins));
obj.h.protocolTimeEstimate.Text = sprintf('0:00 / %d:%d', protocolTimeMins, protocolTimeSecs);
obj.h.trialInformationScroller.Value = '';
obj.h.trialInformationScroller.FontColor = 'black';

obj.updateDateTime; 
% TODO SET TRIAL LOADED HERE AND UNLOADED AT COMPONENT.START AND LOAD NEW
% PROTOCOL

%% Load first trial
obj.callbackLoadTrial(src, event);

%% update status (GUI updates handled in here)
obj.status = 'ready';
end