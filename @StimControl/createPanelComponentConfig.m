function createPanelComponentConfig(obj, hPanel, ~, component)
% function createPanelThermode(obj,hPanel,~,idxThermode,nThermodes)
%     obj.h.(thermodeID).panel.params = uipanel(obj.h.fig,...
%         'CreateFcn',    {@obj.createPanelThermode,ii,length(obj.s)});
    hPanel.Title = 'Config';
    hPanel.Layout.Row = 1;
    hPanel.Layout.Column = [2 3];

    %set up panel visuals
    cp = component.GetComponentProperties();
    if ~component.Abstract
        hPanel.Title = component.ID;
    else
        hPanel.Title = cp.ID.default;
    end
    
    grid = uigridlayout(hPanel);
    grid.RowHeight = {'1x', 23};
    grid.ColumnWidth = {'1x'};
    
    attributeRows = [];
    valueRows = [];
    r = 1;
    
    fs = fields(cp);
    if ~component.Abstract
        vals = component.GetConfigStruct; %TODO DOES THIS ALWAYS WORK
    else
        vals = component.GetDefaultComponentStruct;
    end
    
    for f = 1:length(fs)
        prop = cp.(fs{f});
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
            'VariableNames', {class(component)}, ...
            'RowNames', attributeRows);
    uit = uitable(grid, 'Data', tData, 'ColumnEditable', true, ...
        'ColumnWidth', 'fit');
    uit.Layout.Row = 1;
    uit.Layout.Column = [1 2];
    uit.DisplayDataChangedFcn = @(src,event) updateTable(src,event, cp, class(component));
    
    confirmConfigBtn = uibutton(grid);
    confirmConfigBtn.Layout.Row = 2;
    confirmConfigBtn.Layout.Column = 1;
    confirmConfigBtn.Text =  "Confirm";
    confirmConfigBtn.ButtonPushedFcn = {@component.Configure,"configStruct",extractConfigStruct(uit)};
end

%% update table function
function updateTable(src,event,componentProperties, componentClass)
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


