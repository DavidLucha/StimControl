classdef (Abstract, HandleCompatible) HardwareComponent < handle
%Abstract class representing all hardware components
properties(Abstract, Constant, Access = public)
    ComponentProperties
end

properties (Access = public)
    Name
    SessionHandle
    SavePath
    Required
    Abstract
    ConfigStruct
    PreviewPlot = []
    Previewing = false
    ComponentID
end

properties (Abstract, Access = protected)
    HandleClass
end

methods(Access=public)
% All device constructors can take the following arguments, 
% as well as device-specific arguments:
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
function p = GetBaseParser(obj)
    p = inputParser;
    strValidate = @(x) ischar(x) || isstring(x);
    handleValidate = @(x) (contains(class(x), obj.HandleClass)) || isempty(x);
    addParameter(p, 'Required', true, @islogical);
    addParameter(p, 'Handle', [], handleValidate);
    addParameter(p, 'ConfigStruct', []);
    addParameter(p, 'SavePath', '', strValidate);
    addParameter(p, 'Abstract', false, @islogical);
    addParameter(p, 'Initialise', true, @islogical);
    addParameter(p, 'ComponentID', false, @(x) ischar(x) || isstring(x) || islogical(x));
end

function obj = Initialise(obj, params)
    obj.SavePath = params.SavePath;
    obj.Required = params.Required;
    obj.SessionHandle = params.Handle;
    obj.Abstract = params.Abstract;
    obj.ConfigStruct = obj.GetConfigStruct(params.ConfigStruct);
    if all(~params.ComponentID)
        obj.ComponentID = obj.GetComponentID;
    else
        obj.ComponentID = params.ComponentID;
    end
end

function configStruct = GetDefaultConfigStruct(obj)
    configStruct = struct();
    fs = fields(obj.ComponentProperties);
    for i = 1:length(fs)
        attr = getfield(obj.ComponentProperties, fs{i});
        d = {attr.default};
        configStruct = setfield(configStruct, fs{i}, d{1});
    end
end

function configStruct = GetConfigStruct(obj, varargin)
    %Fill out a config struct with existing or default values.
    default = obj.GetDefaultConfigStruct();
    if isempty(varargin) || isempty(varargin{1})
        if isempty(obj.ConfigStruct)
            warning("No %s config provided. Using default setup", class(obj));
            configStruct = default; 
        else
            configStruct = obj.ConfigStruct;
        end
    else
        configStruct = varargin{1};
    end
    % fill in required fields with defaults.
    props = obj.ComponentProperties;
    propFields = fields(props);
    for i = 1:length(propFields)
        f = propFields{i};
        if ~isfield(configStruct, f) %TODO & field is needed?
            if isfield(obj.ConfigStruct, f)
                % if the property is already defined by the object, use that value
                val = obj.ConfigStruct.(f);
            else
                % else, use default value
                val = props.(f).default;
            end
            configStruct = setfield(configStruct, f, val);
        end
    end
end

function status = GetStatus(obj)
% Gets current device status
% Options: abstract / empty / ready / running / error /  / loading
    sessionStatus = obj.GetSessionStatus();
    if obj.Abstract
        status = 'abstract';
    elseif isempty(obj.SessionHandle)
        status = 'empty';
    elseif strcmpi(obj.Status, 'loading')
        status = 'loading';
    elseif(strcmpi(obj.Status, 'error'))
        status = 'error';
    elseif ~isempty(sessionStatus)
        status = sessionStatus;
    else
        status = 'unknown';
    end
end

% Updates the preview to move its target plot.
function UpdatePreview(obj, varargin)
    p = inputParser;
    addOptional(p, 'newPlot', []);
    parse(p, varargin{:});
    newPlot = p.Results.newPlot;
    restart = obj.Previewing;

    obj.StopPreview();
    if ~isempty(newPlot)
        obj.PreviewPlot = newPlot;
    end
    if restart
        obj.StartPreview();
    end
end

function obj = SetParam(obj, param, val)
    if ~isfield(obj.ComponentProperties, param)
        error("Invalid field: %s", param);
    elseif ~obj.ComponentProperties.(param).isValid(val)
        error("Invalid value for parameter %s", param);
    elseif ~obj.ComponentProperties.(param).dynamic
        warning("Changing param %s requires device restart. Restarting device...", param);
    else
        paramStruct = struct(param, val);
        obj.SetParams(paramStruct);
    end
end

% Save any additional device parameters to given savepath
function SaveAuxiliaries(obj, filepath)
    return;
end

% get current device parameters for saving
function objStruct = GetParams(obj)
    objStruct = setfield(obj.ConfigStruct, 'ComponentID', obj.ComponentID);
end
end

methods (Abstract, Access=public)
% Initialise hardware session. Accepts one arg to varargin - 'ConfigStruct'
InitialiseSession(obj, varargin)

% Start device
Start(obj)

% Stop device
Stop(obj)

% Complete reset. Clear device
Clear(obj)

% Change device parameters
SetParams(obj, varargin)

% Dynamic visualisation of the object output
StartPreview(obj)

% Dynamic visualisation of the object output
StopPreview(obj)

% Print device information
PrintInfo(obj)

% Preload an experimental protocol
LoadProtocol(obj, varargin)
end

methods(Abstract, Access=protected)

% gets current device status
% Options: ready / running / error
status = GetSessionStatus(obj)

componentID = GetComponentID(obj)

end
end