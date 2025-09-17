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
targetComponents = keys(obj.h.ComponentProtocols);
for i = 1:length(targetComponents)
    componentID = targetComponents{i};
    component = obj.h.IDComponentMap{componentID};
    componentProtocolNames = obj.h.ComponentProtocols{componentID};
    componentTrialData = struct();
    for j = 1:length(componentProtocolNames)
        name = componentProtocolNames{j};
        componentTrialData.(name) = trialData.(name);
    end
    component.LoadTrial(componentTrialData, genericTrialData);
    component.SavePath = obj.path.dirData;
end
end