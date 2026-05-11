debugX = true

-- Carrega a biblioteca Rayfield Premium (Void Overhaul)
local Rayfield = loadstring(game:HttpGet('https://raw.githubusercontent.com/joelsonp13/Void/main/source.lua'))()

local Window = Rayfield:CreateWindow({
   Name = "Void Premium",
   Icon = 0,
   LoadingTitle = "Void Premium Overhaul",
   LoadingSubtitle = "by Lunara Void",
   Theme = "PremiumDark", -- 🔥 Tema premium ativado
   CommandPalette = true, -- Ctrl+P para buscar abas/comandos
   PerformanceFX = "Ultra", -- Animações completas (ripple, glow, bounce)

   DisableRayfieldPrompts = false,
   DisableBuildWarnings = false,

   ConfigurationSaving = {
      Enabled = true,
      FolderName = nil,
      FileName = "VoidHub"
   },

   Discord = {
      Enabled = false,
      Invite = "noinvitelink",
      RememberJoins = true
   },

   KeySystem = false,
   KeySettings = {
      Title = "Untitled",
      Subtitle = "Key System",
      Note = "No method of obtaining the key is provided",
      FileName = "Key",
      SaveKey = true,
      GrabKeyFromSite = false,
      Key = {"Hello"}
   }
})

-- Verifica se DesignTokens carregou corretamente
local dt = Rayfield:GetDesignTokens()
if dt then
   print("[VOID] DesignTokens carregado:", dt.Spacing and "OK" or "FAIL")
   print("[VOID] Performance Tier:", Rayfield:GetPerformanceTier())
   Rayfield:Notify({
      Title = "Void Premium",
      Content = "DesignTokens carregado com sucesso. Performance: " .. Rayfield:GetPerformanceTier(),
      Duration = 5
   })
else
   warn("[VOID] DesignTokens NÃO carregado - usando fallback inline")
   Rayfield:Notify({
      Title = "Void Premium",
      Content = "DesignTokens não encontrado. Usando fallback inline.",
      Duration = 5
   })
end

-- ========================
-- ABA PRINCIPAL
-- ========================
local MainTab = Window:CreateTab("Main", 'home')

MainTab:CreateSection("Features Premium")

-- Toggle com spring bounce (DesignTokens)
MainTab:CreateToggle({
   Name = "Ripple Effect (Ultra)",
   CurrentValue = true,
   Flag = "RippleToggle",
   Callback = function(Value)
      print("Ripple:", Value)
   end,
})

-- Slider com curvas suaves (DesignTokens)
MainTab:CreateSlider({
   Name = "Animation Speed",
   Range = {0, 100},
   Increment = 5,
   Suffix = "%",
   CurrentValue = 75,
   Flag = "AnimSpeed",
   Callback = function(Value)
      print("Speed:", Value)
   end,
})

-- Dropdown multi com busca
local multiDropdown = MainTab:CreateMultiDropdown({
   Name = "Módulos Ativos",
   Options = {"ESP", "Aimbot", "Fly", "Speed", "God Mode", "TP", "Inf Jump", "Noclip"},
   CurrentOption = {"ESP", "Aimbot", "Fly"},
   Flag = "Modules",
   SelectAll = true,
   ShowSelectionCount = true,
   ListSearch = true, -- 🔍 barra de filtro na lista
   Callback = function(Options)
      print("Módulos:", table.concat(Options, ", "))
   end,
})

-- SearchBox com histórico
MainTab:CreateSearchBox({
   Name = "Buscar Player",
   PlaceholderText = "Nome do jogador...",
   SaveRecent = true,
   ClearButton = true,
   Flag = "PlayerSearch",
   Callback = function(Text)
      if #Text > 0 then
         Rayfield:Notify({
            Title = "Busca",
            Content = "Procurando por: " .. Text,
            Duration = 2
         })
      end
   end,
})

MainTab:CreateDivider()

-- ========================
-- ABA FERRAMENTAS
-- ========================
local ToolsTab = Window:CreateTab("Tools", 'settings')

ToolsTab:CreateSection("Theme Switcher")

-- Troca rápida de temas premium
local themesDropdown = ToolsTab:CreateDropdown({
   Name = "Tema",
   Options = {"Default", "PremiumDark", "AMOLED", "Ocean", "Amethyst", "DarkBlue", "Bloom", "Light", "Serenity", "AmberGlow", "Green"},
   CurrentOption = {"PremiumDark"},
   Flag = "ThemeSelect",
   ListSearch = true,
   Callback = function(Options)
      Window.ModifyTheme(Options[1])
   end,
})

