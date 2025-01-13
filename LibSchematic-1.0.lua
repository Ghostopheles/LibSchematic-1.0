assert(LibStub, "LibStub not found.");

---@alias LibSchematic-1.0 LibSchematic
local major, minor = "LibSchematic-1.0", 1;

---@class LibSchematic
local LibSchematic = LibStub:NewLibrary(major, minor);

if not LibSchematic then
    return;
end

local function CreateObject(object, ...)
    return CreateAndInitFromMixin(object, ...);
end

------------
--- INPUTS AND OUTPUTS

---@class LibSchematicNodeInput
local NodeInput = {};

function NodeInput:Init() end;

---@param name string
function NodeInput:SetName(name)
    self.Name = name;
end

---@return string name
function NodeInput:GetName()
    return self.Name;
end

---@param type type
function NodeInput:SetType(type)
    self.Type = type;
end

---@return type
function NodeInput:GetType()
    return self.Type;
end

---@param isRequired boolean
function NodeInput:SetRequired(isRequired)
    self.Required = isRequired;
end

---@return boolean isRequired
function NodeInput:IsRequired()
    return self.Required;
end

------

---@class LibSchematicRuntimeNodeInput
local RuntimeNodeInput = {};

---@param parent LibSchematicNodeInput
function RuntimeNodeInput:Init(parent)
    self:SetParent(parent);
end

---@param parentNodeInput LibSchematicNodeInput
function RuntimeNodeInput:SetParent(parentNodeInput)
    self.Parent = parentNodeInput;
end

---@return LibSchematicNodeInput
function RuntimeNodeInput:GetParent()
    return self.Parent;
end

---@param output LibSchematicRuntimeNodeOutput
function RuntimeNodeInput:SetSource(output)
    self.Source = output;
end

---@return LibSchematicRuntimeNodeOutput?
function RuntimeNodeInput:GetSource()
    return self.Source;
end

function RuntimeNodeInput:SetValue(value)
    self.Value = value;
end

function RuntimeNodeInput:GetValue()
    return self.Value;
end

------------

---@class LibSchematicNodeOutput
local NodeOutput = {};

function NodeOutput:Init() end;

---@param name string
function NodeOutput:SetName(name)
    self.Name = name;
end

---@return string name
function NodeOutput:GetName()
    return self.Name;
end

---@param type type
function NodeOutput:SetType(type)
    self.Type = type;
end

---@return type
function NodeOutput:GetType()
    return self.Type;
end

------

---@class LibSchematicRuntimeNodeOutput
local RuntimeNodeOutput = {
    Destinations = {}
};

---@param parent LibSchematicNodeOutput
function RuntimeNodeOutput:Init(parent)
    self:SetParent(parent);
end

---@param parentNodeInput LibSchematicNodeOutput
function RuntimeNodeOutput:SetParent(parentNodeInput)
    self.Parent = parentNodeInput;
end

---@return LibSchematicNodeOutput
function RuntimeNodeOutput:GetParent()
    return self.Parent;
end

---@param input LibSchematicRuntimeNodeInput
function RuntimeNodeOutput:AddDestination(input)
    tinsert(self.Destinations, input);
end

function RuntimeNodeOutput:SetValue(value)
    self.Value = value;
end

function RuntimeNodeOutput:GetValue()
    return self.Value;
end

------------
--- NODE

---@class LibSchematicNode
local Node = {
    Inputs = {},
    Outputs = {},
    Static = false,
};

---@param context LibSchematicContext
function Node:Init(context)
    self:SetContext(context);
end

---@return LibSchematicContext
function Node:GetContext()
    return self.Context;
end

---@param context LibSchematicContext
function Node:SetContext(context)
    self.Context = context;
end

---@param isUserCreateable boolean
function Node:SetUserCreateable(isUserCreateable)
    self.UserCreateable = isUserCreateable;
end

---@return boolean isUserCreateable
function Node:IsUserCreateable()
    return self.UserCreateable;
end

---@return string name
function Node:GetName()
    return self.Name;
end

---@param name string
function Node:SetName(name)
    self.Name = name;
end

---@return function
function Node:GetClosure()
    return self.Closure;
end

---@param closure function
function Node:SetClosure(closure)
    self.Closure = closure;
end

---@param input LibSchematicNodeInput
function Node:AddInput(input)
    tinsert(self.Inputs, input);
end

---@return LibSchematicNodeInput[]
function Node:GetInputs()
    return self.Inputs;
end

---@param output LibSchematicNodeOutput
function Node:AddOutput(output)
    tinsert(self.Outputs, output);
end

---@return LibSchematicNodeOutput[]
function Node:GetOutputs()
    return self.Outputs;
end

---@param isStatic boolean
function Node:SetStatic(isStatic)
    self.Static = isStatic;
end

---@return boolean isStatic
function Node:IsStatic()
    return self.Static;
end

------------
--- RUNTIME NODE

---@class LibSchematicRuntimeNode
---@field Inputs LibSchematicRuntimeNodeInput[]
---@field Outputs LibSchematicRuntimeNodeOutput[]
local RuntimeNode = {
    Inputs = {},
    Outputs = {}
};

