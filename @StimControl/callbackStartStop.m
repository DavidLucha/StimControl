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
% https://au.mathworks.com/help/matlab/ref/parfeval.html
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
obj.d.experimentThread = parfeval(obj.taskPool, @testExperiment, 0, {obj, src, event});
disp("GREAT SUCCESS");
end

function testExperiment(obj, src, event)
disp("SECOND SUCCESS");
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
    obj.d.experimentThread = parfeval(obj.taskPool, @(obj, src)runTrial(obj, src), 0);
    obj.status = 'inter-trial';
    if i ~= nTrials
        pause(obj.g.dPause);
    end
end
end

function runTrial(obj, src)
    % runs a single trial
    obj.status = 'running';
    obj.callbackLoadTrial(obj, src, []);
    % Set save prefixes
    savePrefix = sprintf("%05d_stim%05d", obj.trialIdx, obj.trialNum);
    for ci = 1:sum(obj.d.Active)
        component = obj.activeComponents{ci};
        component.SavePrefix = savePrefix;
    end

    % Schedule component outputs
    % https://au.mathworks.com/matlabcentral/answers/322107-how-can-i-listen-for-completion-of-a-job
    nTasks = sum(obj.d.Active);
    futures = p.FevalFuture.empty(0, sum(nTasks)); % Preallocate array of Future objects
    for i = 1:sum(nTasks)
        component = obj.activeComponents{ci};
        futures(i) = parfeval(@component.Start, 1); % Schedule myFunction with 1 output
    end
    wait(futures);
    obj.trialIdx = obj.trialIdx + 1;

    % for ci = 1:sum(obj.d.Active)
    %     component = obj.d.activeComponents{ci};
    %     component.Start();
    % end
    % wait(obj.g.tPre + obj.g.tPost + obj.g.tTrial + 1);
    % NB NEED TO MANAGE NO TRIGGER CONDITION FOR INDIVIDUAL COMPONENTS
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