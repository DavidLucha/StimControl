function callbackEditComponentConfig(obj)
%% first, retrieve selected component from obj.

%% set obj.h.ComponentConfig.Component.Handle to component

%% set obj.h.ComponentConfig.Component.Properties to componentProperties

%% Enable confirmation and cancel buttons
obj.h.confirmComponentConfigBtn.Enabled = true;
obj.h.cancelComponentConfigBtn.Enabled = true;
    
%% then populate table
%     %set up panel visuals
%     cp = component.GetComponentProperties();
%     if ~component.Abstract
%         obj.h.ComponentConfig.Label.Text = component.ID;
%     else
%         obj.h.ComponentConfig.Label.Text = cp.ID.default;
%     end
% 
%     attributeRows = [];
%     valueRows = [];
%     r = 1;
% 
%     fs = fields(cp);
%     if ~component.Abstract
%         vals = component.GetConfigStruct; %TODO DOES THIS ALWAYS WORK
%     else
%         vals = component.GetDefaultComponentStruct;
%     end
% 
%     for f = 1:length(fs)
%         prop = cp.(fs{f});
%         if ~prop.dependencies(vals)
%             continue
%         end
%         attributeRows{r} = fs{f};
%         if ~isempty(prop.allowable)
%             valueRows{r} = categorical(cellstr(prop.allowable));
%         else
%             valueRows{r} = vals.(fs{f});
%         end
%         r = r + 1;
%     end
%     tData =  table(transpose(valueRows), ...
%             'VariableNames', {class(component)}, ...
%             'RowNames', attributeRows);
%     obj.h.ComponentConfig.Table.Data = tData;
% 
%     
% end