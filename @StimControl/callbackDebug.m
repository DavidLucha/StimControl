function callbackDebug(obj, src, event)    
keyboard;
testfcn(obj);
disp("DEBUG");
keyboard;
end

function testfcn(obj)
if isempty(gcp('nocreate'))
    p = parpool;
else
    p= gcp('nocreate');             % this takes a while to initialise.
end

experimentThread = parfeval(p, @testExperiment, 0, obj);
disp("GREAT SUCCESS");
end

function out = testExperiment(test)
out = "SECOND SUCCESS";`
end