function callbackChangeTab(obj, src, event)
if strcmpi(event.NewValue.Title, 'Experiment')
    %% TODO HOW DO I CONFIRM THEY WANT TO DO ALL THIS - BIG BUTTON???
    % move components over
    for i = 1:length(obj.d.Available)
        component = obj.d.Available{i};
        if obj.d.Active(i)
            % make sure device is initialised
            if isempty(component.SessionHandle)
                component.InitialiseSession();
            end
        else
            % de-initialise unnecessary devices
            component.Stop();
        end
    end
    % update preview panel with final count of active components.
    obj.createPanelSessionPreview(obj.h.Session.Preview.panel.params);
elseif strcmpi(event.NewValue.Title, 'Setup')
    % move component previews back
    for i = 1:length(obj.d.Available)
        component = obj.d.Available{i};
        component.UpdatePreview(obj.h.Setup.PreviewPanels{i});
    end
end
end