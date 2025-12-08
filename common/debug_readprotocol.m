filename = 'C:\Users\labadmin\Documents\MATLAB\StimControl\config\experiment_protocols\Example_StimProtocol.stim';
if ~isfile(filename)
    filename = 'C:\Users\labadmin\OneDrive - The University of Queensland\Documents\MATLAB\StimControl\config\experiment_protocols\Example_StimProtocol.stim';
end
[p, g] = readProtocol(filename);
trial = p(1);

for trialIdx = 1:length(p)
    params = p(trialIdx).params;
    
end


% 
% function seq = generateSequence(obj)
% tmp = arrayfun(@(x,y) {ones(1,x)*y},[obj.p.nRuns],1:length(obj.p));
% tmp = [tmp{:}];
% if obj.g.rand > 0
%     if obj.g.rand == 2
%         rng(0)
%     else
%         rng('shuffle')
%     end
%     seq = [];
%     for ii = 1:obj.g.nProtRuns
%         seq = [seq tmp(randperm(length(tmp)))]; %#ok<AGROW>
%     end
% else
%     seq = repmat(tmp,1,obj.g.nProtRuns);
% end
% end
% 
% %% Helpers
% function targets = getAllTargets(p)
%     targets = {};
%     for i = 1:length(p)
%         fds = fields(p(i).params);
%         for j = 1:length(fds)
%             if ~any(contains(targets, fds{j}))
%                 targets{end+1} = fds{j};
%             end
%         end
%     end
% end