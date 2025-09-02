function callbackReadSessionProtocol(obj)
% todo if empty
[file, location] = uigetfile([obj.path.protocolBase filesep '*.stim'], 'Select protocol');

[p, g] = readProtocol([location file]);
obj.p = p;
obj.g = g;
obj.idxStim = 1;
end