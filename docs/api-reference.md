# Janitor API Reference

## Types

```luau
export type BooleanOrString = boolean | string

export type Janitor = {
    CurrentlyCleaning: boolean,
    SuppressInstanceReDestroy: boolean,
    UnsafeThreadCleanup: boolean,

    Add: <T>(self: Janitor, object: T, methodName: BooleanOrString?, index: any?) -> T,
    AddObject: <T, A...>(self: Janitor, constructor: { new: (A...) -> T }, methodName: BooleanOrString?, index: any?, A...) -> T,
    AddPooled: <T>(self: Janitor, object: T, pool: any, returnMethodName: string?) -> T,
    AddPromise: (self: Janitor, promiseObject: any, index: unknown?) -> any,

    Remove: (self: Janitor, index: any) -> Janitor,
    RemoveNoClean: (self: Janitor, index: any) -> Janitor,
    RemoveList: (self: Janitor, ...any) -> Janitor,
    RemoveListNoClean: (self: Janitor, ...any) -> Janitor,

    Get: (self: Janitor, index: any) -> any?,
    GetAll: (self: Janitor) -> { [any]: any },

    Cleanup: (self: Janitor) -> (),
    Destroy: (self: Janitor) -> (),

    LinkToInstance: (self: Janitor, object: Instance, allowMultiple: boolean?) -> RBXScriptConnection,
    LegacyLinkToInstance: (self: Janitor, object: Instance, allowMultiple: boolean?) -> RBXScriptConnection,
    LinkToInstances: (self: Janitor, ...Instance) -> Janitor,
}
```

## Constructor

### `Janitor.new(): Janitor`
Creates a new `Janitor` instance.

```luau
local janitor = Janitor.new()
```

## Static Methods

### `Janitor.Is(object: any): boolean`
Checks if the given object is a valid `Janitor` instance.

---

## Instance Methods

### `Janitor:Add<T>(object: T, methodName: BooleanOrString?, index: any?): T`
Adds an object to the Janitor cleanup queue. Returns the added object.
- `methodName`: Function/method name to invoke during cleanup. If `true`, assumes object is a function or thread.
- `index`: Optional key to store the object under for targeted removal.

### `Janitor:AddPromise(promiseObject: Promise, index: unknown?): Promise`
Adds a promise to the Janitor. If the Janitor is cleaned up while the promise is pending, the promise is automatically cancelled.

### `Janitor:Remove(index: any): Janitor`
Cleans up and removes the object stored at `index`.

### `Janitor:RemoveNoClean(index: any): Janitor`
Removes the object stored at `index` without invoking its cleanup handler.

### `Janitor:Cleanup()`
Cleans up all tracked objects and resets internal state.

### `Janitor:Destroy()`
Alias for `Janitor:Cleanup()`.
