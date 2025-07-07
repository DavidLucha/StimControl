function createPanelStatusDisplay(obj,hPanel,~)

%set panel position
hPanel.Layout.Row = 3;
hPanel.Layout.Column = 3;

%set up grid layout
grid = uigridlayout(hPanel);
grid.RowHeight = {'1x'};
grid.ColumnWidth = {'1x'};

% LOGO
% [img,~,alpha] = imread('chicken.png');
% obj.h.LED.chicken = axes(hPanel, ...
%     'Units',        'pixels', ...
%     'Position',     [hPanel.Position(3)-size(img,2)-10 7 size(img,2) size(img,1)], ...
%     'Color',        'none');
% axis equal
% f = imshow(img);
% set(f,'AlphaData', alpha);
% logo = uiimage();
% logo.
