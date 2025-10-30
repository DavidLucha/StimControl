classdef StimulusBlock
    properties
        parentIdx   = [];   % int, index of location of parent in the s array. if empty, this is a root node
        childIdxes  = [];   % [int], vector where each entry is the index of its children in the s array. if empty, this is a leaf node
        treeHandle = [];    % TrialData, for indexing into children.
        repeatDelay = 0     % int, ms to wait between stim repeats
        startDelay  = 0;    % int, ms to wait after stim t=0 to start
        nStimRuns   = 1;    % int, number of times to run the stim within the block
        stimParams  = [];   % struct of stimulus parameters. Only one stimulus can be given per parameter ...
        targets     = {};   % target devices, by ProtocolID
        oddParams   = [];   % oddball params, only used if childRel == 'odd'
        childRel    = 'sim';% [char], relationship between children. 
                                % one of: 
                                % odd (oddball, swap out child1 for child2 according to oddball params
                                % sim (simultaneous, children start at same time)
                                % seq (sequential, child1 starts after child2 finishes
        idx         = 1;    % int, if = 1, this is a root node.
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

        function [daqTrial, hardwareTrial] = generateStim(obj)
            daqTrial = obj.generateDAQStim;
            hardwareTrial = obj.constructTrialParams;
        end

        function daqTrial = generateDAQStim(obj)
            if obj.isRootNode
                % childIdxes is a struct with fields tPre and tPost. 
                % generate recursively TWICE
            else
                % childIdxes is a vector
            end
        end

        function [executionOrder, startDelay, trialParams] = constructTrialParams(obj)
            trialParams = [];
            allTargets = obj.allTargets;
            for t = allTargets

                if obj.isLeafNode
                    targetParams = obj.stimParams.(t);
                else
                    targetParams = [];
                    for child = obj.children
                        targetParams = [targetParams child.]
                    end
                end

                trialParams.(t) = struct( ...
                    'executionOrder', executionOrder, ...
                    'delay', delay, ...
                    'stimParams', targetParams);
            end
            if obj.isLeafNode
                executionOrder = [];
                stimParams = [];
                for target = allTargets
                    
                end
            else
                % traverse through children, concatenating structs and
                % rebuilding execution order
            end
        end

        function [executionOrder, delay, trialParams] = getSelfTrialParams(obj)
            executionOrder = [];
            delay = [];
            trialParams = [];
            % get execution order and delays
            if strcmpi(obj.childRel, 'sim')
                executionOrder = ones([1, obj.nStimRuns]); 
                delay = [obj.startDelay repmat(obj.repeatDelay, [1 obj.nStimRuns-1])];
            elseif strcmpi(obj.childRel, 'seq')
                executionOrder = linspace(1, length(obj.childIdxes), length(obj.childIdxes));
            elseif strcmpi(obj.childRel, 'odd')
                
            end
        end

        function children = children(obj)
            children = obj.treeHandle{obj.childIdxes};
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
            if obj.isRootNode
                allTargets = unique(allTargets);
            end
        end

        function targets = targets(obj)
            targets = {};
            if ~isempty(obj.stimParams)
                for field = fields(obj.stimParams)'
                    targets = [targets obj.stimParams.(field).targetDevices];
                end
                targets = unique(targets);
            end
        end
    end
end