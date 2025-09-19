function runTrial(obj, src)
    % runs a single trial. Assumes trial dat is pre-loaded for each component.
    % use obj.callbackLoadTrial to make this a reality!

    obj.status = 'running';
    % Set save prefixes
    if src == obj.h.StartStopBtn
        savePrefix = sprintf("%05d_stim%05d", obj.trialIdx, obj.trialNum);
    end %TODO elseif single stim add an additional thing to the prefix
    for ci = 1:sum(obj.d.Active)
        component = obj.activeComponents{ci};
        component.SavePrefix = savePrefix;
    end

    nTasks = sum(obj.d.Active);
    activeComponents = obj.activeComponents;
    for ci = 1:sum(nTasks)
        component = activeComponents{ci};
        component.Start;
    end
    obj.trialIdx = obj.trialIdx + 1;

    obj.d.executionTimer = timer(...
            'StartDelay',       0, ...
            'Period',           300, ...
            'ExecutionMode',    'fixedRate', ...
            'StartFcn',         @trialStart, ...
            'TimerFcn',         @trialRun, ...
            'StopFcn',          @trialStop);
    start(obj.d.executionTimer);
end

function trialRun(obj, ~, ~)
    obj.status = 'running';
    if ~any(cellfun(@(c) strcmpi(c.GetStatus(), 'running'), obj.activeComponents))
        % all components finished
        obj.state = 'inter-trial';
        stop(obj.d.executionTimer)
    end
end

function trialStop(obj, ~, ~)
    obj.status = 'loading';
    for i = 1:length(obj.activeComponents)
        component = obj.activeComponents{i};
        component.Stop();
    end
end
