# Janitor

Janitor is a high-performance memory management and object cleanup library for Luau on Roblox. It tracks instances, connections, functions, promises, and custom objects, ensuring deterministic destruction and preventing memory leaks.

## Documentation Index

- [API Reference](file:///c:/Lua/Libraries/Janitor/docs/api-reference.md): Complete class definition, types, and method signatures.
- [Architecture & Design](file:///c:/Lua/Libraries/Janitor/docs/architecture-and-design.md): System design, weak-key registry model, and trade-offs.
- [Performance & Memory Profile](file:///c:/Lua/Libraries/Janitor/docs/performance-and-memory.md): Algorithmic complexity bounds and thread cleanup mechanics.
- [Failure Modes & Exception Guarantees](file:///c:/Lua/Libraries/Janitor/docs/failure-modes.md): Exception safety, re-destroy suppression, and edge cases.
- [Executable Examples](file:///c:/Lua/Libraries/Janitor/docs/examples.md): Practical Luau usage patterns and code samples.

## Quick Start

```luau
local Janitor = require(path.to.Janitor)
local janitor = Janitor.new()

-- Track a connection
janitor:Add(workspace.ChildAdded:Connect(print), "Disconnect")

-- Track an Instance
local part = Instance.new("Part")
janitor:Add(part, "Destroy")

-- Clean up everything
janitor:Cleanup()
```
