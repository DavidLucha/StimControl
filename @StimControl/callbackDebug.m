function callbackDebug(obj, src, event)    
keyboard;
qst = obj.d.Available{end};
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