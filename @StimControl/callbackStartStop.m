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
    if isfield(obj.d, 'executionTimer') ...
            && isvalid(obj.d.executionTimer) && isrunning(obj.d.executionTimer)
        stop(obj.d.executionTimer);
    end
    for idx = 1:sum(obj.d.Active)
        component = obj.activeComponents{idx};
        component.Stop();
    end
    updateInteractivity(obj, 'on');
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
try
    runExperiment(obj, src, event);
catch e
    updateInteractivity(obj, 'on');
    obj.status = 'error';
    rethrow(e);
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

obj.trialNum = trialNums(1);

for i = 2:nTrials
    obj.runTrial(src, event); % spawns an execution timer
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
        obj.trialNum = trialNums(i);
        obj.callbackLoadTrial(src, event); % load trial during inter-trial period
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


% function callbackProtocolStart(obj,~,~)

% % disable GUI elemens
% hGUI = findobj('Parent',obj.h.fig,'Enable','on');
% for hChild = obj.h.fig.Children'
%     hGUI = [hGUI;findobj('Parent',hChild,...
%         'Enable','on','-not','Style','Text')]; %#ok<AGROW>
% end
% set(hGUI,'Enable','off')
% set(obj.h.protocol.push.stop,'Enable','on')
% obj.isRunning = true;


% % build/randomize sequence
% tmp = arrayfun(@(x,y) {ones(1,x)*y},[obj.p.nRepetitions],1:length(obj.p));
% tmp = [tmp{:}];
% if obj.g.randomize > 0
%     if obj.g.randomize == 2
%         rng(0)
%     else
%         rng('shuffle')
%     end
%     seq = [];
%     for ii = 1:obj.g.nProtRep
%         seq = [seq tmp(randperm(length(tmp)))]; %#ok<AGROW>
%     end
% else
%     seq = repmat(tmp,1,obj.g.nProtRep);
% end

% % create output directory
% [~,tmp,~] = fileparts(obj.pFile);
% tmp       = sprintf('%s_%s',datestr(now,'yymmdd_HHMMSS'),tmp);
% tmp       = regexprep(tmp,'[^A-Za-z0-9-+]','_');
% dirOut    = fullfile(obj.dirAnimal,datestr(now,'yymmdd'),tmp);
% mkdir(dirOut)

% % copy protocol file to output directory
% [~,tmp1,tmp2] = fileparts(obj.pFile);
% copyfile(obj.pFile,fullfile(dirOut,[tmp1 tmp2]))

% % copy channel information to output directory
% fid = fopen(fullfile(dirOut,'channels.txt'),'w');
% tmp = evalc('disp(obj.DAQ.Channels)');
% tmp = regexprep(tmp,'\n','\r\n');
% fprintf(fid,'%s',tmp);
% fclose(fid);

% % number of columns in output files
% nCols = length(obj.DAQ.Channels)+1;

% % loop through protocol
% try
%     obj.waitForNeutral
%     nSeq = numel(seq);
%     for idxSeq = 1:nSeq
        
%         % set stimulus
%         idxStim = seq(idxSeq);
%         obj.idxStim = idxStim;

%  % % %%%%%%%%%%%%%%%%%%%%%%%%BASELINES%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  %         obj.waitForNeutral
%  %         if idxSeq == 1
%  %             for ii = fliplr(1:obj.g.dPause)
%  %                 if ~obj.isRunning
%  %                     break
%  %                 end
%  %                 obj.setTitle(sprintf('Pause: %ds',ii))
%  %                 pause(1)
%  %             end
%  % 
%  % %             pause(obj.g.dPause)
%  %         end
%  % 
%  %          % should we break?
%  %         if ~obj.isRunning
%  %             break
%  %         end
%  % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%         % set windows title
%         obj.setTitle(sprintf('Running Stimulation %d/%d, stimulus #%d',...
%             idxSeq,nSeq,idxStim))
        
%         % set output filename
%         fnOut = sprintf('%05d_stim%05d_%dcol.dbl',idxSeq,idxStim,nCols);
%         fnOut = fullfile(dirOut,fnOut);
        
%         % run stimulation
%         obj.stimulate(fnOut)
        
%         % poll batteries
%         for ii=1:obj.nThermodes
%             obj.h.(['Thermode' char(64+ii)]).battery.Value = obj.s(ii).battery;
%         end
        
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  % set stimulus
%  if idxSeq<nSeq
%         idxStim = seq(idxSeq+1);
%         obj.idxStim = idxStim;
%  end
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%         % pause between stimuli
%         if idxSeq<nSeq && obj.g.dPause>0
%             for ii = fliplr(1:obj.g.dPause)
%                 if ~obj.isRunning
%                     break
%                 end
%                 obj.setTitle(sprintf('Pause: %ds',ii))
%                 pause(1)
%             end
%         end
        
%         % should we break?
%         if ~obj.isRunning
%             break
%         end
%     end
%     obj.setTitle

% % catch errors during protocol execution
% catch err
%     fid = fopen(fullfile(dirOut,'error.log'),'a+');
%     tmp = regexprep(err.getReport('extended','hyperlinks','off'),'\n','\r\n');
%     fprintf(fid,'%s',tmp);
%     fclose(fid);
%     errordlg('Protocol execution incomplete. See error.log for more information.')
%     keyboard % see what's going on
% end

% % Enable GUI elemens
% set(hGUI,'Enable','on')
% set(obj.h.protocol.push.stop,'Enable','off')
% obj.isRunning = false;
% obj.setTitle()