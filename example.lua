debugX = true

-- Carrega a biblioteca Rayfield do repositório GitHub
local Rayfield = loadstring(game:HttpGet('https://raw.githubusercontent.com/joelsonp13/Void/main/source.lua'))()

local Window = Rayfield:CreateWindow({
   Name = "Rayfield Example Window",
   Icon = 0, -- Icon in Topbar. Can use Lucide Icons (string) or Roblox Image (number). 0 to use no icon (default).
   LoadingTitle = "Rayfield Interface Suite",
   LoadingSubtitle = "by Sirius",
   Theme = "Default", -- "PremiumDark", "AMOLED", etc. Partial custom themes merge with Default keys.
   CommandPalette = false, -- true: Ctrl+P palette (abas + Rayfield:RegisterCommand)
   PerformanceFX = "Medium", -- "Low" | "Medium" | "Ultra" — afeta duração das tweens dos tokens
   -- Tab:CreateSearchBox({ SaveRecent = true }) grava últimas pesquisas em Rayfield/SearchRecent.json
   -- Tab:CreateMultiDropdown({ ListSearch = true, ... }) adiciona caixa "Filtrar opções" na lista

   DisableRayfieldPrompts = false,
   DisableBuildWarnings = false, -- Prevents Rayfield from warning when the script has a version mismatch with the interface

   ConfigurationSaving = {
      Enabled = true,
      FolderName = nil, -- Create a custom folder for your hub/game
      FileName = "Big Hub"
   },

   Discord = {
      Enabled = false, -- Prompt the user to join your Discord server if their executor supports it
      Invite = "noinvitelink", -- The Discord invite code, do not include discord.gg/. E.g. discord.gg/ ABCD would be ABCD
      RememberJoins = true -- Set this to false to make them join the discord every time they load it up
   },

   KeySystem = false, -- Set this to true to use our key system
   KeySettings = {
      Title = "Untitled",
      Subtitle = "Key System",
      Note = "No method of obtaining the key is provided", -- Use this to tell the user how to get a key
      FileName = "Key", -- It is recommended to use something unique as other scripts using Rayfield may overwrite your key file
      SaveKey = true, -- The user's key will be saved, but if you change the key, they will be unable to use your script
      GrabKeyFromSite = false, -- If this is true, set Key below to the RAW site you would like Rayfield to get the key from
      Key = {"Hello"} -- List of keys that will be accepted by the system, can be RAW file links (pastebin, github etc) or simple strings ("hello","key22")
   }
})

local Tab = Window:CreateTab("Tab 1", 4483362458) -- Title, Image
local Tab2 = Window:CreateTab("Tab 2", 'key-round') -- Title, Image (Lucide icon)

local Section = Tab:CreateSection("Section Example")

local Button = Tab:CreateButton({
   Name = "Change Theme",
   Callback = function()
      Window.ModifyTheme('DarkBlue')
   end,
})

local Toggle = Tab:CreateToggle({
   Name = "Toggle Example",
   CurrentValue = false,
   Flag = "Toggle1adwawd",
   Callback = function(Value)
      print("Toggle value changed to:", Value)
   end,
})

local ColorPicker = Tab:CreateColorPicker({
   Name = "Color Picker",
   Color = Color3.fromRGB(255,255,255),
   Flag = "ColorPicker1awd",
   Callback = function(Value)
      print("Color selected:", Value)
   end
})

local Slider = Tab:CreateSlider({
   Name = "Slider Example",
   Range = {0, 100},
   Increment = 10,
   Suffix = "Bananas",
   CurrentValue = 40,
   Flag = "Slider1dawd",
   Callback = function(Value)
      print("Slider value:", Value)
   end,
})

local Input = Tab:CreateInput({
   Name = "Input Example",
   CurrentValue = "Helo",
   PlaceholderText = "Adaptive Input",
   RemoveTextAfterFocusLost = false,
   Flag = 'Input1',
   Callback = function(Text)
      print("Input text:", Text)
   end,
})

local thoptions = {}
for themename, theme in pairs(Rayfield.Theme) do
   table.insert(thoptions, themename)
end

local Dropdown = Tab:CreateDropdown({
   Name = "Theme",
   Options = thoptions,
   CurrentOption = {"Default"},
   MultipleOptions = false,
   Flag = "Dropdown1",
   Callback = function(Options)
      Window.ModifyTheme(Options[1])
   end,
})

local Keybind = Tab:CreateKeybind({
   Name = "Keybind Example",
   CurrentKeybind = "Q",
   HoldToInteract = false,
   Flag = "Keybind1",
   Callback = function(Keybind)
      print("Keybind pressed:", Keybind)
   end,
})

local Label = Tab:CreateLabel("Label Example")

local Label2 = Tab:CreateLabel("Warning", 4483362458, Color3.fromRGB(255, 159, 49),  true)

local Paragraph = Tab:CreateParagraph({Title = "Paragraph Example", Content = "This is an example paragraph showing how to add text content to your UI."})


-- Tab 2 elements
local Section2 = Tab2:CreateSection("Section")

local ColorPicker2 = Tab2:CreateColorPicker({
   Name = "Color Picker 2",
   Color = Color3.fromRGB(255,255,255),
   Flag = "ColorPicfsefker1",
   Callback = function(Value)
   end
})

local Slider2 = Tab2:CreateSlider({
   Name = "Slider Example 2",
   Range = {0, 100},
   Increment = 10,
   Suffix = "Bananas",
   CurrentValue = 80,
   Flag = "Slidefefsr1",
   Callback = function(Value)
   end,
})

local Input2 = Tab2:CreateInput({
   Name = "Input Example 2",
   CurrentValue = '',
   PlaceholderText = "Input Placeholder",
   Flag = 'dawdawd',
   RemoveTextAfterFocusLost = false,
   Callback = function(Text)
   end,
})

Rayfield:LoadConfiguration()