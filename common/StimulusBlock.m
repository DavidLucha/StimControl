classdef StimulusBlock
    properties
        parentIdx   = [];   % int, index of location of parent in the s array. if empty, this is a root node
        childIdxes  = [];   % [int], vector where each entry is the index of its children in the s array. if empty, this is a leaf node
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
    end

    methods
        function obj = StimulusBlock(varargin)
            % Construct an instance of StimulusBlock
            % ARGUMENTS:
            %   parentIdx   - int, index of location of parent in the s array
            %   childIdxes  - [int], vector where each entry is the index of its children in the s array
            %   repeatDelay - int, ms to wait between stim repeats
            %   startDelay  - int, ms to wait after stim t=0 to start
            %   nStimRuns   - int, number of times to run the stim within the
            %   stimParams  - struct of stimulus parameters in the format stimName: [params = struct], ...
            %   oddParams   - oddball params, only used if childRel == 'odd'
            %   childRel    - [char], relationship between children. One of: 'odd', 'sim', 'seq'
            p = inputParser;
            addParameter(p, 'parentIdx', obj.parentIdx);
            addParameter(p, 'childIdxes', obj.childIdxes);
            addParameter(p, 'repeatDelay', obj.repeatDelay, @(x) isnumeric(x));
            addParameter(p, 'startDelay', obj.startDelay, @(x) isnumeric(x));
            addParameter(p, 'nStimRuns', obj.nStimRuns, @(x) isnumeric(x));
            addParameter(p, 'stimParams', obj.stimParams, @(x) isstruct(x));
            addParameter(p, 'oddParams', obj.oddParams, @(x) isstruct(x));
            addParameter(p, 'childRel', obj.childRel, @(x) ischar(x) && ismember(x, {'odd', 'sim', 'seq'}));
            parse(p, varargin{:});
            for fn = fieldnames(p.Results)'
                obj.(fn{1}) = p.Results.(fn{1});
            end
        end

        function isRoot = isRootNode(obj)
            isRoot = isempty(obj.parentIdx);
        end

        function [daqTrial, hardwareTrial] = generateStim(obj)
            daqTrial = obj.generateDAQTrial;
            hardwareTrial = obj.generateHardwareTrial;
        end

        function daqTrial = generateDAQTrial(obj)
            if obj.isRootNode
                % childIdxes is a struct with fields tPre and tPost. 
                % generate recursively TWICE
            else
                % childIdxes is a vector
            end
        end

        function hardwareTrial = generateHardwareTrial(obj)

        end
    end
end