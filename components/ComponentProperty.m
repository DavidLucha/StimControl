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
end

methods (Access=public)
    function obj = ComponentProperty(varargin)
        p = inputParser();
        addParameter(p, 'default', [], @(x) true);
        addParameter(p,'allowable',  {}, @(x) iscell(x) || isnumeric(x));
        addParameter(p,'validatefcn', @(val)true, @(x) isa(x,'function_handle'));
        addParameter(p,'dependencies', @(propStruct) true, @(x) isa(x,'function_handle'));
        addParameter(p,'dependents',  {}, @(x) obj.CategoricalCompatible(x));
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
    function out = isvalid(obj, val)
        if ~isempty(obj.allowable)
            out = ismember(val, obj.allowable);
        else
            out = obj.validatefcn(val);
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