classdef (HandleCompatible) Component < HardwareComponent
% Abstract class representing all hardware components
properties(Abstract, Constant, Access = public)
    ComponentProperties
end

properties (Access = public)
    Name
    SessionHandle
    SavePath
    SavePrefix
    Abstract
    ConfigStruct
    PreviewPlot = []
    Previewing = false
    ComponentID
    TriggerTimer = [];
end

methods(Access=public)
% Constructor that sets generic values for the class
function obj = SerialComponent(varargin)
    p = obj.GetBaseParser();
    parse(p, varargin{:});
    params = p.Results;
    obj = obj.CommonInitialisation(params);
    if params.Initialise && ~params.Abstract
        obj = obj.InitialiseSession('ConfigStruct', params.ConfigStruct);
    end
end

% Initialise the hardware session. 
function obj = InitialiseSession(obj, params)
    obj.ConfigStruct = obj.GetConfigStruct(params.ConfigStruct);
    if all(~params.ComponentID)
        obj.ComponentID = obj.GetComponentID;
    else
        obj.ComponentID = params.ComponentID;
    end
end


function SaveAuxiliaryConfig(obj, filepath)
    return;
end

% Start device. For synchronisation reasons, should only be used for
% self-triggered devices and 
function StartTrial(obj)

end

% Stop device
function Stop(obj)

end

% Change device parameters
function SetParams(obj, varargin)

end

% Dynamic visualisation of the object output
function StartPreview(obj)

end

% Dynamic visualisation of the object output
function StopPreview(obj)

end

% Print device information
function PrintInfo(obj)

end

% Preload a single trial
function LoadTrialFromParams(obj, componentTrialData, genericTrialData)

end
end

methods(Access=protected)

% gets current device status
% Options: ready / running / error
function status = GetSessionStatus(obj)

end

function componentID = GetComponentID(obj)

end

function SoftwareTrigger(obj, ~, ~)

end

end

methods(Static, Access=public)
    % Complete reset. Clear device and all handles of device type.
    Clear()
end
end

% Configure device
function Initialise(obj, varargin)
    %TODO STOP/START
    p = inputParser;
    addParameter(p, 'ConfigStruct', []);
    parse(p, varargin{:});
    params = p.Results;

    %---device---
    if isempty(obj.SessionHandle) || ~isempty(params.ConfigStruct)
        % if the component is uninitialised or the params have changed
        configStruct = obj.GetConfigStruct(params.ConfigStruct);

        obj.SessionHandle = daq(name);
        obj.SessionHandle.Rate = rate;
    end
    
    %---display---
    if ~isempty(obj.SessionHandle)
        obj.PrintInfo();
    end
    
end

% Start device
function Start(obj)

end

%Stop device
function Stop(obj)

end

% Complete reset. Clear device
function Clear(obj)

end

% Pause device
function Pause(obj)

end

% Unpause device
function Continue(obj)

end

% Change device parameters
function SetParams(obj, varargin)

end

% get current device parameters for saving
function objStruct = GetParams(obj)
    
end

% gets current device status
function status = GetStatus(obj)
    if obj.Status == "error" || obj.Status == "loading"
        status = obj.Status;
    elseif isempty(obj.SessionHandle)
        status = "empty";
    elseif isrunning(obj.SessionHandle)
        status = "ready";
        if toc(obj.LastAcquisition) > seconds(1)
            status = "running";
        end
    else
        status = "ok";
    end

end


function StartPreview(obj, varargin)
    if isempty(obj.SessionHandle)
        return;
    end
    if ~isempty(obj.PreviewPlot)
        %target plot
    else
        %target generic and save as PreviewPlot
        return
    end
end

function StopPreview(obj, varargin)
    if isempty(obj.SessionHandle)
        return;
    end
    if isempty(obj.PreviewPlot)
        % SOMETHING IS WRONG YOU SHOULDN'T BE HERE
    else
        % end preview
        return
    end
end

% Print device information
function PrintInfo(obj)
    disp(' ')
    disp(obj.SessionHandle)
    disp(' ')
end

function LoadProtocol(obj, varargin)

end

function defaults = GetDefaultComponentStruct(obj)
   defaults = GetDefaultComponentStruct@HardwareComponent(obj);
end


end