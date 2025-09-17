classdef (HandleCompatible) DAQComponent < HardwareComponent
% Generic wrapper class for DAQ objects
% https://au.mathworks.com/help/daq/daq.interfaces.dataacquisition.html
% https://au.mathworks.com/help/daq/daq.interfaces.dataacquisition.write.html

properties (Constant, Access = public)
    ComponentProperties = DAQComponentProperties.Data;
end

properties (Access = protected)
    SessionInfo = struct();
    ChannelMap = struct();
    HandleClass = 'daq.interfaces.DataAcquisition';
    TrackedChannels = {};
    SaveFID = [];
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
    if ~islogical(params.ChannelConfig) || params.ChannelConfig
        obj = obj.CreateChannels(obj.ConfigStruct.ChannelConfig, []);
    end
end

% Start device
function Start(obj)
    if ~isempty(obj.SavePath) || length(obj.SavePath) == 0
        obj.SaveFID = fopen(obj.SavePath, 'w');
    end
    % run stimulation
    startBackground(obj.DAQ);               % start data acquisition
    try
        wait(obj.DAQ,tTotal+1)          	% wait for data acquisition
    catch me
        warning(me.identifier,'%s',...      % rethrow timeout error as warning
            me.message); 
    end
end

%Stop device
function Stop(obj)
    stop(obj.SessionHandle);
end

% Change device parameters TODO ALL OF THESE REQUIRE A RESTART I THINK
function SetParams(obj, varargin)
    for i = 1:length(varargin):2
        set(obj.SessionHandle, varargin{i}, varargin{i+1});
    end
end

function daqStruct = GetParams(obj) %TODO this should all be handled in configstruct but I gotta check that works.
    % Get current device parameters for saving. Generic.          
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

function SaveAuxiliaries(obj, filepath)
    channelData = obj.GetChanParams;
    writetable(channelData, filepath);
end

function channelData = GetChanParams(obj)
    % Get channel parameters for saving. DAQ-specific.
    channels = obj.SessionHandle.Channels;
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
end

function PrintInfo(obj)
    % Print device information.
    disp(' ');
    disp(obj.SessionHandle.Channels);
    disp(' ');
end

function Clear(obj)
    % Completely clear the component session.
    if isvalid(obj.SessionHandle) && obj.SessionHandle.Running
        obj.Stop();
    end
    daqreset;
end

%% TODO STARTS HERE
function StartPreview(obj)
    % Dynamically visualise object output
    % if ~isempty(obj.PreviewPlot)
    %     return
    % else
    %     return
    % end
    % if isempty(obj.SessionHandle)
    %     return;
    % end
end

function StopPreview(obj)
    return
end

% Load a full experimental protocol
function obj = LoadProtocol(obj, varargin)
    parser = inputParser;
    stringValidate = @(x) ischar(x) || isstring(x);
    intValidate = @(x) ~isinf(x) && floor(x) == x;
    addParameter(parser, 'idxStim', 1, intValidate);
    addParameter(parser, 'filepath', '', stringValidate);
    addParameter(parser, 'p', '', @isstruct);
    addParameter(parser, 'g','', @isstruct);
    parse(parser, varargin{:});

    if ~isempty(parser.Results.filepath)
        [p, g] = readParameters(parser.Results.filepath);
    elseif ~isempty(parser.Results.p) && ~isempty(parser.Results.g)
        p = parser.Results.p;
        g = parser.Results.g;
    else
        error("No protocol provided for DAQComponent. Provide a " + ...
            "protocol using LoadProtocol and defining either the " + ...
            "'filename' or 'p' and 'g' arguments.")
    end
    obj.SessionInfo.p = p;
    obj.SessionInfo.g = g;

    % obj.LoadTrial('idxStim', parser.Results.idxStim);
end

function LoadTrial(obj, out)
    % Loads a trial from a matrix of size c x s where c is the number of
    % output channels and s is the number of samples in the trial.

    % release session (in case the previous run was incomplete)
    if obj.SessionHandle.Running
        obj.SessionHandle.stop
    end
    obj.DAQ.queueOutputData(out)            % queue data
    prepare(obj.DAQ)                        % prepare data acquisition
