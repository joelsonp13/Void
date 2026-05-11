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

-- ========================
-- ABA ELEMENTOS
-- ========================
local ElementsTab = Window:CreateTab("Elements", 'layout')

ElementsTab:CreateSection("Todos os Elementos Disponíveis")

-- Color Picker Premium
ElementsTab:CreateColorPicker({
   Name = "Cor do ESP",
   Color = Color3.fromRGB(0, 255, 120),
   Flag = "ESPColor",
   Callback = function(Value)
      print("Cor selecionada:", Value)
      Rayfield:Notify({
         Title = "Color Picker",
         Content = "Cor RGB: " .. math.floor(Value.R*255) .. ", " .. math.floor(Value.G*255) .. ", " .. math.floor(Value.B*255),
         Duration = 2
      })
   end
})

-- Keybind Element
ElementsTab:CreateKeybind({
   Name = "Atalho Rápido",
   CurrentKeybind = "F",
   HoldToInteract = false,
   Flag = "QuickKeybind",
   Callback = function(Keybind)
      local keyText = Keybind or "Desconhecido"
      print("Keybind pressionado:", keyText)
      Rayfield:Notify({Title = "Keybind", Content = "Atalho " .. keyText .. " ativado!", Duration = 2})
   end
})

-- Input Element
ElementsTab:CreateInput({
   Name = "Nome do Jogador",
   CurrentValue = "",
   PlaceholderText = "Digite o nome...",
   RemoveTextAfterFocusLost = false,
   Flag = "PlayerNameInput",
   Callback = function(Text)
      print("Nome digitado:", Text)
   end
})

-- Label Element
ElementsTab:CreateLabel("Label de Status", 4483362458, nil, false)

-- Paragraph Element
ElementsTab:CreateParagraph({
   Title = "Sobre Void Premium",
   Content = "Void Premium é a versão overhaul da Rayfield com todas as features premium ativadas:\n\n✅ DesignTokens avançado\n✅ Performance Ultra (ripple, glow, bounce)\n✅ Command Palette (Ctrl+P)\n✅ Context Menu\n✅ Hotkey System\n✅ Console Debug\n✅ Sidebar Support\n✅ Todos os temas premium\n✅ Multi-dropdown com busca\n✅ SearchBox com histórico"
})

ElementsTab:CreateDivider()

-- ========================
-- ABA AVANÇADO
-- ========================
local AdvancedTab = Window:CreateTab("Advanced", 'cpu')

AdvancedTab:CreateSection("Features Avançadas")

-- Sidebar Demo
AdvancedTab:CreateButton({
   Name = "Criar Sidebar",
   Callback = function()
      local sidebar = Rayfield:CreateSidebar({
         Name = "Void Sidebar",
         Collapsed = false
      })

      sidebar:AddCategory({
         Name = "Navegação",
         Children = {"Main", "Tools", "Commands", "Elements", "Advanced"}
      })

      sidebar:AddItem({
         Name = "Abrir Console",
         Callback = function()
            Elements.UIPageLayout:JumpTo(Elements["Elements"])
         end
      })

      sidebar:AddItem({
         Name = "Toggle Dev Overlay",
         Callback = function()
            Rayfield:EnableDevOverlay()
         end
      })

      Rayfield:Notify({
         Title = "Sidebar",
         Content = "Sidebar criado! Você pode recolher/expandir com o botão no canto superior direito.",
         Duration = 4
      })
   end
})

-- Performance Tier Info
AdvancedTab:CreateLabel("Performance Tier: " .. Rayfield:GetPerformanceTier(), nil, nil, false)

-- Theme Info
AdvancedTab:CreateLabel("Tema Atual: PremiumDark", nil, nil, false)

-- DesignTokens Info
local dt = Rayfield:GetDesignTokens()
if dt then
   AdvancedTab:CreateLabel("DesignTokens: Carregado ✅", nil, Color3.fromRGB(0, 255, 120), false)
   AdvancedTab:CreateLabel("Spacing: XS=" .. dt.Spacing.XS .. ", SM=" .. dt.Spacing.SM .. ", MD=" .. dt.Spacing.MD, nil, nil, false)
   AdvancedTab:CreateLabel("ZIndex: Base=" .. dt.ZIndex.Base .. ", Modal=" .. dt.ZIndex.Modal, nil, nil, false)
