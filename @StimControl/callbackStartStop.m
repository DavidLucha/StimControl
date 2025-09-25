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
        stop(obj.d.executionTimer);
        component = obj.activeComponents{idx};
        component.Stop();
    end
    updateInteractivity(obj, 'on');
    % if isfield(obj.d, 'experimentThread')
    %     cancel(obj.d.experimentThread);
    % end
    % if isfield(obj.d, 'trialThread')
    %     cancel(obj.d.trialThread)
    % end
    obj.status = 'ready';
    return
end
%% START EXPERIMENT PROTOCOL
obj.status = 'loading';
updateInteractivity(obj, 'off');        % lock off unnecessary GUI elements

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

% refresh information scroller
obj.h.trialInformationScroller.Value = '';

for i = 1:nTrials
    obj.trialNum = trialNums(i);
    obj.runTrial(src); % spawns an execution timer
    wait(obj.d.executionTimer);
    delete(obj.d.executionTimer);
    if i ~= nTrials
        obj.status = 'inter-trial';
        obj.d.interTrialTimer = timer(...
            'StartDelay',       0, ...
            'Period',           1, ...
            'ExecutionMode',    'fixedRate', ...
            'TimerFcn',         @interTrialTimerFcn);
        start(obj.d.interTrialTimer);
        wait(obj.d.interTrialTimer);
        delete(obj.d.interTrialTimer)
    end
end
end

function interTrialTimerFcn(obj, ~, ~)
    persistent secsLeft;
    if isempty(secsLeft)
        secsLeft = obj.g.dPause;
    elseif secsLeft == 0
        obj.h.StatusCountdownLabel.Text = "-0:00";
        stop(obj.d.interTrialTimer);
        return;
    elseif ~strcmpi(obj.Status, 'paused')
       secsLeft = secsLeft - 1;
    end
    if ~strcmpi(obj.Status, 'paused')
        % update GUI
        minsLeft = floor(secsLeft / 60);
        displaySecsLeft = secsLeft - minsLeft*60;
        obj.h.StatusCountdownLabel.Text = sprintf("-%d:%2d", minsLeft, displaySecsLeft);
    end
end

function updateInteractivity(obj, state)
    allUI = findobj(obj.h.Session.Tab);
    for ii = 1:length(allUI)
        uiObj = allUI(ii);
        if contains(class(uiObj), 'matlab.ui.control') ...
                && uiObj ~= obj.h.menuDebug ...
                && isprop(uiObj, "Enable") ...
                && ~contains(class(uiObj), 'Lamp') ...
                && ~contains(class(uiObj), 'Label') ...
                && uiObj ~= obj.h.trialInformationScroller
            uiObj.Enable = state;
        end
    end
end