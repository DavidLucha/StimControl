classdef (Abstract, HandleCompatible) ComponentProperties < handle
    properties
    end

    methods
        function out = isfield(fieldName, obj)
            f = fields(obj);
            if ~any(cellfun(@(x) strcmpi(fieldName, x), f))
                out = false;
            else
                out = true;
            end
        end

        function out = fields(obj)
            out = properties(obj);
        end
    end
end