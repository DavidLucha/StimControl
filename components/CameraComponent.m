classdef (HandleCompatible) CameraComponent < HardwareComponent
% Generic wrapper class for camera objects
% https://au.mathworks.com/help/imaq/videoinput.html
% https://au.mathworks.com/help/parallel-computing/quick-start-parallel-computing-in-matlab.html
properties (Constant, Access = public)
    ComponentProperties = CameraComponentProperties.Data
end

properties (Access = protected)
    Status
    LastAcquisition
    HandleClass = ''
    FrameCount = 1;
end

methods(Static, Access=public)
    function Clear()
        imaqreset;
    end
end

methods (Access = public)
function obj = CameraComponent(varargin)
% Class for interfacing with a generic IMAQ toolbox camera. 
% Constructor takes the following arguments::
% 'Required'    (logical, true)     whether to throw errors as errors or warnings
% 'Handle'      (handle, [])        the handle to an existing session of that component type
% 'ConfigStruct'(struct, [])        struct containing initialisation params - see
%                                   ComponentProperties
% 'SavePath'    (string, '')        the path to save outputs
% 'Abstract'    (logical, false)    if false, does not attempt to initialise a
%                                   session with hardware but retains access to class logic.
% Initialise    (logical, true)     if true, session with hardware will be
%                                   immediately started upon object creation.
%                                   If false, can be initialised later using obj.Configure
    p = obj.GetBaseParser();
    parse(p, varargin{:});
    params = p.Results;
    obj = obj.Initialise(params);
    if params.Initialise && ~params.Abstract
        obj = obj.InitialiseSession('ConfigStruct', params.ConfigStruct);
    end
end

% Initialise device
function obj = InitialiseSession(obj, varargin)
    p = inputParser;
    addParameter(p, 'ConfigStruct', []);
    addParameter(p, 'KeepHardwareSettings', []);
    parse(p, varargin{:});
    params = p.Results;
    
    obj.Status = "loading";

    %---device---
    if isempty(obj.SessionHandle) || ~isempty(params.ConfigStruct)
        % if the camera is uninitialised or the params have changed
        camstr = obj.GetConfigStruct(params.ConfigStruct);
        obj.ConfigStruct = camstr;

        imaqreset
        if ~contains(imaqhwinfo().InstalledAdaptors, obj.ConfigStruct.Adaptor)
            error("Camera adaptor %s not installed. Installed adaptors: %s", ...
                obj.ConfigStruct.Adaptor, imaqhwinfo.InstalledAdaptors{:});
        end
        vidObj = videoinput(obj.ConfigStruct.Adaptor);
        src = getselectedsource(vidObj);
        if contains(obj.ConfigStruct.Adaptor, 'pcocameraadaptor')
            clockSpeed = set(src,'PCPixelclock_Hz');
            [~,idx] = max(str2num(cell2mat(clockSpeed))); %get fastest clockspeed
            src.PCPixelclock_Hz = clockSpeed{idx}; %fast scanning mode
            src.E2ExposureTime = 1000/str2double(app.FrameRate.Value) * 1000; %set framerate
            if isfield(obj.ConfigStruct, 'Binning')
                if ~isnumeric(obj.ConfigStruct.Binning)
                    binVal = str2double(obj.ConfigStruct.Binning);
                else
                    binVal = obj.ConfigStruct.Binning;
                end
                try 
                    src.B1BinningHorizontal = num2str(binVal);
                    src.B2BinningVertical = num2str(binVal);
                catch
                    src.B1BinningHorizontal = num2str(bin,'%02i');
                    src.B2BinningVertical = num2str(bin,'%02i');
                end
            end
        elseif contains(obj.ConfigStruct.Adaptor, 'gentl')
            src.Gain = str2double(obj.ConfigStruct.Gain);
            src.AutoTargetBrightness = 5.019608e-01;
            if isfield(obj.ConfigStruct, 'Binning')
                if ~isnumeric(obj.ConfigStruct.Binning)
                    binVal = str2double(obj.ConfigStruct.Binning);
                else
                    binVal = obj.ConfigStruct.Binning;
                end
                src.BinningHorizontal = binVal;
                src.BinningVertical = binVal;
            end
        else
            %TODO fill out GENERIC CAMERAS
        end
        if isempty(obj.ConfigStruct.ROIPosition)
            vidRes = get(vidObj,'VideoResolution');
            obj.ConfigStruct.ROIPosition = num2str([0 0 vidRes]);
        end
        set(vidObj,'TriggerFrameDelay',obj.ConfigStruct.TriggerFrameDelay);
        set(vidObj,'FrameGrabInterval',obj.ConfigStruct.FrameGrabInterval);
        set(vidObj,'TriggerRepeat',obj.ConfigStruct.TriggerRepeat);
        set(vidObj,'ROIposition',str2num(obj.ConfigStruct.ROIPosition));
        set(vidObj,'FramesPerTrigger',str2double(obj.ConfigStruct.FramesPerTrigger));
        vidObj.FramesAcquiredFcnCount = obj.ConfigStruct.FrameGrabInterval;
        vidObj.FramesAcquiredFcn = @obj.ReceiveFrame;
        obj.SessionHandle = vidObj;
        obj.UpdateTriggerMode();
        obj.Status = "ok";
    end
