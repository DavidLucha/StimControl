classdef ComponentProperty

properties (SetAccess=private, GetAccess=public)
default     = []
allowable   = {}
validatefcn = @(val) true
dependencies= @(propStruct) true
dependents  = []
dynamic     = false
required    = @(propStruct) true
note        = ""
end

methods
function obj = ComponentProperty(varargin)
p = inputParser();
addRequired(p, 'default', []);
addParameter(p,'allowable',  {}, @iscell);
addParameter(p,'validatefcn', @(val)true, @(input) isa(input,'function_handle'));
addParameter(p,'dependencies', @(propStruct) true, @(input) isa(input,'function_handle'));
addParameter(p,'dependents',  {}, @iscell);
addParameter(p,'dynamic',  false, @islogical);
addParameter(p,'required',  @(propStruct) true, @islogical);
addParameter(p,'note',  "", @(input) isstring(input) || ischar(input));

res = p.parse();
res = res.Results;

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
end