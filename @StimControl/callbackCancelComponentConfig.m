function callbackCancelComponentConfig(obj)

obj.h.ComponentConfig.Label.Text = "No Component Selected";
obj.h.ComponentConfig.Component.Handle = [];
obj.h.ComponentConfig.Component.Properties = [];
obj.h.ComponentConfig.Table.Data = table();

obj.h.confirmComponentConfigBtn.Enable = false;
obj.h.cancelComponentConfigBtn.Enable = false;
end