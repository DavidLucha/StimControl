function callbackDebug(obj, src, event)    
keyboard;
% da = obj.d.Available{1};
% da = da.SessionHandle;
% for i = 1:20
%     da.write([1 1 1 1]);
%     pause(0.5);
%     da.write([0 0 0 0]);
% end
% % runTrial(obj);
disp("DEBUG");
keyboard;
end

function runTrial(obj)
    % runs a single trial. Assumes trial dat is pre-loaded for each component.
    % use obj.callbackLoadTrial to make this a reality!
    % designed to be run in a thread so it's pausable.
    
    obj.d.executionTimer = timer(...
            'StartDelay',       0, ...
            'Period',           300, ...
            'ExecutionMode',    'fixedRate', ...
            'TimerFcn',         @testRun);
    start(obj.d.executionTimer);
end

function testRun(obj, ~, ~)
    disp("BOO");
end

function trialStop(obj)
    obj.status = 'loading';
    for i = 1:length(obj.activeComponents)
        component = obj.activeComponents{i};
        component.Stop();
    end
    obj.status = 'ready';
end