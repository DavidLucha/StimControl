classdef (HandleCompatible) TrialData < handle
    % TODO https://au.mathworks.com/help/matlab/matlab_oop/indexed-reference-and-assignment.html
    % Handle wrapper for cell array of stimulus blocks so that they can be
    % passed to one another without data reduplication. 

    properties
        StimulusBlocks = {};
    end

    properties(Dependent)
        RootNode
    end

    methods
        function obj = TrialData(stimulusBlocks)
            % Construct an instance of this class
            %   ARGUMENTS: 
            %       stimulusBlocks (cell array): a 1xn cell array where n is the number of stimulus blocks in the trial
            obj.StimulusBlocks = stimulusBlocks;
        end

        function outputArg = method1(obj,inputArg)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            outputArg = obj.Property1 + inputArg;
        end
        
        function out = get.RootNode(obj)

        end

        function set.RootNode(obj, newNode)

        end
    end
end