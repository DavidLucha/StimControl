function callbackLoadTrial(obj)
if isempty(obj.h.Active)
    error("No hardware selected for protocol")
elseif isempty(obj.p) || isempty(obj.g)
    error("No protocol available to load")
end
trialData = obj.p(obj.trialNum);

% for hardwareNum = 1:length(obj.h.Available)
%     A = cellfun(@(x, idx) class(x), 'uniformoutput', );
% 
%     countInstances = @(x,value) sum(x(:) == value);
%     A = cellfun(@(x, idx) isa(x, 'DAQComponent') && );
% 
% end

end

function assignStimulus(obj)
    for i = 1:height(fields(obj.p))
        
    end
end