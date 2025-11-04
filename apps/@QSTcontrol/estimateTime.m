function out = estimateTime(obj)

out = sum(([obj.p.tPre]+[obj.p.tPost]).*[obj.p.nRuns])/1000 + ...
    (length(obj.p)-1)*obj.g.dPause;