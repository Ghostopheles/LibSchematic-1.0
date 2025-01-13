# LibSchematic-1.0
LibSchematic is a framework for creating a visual scripting experiences for user-facing addons

## Usage

```lua
---@type LibSchematic
local LibSchematic = LibStub:GetLibrary("LibSchematic-1.0");

-- pre-runtime setup (defining your context/environment)

-- define context
local Context = LibSchematic.CreateContext("MyContext");

do -- define a function
    local function Multiply(a, b)
        return a * b;
    end
    -- define the node within the context, this adds it to the context's 'node library'
    local node = Context:DefineNode("Multiply", Multiply);
    node:SetStatic(true); -- static functions don't require a reference to it's owning context

    -- define our inputs and outputs, used later for linking nodes and building out UI elements
    node:CreateInput("A", "number"); 
    node:CreateInput("B", "number");
    node:CreateOutput("Result", "number");
end

--- runtime (user interacting w/ the UI)

-- when the user drags a node onto the canvas, we create a runtime node
local runtimeNodeA = Context:CreateRuntimeNodeByName("Multiply");
local runtimeNodeB = Context:CreateRuntimeNodeByName("Multiply");

-- when the user connects a node to another - this controls code flow
Context:CreateLink(runtimeNodeA, runtimeNodeB);

-- when the user connects an output to an input
local outputIndex = 1;
local inputIndex = 1;
local output = runtimeNodeA:GetOutput(outputIndex);
local input = runtimeNodeB:GetInput(inputIndex);
Context:CreateIOLink(output, input); -- links output 1 of nodeA to input 1 of nodeB

-- evaluate the context, return the result, if any
local results = Context:Eval();
```