function callbackLoadTrial(obj)
if isempty(obj.h.Active)
    error("No hardware selected for protocol")
elseif isempty(obj.p) || isempty(obj.g)
    error("No protocol available to load")
end

trialData = obj.p(obj.trialNum);
ks = keys(obj.h.ComponentProtocols);
for i = 1:length(ks)
    componentID = ks{i};
    component = obj.h.IDComponentMap{componentID};
    protocolNames = obj.h.ComponentProtocols(componentID);
    s = struct();
    for f = 1:length(protocolNames)
        name = protocolNames{f};
        s.(name) = trialData.(name);
    end
    component.LoadProtocol(s);
end

%TODO THINGS THAT HAPPEN WHEN LOADING FINISHES
end