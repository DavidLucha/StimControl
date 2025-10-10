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
    'tPre', trialData(obj.trialIdx).tPre, ...
    'tPost', trialData(obj.trialIdx).tPost, ...
    'nRepetitions', trialData(obj.trialIdx).nRepetitions);
fs = fields(trialData(obj.trialIdx));
for fIdx = 1:length(fs)
    f = fs{fIdx};
    if any(strcmpi({'tPre', 'tPost', 'nRepetitions', 'Comments'}, f))
        continue
    end
    component = obj.d.Available{obj.d.ProtocolIDMap(f)};
    component.LoadTrialFromParams(trialData(obj.trialIdx).(f), genericTrialData);
end

if src ~= obj.h.StartStopBtn
    obj.status = 'ready'; % prevent softlocks
end
obj.f.trialLoaded = true;
end