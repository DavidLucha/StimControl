function callbackDebug(obj, src, event)    
keyboard;
% runTrial(obj);
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