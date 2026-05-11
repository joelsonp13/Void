-- Test script to verify design_tokens.lua loading
print("Testing design_tokens.lua loading...")

-- Test 1: Direct file read
print("Test 1: Reading file directly...")
local success, content = pcall(readfile, "design_tokens.lua")
if success and content and #content > 0 then
    print("✅ File read successfully, length:", #content)

    -- Test 2: Load as Lua module
    print("Test 2: Loading as Lua module...")
    local loadSuccess, tokens = pcall(function()
        return loadstring(content)()
    end)

    if loadSuccess and type(tokens) == "table" then
        print("✅ Module loaded successfully!")
        print("Spacing.XS:", tokens.Spacing.XS)
        print("Spacing.MD:", tokens.Spacing.MD)
        print("Radius.LG:", tokens.Radius.LG)
        print("ZIndex.Modal:", tokens.ZIndex.Modal)
    else
        print("❌ Failed to load module:", tokens)
    end
else
    print("❌ Failed to read file:", content)
end

print("Test completed.")