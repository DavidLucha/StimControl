function createPanelSessionHardware(obj, hPanel, ~)
numComponents = sum(obj.d.Active);
grid = uigridlayout(hPanel);
grid.RowHeight = {'1x'};
grid.ColumnWidth = repmat({'1x'}, 1, numComponents);
grid.RowSpacing = 2;
nCols = length(grid.ColumnWidth);
nRows = length(grid.RowHeight);
for i = 1:numComponents
    component = obj.activeComponents{i};
    component.statusPanel = uipanel(grid, ...
        'Layout', matlab.ui.layout.GridLayoutOptions( ...
        'Row', 1, ...
        'Column', i));
    component.CreateStatusDisplay;
end
obj.h.SessionHardwareGrid = grid;
end