classdef StimulusBlock
    properties
        parentIdx   = [];   % int, index of location of parent in the s array. if empty, this is a root node
        childIdxes  = [];   % [int], vector where each entry is the index of its children in the s array. if empty, this is a leaf node
        treeHandle = [];    % TrialData, for indexing into children.
        repeatDelay = 0     % int, ms to wait between stim repeats
        startDelay  = 0;    % int, ms to wait after stim t=0 to start
        nStimRuns   = 1;    % int, number of times to run the stim within the block
        stimParams  = [];   % struct of stimulus parameters in the format stimName: [params = struct], ...
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

        function trialParams = constructTrialParams(obj)
            % trialParams = [];
            % if obj.isLeafNode
            %     targets = obj.targets;
            %     for target = targets
            %         tData = obj.getParamsForTarget(target{1});
            %         trialParams.(target{1}) = tData;
            %     end
            % else
            %     match obj.childRel
            %         case 'odd'
            %             % construct the order the oddballs will be presented in, then construct the params for each.
            %             % TODO
            %         case 'sim'
            %             % TODO
            %         case 'seq'
            %             % TODO
            %     end
            %     for child = obj.children'
            %         childParams = child.constructTrialParams;
            %         trialParams = mergeStructs(trialParams, childParams);
            %     end 
            % end
            % end
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
                    targets{end+1} = targets {obj.stimParams.(field).targetDevices};
                end
                targets = unique(targets);
            end
        end
    end
end