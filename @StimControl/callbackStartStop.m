function callbackStartStop(obj, src, event)
% Starts or stops an experiment. 
% enables or disables relevant GUI elements for interactivity
if obj.isRunning
    % Confirm stop experiment
    selection = uiconfirm(fig, ...
        "Experiment is still running! Really stop?","Confirm Stop", ...
        "Icon","warning");
    if ~strcmpi(selection, "OK")
        return
    end
    for idx = 1:sum(obj.d.Active)
        component = obj.activeComponents{idx};
        component.Stop();
    end
    obj.status = 'ready';
    return
end

runExperiment(obj);
end

function runExperiment(obj)
    obj.trialIdx = 1;
    obj.activeComponents;
end