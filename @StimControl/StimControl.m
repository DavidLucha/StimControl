classdef StimControl < handle

properties (Access = protected)
    path = [];
end

properties %(Access = private)
    h           = []            % GUI handles
    d           = []            % 
    p           = []            % stimulation parameters/protocol
    g           = []            % general protocol parameters
    idxStim     = []            % current stimulus index
    t                           % timer
    chAI
    chD
    cmdStack    = []
    name        = 'StimControl'
    pFile       = []
    isRunning   = false;
    isPaused    = false;
    hardwareParams
    trialIdx    = 1;
    tLastStatusChange = 0;
    taskPool    = [];
end

properties (Dependent)
    animalID
    experimentID
    trialNum
    dirAnimal
    dirExperiment
    status
    activeComponents
end

methods
    function obj = StimControl(varargin)
        % close all
        daqreset
        imaqreset
        obj.path.base = pwd;
        if ~contains(pwd, 'StimControl')
            obj.path.base = [pwd filesep 'StimControl'];
        end
        addpath(pwd)
        addpath(genpath(fullfile(obj.path.base,'components')))
        addpath(genpath(fullfile(obj.path.base,'common')))
        clc
        disp('Welcome to StimControl')
        
        %% Initialise Path
        obj.path.dirData = fullfile(getenv('UserProfile'),'Desktop','logs');
        configBase = [obj.path.base filesep 'config'];
        obj.path.paramBase = [configBase filesep 'component_params'];
        obj.path.protocolBase  = [configBase filesep 'experiment_protocols'];
        obj.path.sessionBase = [configBase filesep 'session_presets'];
        obj.path.componentMaps = [configBase filesep 'component_protocol_maps'];

        %% Create data directory
        if ~exist(obj.path.dirData,'dir')
            mkdir(obj.path.dirData)
        end

        %% Find available hardware
        disp("Initialising Available Hardware...")
        obj = obj.findAvailableHardware();

        %% Create figure and get things going
        disp("Creating figure...")
        createFigure(obj)
        
        %% battery timer
        obj.t = timer(...
            'StartDelay',       0, ...
            'Period',           300, ...
            'ExecutionMode',    'fixedRate', ...
            'StartFcn',         @obj.callbackTimer, ...
            'TimerFcn',         @obj.callbackTimer);
        start(obj.t)
        
        % obj.p2GUI;
        % obj.checkSync
        StartPreviews(obj);
        disp("Ready")
    end
end

