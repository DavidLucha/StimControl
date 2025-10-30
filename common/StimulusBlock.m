classdef StimulusBlock
properties
    treeHandle  = [];   % TrialData, for indexing into children.
    idx         = 1;        % int, if = 1, this is a root node.
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
    childRel    = 'sim';% [char], relationship between children. One of:
                            % odd (oddball, swap out child1 for child2 according to oddball params
                            % sim (simultaneous, children start at same time)
                            % seq (sequential, child1 starts after child2 finishes
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
            for child = obj.children'
                if ~child.allValid
                    valid = false;
                    return;
                end
            end
        end
    end

    function [sequence, delay, stims] = getTrialParams(obj)
        stims = struct('sequence', [], 'delay', [], 'stims', []);
        if obj.isLeafNode
            sequence = ones([1, obj.nStimRuns]);
            delay = [obj.startDelay rempat(obj.repeatDelay, [1, obj.nStimRuns-1])];
            stims = obj.stimParams;
            return
        else %TODO ROOTNODE
            sequence = [];
            delay = [obj.startDelay repmat(obj.repeatDelay, [1 obj.nStimRuns-1])];
            stims = [];
            % get execution order and delays
            if strcmpi(obj.childRel, 'sim')
                sequence = ones([1, obj.nStimRuns]); 
            elseif strcmpi(obj.childRel, 'seq')
                sequence = linspace(1, length(obj.childIdxes), length(obj.childIdxes));
            elseif strcmpi(obj.childRel, 'odd')
                sequence = obj.generateOddballOrder;
            end
            maxExecutionIdx = 0;
            for i = 1:length(obj.children)
                child = obj.children(i);
                [childExecution, childDel, childParams] = child.getTrialParams;
                executionOrders = [sequence; child.executionOrder+maxExecutionIdx];
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
        isLeafNode = isempty(obj.childIdxes);
    end

    function allTargets = allTargets(obj)
        if ~obj.isLeafNode
            allTargets = {};
            for child = obj.children'
                allTargets = [allTargets, child.allTargets];
            end
        else
            allTargets = obj.targets;
        end
    end

    function childTargets = childTargets(obj)
        childTargets = [];
        if ~obj.isLeafNode
            for child = obj.children'
                childTargets = [childTargets child.targets];
            end
        end
    end

    function targets = targets(obj)
        targets = {};
        if ~isempty(obj.stimParams)
            targets = obj.stimParams.targetDevices;
        end
    end
    
    function duration = durationMs(obj)
        if ~obj.isLeafNode
            if strcmpi(obj.childRel, 'sim') 
                % children occur simultaneously - only count longest duration
                maxChildDur = 0;
                for child = obj.children'
                    maxChildDur = max(child.durationMs, maxChildDur);
                end
                duration = obj.startDelay + obj.nStimRuns*(maxChildDur + obj.repeatDelay) - obj.repeatDelay;
            elseif strcmpi(obj.childRel, 'seq')
                % children occur sequentially. consider a single stim
                duration = obj.startDelay;
                seqChildDur = 0;
                for child = obj.children'
                    seqChildDur = seqChildDur + child.durationMs;
                end
                duration = obj.startDelay + obj.nStimRuns*(obj.repeatDelay + seqChildDur) - obj.repeatDelay;
            elseif strcmpi(obj.childRel, 'odd')
                %TODO
                error("not implemented.");
            end
        else
            if strcmpi(obj.stimParams.type, 'serial')
                if ~contains(obj.stimParams.targetDevices, 'QST')
                    stimDur = 0;
                else
                    stimDur = max(obj.stimParams.thermodeA.dStimulus, obj.stimParams.thermodeB.dStimulus);
                end
            elseif strcmpi(obj.stimParams.type, 'arbitrary')
                %TODO
                error("not implemented.")
            else
                stimDur = obj.stimParams.duration;
            end
            duration = obj.startDelay + obj.nStimRuns*(stimDur * obj.repeatDelay);
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
        if strcmpi(obj.oddParams.distributionMethod, 'even')
            swapIdxes = round(linspace(1, length(order), nSwaps));
        elseif strcmpi(obj.oddParams.distributionMethod, 'random')
            
        else
            if ~contains(obj.oddParams.distributionMethod, 'semirandom')
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
end
end