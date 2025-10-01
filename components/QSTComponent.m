classdef (Abstract, HandleCompatible) QSTComponent < HardwareComponent
% Component for the QST device
% % poll batteries
%         for ii=1:obj.nThermodes
%             obj.h.(['Thermode' char(64+ii)]).battery.Value = obj.s(ii).battery;
%         end

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
function obj = QSTComponent(varargin)
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