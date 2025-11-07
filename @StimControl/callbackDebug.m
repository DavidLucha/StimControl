function callbackDebug(obj, src, event)    
keyboard;
qst = obj.d.Available{end};
q.query('Og')
d = obj.d.Available{1};
disp("DEBUG");
return
obj = ResetAllHardware(obj);
end

function obj = ResetAllHardware(obj)
    daqreset;
    imaqreset;
    obj = obj.findAvailableHardware();
end