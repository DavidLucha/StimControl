function callbackConfirmComponentConfig(obj)
% first get component from obj.
    % @component.Configure,"configStruct",extractConfigStruct(uit) - see
    % EditComponentConfig
    % obj.h.ComponentConfig.ConfigStruct ^ instead of ExtractConfigStruct

% then clear
obj.callbackCancelComponentConfig();
end