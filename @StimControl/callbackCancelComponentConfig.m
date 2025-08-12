function callbackCancelComponentConfig(obj)

obj.h.ComponentConfig.Label.Text = "No Component Selected";
obj.h.ComponentConfig.Component.Handle = 'none';
obj.h.ComponentConfig.Component.Properties = 'none';
obj.h.ComponentConfig.Table.Data = table();

obj.h.confirmComponentConfigBtn.Enabled = false;
obj.h.cancelComponentConfigBtn.Enabled = false;
end