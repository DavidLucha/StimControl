function checkprotocol()
    % fpath = LoadDlg;
    fpath = 'C:\Users\labadmin\Documents\MATLAB\StimControl\config\experiment_protocols\Example_StimProtocol.stim';
    if ~isfile(fpath)
        fpath = 'C:\Users\labadmin\OneDrive - The University of Queensland\Documents\MATLAB\StimControl\config\experiment_protocols\Example_StimProtocol.stim';
    end
    ignoreErrors = false;
    [p, g, err] = ProcessFile(fpath, ignoreErrors);
    if ~isempty(err)
        disp(sprintf("Error reading protocol: %s", err));
    end
    figs = {};
    for i = 1:length(p)
        trial = p(i);
        if trial.valid
            statusMsg = "Valid";
        else
            statusMsg = sprintf("INVALID. %s", trial.errorMsg);
        end
        disp(sprintf("Trial %d: %s", i, statusMsg));
        try
            figs{end+1} = trial.Plot();
        catch exc
            disp(sprintf("  trial could not be plotted: %s", exc.message));
        end
    end
    keyboard; %continue to close all.
    for i = 1:length(figs)
        fig = figs{i};
        if ~isempty(fig) && isvalid(fig)
            delete(fig);
        end
    end
    function [fpath] = LoadDlg()
        folder = mfilename('fullpath');
        idx = strfind(folder, ['common' filesep 'checkprotocol']) - 1;
        folder = [folder(1:idx) 'config' filesep 'experiment_protocols' filesep '*.stim'];
        [filename, dir] = uigetfile(folder);
        if filename == 0
            return
        end
        fpath = [dir filesep filename];
    end

    function [p, g, err] = ProcessFile(fpath, ignoreErrors)
        p = [];
        g = [];
        err = [];
        if contains(fpath, '.stim')
            try
                [p, g] = readProtocol(fpath, ignoreErrors);
            catch err
                if ignoreErrors
                    err = err.message;
                else
                    dbstack
                    rethrow(err);
                end
            end
        else
            err = "Unsupported file format. Supported formats: .stim";
        end
    end
end
