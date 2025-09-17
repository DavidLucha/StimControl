function callbackChangeTab(obj, src, event)
if strcmpi(event.NewValue.Title, 'Experiment')
    %% TODO HOW DO I CONFIRM THEY WANT TO DO ALL THIS - BIG BUTTON???
    % move components over
    for i = 1:length(obj.h.Available)
        component = obj.h.Available{i};
        if obj.h.Active{i}
            % make sure device is initialised
            if isempty(component.SessionHandle)
                component.InitialiseSession();
            end
            % update preview window
            component.UpdatePreview('newPlot', obj.h.Session.PreviewPanels{i});
        end
    end

    % load in protocols TODO

elseif strcmpi(event.NewValue.Title, 'Setup')
    % move component previews back
    for i = 1:length(obj.h.Available)
        component = obj.h.Available{i};
        component.UpdatePreview(obj.h.Setup.PreviewPanels{i});
    end
else
    disp("how did you get here?");
end
end