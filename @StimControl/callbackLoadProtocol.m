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
obj.trialIdx = 1;
obj.trialNum = 1;

allTargets = fields([obj.p(:).params]);
% Construct appropriate trial for each device
deviceTargets = [];
for di = 1:sum(obj.d.Active)
    deviceTargets.(obj.d.activeComponents{di}.ConfigStruct.ProtocolID) = [];
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
        obj.indicateLoading("Creating channels...");
        obj.d.Available{i} = comp.InitialiseSession('ActiveDeviceIDs', obj.d.ActiveIDs);
    end
end
obj.indicateLoading("Protocol load completed. Loading trial.");

% refresh information scroller
obj.h.trialInformationScroller.Value = '';

%% calculate estimated time + rest time
protocolTotalTimeSecs = (obj.g.dPause(1)*(obj.g.nProtRuns-1) + ((sum(([obj.p.tPre] + [obj.p.tPost]).*[obj.p.nRuns])))*obj.g.nProtRuns/1000);
protocolTimeMins = floor(protocolTotalTimeSecs/60);
protocolTimeSecs = ceil(protocolTotalTimeSecs - (60*protocolTimeMins));
obj.h.protocolTimeEstimate.Text = sprintf('0:00 / %d:%d', protocolTimeMins, protocolTimeSecs);
obj.h.trialInformationScroller.Value = '';
obj.h.trialInformationScroller.FontColor = 'black';

%% Update paths
obj.updateDateTime; 
obj.g.sequence = generateSequence(obj);
createOutputDir(obj);

%% Load first trial
obj.callbackLoadTrial(src, event);

obj.status = 'ready';
end

function seq = generateSequence(obj)
tmp = arrayfun(@(x,y) {ones(1,x)*y},[obj.p.nRuns],1:length(obj.p));
tmp = [tmp{:}];
if obj.g.rand > 0
    if obj.g.rand == 2
        rng(0)
    else
        rng('shuffle')
    end
    seq = [];
    for ii = 1:obj.g.nProtRuns
        seq = [seq tmp(randperm(length(tmp)))]; %#ok<AGROW>
    end
else
    seq = repmat(tmp,1,obj.g.nProtRuns);
end
end

function createOutputDir(obj)
% create output directory if it doesn't already exist
if ~isfolder(obj.dirExperiment)
    mkdir(obj.dirExperiment)
end

% copy protocol file to output directory
[~,tmp1,tmp2] = fileparts(obj.path.SessionProtocolFile);
copyfile(obj.path.SessionProtocolFile,fullfile(obj.dirExperiment,[tmp1 tmp2]))

% % copy channel information to output directory TODO this is copied from
% QSTcontrol 
% fid = fopen(fullfile(dirOut,'channels.txt'),'w');
% tmp = evalc('disp(obj.DAQ.Channels)');
% tmp = regexprep(tmp,'\n','\r\n');
% fprintf(fid,'%s',tmp);
% fclose(fid);
end