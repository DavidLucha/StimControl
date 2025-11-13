function callbackStartStop(obj, src, event)
% Starts or stops an experiment. 
% enables or disables relevant GUI elements for interactivity
if strcmpi(obj.status, 'running') || strcmpi(obj.status, 'paused') ...
    || strcmpi(obj.status, 'inter-trial') || strcmpi(obj.status, 'awaiting trigger')
    % Confirm stop experiment
    selection = uiconfirm(obj.h.fig, ...
        "Experiment is still running! Really stop?","Confirm Stop", ...
        "Icon","warning");
    if ~strcmpi(selection, "OK")
        return
    end
    obj.f.stopTrial = true;
elseif src == obj.h.StartStopBtn || src == obj.h.StartSingleTrialBtn
    obj.updateDateTime;
    createOutputDir(obj);
    if src == obj.h.StartStopBtn
        obj.f.runningExperiment = true;
    end
    for i = 1:obj.d.nActive
        component = obj.d.activeComponents{i};
        component.SavePath = obj.dirExperiment;
        component.LoadTrial([]);
    end
    obj.f.startTrial = true;
    
elseif src == obj.h.StartPassiveBtn
    obj.f.passive = true;
    for i = 1:obj.d.nActive
        component = obj.d.activeComponents{i};
        component.SavePath = [obj.dirExperiment '_passive'];
    end
end
end

function createOutputDir(obj)
% create output directory if it doesn't already exist
if ~isfolder(obj.dirExperiment)
    mkdir(obj.dirExperiment)
end

% copy protocol file to output directory
[~,tmp1,tmp2] = fileparts(obj.path.SessionProtocolFile);
copyfile(obj.path.SessionProtocolFile,fullfile(obj.dirExperiment,[tmp1 tmp2]))

% % copy channel information to output directory TODO this is copied from
% QSTcontrol 
% fid = fopen(fullfile(dirOut,'channels.txt'),'w');
% tmp = evalc('disp(obj.DAQ.Channels)');
% tmp = regexprep(tmp,'\n','\r\n');
% fprintf(fid,'%s',tmp);
% fclose(fid);
end