end

function LoadTrialFromParams(obj, componentTrialData, genericTrialData)
    % release session (in case the previous run was incomplete)
    if obj.SessionHandle.Running
        obj.SessionHandle.stop
    end
    % release(obj.SessionHandle)
    
    channels = obj.SessionHandle.Channels;
    rate = obj.SessionHandle.Rate;

    tPre     = genericTrialData.tPre  / 1000;
    tPost    = genericTrialData.tPost / 1000;
    tStim   = genericTrialData.tStim  / 1000;
    tTotal  = tPre + tStim + tPost;

    % Add Listener 
    obj.SessionHandle.ScansAvailableFcn = @obj.plotData;

    fds = fields(componentTrialData);
    timeAxis = linspace(1/obj.SessionHandle.Rate,tTotal,tTotal*obj.SessionHandle.Rate)-tPre;
    % Preallocate all zeros
    out = zeros(numel(timeAxis), length(obj.SessionHandle.Channels));

    for i = 1:length(fds)
        fieldName = fds{i};
        chIdx = obj.ChannelMap.fieldName.Index;
        if regexpi(fieldName, '^Thermode[A-z]*')
            % Thermode 
        elseif regexpi(fieldName, '^((Ana)|(Vib)|(Piezo))[A-z]*')
            % Analog 
        elseif regexpi(fieldName, '^(Dig)[A-z]*')
            % Arbitrary digital 
        elseif regexpi(fieldName, '^((PWM)|(LED))[A-z]*')
            % PWM 
        elseif regexpi(fieldName, '^Piezo[A-z]*')
            % Piezo
        elseif regexpi(fieldName, '^(Cam)[A-z]*')
            % Camera trigger TODO what if it's just a start??
            if contains(channels(chIdx).Type, 'Output')
                framerate = componentTrialData.(fieldName).Rate;
                framerate_unitstep = round(obj.SessionHandle.Rate/framerate);
                for jjj = 1:round(framerate_unitstep/2)
                    out(jjj:framerate_unitstep:end,chIdx) = 1;
                end
            else
                % set for input - I think this means do nothing? TODO check
            end
        elseif regexpi(fieldName, '^Arbitrary[A-z]*')
            % Arbitrary output.
        else
            error('Unsupported data type for DAQComponent: %s', fieldName);
        end
    end

    obj.LoadTrial(out);
end

function out = GenerateAnalogStim(obj, stimType, stimLength, params)
    % Accepts stimType / params combinations of:
    % piezo: ramp (default 20), freq, amp, dur, delay, rep
    rate = obj.ConfigStruct.Rate;
    MsToTicks = @(x) round(x*rate/1000);
    out = zeros(1, MsToTicks(stimLength));
    Aurorasf = 1/52; % (1V per 50mN as per book,20241125 measured as 52mN per 1 V PB)

    switch lower(stimType)
        case 'piezo'
            if ~isfield(params, 'ramp')
                ramp = 20;
            else
                ramp = params.ramp;
            end
            piezostimunitx = -ramp:ramp;
            piezostimunity = normpdf(piezostimunitx,0,3);
            piezostimunity = piezostimunity./max(piezostimunity);
            piezohold = ones(1,piezoDur);
            piezostimunity = [piezostimunity(1:ramp) piezohold piezostimunity(ramp+1:end)];
            
            if params.rep>0 % TODO MAKE SURE THIS IS CONSISTENT - DOES REP1 MEAN 2 INSTANCES OR ONE
                out(MsToTicks(params.delay))
                for pp = 1:rep
                    pos1 = (pp-1) .*(1/piezoFreq) ; % in seconds
                    tloc = find(tax>=pos1); tloc = tloc(1);
                    out(tloc:tloc+numel(piezostimunity)-1) = piezostim(tloc:tloc+numel(piezostimunity)-1)+piezostimunity;
                end
                out = piezostim.*piezoAmp;
            end
    end
