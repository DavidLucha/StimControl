function callbackSaveComponentParams(obj)
    filepath = [obj.h.path.setup.base filesep 'componentParams'];
    filename = ['params' obj.h.path.nameExtension '_' char(datetime)];
    saveData = {};
    for i = 1:length(obj.d.Active)
        component = obj.d.Active{i};
        saveData{end+1} = component.GetParams;
        component.SaveAuxiliaries(filepath);
    end
    jsonData = jsonencode(saveData);
    file = fopen([filepath filesep filename], 'w+');
    fprintf(file, '%s', jsonData);
    fclose(file);
end