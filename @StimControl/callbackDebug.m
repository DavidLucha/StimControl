function callbackDebug(obj, src, event)    
% obj.t.stop;
% obj.t.start;
path = 'C:\Users\labadmin\Desktop\logs\debug\251112\251112_161302_TempandVibe';
daqDataFile = '00011_stim00004.csv';
daqChannelNames = 'TriggerDAQ_channelNames.csv';
m = readmatrix([path filesep daqDataFile]);
timeAxis = m(:,1);
n = readcell([path filesep daqChannelNames]);
% t = table('VariableNames',[{'TimeMs'} n]);
% t.Data = m';
t = tiledlayout('flow');
t.TileSpacing = 'compact';
t.Padding = 'compact';
for i = 1:length(n)
    nexttile;
    plot(timeAxis, m(:,i+1));
    ylabel(n{i}, 'fontsize', 7);
    ax = gca;
    ax.XAxis.Visible = 'off'; 
end
keyboard;
disp("DEBUG");
end

function PlotSavedData()
    path = 'C:\Users\labadmin\Desktop\logs\debug\251112\251112_161302_TempandVibe';
    daqDataFile = '00011_stim00004.csv';
    daqChannelNames = 'TriggerDAQ_channelNames.csv';

end