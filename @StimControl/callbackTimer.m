function callbackTimer(obj,~,~)
% hardware status updates in a timer
persistent trialNums;
persistent nTrials;
persistent startTic;
persistent previousStatus;
persistent pauseOffset;
if isempty(startTic)
    startTic = tic;
end

if strcmpi(obj.h.tabs.SelectedTab.Title, 'Setup')
    % update GUI in setup tab
    for i = 1:height(obj.h.AvailableHardwareTable)
        component = obj.d.Available{i};
        obj.h.AvailableHardwareTable.Data.Status{i} = component.GetStatus;
    end
else
    if isempty(previousStatus)
        previousStatus = obj.status;
    end
    if ~strcmpi(previousStatus, obj.status)
        disp(obj.status);
        previousStatus = obj.status;
    end
    % state handling
    try
        switch obj.status
            case 'not initialised'
                % do nothing
            case 'ready'
                if obj.f.startTrial
                    % start the trial
                    startTic = tic;
                    if obj.f.runningExperiment
                        trialNums = buildTrialSequence(obj);
                        nTrials = length(trialNums);
                        if trialNums(nTrials) ~= obj.trialNum
                            obj.trialNum = trialNums(1);
                            obj.callbackLoadTrial([]);
                        end
                    else
                        trialNums = [obj.trialNum];
                        nTrials = 1;
                    end
                    obj.trialIdx = 1;
                    updateGUITimers(obj, startTic, true);
                    startTrial(obj);
                    obj.f.startTrial = false;
                    obj.status = 'running';
                end
            case 'stopping'
                % stop the trial (interrupt)
                obj.f.stopTrial = false;
                obj.f.startTrial = false;
                for idx = 1:sum(obj.d.Active)
                    component = obj.activeComponents{idx};
                    component.Stop();
                end
                obj.h.StatusCountdownLabel.Text = '-0:00';
                updateGUITimers(obj, tic, true);
                updateInteractivity(obj, 'on');
                obj.status = 'ready';
            case 'running'
                if obj.f.stopTrial
                    obj.status = 'stopping';
                elseif obj.f.trialFinished
                    % trial completed.
                    obj.f.trialFinished = false;
                    if obj.trialIdx == nTrials
                        obj.status = 'ready';
                        obj.f.runningExperiment = false;
                    else
                        obj.trialIdx = obj.trialIdx + 1;
                        startTic = tic;
                        obj.status = 'inter-trial';
                        pauseOffset = 0;
                        obj.h.StatusCountdownLabel.Text = strcat('-', string(duration(seconds(obj.g.dPause)), 'mm:ss'));
                        updateGUITimers(obj, startTic, true);
                        obj.callbackLoadTrial([]); % load next trial
                    end
                else
                    % monitor trial
                    updateGUITimers(obj, startTic, false);
                    if ~any(cellfun(@(c) strcmpi(c.GetStatus(), 'running'), obj.activeComponents))
                        obj.f.trialFinished = true;
                    end
                end
            case 'inter-trial'
                if obj.f.pause
                    % pause inter-trial timer
                    pauseOffset = obj.g.dPause - (toc(startTic) + pauseOffset);
                    obj.status = 'paused';
                    obj.f.pause = false;
                    obj.f.resume = false;
                elseif obj.f.stopTrial
                    obj.status = 'stopping';
                else
                    %update GUI
                    updateGUITimers(obj, startTic, false);
                    if toc(startTic) >= obj.g.dPause - pauseOffset
                        startTic = tic;
                        startTrial(obj);
                        obj.status = 'running';
                    end
                end
            case 'paused'
                if obj.f.resume
                    % resume inter-trial timer
                    obj.f.resume = false;
                    startTic = tic;
                    updateGUITimers(obj, startTic, true);
                    obj.status = 'inter-trial';
                elseif obj.f.stopTrial
                    obj.status = 'stopping';
                end
            case 'error'
        end
    % catch errors during protocol execution
    catch err
        fid = fopen(fullfile(obj.path.dirData, filesep,'error.log'),'a+');
        tmp = regexprep(err.getReport('extended','hyperlinks','off'),'\n','\r\n');
        fprintf(fid,'%s',tmp);
        fclose(fid);
        errordlg('Protocol execution incomplete. See error.log for more information.')
        keyboard % see what's going on
    end
