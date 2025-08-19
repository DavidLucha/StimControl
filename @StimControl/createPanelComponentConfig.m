function createPanelComponentConfig(obj, hPanel, ~)
% function createPanelThermode(obj,hPanel,~,idxThermode,nThermodes)
%     obj.h.(thermodeID).panel.params = uipanel(obj.h.fig,...
%         'CreateFcn',    {@obj.createPanelThermode,ii,length(obj.s)});

grid = uigridlayout(hPanel);
grid.RowHeight = {23, '1x', 23};
grid.ColumnWidth = {'1x', '1x'};

obj.h.ComponentConfig.Label = uilabel(grid, "Text", "No Component Selected", ...
    'Layout', matlab.ui.layout.GridLayoutOptions( ...
        'Row', 1, ...
        'Column', [1 2]));

obj.h.ComponentConfig.Table = uitable(grid, 'Data', table(), ...
    'ColumnEditable', true, ...
    'ColumnWidth', 'fit', ...
    'Layout', matlab.ui.layout.GridLayoutOptions( ...
        'Row', 2, ...
        'Column', [1 2]), ...
        'DisplayDataChangedFcn', @(src, event) updateComponentConfigTable(src, event, obj));

obj.h.ConfirmConfigBtn = uibutton(grid, 'Text', 'Confirm', ...
    'Layout', matlab.ui.layout.GridLayoutOptions( ...
        'Row', 3, ...
        'Column', 2), ...
    'ButtonPushedFcn', @(src, event) obj.callbackConfirmComponentConfig, ...
    'Enable', false);

obj.h.CancelConfigBtn = uibutton(grid, 'Text', 'Cancel', ...
    'Layout', matlab.ui.layout.GridLayoutOptions( ...
        'Row', 3, ...
        'Column', 1), ...
    'ButtonPushedFcn', @(src, event) obj.callbackCancelComponentConfig, ...
    'Enable', false);

end

%% update table function
% TODO DYNAMIC UPDATE IF ALLOWABLE
function updateComponentConfigTable(src,event,obj)
    rownum  = event.DisplaySelection(1);
    component = obj.h.Available(obj.h.ComponentConfig.SelectedComponentIndex);
    propertyName = event.DisplayRowName{rownum};
    c = 1;
    if iscategorical(event.Source.Data{rownum, 1}{1}) 
        % TODO possible to add categories? 
        % if you want, change protected=true in ComponentProperty.getCategorical
    elseif ~component.ComponentProperties.(propertyName)(1).validatefcn(src.Data{rownum,c}{1}) %validate function
        % new value is invalid
        sInvalid = uistyle('BackgroundColor','red');
        addStyle(src,sInvalid,'row', rownum);
        return
    end
    removeStyle(src);
    % if component.ComponentProperties.()
    % newVal = 
    table2struct(event.Source.Data)
    vals = extractConfigVals(src, componentProperties);
    % fs = fields(componentProperties);
    

    tData =  table(transpose(valueRows), ...
            'VariableNames', {componentClass}, ...
            'RowNames', attributeRows);
    src.Data = tData;
    obj.h.ComponentConfig.ConfigStruct = vals;
end

%% extract config struct from uitable
% function s = extractConfigVals(src, componentConfigStruct)
%     s = struct();
%     for i = 1:length(src.RowName)
%     v = src.Data{i, 1}{1};
%     if iscell(v)
%         v = v{1};
%     elseif iscategorical(v)
%         v = string(v);
%     end
%     s.(src.RowName{i}) = v;
%     end
% end


