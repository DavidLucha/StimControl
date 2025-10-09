classdef (HandleCompatible) DAQComponent < HardwareComponent
% Generic wrapper class for DAQ objects
% https://au.mathworks.com/help/daq/daq.interfaces.dataacquisition.html
% https://au.mathworks.com/help/daq/daq.interfaces.dataacquisition.write.html

properties (Constant, Access = public)
    ComponentProperties = DAQComponentProperties;
end

properties (Access = protected)
    SessionInfo = struct();
    ChannelMap = struct();
    OutChanIdxes = [];
    InChanIdxes = [];
    TrackedChannels = {};
    SaveFID = [];
    PreviewData = [];
    PreviewTimeAxis = [];
    tiledLayout = [];
    tPrePost = [];
    idxData;
end

properties(Access = private)
    StackedPreview = [];
    triggerIdx = 1; % for on-demand DAQ write operations only.
    timeoutWait = 0;
end

methods (Access = public, Static)
    function Clear()
        % Complete reset. Clear device.
        daqreset;
    end

    function components = FindAll(varargin)
        % Finds all available DAQ devices.
        p = inputParser();
        addParameter(p, 'Initialise', true, @islogical);
        p.parse(varargin{:});
        components = {};
        daqs = daqlist();
        for i = 1:height(daqs)
            s = table2struct(daqs(i, :));
            initStruct = struct( ...
                'Vendor', s.VendorID, ...
                'ID', s.DeviceID, ...
                'Model', s.Model);
            comp = DAQComponent('Initialise', p.Results.Initialise, ...
                'ConfigStruct', initStruct, 'ChannelConfig', false);
            components{end+1} = comp;
        end
    end
end

methods (Access = public)
function obj = DAQComponent(varargin)
    p = obj.GetBaseParser();
    addParameter(p, 'ChannelConfig', '', @(x) isstring(x) | ischar(x) | islogical(x))
    parse(p, varargin{:});
    params = p.Results;

    obj = obj.Initialise(params);
    if params.Initialise && ~params.Abstract
        obj = obj.InitialiseSession('ConfigStruct', params.ConfigStruct, ...
            'ChannelConfig', params.ChannelConfig);
    end
end

function obj = InitialiseSession(obj, varargin)
    % Initialise device. 
    %TODO STOP/START
    p = inputParser;
    addParameter(p, 'ChannelConfig', '', @(x) ischar(x) || isstring(x) || islogical(x));
    addParameter(p, 'ConfigStruct', []);
    addParameter(p, 'KeepHardwareSettings', []);
    addParameter(p, 'ActiveDeviceIDs', {}, @iscellstr);
    parse(p, varargin{:});
    params = p.Results;

    %---device---
    if isempty(obj.SessionHandle) || ~isvalid(obj.SessionHandle) || ~isempty(params.ConfigStruct)
        % if the DAQ is uninitialised or the params have changed
        daqStruct = obj.GetConfigStruct(params.ConfigStruct);
        if isempty(params.ConfigStruct) && isempty(obj.ConfigStruct)
            name = obj.FindDaqName(daqStruct.ID, '', '');
        else
            deviceID = daqStruct.ID;
            vendorID = daqStruct.Vendor;
            model = daqStruct.Model;
            name = obj.FindDaqName(deviceID, vendorID, model);
        end
        obj.ConfigStruct = daqStruct;
        obj.SessionHandle = daq(name);
        obj.SessionHandle.Rate = daqStruct.Rate;
    end
    
    %---channels---
    if islogical(params.ChannelConfig) || isempty(params.ChannelConfig)
        % current value is default
        [s, pcInfo] = system('vol');
        pcInfo = strsplit(pcInfo, '\n');
        pcID = pcInfo{2}(end-8:end);
        filename = [pcID '_' obj.ComponentID '.csv'];
        obj.ConfigStruct.ChannelConfig = [obj.ConfigStruct.ChannelConfig filesep filename];
        % TODO REMOVE - DEBUG
        obj.ConfigStruct.ChannelConfig = 'C:\Users\labadmin\Documents\MATLAB\StimControl\config\component_params\48AC-D74C_Dev1-ni-PCIe-6323.csv';
    end
    obj = obj.CreateChannels(obj.ConfigStruct.ChannelConfig, params.ActiveDeviceIDs);
