function checkprotocol()
    % fig = CreateFigure;
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

    % TODO SIMPLIFY THIS: make trial textarea not editable or remove it entirely

    if ~isempty(err)
        % set ProtocolInformationLabel to err or general params
    else
        % set ProtocolInformationLabel to general params
    end

    % load trial info
    % preselect first trial
    % fill out fpath


    

    % Show the figure after all components are created
    % fig.UIFigure.Visible = 'on';
    
    


    %% helper functions

    % Create UIFigure and components
    function fig = CreateFigure()
        fig = [];
        % Create UIFigure and hide until all components are created
        fig.UIFigure = uifigure('Visible', 'off', ...
            'Position', [100 100 640 480], ...
            'Name', 'Protocol Checker');

        fig.GridLayout = uigridlayout(fig.UIFigure, ...
            'ColumnWidth', {'1x', 25, '1x'}, ...
            'RowHeight', {'1x', 22, 5, 20, '1x'}, ...
            'ColumnSpacing', 6, ...
            'RowSpacing', 0, ...
            'Padding', [6 0 6 0]);

        fig.OverviewPanel = uipanel(fig.GridLayout);
        fig.OverviewPanel.Layout.Row = [1 5];
        fig.OverviewPanel.Layout.Column = 1;

        fig.OverviewGrid = uigridlayout(fig.OverviewPanel, ...
            'ColumnWidth', {22, '1x'}, ...
            'RowHeight', {22, '1x', '1x', '1x', '1x', '1x', '1x', '1x'}); 

        fig.TrialPanel = uipanel(fig.OverviewGrid, ...
            'Scrollable', 'on');
        fig.TrialPanel.Layout.Row = [6 8];
        fig.TrialPanel.Layout.Column = [1 2];

        fig.TrialGrid = uigridlayout(fig.TrialPanel, ...
            'ColumnWidth', {'1x', 50}, ...
            'RowHeight', {'1x', 22});

        fig.TrialInformationabel = uilabel(fig.TrialGrid, ...
            'VerticalAlignment', 'top', ...
            'Text', 'Trial Information, when selected.');
        fig.TrialInformationabel.Layout.Row = [1 2];
        fig.TrialInformationabel.Layout.Column = [1 2];

        fig.PlotTrialButton = uibutton(fig.TrialGrid, 'push', ...
            'Tooltip', {'Refresh the contents of the TextArea above to match the contents of the file it was loaded from'}, ...
            'Text', 'Plot');
        fig.PlotTrialButton.Layout.Row = 2;
        fig.PlotTrialButton.Layout.Column = 2;

        fig.TrialSummaryTable = uitable(fig.OverviewGrid, ...
            'ColumnName', {'Trial No.'; 'Status'}, ...
            'RowName', {});
        fig.TrialSummaryTable.Layout.Row = [2 5];
        fig.TrialSummaryTable.Layout.Column = [1 2];

        fig.ProtocolInformationLabel = uilabel(fig.OverviewGrid, ...
            'Text', 'General Read Status');
        fig.ProtocolInformationLabel.Layout.Row = 1;
        fig.ProtocolInformationLabel.Layout.Column = 2;

        fig.LoadLeftBtn = uibutton(fig.OverviewGrid, 'push', ...
            'Text', '+');
        fig.LoadLeftBtn.Layout.Row = 1;
        fig.LoadLeftBtn.Layout.Column = 1;

        fig.CopyRLBtn = uibutton(fig.GridLayout, 'push', ...
            'Tooltip', {'Expand to see full protocol text'}, ...
            'Text', '<');
        fig.CopyRLBtn.Layout.Row = 4;
        fig.CopyRLBtn.Layout.Column = 2;

        fig.RightPanel = uipanel(fig.GridLayout);
        fig.RightPanel.Layout.Row = [1 5];
        fig.RightPanel.Layout.Column = 3;

        fig.RightGrid = uigridlayout(fig.RightPanel, ...
            'ColumnWidth', {'1x', '1x', '1x'}, ...
            'RowHeight', {22, '1x', 22});

        fig.TextArea = uitextarea(fig.RightGrid);
        fig.TextArea.Layout.Row = 2;
        fig.TextArea.Layout.Column = [1 3];

        fig.LoadRightBtn = uibutton(fig.RightGrid, 'push', ...
            'Text', 'Browse');
        fig.LoadRightBtn.Layout.Row = 1;
        fig.LoadRightBtn.Layout.Column = 3;

        fig.SaveButton = uibutton(fig.RightGrid, 'push', ...
            'Tooltip', {'Save the contents of the TextArea to the file defined at the top'}, ...
            'Text', 'Save');
        fig.SaveButton.Layout.Row = 3;
        fig.SaveButton.Layout.Column = 3;

        fig.RecalculateButton = uibutton(fig.RightGrid, 'push', ...
            'Tooltip', {'Recalculate the protocol''s validity from the text in the TextArea above'}, ...
            'Text', 'Recalculate');
        fig.RecalculateButton.Layout.Row = 3;
        fig.RecalculateButton.Layout.Column = 2;

        fig.RefreshButton = uibutton(fig.RightGrid, 'push', ...
            'Tooltip', {'Refresh the contents of the TextArea above to match the contents of the file it was loaded from'}, ...
            'Text', 'Refresh');
        fig.RefreshButton.Layout.Row = 3;
        fig.RefreshButton.Layout.Column = 1;

        fig.FilePathField = uieditfield(fig.RightGrid, 'text');
        fig.FilePathField.Layout.Row = 1;
        fig.FilePathField.Layout.Column = [1 2];

        fig.CopyLRBtn = uibutton(fig.GridLayout, 'push', ...
            'Tooltip', {'Expand to see full protocol text'}, ...
            'Text', '>');
        fig.CopyLRBtn.Layout.Row = 2;
        fig.CopyLRBtn.Layout.Column = 2;
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