else
   AdvancedTab:CreateLabel("DesignTokens: Fallback ⚠️", nil, Color3.fromRGB(255, 200, 0), false)
end

AdvancedTab:CreateDivider()

AdvancedTab:CreateSection("Notificações Avançadas")

AdvancedTab:CreateButton({
   Name = "Testar Notificações",
   Callback = function()
      -- Success notification
      Rayfield:Notify({
         Title = "✅ Sucesso",
         Content = "Operação concluída com sucesso!",
         Duration = 3,
         Image = 4483362458
      })

      -- Warning notification
      task.wait(1)
      Rayfield:Notify({
         Title = "⚠️ Aviso",
         Content = "Esta ação requer atenção especial.",
         Duration = 4,
         Image = 4483362458
      })

      -- Error notification
      task.wait(1)
      Rayfield:Notify({
         Title = "❌ Erro",
         Content = "Não foi possível completar a operação.",
         Duration = 5,
         Image = 4483362458
      })

      -- Info notification
      task.wait(1)
      Rayfield:Notify({
         Title = "ℹ️ Informação",
         Content = "Void Premium está usando Performance Tier: " .. Rayfield:GetPerformanceTier(),
         Duration = 3,
         Image = 4483362458
      })
   end
})

-- ========================
-- ABA CONFIGURAÇÕES
-- ========================
local SettingsTab = Window:CreateTab("Settings", 'settings')

SettingsTab:CreateSection("Configurações do Void Premium")

-- Toggle para Command Palette
SettingsTab:CreateToggle({
   Name = "Command Palette (Ctrl+P)",
   CurrentValue = true,
   Flag = "CmdPaletteToggle",
   Callback = function(Value)
      print("Command Palette:", Value and "Ativado" or "Desativado")
   end
})

-- Dropdown para Performance Tier
SettingsTab:CreateDropdown({
   Name = "Performance Tier",
   Options = {"Low", "Medium", "Ultra"},
   CurrentOption = {"Ultra"},
   Flag = "PerfTier",
   Callback = function(Options)
      print("Performance Tier selecionado:", Options[1])
   end
})

-- Slider para Transparência
SettingsTab:CreateSlider({
   Name = "Transparência da UI",
   Range = {0, 100},
   Increment = 5,
   Suffix = "%",
   CurrentValue = 0,
   Flag = "UITransparency",
   Callback = function(Value)
      print("Transparência:", Value .. "%")
   end
})

SettingsTab:CreateDivider()

SettingsTab:CreateSection("Informações do Sistema")

SettingsTab:CreateParagraph({
   Title = "Void Premium Overhaul",
   Content = "Build: UU2NX\nVersão: 1.746 Premium\nDesenvolvedor: Lunara Void\n\nTodas as features premium estão ativadas e funcionando!"
})

SettingsTab:CreateButton({
   Name = "Salvar Configuração",
   Callback = function()
      Rayfield:Notify({
         Title = "Configuração",
         Content = "Configurações salvas com sucesso!",
         Duration = 2
      })
   end
})

SettingsTab:CreateButton({
   Name = "Carregar Configuração",
   Callback = function()
      Rayfield:LoadConfiguration()
      Rayfield:Notify({
         Title = "Configuração",
         Content = "Configurações carregadas!",
         Duration = 2
      })
   end
})

Rayfield:LoadConfiguration()

-- Notificação inicial
Rayfield:Notify({
   Title = "Void Premium Overhaul",
   Content = "Build UU2NX | v1.746 Premium\nDesignTokens: " .. (Rayfield:GetDesignTokens() and "OK" or "Fallback") .. "\nCtrl+P para abrir comandos\nTodas as features premium ativadas!",
   Duration = 8
})

-- Notificação de boas-vindas
task.wait(2)
Rayfield:Notify({
   Title = "👑 Bem-vindo",
   Content = "Você está usando Void Premium Overhaul - a versão mais poderosa da Rayfield!\n\nExplore todas as abas para ver todas as features.",
   Duration = 10
})

-- Dica de uso
task.wait(4)
Rayfield:Notify({
   Title = "💡 Dica",
   Content = "Pressione Ctrl+P para abrir a Command Palette e buscar abas/comandos rapidamente!",
   Duration = 6
})