end

% Start device
function StartTrial(obj)
    obj.idxData = 1;
    % Starts device with a preloaded session. 
    if ~isempty(obj.SavePath) || length(obj.SavePath) ~= 0
        % obj.SaveFID = fopen(strcat(obj.SavePath, filesep, obj.SavePrefix), 'w');
    end
    if ~isempty(obj.TriggerTimer) && isvalid(obj.TriggerTimer)
        % run stimulation on matlab timer
        start(obj.TriggerTimer);
        try
            wait(obj.TriggerTimer,obj.timeoutWait)       % wait for data acquisition
        catch me
            warning(me.identifier,'%s',...      % rethrow timeout error as warning
                me.message); 
        end
    else
        % run stimulation on DAQ clock
        start(obj.SessionHandle);               % start data acquisition
    end
end

% Stop device
function Stop(obj)
    if obj.SessionHandle.Running
        stop(obj.SessionHandle);
    end
    if ~isempty(obj.TriggerTimer) && isvalid(obj.TriggerTimer) && obj.TriggerTimer.Running
        stop(obj.TriggerTimer);
        delete(obj.TriggerTimer);
    end
    try
        fclose(obj.SaveFID);
    catch
        %file already closed. Do nothing.
    end
    flush(obj.SessionHandle);
end

% Change device parameters TODO ALL OF THESE REQUIRE A RESTART I THINK
function SetParams(obj, paramsStruct)
    paramFields = fields(paramsStruct);
    for i = 1:length(paramFields)
        param = paramFields{i};
        val = paramsStruct.(param);
        if any(contains(fields(obj.ConfigStruct), param)) 
            if obj.ComponentProperties.(param).isValid(val) 
                obj.ConfigStruct = setfield(obj.ConfigStruct, param, val);
            else
                error("Invalid value provided for field %s: %s", param, val)
            end
        elseif ~strcmpi(param, 'SavePath')
            error("Could not set field %s. Valid fields are: %s, SavePath", param, getfields(obj.ConfigStruct));
        end
        switch param
            case "ProtocolID"
                obj.ConfigStruct.ProtocolID = val;
            case "Rate"
                obj.Stop();
                if ~isdouble(val)
                    val = str2double(val);
                end
                obj.SessionHandle.Rate = val;
        end
    end
end

function daqStruct = GetParams(obj) %TODO this should all be handled in configstruct but I gotta check that works.
    % Get current device parameters for saving          
    daqs = daqlist().DeviceInfo;
    correctIndex = -1;
    for i = 1:length(daqs)
        if strcmpi(obj.SessionHandle.Vendor.ID, daqs(i).Vendor.ID)
            correctIndex = i;
        end
    end
    if correctIndex == -1
        warning('Unable to find DAQ in daqlist. ' + ...
            'DAQ device settings not saved.'); %note this should NEVER happen
    end
    d = daqs(correctIndex);
    daqStruct = struct();
    daqStruct.Vendor = d.Vendor.ID;
    daqStruct.Model = d.Model;
    daqStruct.ID = d.ID;
    daqStruct.Rate = obj.SessionHandle.Rate;
    daqStruct.ComponentID = obj.ComponentID;
end

