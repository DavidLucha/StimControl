classdef (Abstract, HandleCompatible) HardwareComponent
%Abstract class representing all hardware components
properties (Access = public)
    Name
    SessionHandle
    SavePath
    Required
    Abstract
    ConfigStruct
end

properties(Abstract, Constant, Access = public)
    ComponentProperties
end

properties (Abstract, Access = protected)
    HandleClass
end

methods(Access=public)
% All device constructors can take the following arguments, 
% as well as device-specific arguments:
% 'Required'    (logical, true)     whether to throw errors as errors or warnings
% 'Handle'      (handle, [])        the handle to an existing session of that component type
% 'Struct'      (struct, [])        struct containing initialisation params - see
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
    addParameter(p, 'Struct', []);
    addParameter(p, 'SavePath', '', strValidate);
    addParameter(p, 'Abstract', false, @islogical);
    addParameter(p, 'Initialise', true, @islogical);
end

function obj = CommonInitialisation(obj, params)
    obj.SavePath = params.SavePath;
    obj.Required = params.Required;
    obj.SessionHandle = params.Handle;
    obj.Abstract = params.Abstract;
end

function componentStruct = GetDefaultConfigStruct(obj)
    componentStruct = struct();
    fs = fields(obj.ComponentProperties);
    for i = 1:length(fs)
        attr = getfield(obj.ComponentProperties, fs{i});
        d = {attr.default};
        componentStruct = setfield(componentStruct, fs{i}, d{1});
    end
end

function configStruct = GetConfigStruct(obj, varargin)
    %Fill out a config struct with existing or default values.
    default = obj.GetDefaultConfigStruct();
    if isempty(varargin)
        if isempty(obj.ConfigStruct)
            warning("No %s config provided. Using default setup", class(obj));
            configStruct = default;
        else
            configStruct = obj.ConfigStruct;
        end
    else
        configStruct = varargin{1};
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
end

function status = GetStatus(obj)
    if obj.Abstract
        status = "Abstract";
    elseif isempty(obj.SessionHandle)
        status = "Not Initialised";
    else
        status = obj.GetSessionStatus();
    end
end
end

methods (Abstract, Access=public)
% Initialise hardware session
Configure(obj, varargin)

% Start device
Start(obj)

% Stop device
Stop(obj)

% Complete reset. Clear device
Clear(obj)

% Change device parameters
SetParams(obj, varargin)

% get current device parameters for saving
objStruct = GetParams(obj)

% gets current device status
% Options: ok / ready / running / error / loading
status = GetSessionStatus(obj)

% Dynamic visualisation ofthe object output. Can target a specific
% plot using the "Plot" param.
VisualiseOutput(obj, varargin)

% Print device information
PrintInfo(obj)

% Preload an experimental protocol
LoadProtocol(obj, varargin)
end
end