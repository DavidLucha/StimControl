function checkprotocol()
   fpath = LoadDlg;
    [p, g, err] = ProcessFile(fpath);
    if ~isempty(err)
        disp(sprintf("Error reading protocol: %s", err));
    end
    for i = 1:length(p)
        trial = p(i);
        if trial.validity
            statusMsg = "Valid";
        else
            statusMsg = sprintf("INVALID. %s", trial.err);
        end
        disp(sprintf("Trial %d: %s", i, statusMsg));
        try
            trial.Plot();
        catch exc
            disp(sprintf("  trial could not be plotted: %s", exc.message));
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

    function [p, g, err] = ProcessFile(fpath)
        if contains(fpath, '.stim')
            try
                [p, g] = readProtocol(fpath, true);
            catch err
                err = err.message;
            end
        else
            err = "Unsupported file format. Supported formats: .stim";
        end
    end
end
