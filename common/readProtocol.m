function [p,g] = readProtocol(filename,varargin)

% NB THINGS TO VALIDATE:
% hardware is not targeted by two functions simultaneously
% oddball params are valid: 
    % with buffers, it's physically possible to leave a buffer of x stims at nstims y and swap ratio z

%% parse inputs
ip = inputParser;
addRequired(ip,'filename',...
    @(x)validateattributes(x,{'char'},{'nonempty'}));
parse(ip,filename,varargin{:});

%% read file
if ~exist(ip.Results.filename,'file')
    error('File not found: %s',ip.Results.filename)
end
pathBase = ip.Results.filename(1:find(ip.Results.filename == filesep, 1,'last'));
fid   = fopen(ip.Results.filename);
lines = textscan(fid,'%s','Delimiter','\n','MultipleDelimsAsOne',1);
fclose(fid);
lines = lines{1};

%% remove comment lines
lines(cellfun(@(x) strcmp(x(1),'%'),lines)) = [];

%% define defaults
g = struct(...              % general parameters
    'dPause',               5,...
    'nProtRuns',            1,...
    'rand',                 0);
defaultTrial = struct( ...
    'nRuns',                1, ...
    'tPre',                 1000, ...
    'tPost',                5000);

validTrialParams = struct("tPre", false, ... % param and whether it's already been initialised
    "tPost", false, ...
    "nTrialRuns", false);

validStimBlockParams = struct(...
    "OddDistr", false, ...
    "OddMinDist", false, ...
    "repDel", false, ...
    "nStims", false, ...
    "startDel", false);

BaseStimStructs = struct(...
    'qst', struct( ...
        'identifier', 'QST', ....
        'type', 'serial', ...
        'targetDevices', ["QST"], ...
        'isAcquisitionTrigger', false, ...
        'duration', 0, ...
        'commands', struct(...
            'NeutralTemp',          32,...    
            'PacingRate',           ones(1,5) * 999,...
            'ReturnSpeed',          ones(1,5) * 999,...
            'SetpointTemp',         ones(1,5) * 32,...
            'SurfaceSelect',        true(1,5),...
            'dStimulus',            ones(1,5) * 1000,...
            'integralTerm',         1,...
            'nTrigger',             255,...
            'VibrationDuration',    0)), ...
    'serial', struct( ...
        'identifier', '', ....
        'type', 'serial', ...
        'targetDevices', [], ...
        'isAcquisitionTrigger', false, ...
        'duration', 0, ...
        'commands', []), ...
    'pwm', struct( ...
        'type', 'PWM', ...
        'identifier', '', ...
        'targetDevices', [], ...
        'isAcquisitionTrigger', false, ...
        'duration', 0, ...
        'rampUp', 0, ...
        'rampDown', 0, ...
        'frequency', 25, ...
        'dutyCycle', 50), ...
    'piezo', struct( ...
        'identifier', 'piezoStim', ....
        'type', 'piezo', ...
        'targetDevices', ["Aurora"], ...
        'isAcquisitionTrigger', false, ...
        'duration', 0, ...
        'frequency', 0, ...
        'stimNum', 0, ...
        'amplitude', 0, ...
        'ramp', 20, ...
        'nStims', 0), ...
    'digitaltrigger', struct( ...
        'type', 'digitalTrigger', ...
        'identifier', '', ...
        'targetDevices', [], ...
        'isAcquisitionTrigger', false, ...
        'duration', 0, ...
        'frequency', 20), ...
    'digitalpulse', struct( ...
        'type', 'digitalPulse', ...
        'identifier', '', ...
        'targetDevices', [], ...
        'isAcquisitionTrigger', false, ...
        'duration', 0), ...
    'analogpulse', struct( ...
        'type', 'analogPulse', ...
        'identifier', '', ...
        'targetDevices', [], ...
        'isAcquisitionTrigger', false, ...
        'duration', 0, ...
        'rampOn', 0, ...
        'rampOff', 0, ...
        'baseAmp', 0, ...
        'pulseAmp', 10), ...
    'sinewave', struct( ...
        'type', 'sineWave', ...
        'identifier', '', ...
        'targetDevices', [], ...
        'isAcquisitionTrigger', false, ...
        'duration', 0, ...
        'amplitude', 0, ...
        'frequency', 30, ...
        'phase', 0, ...
        'verticalShift', 0, ...
        'amplitudeMod', 1), ...
    'analognoise', struct( ...
        'type', 'analogNoise', ...
        'identifier', '', ...
        'targetDevices', [], ...
        'isAcquisitionTrigger', false, ...
        'duration', 0, ...
        'maxAmplitude', 10, ...
        'minAmplitude', -10, ...
        'distribution', 'normal'), ... %either normal or uniform
    'arbitrary', struct( ...
        'type', 'arbitrary', ...
        'identifier', '', ...
        'targetDevices', [], ...
        'isAcquisitionTrigger', false, ...
        'duration', 0, ...
        'filename', '', ...
        'interpolate', false), ...
    'squarewave', struct( ...
        'type', 'squareWave', ...
        'identifier', '', ...
        'targetDevices', [], ...
        'isAcquisitionTrigger', false, ...
        'duration', 0, ...
        'frequency', 20, ...
        'pulseWidth', 0.5, ...
        'maxAmp', 10, ...
        'minAmp', -10)); %TODO RAMP???

