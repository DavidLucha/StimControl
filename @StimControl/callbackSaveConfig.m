function callbackSaveConfig(obj, src, event)
    [s, pcInfo] = system('vol');
    pcInfo = strsplit(pcInfo, '\n');
    pcID = pcInfo{2}(end-8:end);
    prompt = {'Enter filename:'};
    dlgtitle = 'Save config';
    definput = {[pcID 'default']};
    filename = inputdlg('Enter filename:','Save config',[1 45],{[pcID '_default']});
    if isempty(filename)
        return
    end
    filename = [filename{:} '.json'];
    if src == obj.h.saveSessionBtn
        %% Save session
        pBase = obj.path.sessionBase;
        saveData = [];
        saveData.activeHardware = obj.d.ActiveIDs;
        saveData.hardwareTableData = [];
        obj.h.AvailableHardwareTable.Data;
        for ri = 1:height(obj.h.AvailableHardwareTable.Data)
            line = obj.h.AvailableHardwareTable.Data(ri,:);
            saveData.hardwareTableData.(line.('Protocol ID'){:}) = struct( ...
                'Enable', line.('Enable'), ...
                'Preview', line.('Preview'), ...
                'PRow', line.('PRow'){:}, ...
                'PColumn', line.('PColumn'){:});
        end
    elseif src == obj.h.createConfigBtn
        %% Save Component params
        pBase = obj.path.paramBase;
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
    end
    jsonData = jsonencode(saveData);
    file = fopen([pBase filesep filename], 'w+');
    fprintf(file, '%s', jsonData);
    fclose(file);
end