function SaveAuxiliaryConfig(obj, filepath)
    % Get channel parameters for saving. DAQ-specific.
    % [s, out] = system('vol');
    %     out = strsplit(out, '\n');
    %     out = out{2}(end-8:end);
    %     if strcmpi(out, '48AC-D74C')
    %         filename = [out, '_', obj.ComponentID];
    channels = obj.SessionHandle.Channels;
    % channelData = {'portNum', 'channelName', 'ioType', 'signalType', 'TerminalConfig', 'Range', 'ProtType',  'ProtFunc', 'ProtID'};

    channelData = {'deviceID' 'portNum' 'channelName' 'ioType' ...
        'signalType' 'TerminalConfig' 'Range'};
    nChans = size(channels);
    nChans = nChans(2);
    for i = 1:nChans
        chan = channels(i);
        deviceID = chan.Device.ID;
        portNum = chan.ID;
        name = chan.Name;
        if contains(ch.Type, 'Output')
            ioType = 'output';
        elseif contains(ch.Type, 'Input')
            ioType = 'input';
        else
            ioType = 'bidirectional';
        end
        signalType = chan.MeasurementType;
        terminalConfig = chan.TerminalConfig;
        range = ['[' char(string(chan.Range.Min)) ' ' char(string(ch.Range.Max)) ']'];
        chanCell = {deviceID portNum name ioType signalType terminalConfig range};
        channelData(i+1,:) = chanCell;
    end
    writetable(channelData, filepath);
end

function PrintInfo(obj)
    % Print device information.
    disp(' ');
    disp(obj.SessionHandle.Channels);
    disp(' ');
end

function StartPreview(obj)
    % Dynamically visualise object output TODO FILTER FOR ONLY INFORMATIVE ONES
    if isempty(obj.PreviewPlot) || isempty(obj.SessionHandle)
        return
    end
    %clear previous preview data, if any
    obj.StopPreview;
    if isempty(obj.PreviewData)
        obj.Previewing = true;
        obj.PreviewPlot.Visible = 'on';
        x = 400;
        y = 400;
        imshow(ones(x,y),[],'parent',obj.PreviewPlot);
        text(x/2,y/2, 'No data', ...
            'Parent', obj.PreviewPlot, 'FontSize', 16, 'FontWeight','bold', ...
            'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', ...
            'Color', 'black');
        return
    end
    obj.Previewing = true;
    names = {obj.SessionHandle.Channels.Name};
    ids = {obj.SessionHandle.Channels.ID};
    comb = {names{:}; ids{:}}';
    fmt = ['%s' newline '%s'];
    displayLabels = compose(fmt, string(comb));
    % obj.charts = gobjects(length(displayLabels), 1);    
    % for i = 1:length(names)
    %     plt = plot(obj.PreviewTimeAxis, obj.PreviewData(:,i));
    %     % set(plt, 'XDataSource', obj.PreviewTimeAxis);
    %     % set(plt, 'YDataSource', obj.PreviewData(:,i));
    %     % plt.XDataSource = obj.PreviewTimeAxis;
    %     % plt.YDataSource = obj.PreviewData(:,i);
    %     plt.title = displayLabels(i);
    %     obj.charts{i} = plt;
    % end
    obj.StackedPreview = stackedplot(obj.PreviewPlot.Parent, obj.PreviewTimeAxis, obj.PreviewData, ...
        'DisplayLabels', displayLabels, ...
        'Layout', obj.PreviewPlot.Layout, ...
        'Position', obj.PreviewPlot.Position);
    % obj.dataLink = linkdata(obj.StackedPreview); %todo deal with this when causes bugs later :)
    obj.PreviewPlot.Visible = 'off';
end

function StopPreview(obj)
    if isempty(obj.PreviewPlot) || isempty(obj.SessionHandle)
        return
    end
    if ~isempty(obj.PreviewPlot.Children)
        delete(obj.PreviewPlot.Children);
    end
    if ~isempty(obj.StackedPreview) && isvalid(obj.StackedPreview)
        delete(obj.StackedPreview);
        obj.PreviewPlot.Visible = 'on';
    end
    obj.Previewing = false;
end

