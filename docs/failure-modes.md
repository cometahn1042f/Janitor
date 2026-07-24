# Janitor Failure Modes & Exception Guarantees

## Exception Safety & Re-destroy Suppression

### Re-destroying Roblox Instances
When an `Instance` added to Janitor is already destroyed externally, invoking `:Destroy()` again might throw or log warnings depending on Roblox engine settings.
- Setting `janitor.SuppressInstanceReDestroy = true` wraps instance cleanup in a `pcall(game.Destroy, object)` block, suppressing engine error logs.

### Active Thread Cancellation
Attempting to cancel the currently running coroutine (`coroutine.running() == thread`) directly causes a runtime error. Janitor detects this condition and automatically defers cancellation to the next engine frame.

### Invalid Method Invocation
If a string method name is provided for cleanup (e.g. `"Destroy"`) but the target object lacks that method, Janitor safely handles the missing key without throwing unhandled exceptions.
