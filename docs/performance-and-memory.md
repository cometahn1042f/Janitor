# Janitor Performance & Memory Profile

## Complexity Bounds

| Operation | Time Complexity | Space Complexity |
| :--- | :--- | :--- |
| `Janitor.new()` | $O(1)$ | $O(1)$ |
| `Janitor:Add()` | $O(1)$ | $O(1)$ |
| `Janitor:Get(index)` | $O(1)$ | $O(1)$ |
| `Janitor:Remove(index)` | $O(1)$ | $O(1)$ |
| `Janitor:Cleanup()` | $O(N)$ | $O(1)$ deallocation |

## Thread Cleanup Execution Mechanics

Janitor supports two thread cancellation modes:
- **Safe Mode (`UnsafeThreadCleanup = false`)**: Defers thread cancellation using `task.defer(task.cancel, thread)`. Prevents stack corruption during active thread execution.
- **Fast Mode (`UnsafeThreadCleanup = true`)**: Uses `fastDefer` for immediate micro-task scheduling when latency-sensitive thread termination is required.