function LoadTrial(obj, out)
    % Loads a trial from a matrix of size c x s where c is the number of
    % output channels and s is the number of samples in the trial.
    
    % release session (in case the previous run was incomplete)
    stop(obj.SessionHandle);
    flush(obj.SessionHandle);
    if obj.SessionHandle.Rate == 0 && any(contains({obj.SessionHandle.Channels.Type}, 'Output'))
        % clocked sampling not supported - timer required for outputs.
        % TODO this might not strictly be true - might be possible to
        % connect to a clock for SOME DAQS - USB6001 is not one of them though
        obj.CreateSoftwareTriggerTimer(obj.ComponentConfig.Rate);

    elseif any(contains({obj.SessionHandle.Channels.Type}, 'Output'))
        % normal DAQ things hell yeah
        preload(obj.SessionHandle, out); % (1:1000,:) TODO remove the indexing - limiting numscans for debug purposes.
    end

    if ~isempty(obj.PreviewPlot) % show preview data
        obj.StartPreview
    end
end

function LoadTrialFromParams(obj, componentTrialData, genericTrialData)
    % release session (in case the previous run was incomplete)
    if obj.SessionHandle.Running
        obj.SessionHandle.stop
    end
    % release(obj.SessionHandle)
    
    channels = obj.SessionHandle.Channels;
    if isempty(channels)
        disp("oooh no");
    end
    rate = obj.SessionHandle.Rate;
    if rate==0
        % Software triggering required - only on-demand operations supported.
        rate = obj.ConfigStruct.Rate;
    end

    tPre     = genericTrialData.tPre  / 1000;
    tPost    = genericTrialData.tPost / 1000;
    tTotal   = tPre + tPost;
    obj.tPrePost = [genericTrialData.tPre genericTrialData.tPost];
    obj.timeoutWait = tTotal;

    % Add Listener 
    if ~obj.SessionHandle.Running
        obj.SessionHandle.ScansAvailableFcn = @obj.plotData;
        % obj.SessionHandle.NotifyWhenDataAvailableExceeds=1000;
    end

    fds = fields(componentTrialData);
    timeAxis = linspace(1/rate,tTotal,tTotal*rate)-tPre; %todo this falls apart if the rate !=1000? - need fixed?
    obj.PreviewTimeAxis = timeAxis;
    stimLength = numel(timeAxis);
    % Preallocate all zeros
    previewOut = zeros(numel(timeAxis), length(obj.SessionHandle.Channels));
    out = zeros(numel(timeAxis), sum(contains({obj.SessionHandle.Channels.Type}, 'Output')));

    for i = 1:length(fds)
        fieldName = fds{i};
        chIdx = obj.ChannelMap.(fieldName);
        outIdx = find(obj.OutChanIdxes == chIdx);
        if regexpi(fieldName, '^Thermode[A-z]*')
            % Thermode 
            continue
        elseif regexpi(fieldName, '^((Ana)|(Vib)|(Piezo))[A-z]*')
            % Analog 
            continue
            % stim = obj.GenerateAnalogStim('PWM', stimLength, componentTrialData.(fieldName));

        elseif regexpi(fieldName, '^(Dig)[A-z]*')
            % Arbitrary digital 
            stim = obj.GenerateArbitraryStim(stimLength, componentTrialData.(fieldName));

        elseif regexpi(fieldName, '^((PWM)|(LED))[A-z]*')
            % PWM 
            % TODO https://au.mathworks.com/help/daq/generate-pulse-width-modulated-signals-using-ni-devices.html
            stim = obj.GenerateDigitalStim('pwm', stimLength, componentTrialData.(fieldName));

        elseif regexpi(fieldName, '^Piezo[A-z]*')
            % Piezo
            stim = obj.GenerateAnalogStim('piezo', stimLength, componentTrialData.(fieldName));

        elseif regexpi(fieldName, '^(Cam)[A-z]*')
            % Camera trigger TODO what if it's just a start??
            if contains(channels(chIdx).Type, 'Output')
                stim = obj.GenerateDigitalStim('repeattrigger', stimLength, componentTrialData.(fieldName));
            else
                % set for input - I think this means do nothing? TODO check
                continue
            end
        elseif regexpi(fieldName, '^Arbitrary[A-z]*')
            % Arbitrary output.
            continue
            % stim = obj.GenerateArbitraryStim(stimLength, componentTrialData.(fieldName));
            % out(:,chIdx) = stim;
        else
            error('Unsupported data type for DAQComponent: %s', fieldName);
        end
        out(:,outIdx) = stim;
        previewOut(:,chIdx) = stim;
    end
    obj.PreviewData = previewOut;
    obj.LoadTrial(out);
