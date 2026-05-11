-- Test script to verify dropdown closing logic fix
local Rayfield = loadstring(game:HttpGet('https://raw.githubusercontent.com/joelsonp13/Void/main/source.lua'))()

local Window = Rayfield:CreateWindow({
    Name = "Dropdown Test",
    LoadingTitle = "Testing Dropdown Fix",
    LoadingSubtitle = "by Lunara Void",
    ConfigurationSaving = {
        Enabled = false,
    },
})

local Tab = Window:CreateTab("Test Tab", 4483362458)

-- Create a dropdown with search enabled
local Dropdown = Tab:CreateDropdown({
    Name = "Test Dropdown",
    Options = {"Option 1", "Option 2", "Option 3", "Option 4", "Option 5"},
    CurrentOption = {"Option 1"},
    MultipleOptions = false,
    Flag = "TestDropdown",
    ListSearch = true,
    Callback = function(options)
        print("Selected:", options[1])
    end
})

-- Create a button to test clicking outside
local Button = Tab:CreateButton({
    Name = "Test Button",
    Callback = function()
        print("Button clicked!")
    end
})

print("Test script loaded. Open the dropdown and try clicking:")
print("1. Inside the dropdown list (should NOT close)")
print("2. On the dropdown header (should toggle)")
print("3. Outside the dropdown (should close)")
print("4. Try using the search box (should NOT close when typing)")