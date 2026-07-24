# Janitor Architecture & Design

## System Overview

Janitor manages lifecycle tracking using weak-key tables to prevent memory leaks while guaranteeing deterministic cleanup upon destruction.

```
┌──────────────────────────────────────────────┐
│                  Janitor                     │
├──────────────────────┬───────────────────────┤
│ Janitors[self]       │ Internal Object Map   │
│ (Weak key metadata)  │ [Index] -> Object     │
└──────────────────────┴───────────────────────┘
          │
          ▼
   Cleanup Invocation
   ├── Function   -> Executed directly
   ├── Thread     -> task.cancel deferred/fast
   ├── Instance   -> Instance:Destroy()
   └── Object     -> Object[methodName](Object)
```

## Internal Storage Model
Janitor maintains an internal weak table `Janitors` keyed by the Janitor instance. This isolates internal tracked tables from public metatable key collision.

## Design Goals & Non-Goals

### Goals
- Deterministic resource deallocation.
- Seamless integration with Roblox `Instance`, `RBXScriptConnection`, functions, and promises.
- Zero-overhead index lookup for indexed objects.

### Non-Goals
- Automatic garbage collection without calling `:Cleanup()` or `:Destroy()`.
- Thread safety across multiple parallel Lua state threads (must operate on standard Luau thread context).
