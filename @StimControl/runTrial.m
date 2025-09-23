function runTrial(obj, src)
    % runs a single trial. Assumes trial data is pre-loaded for each component.
    % use obj.callbackLoadTrial to make this a reality!

    obj.status = 'running';
    
    % update information scroller
    comment = '';
    if isfield(obj.p, 'Comments')
        comment = obj.p(obj.trialNum).Comments;
    end
    obj.h.trialInformationScroller.Value = [obj.h.trialInformationScroller.Value, ...
        newline, char(sprintf("%d(%d): %s", obj.trialIdx, obj.trialNum, comment))];

    % Set save prefixes
    if src == obj.h.StartStopBtn
        savePrefix = sprintf("%05d_stim%05d", obj.trialIdx, obj.trialNum);
    end %TODO elseif single stim add an additional identifier to the prefix
    for ci = 1:sum(obj.d.Active)
        component = obj.activeComponents{ci};
        component.SavePrefix = savePrefix;
    end

    nTasks = sum(obj.d.Active);
    activeComponents = obj.activeComponents;
    for ci = 1:sum(nTasks)
        component = activeComponents{ci};
        component.StartTrial;
    end
    obj.trialIdx = obj.trialIdx + 1;

    obj.d.executionTimer = timer(...
            'StartDelay',       0, ...
            'Period',           1, ...
            'ExecutionMode',    'fixedRate', ...
            'TimerFcn',         @trialRun, ...
            'StopFcn',          @trialStop, ...
            'UserData',         src == obj.h.StartStopBtn);
    obj.status = 'running';
    start(obj.d.executionTimer);
end

function trialRun(obj, ~, ~)
    persistent startSec;
    persistent trialSecs;
    persistent experimentStartSecs;
    persistent experimentTotalSecs;
    if isempty(trialSecs)
        totalTimeLabel = strip(split(obj.h.trialTimeEstimate.Text, '/'));
        trialSecs = seconds(duration(totalTimeLabel{2}, 'Format', 'mm:ss'));
        startSec = tic;
        experimentTimeLabel = strip(split(obj.h.protocolTimeEstimate.Text, '/'));
        experimentTotalSecs = seconds(duration(experimentTimeLabel{2}));
        experimentStartSecs = seconds(duration(experimentTimeLabel{1}));
    end
    if ~any(cellfun(@(c) strcmpi(c.GetStatus(), 'running'), obj.activeComponents))
        % all components finished
        obj.state = 'inter-trial';
        stop(obj.d.executionTimer)
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

function trialStop(obj, ~, ~)
    obj.status = 'loading';
    for i = 1:length(obj.activeComponents)
        component = obj.activeComponents{i};
        component.Stop();
    end
end
