function runTrial(obj)
    % runs a single trial. Assumes trial dat is pre-loaded for each component.
    % use obj.callbackLoadTrial to make this a reality!
    % designed to be run in a thread so it's pausable.

    obj.status = 'running';
    % Set save prefixes
    savePrefix = sprintf("%05d_stim%05d", obj.trialIdx, obj.trialNum);
    for ci = 1:sum(obj.d.Active)
        component = obj.activeComponents{ci};
        component.SavePrefix = savePrefix;
    end

    % make pool of parallel workers.
    if isempty(gcp('nocreate'))
        obj.taskPool = parpool;
    end

    % Schedule component outputs
    % https://au.mathworks.com/matlabcentral/answers/322107-how-can-i-listen-for-completion-of-a-job
    nTasks = sum(obj.d.Active);
    futures = parallel.FevalFuture.empty(0, sum(nTasks)); % Preallocate array of Future objects
    for i = 1:sum(nTasks)
        component = obj.activeComponents{ci};
        futures(i) = parfeval(@component.Start, 1); % Schedule myFunction with 1 output
    end
    wait(futures);
    obj.trialIdx = obj.trialIdx + 1;

end
