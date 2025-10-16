function callbackSaveConfig(obj, src, event)
    
    %% save Component Params
    filepath = [obj.path.setup.base filesep 'componentParams'];
    filename = ['params' obj.path.nameExtension '_' char(datetime)];
    saveData = {};
    for i = 1:length(obj.d.Available)
        component = obj.d.Available{i};
        params = component.GetParams;
        params.Active = obj.d.Active(i);
        saveData{end+1} =params;
        component.SaveAuxiliaries(filepath);
    end
    jsonData = jsonencode(saveData);
    file = fopen([filepath filesep filename], 'w+');
    fprintf(file, '%s', jsonData);
    fclose(file);
end