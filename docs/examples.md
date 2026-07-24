# Janitor Integration Examples

## Linking to Instance Lifecycle

Automatically clean up Janitor resources when a Roblox `Instance` is destroyed from the game hierarchy:

```luau
local Janitor = require(path.to.Janitor)

local janitor = Janitor.new()
local part = Instance.new("Part")
part.Parent = workspace

-- Link Janitor cleanup to part destruction
janitor:LinkToInstance(part)

janitor:Add(workspace.ChildAdded:Connect(function(child)
    print("New child:", child.Name)
end), "Disconnect")

-- Destroying part automatically triggers janitor:Cleanup()
part:Destroy()
```

## Managing Promises

```luau
local Janitor = require(path.to.Janitor)
local Promise = require(path.to.Promise)

local janitor = Janitor.new()

local p = Promise.new(function(resolve)
    task.wait(5)
    resolve("Done")
end)

janitor:AddPromise(p)

-- If janitor is cleaned up within 5 seconds, promise 'p' is automatically cancelled
task.wait(1)
janitor:Cleanup()
```
