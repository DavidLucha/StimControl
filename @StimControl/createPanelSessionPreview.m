function createPanelSessionPreview(obj, hPanel, ~)
numComponents = length(obj.d.Available);
numRows = floor(sqrt(numComponents));
numCols = ceil(numComponents/numRows);

obj.h.Session.PreviewGrid = uigridlayout(hPanel);
if numRows > 1
    obj.h.Session.PreviewGrid.RowHeight = repmat("1x", [1 numRows]);
    rowSpan = [1 numRows];
else
    obj.h.Session.PreviewGrid.RowHeight = {'1x'};
    rowSpan = 1;
end
if numCols > 1
    obj.h.Session.PreviewGrid.ColumnWidth = repmat("1x", [1 numCols]);
    colSpan = [1 numCols];
else
    obj.h.Session.PreviewGrid.ColumnWidth = {'1x'};
    colSpan = 1;
end
obj.h.Session.PreviewPanels = {};
obj.h.Session.FullscreenPreviewAxes = uiaxes( ...
            obj.h.Session.PreviewGrid, ...
            'Layout', matlab.ui.layout.GridLayoutOptions( ...
                'Row', rowSpan, ...
                'Column', colSpan), ...
            'Visible', false);
obj.h.Session.FullscreenPreviewAxes.Title.String = "Preview";

for i = 1:numRows
    for j = 1:numCols
        componentIdx = ((i-1) * numRows) + j;
        ax = uiaxes( ...
            obj.h.Session.PreviewGrid, ...
            'Layout', matlab.ui.layout.GridLayoutOptions( ...
                'Row', i, ...
                'Column', j), ...
            'XTick', [], ...
            'XTickLabel', [], ...
            'YTick', [], ...
            'YTickLabel', []);
        component = obj.d.Available{componentIdx};
        ax.Title.String = component.ConfigStruct.ID;
        obj.h.Session.PreviewPanels{end+1} = ax;
        % component.UpdatePreviewPlot(obj.h.Session.PreviewPanels{end});
    end
end