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
elseif src == obj.h.StartStopBtn
    obj.f.runningExperiment = true;
    obj.f.startTrial = true;

elseif src == obj.h.StartPassiveBtn
    obj.f.passive = true;

elseif src == obj.h.StartSingleTrialBtn
    obj.f.startTrial = true;
end
end