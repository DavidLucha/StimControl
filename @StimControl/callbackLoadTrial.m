function callbackLoadTrial(obj)
if isempty(obj.d.Active)
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
    component.LoadTrial(componentTrialData, genericTrialData);
    component.SavePath = obj.dirExperiment;
end
% TODO ADD PREVIEWS??
end