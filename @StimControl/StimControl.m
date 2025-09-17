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
    trialNum
end

properties (Dependent)
    animalID
    experimentID
    dirAnimal
    dirExperiment
    displayDate
    displayDateTime
end

methods
    function obj = StimControl(varargin)
        % close all
        daqreset
        imaqreset
        addpath(pwd)
        addpath(genpath(fullfile(pwd,'components')))
        addpath(genpath(fullfile(pwd,'common')))
        clc
        disp('Welcome to StimControl')
        
        %% Initialise Path
        obj.path.dirData = fullfile(getenv('UserProfile'),'Desktop','logs');
        obj.path.base = pwd;
        if ~contains(pwd, 'StimControl')
            obj.path.base = [pwd filesep 'StimControl'];
        end
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
    callbackSelectTrial(obj, src, event)
    callbackSelectAnimal(obj, src, event)

    % file control callbacks
    callbackLoadConfig(obj, src, event)
    callbackSaveConfig(obj, src, event)

    % hardware control callbacks
    callbackEditComponentConfig(obj)
    % callbackViewHardwareOutput(obj)

    % misc
    callbackFileExit(obj,~,~)

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
        filepath = [obj.path.dirData filesep obj.animalID];
        if ~exist(filepath,'dir')
            mkdir(filepath)
        end
    end

    function filepath = get.dirExperiment(obj)
        tmpPath = [obj.path.dirAnimal filesep obj.displayDate];
        if ~exist(tmpPath, 'dir')
            mkdir(tmpPath);
        end
        tmpPath = [tmpPath filesep obj.displayDateTime '_' obj.experimentID];
        if ~exist(tmpPath, 'dir')
            mkdir(tmpPath);
        end
        filepath = tmpPath;
    end

    function out = get.displayDate(obj)
        dt = datetime("now");
        dt.Format = "yyyyMMdd";
        out = string(dt);
    end

    function out = get.displayDateTime(obj)
        dt = datetime("now");
        dt.Format  = "yyyyMMdd_hhmmss";
        obj.path.datetime = string(dt);
        out = string(dt);
    end

    function set.animalID(obj, val)

    end

    function set.experimentID(obj, val)

    end
    
    function set.trialNum(obj, value)
        nTrials = length(obj.p);
        validateattributes(value,{'numeric'},...
            {'scalar','integer','real','nonnegative','<=',nTrials})
        obj.trialNum = value;
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

    function updatePathDisplay(obj)

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