end

% Start device
function StartTrial(obj)
    if isempty(obj.SessionHandle)
        return
    end
    if ~isrunning(obj.SessionHandle)
        start(obj.SessionHandle);
    end
    obj.FrameCount = 1;
    if strcmpi(obj.SessionHandle.TriggerMode,'immediate')
        trigger(obj.SessionHandle);
    end
    if ~isrunning(obj.SessionHandle)
        obj.Status = 'error';
    else
        obj.Status = 'ok';
    end
end

% Stop device
function Stop(obj)
    obj.StopPreview();
    if ~isempty(obj.SessionHandle) && isrunning(obj.SessionHandle)
        stop(obj.SessionHandle);
    end
end

% Start device preview
function StartPreview(obj)
    if isempty(obj.SessionHandle)
        error("Preview cannot be started if device is uninitialised.");
    end
    vidRes = get(obj.SessionHandle,'VideoResolution');
    nbands = get(obj.SessionHandle,'NumberOfBands');
    if ~isempty(obj.PreviewPlot)
        imshow(zeros(vidRes(2),vidRes(1),nbands),[],'parent',obj.PreviewPlot);
    else
        obj.PreviewPlot = imshow(zeros(vidRes(2),vidRes(1),nbands),[]);
    end
    preview(obj.SessionHandle, obj.PreviewPlot.Children);
    axis(obj.PreviewPlot, "tight");
    maxRange = floor(256*0.7); %limit intensity to 70% of dynamic range to avoid ceiling effects
    cMap = gray(maxRange); cMap(end+1:256,:) = repmat([1 0 0 ],256-maxRange,1);
    colormap(obj.PreviewPlot,cMap);

    if strcmpi(obj.ConfigStruct.TriggerMode, 'hardware')
        x = obj.PreviewPlot.XLim(2)/2;
        y = obj.PreviewPlot.YLim(2)/2;
        text(x,y, ['Preview not available', newline, 'in hardware trigger mode'], ...
            'Parent', obj.PreviewPlot, 'FontSize', 16, 'FontWeight','bold', ...
            'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', ...
            'Color', 'black');
    end
    obj.Previewing = true;
end

% Stop device preview
function StopPreview(obj)
    if isempty(obj.PreviewPlot) || isempty(obj.SessionHandle)
        return
    end
    if length(obj.PreviewPlot.Children) > 1
        % delete text object, if any
        delete(obj.PreviewPlot.Children(1));
    end
    stoppreview(obj.SessionHandle);
    closepreview(obj.SessionHandle);
    obj.Previewing = false;
end

% Change multiple device parameters at once.
function obj = SetParams(obj, paramsStruct)
    % todo account for abstract
    obj.Status = "loading";
    vidObj = obj.SessionHandle;
    src = getselectedsource(vidObj);
    paramFields = fields(paramsStruct);
    updateTrigger = false;
    updateBinning = false;
    % check if device needs to be restarted
    for i = 1:length(paramFields)
        param = paramFields{i};
        if ~obj.ComponentProperties.(param).dynamic
            previewPaused = true;
            obj.Stop();
        end
    end
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
            case "SavePath"
                obj.SavePath = val;
            case "Binning"
                continue
            case "BinningType"
                continue
            case "Gain"
                if ~isnumeric(val)
                    % assume it's a number
                    val = str2double(val);
                end
                src.Gain = val;
            case "ExposureTime"
                if ~isnumeric(val)
                    % assume it's a number
                    val = str2double(val);
                end
                src.ExposureTime = val;
            case "ROIPosition"
                if isempty(val)
                    % reset ROI
                    vidRes = get(obj.SessionHandle,'VideoResolution');
                    val = [0 0 vidRes];
                else
                    val = str2num(val);
                end
                    set(obj.SessionHandle, param, val);
            case "OutputLine"
                src.LineSelector = val;
                src.LineMode = "Output";
            case "TriggerLine"
                src.LineSelector = val;
                src.LineMode = "Input";
                src.TriggerSource = val;
            case "FramesPerTrigger"
                set(obj.SessionHandle, param, val);
            case "TriggerFrameDelay"
                set(obj.SessionHandle, param, val);
            case "FrameGrabInterval"
                set(obj.SessionHandle, param, val);
            case "TriggerRepeat"
                set(obj.SessionHandle, param, val);
            otherwise
                if contains(param, "Trigger") 
                    % TriggerActivation, TriggerMode, TriggerSelector
                    updateTrigger = true;
                elseif contains(param, "Binning")
                    updateBinning = true;
                end
        end
    end
    if updateTrigger
        obj.UpdateTriggerMode();
    end
    if updateBinning
        imaqreset;
        obj = obj.InitialiseSession();
    end
    if previewPaused
        obj.StartPreview();
    end
    obj.Status = "ok";
