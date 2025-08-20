classdef (HandleCompatible) CameraComponent < HardwareComponent
% Generic wrapper class for camera objects
properties (Constant, Access = public)
    ComponentProperties = CameraComponentProperties.Data
end

properties (Access = protected)
    Status
    LastAcquisition
    HandleClass = ''
end

methods (Access = public)
function obj = CameraComponent(varargin)  
    p = obj.GetBaseParser();
    % add device-specific parameters here
    parse(p, varargin{:});
    params = p.Results;
    % extract device-specific parameters here
    obj = obj.CommonInitialisation(params);
    if params.Initialise
        obj = obj.Initialise('ConfigStruct', params.Struct);
    end
end

% Initialise device
function obj = Initialise(obj, varargin)
    p = inputParser;
    addParameter(p, 'ConfigStruct', []);
    parse(p, varargin{:});
    params = p.Results;
    obj.Status = "loading";

    %---device---
    if isempty(obj.SessionHandle) || ~isempty(params.ConfigStruct)
        % if the camera is uninitialised or the params have changed
        camstr = obj.GetConfigStruct(params.ConfigStruct);

        obj.ConfigStruct = camstr;
        imaqreset
        if ~contains(imaqhwinfo().InstalledAdaptors, camstr.Adaptor)
            error("Camera adaptor %s not installed. Installed adaptors: %s", ...
                camstr.Adaptor, imaqhwinfo.InstalledAdaptors{:});
        end
        vidObj = videoinput(camstr.Adaptor);
        src = getselectedsource(vidObj);
        if contains(camstr.Adaptor, 'pcocameraadaptor')
            clockSpeed = set(src,'PCPixelclock_Hz');
            [~,idx] = max(str2num(cell2mat(clockSpeed))); %get fastest clockspeed
            src.PCPixelclock_Hz = clockSpeed{idx}; %fast scanning mode
            src.E2ExposureTime = 1000/str2double(app.FrameRate.Value) * 1000; %set framerate
            if isfield(camstr, 'Binning')
                if ~isnumeric(camstr.Binning)
                    binVal = str2double(camstr.Binning);
                else
                    binVal = camstr.Binning;
                end
                try 
                    src.B1BinningHorizontal = num2str(binVal);
                    src.B2BinningVertical = num2str(binVal);
                catch
                    src.B1BinningHorizontal = num2str(bin,'%02i');
                    src.B2BinningVertical = num2str(bin,'%02i');
                end
            end
        elseif contains(camstr.Adaptor, 'gentl')
            src.Gain = str2double(camstr.Gain);
            src.AutoTargetBrightness = 5.019608e-01;
            if isfield(camstr, 'Binning')
                if ~isnumeric(camstr.Binning)
                    binVal = str2double(camstr.Binning);
                else
                    binVal = camstr.Binning;
                end
                src.BinningHorizontal = binVal;
                src.BinningVertical = binVal;
            end
        else
            %TODO fill out GENERIC CAMERAS
        end
        if isempty(camstr.ROIPosition)
            vidRes = get(vidObj,'VideoResolution');
            camstr.ROIPosition = [0 0 vidRes];
        end
        set(vidObj,'TriggerFrameDelay',camstr.TriggerFrameDelay);
        set(vidObj,'FrameGrabInterval',camstr.FrameGrabInterval);
        set(vidObj,'TriggerRepeat',camstr.TriggerRepeat);
        set(vidObj,'ROIposition',camstr.ROIPosition);
        set(vidObj,'FramesPerTrigger',str2double(camstr.FramesPerTrigger));
        vidObj.FramesAcquiredFcnCount = camstr.FrameGrabInterval;
        vidObj.FramesAcquiredFcn = @obj.ReceiveFrame;
        switch camstr.TriggerMode
            %TODO FURTHER INTO THIS AND FIND THE DOCUMENTATION
            case "hardware"
                src.LineSelector = camstr.TriggerLine;
                src.LineMode = "Input";
                src.TriggerSelector = camstr.TriggerSelector;
                src.TriggerMode = "On";
                src.TriggerSource = camstr.TriggerLine;
                src.TriggerActivation = camstr.TriggerActivation;
            case "manual" %TODO TEST THESE
                src.TriggerSource = "Software";
                src.TriggerSelector = camstr.TriggerSelector;
                src.TriggerActivation = "none";
            case "immediate" %TODO TEST THESE
                src.LineSelector = camstr.OutputLine;
                src.LineMode = "Output";
                src.TriggerActivation = "none";
        end
        triggerconfig(vidObj,camstr.TriggerMode);
        obj.SessionHandle = vidObj;
        obj.Status = "ok";
    end
    
    % ---display---
    if ~isempty(obj.SessionHandle)
        obj.PrintInfo();
    end
end

% Start device
function Start(obj)
    %TODO if in protocol vs out.
    if ~isrunning(obj.SessionHandle)
        start(obj.SessionHandle);
    end
    obj.FrameCount = 1;
end

% Stop device
function Stop(obj)
    try %TODO CHECK WHICH OF THESE WORKS?
        stoppreview(obj.SessionHandle);
    end
    try
        closepreview(obj.SessionHandle);
    end
    if ~isempty(obj.SessionHandle)
        stop(obj.SessionHandle);
    end
end

% Pause device
function Pause(obj)
    return
end

% Unpause device
function Continue(obj)
    return
end

% Complete reset. Clear device.
function Clear(obj)
    obj.Stop();
    imaqreset;