end

function out = GenerateDigitalStim(obj, stimType, stimLength, params)
    % Accepts stimType / params combinations of:
    % PWM: dc (duty cycle, 0<=dc<=100), freq (Hz), dur, delay, rep, repdel, rampup, rampdown
    % square: delay, dur, rep, repdel
    % repeattrigger: freq, delay, dur(optional, defaults to full duration)
    % singletrigger: delay
    % startstoptrigger: delay, dur
    %% TODO ADD TTL SCANIMAGE
    rate = obj.ConfigStruct.Rate;
    MsToTicks = @(x) round(x*rate/1000);
    out = zeros(1, MsToTicks(stimLength));
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
            offset = MsToTicks(params.delay) + 1;
            % generate single stim
            singleStim = zeros(1, durationTicks);
            for i = 1:rampUpPeriods:periodTicks
                singleStim(i:i+round(rampUpTickIncrease * i)) = 1;
            end
            st = rampUpPeriods*periodTicks + 1;
            for i = st:st + highPeriods:periodTicks
                singleStim(i:i+onTicks) = ones(1, onTicks);
            end
            st = st + (highPeriods * periodTicks);
            for i = st:st + rampUpPeriods:periodTicks
                singleStim(i:i+round(onTicks - (rampDownTickDecrease * i))) = ones(1, onTicks - (rampDownTickDecrease*i));
            end
            repdelTicks = MsToTicks(params.repdel);
            totalDurTicks = (repdelTicks + durationTicks) * params.rep;
            for i = offset+1:offset+1+totalDurTicks:durationTicks+numel(singleStim)
                out(i:i+numel(singleStim)) = singleStim;
            end

        case 'square'
            stimTicks = MsToTicks(params.dur + params.repdel);
            for i = 1:params.rep:stimTicks
                out(i:i+MsToTicks(params.dur)) = 1;
            end

        case 'repeattrigger'
            framerateTicks = round(rate * params.freq);
            if ~isfield(params, 'dur')
                out(MsToTicks(params.delay):framerateTicks:end) = 1;
            else
                out(MsToTicks(params.delay):framerateTicks:MsToTicks(params.dur+params.delay)) = 1;
            end

        case 'singletrigger'
            out(MsToTicks(params.delay)) = 1;

        case 'startstoptrigger'
            out(MsToTicks(params.delay)) = 1;
            out(MsToTicks(params.delay)+MsToTicks(params.dur)) = 1;
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
        %% DEBUG
        filename = [pwd filesep 'config' filesep 'component_params' filesep 'Minimal_OuterLab_DaqChanParams.csv'];
    end
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
            if ~isempty(protocolIDs) && ~any(contains(protocolIDs, line.('ProtocolID'){:}))
                % skip channels that aren't required for this protocol.
                %TODO CHECK THIS WORKS FOR SUFFIXES e.g. ThermA-Recording
                %vs ThermA-Driver vs ThermA
                continue
            end
            deviceID = line.('deviceID'){1};
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
            channelID = line.('ProtocolID'){1};
            if ~isMATLABReleaseOlderThan('R2024b')
                channelList = add(channelList, ioType, deviceID, portNum, signalType, TerminalConfig=terminalConfig, Range=range);
            else
                switch ioType
                    case 'input'
                        ch = addinput(obj.SessionHandle,deviceID,portNum,signalType);
                    case 'output'
                        ch = addoutput(obj.SessionHandle,deviceID,portNum,signalType);
                    case 'bidirectional'
                        ch = addbidirectional(obj.SessionHandle,deviceID,portNum,signalType);
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
            obj.ChannelMap.(channelID) =  ch;
        catch exception
            % dbstack
            % keyboard
            message = ['Encountered an error reading channels config file on line ' ...
                    char(string(ii)) ': ' exception.message ' Line skipped.'];
            warning(message);
        end
    end
    if ~isMATLABReleaseOlderThan('R2024b')
        obj.SessionHandle.Channels = channelList;
    end
end
end


%% Private Methods
methods (Access = protected)

