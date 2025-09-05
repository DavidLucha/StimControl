function callbackLoadTrial(obj)
if isempty(obj.h.Active)
    error("No hardware selected for protocol")
elseif isempty(obj.p) || isempty(obj.g)
    error("No protocol available to load")
end
if isempty(obj.trialNum)
    obj.trialNum = 1;
end
trialData = obj.p(obj.trialNum);
genericTrialData = struct( ...
    'tPre', trialData.tPre, ...
    'tPost', trialData.tPost, ...
    'nRepetitions', trialData.nRepetitions);
% genericTrialData;
ks = keys(obj.h.ComponentProtocols);
for i = 1:length(ks)
    componentID = ks{i};
    component = obj.h.IDComponentMap{componentID};
    protocolNames = obj.h.ComponentProtocols(componentID);
    componentTrialData = struct();
    for f = 1:length(protocolNames{:})
        name = protocolNames{:}{f};
        componentTrialData.(name) = trialData.(name);
    end
    component.LoadTrial(componentTrialData, genericTrialData);
end

end