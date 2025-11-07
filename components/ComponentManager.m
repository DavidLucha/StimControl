classdef ComponentManager < handle
%UNTITLED Summary of this class goes here
%   Detailed explanation goes here

properties
    Available
    Active
    ProtocolIDMap
    IDComponentMap

    ActiveIDs
    componentTargets
end

properties(Dependent)
    activeComponents
    nAvailable
    nActive
end

methods
    function obj = ComponentManager()
    end

    function obj = FindAvailableHardware(obj)
        %% Find available hardware
        obj.Available = {};
        obj.Active = [];
        obj.IDComponentMap = configureDictionary('string', 'uint32');
        obj.ProtocolIDMap = configureDictionary('string', 'uint32');
        
        tmpPlur = ["", "s"];
        pluralStr = @(input) tmpPlur(double(length(input)~=1)+1);
        daqs = DAQComponent.FindAll();
        fprintf("\t Found %d DAQ%s\n", length(daqs), pluralStr(daqs));
        cameras = CameraComponent.FindAll();
        fprintf("\t Found %d camera%s\n", length(cameras), pluralStr(cameras));
        serials = SerialComponent.FindAll();
        fprintf("\t found %d serial device%s\n", length(serials), pluralStr(serials));
        components = [cameras serials daqs]; %daqs on the end because they're activated together too
    
        for ci = 1:length(components)
            comp = components{ci};
            obj.IDComponentMap(comp.ComponentID) = ci;
            obj.ProtocolIDMap(comp.ConfigStruct.ProtocolID) = ci;
            obj.Available{end+1} = comp;
            obj.Active(end+1) = true;
        end
    end

    function StartPreviews(obj)
        for i = 1:length(obj.Available)
            obj.Available{i}.StartPreview();
        end
    end

    function CloseAll(obj)
        if ~isempty(obj.Available)
            for i = 1:obj.nAvailable
                comp = obj.Available{i};
                comp.Close();
            end
        end
    end

    function ClearAll(obj)
        obj.CloseAll();
        CameraComponent.ClearAll();
        SerialComponent.ClearAll();
        DAQComponent.ClearAll();
    end

    function activeComponents = get.activeComponents(obj)
        activeComponents = obj.Available(obj.Active == 1);
    end

    function out = get.nAvailable(obj)
        out = length(obj.Available);
    end

    function out = get.nActive(obj)
        out = sum(obj.Active);
    end
end
end