end

% Print device information
function PrintInfo(obj)
    obj.SessionHandle
end

function GetInspector(obj)
    inspect(obj.SessionHandle);
    inspect(obj.ConfigStruct);
end

function LoadTrialFromParams(obj, componentTrialData, genericTrialData)
    % TODO restart camera to reset framecount?
    % check triggermode and change if needed
    % detect number of triggers needed / framerate / etc.
end

function TakeSnapShot(obj, savePath)
    if isempty(obj.SessionHandle)
        disp('Snapshot not available. Check if camera is connected and restart.')
    else
        h = figure('Toolbar','none','Menubar','none','NumberTitle','off','Name','Snapshot'); %create figure to show snapshot
        snap = getsnapshot(obj.SessionHandle); %get snapshot from video object
        temp = ls(savePath); %check if earlier snapshots exist
        temp(1,8)=' '; % make sure temp has enough characters
        temp = temp(sum(ismember(temp(:,1:8),'Snapshot'),2)==8,:); %only keep snapshot filenames
        temp(~ismember(temp,'0123456789')) = ' '; %replace non-integer characters with blanks
        cNr = max(str2num(temp)); %get highest snapshot nr
        cNr(isempty(cNr)) = 0; %replace empty with 0 if no previous snapshot existed
        save([savePath 'Snapshot_' num2str(cNr+1) '.mat'],'snap') % snapshot
        imwrite(mat2gray(snap),[savePath 'Snapshot_' num2str(cNr+1) '.jpg']) %save snapshot as jpg
    
        %     imshow(snap,'XData',[0 1],'YData',[0 1]); colormap gray; axis image;
        imshow(snap); axis image; title(['Saved as Snapshot ' num2str(cNr+1)]);
        uicontrol('String','Close','Callback','close(gcf)','units','normalized','position',[0 0 0.15 0.07]); %close button
    end
end

end

%% Protected Methods
methods (Access = protected)
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
 
function componentID = GetComponentID(obj)
    componentID = convertStringsToChars([obj.ConfigStruct.Adaptor '-' obj.ConfigStruct.ID]); %TODO IS THIS UNIQUE ENOUGH
    if iscell(componentID)
        componentID = [componentID{:}];
    end
end

function ReceiveFrame(obj, src, vidObj)
    if ~exist(strcat(obj.SavePath, filesep, obj.ComponentID, obj.SavePrefix), 'dir')
        mkdir(obj.SavePath, obj.SavePrefix)
    end
    try
        imgs = getdata(src,src.FramesAvailable); 
        obj.LastAcquisition = tic;
        numImgs = size(imgs);
        numImgs = numImgs(4);
        for i = 1:numImgs
            imname = strcat(obj.SavePath, obj.SavePrefix, filesep, string(obj.FrameCount), '_', string(datetime(datetime, "Format", 'yyyyMMdd_HHmmss.SSS')), ".TIFF");
            imwrite(imgs(:,:,:,i),imname);
            obj.FrameCount = obj.FrameCount + 1;
        end
    catch exception
        disp("Encountered an error imaging on CameraComponent %s", obj.ComponentID)
        dbstack
        disp(exception.message)
    end
end

function UpdateTriggerMode(obj)
    src = getselectedsource(obj.SessionHandle);
    switch obj.ConfigStruct.TriggerMode
        case "hardware"
            obj.SessionHandle.FramesPerTrigger = str2double(obj.ConfigStruct.FramesPerTrigger);
            src.LineSelector = obj.ConfigStruct.TriggerLine;
            src.LineMode = "Input";
            src.TriggerSelector = obj.ConfigStruct.TriggerSelector;
            src.TriggerMode = "On";
            src.TriggerSource = obj.ConfigStruct.TriggerLine;
            src.TriggerActivation = obj.ConfigStruct.TriggerActivation;
        case "manual"
            src.TriggerSource = "Software";
            src.TriggerMode = "Off";
            obj.SessionHandle.FramesPerTrigger = str2double(obj.ConfigStruct.FramesPerTrigger);
            src.TriggerSelector = obj.ConfigStruct.TriggerSelector;
            % src.TriggerActivation = "none";
        case "immediate"
            src.LineSelector = obj.ConfigStruct.OutputLine;
            src.LineMode = "Output";
            src.TriggerMode = "Off";
            % src.TriggerActivation = "none";
    end
    triggerconfig(obj.SessionHandle, obj.ConfigStruct.TriggerMode);
    
end

% Gets current device status
% Options: ready / running / error
function status = GetSessionStatus(obj)
    if isrunning(obj.SessionHandle)
        status = 'ready';
        if toc(obj.LastAcquisition) < seconds(1)
            status = 'running';
        end
    elseif ~isempty(obj.Status)
        status = char(obj.Status);
    else
        status = '';
    end
end

function img = GetCurrentPreviewDisplay(obj)
    img = getimage(obj.PreviewPlot);
end

function SoftwareTrigger(obj, ~, ~)
%%TODO
end

end
end