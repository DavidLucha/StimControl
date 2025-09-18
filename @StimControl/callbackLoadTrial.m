function callbackLoadTrial(obj, src, event)
% Sets trial number if changed, and preloads trial data into   
if src == obj.h.prevTrialBtn
    if obj.trialNum == 1
        obj.trialNum = length(obj.p);
    else
        obj.trialNum = obj.trialNum - 1;
    end
elseif src == obj.h.nextTrialBtn
    if obj.trialNum == length(obj.p)
        obj.trialNum = 1;
    else
        obj.trialNum = obj.trialNum + 1;
    end
end

% Load a trial
if sum(obj.d.Active) == 0
    obj.errorMsg('please select at least one hardware component');
elseif isempty(obj.p) || isempty(obj.g)
    obj.errorMsg('please select a protocol');
end

trialData = obj.p(obj.trialNum);
if isfield(trialData, 'tStim')
    tStim = trialData.tStim;
else
    tStim = 0;
end
genericTrialData = struct( ...
    'tPre', trialData.tPre, ...
    'tPost', trialData.tPost, ...
    'tStim', tStim', ...
    'nRepetitions', trialData.nRepetitions);
ks = keys(obj.d.ComponentProtocols);
for i = 1:length(ks)
    componentID = ks{i};
    component = obj.d.IDComponentMap{componentID};
    protocolNames = obj.d.ComponentProtocols(componentID);
    componentTrialData = struct();
    for f = 1:length(protocolNames{:})
        name = protocolNames{:}{f};
        componentTrialData.(name) = trialData.(name);
    end
    component.SavePath = obj.dirExperiment;
    component.LoadTrialFromParams(componentTrialData, genericTrialData);
end

tTrial = (genericTrialData.tPre + genericTrialData.tPost + genericTrialData.tStim) / 1000;
trialMins = floor(tTrial / 60);
trialSecs = ceil(tTrial - (trialMins * 60));
obj.h.StatusCountdownLabel.Text = sprintf('-%d:%d', trialMins, trialSecs);
obj.h.numTrialsElapsedLabel.Text = sprintf('Trial %d / %d', obj.trialIdx, length(obj.p));
obj.h.trialTimeEstimate.Text = sprintf('00:00 / %d:%d', trialMins, trialSecs);


% TODO ADD PREVIEWS
end