function callbackDebug(obj, src, event)    
obj.t.stop;
obj.t.start;
keyboard;
qst = obj.d.Available{end};
% q.query('Og')
d = obj.d.activeComponents{1};
disp("DEBUG");
return
obj = ResetAllHardware(obj);
end

function obj = ResetAllHardware(obj)
    daqreset;
    imaqreset;
    obj = obj.findAvailableHardware();
end