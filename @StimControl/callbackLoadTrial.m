function callbackLoadTrial(obj, src, ~)
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
genericTrialData = struct( ...
    'tPre', trialData.tPre, ...
    'tPost', trialData.tPost, ...
    'nRepetitions', trialData.nRepetitions);
ks = keys(obj.d.ComponentProtocols);
for i = 1:length(ks) %TODO PARALLELISE?
    componentID = ks{i};
    component = obj.d.IDComponentMap{componentID};
    protocolNames = obj.d.ComponentProtocols(componentID);
    componentTrialData = struct();
    for f = 1:length(protocolNames{:})
        name = protocolNames{:}{f};
        componentTrialData.(name) = trialData.(name);
    end
    component.LoadTrialFromParams(componentTrialData, genericTrialData);
end

end