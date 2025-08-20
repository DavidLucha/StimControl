function createPanelPreview(obj, hPanel, ~)
numComponents = length(obj.h.Available);
numRows = floor(sqrt(numComponents));
numCols = ceil(numComponents/numRows);

obj.h.PreviewGrid = uigridlayout(hPanel);
if numRows > 1
    obj.h.PreviewGrid.RowHeight = repmat("1x", [1 numRows]);
    rowSpan = [1 numRows];
else
    obj.h.PreviewGrid.RowHeight = {'1x'};
    rowSpan = 1;
end
if numCols > 1
    obj.h.PreviewGrid.ColumnWidth = repmat("1x", [1 numCols]);
    colSpan = [1 numCols];
else
    obj.h.PreviewGrid.ColumnWidth = {'1x'};
    colSpan = 1;
end
obj.h.PreviewPanels = {};
obj.h.FullscreenPreviewAxes = uiaxes( ...
            obj.h.PreviewGrid, ...
            'Layout', matlab.ui.layout.GridLayoutOptions( ...
                'Row', rowSpan, ...
                'Column', colSpan), ...
            'Visible', false);
obj.h.FullscreenPreviewAxes.Title.String = "Preview";

for i = 1:numRows
    for j = 1:numCols
        componentIdx = ((i-1) * numRows) + j;
        ax = uiaxes( ...
            obj.h.PreviewGrid, ...
            'Layout', matlab.ui.layout.GridLayoutOptions( ...
                'Row', i, ...
                'Column', j), ...
            'XTick', [], ...
            'XTickLabel', [], ...
            'YTick', [], ...
            'YTickLabel', []);
        component = obj.h.Available{componentIdx};
        ax.Title.String = component.ConfigStruct.ID;
        obj.h.PreviewPanels{end+1} = ax;
        component.UpdatePreviewPlot(obj.h.PreviewPanels{end});
    end
end