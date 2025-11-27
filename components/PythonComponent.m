classdef PythonComponent
    %PythonComponent - call devices through HardwareComponent files written
    % in python.
    %   See https://au.mathworks.com/help/matlab/matlab_external/create-object-from-python-class.html
    %     and https://au.mathworks.com/help/matlab/matlab_external/call-user-defined-custom-module.html
    %     https://au.mathworks.com/help/matlab/matlab_external/passing-data-to-python.html
    %     for guides on how to implement - remember to add python and
    %     module to matlab path!!

properties(Constant, Access = public)
    ComponentProperties
end

properties (Access = public)
    Name
    SessionHandle
    SavePath
    TrialPrefix
    Abstract
    ConfigStruct
    PreviewPlot = []
    Previewing = false
    statusPanel = [];
    ComponentID
    TriggerTimer = [];
    ConnectedDevices = [];
end

properties(Access=public, Dependent)
    SavePrefix
end

properties(Access=protected)
    statusHandles = [];
end

methods(Static, Access=public)

function ClearAll()
    % Complete reset. Clear device and all handles of device type.
end

function components = FindAll(varargin)
    % Finds all available hardware components of the given type.
end
end

methods(Access=public)

function obj = PythonComponen(varargin)
    p = obj.GetBaseParser();
    parse(p, varargin{:});
    params = p.Results;
    obj = obj.CommonInitialisation(params);
    if params.Initialise && ~params.Abstract
        obj = obj.InitialiseSession('ConfigStruct', params.ConfigStruct);
    end
end

function TrialMaintain(obj)
    % for components that may need to load additional data during a trial 
    % (e.g. serial components). By default, does nothing. 
end

function EndTrial(obj)
    % for components that may need additional data saved after a trial ends
    % - e.g. cameras that only write to file every 10 frames.
end

function UpdateSavePath(obj)
    % Updates the component's savepath. Does nothing 
    % unless the component saves to a sub-folder within the experiment;
    % in that case make the subfolder. See CameraComponent
end

function InitialiseSession(obj, varargin)
    % Initialise hardware session. By default, accepts two args:
    % 'ConfigStruct'        (struct)    a struct of all device settings you want set
    % 'KeepHardwareConfig'  (logical)   [TODO, LOGIC NOT IMPLEMENTED] determines behaviour for attributes 
    %                                   not explicitly set with ConfigStruct.
    %                                   If false, enforces default settings for
    %                                   hardware configuration. If true,
    %                                   retains the hardware's existing
    %                                   settings
end

function StartTrial(obj)
    % Start device. Start the trigger device last.
end

function Stop(obj)
    % Stop device during trial and flush any remaining data.
end

function SetParams(obj, varargin)
    % Change device parameters
end

function StartPreview(obj)
    % Dynamic visualisation of the object output
end

function StopPreview(obj)
    % Dynamic visualisation of the object output
end

function PrintInfo(obj)
    % Print device information
end

function LoadTrialFromParams(obj, componentTrialData, genericTrialData, preloadDevice)
    % Preload a single trial
end

function Close(obj)
    % Close connection to the hardware session
end
end

methods(Access=protected)

% gets current device status
function status = GetSessionStatus(obj)
    % Options: ready / running / error
end
function componentID = GetComponentID(obj)

end
function SoftwareTrigger(obj, ~, ~)

end

end
end