end

function out = GenerateAnalogStim(obj, stimType, stimLength, params)
    % stimLength is in DAQ ticks
    % Accepts stimType / params combinations of:
    % piezo: ramp (default 20), freq, amp, dur, delay, rep
    rate = obj.ConfigStruct.Rate;
    MsToTicks = @(x) round(x*rate/1000);
    out = zeros(1, stimLength);
    Aurorasf = 1/52; % (1V per 50mN as per book,20241125 measured as 52mN per 1 V PB)

    switch lower(stimType)
        case 'piezo'
            if ~isfield(params, 'ramp')
                ramp = 20;
            else
                ramp = params.ramp;
            end
            piezoAmp = params.amp * Aurorasf; piezoAmp = min([piezoAmp 9.5]);  %added a safety block here 2024.11.15
            piezostimunitx = -ramp:ramp;
            piezostimunity = normpdf(piezostimunitx,0,3);
            piezostimunity = piezostimunity./max(piezostimunity);
            piezohold = ones(1,piezoDur);
            piezostimunity = [piezostimunity(1:ramp) piezohold piezostimunity(ramp+1:end)];
            
            if params.rep>0 % TODO MAKE SURE THIS IS CONSISTENT - DOES REP1 MEAN 2 INSTANCES OR ONE
                % I actually think in previous runs this just meant "are we using piezo or not" 
                % out(MsToTicks(params.delay))
                for pp = 1:rep
                    pos1 = (pp-1) .*(1/piezoFreq) ; % in seconds
                    tloc = find(tax>=pos1); tloc = tloc(1);
                    out(tloc:tloc+numel(piezostimunity)-1) = piezostim(tloc:tloc+numel(piezostimunity)-1)+piezostimunity;
                end
                out = piezostim.*piezoAmp;
            end
    end
end

function out = GenerateArbitraryStim(obj, stimLength, params)
    disp("WAGH");
end

