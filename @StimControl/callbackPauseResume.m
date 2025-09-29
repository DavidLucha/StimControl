function callbackPauseResume(obj, src, event)
if strcmpi(obj.status, 'paused')
    obj.f.resume = true;
else
    obj.f.pause = true;
end
end