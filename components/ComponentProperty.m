classdef ComponentProperty

properties (SetAccess=private, GetAccess=public)
    default
    allowable
    validatefcn
    dependencies
    dependents
    dynamic
    required
    note
    cat
end

methods (Access=public)
    function obj = ComponentProperty(varargin)
        p = inputParser();
        addParameter(p, 'default', [], @(x) true);
        addParameter(p,'allowable',  {}, @(x) obj.CategoricalCompatible(x));
        addParameter(p,'validatefcn', @(val)true, @(x) isa(x,'function_handle'));
        addParameter(p,'dependencies', @(propStruct) true, @(x) isa(x,'function_handle'));
        addParameter(p,'dependents',  {}, @iscellstr);
        addParameter(p,'dynamic',  false, @islogical);
        addParameter(p,'required',  @(propStruct) true, @islogical);
        addParameter(p,'note',  "", @(x) isstring(x) || ischar(x));
        
        p.parse(varargin{:});
        res = p.Results;
        
        obj.default = res.default;
        obj.allowable = res.allowable;
        obj.validatefcn = res.validatefcn;
        obj.dependencies = res.dependencies;
        obj.dependents = res.dependents;
        obj.dynamic = res.dynamic;
        obj.required = res.required;
        obj.note = res.note;
    end
end

methods(Access=public)
    function out = isValid(obj, val)
        if ~isempty(obj.allowable)
            out = ismember(val, obj.allowable);
        else
            out = obj.validatefcn(val);
        end
    end

    function out = getCategorical(obj)
        if isempty(obj.allowable)
            return
        elseif isempty(obj.cat)
            if ~iscellstr(obj.allowable) && iscell(obj.allowable)
                obj.cat = categorical(obj.allowable{1}, 'Protected', true);
            else
                obj.cat = categorical(obj.allowable, 'Protected', true);
            end
        end
        out = obj.cat;
    end

    function out = dependenciesMet(obj, vals)
        try
            out = obj.dependencies(vals);
        catch
            disp(obj)
            out = all(obj.dependencies(vals));
        end
    end
end

methods(Access=private)
    function out = CategoricalCompatible(~, x)
        try
            categorical(x); 
            out = true;
        catch
            out = false;
        end
    end
end
end