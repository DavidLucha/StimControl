function callbackStartStop(obj, src, event)
% Starts or stops an experiment. 
% enables or disables relevant GUI elements for interactivity
if obj.isRunning
    % Confirm stop experiment
    selection = uiconfirm(obj.h.fig, ...
        "Experiment is still running! Really stop?","Confirm Stop", ...
        "Icon","warning");
    if ~strcmpi(selection, "OK")
        return
    end
    for idx = 1:sum(obj.d.Active)
        component = obj.activeComponents{idx};
        component.Stop();
    end
    updateInteractivity(obj, 'on');
    if isfield(obj.d, 'experimentThread')
        cancel(obj.d.experimentThread);
    end
    if isfield(obj.d, 'trialThread')
        cancel(obj.d.trialThread)
    end
    obj.status = 'ready';
    return
end
%% START EXPERIMENT PROTOCOL
obj.status = 'loading';
updateInteractivity(obj, 'off');        % lock off unnecessary GUI elements
% make pool of parallel workers.
if isempty(obj.taskPool) || ~isvalid(obj.taskPool)
    if ~isempty(gcp('nocreate'))
        delete(gcp('nocreate'));
    end
    obj.taskPool = parpool;             % this takes a while to initialise.
end

obj.updateDateTime;                     % update datetime + savepath for each component
for i = 1:sum(obj.d.Active)
    component = obj.activeComponents{i};
    component.SavePath = obj.dirExperiment;
end

end

function runExperiment(obj, src, event)
nTrials = length(obj.p);
if obj.g.randomize
    trialNums = randperm(nTrials);
else
    trialNums = 1:nTrials;
end

for i = 1:nTrials
    obj.trialNum = trialNums(i);
    obj.runTrial(src); % spawns an execution timer
    wait(obj.d.executionTimer);
    delete(obj.d.executionTimer);
    obj.status = 'inter-trial';
    if i ~= nTrials
        wait(obj.d.interTrialTimer);
        pause(obj.g.dPause);
    end
end
end

function interTrialTimerStart(obj, ~, ~)

end

function interTrialTimer(obj, ~, ~)
    
end


function updateInteractivity(obj, state)
    allUI = findobj(obj.h.Session.Tab);
    for ii = 1:length(allUI)
        uiObj = allUI(ii);
        if contains(class(uiObj), 'matlab.ui.control') ...
                && uiObj ~= obj.h.menuDebug ...
                && isprop(uiObj, "Enable") ...
                && ~contains(class(uiObj), 'Lamp') ...
                && ~contains(class(uiObj), 'Label')
            uiObj.Enable = state;
        end
    end
end