end
end


function startTrial(obj)
    updateInteractivity(obj, 'off');
    obj.indicateLoading('Loading trial data');
    obj.updateDateTime;
    if ~obj.f.trialLoaded
        obj.callbackLoadTrial([]);
    end
    if isfield(obj.p, 'Comments')
        comment = obj.p(obj.trialNum).Comments;
    else
        comment = '';
    end
    obj.h.trialInformationScroller.Value{end+1} = ...
        char(sprintf("%d(%d): %s", obj.trialIdx, obj.trialNum, comment));
    
    % Set filepath params
    savePrefix = sprintf("%05d_stim%05d", obj.trialIdx, obj.trialNum);
    for i = 1:sum(obj.d.Active)
        component = obj.activeComponents{i};
        component.SavePath = obj.dirExperiment;
        component.SavePrefix = savePrefix;
    end
    updateInteractivity(obj, 'on');

    % COMPONENTS: ACTIVATE
    for ci = 1:sum(obj.d.Active)
        component = obj.activeComponents{ci};
        component.StartTrial;
    end
    obj.f.trialLoaded = false;
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

function updateGUITimers(obj, startTic, reset)
    persistent trialSecs;
    persistent intervalSecs;
    persistent experimentSecs;
    persistent experimentStartSecs;

    if reset || isempty(trialSecs)
        % initialise variables
        totalTimeLabel = strip(split(obj.h.trialTimeEstimate.Text, '/'));
        trialSecs = seconds(duration(totalTimeLabel{2}, 'InputFormat', 'mm:ss'));
        experimentTimeLabel = strip(split(obj.h.protocolTimeEstimate.Text, '/'));
        experimentSecs = seconds(duration(experimentTimeLabel{2}, 'InputFormat', 'mm:ss'));
        experimentStartSecs = seconds(duration(experimentTimeLabel{1}, 'InputFormat', 'mm:ss'));
        intervalSecs = seconds(duration(obj.h.StatusCountdownLabel.Text(2:end), ...
                'InputFormat', 'mm:ss'));
    end

    tElapsed = toc(startTic);

    obj.h.StatusCountdownLabel.Text = sprintf("-%s",  ...
        string(duration(seconds(intervalSecs-tElapsed), 'Format', 'mm:ss')));
    if strcmpi(obj.status, 'running')
        obj.h.trialTimeEstimate.Text = sprintf("%s / %s",  ...
            string(duration(seconds(tElapsed), 'Format', 'mm:ss')), ...
            string(duration(seconds(trialSecs), 'Format', 'mm:ss')));
    end
    if obj.f.runningExperiment
        % called from full experiment - update full experiment timer.
        obj.h.protocolTimeEstimate.Text = sprintf("%s / %s",  ...
        string(duration(seconds(experimentStartSecs+tElapsed), 'Format', 'mm:ss')), ...
        string(duration(seconds(experimentSecs), 'Format', 'mm:ss')));
    end
end

function seq = buildTrialSequence(obj)
% builds a sequences of indices from a list of trialNums.
    tmp = arrayfun(@(x,y) {ones(1,x)*y},[obj.p.nRepetitions],1:length(obj.p));
    tmp = [tmp{:}];
    if obj.g.randomize > 0
        if obj.g.randomize == 2
            rng(0)
        else
            rng('shuffle')
        end
        seq = [];
        for ii = 1:obj.g.nProtRep
            seq = [seq tmp(randperm(length(tmp)))]; %#ok<AGROW>
        end
    else
        seq = repmat(tmp,1,obj.g.nProtRep);
    end
end

function stopTrial(obj)
% Stops all components, regardless of whether they're finished or not.
    for i = 1:length(obj.activeComponents)
        component = obj.activeComponents{i};
        component.Stop();
    end
end