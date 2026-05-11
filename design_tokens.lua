--[[
	╔═══════════════════════════════════════════════════════════════╗
	║              RAYFIELD DESIGN TOKENS — v1.746               ║
	║              Referência completa de tokens                  ║
	╚═══════════════════════════════════════════════════════════════╝

	📦 COMO USAR:
	   local Tokens = require(script.Parent.design_tokens)
	   
	   -- Spacing
	   local padding = Tokens.Spacing.MD  -- 12
	   local gap = Tokens.Spacing.LG      -- 16
	   
	   -- Radius
	   local corner = Tokens.Radius.LG    -- 12
	   
	   -- ZIndex (layers)
	   frame.ZIndex = Tokens.ZIndex.Modal  -- 30
	   
	   -- Motion (TweenInfo centralizado)
	   Tokens.Tween(frame, { BackgroundTransparency = 0 }, "Smooth", "Medium")
	   
	   -- Typography
	   Tokens.ApplyTypographyRole(textLabel, "Title", Color3.fromRGB(255,255,255))
	   
	   -- Theme merge (temas parciais)
	   local myTheme = Tokens.MergeTheme(RayfieldLibrary.Theme.Default, { Background = Color3.new(0,0,0) })
	   
	   -- State colors
	   local states = Tokens.StateColors(theme)
	   local hoverColor = states.Hover
	   
	   -- Shadow tier
	   Tokens.ApplyShadowTier(myStroke, myShadow, "medium")
	   
	   -- Semantic colors
	   local sem = Tokens.SemanticFromTheme(theme)
	   local successColor = sem.Success
	
	📋 TABELA DE REFERÊNCIA RÁPIDA:
	
	   Tokens.Spacing:
	       XS=4 | SM=8 | MD=12 | LG=16 | XL=24
	   
	   Tokens.Radius:
	       SM=6 | MD=8 | LG=12 | XL=16
	   
	   Tokens.Opacity:
	       Backdrop=0.5 | Disabled=0.45 | Hint=0.35 | MutedStroke=0.85
	   
	   Tokens.ZIndex:
	       Base=1 | Sidebar=5 | Dropdown=10 | DropdownItem=50 | Overlay=20
	       Modal=30 | Notifications=40 | Tooltip=50
	   
	   Tokens.Shadow (tiers): weak → medium → strong → glow → neon
	       Cada tier define: imageTransparency + strokeThickness
	   
	   Tokens.PerformanceFX:
	       Low | Medium | Ultra
	       Low: multiplicador 0.55 nos tweens
	       Medium: multiplicador 1.0
	       Ultra: multiplicador 1.08
	   
	   Tokens.Typography (roles):
	       Title   → Font=GothamBold     Size=18 | Weight=Bold
	       Subtitle → Font=GothamMedium  Size=15
	       Body    → Font=Gotham         Size=14
	       Caption → Font=Gotham         Size=12
	       Hint    → Font=Gotham         Size=12 | Transparency=0.35
	   
	   Tokens.GetMotion(name, tier?) → TweenInfo
	       Nomes: Instant(0.05s) | Fast(0.15s) | Smooth(0.35s)
	              Bouncy(0.45s) | Elastic(0.55s) | Slow(0.75s)
	              Emphasis(0.65s - Exponential)
	   
	   Tokens.Tween(instance, props, motionName?, tier?) → Tween
	       Shorthand: Tokens.Tween(frame, {Size = UDim2.new(1,0,1,0)}, "Bouncy")
	   
	   OverlaySystem (source.lua): use show({ detachContentBeforeDestroy = holderFolder })
	       para modais reutilizáveis (ex.: command palette) sem destruir o painel ao fechar.
	   
	   Tokens.StateColors(theme) → { Hover, Idle, Pressed, Focused, Disabled, Selected }
	   
	   Tokens.SemanticFromTheme(theme) → { Success, Warning, Error, Info, Muted }
	   
	   Tokens.ApplyTypographyRole(textObject, role, themeTextColor?)
	       Aplica Font + TextSize + LineHeight do role
	   
	   Tokens.MergeTheme(default, override?) → theme
	       Preenche chaves faltando do tema base
	   
	   Tokens.ApplyShadowTier(uiStroke?, imageShadow?, tierName?)
	       Aplica espessura + transparência do tier
	
	🎯 LINGUAGEM DE ANIMAÇÃO (Motion):
	   - Instant: feedback imediato (hover micro, clique)
	   - Fast: transições rápidas (hover, foco, resize)
	   - Smooth: abertura de painéis, fades padrão
	   - Bouncy: spring de toggles, microinterações
	   - Elastic: key shake, erro
	   - Slow: saída de notificações, fades longos
	   - Emphasis: notificações entrando, destaque
	
	🔧 PERFORMANCE TIERS:
	   Low:   tweens 55% mais rápidos, sem ripple, sem glow
	   Medium: padrão desktop
	   Ultra:  tweens 8% mais lentos, microinterações completas
	
	📐 REGRAS DE CONSISTÊNCIA:
	   - Todo novo componente usa Tokens.Spacing para padding
	   - Todo novo popup usa Tokens.ZIndex
	   - Toda animação usa Tokens.GetMotion ou Tokens.Tween
	   - Todo hover usa Tokens.StateColors(theme).Hover
	   - Toda sombra usa Tokens.ApplyShadowTier
	   - Todo texto usa Tokens.ApplyTypographyRole
]]

