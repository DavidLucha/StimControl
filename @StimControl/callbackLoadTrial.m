function callbackLoadTrial(obj)
if isempty(obj.h.Active)
    error("No hardware selected for protocol")
elseif isempty(obj.p) || isempty(obj.g)
    error("No protocol available to load")
end

trialData = obj.p(obj.trialNum);

for hardwareNum = 1:length(obj.h.Active)
    
end

end