validProtocolParams = struct(... %fields: valid params in protocol file. values: associated internal struct params.
    'pwm', struct( ...
        'Dur', 'duration', ...
        'Freq', 'frequency', ...
        'DC', 'dutyCycle', ...
        'RampOnDur', 'rampUp', ...
        'RampOffDur', 'rampDown'), ...
    'piezo', struct(...
        'Dur', 'duration', ...
        'Freq', 'frequency', ...
        'stimNum', 'stimNum', ...
        'Amp', 'amplitude', ...
        'Ramp', 'ramp', ...
        'nStims', 'nStims'), ...
    'digitaltrigger', struct(  ...
        'Dur', 'duration', ...
        'Freq', 'frequency'), ...
    'digitalpulse', struct( ...
        'Dur', 'duration'), ...
    'analogpulse', struct(...
        'Dur', 'duration', ...
        'RampOnDur', 'rampOn', ...
        'RampOffDur', 'rampOff', ...
        'Amp', 'pulseAmp', ...
        'BaseAmp', 'baseAmp'), ...
    'sinewave', struct(...
        'Dur', 'duration', ...
        'Amp', 'amplitude', ...
        'Freq', 'frequency', ...
        'Phase', 'phase', ...
        'VShift', 'verticalShift', ...
        'AmpMod', 'amplitudeMod'), ... %nb special case? todo, low prio, just don't implement for now
    'analognoise', struct( ...
        'Dur', 'duration', ...
        'Max', 'maxAmplitude', ...
        'Min', 'minAmplitude', ...
        'Distr', 'distribution'), ... 
    'arbitrary', struct( ...
        'Dur', 'duration', ...
        'Src', 'filename', ... %nb special case
        'Interp', 'interpolate'), ...
    'squarewave', struct( ...
        'Dur', 'duration', ...
        'Max', 'maxAmp', ...
        'Min', 'minAmp', ...
        'Freq', 'frequency', ...
        'PW', 'pulseWidth'));

oddballParams = struct(...
    'distributionMethod', 'random', ... %0=even / 1=random / 2=semirandom 
    'minSwapDist', 0, ...
    'swapRatio', 0.5, ...
    'oddballRel', 'rand'); % rand / seq - | or |> 

splitIdxes = find(startsWith(lines, '~'));
if length(splitIdxes) ~= 2
    error("Sections should be separated with a tilde (~) character on a new line. " + ...
        "Refer to the wiki for a full overview of formatting requirements: " + ...
        "https://github.com/WhitmireLab/StimControl/wiki/Protocols");
end

trialParams = lines(splitIdxes(1)+1:splitIdxes(2)-1);
stimDefinitions = lines(splitIdxes(2)+1:end);

%% Parse general specs
if splitIdxes(1) > 1
    if splitIdxes(1) > 2
        error("General params should be defined in a single line.");
    end
    generalParams = lines{1:splitIdxes(1)-1};
    [generalParams,~]  = strtok(generalParams,'%');
    generalParams      = strtrim(generalParams);
    while ~isempty(generalParams)
        [token,generalParams] = strtok(generalParams); %#ok<STTOK>
        tmp = regexpi(token,'^([a-z]+)(-?\d+)$','once','tokens');
        if ~isempty(tmp)
            val = str2double(tmp(2));
            switch lower(tmp{1})
                case 'nprotruns'
                    validateattributes(val,{'numeric'},{'positive'},...
                        mfilename,token)
                    g.nProtRuns = val;
                    continue
                case 'rand'
                    validateattributes(val,{'numeric'},{'nonnegative',...
                        '<=',2},mfilename,token)
                    g.rand = val;
                    continue
                case 'dpause'
                    validateattributes(val,{'numeric'},{'nonnegative'},...
                        mfilename,token)
                    g.dPause = val;
                    continue
                case 'ntrialruns'
                    validateattributes(val,{'numeric'},{'nonnegative'},...
                        mfilename,token)
                    defaultTrial.nRuns = val;
                    continue
                case 'tpre'
                    validateattributes(val,{'numeric'},{'nonnegative'},...
                        mfilename,token)
                    defaultTrial.tPre = val;
                    continue
                case 'tpost'
                    validateattributes(val,{'numeric'},{'nonnegative'},...
                        mfilename,token)
                    defaultTrial.tPost = val;
                continue
            end
        end
        error('Unknown parameter "%s"',token)
    end
