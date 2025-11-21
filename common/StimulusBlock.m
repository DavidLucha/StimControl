classdef StimulusBlock
properties
    treeHandle  = [];   % TrialData, for indexing into children.
    idx         = 1;    % int, if == 1, this is a root node.
    repeatDelay = 0     % int, ms to wait between stim repeats
    startDelay  = 0;    % int, ms to wait after stim t=0 to start
    nStimRuns   = 1;    % int, number of times to run the stim within the block
    stimParams  = [];   % struct of stimulus parameters. Only one stimulus can be given per block.
    parentIdx   = [];   % int, index of location of parent in the s array. if empty, this is a root node
    childIdxes  = [];   % [int], vector where each entry is the index of its children in the s array. 
                            % For oddball childRel, assume the leftmost child is the default and all other children are swaps,
                            % Root node should have exactly two
                            % children: left for stims that start at tPre and right for stims that start at tPost
    oddParams   = [];   % oddball params, only used if childRel == 'odd'. Has fields:
                            % swapRatio (% of default stim to swap)
                            % distributionMethod (one of: 
                                % even, 
                                % random,
                                % semirandomX where x is the number of times 
                                    % to guarantee default stim between oddballs)
                            % oddballRel (rand / seq) - with multiple oddballs, 
                                % defined whether the oddballs are randomly distributed or 
                                % swapped in sequentially.
    childRel    = '';   % [char], relationship between children. One of:
                            % odd (oddball, swap out child1 for child2 according to oddball params
                            % sim (simultaneous, children start at same time)
                            % seq (sequential, child1 starts after child2 finishes
end

properties (Access=private)
    allTargetsCached = [];
end

methods
    function obj = StimulusBlock(varargin)
        % Construct an instance of StimulusBlock
        % ARGUMENTS:
        %   childIdxes  - [int], vector where each entry is the index of its children in the s array
        %   repeatDelay - int, ms to wait between stim repeats
        %   startDelay  - int, ms to wait after stim t=0 to start
        %   nStimRuns   - int, number of times to run the stim within the
        %   stimParams  - struct of stimulus parameters in the format stimName: [params = struct], ...
        %   oddParams   - oddball params, only used if childRel == 'odd'
        %   childRel    - [char], relationship between children. One of: 'odd', 'sim', 'seq'
        p = inputParser;
        addParameter(p, 'childIdxes', obj.childIdxes);
        addParameter(p, 'repeatDelay', obj.repeatDelay, @(x) isnumeric(x));
        addParameter(p, 'startDelay', obj.startDelay, @(x) isnumeric(x));
        addParameter(p, 'nStimRuns', obj.nStimRuns, @(x) isnumeric(x));
        addParameter(p, 'stimParams', obj.stimParams, @(x) isstruct(x));
        addParameter(p, 'oddParams', obj.oddParams, @(x) isstruct(x));
        addParameter(p, 'childRel', obj.childRel, @(x) ischar(x) && ismember(x, {'odd', 'sim', 'seq'}));
        addParameter(p, 'treeHandle', []);
        parse(p, varargin{:});
        for fn = fieldnames(p.Results)'
            obj.(fn{1}) = p.Results.(fn{1});
        end
    end

    function valid = isValid(obj)
        % whether this node is valid.
        valid = true;
         if obj.isRootNode % root node
            if length(obj.childIdxes) ~=2 ...   % should have exactly 2 children
                    || ~strcmpi(obj.childRel, 'sim') % tPre tPost
                valid = false;
            end
         elseif ~obj.isLeafNode
            % check the following attributes:
            % no simultaneous addressing of the same device
            % check oddball is valid: >1 children, >1 nStimRuns, params defined, common sense ratio checking?
            % check if not oddball params are not defined
         else
            % check stimParams is defined & valid
         end
    end

    function valid = allValid(obj)
        % whether this node and all its children are valid.
        valid = obj.isValid;
        if ~obj.isLeafNode
            children = obj.children;
            for i = 1:length(children)
                child = children(i);
                if ~child.allValid
                    valid = false;
                    return;
                end
            end
        end
    end

    function trialParams = buildParams(obj)
        % Builds a params sequence
        singleStimParams = [];
        params = struct('sequence', [], 'delay', [], 'params', []);
        targets = obj.targets;
        helperStruct = [];
        for ti = 1:length(targets)
            targetName = targets{ti};
            singleStimParams.(targetName).sequence = [];
            singleStimParams.(targetName).delay = [];
            singleStimParams.(targetName).params = params;

            % initalise helperstruct
            helperStruct.(targetName) = [];
            helperStruct.(targetName).idxOffset = 0;
            helperStruct.(targetName).totalDelay = obj.startDelay;
        end
        trialParams = singleStimParams; % will be built out later.

        if obj.isLeafNode
            % only one stimulus. Easiest case.
            tds = obj.stimParams.targetDevices;
            for ti = 1:length(tds)
                % TODO-OPTIMISATION: POSSIBILITY FOR A FAIR BIT OF REPLICATION HERE
                targetName = tds(ti);
                singleStimParams.(targetName).params = obj.stimParams;
                singleStimParams.(targetName).delay = [obj.startDelay repmat(obj.repeatDelay, [1 obj.nStimRuns-1])];
                singleStimParams.(targetName).sequence = ones([1, obj.nStimRuns]);
                trialParams = singleStimParams;
            end
            return
        end
        % Traverse children
        children = obj.children;
        traversedParams = cell([1, length(children)]);
        for ci = 1:length(children)
            child = children(ci);
            traversedParams{ci} = child.buildParams;
        end
        if strcmpi(obj.childRel, 'sim') 
            % children occur simultaneously (the easiest case)
            for ti = 1:length(traversedParams)
                traversedParam = traversedParams{ti};
                fds = fields(traversedParam);
                for fi = 1:length(fds)
                    fieldName = fds{fi};
                    singleStimParams.(fieldName) = traversedParam.(fieldName);
                    singleStimParams.(fieldName).delay = singleStimParams.(fieldName).delay + obj.startDelay;
                end
            end
        else
            % sequential or oddball. Build sequence and go from there.
            if strcmpi(obj.childRel, 'seq')
                sequence = linspace(1, length(obj.childIdxes), length(obj.childIdxes));
            elseif strcmpi(obj.childRel, 'odd')
                sequence = obj.generateOddballOrder;
            end
            totalDelay = obj.startDelay;
            for si = 1:length(sequence)
                traversedParam = traversedParams{sequence(si)};
                if ~isstruct(traversedParam)
                    traversedParam = traversedParam{:};
                end
                child = children(sequence(si));
                for f = fields(traversedParam)'
                    % set params
                    % TODO this might be worse than just having an absolute
                    % offset for each child, greater possibility of
                    % miscalculating if you're doing stim duration in two
                    % places (here and StimGenerator: see TODO:SEQ)
                    if iscell(f)
                        f = f{:};
                    end
                    singleStimParams.(f).sequence = ...
                        [singleStimParams.(f).sequence traversedParam.(f).sequence+helperStruct.(f).idxOffset]; 
                    singleStimParams.(f).delay = ...
                        [singleStimParams.(f).delay traversedParam.(f).delay+(totalDelay-helperStruct.(f).offsetMs)];
                    singleStimParams.(f).params = ...
                        [singleStimParams.(f).params traversedParam.(f).params];
                    % update helperstruct
                    helperStruct.(f).idxOffset = helperStruct.(f).idxOffset + max(traversedParam.(f).sequence);
                    helperStruct.(f).totalDelay = helperStruct.(f).totalDelay + child.durationMs;
                end
                totalDelay = totalDelay + child.durationMs;
            end
        end
        
        % build trial params out of single stim params
        trialParams = singleStimParams;
        if obj.nStimRuns > 1
            for f = targets
                for nRep = 2:obj.nStimRuns
                    trialParams.(f).delay = [trialParams.(f).delay singleStimParams.(f).delay+obj.singleStimMs];
                    trialParams.(f).sequence = [trialParams.(f).sequence singleStimParams.(f).sequence];
                end
            end
        end
    end

    %% Attribute-like functions
    function children = children(obj)
        children = [obj.treeHandle{obj.childIdxes}];
    end

    function isRootNode = isRootNode(obj)
        isRootNode = obj.idx == 1;
    end

    function isLeafNode = isLeafNode(obj)
        isLeafNode = length(obj.childIdxes)==0; %#ok<ISMT>
    end

    function allTargets = targets(obj)
        % tree traversal to find all child targets
        %TODO caching here would be SO HELPFUL but not a priority rn
        if ~obj.isLeafNode
            allTargets = {};
            children = obj.children;
            for i = 1:length(children)
                child = children(i);
                allTargets = [allTargets, child.targets]; %#ok<AGROW>
            end
        else
            allTargets = obj.selfTargets;
        end
    end

    function childTargets = childTargets(obj)
        % returns the list of the direct targets of the children.
        childTargets = [];
        if ~obj.isLeafNode
            children = obj.children;
            for i = 1:length(children)
                child = children(i);
                childTargets = [childTargets child.targets];
            end
        end
    end

    function targets = selfTargets(obj)
        % direct targets
        targets = {};
        if ~isempty(obj.stimParams)
            targets = obj.stimParams.targetDevices;
        end
    end
    
    function duration = durationMs(obj)
        duration = obj.startDelay + obj.nStimRuns*(obj.singleStimMs + obj.repeatDelay);
    end

    function stimDur = singleStimMs(obj)
        if ~obj.isLeafNode
            children = obj.children;
            if strcmpi(obj.childRel, 'sim') 
                % children occur simultaneously - only count longest duration
                stimDur = 0;
                for i = 1:length(children)
                    stimDUr = max(stimDUr, children(i).durationMs);
                end
            elseif strcmpi(obj.childRel, 'seq')
                % children occur sequentially. consider a single stim
                stimDUr = 0;
                for i = 1:length(children)
                    stimDur = stimDur + children(i).durationMs;
                end
            elseif strcmpi(obj.childRel, 'odd')
                %TODO
                error("not implemented.");
            end
        else
            % leaf node.
            if strcmpi(obj.stimParams.type, 'serial')
                if ~contains(obj.stimParams.targetDevices, 'QST')
                    stimDur = 0;
                else
                    stimDur = max([obj.stimParams.commands.dStimulus]);
                end
            elseif strcmpi(obj.stimParams.type, 'arbitrary')
                %TODO
                error("not implemented.")
            else
                stimDur = obj.stimParams.duration;
            end
        end
    end
end

methods(Access=private)
    %% PRIVATE FUNCTIONS
    function order = generateOddballOrder(obj)
        order = ones(1, obj.nStimRuns);
        nOdds = length(obj.childIdxes) - 1;
        nSwaps = floor(obj.nStimRuns * obj.oddParams.swapRatio);
        oddIdxes = linspace(2, nOdds+1, nOdds);

        odds = [repmat(oddIdxes, [1 floor(nSwaps / nOdds)]) oddIdxes(1:rem(nSwaps, nOdds))];
        if strcmpi(obj.oddParams.oddballRel, 'rand')
            odds = odds(randperm(length(odds)));
        end

        % swap in oddballs
        if strcmpi(obj.oddParams.distributionMethod, 'even') %evenly distributed
            swapIdxes = round(linspace(1, length(order), nSwaps));
        elseif strcmpi(obj.oddParams.distributionMethod, 'random') %randomly distributed
            
        else
            if ~contains(obj.oddParams.distributionMethod, 'semirandom') %randomly distributed with minimum swap distance
                error("Invalid distribution method: %s", obj.oddParams.distributionMethod);
            end
            minPostOddDefaults = str2double(obj.oddParams.distributionMethod(11:end)); % warning: cursed
            if minPostOddDefaults > obj.nStimRuns/nSwaps
                error("Unable to set %d default stimuli between oddballs " + ...
                    "for %d total instances at %d oddball rate. Set distribution value to <= %d", ...
                    minPostOddDefaults, obj.nStimRuns, obj.oddParams.SwapRatio, ...
                    floor(obj.nStimRuns*obj.oddParams.SwapRatio));
            end
            swapIdxes = round(linspace(1, obj.nStimRuns, nSwaps));
            swapIdxes(1) = floor(1 + minPostOffDefaults*rand(1,1));
            dBack = swapIdxes(1);
            dForward = 0;
            for i = 1:length(swapIdxes)
                if i ~= length(swapIdxes)
                    dForward = swapIdxes(i+1) - swapIdxes(i);
                    error("Not implemented");
                end
            end
        end
    end

    function out = childfcn(obj, fcnHandle)
        out = [];
        children = obj.children;
        for i = 1:length(children)
            out = [out child.fcnHandle];
        end
    end
end
end