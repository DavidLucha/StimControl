classdef (HandleCompatible) TrialData < handle &  matlab.mixin.indexing.RedefinesBrace
    % TODO https://au.mathworks.com/help/matlab/matlab_oop/indexed-reference-and-assignment.html
    % Handle wrapper for cell array of stimulus blocks so that they can be
    % passed to one another without data reduplication. 

    properties (Access=protected)
        StimulusBlocks (1,:) cell
    end
    
    properties (Dependent)
        data
    end

    properties 
        tPre
        tPost
        nRuns
        comment
    end

    methods
        function obj = TrialData(varargin)
            % Construct an instance of this class
            %   ARGUMENTS: 
            %       stimulusBlocks (cell array): a 1xn cell array where n is the number of stimulus blocks in the trial
            if nargin > 0
                obj.StimulusBlocks = varargin;
            else
                obj.StimulusBlocks = {};
            end
            for i = 1:length(obj.StimulusBlocks)
                block = obj.StimulusBlocks{i};
                block.treeHandle = obj;
                block.idx = i;
                obj.StimulusBlocks{i} = block;
            end
        end
        
        function out = rootNode(obj)
            out = obj.StimulusBlocks{1};
        end

        function targets = targets(obj)
            rootNode = obj.rootNode;
            targets = rootNode.allTargets;
        end

        function trialParams = constructTrialParams(obj)
            rootNode = obj.rootNode;
            trialParams = rootNode.generateHardwareStim;
            % you want a data structure like this:
            % trialParams:
            %   targetID: 
            %       StimulusOrder: [list of indices that indicates the order in which to execute the stimuli], 
            %       stimuli: {array of structs, each struct is the parameters for that stimulus.}
            % I THINK, ANYWAY.
        end

        function set.data(obj, val)
            obj.StimulusBlocks = val;
            for i = 1:length(obj.StimulusBlocks)
                block = obj.StimulusBlocks{i};
                block.treeHandle = obj;
                block.idx = i;
                obj.StimulusBlocks{i} = block;
            end
        end

        function out = get.data(obj)
            out = obj.StimulusBlocks;
        end
    end

    methods (Access=protected)
        function varargout = braceReference(obj,indexOp)
            [varargout{1:nargout}] = obj.StimulusBlocks.(indexOp);
        end

        function obj = braceAssign(obj,indexOp,varargin)
            if isscalar(indexOp)
                [obj.StimulusBlocks.(indexOp)] = varargin{:};
                return;
            end
            [obj.StimulusBlocks.(indexOp)] = varargin{:};
            
            for i = 1:length(indexOp)
                idx = obj.StimulusBlocks{i};
                block = obj.StimulusBlocks.(indexOp);
                block.treeHandle = obj;
                block.idx = idx;
            end
        end

        function n = braceListLength(obj,indexOp,indexContext)
            n = listLength(obj.StimulusBlocks,indexOp,indexContext);
        end
    end
end