---@param parentNode LibSchematicNode
function RuntimeNode:Init(parentNode)
    self:SetParent(parentNode);

    -- populate inputs and outputs with runtime equivalents
    for _, input in ipairs(parentNode:GetInputs()) do
        local runtimeInput = CreateObject(RuntimeNodeInput, input);
        tinsert(self.Inputs, runtimeInput);
    end

    for _, output in ipairs(parentNode:GetInputs()) do
        local runtimeOutput = CreateObject(RuntimeNodeOutput, output);
        tinsert(self.Outputs, runtimeOutput);
    end
end

---@param parentNode LibSchematicNode
function RuntimeNode:SetParent(parentNode)
    self.ParentNode = parentNode;
end

---@return LibSchematicNode
function RuntimeNode:GetParent()
    return self.ParentNode;
end

---@param inputIndex number
function RuntimeNode:GetInput(inputIndex)
    return self.Inputs[inputIndex];
end

---@param outputIndex number
function RuntimeNode:GetOutput(outputIndex)
    return self.Outputs[outputIndex];
end

function RuntimeNode:Eval()
    local parent = self.ParentNode;
    local closure = parent:GetClosure();
    local results;

    -- collect inputs
    local inputs = {};
    for _, input in ipairs(self.Inputs) do
        local value;
        local source = input:GetSource();
        if source then
            value = source:GetValue();
        else
            value = input:GetValue();
        end
        tinsert(inputs, value);
    end

    -- evaluate
    if parent:IsStatic() then
        results = {closure(unpack(inputs))};
    else
        local context = parent:GetContext();
        results = {closure(context, unpack(inputs))};
    end

    -- set the value of our outputs
    local numOutputs = #self.Outputs;
    if numOutputs > 0 then
        for i=1, numOutputs do
            local output = self.Outputs[i];
            output:SetValue(results[i]);
        end
    end

    return results;
end

----- runtime flow

---@param node LibSchematicRuntimeNode
function RuntimeNode:SetInNode(node)
    self.InNode = node;
end

---@return LibSchematicRuntimeNode?
function RuntimeNode:GetInNode()
    return self.InNode;
end

---@param node LibSchematicRuntimeNode
function RuntimeNode:SetOutNode(node)
    assert(node ~= self.InNode, "Please do not recurse infinitely.");
    self.OutNode = node;
end

---@return LibSchematicRuntimeNode?
function RuntimeNode:GetOutNode()
    return self.OutNode;
end

------------
--- CONTEXT

---@class LibSchematicContext
---@field private Nodes LibSchematicNode[]
---@field private Canvas LibSchematicRuntimeNode[]
---@field private EventGraph LibSchematicRuntimeNode[]
---@field private EntryPoint LibSchematicRuntimeNode
---@field private ExitPoint LibSchematicRuntimeNode
local Context = {
    Nodes = {}, -- the function library
    Canvas = {},  -- all created runtime nodes
    EventGraph = {} -- all runtime nodes in order of execution
};

---@param name string
function Context:Init(name)
    self:SetName(name);
    self:DefineStaticPoints();
end

---@return string name
function Context:GetName()
    return self.Name;
end

---@param name string
function Context:SetName(name)
    self.Name = name;
end

function Context:DefineStaticPoints()
    local entryName = "@EntryPoint";
    self:DefineNode(entryName, nop);
    self.EntryPoint = self:CreateRuntimeNodeByName(entryName);

    local exitName = "@ExitPoint";
    self:DefineNode(exitName, nop);
    self.ExitPoint = self:CreateRuntimeNodeByName(exitName);
end

function Context:GetEntryPoint()
    return self.EntryPoint;
end

function Context:GetExitPoint()
    return self.ExitPoint;
end

---@param name string
---@param closure function
---@return LibSchematicNode node
function Context:DefineNode(name, closure)
    local node = CreateObject(Node, self);
    node:SetName(name);
    node:SetClosure(closure);
    self.Nodes[name] = node;
    return node;
end

---@param name string
function Context:CreateRuntimeNodeByName(name)
    local node = self.Nodes[name];
    assert(node, "Node with name " .. name .. " not found");

    local runtimeNode = CreateObject(RuntimeNode, node);
    tinsert(self.Canvas, runtimeNode);
    return runtimeNode;
end

---@param firstNode LibSchematicRuntimeNode
---@param secondNode LibSchematicRuntimeNode
function Context:CreateLink(firstNode, secondNode)
    firstNode:SetOutNode(secondNode);
    secondNode:SetInNode(firstNode);
end

---@param output LibSchematicRuntimeNodeOutput
---@param input LibSchematicRuntimeNodeInput
function Context:CreateIOLink(output, input)
    output:AddDestination(input);
    input:SetSource(output);
end

------------
--- Public API

---@type LibSchematicContext[]
local Contexts = {};

---@param contextName string
---@return LibSchematicContext context
function LibSchematic.CreateContext(contextName)
    assert(not Contexts[contextName], format("Context with the name '%s' already exists", contextName));

    local context = CreateObject(Context, contextName);
    return context;
end

---@param contextName string
---@return LibSchematicContext? context
function LibSchematic.GetContextByName(contextName)
    return Contexts[contextName];
end