end

stimuli = [];

%% parse stimulus definitions
for idxStim = 1:length(stimDefinitions)
    line = stimDefinitions{idxStim};
    % todo support for targeting specific channels connected to the same defice (e.g. Widefield1_Trigger)
    % note - this is way harder than it sounds. We're gonna name our channels individually for now.
    tmp = regexpi(line, '([A-z])*\((\w)+\)\[((\w)(-\w)?,? ?)+\]: ?(.*)(%.*)?', 'tokens', 'once'); 
    % note to future devs: sorry about this ^. There are some regex testers out there that can help with reading this.
    % I've been using https://regexr.com/
    [stimID, stimType, targets, params, comment] = tmp{:};
    stimType = lower(stimType);
    if isfield(stimuli, stimID)
        error("Stimulus defined twice: %s", stimID);
    end
    if ~contains(fields(BaseStimStructs), stimType)
        error("Unknown stimulus type: %s. Valid types: %s", stimType, GetListFromArray(fields(BaseStimStructs)));
    end
    % special cases
    switch lower(stimType)
        case 'qst'
            stimStruct = ParseQST(params, BaseStimStructs.(stimType), stimID);
        case 'serial'
            stimStruct = ParseSerial(params, BaseStimStructs.(stimType), stimID);
        otherwise
            % standard cases
            stimStruct = BaseStimStructs.(stimType);
            while ~isempty(params)
                [tok, remain] = strtok(params);
                pv = regexpi(tok, '([A-z]*)(-?\d*.?\d*)', 'tokens', 'once');
                [param, val] = pv{:};
                if strcmpi(param, 'acquisitiontrigger')
                    stimStruct.isAcquisitionTrigger = true;
                    params = remain;
                    continue
                elseif isempty(val) || isnan(str2double(val))
                    if strcmpi(stimType, 'arbitrary')
                        % probably the filename
                        param = 'Src';
                        val = tok;
                        if ~contains(val, filesep)
                            % expand to full filepath
                            val = [pathBase val];
                        end
                    else
                        error("No value provided for %s:%s", stimID, stimType);
                    end
                elseif ~contains(fields(validProtocolParams.(stimType)), param)
                    error("Invalid parameter for %s: %s. Valid parameters are: %s", ...
                        stimID, param, GetListFromArray(fields(validProtocolParams.(stimType))));
                end
                val = ValidateParam(val, param, stimID);
                stimStruct.(validProtocolParams.(stimType).(param)) = val;
                params = strtrim(remain);
            end
    end
    stimuli.(stimID) = stimStruct;
    if contains(targets, ',')
        targets = string(strtrim(split(targets, ',')))';
    end
    stimuli.(stimID).targetDevices = string(targets); % todo convert to array of strings if length > 1
end

