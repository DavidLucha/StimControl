function callbackFileExit(obj,~,~)

% delete the figure
delete(obj.h.fig)

% stop and delete timer
stop(obj.t)
delete(obj.t)

% remove parallel pool sessions
delete(gcp('nocreate'))
daqreset
imaqreset
for port = SerialComponent.FindPorts
    SerialComponent.ClearPort(port);
end

% if QSTcontrol was called via the batch file, also quit Matlab
if ~usejava('desktop')
    exit
end