function out = GenerateDigitalStim(obj, stimType, stimLength, params)
    % Generates a digital stim given a stimtype, length, and params
    % stimLength is in DAQ ticks.
    % Accepts stimType / params combinations of:
    % PWM: dc (duty cycle, 0<=dc<=100), freq (Hz), dur, delay, rep, repdel, rampup, rampdown
    % square: delay, dur, rep, repdel
    % repeattrigger: freq, delay, dur(optional, defaults to full duration)
    % singletrigger: delay
    % startstoptrigger: delay, dur
    rate = obj.ConfigStruct.Rate;
    MsToTicks = @(x) round(x*rate/1000);
    out = zeros(1, stimLength);
    if ~isfield(params, 'delay')
        delay = 1;
    else
        delay = MsToTicks(params.delay);
    end
    switch lower(stimType)
        case 'pwm'
            if params.rampup + params.rampdown > params.dur
                error('invalid parameters for stimulus %s: ramp duration must fit within overall duration', stimType);
            end
            periodTicks = round(rate/params.freq); % period in ticks
            onTicks = round(periodTicks*(params.dc/100));
            durationTicks = MsToTicks(params.dur);
            % TODO MAKE THIS MORE ROUNDY - CALCULATE TOTAL DURATION IN PERIODS AND MINUS RAMPUP AND RAMPDOWN INSTEAD OF THIS
            totalPeriods = floor(durationTicks / periodTicks);
            rampUpPeriods = round(MsToTicks(params.rampup) / periodTicks); %TODO SIMPLIFY
            rampUpTickIncrease = onTicks / rampUpPeriods;
            rampDownPeriods = round(MsToTicks(params.rampdown) / periodTicks); %TODO SIMPLIFY
            rampDownTickDecrease = onTicks / rampDownPeriods;
            highPeriods = totalPeriods - (rampUpPeriods + rampDownPeriods);
            offset = delay;
            % generate single stim
            singleStim = zeros(1, durationTicks);
            for i = 1:rampUpPeriods:periodTicks
                singleStim(i:i+round(rampUpTickIncrease * i)) = 1;
            end
            st = rampUpPeriods*periodTicks + 1;
            for i = st:st + highPeriods:periodTicks
                singleStim(i:i+onTicks) = 1;
            end
            st = st + (highPeriods * periodTicks);
            for i = st:st + rampUpPeriods:periodTicks
                singleStim(i:i+round(onTicks - (rampDownTickDecrease * i))) = 1;
            end
            repdelTicks = MsToTicks(params.repdel);
            totalDurTicks = (repdelTicks + durationTicks) * params.rep;
            for i = offset+1:offset+1+totalDurTicks:durationTicks+numel(singleStim)
                out(i:i+numel(singleStim)-1) = singleStim;
            end

        case 'square'
            stimTicks = MsToTicks(params.dur + params.repdel);
            for i = 1:params.rep:stimTicks
                out(i:i+MsToTicks(params.dur)) = 1;
            end

        case 'repeattrigger'
            %TODO currently assumes trigger length as basically 50DC PWM -
            % parametrise?
            framerateTicks = round(rate/params.freq);
            if ~isfield(params, 'dur')
                endIdx = length(out);
                out(delay:framerateTicks:end) = 1;
            else
                endIdx = delay + MsToTicks(params.dur);
                out(delay:framerateTicks:MsToTicks(params.dur)+delay) = 1;
            end
            for i = 1:framerateTicks:endIdx-framerateTicks
                out(i:i+round(framerateTicks/2)) = 1;
            end

        case 'singletrigger'
            out(delay) = 1;

        case 'startstoptrigger'
            out(delay) = 1;
            out(delay+MsToTicks(params.dur)) = 1;
    end
end

