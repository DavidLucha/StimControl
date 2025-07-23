function tData = callbackPopulateHardwareTable(obj)
% get DAQs

columnNames = {'Type', 'ID', 'Enabled', 'Status', 'Display'};
tData = table();

if ~isempty(obj.hardwareParams)
    takeFromParams = true;
end

% Populate DAQs
daqs = daqlist();
for i = 1:height(daqs)
    deviceID = strcat(daqs.VendorID(i), '.', daqs.DeviceID(i), '.', daqs.Model(i));
    enabled = false;
    tData(end+1, :) = {'DAQ', deviceID, enabled, 'Not Initialised', false};
end

% populate cameras TODO

tData.Properties.VariableNames = columnNames;
end