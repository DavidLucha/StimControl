classdef (HandleCompatible) TrialData < handle &  matlab.mixin.indexing.RedefinesBrace
% TODO https://au.mathworks.com/help/matlab/matlab_oop/indexed-reference-and-assignment.html
% Handle wrapper for cell array of stimulus blocks so that they can be
% passed to one another without data reduplication. 

properties (Access=protected)
    StimulusBlocks (1,:) cell
end

properties(Access=private)
    treeTargets = []; % to be cached on first call of obj.targets
end

properties (Dependent)
    data
end

properties 
    tPre
    tPost
    nRuns
    comment
    params
end

methods
    function obj = TrialData(varargin)
        % Construct an instance of this class
        %   ARGUMENTS: 
        %       data (cell array): a 1xn cell array where n is the number of stimulus blocks in the trial
        %       tPre
        %       tPost
        %       nRuns
        %       comment
        p = inputParser;
        addParameter(p, 'tPre', obj.tPre, @(x) isnumeric(x) && x > 0);
        addParameter(p, 'tPost', obj.tPost, @(x) isnumeric(x) && x > 0);
        addParameter(p, 'nRuns', obj.nRuns, @(x) isnumeric(x) && x > 0);
        addParameter(p, 'comment', obj.comment);
        addParameter(p, 'data', obj.data);
        parse(p, varargin{:});
        obj.tPre = p.Results.tPre;
        obj.tPost = p.Results.tPost;
        obj.nRuns = p.Results.nRuns;
        obj.comment = p.Results.comment;
        obj.data = p.Results.data;

        for i = 1:length(obj.StimulusBlocks)
            block = obj.StimulusBlocks{i};
            block.treeHandle = obj;
            block.idx = i;
            obj.StimulusBlocks{i} = block;
        end
    end
    
    function out = RootNode(obj)
        out = obj.StimulusBlocks{1};
    end

    function targets = targets(obj)
        if isempty(obj.treeTargets)
            rootNode = obj.RootNode;
            targets = rootNode.targets;
            obj.treeTargets = targets;
        else
            targets = obj.treeTargets;
        end
    end

    function targets = recalculateTargets(obj)
        rootNode = obj.RootNode;
        targets = rootNode.allTargets;
        obj.treeTargets = targets;
    end

    function trialParams = generateParamsSequence(obj)
        % generates full set of params for a trial in the format:
        %   targetID: 
        %       sequence [int]: the order in which to execute the stimuli
        %       delay [double]: ms delay to wait between each parameter 
        %       params: [struct] array of params for each struct. Order maps to sequence
        rootNode = obj.RootNode;
        obj.params = rootNode.buildParams;
        trialParams = obj.params;
        obj.data = {};
    end

    function set.data(obj, val)
        %sets the data      
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