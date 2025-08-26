function callbackLoadSessionProtocol(obj)
%UNTITLED4 Summary of this function goes here
%   Detailed explanation goes here
[file, location] = uigetfile([obj.h.path.setup.base filesep 'protocols']);

[p, g] = readProtocol([location filesep file]);

end