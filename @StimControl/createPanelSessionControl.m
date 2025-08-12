function createPanelSessionControl(obj, hPanel, ~)

grid = uigridlayout(hPanel);
grid.RowHeight = {22, 22, '1x', 22, 22, '1x', 22, 22};
grid.ColumnWidth = {22, '1x', '1x', 22, 60, 36, 22};
grid.RowSpacing = 2;
nCols = length(grid.ColumnWidth);

%% create animal select section
aRow = 1;
animalSelect = uidropdown(grid, ...
    'Editable', 'on', 'Items', getFilesList(obj.path.dirData, ''), ...
    'ValueChangedFcn', @obj.callbackSelectAnimal);
animalSelect.Layout.Row = aRow + 1;
animalSelect.Layout.Column = [1 3];
obj.h.animalSelectDropDown = animalSelect;

newAnimalBtn = uibutton(grid, ...
    'ButtonPushedFcn', @obj.callbackNewAnimal, ...
    'Text', '+');
newAnimalBtn.Layout.Row = aRow + 1;
newAnimalBtn.Layout.Column = 4;

animalLabel = uilabel(grid, 'Text', 'Animal ID/Subfolder');
animalLabel.Layout.Row = aRow;
animalLabel.Layout.Column = [1 4];

%% create start/stop buttons
singleStimBtn = uibutton(grid, ...
    'Text', 'Single Stim', 'WordWrap', 'on', ...
    'ButtonPushedFcn', @obj.callbackSingleStim);
singleStimBtn.Layout.Row = [aRow aRow + 1];
singleStimBtn.Layout.Column = [nCols-1 nCols];
obj.h.singleStimBtn = singleStimBtn;

stimulateBtn = uibutton(grid, ...
    'Text', 'Start Protocol', 'WordWrap', 'on', ...
    'ButtonPushedFcn', @obj.callbackStimulate);
stimulateBtn.Layout.Row = [aRow aRow + 1];
stimulateBtn.Layout.Column = nCols-2;
obj.h.stimulateBtn = stimulateBtn;

%% create protocol section
protRow = 4;
protocolSelect = uidropdown(grid, ...
    'Editable', 'on', 'Items', getFilesList(obj.path.dirData, '.stim'), ...
    'ValueChangedFcn', @obj.callbackSelectProtocol);
protocolSelect.Layout.Row = protRow + 1;
protocolSelect.Layout.Column = [1 nCols-1];
obj.h.protocolSelectDropDown = protocolSelect;

newProtocolBtn = uibutton(grid, ...
    'ButtonPushedFcn', @obj.callbackNewProtocol, ...
    'Text', '+');
newProtocolBtn.Layout.Row = protRow + 1;
newProtocolBtn.Layout.Column = nCols;

protocolLabel = uilabel(grid, 'Text', 'Protocol');
protocolLabel.Layout.Row = protRow;
protocolLabel.Layout.Column = [1 4];

%%TODO TOTAL RUNTIME?!

%% Create trial info section
tRow = 7;
trialLabel = uilabel(grid, 'Text', 'Trial');
trialLabel.Layout.Row = tRow;
trialLabel.Layout.Column = [1 4];

prevTrialBtn = uibutton(grid, ...
    'ButtonPushedFcn', @obj.callbackPrevTrial, ...
    'Text', '<');
prevTrialBtn.Layout.Row = tRow + 1;
prevTrialBtn.Layout.Column = 1;

nextTrialBtn = uibutton(grid, ...
    'ButtonPushedFcn', @obj.callbackNextTrial, ...
    'Text', '>');
nextTrialBtn.Layout.Row = tRow + 1;
nextTrialBtn.Layout.Column = 4;

totalTrialsLabel = uilabel(grid, ...
    'Text', '/Total', 'HorizontalAlignment', 'Left');
totalTrialsLabel.Layout.Row = tRow + 1;
totalTrialsLabel.Layout.Column = 3;
obj.h.totalTrialsLabel = totalTrialsLabel;

trialNum = uieditfield(grid, 'numeric');
trialNum.Layout.Row = tRow + 1;
trialNum.Layout.Column = 2;
obj.h.trialNumDisplay = trialNum;
end