# Lifecycles

Lifecycles allow developers to easily bind all controller methods with a set name to a specific event. This is quite useful in places where code tends to repeat multiple times. Lifecycles offer a quick fix to these issues, and it is also efficient.

## Usage

Usage of lifecycles is very minimal and simple. Here's how to use one:

### Module 1
```luau
local MyLifecycle = Lumin.Lifecycle("MyLifecycle")
MyLifecycle:Fire("Hello!!!")
```

### Module 2
```luau
local function MyLifecycle(printer: string)
    print(printer) -- Output: Hello!!!
end
```

## Custom Callbacks

By default, a callback is automatically assigned. This callback has access to the lifecycle's listeners (what functions it is hooked onto) and allows you to run them in a few different ways. The regular nature of this is a `task.spawn` to prevent any yielding inside of the main framework thread. Sometimes you may want these listeners to yield though, so here's how you can achieve that:

### Module 1
```luau
local MyLifecycle = Lumin.Lifecycle("MyYieldingLifecycle", function(lifecycle, ...)
    for _, listener in lifecycle.Listeners do
		listener(...)
	end
end)

MyLifecycle:Fire("Did I go first or second?")
```

### Module 2
```luau
local function MyYieldingLifecycle(printer: string)
    task.wait(5)
    print(printer) -- Output: Did I go first or second?
end
```

### Module 3
```luau
local function MyYieldingLifecycle(printer: string)
    task.wait(5)
    print(printer) -- Output: Did I go first or second?
end
```

## Default Lifecycles

For ease of use, a few default lifecycle types are automatically provided. No extra configuration needed, all you have to do is create a new lifecycle with the specific name. Here's a list of the available lifecycles:

- **PostSimulation**
- **PreSimulation**
- **PreRender** Client only!
- **PreAnimation** Client only!
- **PlayerAdded**
- **PlayerRemoving**