%% DEVICE-SPECIFIC FUNCTIONS
function obj = CreateChannels(obj, filename, protocolIDs)
    % Create DAQ channels from filename.
    if isempty(obj.SessionHandle) || ~isvalid(obj.SessionHandle)
        error("DAQComponent %s has no valid session handle to attach channels to.", obj.ComponentID);
    end
    if isempty(filename)
        filename = obj.ConfigStruct.ChannelConfig;
    end
    % clear previous channels, if any
    obj = obj.ClearChannels();
    % obj.SessionHandle.
    tab = readtable(filename);
    s = size(tab);
    if ~isMATLABReleaseOlderThan('R2024b')
        channelList = daqchannellist;
    end
    for ii = 1:s(1)
        try
            warning('');
            line = tab(ii, :); %TODO CHECK FOR BLANKS
            % line.('deviceID') or line.(1);
            if ~isempty(protocolIDs) ...
                && ~any(contains(protocolIDs, [line.('ProtType'){:} line.('ProtID'){:}])) ...
                && ~any(contains([line.('ProtType'){:} line.('ProtID'){:}], protocolIDs))
                % skip channels that aren't required for this protocol.
                continue
            end
            tmp = strsplit(obj.ComponentID, '-');
            deviceID = tmp{1};
            portNum = line.('portNum'){1}; 
            channelName = line.('channelName'){1};
            if isempty(channelName)
                channelName = line.('Note'){1};
            end
            ioType = line.('ioType'){1};
            signalType = line.('signalType'){1};
            terminalConfig = line.('TerminalConfig');
            if contains(class(terminalConfig), 'cell')
                terminalConfig = terminalConfig{1};
            end
            range = line.('Range');
            if contains(class(range), 'cell')
                range = range{1};
            end
            if ~isMATLABReleaseOlderThan('R2024b')
                channelList = add(channelList, ioType, deviceID, portNum, signalType, TerminalConfig=terminalConfig, Range=range);
            else
                switch ioType
                    case 'input'
                        [ch, idx] = addinput(obj.SessionHandle,deviceID,portNum,signalType);
                        obj.InChanIdxes(end+1) = idx;
                    case 'output'
                        [ch, idx] = addoutput(obj.SessionHandle,deviceID,portNum,signalType);
                        obj.OutChanIdxes(end+1) = idx;
                    case 'bidirectional'
                        [ch, idx] = addbidirectional(obj.SessionHandle,deviceID,portNum,signalType);
                        obj.OutChanIdxes(end+1) = idx;
                        obj.InChanIdxes(end+1) = idx;
                end
                ch.Name = channelName;
                if ~isempty(terminalConfig) && ~contains(class(ch), 'Digital')
                    ch.TerminalConfig = terminalConfig;
                end
                if ~isempty(range) && ~contains(class(ch), 'Digital')
                    range = str2num(range);
                    ch.Range = range;
                end
                [warnMsg, warnId] = lastwarn;
                if ~isempty(warnMsg)
                    message = ['Warning encountered loading DAQComponent channel information on line ' char(string(ii))];
                    warning(message);
                end
            end
            % if any(strcmp(protocolIDs, [line.ProtType line.ProtID]))
            %     % exact match between protocolID and table protocolID
            %     channelID = [line.ProtType line.ProtID];
            % elseif any(strcmp(protocolIDs, line.ProtType))
            %     % subtype not defined in protocolIDs. Activate all TODO check this is the
            %     % desired behaviour
            %     % note that it's the same, we'll just go through keys and
            %     % put the same data in all of them. Keeping logic here for
            %     % now.
            %     channelID = [line.ProtType line.ProtID];
            % else
            %     % for debugging. TODO remove when we have a chance
            %     dbstack
            %     keyboard
            %     error("Unable to map line %s to protocolIDs %s", [line.ProtType '.' line.ProtID], protocolIDs{:})
            % end
            channelID = [line.ProtType{:} line.ProtID{:}];
            if ~isfield(obj.ChannelMap, channelID)
                obj.ChannelMap.(channelID) = {};
            end
            obj.ChannelMap.(channelID){end+1, 1} = idx;
            obj.ChannelMap.(channelID){end, 2} = line.ProtFunc;

        catch exception
            disp(exception.message)
            dbstack
            keyboard
            message = ['Encountered an error reading channels config file on line ' ...
                    char(string(ii)) ': ' exception.message ' Line skipped.'];
            warning(message);
        end
    end
    if ~isMATLABReleaseOlderThan('R2024b')
        obj.SessionHandle.Channels = channelList;
    end
end

function obj = ClearChannels(obj)
    obj.ChannelMap = struct();
    obj.OutChanIdxes = [];
    obj.InChanIdxes = [];
    obj.TrackedChannels = {};
    if length(obj.SessionHandle.Channels) ~= 0
        removechannel(obj.SessionHandle, 1:length(obj.SessionHandle.Channels));
    end
end
end


%% Private Methods
methods (Access = protected)

function componentID = GetComponentID(obj)
    componentID = convertStringsToChars([obj.ConfigStruct.ID '-' obj.ConfigStruct.Vendor '-' obj.ConfigStruct.Model]);
    componentID = [componentID{:}];
end

function SoftwareTrigger(obj, ~, ~)
    if obj.triggerIdx >= length(obj.PreviewData)
        write(obj.SessionHandle, obj.PreviewData(obj.triggerIdx,:))
    else
        obj.Stop();
    end
end