local TweenService = game:GetService("TweenService")

local M = {}

-- Spacing scale (px)
M.Spacing = {
	XS = 4,
	SM = 8,
	MD = 12,
	LG = 16,
	XL = 24,
}

M.Radius = {
	SM = 6,
	MD = 8,
	LG = 12,
	XL = 16,
}

M.Opacity = {
	Backdrop = 0.5,
	Disabled = 0.45,
	Hint = 0.35,
	MutedStroke = 0.85,
}

M.ZIndex = {
	Base = 1,
	-- Barra lateral opcional (CreateSidebar): acima do conteúdo base, abaixo de dropdowns
	Sidebar = 5,
	Dropdown = 10,
	DropdownItem = 50,
	Overlay = 20,
	Modal = 30,
	Notifications = 40,
	Tooltip = 50,
}

-- Ícones (UDim2 tamanho alvo; usar com ImageLabel.Size)
M.IconSize = {
	SM = UDim2.fromOffset(16, 16),
	MD = UDim2.fromOffset(20, 20),
	LG = UDim2.fromOffset(24, 24),
}

-- Shadow: ImageTransparency targets for layered shadow images (weak = more visible shadow image = lower transparency)
M.Shadow = {
	weak = { imageTransparency = 0.92, strokeThickness = 1 },
	medium = { imageTransparency = 0.85, strokeThickness = 1 },
	strong = { imageTransparency = 0.78, strokeThickness = 1 },
	glow = { imageTransparency = 0.65, strokeThickness = 2 },
	neon = { imageTransparency = 0.5, strokeThickness = 2 },
}

M.PerformanceFX = {
	Low = "Low",
	Medium = "Medium",
	Ultra = "Ultra",
}

local perfMultipliers = {
	Low = 0.55,
	Medium = 1,
	Ultra = 1.08,
}

-- Typography roles (Roblox: Font + TextSize; LineHeight via TextLineHeight when available)
M.Typography = {
	Title = {
		Font = Enum.Font.GothamBold,
		TextSize = 18,
		TextLineHeight = 1.15,
	},
	Subtitle = {
		Font = Enum.Font.GothamMedium,
		TextSize = 15,
		TextLineHeight = 1.2,
	},
	Body = {
		Font = Enum.Font.Gotham,
		TextSize = 14,
		TextLineHeight = 1.25,
	},
	Caption = {
		Font = Enum.Font.Gotham,
		TextSize = 12,
		TextLineHeight = 1.3,
	},
	Hint = {
		Font = Enum.Font.Gotham,
		TextSize = 12,
		TextLineHeight = 1.3,
		TextTransparency = 0.35,
	},
}

