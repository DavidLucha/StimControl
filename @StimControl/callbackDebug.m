function callbackDebug(obj, src, event)    
keyboard;
cam = obj.d.Available{end};
d = obj.d.Available{1};
d.StartPreview;
disp("DEBUG");
return
obj = ResetAllHardware(obj);
end

function obj = ResetAllHardware(obj)
    daqreset;
    imaqreset;
    obj = obj.findAvailableHardware();
end