function status = GetSessionStatus(obj)
    % get current device status.
    % STATUS:
    %   connected       device session initialised; not ready to start trial
    %   ready           device session initialised, trial loaded
    %   running         currently running a trial
    status = '';
    if obj.SessionHandle.Running
        status = 'running'; % DAQ running
    elseif ~isempty(obj.TriggerTimer) && isvalid(obj.TriggerTimer) && obj.TriggerTimer.Running
        status = 'running'; % Software triggered timer running
    elseif obj.SessionHandle.NumScansQueued ~= 0
        status = 'ready'; % ready for DAQ triggered run
    elseif ~isempty(obj.PreviewData)
        status = 'ready'; % ready for software triggered run
    elseif ~isempty(obj.SessionHandle) && isvalid(obj.SessionHandle)
        status = 'connected';
    end
end

function name = FindDaqName(obj, deviceID, vendorID, model)
    % TODO shouldn't use this within StimControl but it's useful for other applications
    % Find available daq names
    % https://au.mathworks.com/help/daq/daq.interfaces.dataacquisition.html
    try
        daqs = daqlist().DeviceInfo;
    catch
        daqs = [];
    end
    if isempty(daqs)
        errorStruct.message = 'No data acquistion devices found or data acquisition toolbox missing.';
        errorStruct.identifier = 'DAQ:Initialise:NoDAQDevicesFound';
        error(errorStruct);
    end
    checker = false;
    for x = 1 : length(daqs)
        if (strcmpi(daqs(x).ID, deviceID) ...
                && isempty(vendorID) && isempty(model)) ||  ... %if only DAQ name is given
            (strcmpi(daqs(x).ID, deviceID) ...
                && strcmpi(daqs(x).Vendor.ID, vendorID) && isempty(model)) ||  ... %if only name and vendorID are given
            (strcmpi(daqs(x).ID, deviceID) ...
                && strcmpi(daqs(x).Vendor.ID, vendorID) ...
                && strcmpi(daqs(x).Model, model)) % if more info is given. todo check this logic is sound
            checker = true;
            correctIndex = x;
        end
    end
    if ~checker
        warning(['Could not find specified DAQ: ' deviceID ' - Using existing board ' daqs(x).ID ' instead.'])
        correctIndex = x;
    end
    name = daqs(correctIndex).Vendor.ID;
end


function plotData(obj, ~,event)
    % manage persistent variables
    persistent emptyCount
    if obj.idxData > size(obj.StackedPreview.YData)
        % cut off the end of the data
        disp("we have too much data??");
        return
    end

    data = read(event.Source);
    % check data exists.
    
    % scale data from thermodes TODO
    % dat = event.Data;
    % % dat(:,idxData(1:2)) = dat(:,idxData(1:2)) * 17.0898 - 5.0176;
    % dat(:,idxData(1:2)) = dat(:,idxData(1:2)) * 12  - 2; % PB 20241219
    % dat(:,idxData(3:4)) = (dat(:,idxData(3:4))*10 + 32) ;
    % ylim([12 50])
    if ~isempty(data)
        targetIdx = obj.idxData:data.NumScans+obj.idxData-1;
        obj.PreviewData(targetIdx, obj.InChanIdxes) = data.Data;
        warning('off');
        obj.StackedPreview.YData(targetIdx, obj.InChanIdxes) = data.Data; %todo fix this but I'm going to have to fix it by changing the plot function
        warning('on');
        try
            writematrix([data.Timestamps-obj.tPrePost(1),obj.PreviewData(targetIdx,:)], ...
            strcat(obj.SavePath, filesep, obj.SavePrefix, '.csv'), ...
            'WriteMode', 'append');
            % fwrite(obj.SaveFID,[data.Timestamps-obj.tPrePost(1),obj.PreviewData(targetIdx)'],'double');
        catch e
            keyboard;
            rethrow(e);
        end
        obj.idxData = obj.idxData + data.NumScans;
        emptyCount = 0;
    else
        if isempty(emptyCount)
            emptyCount = 1;
        else
            emptyCount = emptyCount + 1;
        end
    end
end

end
end