-- Motion presets: single easing language (Quint/Quad/Back/Elastic) — map all UI to these names
local motionDefs = {
	Instant = { duration = 0.05, style = Enum.EasingStyle.Quad, dir = Enum.EasingDirection.Out },
	Fast = { duration = 0.15, style = Enum.EasingStyle.Quad, dir = Enum.EasingDirection.Out },
	Smooth = { duration = 0.35, style = Enum.EasingStyle.Quint, dir = Enum.EasingDirection.Out },
	Bouncy = { duration = 0.45, style = Enum.EasingStyle.Back, dir = Enum.EasingDirection.Out },
	Elastic = { duration = 0.55, style = Enum.EasingStyle.Elastic, dir = Enum.EasingDirection.Out },
	Slow = { duration = 0.75, style = Enum.EasingStyle.Quint, dir = Enum.EasingDirection.Out },
	-- Legacy alias: exponential-style long fades
	Emphasis = { duration = 0.65, style = Enum.EasingStyle.Exponential, dir = Enum.EasingDirection.Out },
}

function M.GetMotion(name: string, performanceTier: string?): TweenInfo
	local tier = performanceTier or "Medium"
	local mult = perfMultipliers[tier] or 1
	local def = motionDefs[name] or motionDefs.Smooth
	local d = def.duration * mult
	if tier == "Low" and name ~= "Instant" then
		d = math.max(0.08, d * 0.65)
	end
	if name == "Instant" then
		d = 0.05
	end
	return TweenInfo.new(d, def.style, def.dir)
end

function M.Tween(instance: Instance, props: { [string]: any }, motionName: string?, performanceTier: string?): Tween
	return TweenService:Create(instance, M.GetMotion(motionName or "Smooth", performanceTier), props)
end

-- Semantic colors optional on theme; fallback uses existing Rayfield keys
function M.SemanticFromTheme(theme: { [string]: any }): { Success: Color3, Warning: Color3, Error: Color3, Info: Color3, Muted: Color3 }
	return {
		Success = theme.Success or theme.SliderProgress or Color3.fromRGB(80, 200, 120),
		Warning = theme.Warning or Color3.fromRGB(220, 180, 60),
		Error = theme.Error or Color3.fromRGB(200, 70, 70),
		Info = theme.Info or theme.SliderBackground or Color3.fromRGB(80, 160, 220),
		Muted = theme.MutedText
			or Color3.new(
				math.clamp(theme.TextColor.R * 0.65, 0, 1),
				math.clamp(theme.TextColor.G * 0.65, 0, 1),
				math.clamp(theme.TextColor.B * 0.65, 0, 1)
			),
	}
end

function M.ApplyTypographyRole(textObject: TextLabel | TextBox, role: string, themeTextColor: Color3?)
	local spec = M.Typography[role] or M.Typography.Body
	textObject.Font = spec.Font
	textObject.TextSize = spec.TextSize
	if spec.TextLineHeight and (textObject:IsA("TextLabel") or textObject:IsA("TextBox")) then
		pcall(function()
			(textObject :: any).TextLineHeight = spec.TextLineHeight
		end)
	end
	if themeTextColor then
		textObject.TextColor3 = themeTextColor
	end
	if spec.TextTransparency ~= nil then
		textObject.TextTransparency = spec.TextTransparency
	end
end

-- Flat theme merge: fills missing keys from default theme (backward compatible partial custom themes)
function M.MergeTheme(defaultTheme: { [string]: any }, override: { [string]: any }?): { [string]: any }
	if not override then
		return defaultTheme
	end
	local out = table.clone(defaultTheme)
	for k, v in pairs(override) do
		out[k] = v
	end
	return out
end

-- Interaction state helpers (colors derived from theme; optional explicit overrides later)
function M.StateColors(theme: { [string]: any })
	return {
		Hover = theme.ElementBackgroundHover or theme.ElementBackground,
		Idle = theme.ElementBackground,
		Pressed = theme.ElementBackgroundHover,
		Focused = theme.InputBackground,
		Disabled = theme.SecondaryElementBackground or theme.ElementBackground,
		Selected = theme.DropdownSelected or theme.TabBackgroundSelected,
	}
end

function M.ApplyShadowTier(uiStroke: UIStroke?, imageShadow: ImageLabel?, tierName: string?)
	local tier = tierName and M.Shadow[tierName] or M.Shadow.medium
	if uiStroke then
		uiStroke.Thickness = tier.strokeThickness
	end
	if imageShadow then
		imageShadow.ImageTransparency = tier.imageTransparency
	end
end

return M
