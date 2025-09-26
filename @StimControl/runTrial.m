function runTrial(obj, src, event)
    % runs a single trial. Assumes trial data is pre-loaded for each component.
    % use obj.callbackLoadTrial to make this a reality!

    obj.status = 'running';
    
    % update information scroller
    comment = '';
    if isfield(obj.p, 'Comments')
        comment = obj.p(obj.trialNum).Comments;
    end
    obj.h.trialInformationScroller.Value{end+1} = ...
        char(sprintf("%d(%d): %s", obj.trialIdx, obj.trialNum, comment));

    % Set save prefixes
    if src == obj.h.StartStopBtn
        savePrefix = sprintf("%05d_stim%05d", obj.trialIdx, obj.trialNum);
    end %TODO elseif single stim add an additional identifier to the prefix
    for ci = 1:sum(obj.d.Active)
        component = obj.activeComponents{ci};
        component.SavePrefix = savePrefix;
    end

    % nTasks = sum(obj.d.Active);
    % activeComponents = obj.activeComponents;
    % for ci = 1:sum(nTasks)
    %     component = activeComponents{ci};
    %     component.StartTrial;
    % end
    obj.trialIdx = obj.trialIdx + 1;
    % disp("STARTED")
    tPre = [obj.p.tPre];
    tPost = [obj.p.tPost];
    tTotal = tPre(obj.trialNum) + tPost(obj.trialNum);

    obj.d.executionTimer = timer(...
            'StartDelay',       0, ...
            'Period',           1, ...
            'ExecutionMode',    'fixedRate', ...
            'TimerFcn',         @(timer, event)trialRun(timer, event, obj), ...
            'StopFcn',          @(timer, event)trialStop(timer, event, obj), ...
            'UserData',         src == obj.h.StartStopBtn, ...
            'TasksToExecute',   round(tTotal / 100),...
            'Name',             'executionTimer');
    obj.status = 'running';
    start(obj.d.executionTimer);
    
    if src ~= obj.h.StartStopBtn
        wait(obj.d.executionTimer);
        obj.status = 'ready';
    end
end

function trialRun(timer, event, obj)
    persistent startSec;
    persistent trialSecs;
    persistent experimentStartSecs;
    persistent experimentTotalSecs;
    if isempty(trialSecs) || startSec == 0
        % initialise variables
        totalTimeLabel = strip(split(obj.h.trialTimeEstimate.Text, '/'));
        trialSecs = seconds(duration(totalTimeLabel{2}, 'InputFormat', 'mm:ss'));
        experimentTimeLabel = strip(split(obj.h.protocolTimeEstimate.Text, '/'));
        experimentTotalSecs = seconds(duration(experimentTimeLabel{2}, 'InputFormat', 'mm:ss'));
        experimentStartSecs = seconds(duration(experimentTimeLabel{1}, 'InputFormat', 'mm:ss'));
        % start trial
        for ci = 1:sum(obj.d.Active)
            component = obj.activeComponents{ci};
            component.StartTrial;
        end
        startSec = tic;
    end
    if ~any(cellfun(@(c) strcmpi(c.GetStatus(), 'running'), obj.activeComponents))
        % all components finished
        obj.status = 'inter-trial';
        stop(obj.d.executionTimer)
        startSec = 0;
    else
        secsElapsed = toc(startSec);
        % update GUI
        obj.h.StatusCountdownLabel.Text = sprintf("-%s / %s",  ...
            string(duration(seconds(trialSecs-secsElapsed), 'Format', 'mm:ss')), ...
            string(duration(seconds(trialSecs), 'Format', 'mm:ss')));
        obj.h.trialTimeEstimate.Text = sprintf("%s / %s",  ...
            string(duration(seconds(secsElapsed), 'Format', 'mm:ss')), ...
            string(duration(seconds(trialSecs), 'Format', 'mm:ss')));
        if obj.d.executionTimer.UserData
            % called from full experiment - update full experiment timer.
            obj.h.protocolTimeEstimate.Text = sprintf("%s / %s",  ...
            string(duration(seconds(experimentStartSecs+secsElapsed), 'Format', 'mm:ss')), ...
            string(duration(seconds(experimentTotalSecs), 'Format', 'mm:ss')));
        end
    end
end

function trialStop(timer, event, obj)
    for i = 1:length(obj.activeComponents)
        component = obj.activeComponents{i};
        component.Stop();
    end
end
