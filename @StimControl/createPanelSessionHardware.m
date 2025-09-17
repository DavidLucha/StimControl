function createPanelSessionHardware(obj, hPanel, ~)
numComponents = sum(obj.d.Active);
grid = uigridlayout(hPanel);
grid.RowHeight = {20, 22, 22, '1x'};
grid.ColumnWidth = repmat({'1x'}, 1, numComponents);
grid.RowSpacing = 2;
nCols = length(grid.ColumnWidth);
nRows = length(grid.RowHeight);

end