end

% Gets current device status
% Options: ok / ready / running / error / empty / loading
function status = GetSessionStatus(obj)
    if obj.Status == "error" || obj.Status == "loading"
        status = obj.Status;
    elseif isrunning(obj.SessionHandle)
        status = "ready";
        if toc(obj.LastAcquisition) > seconds(1)
            status = "running";
        end
    else
        status = "ok";
    end
end

function StartPreview(obj)
    target = obj.PreviewPlot;

    if isempty(obj.SessionHandle)
        return;
    end

    vidRes = get(obj.SessionHandle,'VideoResolution');
    nbands = get(obj.SessionHandle,'NumberOfBands');

    if ~isempty(target)
        imshow(zeros(vidRes(2),vidRes(1),nbands),[],'parent',target);
        preview(obj.SessionHandle, target.Children);
        axis(target, "tight");
    else
        preview(obj.SessionHandle);
        axis("tight");
    end
    maxRange = floor(256*0.7); %limit intensity to 70% of dynamic range to avoid ceiling effects
    cMap = gray(maxRange); cMap(end+1:256,:) = repmat([1 0 0 ],256-maxRange,1);
    colormap(target,cMap);
end

function StopPreview(obj)

end

% Change device parameters
function obj = SetParams(obj, varargin)
    obj.Status = "loading";
    restarters = ["Binning", "TriggerMode", "ROIPosition"];
    vidObj = obj.SessionHandle;
    src = getselectedsource(vidObj);
    for i = 1:length(varargin):2
        param = varargin{i};
        if ~obj.ComponentProperties.(param).dynamic
            % if any given params require obj restart, restart obj.
            Stop(obj);
            break
        end
    end
    for i = 1:length(varargin):2
        param = varargin{i};
        val = varargin{i+1};
        if ~contains(getfields(obj.ConfigStruct), param)
            error("Could not set field %s. Valid fields are: %s", param, getfields(obj.ConfigStruct));
        else
            obj.ConfigStruct = setfield(obj.ConfigStruct, param, val);
        end
        switch param
            case "SavePath"
                obj.SavePath = val;
            case "Binning"
                continue
            case "BinningType"
                continue
            case "Gain"
                src.Gain = val;
            case "ExposureTime"
                src.ExposureTime = val;
            case "OutputLine"
                src.LineSelector = val;
                src.LineMode = "Output";
            case "TriggerActivation"
                src.TriggerActivation = val;
            case "TriggerLine"
                src.LineSelector = val;
                src.LineMode = "Input";
                src.TriggerSource = val;
            case "TriggerMode"
                switch val
                    case "hardware"
                        src.TriggerSource = obj.ConfigStruct.TriggerLine;
                        src.TriggerMode = "On";
                    case "manual" %TODO TEST THESE
                        src.TriggerSource = "Software";
                    case "immediate" %TODO TEST THESE
                end
                triggerconfig(vidObj,val);
            case "TriggerSelector"
                src.TriggerSelector = val;
            case "ROIPosition"
                if isempty(val)
                    % reset ROI
                    vidRes = get(obj.SessionHandle,'VideoResolution');
                    val = [0 0 vidRes];
                end
                    set(obj.SessionHandle, param, val);
            otherwise
                %FramesPerTrigger, TriggerFrameDelay,
                %FrameGrabInterval, TriggerRepeat,
                set(obj.SessionHandle, param, val);
        end

        if contains(varargin, "Binning")
            imaqreset;
            obj = obj.Initialise();
        end
    end
    obj.Status = "ok";
end

% get current device parameters for saving
function objStruct = GetParams(obj)
    objStruct = obj.ConfigStruct;
end

% Print device information
function PrintInfo(obj)
    obj.SessionHandle
end

function GetInspector(obj)
    inspect(obj.SessionHandle);
    inspect(obj.ConfigStruct);
end

function LoadProtocol(obj, varargin)
    %TODO THIS
    % depending on trigger type this could be dicey? hardware is
    % taken care of with daq but software is gonna be rough
end
end

methods (Access = private)
function name = GetCameraName(obj, adaptorName)
    info = imaqhwinfo;
    nameCheck = contains(info.InstalledAdaptors, adaptorName);
    name = '';
    if any(nameCheck)
        name = adaptorName;
    else
        warning("Target camera adaptor %s not available. Searching for other cameras.", adaptorName);
        if length(info.InstalledAdaptors) == 1
            name = info.InstalledAdaptors{1};
        elseif obj.Required
            out = listdlg('Name', 'Please select your camera', ...
                'SelectionMode','single','liststring',info.InstalledAdaptors,'listsize',[300 300]);
            if ~isempty(out)
                name = info.InstalledAdaptors{out};
            end
        end
    end
end

function ReceiveFrame(obj, src, vidObj)
    try
        imgs = getdata(src,src.FramesAvailable); 
        obj.LastAcquisition = tic;
        numImgs = size(imgs);
        numImgs = numImgs(4);
        for i = 1:numImgs
            imname = strcat(obj.SavePath, filesep, string(obj.FrameCount), '_', string(datetime(datetime, "Format", 'yyyyMMdd_HHmmss.SSS')), ".TIFF");
            imwrite(imgs(:,:,:,i),imname);
            obj.FrameCount = obj.FrameCount + 1;
        end
    catch exception
        obj.Status = "error";
        disp("Encountered an error imaging.")
        dbstack
        disp(exception.message)
    end
end
end
end