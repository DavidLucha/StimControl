function callbackStartStop(obj, src, event)
% Starts or stops an experiment. 
% enables or disables relevant GUI elements for interactivity
if strcmpi(obj.status, 'running') || strcmpi(obj.status, 'paused') ...
    || strcmpi(obj.status, 'inter-trial') || strcmpi(obj.status, 'awaiting trigger')
    % Confirm stop experiment
    selection = uiconfirm(obj.h.fig, ...
        "Experiment is still running! Really stop?","Confirm Stop", ...
        "Icon","warning");
    if ~strcmpi(selection, "OK")
        return
    end
    obj.f.stopTrial = true;
elseif src == obj.h.StartStopBtn || src == obj.h.StartSingleTrialBtn
    
    if src == obj.h.StartStopBtn
        obj.f.runningExperiment = true;
    end
    for i = 1:obj.d.nActive
        component = obj.d.activeComponents{i};
        component.LoadTrial([]);
    end
    obj.f.startTrial = true;

elseif src == obj.h.StartPassiveBtn
    obj.f.passive = true;
    for i = 1:obj.d.nActive
        component = obj.d.activeComponents{i};
        component.SavePath = [obj.dirExperiment '_passive'];
    end
end
end