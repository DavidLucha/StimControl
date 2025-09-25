function callbackTimer(obj,~,~)
% hardware status updates in a timer

if strcmpi(obj.h.tabs.SelectedTab.Title, 'Setup')
    % update GUI in setup tab
    for i = 1:height(obj.h.AvailableHardwareTable)
        component = obj.d.Available{i};
        obj.h.AvailableHardwareTable.Data.Status{i} = component.GetStatus;
    end
else
    %update hardware status - thermode battery, etc.
    
    % update thermode gui
    

    % update GUI in experiment tab
    % if ~obj.DAQ.IsRunning && ~obj.isRunning
    %     for ii = 1:obj.nThermodes
    %         if obj.s(ii).existPort
    %             obj.h.(['Thermode' char(64+ii)]).battery.Value = ...
    %                 obj.s(ii).battery;
    %         end
    %     end
    % end
end