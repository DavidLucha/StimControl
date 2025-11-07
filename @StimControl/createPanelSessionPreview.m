function createPanelSessionPreview(obj, hPanel, ~)

numComponents = obj.d.nActive;
numRows = floor(sqrt(numComponents));
numCols = ceil(numComponents/numRows);

% if the display is beingpdated and not created, flag that component preview plots
% should also be updated.
updatePlots = isfield(obj.h.Session, 'PreviewGrid');

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
doNothing = @(x, y, z) true;
for i = 1:numRows
    for j = 1:numCols
        componentIdx = ((i-1) * numCols) + j;
        if obj.d.nActive < componentIdx
            return
        end
        panel = uipanel(obj.h.Session.PreviewGrid, ...
            'CreateFcn', doNothing,...
            'Layout', matlab.ui.layout.GridLayoutOptions( ...
                'Row', i, ...
                'Column', j));
        panelGrid = uigridlayout(panel, ...
            'RowHeight', {'1x'}, ...
            'ColumnWidth', {'1x'});
        ax = uiaxes(panelGrid, ...
            'Layout', matlab.ui.layout.GridLayoutOptions( ...
                'Row', 1, ...
                'Column', 1), ...
            'XTick', [], ...
            'XTickLabel', [], ...
            'YTick', [], ...
            'YTickLabel', []);
        component = obj.d.activeComponents{componentIdx};
        panel.Title = component.ConfigStruct.ProtocolID;
        obj.h.Session.PreviewPanels{end+1} = ax;
        if updatePlots
            component.UpdatePreview('newPlot', obj.h.Session.PreviewPanels{end});
        end
    end
end
end