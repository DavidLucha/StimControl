filename = 'C:\Users\labadmin\Documents\MATLAB\StimControl\config\experiment_protocols\Example_StimProtocol.stim';
if ~isfile(filename)
    filename = 'C:\Users\labadmin\OneDrive - The University of Queensland\Documents\MATLAB\StimControl\config\experiment_protocols\Example_StimProtocol.stim';
end
[p, g] = readProtocol(filename);
trial = p(1);