methods (Access = private)
    % figure creation
    createFigure(obj)
    createPanelSetupControl(obj, hPanel, ~)
    createPanelSetupPreview(obj, hPanel, ~)
    createPanelComponentConfig(obj, hPanel, ~, component)
    createPanelSessionControl(obj, hPanel, ~)
    createPanelSessionPreview(obj, hPanel, ~)
    createPanelSessionHardware(obj, hPanel, ~)

    % app control callbacks
    callbackChangeTab(obj, src, event)
    callbackDebug(obj, src, event)
    
    % experiment control callbacks
    callbackLoadProtocol(obj, src, event)
    callbackLoadTrial(obj, src, event)
    callbackStartStop(obj, src, event)
    callbackPauseResume(obj, src, event)
    callbackTrialStart(obj, src, event)
    callbackNewTrial(obj, src, event)
    callbackSelectAnimal(obj, src, event)

    % file control callbacks
    callbackLoadConfig(obj, src, event)
    callbackSaveConfig(obj, src, event)

    % hardware control callbacks
    callbackEditComponentConfig(obj, ~, ~)

    % Run it all
    runTrial(obj)

    % misc
    callbackFileExit(obj,~,~)
    callbackTimer(obj, ~, ~)

    % createPanelAnimal(obj,hPanel,~)
    % createPanelProtocol(obj,hPanel,~)
    % createPanelSingleRun(obj,hPanel,~)
    % createPanelLED(obj,hPanel,~)
    % createPanelThermode(obj,hPanel,~,idxThermode,nThermodes)
    % createPlotThermode(obj,hAx)
    % createPlotLED(obj,hAx)
    % createDAQchannels(obj)
    % 
    % callbackInitialise(obj)
    % callbackFileOpen(obj,~,~)
    % callbackFileClose(obj,hClose,~)
    % callbackFileExit(obj,~,~)
    % 
    % callbackDebugKB(obj,~,~)
    % callbackDebugCB(obj,~,~)
    % callbackDebugDelEmpty(obj,~,~)
    % 
    % callbackThermodeToggle(obj,hEdit,src)
    % callbackThermodeEdit(obj,hEdit,src)
    % callbackThermodeSync(obj,hCheck,~)
    % callbackThermodeITerm(obj,hCheck,~)
    % 
    % callbackLEDEdit(obj,hEdit,src)
    % 
    % callbackTimer(obj,~,~)
    % 
    % callbackAnimalAdd(obj,hCtrl,~)
    % updateAnimals(obj)
    % 
    % callbackSingleRunStart(obj,hCtrl,~)
    % 
    % callbackProtocolNstim(obj,hCtrl,src)
    % callbackProtocolStart(obj,~,~)
    % callbackProtocolStop(obj,~,~)
    % 
    % enableThermodeEdit(obj,bool)
    % p2serial(obj,p)
    % p2GUI(obj)
    % setAxesPadding(~,hax,padding)
    % checkSync(obj)
    % waitForNeutral(obj)
    % setTitle(obj,string)
    % stimulate(obj,filename)
    % out = estimateTime(obj)

    %% Inline functions
    function obj = findAvailableHardware(obj)
        %% Find available hardware
        obj.d.Available = {};
        obj.d.Active = [];
        obj.d.IDComponentMap = configureDictionary('string', 'cell');
        obj.d.IDidxMap = configureDictionary('string', 'double');
        obj.d.ProtocolComponents = configureDictionary('string', 'cell');
        obj.d.ComponentProtocols = configureDictionary('string', 'cell');
        
        % DAQs
        daqs = daqlist();
        for i = 1:height(daqs)
            s = table2struct(daqs(i, :));
            initStruct = struct( ...
                'Vendor', s.VendorID, ...
                'ID', s.DeviceID, ...
                'Model', s.Model);
            comp = DAQComponent('Initialise', true, 'ConfigStruct', initStruct, 'ChannelConfig', false);
            obj.d.IDComponentMap(comp.ComponentID) = {comp};
            obj.d.IDidxMap(comp.ComponentID) = length(obj.d.Available) + 1;
            obj.d.Available{end+1} = comp;
            obj.d.Active(end+1) = true;
        end
    
        % Cameras
        %TODO FIX/SUPPRESS WARNING HERE FOR GIGE
        adaptors = imaqhwinfo().InstalledAdaptors;
        for i = 1:length(adaptors)
            adaptorDevices = imaqhwinfo(adaptors{i});
            devices = adaptorDevices.DeviceInfo;
            for j = 1:length(devices)
                temp = devices(j);
                initStruct = struct( ...
                    'Adaptor', adaptorDevices.AdaptorName, ...
                    'ID', temp.DeviceName);
                 comp = CameraComponent('Initialise', true, 'ConfigStruct', initStruct);
                 obj.d.IDComponentMap(comp.ComponentID) = {comp};
                 obj.d.IDidxMap(comp.ComponentID) = length(obj.d.Available) + 1;
                 obj.d.Available{end+1} = comp;
                 obj.d.Active(end+1) = true;
            end
        end
    end

    function StartPreviews(obj)
        for i = 1:length(obj.d.Available)
            obj.d.Available{i}.StartPreview();
        end
    end
end

