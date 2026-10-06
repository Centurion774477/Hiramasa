# Hiramasa

Lua has some rough spots. There's no native function or method to check if a value is in an array. There isn't even a way to split a string -- you have to use `gmatch`.

Hiramasa builds on top of Lua while preserving all of the original syntax; it is a preprocessor. Here's what Hiramasa adds.

## .includes?

This is used to check if a value is in an array. The cleanest way to implement this was to create a function in your file, so this is added to the top of your file:
```lua
local function contains(array, item)
	for _, part in members do
		if part == item then return true end
	end
	return false
end
```
Since you have the function in your file, any usages of `array.includes?(item)` gets transpiled into `contains(array, item)`.

You can also use these aliases depending on your context:
- `has?`
- `contains?`

## foreach

This is, naturally, used to iterate through an array. Lua makes this weirdly painful, requiring `ipairs` or `pairs` and giving you two variables instead of one.

Hiramasa states the obvious and lets you write:

```lua
foreach item in items do
```

Note that you can also use `for` instead of `foreach`. This is a common problem when you bounce between languages because some use `for` in foreach loops and some have a separate keyword.

This transpiles into:

```lua
for _, item in ipairs(items) do
```

## .blank?

This is inspired by Rails' method of the same name. The problem isn't Lua-specific, but I might as well add it because it solves a huge pain point and fits the design.

Much like `.includes?`, this uses a function under the hood. You'll see this function in all of your generated files:

```lua
local function isBlank(str)
    if type(str) == "number" then
        error("You cannot check if a number is blank. You passed an integer to isBlank()")
    end

    if str == nil then return true end
    if str == false then return true end
    if str == "" then return true end

    local trimmed = str:match("^%s*(.-)%s*$")
    if trimmed == "" then return true end

    return false
end
```

Because of that, your usages of the method will be transpiled into `isBlank(string)`. For example:

`maltese.blank?` => `isBlank(maltese)`

## Conclusion

That's all for now. I'm actively considering new features to add but I'm waiting for them to come out of a real need, and not just an assumption.

Cheers!