function componentID = GetComponentID(obj)
    componentID = convertStringsToChars([obj.ConfigStruct.ID '-' obj.ConfigStruct.Vendor '-' obj.ConfigStruct.Model]);
    componentID = [componentID{:}];
end

% gets current device status. TODO
% Options: ready / running / error
function status = GetSessionStatus(obj)
    % Query device status. TODO
    % options: ready / acquiring / writing / error / stopped / empty / loading
    if isempty(obj.SessionHandle)
        status = 'not initialised';
    else
        status = 'ok';
    end
end

function name = FindDaqName(obj, deviceID, vendorID, model)
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

%%TODO!! STARTS HERE
function preloadChannels(obj, p, idxStim)

    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%% ADD ANALOG OUTPUT GENERATION %%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    ramp1 = 20;  % original was 15, trying with 2 on 13.12.2024 change 2 on 20250501
    piezostimunitx = -ramp1:ramp1;
    piezostimunity = normpdf(piezostimunitx,0,3);
    piezostimunity = piezostimunity./max(piezostimunity);
    piezohold = ones(1,piezoDur);
    piezostimunity = [piezostimunity(1:ramp1) piezohold piezostimunity(ramp1+1:end)];
    
    piezostim = zeros(size(tax ));
    if piezoStimNum>0
        for pp = 1:piezoStimNum
            pos1 = (pp-1) .*(1/piezoFreq) ; % in seconds
            tloc = find(tax>=pos1); tloc = tloc(1);
            piezostim(tloc:tloc+numel(piezostimunity)-1) = piezostim(tloc:tloc+numel(piezostimunity)-1)+piezostimunity;
        end
        piezostim = piezostim.*piezoAmp;
    else
       piezostim = zeros(size(tax )); 
    end
    
    out(:,npreQSTtrig+kk+2) = piezostim;
    
    
    
    
    
    obj.DAQ.queueOutputData(out)            % queue data
    prepare(obj.DAQ)                        % prepare data acquisition
    
    % wait for thermodes to reach neutral temperature
    obj.waitForNeutral
    
    % open output file (if filename provided)
    if nargin > 1
        output  = true;
        fid1    = fopen(fnOut,'w');
    else
        output  = false;
    end
    
    % run stimulation
    startBackground(obj.DAQ);               % start data acquisition
    try
        wait(obj.DAQ,tTotal+1)          	% wait for data acquisition
    catch me
        warning(me.identifier,'%s',...      % rethrow timeout error as warning
            me.message); 
    end
    
    % close output file
    if output
        fclose(fid1);
    end
    
    % delete listener
    delete(lh);
end


function plotData(~,event)
    
    % manage persistent variables
    persistent nTherm idTherm idxData
    if isempty(nTherm)
        nTherm = obj.nThermodes;
    end
    if isempty(idxData)
        idxData = 1:(4*nTherm);
    end
    if isempty(idTherm)
        idTherm = arrayfun(@(x) {['Thermode' char(64+x)]},1:nTherm);
    end
    
    % build indices for plotting
    a   = event.Source.NotifyWhenDataAvailableExceeds;
    b   = event.Source.ScansAcquired;
    idx = (1:a)+(b-a);
    
    % scale data from thermodes
    dat = event.Data;
    % dat(:,idxData(1:2)) = dat(:,idxData(1:2)) * 17.0898 - 5.0176;
    dat(:,idxData(1:2)) = dat(:,idxData(1:2)) * 12  - 2; % PB 20241219
    dat(:,idxData(3:4)) = (dat(:,idxData(3:4))*10 + 32) ;
    ylim([12 50])
    
    % plot data
    for ii = 1:5
        for jj = 1:nTherm
            obj.h.(idTherm{jj}).plot(ii).YData(idx) = dat(:,ii+(jj-1)*5);
        end
    end
    
    % save to disk (optional)
    if output
        fwrite(fid1,[event.TimeStamps-tPre,dat,out(idx,:)]','double');
    end
end

%TODO!! ENDS HERE
end
end