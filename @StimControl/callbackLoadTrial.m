function callbackLoadTrial(obj, src, ~)
% Sets trial number if changed, and preloads trial data into  
obj.indicateLoading("Loading trial");
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
elseif isfield(obj.g, 'sequence')
    obj.trialNum = obj.g.sequence(obj.trialIdx);
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
    'nRuns', trialData.nRuns);

ct = fields(obj.d.componentTargets);
for cIdx = 1:length(ct)
    compID = ct{cIdx};
    component = obj.d.Available{obj.d.ProtocolIDMap(compID)};
    componentData = trialData.params.(compID);
    component.LoadTrialFromParams(componentData, genericTrialData, false);
end

% tic
% for cIdx = 1:length(ct)
%     compID = ct{cIdx};
%     component = obj.d.Available{obj.d.ProtocolIDMap(compID)};
%     targets = obj.d.componentTargets.(compID);
%     componentData = [];
%     for f = 1:length(targets)
%         if isfield(trialData.params, targets{f})
%             componentData.(targets{f}) = trialData.params.(targets{f});
%         end
%     end
%     
%     toc
% end

if src ~= obj.h.StartStopBtn
    obj.status = 'ready'; % prevent softlocks
end
obj.f.trialLoaded = true;
end