ToolsTab:CreateButton({
   Name = "Alternar Dev Overlay",
   Callback = function()
      Rayfield:EnableDevOverlay()
      Rayfield:Notify({
         Title = "Dev Overlay",
         Content = "FPS overlay ativado no canto superior direito",
         Duration = 3
      })
   end,
})

-- Console para debug
local console = ToolsTab:CreateConsole({
   Name = "Debug Console",
   MaxLines = 100,
})

ToolsTab:CreateButton({
   Name = "Testar Console",
   Callback = function()
      console:AddLine("[INFO] DesignTokens: " .. (Rayfield:GetDesignTokens() and "Loaded" or "Fallback"))
      console:AddLine("[INFO] Performance: " .. Rayfield:GetPerformanceTier())
      console:AddLine("[WARN]", Color3.fromRGB(220, 180, 60))
      console:AddLine("[ERROR] Test error message", Color3.fromRGB(200, 70, 70))
   end,
})

ToolsTab:CreateDivider()

ToolsTab:CreateSection("Hotkeys Globais")

-- Registra hotkeys premium
Rayfield:RegisterHotkey({
   Id = "quick_tp",
   Title = "Quick TP",
   DefaultKey = "T",
   Mode = "Toggle",
   Callback = function()
      print("[Hotkey] Quick TP ativado")
   end
})

Rayfield:RegisterHotkey({
   Id = "panic",
   Title = "Panic Mode",
   DefaultKey = "P",
   Mode = "Toggle",
   Callback = function()
      Rayfield:Notify({
         Title = "⚠️ PANIC",
         Content = "Todos os módulos desativados!",
         Duration = 3
      })
   end
})

local hotkeys = Rayfield:GetAllHotkeys()
local hkLabels = {}
for _, hk in ipairs(hotkeys) do
   table.insert(hkLabels, hk.Title .. " [" .. hk.Key .. "]")
end

ToolsTab:CreateLabel("Hotkeys: " .. table.concat(hkLabels, ", "))

-- ========================
-- ABA COMANDOS
-- ========================
local CmdTab = Window:CreateTab("Commands", 'terminal')

CmdTab:CreateSection("Command Palette (Ctrl+P)")

-- Registra comandos pra palette
Rayfield:RegisterCommand({
   Title = "Clear Console",
   Callback = function()
      console:Clear()
      Rayfield:Notify({Title = "Console", Content = "Console limpo!", Duration = 2})
   end
})

Rayfield:RegisterCommand({
   Title = "Toggle Theme Dark/Light",
   Callback = function()
      local currentTheme = themesDropdown.CurrentOption[1]
      local newTheme = currentTheme == "PremiumDark" and "Light" or "PremiumDark"
      Window.ModifyTheme(newTheme)
      themesDropdown:Set({newTheme})
   end
})

Rayfield:RegisterCommand({
   Title = "Show Gate Checklist",
   Callback = function()
      local checklist = Rayfield:GetGateChecklist()
      local text = "✅ Gate Checklist:\n"
      for _, item in ipairs(checklist) do
         text = text .. "  " .. item .. "\n"
      end
      console:AddLine(text)
   end
})

CmdTab:CreateParagraph({
   Title = "Como usar",
   Content = "Pressione Ctrl+P para abrir a palette de comandos. Digite para filtrar, use ↑↓ para navegar e Enter para executar."
})

CmdTab:CreateButton({
   Name = "Verificar Gate",
   Callback = function()
      local ok = Rayfield:GateCheck("example.lua")
      Rayfield:Notify({
         Title = "Gate Check",
         Content = ok and "✅ Todas as features premium ativas!" or "❌ DesignTokens não carregado",
         Duration = 3
      })
   end,
})

-- Context Menu demo (clique direito)
CmdTab:CreateButton({
   Name = "Demo Context Menu",
   Callback = function()
      local ctx = Rayfield:CreateContextMenu({
         Items = {
            { Title = "Copiar", Callback = function() print("Copiado!") end },
            { Title = "Colar", Callback = function() print("Colado!") end },
            { Divider = true },
            { Title = "Deletar", Callback = function() print("Deletado!") end, Color = Color3.fromRGB(200, 70, 70) },
         }
      })
      ctx:Show()
   end,
})

Rayfield:LoadConfiguration()

-- Notificação inicial
Rayfield:Notify({
   Title = "Void Premium Overhaul",
   Content = "Build UU2NX | v1.746 Premium\nDesignTokens: " .. (Rayfield:GetDesignTokens() and "OK" or "Fallback") .. "\nCtrl+P para abrir comandos",
   Duration = 8
})