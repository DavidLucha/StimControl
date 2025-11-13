function callbackSaveConfig(obj, src, event)
    
    [s, pcInfo] = system('vol');
    pcInfo = strsplit(pcInfo, '\n');
    pcID = pcInfo{2}(end-8:end);

    %% Save Component Params
    % todo if src = saveAs button then ask for a filename, else filename ispcID
    filename = [pcID '.json'];
    saveData = {};
    for i = 1:length(obj.d.Available)
        component = obj.d.Available{i};
        params = component.GetParams;
        params.type = class(component);
        params.Active = logical(obj.d.Active(i));
        params.Previewing = component.Previewing;
        saveData{end+1} =params;
        component.SaveAuxiliaryConfig(obj.path.paramBase);
    end
    jsonData = jsonencode(saveData);
    file = fopen([obj.path.paramBase filesep filename], 'w+');
    fprintf(file, '%s', jsonData);
    fclose(file);
end