function callbackEditComponentConfig(obj)
%% first, retrieve selected component from obj.
rowIndex = obj.h.AvailableHardwareTable.Selection;
% selectedRow = obj.h.AvailableHardwareTable.Data(rowIndex,:);
component = obj.h.Available{rowIndex};

%% Pass handle for later use
obj.h.ComponentConfig.SelectedComponentIndex = rowIndex;

%% Enable confirmation and cancel buttons
obj.h.ConfirmConfigBtn.Enable = true;
obj.h.CancelConfigBtn.Enable = true;
    
%% Populate Config Table
if isfield(component.ConfigStruct, 'ID')
    obj.h.ComponentConfig.Label.Text = component.ConfigStruct.ID;
else
    obj.h.ComponentConfig.Label.Text = class(component);
end

tData = rows2vars(struct2table(component.ConfigStruct, 'AsArray', true));
rowNames = tData{:, 1};
values = tData{:, 2};

for fnum = 1:length(rowNames)
    prop = component.ComponentProperties.(rowNames{fnum});
    if ~isempty(prop.allowable)
        cat = prop.getCategorical;
        configVal = component.ConfigStruct.(rowNames{fnum});
        if ischar(configVal)
            configCat = categorical(cellstr(configVal));
            idx = find(cat == configCat);
            values{fnum} = cat(idx);
        elseif isstring(configVal)
            configCat = categorical(cellstr(configVal));
            idx = find(cat == configCat);
            values(fnum) = {cat(idx)};
        elseif isnumeric(configVal)
            configCat = categorical(configVal);
            idx = find(cat == configCat);
            values(fnum) = {cat(idx)};
        end
    end
end

tData =  table(values, ...
    'RowNames', rowNames);

obj.h.ComponentConfig.Table.Data = tData;
end