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
    'ButtonPushedFcn', @obj.callbackConfirmComponentConfig);

obj.h.cancelConfigBtn = uibutton(grid, 'Text', 'Cancel', ...
    'Layout', matlab.ui.layout.GridLayoutOptions( ...
        'Row', 3, ...
        'Column', 1), ...
    'ButtonPushedFcn', @obj.callbackCancelComponentConfig);

end

%% update table function
% TODO DYNAMIC UPDATE IF ALLOWABLE
function updateComponentConfigTable(src,event,obj)
    componentProperties = obj.h.ComponentConfig.Component.Properties;
    componentClass = class(obj.h.ComponentConfig.Component.Handle);

    r  = event.DisplaySelection(1);
    c = 1;
    vals = struct();
    if ~componentProperties.(event.DisplayRowName{r}).validatefcn(src.Data{r,c}{1})
        % new value is invalid
        sInvalid = uistyle('BackgroundColor','red');
        addStyle(src,sInvalid,'row', r);
        return
    end
    removeStyle(src);
    vals = extractConfigStruct(src);
    fs = fields(componentProperties);
    attributeRows = [];
    valueRows = [];
    r = 1;
    for f = 1:length(fs)
        prop = componentProperties.(fs{f});
        if ~prop.dependencies(vals)
            continue
        end
        attributeRows{r} = fs{f};
        if ~isempty(prop.allowable)
            valueRows{r} = categorical(cellstr(prop.allowable));
        else
            valueRows{r} = vals.(fs{f});
        end
        r = r + 1;
    end
    tData =  table(transpose(valueRows), ...
            'VariableNames', {componentClass}, ...
            'RowNames', attributeRows);
    src.Data = tData;
    obj.h.ComponentConfig.ConfigStruct = vals;
end

%% extract config struct from uitable
function s = extractConfigStruct(src)
    s = struct();
    for i = 1:length(src.RowName)
    v = src.Data{i, 1}{1};
    if iscell(v)
        v = v{1};
    elseif iscategorical(v)
        v = string(v);
    end
    s.(src.RowName{i}) = v;
    end
end