methods
    function filepath = get.dirAnimal(obj)
        filepath = fullfile(obj.path.dirData,obj.animalID);
        if ~exist(filepath,'dir')
            mkdir(filepath)
        end
    end

    function filepath = get.dirExperiment(obj)
        if ~isfield(obj.path, 'date')
            obj.UpdateDateTime
        end
        tmpPath = [obj.dirAnimal filesep obj.path.date];
        if ~exist(tmpPath, 'dir')
            mkdir(tmpPath);
        end
        tmpPath = [tmpPath filesep obj.path.date '_' obj.path.time '_' obj.experimentID];
        if ~exist(tmpPath, 'dir')
            mkdir(tmpPath);
        end
        filepath = tmpPath;
    end

    function updateDateTime(obj)
        obj.updateDate;
        obj.updateTime;
    end

    function updateDate(obj)
        dt = datetime("now");
        dt.Format = "yyyyMMdd";
        obj.path.date = char(dt);
    end

    function updateTime(obj)
        dt = datetime("now");
        dt.Format  = "hhmmss";
        obj.path.time = char(dt);
    end

    function set.experimentID(obj, val)
        if ~contains(obj.h.protocolSelectDropDown.Items, val)
            obj.h.protocolSelectDropDown.Items{end+1} = val;
        end
        obj.h.protocolSelectDropDown.Value = val;
        % TODO UPDATE GUI HERE - trialnum, estimated time, etc.
    end

    function out = get.experimentID(obj)
        out = obj.h.protocolSelectDropDown.Value;
    end

    function set.animalID(obj, val)
        obj.h.animalSelectDropDown.Items{end+1} = val;
        obj.h.animalSelectDropDown.Value = val;
    end

    function out = get.animalID(obj)
        out = obj.h.animalSelectDropDown.Value;
    end

    function set.status(obj, val)
        % supported values: 
        % NOT INITIALISED / READY / RUNNING / INTER-TRIAL / PAUSED / ERROR
        % / LOADING
        obj.tLastStatusChange = tic;
        val = lower(val);
        if strcmpi(val, 'not initialised')
            obj.h.statusLabel.Text = 'Not Initialised';
            obj.h.statusLamp.Color = '#808080';
            obj.h.startStopExperimentBtn.Enable = 'off';
            obj.h.startStopExperimentBtn.Text = 'START';
            obj.h.pauseBtn.Enable = 'off';
            obj.isRunning = false;
            obj.isPaused = false;

        elseif strcmpi(val, 'ready')
            obj.h.statusLabel.Text = 'Ready';
            obj.h.statusLamp.Color = '#00FF00';
            obj.h.startStopExperimentBtn.Enable = 'on';
            obj.h.startStopExperimentBtn.Text = 'START';
            obj.h.pauseBtn.Enable = 'off';
            obj.isRunning = false;
            obj.isPaused = false;

        elseif strcmpi(val, 'running')
            obj.h.statusLabel.Text = 'Running';
            obj.h.statusLamp.Color = '#FFA500';
            obj.h.startStopExperimentBtn.Enable = 'on'; %TODO or on?
            obj.h.startStopExperimentBtn.Text = 'STOP';
            obj.h.pauseBtn.Enable = 'off';
            obj.h.pauseBtn.Text = 'PAUSE';
            obj.isRunning = true;
            obj.isPaused = false;

        elseif strcmpi(val, 'inter-trial')
            obj.h.statusLabel.Text = 'Inter-trial';
            obj.h.statusLamp.Color = '#FFFFFF';
            obj.h.startStopExperimentBtn.Enable = 'on';
            obj.h.startStopExperimentBtn.Text = 'STOP';
            obj.h.pauseBtn.Enable = 'on';
            obj.h.pauseBtn.Text = 'PAUSE';
            obj.isRunning = true;
            obj.isPaused = false;

        elseif strcmpi(val, 'paused')
            obj.h.statusLabel.Text = 'Paused';
            obj.h.statusLamp.Color = '#008080';
            obj.h.startStopExperimentBtn.Enable = 'on';
            obj.h.startStopExperimentBtn.Text = 'STOP';
            obj.h.pauseBtn.Enable = 'on';
            obj.h.pauseBtn.Text = 'RESUME';
            obj.isRunning = true;
            obj.isPaused = true;

        elseif strcmpi(val, 'loading')
            obj.h.statusLabel.Text = 'Loading';
            obj.h.statusLamp.Color = '#FFFF00';
        end
    end

    function val = get.status(obj)
        val = lower(obj.h.statusLabel.Text);
    end

    function activeComponents = get.activeComponents(obj)
        activeComponents = obj.d.Available(obj.d.Active == 1);
    end
    
    function set.trialNum(obj, value)
        nTrials = length(obj.p);
        validateattributes(value,{'numeric'},...
            {'scalar','integer','real','nonnegative','<=',nTrials})
        
        obj.h.numTrialsElapsedLabel.Text = sprintf('Trial: %d/%d', value, nTrials);
        obj.h.trialNumDisplay.Value = value;   
        obj.h.totalTrialsLabel.Text = sprintf('/ %d', nTrials);
        obj.h.trialTimeEstimate.Text = sprintf('timeEstimate');
        % TODO UPDATE GUI (as below)
        % obj.h.protocol.edit.nStim.String   = sprintf('%d/%d',value,nTrials);
        % obj.h.protocol.edit.Comment.String = obj.p(value).Comments;
        % obj.h.ThermodeA.edit.vibDur.String = obj.p(value).ThermodeA.VibrationDuration;
        % obj.h.ThermodeB.edit.vibDur.String = obj.p(value).ThermodeB.VibrationDuration;
        % obj.h.ThermodeA.edit.vibDur.Value  = obj.p(value).ThermodeA.VibrationDuration;
        % obj.h.ThermodeB.edit.vibDur.Value  = obj.p(value).ThermodeB.VibrationDuration;
        % obj.h.LED.edit.ledDur.String       = obj.p(value).ledDuration;
        % obj.h.LED.edit.ledFreq.String      = obj.p(value).ledFrequency;
        % obj.h.LED.edit.ledDC.String        = obj.p(value).ledDutyCycle;
        % obj.h.LED.edit.ledDelay.String     = obj.p(value).ledDelay;
        % obj.h.LED.edit.ledDur.Value        = obj.p(value).ledDuration;
        % obj.h.LED.edit.ledFreq.Value       = obj.p(value).ledFrequency;
        % obj.h.LED.edit.ledDC.Value         = obj.p(value).ledDutyCycle;
        % obj.h.LED.edit.ledDelay.Value      = obj.p(value).ledDelay;
        % obj.p2serial(obj.p(value));
        % obj.p2GUI
    end

    function val = get.trialNum(obj)
        val = obj.h.trialNumDisplay.Value;
    end

    function updatePathDisplay(obj)

    end

    function errorMsg(obj, message)
        try
            obj.h.trialInformationScroller.Value = char(message);
            obj.h.trialInformationScroller.FontColor = 'red';
        catch % handle likely not initialised
            error(message)
        end
    end

    % function out = get.dirAnimal(obj)
    %     out = fullfile(obj.dirData,obj.animalID);
    % end
    % 
    % function out = get.animalID(obj)
    %     tmp = obj.h.animal.listbox.id;
    %     out = tmp.String{tmp.Value};
    % end
    % 
    % function out = get.nThermodes(obj)
    %     out = length(obj.s);
    % end
    % 
    % function set.idxStim(obj,value)
    %     nStim = length(obj.p);
    %     validateattributes(value,{'numeric'},...
    %         {'scalar','integer','real','nonnegative','<=',nStim})
    %     obj.idxStim = value;
    % 
    %     obj.h.protocol.edit.nStim.String   = sprintf('%d/%d',value,nStim);
    %     obj.h.protocol.edit.Comment.String = obj.p(value).Comments;
    %     obj.h.ThermodeA.edit.vibDur.String = obj.p(value).ThermodeA.VibrationDuration;
    %     obj.h.ThermodeB.edit.vibDur.String = obj.p(value).ThermodeB.VibrationDuration;
    %     obj.h.ThermodeA.edit.vibDur.Value  = obj.p(value).ThermodeA.VibrationDuration;
    %     obj.h.ThermodeB.edit.vibDur.Value  = obj.p(value).ThermodeB.VibrationDuration;
    %     obj.h.LED.edit.ledDur.String       = obj.p(value).ledDuration;
    %     obj.h.LED.edit.ledFreq.String      = obj.p(value).ledFrequency;
    %     obj.h.LED.edit.ledDC.String        = obj.p(value).ledDutyCycle;
    %     obj.h.LED.edit.ledDelay.String     = obj.p(value).ledDelay;
    %     obj.h.LED.edit.ledDur.Value        = obj.p(value).ledDuration;
    %     obj.h.LED.edit.ledFreq.Value       = obj.p(value).ledFrequency;
    %     obj.h.LED.edit.ledDC.Value         = obj.p(value).ledDutyCycle;
    %     obj.h.LED.edit.ledDelay.Value      = obj.p(value).ledDelay;
    % 
    %     obj.p2serial(obj.p(value));
    %     obj.p2GUI
    % end
end
end