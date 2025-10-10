function callbackLoadProtocol(obj, src, event)
% Load a protocol file. Maps protocol inputs/outputs to hardware components.
% and updates GUI to allow trial start.
% eventually this will be more intelligent and able to handle ambiguity, but for now
% the mapping files need to be perfectly aligned to the protocol.
obj.indicateLoading('Loading protocol');
obj.updateDateTime; % update the datetime for component savepaths

if src ~= obj.h.protocolSelectDropDown
    % not implemented.
    return
end

if strcmpi(src.Value, 'Browse...')
    warning("This will cause problems if you choose something outside the default protocol base path, " + ...
        "switch off, then switch back to it through the dropdown. Be careful!");
    [filename, dir] = uigetfile([obj.path.protocolBase], 'Select protocol');
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
    obj.path.SessionProtocolFile = [obj.path.protocolBase filesep src.Value];
end

if strcmpi(src.Value, '')
    obj.h.trialInformationScroller.Value = '';
    obj.h.trialInformationScroller.FontColor = 'black';
    if ~isempty(obj.p)
        obj.trialNum = 0;
    end
    return
end

if contains(obj.path.SessionProtocolFile, '.qst')
    % legacy considerations
    [p, g] = readParameters(obj.path.SessionProtocolFile);
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

tab = readtable(obj.path.ComponentMapFile, 'ReadRowNames', true);
% TODO REMOVE ROWS FOR NON-INITIALISED HARDWARE?

if contains(obj.path.SessionProtocolFile, '.qst')
    df = p;
    protocols = p;
    for f = {'Comments', 'tPre', 'tPost', 'nRepetitions'}
        df = rmfield(df, f{:});
    end
    % create sub-maps for individual protocols as needed
    % protocols = [];
    fs = fields(p);
    for fIdx = 1:length(fs)
        if ~contains({'Comments', 'tPre', 'tPost', 'nRepetitions'}, fs{fIdx})
            protocols = rmfield(protocols, fs{fIdx});
            val = {p.(fs{fIdx})};
            stimTokens = regexp(fs{fIdx}, "^([a-z]+)([A-Z][a-z]+)*([A-Z]?$)", "tokens", "once");
            param = stimTokens{2};
            stimID = [stimTokens{1} stimTokens{3}]; %add prefix (ThermodeA) if needed
            if ~ismember(stimID, tab.Properties.RowNames)
                error("unmapped ID: %s", stimID);
            else
                deviceNames = tab{stimID, :};
                deviceNames = strsplit(deviceNames{:}, ' ');
                % add protocols to each device
                for iDev = 1:length(deviceNames)
                    % extract information
                    deviceLabel = strsplit(deviceNames{iDev}, '-');
                    devType = deviceLabel{1};
                    devID = deviceLabel{2};
    
                    % check mapped device exists & is valid for protocol.
                    if ~isKey(obj.d.ProtocolIDMap, devID)
                        msg = sprintf("No hardware assigned to Protocol ID %s. Please set an appropriate component's Protocol ID in the setup tab.", devID);
                        obj.errorMsg(msg);
                        continue %% TODO REMOVE: DEBUG ONLY
                        error(msg);
                    end
                    targetDevice = obj.d.Available{obj.d.ProtocolIDMap(devID)};
                    if ~contains(class(targetDevice), devType)
                        msg = sprintf("Incorrect hardware type assigned to protocol ID %s. Class should be %sComponent but is %s.", devID, devType, class(targetDevice));
                        obj.errorMsg(msg);
                        error(msg);                   
                    end
    
                    % fill out data structure
                    if ~isfield(protocols, devID)
                        [protocols(:).(devID)] = deal([]);
                    end
                    for i = 1:numel(protocols)
                        if ~isfield(protocols(i).(devID), stimID)
                            protocols(i).(devID).(stimID) = [];
                        end
                        if isempty(param)
                            protocols(i).(devID).(stimID) = val{i};
                        else
                            protocols(i).(devID).(stimID).(param) = val{i};
                        end
                    end
                end
            end
        end
    end
    obj.p = protocols;
elseif  contains(obj.path.SessionProtocolFile, '.stim')
    %TODO
end

if createChans || true %TODO REMOVE || TRUE
    % first time loading a trial. Initialise.
    comps = obj.d.Available(logical(obj.d.Active));
    activeIDs = [cellstr(keys(obj.d.ProtocolIDMap)); fields(obj.p(1).Trigger)]; %TODO this is an imperfect measure!!! and also you'll need to be able to select active hardware!
    for i = 1:length(obj.d.Available)
        if ~obj.d.Active(i) || ~isa(obj.d.Available{i}, 'DAQComponent')
            continue
        end
        comp = obj.d.Available{i};
        obj.d.Available{i} = comp.InitialiseSession('ActiveDeviceIDs', activeIDs);
    end
end


% refresh information scroller
obj.h.trialInformationScroller.Value = '';

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