trials = {};
%% Parse trials (eek!)
for idxTrial = 1:length(trialParams)
    % initialise
    line = trialParams{idxTrial};
    [params, comment] = strtok(line, '%');
    params = strtrim(params);
    comment = strtrim(comment(2:end));
    trialParamsTracker = validTrialParams;
    
    % Sanitise line (add spaces around everything)
    sepQuery = '&|>|(\|>)|(\^\.\d?)';
    [startIdxes, endIdxes] = regexpi(params, [sepQuery '|\)|\(']);
    for i = 0:length(startIdxes)-1
        l = length(startIdxes);
        startIdx = startIdxes(l-i);
        endIdx = endIdxes(l-i);
        if endIdx ~= length(params) && ~strcmpi(params(endIdx + 1), ' ')
            params = insertAfter(params, endIdx, ' ');
        end
        if startIdx ~= 1 && ~strcmpi(params(startIdx - 1), ' ')
            params = insertBefore(params, startIdx, ' ');
        end
    end

    % initialise stack vars
    trial = TrialData( ...
        'tPre', defaultTrial.tPre, ...
        'tPost', defaultTrial.tPost, ...
        'nRuns', defaultTrial.nRuns, ...
        'comment', comment);
    stack = java.util.Stack;
    stack.push(1); % push root node index to stack
    tree = {StimulusBlock()};

    paramTokens = split(params, ' ');

    % ENTER THE STACK ZONE
    for i = 1:length(paramTokens)
        token = paramTokens{i};
        [name, value] = regexpi(token, '(\w*)(\d*)', 'tokens');
        value = str2double(value);
        currentParentIdx = stack.pop();
        currentParent = tree{currentParentIdx};
        % do the stuff that doesn't require parsing first because otherwise we'll throw an error
        if token == '('
            % Start of a new block. Make a new parent node.
            stack.push(currentParentIdx);
            tree{end+1} = StimulusBlock();
            currentParent.childIdxes(end+1) = length(tree);
            tree{currentParentIdx} = currentParent;
            stack.push(length(tree));
            continue
        elseif token == ')'
            % End of a block. Remove the parent's index from the stack and
            % update the next parent's child indices.
            newParentIdx = stack.pop();
            currentParent = tree{newParentIdx};
            currentParent.childIdxes(end+1) = currentParentIdx;
            currentParentIdx = newParentIdx;
        elseif regexpi(token, sepQuery)
            % Separator. Set parent's child relationship
            if token(1) == '&'
                childRel = 'sim';
            elseif token(1) == '>'
                childRel = 'seq';
            elseif token(1) == '|'
                if strcmpi(token, '|>')
                    childRel = 'oddSeq'; %TODO IMPLEMENT IN STIMULUSBLOCK
                else
                    childRel = 'oddRan'; %TODO IMPLEMENT IN STIMULUSBLOCK
                end
            else % ^.X
                childRel = 'odd';
                currentParent.oddballParams.swapRatio = str2double(['0.' token(3:end)]);
            end
            if ~isempty(currentParent.childRel) && ~strcmpi(currentParent.childRel, childRel)
                error("Syntax error in trial line %d (%s): Only one relationship type may exist per stim block. " + ...
                    "In oddball paradigms with multiple oddballs, put all oddball " + ...
                    "stimuli into their own bracket block within the oddball block."+ ...
                    "(relationships defined: %s, %s)", ...
                    idxTrial, comment, currentParent.childRel, childRel); 
            else
                currentParent.childRel = childRel;
            end
            % update parent in tree
            tree{currentParentIdx} = currentParent;
        elseif isfield(stimuli, token)
            % leaf (stimulus) node. Create child node and push, add index to current parent
            newNode = StimulusBlock('stimParams', stimuli.(token));
            tree{end+1} = newNode;
            currentParent.childIdxes(end+1) = length(tree);
            tree{currentParentIdx} = currentParent;
        elseif isfield(trialParamsTracker, name)
            % set trial data (and check it hasn't already been set)
            if trialParamsTracker.(name)
                error("Invalid syntax on trial line %d (%s): %s can only be defined once per trial.", ...
                    idxTrial, comment, name);
            else
                trialParamsTracker.(name) = true;
                trial.(name) = value; % todo check this works all the time, I think it does
            end
        elseif isfield(validStimBlockParams, name)
            % params for current parent! set em.
            switch lower(name)
                case 'odddistr'
                    % some syntax checking
                    if ~strcmpi(currentParent.childRel, 'odd')
                        % gotta be an oddball to use this
                        error("Invalid syntax on trial definition line %d (%s): " + ...
                            "OddDistrX is set, but the relationship for its stimulus block is not oddball (^.X)", idxTrial, comment);
                    end
                    if value == 0
                        currentParent.oddParams.distributionMethod = 'even';
                    elseif value == 1
                        currentParent.oddParams.distributionMethod = 'random';
                    elseif value == 2
                        if (~isfield(currentParent.oddParams, 'distributionMethod') || ...
                            currentParent.oddParams.distributionMethod(1) ~= 's') && ...
                            ~contains(lower(params), 'oddmindist')
                                % can't set semirandom without also setting a minimum distance
                                error("Invalid syntax on trial definition line %d (%s): " + ...
                                    "to make oddball distribution semirandom, you must also define the minimum distance between oddballs using OddMinDistX. " + ...
                                    "Add this parameter or change to another OddDistr (0=even, 1=random, 2=semirandom)", idxTrial, comment);
                        end
                    else
                        error("Invalid syntax on trial definition line %d (%s): " + ...
                            "OddDistrX accepts X values 0=even, 1=random, 2=semirandom", idxTrial, comment);
                    end
                case 'oddmindist'
                    % some syntax checking.
                    if ~strcmpi(currentParent.childRel, 'odd')
                        % gotta be an oddball to use this
                        error("Invalid syntax on trial definition line %d (%s): " + ...
                            "OddMinDistX is set, but the relationship for its stimulus block is not oddball (^.X).", idxTrial, comment);
                    elseif isfield(currentParent.oddParams, 'distributionMethod')
                        % shouldn't be set! likely the wrong kind of oddball distribution method.
                        error("Invalid syntax on trial definition line %d (%s): " + ...
                            "OddMinDistX is set, but the OddDistr value for its stimulus block is not semirandom (OddDistr2).", idxTrial, comment);
                    end
                    currentParent.oddParams.distributionMethod = ['semirandom' char(string(value))];
                case 'repdel'
                    currentParent.repeatDelay = value;
                case 'nstims'
                    currentParent.nStimRuns = value;
                case 'startdel'
                    currentParent.startDelay = value;
            end
            tree{currentParentIdx} = currentParent;
        else
            % crime detected!
             error("Invalid parameter on trial definition line %d (%s): %s. " + ...
                "Parameters must be a stimulis defined in the stimulus section " + ...
                "or one of the following: %s", idxTrial, comment, tkName, ...
                GetListFromArray(fields(validTrialParams)));
        end
        % put parent back on the stack
        stack.push(currentParentIdx);
        % plotTree(tree, stack, comment, idxTrial);
    end
    % clear the stack - todo is this necessary?
    while ~stack.empty
        childIdx = stack.pop;
        if ~stack.empty
            parentIdx = stack.pop();
            parent = tree{parentIdx};
            parent.childIdxes(end+1) = childIdx;
            stack.push(parentIdx);
        end
    end
    plotTree(tree, stack, line, idxTrial);
    tree = CleanTree(tree);
    trial.data = tree;
    trial.generateParamsSequence;
    trials{end+1} = trial;
end
p = [trials{:}];

function CleanTree(tree)
    idxesToRemove = [];
    newChildren = repmat({}, [1 length(tree)]);
    idxOffsets = zeros([1 length(tree)]);
    for ti =1:length(tree)
        block = obj.StimulusBlocks{ti};
        if isempty(block.childRel) && isempty(block.stimParams)
            % this is an empty block!! kill it!!
            newChildren{ti} = block.childIdxes;
            idxesToRemove(end+1) = ti;
            idxOffsets(ti:end) = idxOffsets(ti) - 1;
        end
    end
    if ~isempty(idxesToRemove)
        for ti = 1:length(obj.StimulusBlocks)
            block = obj.StimulusBlocks{ti};
            if ~isempty(block.childIdxes)
                % check if any block children are going to be deleted. If
                % yes, transfer that child's children.
                blockNewChildren = newChildren{block.childIdxes};
                for tj = 1:length(blockNewChildren)
                    block.childIdxes = [block.childIdxes blockNewChildren{tj}];
                end
                % update childIdxes to new tree
                block.childIdxes = block.childIdxes+idxOffsets(block.childIdxes);
            end
            tree{ti} = block;
        end
    end
    % remove blank nodes.
    tree{idxesToRemove} = [];
end

function plotTree(tree, stck, comment, trialIdx)
    dat = zeros([1 length(tree)]);
    labels = repmat({}, [1 length(tree)]);
    for j = 1:length(tree)
        node = tree{j};
        if ~isempty(node.childIdxes)
            dat(node.childIdxes) = j;
        end
        if ~isempty(node.stimParams)
            target = strjoin(node.stimParams.targetDevices);
            len = min([length(char(target)) 5]);
            t = char(target);
            target = string(t(1:len));
        else
            target = "";
        end
        labels{j} = sprintf("%d-%s-%s", j, string(node.childRel), target);
    end
    treeplot(dat);
    [x,y] = treelayout(dat);
    text(x + 0.02,y,labels);
    title(sprintf("%s: %d", comment, trialIdx));
    disp(stck);
end

%% Helper functions
function stimStruct = ParseArbitrary(params, stimStruct, stimName)
    tmp = regexpi(tok, '^([A-Z]*)(\:)(.*)$', 'once', 'tokens');
    id = tmp{1};
    filename = tmp{3};
    % extend filename if necessary
    if ~contains(filename, ':')
        % referenced in relation to location of protocol file
        % standardise fileseps
        filename = replace(filename,'/',filesep);
        filename = replace(filename,'\',filesep);
        % extend to full path
        filename = [pathBase filename];
    end
    % read file
    if ~exist(filename,'file')
        error('File not found: %s',filename)
    end
    fid   = fopen(filename);
    lines = textscan(fid,'%s','Delimiter','\n','MultipleDelimsAsOne',1);
    fclose(fid);
    lines = lines{1};
    
    % remove comment lines
    lines(cellfun(@(x) (strcmp(x(1),'%') || strcmp(x(2), '%')) ,lines)) = [];
    try
        type = lower(lines{1});
        protocol = str2num(lines{2});
    catch
        error("Invalid protocol in file %s. Protocol line should have only numbers", filename);
    end
    if ~contains(['digital', 'analog'], type)
        error("invalid data type %s in file %s", type, filename);
    end
    p(idxStim).(id).type = type;
    p(idxStim).(id).filename = filename;
    p(idxStim).(id).data = protocol;
end

function stimStruct = ParseQST(params, stimStruct, stimName)
    while ~isempty(params)
        [tok, remain] = strtok(params);
        switch tok(1)
            case 'N'
                fieldname = 'NeutralTemp';
                value     = readRangeThermode(tok,2:4,[200 500],stimName)/10;
            case 'S'
                fieldname = 'SurfaceSelect';
                value     = tok(2:6)=='1';
            case 'C'
                fieldname = 'SetpointTemp';
                value     = readRangeThermode(tok,3:5,[0 600],stimName)/10;
            case 'V'
                fieldname = 'PacingRate';
                value     = readRangeThermode(tok,3:6,[1 9990],stimName)/10;
            case 'R'
                fieldname = 'ReturnSpeed';
                value     = readRangeThermode(tok,3:6,[100 9990],stimName)/10;
            case 'D'
                fieldname = 'dStimulus';
                value     = readRangeThermode(tok,3:7,[10 99999],stimName);
            case 'T'
                fieldname = 'nTrigger';
                value     = readRangeThermode(tok,2:4,[0 255],stimName);
            case 'I'
                fieldname = 'integralTerm';
                value     = tok(2)=='1';
        end
        stimStruct.commands.(fieldname) = value;
        params = remain;
    end
end

function value = readRangeThermode(token,pos,range,stimName)
value = str2double(token(pos));
if value<range(1) || value>range(2)
    x = sprintf('%%0%dd',max(arrayfun(@(x) length(num2str(x)),range)));
    format = subsasgn(token,struct('type','()','subs',{{pos}}),'X');
    error(['Faulty parameter "%s" for stimulus #%d (%s, valid ' ...
        'range for %s: ' x '-' x ')'],token,stimName,format,...
        repmat('X',1,length(pos)),range(1),range(2))
end
end

function val = ValidateParam(val, paramName, stimName)
    if ~strcmpi(paramName, 'src')
        val = str2double(val);
    end
    switch lower(paramName)
    case 'dur'
        if ~val>0 && v~=-1
            error("Invalid duration for %s: %s. Duration should be a positive number of ms, or -1", stimName, val);
        end
    case 'freq'
        if ~val>0
            error("Invalid frequency for %s: %s. Frequency should be positive.", stimName, val);
        end
    case 'src'
        % check if filepath exists
        if ~isfile(val)
            error("Unable to find file %s for %s.", val, stimName);
        end
    case 'distr'
        if val == 1
            val = 'normal';
        elseif val == 0
            val = 'uniform';
        else
            error("Invalid distribution for %s: %s. Distribution can be 0 (uniform) or 1 (normal).", stimName, val);
        end
    end
end

function out = GetListFromArray(A)
    commas = repmat([", "], size(A));
    commas(end) = "";
    s = size(A);
    if s(1) == 1
        A = A';
        commas = commas';
    end
    arr = horzcat(A, commas);
    arr = append(arr(:,1), arr(:,2));
    out = strjoin(arr');
end
end



% function checkRange(value,range,token,idxStim)
% if value<range(1) || value>range(2)
%     error(['Faulty parameter "%s" for stimulus #%d (expecting value ' ...
%         'to be within %d-%d)'],token,idxStim,range(1),range(2))
% end
% end