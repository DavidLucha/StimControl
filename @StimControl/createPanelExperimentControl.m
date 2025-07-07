function createPanelExperimentControl(obj,hPanel,~)

% set panel position
hPanel.Title = 'Experiment Control';
hPanel.Layout.Row = 2;
hPanel.Layout.Column = [2 3];

%set up grid layout
grid = uigridlayout(hPanel);
grid.RowHeight = {22,22,'1x',22,22,'1x',22};
grid.ColumnWidth = {'1x', '1x', '2x', '1x', '1x'};
grid.RowSpacing = 2;
grid.ColumnSpacing = 5;

% animal selection
animalLabel = uilabel(grid);
animalLabel.Layout.Row = 1;
animalLabel.Layout.Column = [1 2];
animalLabel.Text = 'Animal';

newAnimalBtn = uibutton(grid);
newAnimalBtn.Layout.Row = 1;
newAnimalBtn.Layout.Column = 3;
newAnimalBtn.ButtonPushedFcn = @obj.callbackNewAnimal;
newAnimalBtn.Text = 'New Animal';

animalDropDown = uidropdown(grid);
animalDropDown.Layout.Row = 2;
animalDropDown.Layout.Column = [1 3];
animalDropDown.Items = {'hello'};
animalDropDown.Editable = 'on';
obj.h.animalDropDown = animalDropDown;

% experiment selection
experimentLabel = uilabel(grid);
experimentLabel.Layout.Row = 4;
experimentLabel.Layout.Column = [1 2];
experimentLabel.Text = 'Experiment';

newExperimentBtn = uibutton(grid);
newExperimentBtn.Layout.Row = 4;
newExperimentBtn.Layout.Column = 3;
newExperimentBtn.ButtonPushedFcn = @obj.callbackNewExperiment;
newExperimentBtn.Text = 'New Experiment';

experimentDropDown = uidropdown(grid);
experimentDropDown.Layout.Row = 5;
experimentDropDown.Layout.Column = [1 3];
experimentDropDown.Items = {'hi'};
experimentDropDown.Editable = 'on';
obj.h.experimentDropDown = experimentDropDown;

% trial number information
trialNrLabel = uilabel(grid);
trialNrLabel.Layout.Row = 7;
trialNrLabel.Layout.Column = 1;
trialNrLabel.Text = 'TrialNr';

trialNr = uilabel(grid);
trialNr.Layout.Row = 7;
trialNr.Layout.Column = 2;
trialNr.Text = 'X/X';
obj.h.trialNrDisplay = trialNr;

newTrialBtn = uibutton(grid);
newTrialBtn.Layout.Row = 7;
newTrialBtn.Layout.Column = 3;
newTrialBtn.ButtonPushedFcn = @obj.callbackNewTrial;
newTrialBtn.Text = 'New Trial';

% start/stop buttons
startExperimentBtn = uibutton(grid);
startExperimentBtn.Layout.Row = [1 2];
startExperimentBtn.Layout.Column = [4 5];
startExperimentBtn.ButtonPushedFcn = @obj.callbackStartExperiment;
startExperimentBtn.Text = 'Start Experiment';
obj.h.startExperimentBtn = startExperimentBtn;

singleStimBtn = uibutton(grid);
singleStimBtn.Layout.Row = [4 5];
singleStimBtn.Layout.Column = [4 5];
singleStimBtn.ButtonPushedFcn = @obj.callbackStartSingleStim;
singleStimBtn.Text = 'Start Single Stim';
obj.h.singleStimBtn = singleStimBtn;

% status indicator
statusLamp = uilamp(grid);
statusLamp.Layout.Row = 7;
statusLamp.Layout.Column = 4;
obj.h.statusLamp = statusLamp;

statusLabel = uilabel(grid);
statusLabel.Layout.Row = 7;
statusLabel.Layout.Column = 5;
statusLabel.Text = 'Status';
statusLabel.HorizontalAlignment = 'left';
statusLabel.VerticalAlignment = 'center';
statusLabel.WordWrap = 'on';
statusLabel.FontSize = 9;
obj.h.statusLabel = statusLabel;