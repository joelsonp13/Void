--[[

	Rayfield Interface Suite — Premium Edition
	by Sirius + Void Premium Overhaul

	shlex  | Designing + Programming
	iRay   | Programming
	Max    | Programming
	Damian | Programming

	Build UU2NX | v1.746 Premium

]]

-- Environment Check (precisa ser definido ANTES de qualquer uso de useStudio/script)
local function getService(name)
	local service = game:GetService(name)
	return if cloneref then cloneref(service) else service
end
local HttpService = getService('HttpService')
local RunService = getService('RunService')
local useStudio = RunService:IsStudio() or false

-- Services (definidos ANTES do DesignTokens para evitar nil)
local UserInputService = getService("UserInputService")
local GuiService = getService("GuiService")
local TweenService = getService("TweenService")
local Players = getService("Players")
local CoreGui = getService("CoreGui")

-- Carrega Design Tokens (Fase 1c+)
-- Tenta carregar localmente (Studio), depois via HTTP (executors), por último fallback inline
local Tokens = nil
if useStudio and script and script.Parent and script.Parent:FindFirstChild("design_tokens") then
	local ok, result = pcall(require, script.Parent.design_tokens)
	if ok and type(result) == "table" then
		Tokens = result
	end
end
if not Tokens then
	-- Tenta carregar via HTTP (para executors que não têm o módulo local)
	local fetchSuccess, fetchResult = pcall(readfile, "design_tokens.lua")
	if fetchSuccess and #fetchResult > 0 then
		local execSuccess, execResult = pcall(function()
			return loadstring(fetchResult)()
		end)
		if execSuccess and type(execResult) == "table" then
			Tokens = execResult
		end
	end
end
if not Tokens then
	-- Fallback inline mínimo caso design_tokens.lua não exista (assinatura alinhada com o módulo real)
	Tokens = {
		Spacing = { XS = 4, SM = 8, MD = 12, LG = 16, XL = 24 },
		Radius = { SM = 6, MD = 8, LG = 12, XL = 16 },
		ZIndex = { Base = 1, Sidebar = 5, Dropdown = 10, Overlay = 20, Modal = 30, Notifications = 40, Tooltip = 50 },
		GetMotion = function(name, performanceTier)
			local defs = {
				Instant = { duration = 0.05, style = Enum.EasingStyle.Quad, dir = Enum.EasingDirection.Out },
				Fast = { duration = 0.15, style = Enum.EasingStyle.Quad, dir = Enum.EasingDirection.Out },
				Smooth = { duration = 0.35, style = Enum.EasingStyle.Quint, dir = Enum.EasingDirection.Out },
				Bouncy = { duration = 0.45, style = Enum.EasingStyle.Back, dir = Enum.EasingDirection.Out },
				Elastic = { duration = 0.55, style = Enum.EasingStyle.Elastic, dir = Enum.EasingDirection.Out },
				Slow = { duration = 0.75, style = Enum.EasingStyle.Quint, dir = Enum.EasingDirection.Out },
				Emphasis = { duration = 0.65, style = Enum.EasingStyle.Exponential, dir = Enum.EasingDirection.Out },
			}
			local def = defs[name] or defs.Smooth
			return TweenInfo.new(def.duration, def.style, def.dir)
		end,
		Tween = function(instance, props, motionName, performanceTier)
			return TweenService:Create(instance, Tokens.GetMotion(motionName or "Smooth", performanceTier), props)
		end,
		MergeTheme = function(defaultTheme, override)
			if not override then return defaultTheme end
			local out = table.clone(defaultTheme)
			for k, v in pairs(override) do out[k] = v end
			return out
		end,
		StateColors = function(theme)
			return {
				Hover = theme.ElementBackgroundHover or theme.ElementBackground,
				Idle = theme.ElementBackground,
				Pressed = theme.ElementBackgroundHover,
				Focused = theme.InputBackground,
				Disabled = theme.SecondaryElementBackground or theme.ElementBackground,
				Selected = theme.DropdownSelected or theme.TabBackgroundSelected,
			}
		end,
		SemanticFromTheme = function(theme)
			return {
				Success = theme.Success or theme.SliderProgress or Color3.fromRGB(80, 200, 120),
				Warning = theme.Warning or Color3.fromRGB(220, 180, 60),
				Error = theme.Error or Color3.fromRGB(200, 70, 70),
				Info = theme.Info or theme.SliderBackground or Color3.fromRGB(80, 160, 220),
				Muted = theme.MutedText or Color3.new(
					math.clamp(theme.TextColor.R * 0.65, 0, 1),
					math.clamp(theme.TextColor.G * 0.65, 0, 1),
					math.clamp(theme.TextColor.B * 0.65, 0, 1)
				),
			}
		end,
		ApplyTypographyRole = function(textObject, role, themeTextColor)
			if themeTextColor then textObject.TextColor3 = themeTextColor end
		end,
		ApplyShadowTier = function(uiStroke, imageShadow, tierName)
			if uiStroke then uiStroke.Thickness = 1 end
			if imageShadow then imageShadow.ImageTransparency = 0.85 end
		end,
		Opacity = { Backdrop = 0.5, Disabled = 0.45, Hint = 0.35, MutedStroke = 0.85 },
	}
	warn("Rayfield Premium: design_tokens.lua not found, using inline fallback")
end

if debugX then
	warn('Initialising Rayfield Premium')
end

-- Loads and executes a function hosted on a remote URL. Cancels the request if the requested URL takes too long to respond.
-- Errors with the function are caught and logged to the output
local function loadWithTimeout(url: string, timeout: number?): ...any
	assert(type(url) == "string", "Expected string, got " .. type(url))
	timeout = timeout or 5
	local requestCompleted = false
	local success, result = false, nil

	local requestThread = task.spawn(function()
		local fetchSuccess, fetchResult = pcall(game.HttpGet, game, url) -- game:HttpGet(url)
		-- If the request fails the content can be empty, even if fetchSuccess is true
		if not fetchSuccess or #fetchResult == 0 then
			if #fetchResult == 0 then
				fetchResult = "Empty response" -- Set the error message
			end
			success, result = false, fetchResult
			requestCompleted = true
			return
		end
		local content = fetchResult -- Fetched content
		local execSuccess, execResult = pcall(function()
			return loadstring(content)()
		end)
		success, result = execSuccess, execResult
		requestCompleted = true
	end)

	local timeoutThread = task.delay(timeout, function()
		if not requestCompleted then
			warn("Request for " .. url .. " timed out after " .. tostring(timeout) .. " seconds")
			task.cancel(requestThread)
			result = "Request timed out"
			requestCompleted = true
		end
	end)

	-- Wait for completion or timeout
	while not requestCompleted do
		task.wait()
	end
	-- Cancel timeout thread if still running when request completes
	if coroutine.status(timeoutThread) ~= "dead" then
		task.cancel(timeoutThread)
	end
	if not success then
		warn("Failed to process " .. tostring(url) .. ": " .. tostring(result))
	end
	return if success then result else nil
end

local _getgenv = rawget(_G, "getgenv")
local requestsDisabled = false
local customAssetId = nil
local secureMode = false
if _getgenv then
	local ok, result = pcall(function() return _getgenv().DISABLE_RAYFIELD_REQUESTS end)
	if ok and result then requestsDisabled = true end
	local ok2, result2 = pcall(function() return _getgenv().RAYFIELD_ASSET_ID end)
	if ok2 and type(result2) == "number" then customAssetId = result2 end
	local ok3, result3 = pcall(function() return _getgenv().RAYFIELD_SECURE end)
	if ok3 and result3 then secureMode = true end
end

if secureMode then
	local _error = error
	local _assert = assert
	warn = function(...) end
	print = function(...) end
	error = function(_, level) _error("", level) end
	assert = function(v, ...) return _assert(v) end
end

local secureWarnings = {}
local customAssets = {}

local function secureNotify(wType, title, content)
	if secureWarnings[wType] then return end
	secureWarnings[wType] = true
	task.spawn(function()
		while not RayfieldLibrary or not RayfieldLibrary.Notify do task.wait(0.5) end
		RayfieldLibrary:Notify({
			Title = title,
			Content = content,
			Duration = 8,
		})
	end)
end
local InterfaceBuild = 'UU2NX'
local Release = "Build 1.746"
local RayfieldFolder = "Rayfield"
local ConfigurationFolder = RayfieldFolder.."/Configurations"
local ConfigurationExtension = ".rfld"
local settingsTable = {
	General = {
		-- if needs be in order just make getSetting(name)
		rayfieldOpen = {Type = 'bind', Value = 'K', Name = 'Rayfield Keybind'},
		-- buildwarnings
		-- rayfieldprompts

	},
	System = {
		usageAnalytics = {Type = 'toggle', Value = true, Name = 'Anonymised Analytics'},
	}
}

-- Settings that have been overridden by the developer. These will not be saved to the user's configuration file
-- Overridden settings always take precedence over settings in the configuration file, and are cleared if the user changes the setting in the UI
local overriddenSettings: { [string]: any } = {} -- For example, overriddenSettings["System.rayfieldOpen"] = "J"
local function overrideSetting(category: string, name: string, value: any)
	overriddenSettings[category .. "." .. name] = value
end

local function getSetting(category: string, name: string): any
	if overriddenSettings[category .. "." .. name] ~= nil then
		return overriddenSettings[category .. "." .. name]
	elseif settingsTable[category][name] ~= nil then
		return settingsTable[category][name].Value
	end
end

-- If requests/analytics have been disabled by developer, set the user-facing setting to false as well
if requestsDisabled then
	overrideSetting("System", "usageAnalytics", false)
end

local settingsCreated = false
local settingsInitialized = false -- Whether the UI elements in the settings page have been set to the proper values
local prompt = nil
if useStudio and script and script.Parent and script.Parent:FindFirstChild("prompt") then
	prompt = require(script.Parent.prompt)
else
	prompt = loadWithTimeout('https://raw.githubusercontent.com/SiriusSoftwareLtd/Sirius/refs/heads/request/prompt.lua')
end
local requestFunc = (syn and syn.request) or (fluxus and fluxus.request) or (http and http.request) or http_request or request

-- Validate prompt loaded correctly
if not prompt and not useStudio then
	warn("Failed to load prompt library, using fallback")
	prompt = {
		create = function() end -- No-op fallback
	}
end


-- The function below provides a safe alternative for calling error-prone functions
-- Especially useful for filesystem function (writefile, makefolder, etc.)
local function callSafely(func, ...)
	if func then
		local success, result = pcall(func, ...)
		if not success then
			warn("Rayfield | Function failed with error: ", result)
			return false
		else
			return result
		end
	end
end

-- Ensures a folder exists by creating it if needed
local function ensureFolder(folderPath)
	if isfolder and not callSafely(isfolder, folderPath) then
		callSafely(makefolder, folderPath)
	end
end

local function loadSettings()
	local file = nil

	local success, result =	pcall(function()
		if callSafely(isfolder, RayfieldFolder) then
			if callSafely(isfile, RayfieldFolder..'/settings'..ConfigurationExtension) then
				file = callSafely(readfile, RayfieldFolder..'/settings'..ConfigurationExtension)
			end
		end

		-- for debug in studio
		if useStudio then
			file = [[
	{"General":{"rayfieldOpen":{"Value":"K","Type":"bind","Name":"Rayfield Keybind","Element":{"HoldToInteract":false,"Ext":true,"Name":"Rayfield Keybind","Set":null,"CallOnChange":true,"Callback":null,"CurrentKeybind":"K"}}},"System":{"usageAnalytics":{"Value":false,"Type":"toggle","Name":"Anonymised Analytics","Element":{"Ext":true,"Name":"Anonymised Analytics","Set":null,"CurrentValue":false,"Callback":null}}}}
]]
		end

		if file then
			local decodeSuccess, decodedFile = pcall(function() return HttpService:JSONDecode(file) end)
			if decodeSuccess then
				file = decodedFile
			else
				file = {}
			end
		else
			file = {}
		end


		if not settingsCreated then
			return
		end

		if next(file) ~= nil then
			for categoryName, settingCategory in pairs(settingsTable) do
				if file[categoryName] then
					for settingName, setting in pairs(settingCategory) do
						if file[categoryName][settingName] then
							setting.Value = file[categoryName][settingName].Value
							setting.Element:Set(getSetting(categoryName, settingName))
						end
					end
				end
			end
		-- If no settings saved, apply overridden settings only
		else
			for settingName, settingValue in overriddenSettings do
				local split = string.split(settingName, ".")
				assert(#split == 2, "Rayfield | Invalid overridden setting name: " .. settingName)
				local categoryName = split[1]
				local settingNameOnly = split[2]
				if settingsTable[categoryName] and settingsTable[categoryName][settingNameOnly] then
					settingsTable[categoryName][settingNameOnly].Element:Set(settingValue)
				end
			end
		end
		settingsInitialized = true
	end)

	if not success then 
		if writefile then
			warn('Rayfield had an issue accessing configuration saving capability.')
		end
	end
end

if debugX then
	warn('Now Loading Settings Configuration')
end

loadSettings()

if debugX then
	warn('Settings Loaded')
end

local ANALYTICS_TOKEN = "05de7f9fd320d3b8428cd1c77014a337b85b6c8efee2c5914f5ab5700c354b9a"

local reporter = nil
if not requestsDisabled and not useStudio then
	local fetchSuccess, fetchResult = pcall(readfile, "reporter.lua")
	if fetchSuccess and #fetchResult > 0 then
		local execSuccess, Analytics = pcall(function()
			return (loadstring(fetchResult) :: any)()
		end)
		if execSuccess and Analytics then
			pcall(function()
				reporter = Analytics.new({
					url          = "https://rayfield-collect.sirius-software-ltd.workers.dev",
					token        = ANALYTICS_TOKEN,
					product_name = "Rayfield",
					category     = "UILibrary",
				})
			end)
		end
	end
end

local promptUser = 2

if promptUser == 1 and prompt and type(prompt.create) == "function" then
	prompt.create(
		'Be cautious when running scripts',
	    [[Please be careful when running scripts from unknown developers. This script has already been ran.

<font transparency='0.3'>Some scripts may steal your items or in-game goods.</font>]],
		'Okay',
		'',
		function()

		end
	)
end

if debugX then
	warn('Moving on to continue initialisation')
end

local RayfieldLibrary = {
	Flags = {},
	Theme = {
		Default = {
			TextColor = Color3.fromRGB(240, 240, 240),

			Background = Color3.fromRGB(25, 25, 25),
			Topbar = Color3.fromRGB(34, 34, 34),
			Shadow = Color3.fromRGB(20, 20, 20),

			NotificationBackground = Color3.fromRGB(20, 20, 20),
			NotificationActionsBackground = Color3.fromRGB(230, 230, 230),

			TabBackground = Color3.fromRGB(80, 80, 80),
			TabStroke = Color3.fromRGB(85, 85, 85),
			TabBackgroundSelected = Color3.fromRGB(210, 210, 210),
			TabTextColor = Color3.fromRGB(240, 240, 240),
			SelectedTabTextColor = Color3.fromRGB(50, 50, 50),

			ElementBackground = Color3.fromRGB(35, 35, 35),
			ElementBackgroundHover = Color3.fromRGB(40, 40, 40),
			SecondaryElementBackground = Color3.fromRGB(25, 25, 25),
			ElementStroke = Color3.fromRGB(50, 50, 50),
			SecondaryElementStroke = Color3.fromRGB(40, 40, 40),

			SliderBackground = Color3.fromRGB(50, 138, 220),
			SliderProgress = Color3.fromRGB(50, 138, 220),
			SliderStroke = Color3.fromRGB(58, 163, 255),

			ToggleBackground = Color3.fromRGB(30, 30, 30),
			ToggleEnabled = Color3.fromRGB(0, 146, 214),
			ToggleDisabled = Color3.fromRGB(100, 100, 100),
			ToggleEnabledStroke = Color3.fromRGB(0, 170, 255),
			ToggleDisabledStroke = Color3.fromRGB(125, 125, 125),
			ToggleEnabledOuterStroke = Color3.fromRGB(100, 100, 100),
			ToggleDisabledOuterStroke = Color3.fromRGB(65, 65, 65),

			DropdownSelected = Color3.fromRGB(40, 40, 40),
			DropdownUnselected = Color3.fromRGB(30, 30, 30),

			InputBackground = Color3.fromRGB(30, 30, 30),
			InputStroke = Color3.fromRGB(65, 65, 65),
			PlaceholderColor = Color3.fromRGB(178, 178, 178),

			Success = Color3.fromRGB(90, 200, 130),
			Warning = Color3.fromRGB(220, 190, 80),
			Error = Color3.fromRGB(200, 75, 75),
			Info = Color3.fromRGB(80, 160, 220),
			MutedText = Color3.fromRGB(150, 150, 155),
		},

		Ocean = {
			TextColor = Color3.fromRGB(230, 240, 240),

			Background = Color3.fromRGB(20, 30, 30),
			Topbar = Color3.fromRGB(25, 40, 40),
			Shadow = Color3.fromRGB(15, 20, 20),

			NotificationBackground = Color3.fromRGB(25, 35, 35),
			NotificationActionsBackground = Color3.fromRGB(230, 240, 240),

			TabBackground = Color3.fromRGB(40, 60, 60),
			TabStroke = Color3.fromRGB(50, 70, 70),
			TabBackgroundSelected = Color3.fromRGB(100, 180, 180),
			TabTextColor = Color3.fromRGB(210, 230, 230),
			SelectedTabTextColor = Color3.fromRGB(20, 50, 50),

			ElementBackground = Color3.fromRGB(30, 50, 50),
			ElementBackgroundHover = Color3.fromRGB(40, 60, 60),
			SecondaryElementBackground = Color3.fromRGB(30, 45, 45),
			ElementStroke = Color3.fromRGB(45, 70, 70),
			SecondaryElementStroke = Color3.fromRGB(40, 65, 65),

			SliderBackground = Color3.fromRGB(0, 110, 110),
			SliderProgress = Color3.fromRGB(0, 140, 140),
			SliderStroke = Color3.fromRGB(0, 160, 160),

			ToggleBackground = Color3.fromRGB(30, 50, 50),
			ToggleEnabled = Color3.fromRGB(0, 130, 130),
			ToggleDisabled = Color3.fromRGB(70, 90, 90),
			ToggleEnabledStroke = Color3.fromRGB(0, 160, 160),
			ToggleDisabledStroke = Color3.fromRGB(85, 105, 105),
			ToggleEnabledOuterStroke = Color3.fromRGB(50, 100, 100),
			ToggleDisabledOuterStroke = Color3.fromRGB(45, 65, 65),

			DropdownSelected = Color3.fromRGB(30, 60, 60),
			DropdownUnselected = Color3.fromRGB(25, 40, 40),

			InputBackground = Color3.fromRGB(30, 50, 50),
			InputStroke = Color3.fromRGB(50, 70, 70),
			PlaceholderColor = Color3.fromRGB(140, 160, 160)
		},

		AmberGlow = {
			TextColor = Color3.fromRGB(255, 245, 230),

			Background = Color3.fromRGB(45, 30, 20),
			Topbar = Color3.fromRGB(55, 40, 25),
			Shadow = Color3.fromRGB(35, 25, 15),

			NotificationBackground = Color3.fromRGB(50, 35, 25),
			NotificationActionsBackground = Color3.fromRGB(245, 230, 215),

			TabBackground = Color3.fromRGB(75, 50, 35),
			TabStroke = Color3.fromRGB(90, 60, 45),
			TabBackgroundSelected = Color3.fromRGB(230, 180, 100),
			TabTextColor = Color3.fromRGB(250, 220, 200),
			SelectedTabTextColor = Color3.fromRGB(50, 30, 10),

			ElementBackground = Color3.fromRGB(60, 45, 35),
			ElementBackgroundHover = Color3.fromRGB(70, 50, 40),
			SecondaryElementBackground = Color3.fromRGB(55, 40, 30),
			ElementStroke = Color3.fromRGB(85, 60, 45),
			SecondaryElementStroke = Color3.fromRGB(75, 50, 35),

			SliderBackground = Color3.fromRGB(220, 130, 60),
			SliderProgress = Color3.fromRGB(250, 150, 75),
			SliderStroke = Color3.fromRGB(255, 170, 85),

			ToggleBackground = Color3.fromRGB(55, 40, 30),
			ToggleEnabled = Color3.fromRGB(240, 130, 30),
			ToggleDisabled = Color3.fromRGB(90, 70, 60),
			ToggleEnabledStroke = Color3.fromRGB(255, 160, 50),
			ToggleDisabledStroke = Color3.fromRGB(110, 85, 75),
			ToggleEnabledOuterStroke = Color3.fromRGB(200, 100, 50),
			ToggleDisabledOuterStroke = Color3.fromRGB(75, 60, 55),

			DropdownSelected = Color3.fromRGB(70, 50, 40),
			DropdownUnselected = Color3.fromRGB(55, 40, 30),

			InputBackground = Color3.fromRGB(60, 45, 35),
			InputStroke = Color3.fromRGB(90, 65, 50),
			PlaceholderColor = Color3.fromRGB(190, 150, 130)
		},

		Light = {
			TextColor = Color3.fromRGB(40, 40, 40),

			Background = Color3.fromRGB(245, 245, 245),
			Topbar = Color3.fromRGB(230, 230, 230),
			Shadow = Color3.fromRGB(200, 200, 200),

			NotificationBackground = Color3.fromRGB(250, 250, 250),
			NotificationActionsBackground = Color3.fromRGB(240, 240, 240),

			TabBackground = Color3.fromRGB(235, 235, 235),
			TabStroke = Color3.fromRGB(215, 215, 215),
			TabBackgroundSelected = Color3.fromRGB(255, 255, 255),
			TabTextColor = Color3.fromRGB(80, 80, 80),
			SelectedTabTextColor = Color3.fromRGB(0, 0, 0),

			ElementBackground = Color3.fromRGB(240, 240, 240),
			ElementBackgroundHover = Color3.fromRGB(225, 225, 225),
			SecondaryElementBackground = Color3.fromRGB(235, 235, 235),
			ElementStroke = Color3.fromRGB(210, 210, 210),
			SecondaryElementStroke = Color3.fromRGB(210, 210, 210),

			SliderBackground = Color3.fromRGB(150, 180, 220),
			SliderProgress = Color3.fromRGB(100, 150, 200), 
			SliderStroke = Color3.fromRGB(120, 170, 220),

			ToggleBackground = Color3.fromRGB(220, 220, 220),
			ToggleEnabled = Color3.fromRGB(0, 146, 214),
			ToggleDisabled = Color3.fromRGB(150, 150, 150),
			ToggleEnabledStroke = Color3.fromRGB(0, 170, 255),
			ToggleDisabledStroke = Color3.fromRGB(170, 170, 170),
			ToggleEnabledOuterStroke = Color3.fromRGB(100, 100, 100),
			ToggleDisabledOuterStroke = Color3.fromRGB(180, 180, 180),

			DropdownSelected = Color3.fromRGB(230, 230, 230),
			DropdownUnselected = Color3.fromRGB(220, 220, 220),

			InputBackground = Color3.fromRGB(240, 240, 240),
			InputStroke = Color3.fromRGB(180, 180, 180),
			PlaceholderColor = Color3.fromRGB(140, 140, 140)
		},

		Amethyst = {
			TextColor = Color3.fromRGB(240, 240, 240),

			Background = Color3.fromRGB(30, 20, 40),
			Topbar = Color3.fromRGB(40, 25, 50),
			Shadow = Color3.fromRGB(20, 15, 30),

			NotificationBackground = Color3.fromRGB(35, 20, 40),
			NotificationActionsBackground = Color3.fromRGB(240, 240, 250),

			TabBackground = Color3.fromRGB(60, 40, 80),
			TabStroke = Color3.fromRGB(70, 45, 90),
			TabBackgroundSelected = Color3.fromRGB(180, 140, 200),
			TabTextColor = Color3.fromRGB(230, 230, 240),
			SelectedTabTextColor = Color3.fromRGB(50, 20, 50),

			ElementBackground = Color3.fromRGB(45, 30, 60),
			ElementBackgroundHover = Color3.fromRGB(50, 35, 70),
			SecondaryElementBackground = Color3.fromRGB(40, 30, 55),
			ElementStroke = Color3.fromRGB(70, 50, 85),
			SecondaryElementStroke = Color3.fromRGB(65, 45, 80),

			SliderBackground = Color3.fromRGB(100, 60, 150),
			SliderProgress = Color3.fromRGB(130, 80, 180),
			SliderStroke = Color3.fromRGB(150, 100, 200),

			ToggleBackground = Color3.fromRGB(45, 30, 55),
			ToggleEnabled = Color3.fromRGB(120, 60, 150),
			ToggleDisabled = Color3.fromRGB(94, 47, 117),
			ToggleEnabledStroke = Color3.fromRGB(140, 80, 170),
			ToggleDisabledStroke = Color3.fromRGB(124, 71, 150),
			ToggleEnabledOuterStroke = Color3.fromRGB(90, 40, 120),
			ToggleDisabledOuterStroke = Color3.fromRGB(80, 50, 110),

			DropdownSelected = Color3.fromRGB(50, 35, 70),
			DropdownUnselected = Color3.fromRGB(35, 25, 50),

			InputBackground = Color3.fromRGB(45, 30, 60),
			InputStroke = Color3.fromRGB(80, 50, 110),
			PlaceholderColor = Color3.fromRGB(178, 150, 200)
		},

		Green = {
			TextColor = Color3.fromRGB(30, 60, 30),

			Background = Color3.fromRGB(235, 245, 235),
			Topbar = Color3.fromRGB(210, 230, 210),
			Shadow = Color3.fromRGB(200, 220, 200),

			NotificationBackground = Color3.fromRGB(240, 250, 240),
			NotificationActionsBackground = Color3.fromRGB(220, 235, 220),

			TabBackground = Color3.fromRGB(215, 235, 215),
			TabStroke = Color3.fromRGB(190, 210, 190),
			TabBackgroundSelected = Color3.fromRGB(245, 255, 245),
			TabTextColor = Color3.fromRGB(50, 80, 50),
			SelectedTabTextColor = Color3.fromRGB(20, 60, 20),

			ElementBackground = Color3.fromRGB(225, 240, 225),
			ElementBackgroundHover = Color3.fromRGB(210, 225, 210),
			SecondaryElementBackground = Color3.fromRGB(235, 245, 235), 
			ElementStroke = Color3.fromRGB(180, 200, 180),
			SecondaryElementStroke = Color3.fromRGB(180, 200, 180),

			SliderBackground = Color3.fromRGB(90, 160, 90),
			SliderProgress = Color3.fromRGB(70, 130, 70),
			SliderStroke = Color3.fromRGB(100, 180, 100),

			ToggleBackground = Color3.fromRGB(215, 235, 215),
			ToggleEnabled = Color3.fromRGB(60, 130, 60),
			ToggleDisabled = Color3.fromRGB(150, 175, 150),
			ToggleEnabledStroke = Color3.fromRGB(80, 150, 80),
			ToggleDisabledStroke = Color3.fromRGB(130, 150, 130),
			ToggleEnabledOuterStroke = Color3.fromRGB(100, 160, 100),
			ToggleDisabledOuterStroke = Color3.fromRGB(160, 180, 160),

			DropdownSelected = Color3.fromRGB(225, 240, 225),
			DropdownUnselected = Color3.fromRGB(210, 225, 210),

			InputBackground = Color3.fromRGB(235, 245, 235),
			InputStroke = Color3.fromRGB(180, 200, 180),
			PlaceholderColor = Color3.fromRGB(120, 140, 120)
		},

		Bloom = {
			TextColor = Color3.fromRGB(60, 40, 50),

			Background = Color3.fromRGB(255, 240, 245),
			Topbar = Color3.fromRGB(250, 220, 225),
			Shadow = Color3.fromRGB(230, 190, 195),

			NotificationBackground = Color3.fromRGB(255, 235, 240),
			NotificationActionsBackground = Color3.fromRGB(245, 215, 225),

			TabBackground = Color3.fromRGB(240, 210, 220),
			TabStroke = Color3.fromRGB(230, 200, 210),
			TabBackgroundSelected = Color3.fromRGB(255, 225, 235),
			TabTextColor = Color3.fromRGB(80, 40, 60),
			SelectedTabTextColor = Color3.fromRGB(50, 30, 50),

			ElementBackground = Color3.fromRGB(255, 235, 240),
			ElementBackgroundHover = Color3.fromRGB(245, 220, 230),
			SecondaryElementBackground = Color3.fromRGB(255, 235, 240), 
			ElementStroke = Color3.fromRGB(230, 200, 210),
			SecondaryElementStroke = Color3.fromRGB(230, 200, 210),

			SliderBackground = Color3.fromRGB(240, 130, 160),
			SliderProgress = Color3.fromRGB(250, 160, 180),
			SliderStroke = Color3.fromRGB(255, 180, 200),

			ToggleBackground = Color3.fromRGB(240, 210, 220),
			ToggleEnabled = Color3.fromRGB(255, 140, 170),
			ToggleDisabled = Color3.fromRGB(200, 180, 185),
			ToggleEnabledStroke = Color3.fromRGB(250, 160, 190),
			ToggleDisabledStroke = Color3.fromRGB(210, 180, 190),
			ToggleEnabledOuterStroke = Color3.fromRGB(220, 160, 180),
			ToggleDisabledOuterStroke = Color3.fromRGB(190, 170, 180),

			DropdownSelected = Color3.fromRGB(250, 220, 225),
			DropdownUnselected = Color3.fromRGB(240, 210, 220),

			InputBackground = Color3.fromRGB(255, 235, 240),
			InputStroke = Color3.fromRGB(220, 190, 200),
			PlaceholderColor = Color3.fromRGB(170, 130, 140)
		},

		DarkBlue = {
			TextColor = Color3.fromRGB(230, 230, 230),

			Background = Color3.fromRGB(20, 25, 30),
			Topbar = Color3.fromRGB(30, 35, 40),
			Shadow = Color3.fromRGB(15, 20, 25),

			NotificationBackground = Color3.fromRGB(25, 30, 35),
			NotificationActionsBackground = Color3.fromRGB(45, 50, 55),

			TabBackground = Color3.fromRGB(35, 40, 45),
			TabStroke = Color3.fromRGB(45, 50, 60),
			TabBackgroundSelected = Color3.fromRGB(40, 70, 100),
			TabTextColor = Color3.fromRGB(200, 200, 200),
			SelectedTabTextColor = Color3.fromRGB(255, 255, 255),

			ElementBackground = Color3.fromRGB(30, 35, 40),
			ElementBackgroundHover = Color3.fromRGB(40, 45, 50),
			SecondaryElementBackground = Color3.fromRGB(35, 40, 45), 
			ElementStroke = Color3.fromRGB(45, 50, 60),
			SecondaryElementStroke = Color3.fromRGB(40, 45, 55),

			SliderBackground = Color3.fromRGB(0, 90, 180),
			SliderProgress = Color3.fromRGB(0, 120, 210),
			SliderStroke = Color3.fromRGB(0, 150, 240),

			ToggleBackground = Color3.fromRGB(35, 40, 45),
			ToggleEnabled = Color3.fromRGB(0, 120, 210),
			ToggleDisabled = Color3.fromRGB(70, 70, 80),
			ToggleEnabledStroke = Color3.fromRGB(0, 150, 240),
			ToggleDisabledStroke = Color3.fromRGB(75, 75, 85),
			ToggleEnabledOuterStroke = Color3.fromRGB(20, 100, 180), 
			ToggleDisabledOuterStroke = Color3.fromRGB(55, 55, 65),

			DropdownSelected = Color3.fromRGB(30, 70, 90),
			DropdownUnselected = Color3.fromRGB(25, 30, 35),

			InputBackground = Color3.fromRGB(25, 30, 35),
			InputStroke = Color3.fromRGB(45, 50, 60), 
			PlaceholderColor = Color3.fromRGB(150, 150, 160)
		},

		Serenity = {
			TextColor = Color3.fromRGB(50, 55, 60),
			Background = Color3.fromRGB(240, 245, 250),
			Topbar = Color3.fromRGB(215, 225, 235),
			Shadow = Color3.fromRGB(200, 210, 220),

			NotificationBackground = Color3.fromRGB(210, 220, 230),
			NotificationActionsBackground = Color3.fromRGB(225, 230, 240),

			TabBackground = Color3.fromRGB(200, 210, 220),
			TabStroke = Color3.fromRGB(180, 190, 200),
			TabBackgroundSelected = Color3.fromRGB(175, 185, 200),
			TabTextColor = Color3.fromRGB(50, 55, 60),
			SelectedTabTextColor = Color3.fromRGB(30, 35, 40),

			ElementBackground = Color3.fromRGB(210, 220, 230),
			ElementBackgroundHover = Color3.fromRGB(220, 230, 240),
			SecondaryElementBackground = Color3.fromRGB(200, 210, 220),
			ElementStroke = Color3.fromRGB(190, 200, 210),
			SecondaryElementStroke = Color3.fromRGB(180, 190, 200),

			SliderBackground = Color3.fromRGB(200, 220, 235),  -- Lighter shade
			SliderProgress = Color3.fromRGB(70, 130, 180),
			SliderStroke = Color3.fromRGB(150, 180, 220),

			ToggleBackground = Color3.fromRGB(210, 220, 230),
			ToggleEnabled = Color3.fromRGB(70, 160, 210),
			ToggleDisabled = Color3.fromRGB(180, 180, 180),
			ToggleEnabledStroke = Color3.fromRGB(60, 150, 200),
			ToggleDisabledStroke = Color3.fromRGB(140, 140, 140),
			ToggleEnabledOuterStroke = Color3.fromRGB(100, 120, 140),
			ToggleDisabledOuterStroke = Color3.fromRGB(120, 120, 130),

			DropdownSelected = Color3.fromRGB(220, 230, 240),
			DropdownUnselected = Color3.fromRGB(200, 210, 220),

			InputBackground = Color3.fromRGB(220, 230, 240),
			InputStroke = Color3.fromRGB(180, 190, 200),
			PlaceholderColor = Color3.fromRGB(150, 150, 150)
		},

		PremiumDark = {
			TextColor = Color3.fromRGB(235, 236, 240),
			Background = Color3.fromRGB(22, 22, 28),
			Topbar = Color3.fromRGB(28, 28, 36),
			Shadow = Color3.fromRGB(12, 12, 18),
			NotificationBackground = Color3.fromRGB(20, 20, 26),
			NotificationActionsBackground = Color3.fromRGB(200, 200, 210),
			TabBackground = Color3.fromRGB(38, 38, 48),
			TabStroke = Color3.fromRGB(52, 52, 64),
			TabBackgroundSelected = Color3.fromRGB(72, 62, 120),
			TabTextColor = Color3.fromRGB(200, 200, 210),
			SelectedTabTextColor = Color3.fromRGB(245, 245, 250),
			ElementBackground = Color3.fromRGB(32, 32, 40),
			ElementBackgroundHover = Color3.fromRGB(40, 40, 50),
			SecondaryElementBackground = Color3.fromRGB(26, 26, 34),
			ElementStroke = Color3.fromRGB(58, 58, 72),
			SecondaryElementStroke = Color3.fromRGB(48, 48, 60),
			SliderBackground = Color3.fromRGB(88, 76, 160),
			SliderProgress = Color3.fromRGB(120, 100, 220),
			SliderStroke = Color3.fromRGB(140, 120, 235),
			ToggleBackground = Color3.fromRGB(30, 30, 38),
			ToggleEnabled = Color3.fromRGB(110, 90, 210),
			ToggleDisabled = Color3.fromRGB(90, 90, 100),
			ToggleEnabledStroke = Color3.fromRGB(130, 110, 235),
			ToggleDisabledStroke = Color3.fromRGB(85, 85, 95),
			ToggleEnabledOuterStroke = Color3.fromRGB(70, 60, 120),
			ToggleDisabledOuterStroke = Color3.fromRGB(55, 55, 65),
			DropdownSelected = Color3.fromRGB(48, 44, 70),
			DropdownUnselected = Color3.fromRGB(32, 32, 40),
			InputBackground = Color3.fromRGB(28, 28, 36),
			InputStroke = Color3.fromRGB(55, 55, 68),
			PlaceholderColor = Color3.fromRGB(130, 130, 145),
			Success = Color3.fromRGB(85, 210, 140),
			Warning = Color3.fromRGB(230, 190, 85),
			Error = Color3.fromRGB(235, 95, 95),
			Info = Color3.fromRGB(100, 175, 235),
			MutedText = Color3.fromRGB(140, 140, 155),
		},

		AMOLED = {
			TextColor = Color3.fromRGB(240, 240, 245),
			Background = Color3.fromRGB(0, 0, 0),
			Topbar = Color3.fromRGB(8, 8, 10),
			Shadow = Color3.fromRGB(0, 0, 0),
			NotificationBackground = Color3.fromRGB(5, 5, 8),
			NotificationActionsBackground = Color3.fromRGB(220, 220, 225),
			TabBackground = Color3.fromRGB(14, 14, 18),
			TabStroke = Color3.fromRGB(28, 28, 34),
			TabBackgroundSelected = Color3.fromRGB(40, 36, 64),
			TabTextColor = Color3.fromRGB(190, 190, 200),
			SelectedTabTextColor = Color3.fromRGB(250, 250, 255),
			ElementBackground = Color3.fromRGB(10, 10, 12),
			ElementBackgroundHover = Color3.fromRGB(18, 18, 22),
			SecondaryElementBackground = Color3.fromRGB(8, 8, 10),
			ElementStroke = Color3.fromRGB(35, 35, 42),
			SecondaryElementStroke = Color3.fromRGB(28, 28, 34),
			SliderBackground = Color3.fromRGB(60, 50, 110),
			SliderProgress = Color3.fromRGB(100, 85, 200),
			SliderStroke = Color3.fromRGB(120, 100, 220),
			ToggleBackground = Color3.fromRGB(12, 12, 15),
			ToggleEnabled = Color3.fromRGB(95, 80, 200),
			ToggleDisabled = Color3.fromRGB(55, 55, 62),
			ToggleEnabledStroke = Color3.fromRGB(115, 95, 220),
			ToggleDisabledStroke = Color3.fromRGB(70, 70, 78),
			ToggleEnabledOuterStroke = Color3.fromRGB(50, 45, 90),
			ToggleDisabledOuterStroke = Color3.fromRGB(40, 40, 48),
			DropdownSelected = Color3.fromRGB(30, 28, 48),
			DropdownUnselected = Color3.fromRGB(12, 12, 15),
			InputBackground = Color3.fromRGB(10, 10, 12),
			InputStroke = Color3.fromRGB(38, 38, 46),
			PlaceholderColor = Color3.fromRGB(120, 120, 132),
			Success = Color3.fromRGB(70, 220, 130),
			Warning = Color3.fromRGB(235, 195, 70),
			Error = Color3.fromRGB(240, 85, 85),
			Info = Color3.fromRGB(90, 170, 240),
			MutedText = Color3.fromRGB(130, 130, 142),
		},
	}
}




-- Interface Management

local RayfieldAssetId = customAssetId or 10804731440
local Rayfield = nil
if useStudio and script and script.Parent and script.Parent:FindFirstChild('Rayfield') then
	Rayfield = script.Parent:FindFirstChild('Rayfield')
else
	Rayfield = game:GetObjects("rbxassetid://"..RayfieldAssetId)[1]
end
local buildAttempts = 0
local correctBuild = false
local warned
local globalLoaded
local rayfieldDestroyed = false -- True when RayfieldLibrary:Destroy() is called

repeat
	if Rayfield:FindFirstChild('Build') and Rayfield.Build.Value == InterfaceBuild then
		correctBuild = true
		break
	end

	correctBuild = false

	if not warned then
		warn('Rayfield | Build Mismatch')
		print('Rayfield may encounter issues as you are running an incompatible interface version ('.. ((Rayfield:FindFirstChild('Build') and Rayfield.Build.Value) or 'No Build') ..').\n\nThis version of Rayfield is intended for interface build '..InterfaceBuild..'.')
		warned = true
	end

	local toDestroy
	local newRayfield = nil
	if useStudio and script and script.Parent and script.Parent:FindFirstChild('Rayfield') then
		newRayfield = script.Parent:FindFirstChild('Rayfield')
	else
		newRayfield = game:GetObjects("rbxassetid://"..RayfieldAssetId)[1]
	end
	toDestroy, Rayfield = Rayfield, newRayfield
	if toDestroy and not useStudio then toDestroy:Destroy() end

	buildAttempts = buildAttempts + 1
until buildAttempts >= 2

Rayfield.Enabled = false

if gethui then
	Rayfield.Parent = gethui()
elseif syn and syn.protect_gui then 
	syn.protect_gui(Rayfield)
	Rayfield.Parent = CoreGui
elseif not useStudio and CoreGui:FindFirstChild("RobloxGui") then
	Rayfield.Parent = CoreGui:FindFirstChild("RobloxGui")
elseif not useStudio then
	Rayfield.Parent = CoreGui
end

if gethui then
	for _, Interface in ipairs(gethui():GetChildren()) do
		if Interface.Name == Rayfield.Name and Interface ~= Rayfield then
			Interface.Enabled = false
			Interface.Name = "Rayfield-Old"
		end
	end
elseif not useStudio then
	for _, Interface in ipairs(CoreGui:GetChildren()) do
		if Interface.Name == Rayfield.Name and Interface ~= Rayfield then
			Interface.Enabled = false
			Interface.Name = "Rayfield-Old"
		end
	end
end

if secureMode and not customAssetId then
	secureNotify("default_asset", "Secure Mode", "You are using the default Rayfield asset ID. Set RAYFIELD_ASSET_ID to a custom upload to avoid detection.")
end

do
	local AssetPath = RayfieldFolder.."/Assets"
	local AssetBaseURL = "https://github.com/SiriusSoftwareLtd/Rayfield/blob/main/assets/"

	local assetFiles = {
		["111263549366178"] = AssetBaseURL.."111263549366178.png?raw=true",
		["77891951053543"] = AssetBaseURL.."77891951053543.png?raw=true",
		["78137979054938"] = AssetBaseURL.."78137979054938.png?raw=true",
		["80503127983237"] = AssetBaseURL.."80503127983237.png?raw=true",
		["10137832201"] = AssetBaseURL.."10137832201.png?raw=true",
		["10137941941"] = AssetBaseURL.."10137941941.png?raw=true",
		["11036884234"] = AssetBaseURL.."11036884234.png?raw=true",
		["11413591840"] = AssetBaseURL.."11413591840.png?raw=true",
		["11745872910"] = AssetBaseURL.."11745872910.png?raw=true",
		["12577727209"] = AssetBaseURL.."12577727209.png?raw=true",
		["18458939117"] = AssetBaseURL.."18458939117.png?raw=true",
		["3259050989"] = AssetBaseURL.."3259050989.png?raw=true",
		["3523728077"] = AssetBaseURL.."3523728077.png?raw=true",
		["3602733521"] = AssetBaseURL.."3602733521.png?raw=true",
		["IconChevronTopMedium"] = AssetBaseURL.."IconChevronTopMedium.png?raw=true",
		["4483362458"] = AssetBaseURL.."4483362458.png?raw=true",
		["5587865193"] = AssetBaseURL.."5587865193.png?raw=true",
		["IconMagnifyingGlass2"] = AssetBaseURL.."IconMagnifyingGlass2.png?raw=true",
	}

	for id, _ in assetFiles do
		customAssets[tostring(id)] = ""
	end

	local hasCustomAsset = type(getcustomasset) == "function"
	local hasFilesystem = type(writefile) == "function" and type(makefolder) == "function" and type(isfile) == "function" and type(isfolder) == "function"

	if hasCustomAsset and hasFilesystem then
		local ok, err = pcall(function()
			ensureFolder(RayfieldFolder)
			ensureFolder(AssetPath)

			local function nextMissing()
				for id, _ in assetFiles do
					if not isfile(AssetPath.."/"..tostring(id)..".png") then
						return id
					end
				end
				return nil
			end

			if nextMissing() then
				task.spawn(function()
					while true do
						local id = nextMissing()
						if not id then break end
						writefile(AssetPath.."/"..tostring(id)..".png", requestFunc({Url = assetFiles[id], Method = "GET"}).Body)
						task.wait()
					end
				end)

				while nextMissing() do
					task.wait(0.1)
				end
			end

			for id, _ in assetFiles do
				local success, asset = pcall(getcustomasset, AssetPath.."/"..tostring(id)..".png")
				if success then
					customAssets[tostring(id)] = asset
				else
					warn("Rayfield | Failed to load custom asset: "..tostring(id).." - "..tostring(asset))
				end
			end
		end)

		if not ok then
			warn("Rayfield | Failed to load custom assets: "..tostring(err))
			secureNotify("asset_load_fail", "Rayfield", "Failed to load custom assets. UI images may not display correctly.")
		end
	else
		secureNotify("no_getcustomasset", "Rayfield", "Your executor does not support getcustomasset. Some UI images may not render correctly.")
	end


	Rayfield.Main.Shadow.Image.Image = customAssets[tostring(5587865193)]
	Rayfield.Main.Topbar.Hide.Image = customAssets[tostring(10137832201)]
	Rayfield.Main.Topbar.ChangeSize.Image = customAssets[tostring(10137941941)]
	Rayfield.Main.Topbar.Settings.Image = customAssets[tostring(80503127983237)]
	Rayfield.Main.Topbar.Icon.Image = customAssets[tostring(78137979054938)]
	Rayfield.Main.Topbar.Search.Image = customAssets["IconMagnifyingGlass2"]
	Rayfield.Main.Topbar.Search.ImageRectOffset = Vector2.new(0, 0)
	Rayfield.Main.Topbar.Search.ImageRectSize = Vector2.new(0, 0)
	Rayfield.Main.Elements.Template.Toggle.Switch.Shadow.Image = customAssets[tostring(3602733521)]
	Rayfield.Main.Elements.Template.Slider.Main.Shadow.Image = customAssets[tostring(3602733521)]
	Rayfield.Main.Elements.Template.Dropdown.Toggle.Image = customAssets["IconChevronTopMedium"]
	Rayfield.Main.Elements.Template.Dropdown.Toggle.ImageRectOffset = Vector2.new(0, 0)
	Rayfield.Main.Elements.Template.Dropdown.Toggle.ImageRectSize = Vector2.new(0, 0)
	Rayfield.Main.Elements.Template.Label.Icon.Image = customAssets[tostring(11745872910)]
	Rayfield.Main.Elements.Template.ColorPicker.CPBackground.MainCP.Image = customAssets[tostring(11413591840)]
	Rayfield.Main.Elements.Template.ColorPicker.CPBackground.MainCP.MainPoint.Image = customAssets[tostring(3259050989)]
	Rayfield.Main.Elements.Template.ColorPicker.ColorSlider.SliderPoint.Image = customAssets[tostring(3259050989)]
	Rayfield.Main.TabList.Template.Image.Image = customAssets[tostring(4483362458)]
	Rayfield.Main.Search.Search.Image = customAssets[tostring(18458939117)]
	Rayfield.Main.Search.Shadow.Image = customAssets[tostring(5587865193)]
	Rayfield.Notifications.Template.Icon.Image = customAssets[tostring(77891951053543)]
	Rayfield.Notifications.Template.Shadow.Image = customAssets[tostring(3523728077)]
	Rayfield.Loading.Banner.Image = customAssets[tostring(111263549366178)]

end -- custom asset block

local minSize = Vector2.new(1024, 768)
local useMobileSizing

if Rayfield.AbsoluteSize.X < minSize.X and Rayfield.AbsoluteSize.Y < minSize.Y then
	useMobileSizing = true
end

local useMobilePrompt = false
if UserInputService.TouchEnabled then
	useMobilePrompt = true
end


-- Object Variables

local Main = Rayfield.Main
local MPrompt = Rayfield:FindFirstChild('Prompt')
local Topbar = Main.Topbar
local Elements = Main.Elements
local LoadingFrame = Main.LoadingFrame
local TabList = Main.TabList
local dragBar = Rayfield:FindFirstChild('Drag')
local dragInteract = dragBar and dragBar.Interact or nil
local dragBarCosmetic = dragBar and dragBar.Drag or nil

local dragOffset = 255
local dragOffsetMobile = 150

Rayfield.DisplayOrder = 100
LoadingFrame.Version.Text = Release

-- Thanks to Latte Softworks for the Lucide integration for Roblox
local Icons = nil
if useStudio and script and script.Parent and script.Parent:FindFirstChild("icons") then
	Icons = require(script.Parent.icons)
else
	local fetchSuccess, fetchResult = pcall(readfile, "icons.lua")
	if fetchSuccess and #fetchResult > 0 then
		local execSuccess, execResult = pcall(function()
			return loadstring(fetchResult)()
		end)
		if execSuccess and type(execResult) == "table" then
			Icons = execResult
		end
	else
		Icons = loadWithTimeout('https://raw.githubusercontent.com/SiriusSoftwareLtd/Rayfield/refs/heads/main/icons.lua')
	end
end
-- Variables

local CFileName = nil
local CEnabled = false
local Minimised = false
local Hidden = false
local Debounce = false
local searchOpen = false
local Notifications = Rayfield.Notifications
local keybindConnections = {} -- For storing keybind connections to disconnect when Rayfield is destroyed

local performanceTier = "Medium"
local activeWindowSettings = nil
local commandRegistry = {}
local currentWindowTabRegistry = {}
local iconResolveCache = {}
local notifyQueue = {}
local notifyActiveCount = 0
local MAX_CONCURRENT_NOTIFICATIONS = 3
local paletteInputConnection = nil
local paletteOpen = false
local paletteOverlayId: number? = nil
local paletteContentBucket: Folder? = nil
local palettePanelRoot: Frame? = nil
local paletteSavedDisplayOrder = 0
local lastFocusedGuiForPalette = nil
local devOverlayConn = nil
local devOverlayLabel = nil

local DesignTokensMod = nil
do
	local ok, mod = pcall(function()
		if script and script.Parent then
			local tok = script.Parent:FindFirstChild("design_tokens")
			if tok then
				return require(tok)
			end
		end
		return nil
	end)
	if ok and mod then
		DesignTokensMod = mod
	end
	-- Fallback: usa o Tokens global se disponível (carregado via HTTP ou fallback inline)
	if not DesignTokensMod and Tokens and type(Tokens) == "table" then
		DesignTokensMod = Tokens
	end
end

local function mergeThemeTables(defaultT, overrideT)
	if not overrideT then
		return defaultT
	end
	if DesignTokensMod and DesignTokensMod.MergeTheme then
		return DesignTokensMod.MergeTheme(defaultT, overrideT)
	end
	local out = table.clone(defaultT)
	for k, v in pairs(overrideT) do
		out[k] = v
	end
	return out
end

local function rfTween(inst, props, motionName)
	if DesignTokensMod and DesignTokensMod.Tween then
		DesignTokensMod.Tween(inst, props, motionName or "Smooth", performanceTier):Play()
	else
		TweenService:Create(inst, TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), props):Play()
	end
end

local SelectedTheme = RayfieldLibrary.Theme.Default

-- ══════════════════════════════════════════════════════════════
-- 🎯 INTERACTION STATES + SHADOW SYSTEM (Fase 1d)
-- ══════════════════════════════════════════════════════════════

-- Retorna cor de estado baseada no tema atual
local function rfStateColor(stateName: string): Color3
	if DesignTokensMod and DesignTokensMod.StateColors then
		local states = DesignTokensMod.StateColors(SelectedTheme)
		if states[stateName] then
			return states[stateName]
		end
	end
	-- Fallback manual
	if stateName == "Hover" then
		return SelectedTheme.ElementBackgroundHover or SelectedTheme.ElementBackground
	elseif stateName == "Idle" then
		return SelectedTheme.ElementBackground
	elseif stateName == "Pressed" then
		return SelectedTheme.ElementBackgroundHover or SelectedTheme.ElementBackground
	elseif stateName == "Focused" then
		return SelectedTheme.InputBackground
	elseif stateName == "Disabled" then
		return SelectedTheme.SecondaryElementBackground or SelectedTheme.ElementBackground
	elseif stateName == "Selected" then
		return SelectedTheme.DropdownSelected or SelectedTheme.TabBackgroundSelected
	end
	return SelectedTheme.ElementBackground
end

-- Aplica nível de sombra a um UIStroke ou ImageLabel
local function rfApplyShadow(uiStroke: Instance?, imageShadow: Instance?, tierName: string?)
	if DesignTokensMod and DesignTokensMod.ApplyShadowTier then
		DesignTokensMod.ApplyShadowTier(uiStroke, imageShadow, tierName or "medium")
		return
	end
	-- Fallback manual
	local tier = tierName or "medium"
	local transparencies = {
		weak = 0.92,
		medium = 0.85,
		strong = 0.78,
		glow = 0.65,
		neon = 0.5,
	}
	local t = transparencies[tier] or 0.85
	if uiStroke then
		uiStroke.Thickness = (tier == "glow" or tier == "neon") and 2 or 1
	end
	if imageShadow then
		imageShadow.ImageTransparency = t
	end
end

-- Aplica cor semântica (Success, Warning, Error, Info, Muted)
local function rfSemanticColor(semanticName: string): Color3
	if DesignTokensMod and DesignTokensMod.SemanticFromTheme then
		local sem = DesignTokensMod.SemanticFromTheme(SelectedTheme)
		if sem[semanticName] then
			return sem[semanticName]
		end
	end
	return SelectedTheme.TextColor
end

-- ══════════════════════════════════════════════════════════════
-- 🎬 OVERLAY SYSTEM (Fase 1e + Fase 3)
-- ══════════════════════════════════════════════════════════════

-- Estrutura de dados para overlays ativos
local activeOverlays = {}
local overlayIdCounter = 0

-- Cria um overlay genérico com backdrop + fechar ao clicar fora
-- Uso: OverlaySystem.show({ level = "Modal", opacity = 0.5, dismissOnBackdrop = true })
local OverlaySystem = {
	show = function(config)
		config = config or {}
		overlayIdCounter += 1
		local id = overlayIdCounter
		
		local zMap = {
			Sidebar = (DesignTokensMod and DesignTokensMod.ZIndex and DesignTokensMod.ZIndex.Sidebar) or 5,
			Dropdown = (DesignTokensMod and DesignTokensMod.ZIndex and DesignTokensMod.ZIndex.Dropdown) or 10,
			Overlay = (DesignTokensMod and DesignTokensMod.ZIndex and DesignTokensMod.ZIndex.Overlay) or 20,
			Modal = (DesignTokensMod and DesignTokensMod.ZIndex and DesignTokensMod.ZIndex.Modal) or 30,
			Notifications = (DesignTokensMod and DesignTokensMod.ZIndex and DesignTokensMod.ZIndex.Notifications) or 40,
			Tooltip = (DesignTokensMod and DesignTokensMod.ZIndex and DesignTokensMod.ZIndex.Tooltip) or 50,
		}
		local zIndex = zMap[config.level] or zMap.Overlay
		
		local root = Instance.new("Frame")
		root.Name = "Overlay_" .. id
		root.Size = UDim2.new(1, 0, 1, 0)
		root.BackgroundTransparency = 1
		root.ZIndex = zIndex
		root.Visible = true
		root.Parent = Rayfield
		
		local scrim = Instance.new("TextButton")
		scrim.Name = "Scrim"
		scrim.Size = UDim2.new(1, 0, 1, 0)
		scrim.BackgroundColor3 = Color3.new(0, 0, 0)
		scrim.BackgroundTransparency = config.opacity or 0.5
		scrim.Text = ""
		scrim.AutoButtonColor = false
		scrim.ZIndex = zIndex
		scrim.Parent = root
		
		if config.dismissOnBackdrop ~= false then
			scrim.MouseButton1Click:Connect(function()
				OverlaySystem.close(id)
			end)
		end
		
		if config.content then
			config.content.ZIndex = zIndex + 1
			config.content.Parent = root
		end
		
		activeOverlays[id] = {
			root = root,
			scrim = scrim,
			content = config.content,
			onClose = config.onClose,
			zIndex = zIndex,
			detachContentBeforeDestroy = config.detachContentBeforeDestroy,
		}
		
		if config.onOpen then
			pcall(config.onOpen, id)
		end
		
		return id
	end,
	
	close = function(id)
		local overlay = activeOverlays[id]
		if not overlay then return end
		if overlay.detachContentBeforeDestroy and overlay.content then
			local holder = overlay.detachContentBeforeDestroy
			if holder and holder.Parent then
				overlay.content.Parent = holder
			end
		end
		if overlay.onClose then
			pcall(overlay.onClose)
		end
		if overlay.root then
			overlay.root:Destroy()
		end
		activeOverlays[id] = nil
	end,
	
	closeAll = function()
		for id, _ in pairs(activeOverlays) do
			OverlaySystem.close(id)
		end
	end,
	
	isOpen = function(id)
		return activeOverlays[id] ~= nil
	end,
	
	getZIndex = function(level)
		local zMap = {
			Sidebar = (DesignTokensMod and DesignTokensMod.ZIndex and DesignTokensMod.ZIndex.Sidebar) or 5,
			Dropdown = (DesignTokensMod and DesignTokensMod.ZIndex and DesignTokensMod.ZIndex.Dropdown) or 10,
			Overlay = (DesignTokensMod and DesignTokensMod.ZIndex and DesignTokensMod.ZIndex.Overlay) or 20,
			Modal = (DesignTokensMod and DesignTokensMod.ZIndex and DesignTokensMod.ZIndex.Modal) or 30,
			Notifications = (DesignTokensMod and DesignTokensMod.ZIndex and DesignTokensMod.ZIndex.Notifications) or 40,
			Tooltip = (DesignTokensMod and DesignTokensMod.ZIndex and DesignTokensMod.ZIndex.Tooltip) or 50,
		}
		return zMap[level] or zMap.Overlay
	end,
}

-- ══════════════════════════════════════════════════════════════
-- 🎬 MICROINTERAÇÕES (Fase 2)
-- ══════════════════════════════════════════════════════════════

-- Tamanhos de ícone nominais alinhados ao spacing (Fase 5)
local IconSize = {
	SM = UDim2.new(0, 16, 0, 16),
	MD = UDim2.new(0, 20, 0, 20),
	LG = UDim2.new(0, 24, 0, 24),
}

-- Aplica outline de foco (Fase 5)
local function rfApplyFocusOutline(instance: Instance)
	local existing = instance:FindFirstChildOfClass("UIStroke")
	if existing then
		existing.Color = SelectedTheme.SliderBackground or Color3.fromRGB(50, 138, 220)
		existing.Thickness = 1.5
		existing.Transparency = 0.3
		return
	end
	local stroke = Instance.new("UIStroke")
	stroke.Color = SelectedTheme.SliderBackground or Color3.fromRGB(50, 138, 220)
	stroke.Thickness = 1.5
	stroke.Transparency = 0.3
	stroke.Parent = instance
end

-- Ajusta altura mínima para touch targets mobile (Fase 5)
local function rfMakeTouchTarget(instance: Frame, minHeight: number?)
	if not useMobileSizing then return end
	local h = minHeight or 48
	if instance.Size.Y.Offset < h then
		instance.Size = UDim2.new(instance.Size.X.Scale, instance.Size.X.Offset, 0, h)
	end
end

-- Cria efeito ripple em um botão/frame ao clicar
local function rfRippleEffect(button: Instance, color: Color3?)
	if performanceTier == "Low" then return end
	color = color or Color3.fromRGB(255, 255, 255)
	local ripple = Instance.new("Frame")
	ripple.Size = UDim2.new(0, 0, 0, 0)
	ripple.Position = UDim2.new(0.5, 0, 0.5, 0)
	ripple.AnchorPoint = Vector2.new(0.5, 0.5)
	ripple.BackgroundColor3 = color
	ripple.BackgroundTransparency = 0.5
	ripple.BorderSizePixel = 0
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = ripple
	ripple.ZIndex = button.ZIndex + 1
	ripple.Parent = button
	rfTween(ripple, { Size = UDim2.new(2, 0, 2, 0), BackgroundTransparency = 1 }, "Smooth")
	task.delay(0.5, function() pcall(ripple.Destroy, ripple) end)
end

-- Spring bounce ao ativar um toggle
local function rfSpringBounceToggle(toggleIndicator: Instance, targetPos: UDim2, sizeBounce: UDim2?)
	rfTween(toggleIndicator, { Position = targetPos }, "Bouncy")
	if sizeBounce then
		rfTween(toggleIndicator, { Size = sizeBounce }, "Fast")
	end
end

-- Hover glow sutil (aumenta stroke thickness + reduz transparência)
local function rfHoverGlow(uiStroke: UIStroke?, targetTransparency: number?)
	if not uiStroke then return end
	if performanceTier == "Low" then
		uiStroke.Thickness = 1
		return
	end
	rfTween(uiStroke, { Transparency = targetTransparency or 0.3, Thickness = 2 }, "Fast")
end

-- Hover glow off (restaura)
local function rfHoverGlowOff(uiStroke: UIStroke?, defaultTransparency: number?)
	if not uiStroke then return end
	rfTween(uiStroke, { Transparency = defaultTransparency or 0, Thickness = 1 }, "Fast")
end

-- Efeito de escala ao pressionar (active/pressed)
local function rfScalePress(instance: Instance, pressed: boolean)
	if performanceTier == "Low" then return end
	local target = pressed and UDim2.new(0.95, 0, 0.95, 0) or UDim2.new(1, 0, 1, 0)
	rfTween(instance, { Size = target }, "Fast")
end

-- Micro bounce ao clicar em botão
local function rfButtonBounce(button: Instance)
	if performanceTier == "Low" then
		rfTween(button, { BackgroundColor3 = rfStateColor("Pressed") }, "Fast")
		return
	end
	rfTween(button, { Size = UDim2.new(0.96, 0, 0.96, 0) }, "Fast")
	task.delay(0.08, function()
		rfTween(button, { Size = UDim2.new(1, 0, 1, 0) }, "Bouncy")
	end)
end

-- Animação de entrada com slide
local function rfSlideIn(instance: Instance, offset: number, motionName: string?)
	instance.Position = instance.Position + UDim2.new(0, 0, 0, offset)
	instance.Visible = true
	rfTween(instance, { Position = instance.Position - UDim2.new(0, 0, 0, offset) }, motionName or "Smooth")
end

-- Stagger animation para lista de elementos
local function rfStaggerIn(elements: { Instance }, baseDelay: number?, perElementDelay: number?)
	baseDelay = baseDelay or 0
	perElementDelay = perElementDelay or 0.06
	for i, elem in ipairs(elements) do
		task.delay(baseDelay + (i - 1) * perElementDelay, function()
			elem.Visible = true
			rfTween(elem, { BackgroundTransparency = 0 }, "Smooth")
		end)
	end
end

local function refreshPalettePanelTheme()
	if not palettePanelRoot then
		return
	end
	palettePanelRoot.BackgroundColor3 = SelectedTheme.Background
	local filter = palettePanelRoot:FindFirstChild("Filter")
	if filter and filter:IsA("TextBox") then
		filter.BackgroundColor3 = SelectedTheme.InputBackground
		filter.TextColor3 = SelectedTheme.TextColor
		local fs = filter:FindFirstChildOfClass("UIStroke")
		if fs then
			fs.Color = SelectedTheme.InputStroke
		end
	end
end

local function ChangeTheme(Theme)
	local base = RayfieldLibrary.Theme.Default
	if typeof(Theme) == 'string' then
		local named = RayfieldLibrary.Theme[Theme]
		if not named then
			return
		end
		SelectedTheme = mergeThemeTables(base, named)
	elseif typeof(Theme) == 'table' then
		SelectedTheme = mergeThemeTables(base, Theme)
	end

	Rayfield.Main.BackgroundColor3 = SelectedTheme.Background
	Rayfield.Main.Topbar.BackgroundColor3 = SelectedTheme.Topbar
	Rayfield.Main.Topbar.CornerRepair.BackgroundColor3 = SelectedTheme.Topbar
	Rayfield.Main.Shadow.Image.ImageColor3 = SelectedTheme.Shadow

	Rayfield.Main.Topbar.ChangeSize.ImageColor3 = SelectedTheme.TextColor
	Rayfield.Main.Topbar.Hide.ImageColor3 = SelectedTheme.TextColor
	Rayfield.Main.Topbar.Search.ImageColor3 = SelectedTheme.TextColor
	if Topbar:FindFirstChild('Settings') then
		Rayfield.Main.Topbar.Settings.ImageColor3 = SelectedTheme.TextColor
		Rayfield.Main.Topbar.Divider.BackgroundColor3 = SelectedTheme.ElementStroke
	end

	Main.Search.BackgroundColor3 = SelectedTheme.TextColor
	Main.Search.Shadow.ImageColor3 = SelectedTheme.TextColor
	Main.Search.Search.ImageColor3 = SelectedTheme.TextColor
	Main.Search.Input.PlaceholderColor3 = SelectedTheme.TextColor
	Main.Search.UIStroke.Color = SelectedTheme.SecondaryElementStroke

	if Main:FindFirstChild('Notice') then
		Main.Notice.BackgroundColor3 = SelectedTheme.Background
	end

	for _, text in ipairs(Rayfield:GetDescendants()) do
		if text.Parent.Parent ~= Notifications then
			if text:IsA('TextLabel') or text:IsA('TextBox') then text.TextColor3 = SelectedTheme.TextColor end
		end
	end

	for _, TabPage in ipairs(Elements:GetChildren()) do
		for _, Element in ipairs(TabPage:GetChildren()) do
			if Element.ClassName == "Frame" and Element.Name ~= "Placeholder" and Element.Name ~= "SectionSpacing" and Element.Name ~= "Divider" and Element.Name ~= "SectionTitle" and Element.Name ~= "SearchTitle-fsefsefesfsefesfesfThanks" then
				Element.BackgroundColor3 = SelectedTheme.ElementBackground
				Element.UIStroke.Color = SelectedTheme.ElementStroke
			end
		end
	end
	if DesignTokensMod and DesignTokensMod.ApplyTypographyRole then
		local tbTitle = Topbar:FindFirstChild("Title")
		if tbTitle and tbTitle:IsA("TextLabel") then
			DesignTokensMod.ApplyTypographyRole(tbTitle, "Title", SelectedTheme.TextColor)
		end
		local lf = Main:FindFirstChild("LoadingFrame")
		if lf then
			local lt = lf:FindFirstChild("Title")
			local ls = lf:FindFirstChild("Subtitle")
			local lv = lf:FindFirstChild("Version")
			if lt and lt:IsA("TextLabel") then
				DesignTokensMod.ApplyTypographyRole(lt, "Title", SelectedTheme.TextColor)
			end
			if ls and ls:IsA("TextLabel") then
				DesignTokensMod.ApplyTypographyRole(ls, "Subtitle", SelectedTheme.TextColor)
			end
			if lv and lv:IsA("TextLabel") then
				DesignTokensMod.ApplyTypographyRole(lv, "Caption", SelectedTheme.TextColor)
			end
		end
	end
	refreshPalettePanelTheme()
end

local function getIcon(name : string): {id: number, imageRectSize: Vector2, imageRectOffset: Vector2}
	if not Icons then
		warn("Lucide Icons: Cannot use icons as icons library is not loaded")
		return
	end
	name = string.match(string.lower(name), "^%s*(.*)%s*$") :: string
	local sizedicons = Icons['48px']
	local r = sizedicons[name]
	if not r then
		error("Lucide Icons: Failed to find icon by the name of \"" .. name .. "\"", 2)
	end

	local rirs = r[2]
	local riro = r[3]

	if type(r[1]) ~= "number" or type(rirs) ~= "table" or type(riro) ~= "table" then
		error("Lucide Icons: Internal error: Invalid auto-generated asset entry")
	end

	local irs = Vector2.new(rirs[1], rirs[2])
	local iro = Vector2.new(riro[1], riro[2])

	local asset = {
		id = r[1],
		imageRectSize = irs,
		imageRectOffset = iro,
	}

	return asset
end
local function getAssetUri(id: any): string
	local assetUri = ""
	if type(id) == "number" then
		assetUri = "rbxassetid://" .. id
	elseif type(id) == "string" and not Icons then
		warn("Rayfield | Cannot use Lucide icons as icons library is not loaded")
	else
		warn("Rayfield | The icon argument must either be an icon ID (number) or a Lucide icon name (string)")
	end
	return assetUri
end

local function isCustomAsset(value)
	return type(value) == "string" and (string.find(value, "rbxasset://") == 1 or string.find(value, "rbxthumb://") == 1)
end

local function resolveIcon(icon)
	if not icon or icon == 0 then
		return "", nil, nil
	end

	local cacheKey = typeof(icon) .. "\0" .. tostring(icon)
	local cached = iconResolveCache[cacheKey]
	if cached then
		return cached[1], cached[2], cached[3]
	end

	if isCustomAsset(icon) then
		iconResolveCache[cacheKey] = { icon, nil, nil }
		return icon, nil, nil
	end

	if secureMode then
		secureNotify("icon_blocked", "Secure Mode", "Element icons using asset IDs or Lucide names are blocked. Use getcustomasset() for icons to stay undetected.")
		return "", nil, nil
	end

	local r1, r2, r3
	if typeof(icon) == "string" and Icons then
		local asset = getIcon(icon)
		r1 = "rbxassetid://" .. asset.id
		r2 = asset.imageRectOffset
		r3 = asset.imageRectSize
	else
		r1 = getAssetUri(icon)
		r2 = nil
		r3 = nil
	end
	iconResolveCache[cacheKey] = { r1, r2, r3 }
	return r1, r2, r3
end

local function makeDraggable(object, dragObject, enableTaptic, tapticOffset)
	local dragging = false
	local relative = nil

	local offset = Vector2.zero
	local screenGui = object:FindFirstAncestorWhichIsA("ScreenGui")
	if screenGui and screenGui.IgnoreGuiInset then
		offset += getService('GuiService'):GetGuiInset()
	end

	local function connectFunctions()
		if dragBar and enableTaptic then
			dragBar.MouseEnter:Connect(function()
				if not dragging and not Hidden then
					rfTween(dragBarCosmetic, {BackgroundTransparency = 0.5, Size = UDim2.new(0, 120, 0, 4)}, "Bouncy")
				end
			end)

			dragBar.MouseLeave:Connect(function()
				if not dragging and not Hidden then
					rfTween(dragBarCosmetic, {BackgroundTransparency = 0.7, Size = UDim2.new(0, 100, 0, 4)}, "Bouncy")
				end
			end)
		end
	end

	connectFunctions()

	dragObject.InputBegan:Connect(function(input, processed)
		if processed then return end

		local inputType = input.UserInputType.Name
		if inputType == "MouseButton1" or inputType == "Touch" then
			dragging = true

			relative = object.AbsolutePosition + object.AbsoluteSize * object.AnchorPoint - UserInputService:GetMouseLocation()
			if enableTaptic and not Hidden then
				rfTween(dragBarCosmetic, {Size = UDim2.new(0, 110, 0, 4), BackgroundTransparency = 0}, "Bouncy")
			end
		end
	end)

	local inputEnded = UserInputService.InputEnded:Connect(function(input)
		if not dragging then return end

		local inputType = input.UserInputType.Name
		if inputType == "MouseButton1" or inputType == "Touch" then
			dragging = false

			if enableTaptic and not Hidden then
				rfTween(dragBarCosmetic, {Size = UDim2.new(0, 100, 0, 4), BackgroundTransparency = 0.7}, "Bouncy")
			end
		end
	end)

	local renderStepped = RunService.RenderStepped:Connect(function()
		if dragging and not Hidden then
			local position = UserInputService:GetMouseLocation() + relative + offset
			if enableTaptic and tapticOffset then
				rfTween(object, {Position = UDim2.fromOffset(position.X, position.Y)}, "Emphasis")
				rfTween(dragObject.Parent, {Position = UDim2.fromOffset(position.X, position.Y + ((useMobileSizing and tapticOffset[2]) or tapticOffset[1]))}, "Emphasis")
			else
				if dragBar and tapticOffset then
					dragBar.Position = UDim2.fromOffset(position.X, position.Y + ((useMobileSizing and tapticOffset[2]) or tapticOffset[1]))
				end
				object.Position = UDim2.fromOffset(position.X, position.Y)
			end
		end
	end)

	object.Destroying:Connect(function()
		if inputEnded then inputEnded:Disconnect() end
		if renderStepped then renderStepped:Disconnect() end
	end)
end


local function PackColor(Color)
	return {R = Color.R * 255, G = Color.G * 255, B = Color.B * 255}
end    

local function UnpackColor(Color)
	return Color3.fromRGB(Color.R, Color.G, Color.B)
end

local function LoadConfiguration(Configuration)
	local success, Data = pcall(function() return HttpService:JSONDecode(Configuration) end)
	local changed

	if not success then warn('Rayfield had an issue decoding the configuration file, please try delete the file and reopen Rayfield.') return end

	-- Iterate through current UI elements' flags
	for FlagName, Flag in pairs(RayfieldLibrary.Flags) do
		local FlagValue = Data[FlagName]

		if (typeof(FlagValue) == 'boolean' and FlagValue == false) or FlagValue then
			task.spawn(function()
				if Flag.Type == "ColorPicker" then
					changed = true
					Flag:Set(UnpackColor(FlagValue))
				else
					if (Flag.CurrentValue or Flag.CurrentKeybind or Flag.CurrentOption or Flag.Color) ~= FlagValue then 
						changed = true
						Flag:Set(FlagValue) 	
					end
				end
			end)
		else
			warn("Rayfield | Unable to find '"..FlagName.. "' in the save file.")
			print("The error above may not be an issue if new elements have been added or not been set values.")
			--RayfieldLibrary:Notify({Title = "Rayfield Flags", Content = "Rayfield was unable to find '"..FlagName.. "' in the save file. Check sirius.menu/discord for help.", Image = 3944688398})
		end
	end

	return changed
end

local function SaveConfiguration()
	if not CEnabled or not globalLoaded then return end

	if debugX then
		print('Saving')
	end

	local Data = {}
	for i, v in pairs(RayfieldLibrary.Flags) do
		if v.Type == "ColorPicker" then
			Data[i] = PackColor(v.Color)
		else
			if typeof(v.CurrentValue) == 'boolean' then
				if v.CurrentValue == false then
					Data[i] = false
				else
					Data[i] = v.CurrentValue or v.CurrentKeybind or v.CurrentOption or v.Color
				end
			else
				Data[i] = v.CurrentValue or v.CurrentKeybind or v.CurrentOption or v.Color
			end
		end
	end

	if useStudio and script and script.Parent then
		if script.Parent:FindFirstChild('configuration') then script.Parent.configuration:Destroy() end

		local ScreenGui = Instance.new("ScreenGui")
		ScreenGui.Parent = script.Parent
		ScreenGui.Name = 'configuration'

		local TextBox = Instance.new("TextBox")
		TextBox.Parent = ScreenGui
		TextBox.Size = UDim2.new(0, 800, 0, 50)
		TextBox.AnchorPoint = Vector2.new(0.5, 0)
		TextBox.Position = UDim2.new(0.5, 0, 0, 30)
		TextBox.Text = HttpService:JSONEncode(Data)
		TextBox.ClearTextOnFocus = false
	end

	if debugX then
		warn(HttpService:JSONEncode(Data))
	end


	callSafely(writefile, ConfigurationFolder .. "/" .. CFileName .. ConfigurationExtension, tostring(HttpService:JSONEncode(Data)))
end

local function notificationStrokeColor(data)
	local sem = DesignTokensMod and DesignTokensMod.SemanticFromTheme(SelectedTheme)
	if not sem then
		return SelectedTheme.TextColor
	end
	local t = data and data.Type
	if t == "Success" then
		return sem.Success
	elseif t == "Warning" then
		return sem.Warning
	elseif t == "Error" then
		return sem.Error
	elseif t == "Info" then
		return sem.Info
	end
	return SelectedTheme.TextColor
end

local function runSingleNotification(data)
	-- Notification Object Creation
	local newNotification = Notifications.Template:Clone()
	local zNotif = (DesignTokensMod and DesignTokensMod.ZIndex and DesignTokensMod.ZIndex.Notifications) or 40
	newNotification.ZIndex = zNotif
	newNotification.Name = data.Title or 'No Title Provided'
	newNotification.Parent = Notifications
	newNotification.LayoutOrder = #Notifications:GetChildren()
	newNotification.Visible = false

	newNotification.Title.Text = data.Title or "Unknown Title"
	newNotification.Description.Text = data.Content or "Unknown Content"

	if data.Image then
		local img, rectOffset, rectSize = resolveIcon(data.Image)
		newNotification.Icon.Image = img
		if rectOffset then newNotification.Icon.ImageRectOffset = rectOffset end
		if rectSize then newNotification.Icon.ImageRectSize = rectSize end
	else
		newNotification.Icon.Image = ""
	end

	newNotification.Title.TextColor3 = SelectedTheme.TextColor
	newNotification.Description.TextColor3 = SelectedTheme.TextColor
	newNotification.BackgroundColor3 = SelectedTheme.Background
	newNotification.UIStroke.Color = notificationStrokeColor(data)
	newNotification.Icon.ImageColor3 = SelectedTheme.TextColor
	if DesignTokensMod and DesignTokensMod.ApplyShadowTier then
		DesignTokensMod.ApplyShadowTier(newNotification.UIStroke, newNotification.Shadow, "medium")
	end

	newNotification.BackgroundTransparency = 1
	newNotification.Title.TextTransparency = 1
	newNotification.Description.TextTransparency = 1
	newNotification.UIStroke.Transparency = 1
	newNotification.Shadow.ImageTransparency = 1
	newNotification.Size = UDim2.new(1, 0, 0, 800)
	newNotification.Icon.ImageTransparency = 1
	newNotification.Icon.BackgroundTransparency = 1

	if DesignTokensMod and DesignTokensMod.ApplyTypographyRole then
		DesignTokensMod.ApplyTypographyRole(newNotification.Title, "Subtitle", SelectedTheme.TextColor)
		DesignTokensMod.ApplyTypographyRole(newNotification.Description, "Body", SelectedTheme.TextColor)
	end

	task.wait()

	newNotification.Visible = true

	if data.Actions then
		warn('Rayfield | Not seeing your actions in notifications?')
		print("Notification Actions are being sunset for now, keep up to date on when they're back in the discord. (sirius.menu/discord)")
	end

	local bounds = { newNotification.Title.TextBounds.Y, newNotification.Description.TextBounds.Y }
	newNotification.Size = UDim2.new(1, -60, 0, -Notifications:FindFirstChild("UIListLayout").Padding.Offset)

	newNotification.Icon.Size = UDim2.new(0, 32, 0, 32)
	newNotification.Icon.Position = UDim2.new(0, 20, 0.5, 0)

	rfTween(newNotification, { Size = UDim2.new(1, 0, 0, math.max(bounds[1] + bounds[2] + 31, 60)) }, "Emphasis")

	task.wait(0.15)
	rfTween(newNotification, { BackgroundTransparency = 0.45 }, "Smooth")
	rfTween(newNotification.Title, { TextTransparency = 0 }, "Fast")

	task.wait(0.05)

	rfTween(newNotification.Icon, { ImageTransparency = 0 }, "Fast")

	task.wait(0.05)
	rfTween(newNotification.Description, { TextTransparency = 0.35 }, "Fast")
	rfTween(newNotification.UIStroke, { Transparency = 0.95 }, "Smooth")
	rfTween(newNotification.Shadow, { ImageTransparency = 0.82 }, "Smooth")

	local waitDuration = math.min(math.max((#newNotification.Description.Text * 0.1) + 2.5, 3), 10)
	task.wait(data.Duration or waitDuration)

	newNotification.Icon.Visible = false
	rfTween(newNotification, { BackgroundTransparency = 1 }, "Smooth")
	rfTween(newNotification.UIStroke, { Transparency = 1 }, "Smooth")
	rfTween(newNotification.Shadow, { ImageTransparency = 1 }, "Fast")
	rfTween(newNotification.Title, { TextTransparency = 1 }, "Fast")
	rfTween(newNotification.Description, { TextTransparency = 1 }, "Fast")

	rfTween(newNotification, { Size = UDim2.new(1, -90, 0, 0) }, "Slow")

	task.wait(1)

	rfTween(newNotification, { Size = UDim2.new(1, -90, 0, -Notifications:FindFirstChild("UIListLayout").Padding.Offset) }, "Slow")

	newNotification.Visible = false
	newNotification:Destroy()
end

local function drainNotifyQueue()
	while #notifyQueue > 0 and notifyActiveCount < MAX_CONCURRENT_NOTIFICATIONS do
		local data = table.remove(notifyQueue, 1)
		notifyActiveCount = notifyActiveCount + 1
		task.spawn(function()
			pcall(runSingleNotification, data)
			notifyActiveCount = notifyActiveCount - 1
			drainNotifyQueue()
		end)
	end
end

function RayfieldLibrary:Notify(data)
	table.insert(notifyQueue, data)
	drainNotifyQueue()
end

local function openSearch()
	searchOpen = true

	Main.Search.BackgroundTransparency = 1
	Main.Search.Shadow.ImageTransparency = 1
	Main.Search.Input.TextTransparency = 1
	Main.Search.Search.ImageTransparency = 1
	Main.Search.UIStroke.Transparency = 1
	Main.Search.Size = UDim2.new(1, 0, 0, 80)
	Main.Search.Position = UDim2.new(0.5, 0, 0, 70)

	Main.Search.Input.Interactable = true

	Main.Search.Visible = true

	for _, tabbtn in ipairs(TabList:GetChildren()) do
		if tabbtn.ClassName == "Frame" and tabbtn.Name ~= "Placeholder" then
			tabbtn.Interact.Visible = false
			rfTween(tabbtn, {BackgroundTransparency = 1}, "Emphasis")
			rfTween(tabbtn.Title, {TextTransparency = 1}, "Emphasis")
			rfTween(tabbtn.Image, {ImageTransparency = 1}, "Emphasis")
			rfTween(tabbtn.UIStroke, {Transparency = 1}, "Emphasis")
		end
	end

	Main.Search.Input:CaptureFocus()
	rfTween(Main.Search.Shadow, {ImageTransparency = 0.95}, "Smooth")
	rfTween(Main.Search, {Position = UDim2.new(0.5, 0, 0, 57), BackgroundTransparency = 0.9}, "Emphasis")
	rfTween(Main.Search.UIStroke, {Transparency = 0.8}, "Emphasis")
	rfTween(Main.Search.Input, {TextTransparency = 0.2}, "Emphasis")
	rfTween(Main.Search.Search, {ImageTransparency = 0.5}, "Emphasis")
	rfTween(Main.Search, {Size = UDim2.new(1, -35, 0, 35)}, "Emphasis")
end

local function closeSearch()
	searchOpen = false

	rfTween(Main.Search, { BackgroundTransparency = 1, Size = UDim2.new(1, -55, 0, 30) }, "Smooth")
	rfTween(Main.Search.Search, {ImageTransparency = 1}, "Smooth")
	rfTween(Main.Search.Shadow, {ImageTransparency = 1}, "Smooth")
	rfTween(Main.Search.UIStroke, {Transparency = 1}, "Smooth")
	rfTween(Main.Search.Input, {TextTransparency = 1}, "Smooth")

	for _, tabbtn in ipairs(TabList:GetChildren()) do
		if tabbtn.ClassName == "Frame" and tabbtn.Name ~= "Placeholder" then
			tabbtn.Interact.Visible = true
			if tostring(Elements.UIPageLayout.CurrentPage) == tabbtn.Title.Text then
				rfTween(tabbtn, {BackgroundTransparency = 0}, "Emphasis")
				rfTween(tabbtn.Image, {ImageTransparency = 0}, "Emphasis")
				rfTween(tabbtn.Title, {TextTransparency = 0}, "Emphasis")
				rfTween(tabbtn.UIStroke, {Transparency = 1}, "Emphasis")
			else
				rfTween(tabbtn, {BackgroundTransparency = 0.7}, "Emphasis")
				rfTween(tabbtn.Image, {ImageTransparency = 0.2}, "Emphasis")
				rfTween(tabbtn.Title, {TextTransparency = 0.2}, "Emphasis")
				rfTween(tabbtn.UIStroke, {Transparency = 0.5}, "Emphasis")
			end
		end
	end

	Main.Search.Input.Text = ''
	Main.Search.Input.Interactable = false
end

local paletteFilterBox = nil
local paletteScroll = nil
local paletteSelectedIndex = 0
local paletteItemsList = {} -- { label, callback } para navegação por setas

local function paletteFuzzyMatch(haystack: string, needle: string): boolean
	if needle == "" then
		return true
	end
	local h, n = string.lower(haystack), string.lower(needle)
	local ni = 1
	for i = 1, #h do
		if ni <= #n and string.sub(h, i, i) == string.sub(n, ni, ni) then
			ni += 1
		end
	end
	return ni > #n
end

local function paletteHighlightRow(index)
	if not paletteScroll then
		return
	end
	local rowNum = 0
	for _, ch in ipairs(paletteScroll:GetChildren()) do
		if ch:IsA("GuiButton") and ch.Name == "PaletteRow" then
			rowNum += 1
			local existingStroke = ch:FindFirstChildOfClass("UIStroke")
			if existingStroke then
				existingStroke:Destroy()
			end
			if rowNum == index then
				local stroke = Instance.new("UIStroke")
				stroke.Color = SelectedTheme.SliderBackground or Color3.fromRGB(50, 138, 220)
				stroke.Thickness = 1.5
				stroke.Transparency = 0.25
				stroke.Parent = ch
				ch.BackgroundColor3 = SelectedTheme.DropdownSelected or Color3.fromRGB(40, 40, 40)
				local scroll = paletteScroll :: ScrollingFrame
				local yPos = ch.AbsolutePosition.Y - scroll.AbsolutePosition.Y
				local scrollHeight = scroll.AbsoluteSize.Y
				if yPos < 0 or yPos + ch.AbsoluteSize.Y > scrollHeight then
					scroll.CanvasPosition = Vector2.new(0, ch.AbsolutePosition.Y - scroll.AbsolutePosition.Y - 8)
				end
			else
				ch.BackgroundColor3 = SelectedTheme.ElementBackground
			end
		end
	end
end

local function closeCommandPalette()
	if paletteOverlayId and OverlaySystem.isOpen(paletteOverlayId) then
		OverlaySystem.close(paletteOverlayId)
	end
end

local function rebuildPaletteList(filterText: string)
	if not paletteScroll then
		return
	end
	for _, ch in ipairs(paletteScroll:GetChildren()) do
		if ch:IsA("GuiButton") or (ch:IsA("TextLabel") and ch.Name == "PaletteRow") then
			ch:Destroy()
		end
	end
	table.clear(paletteItemsList)
	local rows = 0
	for _, entry in ipairs(currentWindowTabRegistry) do
		local label = "Tab: " .. entry.Name
		if paletteFuzzyMatch(label, filterText) then
			local row = Instance.new("TextButton")
			row.Name = "PaletteRow"
			row.BackgroundColor3 = SelectedTheme.ElementBackground
			row.Size = UDim2.new(1, -8, 0, 32)
			row.AutoButtonColor = true
			row.Text = label
			row.Font = Enum.Font.Gotham
			row.TextSize = 14
			row.TextColor3 = SelectedTheme.TextColor
			row.TextXAlignment = Enum.TextXAlignment.Left
			row.ZIndex = (paletteScroll :: ScrollingFrame).ZIndex + 1
			local pad = Instance.new("UIPadding")
			pad.PaddingLeft = UDim.new(0, 10)
			pad.Parent = row
			if DesignTokensMod and DesignTokensMod.ApplyTypographyRole then
				DesignTokensMod.ApplyTypographyRole(row, "Body", SelectedTheme.TextColor)
			end
			row.Parent = paletteScroll
			local cb = function()
				pcall(entry.Activate)
				closeCommandPalette()
			end
			row.MouseButton1Click:Connect(cb)
			table.insert(paletteItemsList, { label = label, callback = cb })
			rows += 1
		end
	end
	for _, cmd in ipairs(commandRegistry) do
		local label = "Cmd: " .. (cmd.Title or "Command")
		if paletteFuzzyMatch(label, filterText) then
			local row = Instance.new("TextButton")
			row.Name = "PaletteRow"
			row.BackgroundColor3 = SelectedTheme.ElementBackground
			row.Size = UDim2.new(1, -8, 0, 32)
			row.AutoButtonColor = true
			row.Text = label
			row.Font = Enum.Font.Gotham
			row.TextSize = 14
			row.TextColor3 = SelectedTheme.TextColor
			row.TextXAlignment = Enum.TextXAlignment.Left
			row.ZIndex = (paletteScroll :: ScrollingFrame).ZIndex + 1
			local pad = Instance.new("UIPadding")
			pad.PaddingLeft = UDim.new(0, 10)
			pad.Parent = row
			if DesignTokensMod and DesignTokensMod.ApplyTypographyRole then
				DesignTokensMod.ApplyTypographyRole(row, "Body", SelectedTheme.TextColor)
			end
			row.Parent = paletteScroll
			local cb = function()
				pcall(cmd.Callback)
				closeCommandPalette()
			end
			row.MouseButton1Click:Connect(cb)
			table.insert(paletteItemsList, { label = label, callback = cb })
			rows += 1
		end
	end
	if rows == 0 then
		local empty = Instance.new("TextLabel")
		empty.Name = "PaletteRow"
		empty.BackgroundTransparency = 1
		empty.Size = UDim2.new(1, 0, 0, 28)
		empty.Text = "Nenhum resultado"
		empty.TextColor3 = SelectedTheme.PlaceholderColor or SelectedTheme.TextColor
		empty.Font = Enum.Font.Gotham
		empty.TextSize = 13
		empty.ZIndex = (paletteScroll :: ScrollingFrame).ZIndex + 1
		if DesignTokensMod and DesignTokensMod.ApplyTypographyRole then
			DesignTokensMod.ApplyTypographyRole(empty, "Caption", SelectedTheme.PlaceholderColor or SelectedTheme.TextColor)
		end
		empty.Parent = paletteScroll
	end
	if #paletteItemsList > 0 then
		paletteSelectedIndex = 1
		paletteHighlightRow(1)
	else
		paletteSelectedIndex = 0
	end
end

local function ensureCommandPaletteGui()
	if palettePanelRoot and palettePanelRoot.Parent then
		return
	end
	if not paletteContentBucket then
		local bucket = Instance.new("Folder")
		bucket.Name = "__RayfieldPaletteBucket__"
		bucket.Parent = Rayfield
		paletteContentBucket = bucket
	end
	local zModal = (DesignTokensMod and DesignTokensMod.ZIndex and DesignTokensMod.ZIndex.Modal) or 30
	local panel = Instance.new("Frame")
	panel.Name = "Panel"
	panel.Size = UDim2.new(0, 440, 0, 300)
	panel.Position = UDim2.new(0.5, -220, 0.12, 0)
	panel.BackgroundColor3 = SelectedTheme.Background
	panel.ZIndex = zModal + 1
	panel.Visible = false
	panel.Parent = paletteContentBucket

	local pStroke = Instance.new("UIStroke")
	pStroke.Color = SelectedTheme.ElementStroke
	pStroke.Thickness = 1
	pStroke.Parent = panel

	local pCorner = Instance.new("UICorner")
	pCorner.CornerRadius = UDim.new(0, 10)
	pCorner.Parent = panel

	local filter = Instance.new("TextBox")
	filter.Name = "Filter"
	filter.Size = UDim2.new(1, -24, 0, 38)
	filter.Position = UDim2.new(0, 12, 0, 12)
	filter.BackgroundColor3 = SelectedTheme.InputBackground
	filter.TextColor3 = SelectedTheme.TextColor
	filter.PlaceholderText = "Filtrar abas e comandos (Ctrl+P)"
	filter.ClearTextOnFocus = false
	filter.Text = ""
	filter.Font = Enum.Font.Gotham
	filter.TextSize = 15
	filter.ZIndex = zModal + 2
	filter.Parent = panel
	if DesignTokensMod and DesignTokensMod.ApplyTypographyRole then
		DesignTokensMod.ApplyTypographyRole(filter, "Body", SelectedTheme.TextColor)
	end

	local fStroke = Instance.new("UIStroke")
	fStroke.Color = SelectedTheme.InputStroke
	fStroke.Parent = filter

	local fCorner = Instance.new("UICorner")
	fCorner.CornerRadius = UDim.new(0, 8)
	fCorner.Parent = filter

	local scroll = Instance.new("ScrollingFrame")
	scroll.Name = "List"
	scroll.Size = UDim2.new(1, -24, 1, -66)
	scroll.Position = UDim2.new(0, 12, 0, 58)
	scroll.BackgroundTransparency = 1
	scroll.ScrollBarThickness = 5
	scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.ZIndex = zModal + 2
	scroll.Parent = panel

	local listLayout = Instance.new("UIListLayout")
	listLayout.Padding = UDim.new(0, 4)
	listLayout.Parent = scroll

	palettePanelRoot = panel
	paletteFilterBox = filter
	paletteScroll = scroll

	filter:GetPropertyChangedSignal("Text"):Connect(function()
		if paletteOpen then
			rebuildPaletteList(filter.Text)
		end
	end)
end

local function openCommandPalette()
	if rayfieldDestroyed or Hidden then
		return
	end
	if paletteOverlayId and OverlaySystem.isOpen(paletteOverlayId) then
		return
	end
	ensureCommandPaletteGui()
	lastFocusedGuiForPalette = GuiService:GetFocusedTextBox()
	refreshPalettePanelTheme()
	paletteOpen = true
	pcall(function()
		paletteSavedDisplayOrder = Rayfield.DisplayOrder
		Rayfield.DisplayOrder = math.max(paletteSavedDisplayOrder, 200)
	end)
	local backdropOp = (DesignTokensMod and DesignTokensMod.Opacity and DesignTokensMod.Opacity.Backdrop) or 0.5
	paletteOverlayId = OverlaySystem.show({
		level = "Modal",
		opacity = backdropOp,
		dismissOnBackdrop = true,
		content = palettePanelRoot,
		detachContentBeforeDestroy = paletteContentBucket,
		onClose = function()
			paletteOpen = false
			paletteOverlayId = nil
			pcall(function()
				Rayfield.DisplayOrder = paletteSavedDisplayOrder
			end)
			local tb = lastFocusedGuiForPalette
			lastFocusedGuiForPalette = nil
			if tb and tb.Parent then
				pcall(function()
					tb:CaptureFocus()
				end)
			end
			if palettePanelRoot then
				palettePanelRoot.Visible = false
			end
		end,
	})
	if palettePanelRoot then
		palettePanelRoot.Visible = true
	end
	if paletteFilterBox then
		paletteFilterBox.Text = ""
		rebuildPaletteList("")
		task.defer(function()
			if paletteFilterBox then
				paletteFilterBox:CaptureFocus()
			end
		end)
	end
end

local function setupCommandPalette()
	if paletteInputConnection then
		return
	end
	paletteInputConnection = UserInputService.InputBegan:Connect(function(input, processed)
		if processed or rayfieldDestroyed then
			return
		end
		if not activeWindowSettings or not activeWindowSettings.CommandPalette then
			return
		end
		if input.KeyCode == Enum.KeyCode.Escape and paletteOpen then
			closeCommandPalette()
			return
		end
		
		-- Navegação por setas na palette
		if paletteOpen then
			if input.KeyCode == Enum.KeyCode.Up then
				local n = #paletteItemsList
				if n > 0 then
					paletteSelectedIndex = ((paletteSelectedIndex - 2 + n) % n) + 1
					paletteHighlightRow(paletteSelectedIndex)
				end
				return
			end
			if input.KeyCode == Enum.KeyCode.Down then
				local n = #paletteItemsList
				if n > 0 then
					paletteSelectedIndex = (paletteSelectedIndex % n) + 1
					paletteHighlightRow(paletteSelectedIndex)
				end
				return
			end
			if input.KeyCode == Enum.KeyCode.Return then
				if paletteSelectedIndex > 0 and paletteItemsList[paletteSelectedIndex] then
					pcall(paletteItemsList[paletteSelectedIndex].callback)
				end
				return
			end
		end
		
		local ctrl = UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.RightControl)
		if ctrl and input.KeyCode == Enum.KeyCode.P then
			if GuiService.GetFocusedTextBox then
				local focus = GuiService:GetFocusedTextBox()
				if focus and not focus:IsDescendantOf(Rayfield) then
					return
				end
			end
			if paletteOpen then
				closeCommandPalette()
			else
				task.spawn(openCommandPalette)
			end
		end
	end)
end

-- Sets element visibility across all tab pages (used by Hide, Unhide, Maximise, Minimise)
local function setElementsVisible(show)
	for _, tab in ipairs(Elements:GetChildren()) do
		if tab.Name ~= "Template" and tab.ClassName == "ScrollingFrame" and tab.Name ~= "Placeholder" then
			for _, element in ipairs(tab:GetChildren()) do
				if element.ClassName == "Frame" then
					if element.Name ~= "SectionSpacing" and element.Name ~= "Placeholder" then
						if element.Name == "SectionTitle" or element.Name == 'SearchTitle-fsefsefesfsefesfesfThanks' then
							rfTween(element.Title, {TextTransparency = show and 0.4 or 1}, "Emphasis")
						elseif element.Name == 'Divider' then
							rfTween(element.Divider, {BackgroundTransparency = show and 0.85 or 1}, "Emphasis")
						else
							rfTween(element, {BackgroundTransparency = show and 0 or 1}, "Emphasis")
							rfTween(element.UIStroke, {Transparency = show and 0 or 1}, "Emphasis")
							rfTween(element.Title, {TextTransparency = show and 0 or 1}, "Emphasis")
						end
						for _, child in ipairs(element:GetChildren()) do
							if child.ClassName == "Frame" or child.ClassName == "TextLabel" or child.ClassName == "TextBox" or child.ClassName == "ImageButton" or child.ClassName == "ImageLabel" then
								child.Visible = show
							end
						end
					end
				end
			end
		end
	end
end

-- Sets tab button visibility (used by Hide, Unhide, Maximise, Minimise)
local function setTabButtonsVisible(show)
	for _, tabbtn in ipairs(TabList:GetChildren()) do
		if tabbtn.ClassName == "Frame" and tabbtn.Name ~= "Placeholder" then
			if show then
				if tostring(Elements.UIPageLayout.CurrentPage) == tabbtn.Title.Text then
					rfTween(tabbtn, {BackgroundTransparency = 0}, "Emphasis")
					rfTween(tabbtn.Image, {ImageTransparency = 0}, "Emphasis")
					rfTween(tabbtn.Title, {TextTransparency = 0}, "Emphasis")
					rfTween(tabbtn.UIStroke, {Transparency = 1}, "Emphasis")
				else
					rfTween(tabbtn, {BackgroundTransparency = 0.7}, "Emphasis")
					rfTween(tabbtn.Image, {ImageTransparency = 0.2}, "Emphasis")
					rfTween(tabbtn.Title, {TextTransparency = 0.2}, "Emphasis")
					rfTween(tabbtn.UIStroke, {Transparency = 0.5}, "Emphasis")
				end
			else
				rfTween(tabbtn, {BackgroundTransparency = 1}, "Emphasis")
				rfTween(tabbtn.Title, {TextTransparency = 1}, "Emphasis")
				rfTween(tabbtn.Image, {ImageTransparency = 1}, "Emphasis")
				rfTween(tabbtn.UIStroke, {Transparency = 1}, "Emphasis")
			end
		end
	end
end

local function Hide(notify: boolean?)
	if MPrompt then
		MPrompt.Title.TextColor3 = Color3.fromRGB(255, 255, 255)
		MPrompt.Position = UDim2.new(0.5, 0, 0, -50)
		MPrompt.Size = UDim2.new(0, 40, 0, 10)
		MPrompt.BackgroundTransparency = 1
		MPrompt.Title.TextTransparency = 1
		MPrompt.Visible = true
	end

	task.spawn(closeSearch)
	closeCommandPalette()

	Debounce = true
	if notify then
		if useMobilePrompt then 
			RayfieldLibrary:Notify({Title = "Interface Hidden", Content = "The interface has been hidden, you can unhide the interface by tapping 'Show'.", Duration = 7, Image = 4400697855})
		else
			RayfieldLibrary:Notify({Title = "Interface Hidden", Content = "The interface has been hidden, you can unhide the interface by tapping " .. tostring(getSetting("General", "rayfieldOpen")) .. ".", Duration = 7, Image = 4400697855})
		end
	end

	rfTween(Main, {Size = UDim2.new(0, 470, 0, 0)}, "Emphasis")
	rfTween(Main.Topbar, {Size = UDim2.new(0, 470, 0, 45)}, "Emphasis")
	rfTween(Main, {BackgroundTransparency = 1}, "Emphasis")
	rfTween(Main.Topbar, {BackgroundTransparency = 1}, "Emphasis")
	rfTween(Main.Topbar.Divider, {BackgroundTransparency = 1}, "Emphasis")
	rfTween(Main.Topbar.CornerRepair, {BackgroundTransparency = 1}, "Emphasis")
	rfTween(Main.Topbar.Title, {TextTransparency = 1}, "Emphasis")
	rfTween(Main.Shadow.Image, {ImageTransparency = 1}, "Emphasis")
	rfTween(Topbar.UIStroke, {Transparency = 1}, "Emphasis")
	if dragBarCosmetic then
		rfTween(dragBarCosmetic, {BackgroundTransparency = 1}, "Bouncy")
	end

	if useMobilePrompt and MPrompt then
		rfTween(MPrompt, {Size = UDim2.new(0, 120, 0, 30), Position = UDim2.new(0.5, 0, 0, 20), BackgroundTransparency = 0.3}, "Emphasis")
		rfTween(MPrompt.Title, {TextTransparency = 0.3}, "Emphasis")
	end

	for _, TopbarButton in ipairs(Topbar:GetChildren()) do
		if TopbarButton.ClassName == "ImageButton" then
			rfTween(TopbarButton, {ImageTransparency = 1}, "Emphasis")
		end
	end

	setTabButtonsVisible(false)

	if dragInteract then dragInteract.Visible = false end

	setElementsVisible(false)

	task.wait(0.5)
	Main.Visible = false
	Debounce = false
end

local function Maximise()
	Debounce = true
	Topbar.ChangeSize.Image = customAssets[tostring(10137941941)]

	rfTween(Topbar.UIStroke, {Transparency = 1}, "Emphasis")
	rfTween(Main.Shadow.Image, {ImageTransparency = 0.6}, "Emphasis")
	rfTween(Topbar.CornerRepair, {BackgroundTransparency = 0}, "Emphasis")
	rfTween(Topbar.Divider, {BackgroundTransparency = 0}, "Emphasis")
	rfTween(dragBarCosmetic, {BackgroundTransparency = 0.7}, "Bouncy")
	rfTween(Main, {Size = useMobileSizing and UDim2.new(0, 500, 0, 275) or UDim2.new(0, 500, 0, 475)}, "Emphasis")
	rfTween(Topbar, {Size = UDim2.new(0, 500, 0, 45)}, "Emphasis")
	TabList.Visible = true
	task.wait(0.2)

	Elements.Visible = true

	setElementsVisible(true)

	task.wait(0.1)

	setTabButtonsVisible(true)

	task.wait(0.5)
	Debounce = false
end


local function Unhide()
	Debounce = true
	Main.Position = UDim2.new(0.5, 0, 0.5, 0)
	Main.Visible = true
	rfTween(Main, {Size = useMobileSizing and UDim2.new(0, 500, 0, 275) or UDim2.new(0, 500, 0, 475)}, "Emphasis")
	rfTween(Main.Topbar, {Size = UDim2.new(0, 500, 0, 45)}, "Emphasis")
	rfTween(Main.Shadow.Image, {ImageTransparency = 0.6}, "Emphasis")
	rfTween(Main, {BackgroundTransparency = 0}, "Emphasis")
	rfTween(Main.Topbar, {BackgroundTransparency = 0}, "Emphasis")
	rfTween(Main.Topbar.Divider, {BackgroundTransparency = 0}, "Emphasis")
	rfTween(Main.Topbar.CornerRepair, {BackgroundTransparency = 0}, "Emphasis")
	rfTween(Main.Topbar.Title, {TextTransparency = 0}, "Emphasis")

	if MPrompt then
		rfTween(MPrompt, {Size = UDim2.new(0, 40, 0, 10), Position = UDim2.new(0.5, 0, 0, -50), BackgroundTransparency = 1}, "Emphasis")
		rfTween(MPrompt.Title, {TextTransparency = 1}, "Emphasis")

		task.spawn(function()
			task.wait(0.5)
			MPrompt.Visible = false
		end)
	end

	if Minimised then
		task.spawn(Maximise)
	end

	dragBar.Position = useMobileSizing and UDim2.new(0.5, 0, 0.5, dragOffsetMobile) or UDim2.new(0.5, 0, 0.5, dragOffset)

	dragInteract.Visible = true

	for _, TopbarButton in ipairs(Topbar:GetChildren()) do
		if TopbarButton.ClassName == "ImageButton" then
			if TopbarButton.Name == 'Icon' then
				rfTween(TopbarButton, {ImageTransparency = 0}, "Emphasis")
			else
				rfTween(TopbarButton, {ImageTransparency = 0.8}, "Emphasis")
			end

		end
	end

	setTabButtonsVisible(true)

	setElementsVisible(true)

	rfTween(dragBarCosmetic, {BackgroundTransparency = 0.5}, "Bouncy")

	task.wait(0.5)
	Minimised = false
	Debounce = false
end

local function Minimise()
	Debounce = true
	Topbar.ChangeSize.Image = customAssets[tostring(11036884234)]

	Topbar.UIStroke.Color = SelectedTheme.ElementStroke

	task.spawn(closeSearch)

	setTabButtonsVisible(false)

	setElementsVisible(false)

	rfTween(dragBarCosmetic, {BackgroundTransparency = 1}, "Bouncy")
	rfTween(Topbar.UIStroke, {Transparency = 0}, "Emphasis")
	rfTween(Main.Shadow.Image, {ImageTransparency = 1}, "Emphasis")
	rfTween(Topbar.CornerRepair, {BackgroundTransparency = 1}, "Emphasis")
	rfTween(Topbar.Divider, {BackgroundTransparency = 1}, "Emphasis")
	rfTween(Main, {Size = UDim2.new(0, 495, 0, 45)}, "Emphasis")
	rfTween(Topbar, {Size = UDim2.new(0, 495, 0, 45)}, "Emphasis")

	task.wait(0.3)

	Elements.Visible = false
	TabList.Visible = false

	task.wait(0.2)
	Debounce = false
end

local function saveSettings() -- Save settings to config file
	local encoded
	local success, err = pcall(function()
		encoded = HttpService:JSONEncode(settingsTable)
	end)

	if success then
		if useStudio and script and script.Parent then
			if script.Parent['get.val'] then
				script.Parent['get.val'].Value = encoded
			end
		end
		callSafely(writefile, RayfieldFolder..'/settings'..ConfigurationExtension, encoded)
	end
end

local function updateSetting(category: string, setting: string, value: any)
	if not settingsInitialized then
		return
	end
	settingsTable[category][setting].Value = value
	overriddenSettings[category .. "." .. setting] = nil -- If user changes an overriden setting, remove the override
	saveSettings()
end

local function createSettings(window)
	if not (writefile and isfile and readfile and isfolder and makefolder) and not useStudio then
		if Topbar['Settings'] then Topbar.Settings.Visible = false end
		Topbar['Search'].Position = UDim2.new(1, -75, 0.5, 0)
		warn('Can\'t create settings as no file-saving functionality is available.')
		return
	end

	local newTab = window:CreateTab('Rayfield Settings', 0, true)

	if TabList['Rayfield Settings'] then
		TabList['Rayfield Settings'].LayoutOrder = 1000
	end

	if Elements['Rayfield Settings'] then
		Elements['Rayfield Settings'].LayoutOrder = 1000
	end

	-- Create sections and elements
	for categoryName, settingCategory in pairs(settingsTable) do
		newTab:CreateSection(categoryName)

		for settingName, setting in pairs(settingCategory) do
			if setting.Type == 'input' then
				setting.Element = newTab:CreateInput({
					Name = setting.Name,
					CurrentValue = setting.Value,
					PlaceholderText = setting.Placeholder,
					Ext = true,
					RemoveTextAfterFocusLost = setting.ClearOnFocus,
					Callback = function(Value)
						updateSetting(categoryName, settingName, Value)
					end,
				})
			elseif setting.Type == 'toggle' then
				setting.Element = newTab:CreateToggle({
					Name = setting.Name,
					CurrentValue = setting.Value,
					Ext = true,
					Callback = function(Value)
						updateSetting(categoryName, settingName, Value)
					end,
				})
			elseif setting.Type == 'bind' then
				setting.Element = newTab:CreateKeybind({
					Name = setting.Name,
					CurrentKeybind = setting.Value,
					HoldToInteract = false,
					Ext = true,
					CallOnChange = true,
					Callback = function(Value)
						updateSetting(categoryName, settingName, Value)
					end,
				})
			end
		end
	end

	settingsCreated = true
	loadSettings()
	saveSettings()
end

local function fadeOutKeyUI(KeyMain)
	rfTween(KeyMain, {BackgroundTransparency = 1}, "Emphasis")
	rfTween(KeyMain, {Size = UDim2.new(0, 467, 0, 175)}, "Emphasis")
	rfTween(KeyMain.Shadow.Image, {ImageTransparency = 1}, "Emphasis")
	rfTween(KeyMain.Title, {TextTransparency = 1}, "Emphasis")
	rfTween(KeyMain.Subtitle, {TextTransparency = 1}, "Emphasis")
	rfTween(KeyMain.KeyNote, {TextTransparency = 1}, "Emphasis")
	rfTween(KeyMain.Input, {BackgroundTransparency = 1}, "Emphasis")
	rfTween(KeyMain.Input.UIStroke, {Transparency = 1}, "Emphasis")
	rfTween(KeyMain.Input.InputBox, {TextTransparency = 1}, "Emphasis")
	rfTween(KeyMain.NoteTitle, {TextTransparency = 1}, "Emphasis")
	rfTween(KeyMain.NoteMessage, {TextTransparency = 1}, "Emphasis")
	rfTween(KeyMain.Hide, {ImageTransparency = 1}, "Emphasis")
end

function RayfieldLibrary:CreateWindow(Settings)
	if Rayfield:FindFirstChild('Loading') then
		if getgenv and not getgenv().rayfieldCached then
			Rayfield.Enabled = true
			Rayfield.Loading.Visible = true

			task.wait(1.4)
			Rayfield.Loading.Visible = false
		end
	end

	if getgenv then getgenv().rayfieldCached = true end

	activeWindowSettings = Settings
	currentWindowTabRegistry = {}
	table.clear(commandRegistry)
	if Settings.PerformanceFX == "Low" or Settings.PerformanceFX == "Medium" or Settings.PerformanceFX == "Ultra" then
		performanceTier = Settings.PerformanceFX
	else
		local okpf, vpf = pcall(function()
			if _getgenv then
				return _getgenv().RAYFIELD_PERFORMANCE_FX
			end
		end)
		if okpf and (vpf == "Low" or vpf == "Medium" or vpf == "Ultra") then
			performanceTier = vpf
		end
	end

	if not correctBuild and not Settings.DisableBuildWarnings then
		task.delay(3, 
			function() 
				RayfieldLibrary:Notify({Title = 'Build Mismatch', Content = 'Rayfield may encounter issues as you are running an incompatible interface version ('.. ((Rayfield:FindFirstChild('Build') and Rayfield.Build.Value) or 'No Build') ..').\n\nThis version of Rayfield is intended for interface build '..InterfaceBuild..'.\n\nTry rejoining and then run the script twice.', Image = 4335487866, Duration = 15})		
			end)
	end

	if Settings.ToggleUIKeybind then -- Can either be a string or an Enum.KeyCode
		local keybind = Settings.ToggleUIKeybind
		if type(keybind) == "string" then
			keybind = string.upper(keybind)
			assert(pcall(function()
				return Enum.KeyCode[keybind]
			end), "ToggleUIKeybind must be a valid KeyCode")
			overrideSetting("General", "rayfieldOpen", keybind)
		elseif typeof(keybind) == "EnumItem" then
			assert(keybind.EnumType == Enum.KeyCode, "ToggleUIKeybind must be a KeyCode enum")
			overrideSetting("General", "rayfieldOpen", keybind.Name)
		else
			error("ToggleUIKeybind must be a string or KeyCode enum")
		end
	end

	ensureFolder(RayfieldFolder)

	local Passthrough = false
	Topbar.Title.Text = Settings.Name
	if DesignTokensMod and DesignTokensMod.ApplyTypographyRole then
		DesignTokensMod.ApplyTypographyRole(Topbar.Title, "Title", SelectedTheme.TextColor)
	end

	Main.Size = UDim2.new(0, 420, 0, 100)
	Main.Visible = true
	Main.BackgroundTransparency = 1
	if Main:FindFirstChild('Notice') then Main.Notice.Visible = false end
	Main.Shadow.Image.ImageTransparency = 1

	LoadingFrame.Title.TextTransparency = 1
	LoadingFrame.Subtitle.TextTransparency = 1

	if Settings.ShowText then
		MPrompt.Title.Text = 'Show '..Settings.ShowText
	end

	LoadingFrame.Version.TextTransparency = 1
	LoadingFrame.Title.Text = Settings.LoadingTitle or "Rayfield"
	LoadingFrame.Subtitle.Text = Settings.LoadingSubtitle or "Interface Suite"
	if DesignTokensMod and DesignTokensMod.ApplyTypographyRole then
		DesignTokensMod.ApplyTypographyRole(LoadingFrame.Title, "Title", SelectedTheme.TextColor)
		DesignTokensMod.ApplyTypographyRole(LoadingFrame.Subtitle, "Subtitle", SelectedTheme.TextColor)
		if LoadingFrame:FindFirstChild("Version") then
			DesignTokensMod.ApplyTypographyRole(LoadingFrame.Version, "Caption", SelectedTheme.TextColor)
		end
	end

	if Settings.LoadingTitle ~= "Rayfield Interface Suite" then
		LoadingFrame.Version.Text = "Rayfield UI"
	end

	if Settings.Icon and Settings.Icon ~= 0 and Topbar:FindFirstChild('Icon') then
		Topbar.Icon.Visible = true
		Topbar.Title.Position = UDim2.new(0, 47, 0.5, 0)

		if Settings.Icon then
			local img, rectOffset, rectSize = resolveIcon(Settings.Icon)
			Topbar.Icon.Image = img
			if rectOffset then Topbar.Icon.ImageRectOffset = rectOffset end
			if rectSize then Topbar.Icon.ImageRectSize = rectSize end
		else
			Topbar.Icon.Image = ""
		end
	end

	if dragBar then
		dragBar.Visible = false
		dragBarCosmetic.BackgroundTransparency = 1
		dragBar.Visible = true
	end

	if Settings.Theme then
		local success, result = pcall(ChangeTheme, Settings.Theme)
		if not success then
			local success, result2 = pcall(ChangeTheme, 'Default')
			if not success then
				warn('CRITICAL ERROR - NO DEFAULT THEME')
				print(result2)
			end
			warn('issue rendering theme. no theme on file')
			print(result)
		end
	end

	Topbar.Visible = false
	Elements.Visible = false
	LoadingFrame.Visible = true

	if not Settings.DisableRayfieldPrompts then
		task.spawn(function()
			while not rayfieldDestroyed do
				task.wait(math.random(180, 600))
				if rayfieldDestroyed then break end
				RayfieldLibrary:Notify({
					Title = "Rayfield Interface",
					Content = "Enjoying this UI library? Find it at sirius.menu/discord",
					Duration = 7,
					Image = 4370033185,
				})
			end
		end)
	end

	pcall(function()
		if not Settings.ConfigurationSaving.FileName then
			Settings.ConfigurationSaving.FileName = tostring(game.PlaceId)
		end

		if Settings.ConfigurationSaving.Enabled == nil then
			Settings.ConfigurationSaving.Enabled = false
		end

		CFileName = Settings.ConfigurationSaving.FileName
		ConfigurationFolder = Settings.ConfigurationSaving.FolderName or ConfigurationFolder
		CEnabled = Settings.ConfigurationSaving.Enabled

		if Settings.ConfigurationSaving.Enabled then
			ensureFolder(ConfigurationFolder)
		end
	end)


	makeDraggable(Main, Topbar, false, {dragOffset, dragOffsetMobile})
	if dragBar then dragBar.Position = useMobileSizing and UDim2.new(0.5, 0, 0.5, dragOffsetMobile) or UDim2.new(0.5, 0, 0.5, dragOffset) makeDraggable(Main, dragInteract, true, {dragOffset, dragOffsetMobile}) end

	for _, TabButton in ipairs(TabList:GetChildren()) do
		if TabButton.ClassName == "Frame" and TabButton.Name ~= "Placeholder" then
			TabButton.BackgroundTransparency = 1
			TabButton.Title.TextTransparency = 1
			TabButton.Image.ImageTransparency = 1
			TabButton.UIStroke.Transparency = 1
		end
	end

	if Settings.Discord and Settings.Discord.Enabled and not useStudio and not secureMode then
		ensureFolder(RayfieldFolder.."/Discord Invites")

		if not callSafely(isfile, RayfieldFolder.."/Discord Invites".."/"..Settings.Discord.Invite..ConfigurationExtension) then
			if requestFunc then
				pcall(function()
					requestFunc({
						Url = 'http://127.0.0.1:6463/rpc?v=1',
						Method = 'POST',
						Headers = {
							['Content-Type'] = 'application/json',
							Origin = 'https://discord.com'
						},
						Body = HttpService:JSONEncode({
							cmd = 'INVITE_BROWSER',
							nonce = HttpService:GenerateGUID(false),
							args = {code = Settings.Discord.Invite}
						})
					})
				end)
			end

			if Settings.Discord.RememberJoins then -- We do logic this way so if the developer changes this setting, the user still won't be prompted, only new users
				callSafely(writefile, RayfieldFolder.."/Discord Invites".."/"..Settings.Discord.Invite..ConfigurationExtension,"Rayfield RememberJoins is true for this invite, this invite will not ask you to join again")
			end
		end
	end

	if (Settings.KeySystem) then
		if not Settings.KeySettings then
			Passthrough = true
			return
		end

		ensureFolder(RayfieldFolder.."/Key System")

		if typeof(Settings.KeySettings.Key) == "string" then Settings.KeySettings.Key = {Settings.KeySettings.Key} end

		if Settings.KeySettings.GrabKeyFromSite then
			for i, Key in ipairs(Settings.KeySettings.Key) do
				local Success, Response = pcall(function()
					Settings.KeySettings.Key[i] = tostring(game:HttpGet(Key):gsub("[\n\r]", " "))
					Settings.KeySettings.Key[i] = string.gsub(Settings.KeySettings.Key[i], " ", "")
				end)
				if not Success then
					print("Rayfield | "..Key.." Error " ..tostring(Response))
					warn('Check docs.sirius.menu for help with Rayfield specific development.')
				end
			end
		end

		if not Settings.KeySettings.FileName then
			Settings.KeySettings.FileName = "No file name specified"
		end

		if callSafely(isfile, RayfieldFolder.."/Key System".."/"..Settings.KeySettings.FileName..ConfigurationExtension) then
			for _, MKey in ipairs(Settings.KeySettings.Key) do
				local savedKeys = callSafely(readfile, RayfieldFolder.."/Key System".."/"..Settings.KeySettings.FileName..ConfigurationExtension)
				if savedKeys and string.find(savedKeys, MKey) then
					Passthrough = true
				end
			end
		end

		if not Passthrough and secureMode then
			warn("Rayfield | Secure Mode: Key system requires a valid saved key. The key UI cannot be shown as it requires loading detectable assets.")
			Rayfield.Enabled = false
			return RayfieldLibrary
		end

		if not Passthrough then
			local AttemptsRemaining = Settings.KeySettings.MaxAttempts or 5
			Rayfield.Enabled = false
			local KeyUI = nil
			if useStudio and script and script.Parent and script.Parent:FindFirstChild('Key') then
				KeyUI = script.Parent:FindFirstChild('Key')
			else
				KeyUI = game:GetObjects("rbxassetid://11380036235")[1]
			end

			KeyUI.Enabled = true

			if gethui then
				KeyUI.Parent = gethui()
			elseif syn and syn.protect_gui then 
				syn.protect_gui(KeyUI)
				KeyUI.Parent = CoreGui
			elseif not useStudio and CoreGui:FindFirstChild("RobloxGui") then
				KeyUI.Parent = CoreGui:FindFirstChild("RobloxGui")
			elseif not useStudio then
				KeyUI.Parent = CoreGui
			end

			if gethui then
				for _, Interface in ipairs(gethui():GetChildren()) do
					if Interface.Name == KeyUI.Name and Interface ~= KeyUI then
						Interface.Enabled = false
						Interface.Name = "KeyUI-Old"
					end
				end
			elseif not useStudio then
				for _, Interface in ipairs(CoreGui:GetChildren()) do
					if Interface.Name == KeyUI.Name and Interface ~= KeyUI then
						Interface.Enabled = false
						Interface.Name = "KeyUI-Old"
					end
				end
			end

			local KeyMain = KeyUI.Main
			KeyMain.Title.Text = Settings.KeySettings.Title or Settings.Name
			KeyMain.Subtitle.Text = Settings.KeySettings.Subtitle or "Key System"
			KeyMain.NoteMessage.Text = Settings.KeySettings.Note or "No instructions"

			KeyMain.Size = UDim2.new(0, 467, 0, 175)
			KeyMain.BackgroundTransparency = 1
			KeyMain.Shadow.Image.ImageTransparency = 1
			KeyMain.Title.TextTransparency = 1
			KeyMain.Subtitle.TextTransparency = 1
			KeyMain.KeyNote.TextTransparency = 1
			KeyMain.Input.BackgroundTransparency = 1
			KeyMain.Input.UIStroke.Transparency = 1
			KeyMain.Input.InputBox.TextTransparency = 1
			KeyMain.NoteTitle.TextTransparency = 1
			KeyMain.NoteMessage.TextTransparency = 1
			KeyMain.Hide.ImageTransparency = 1

			rfTween(KeyMain, {BackgroundTransparency = 0}, "Emphasis")
			rfTween(KeyMain, {Size = UDim2.new(0, 500, 0, 187)}, "Emphasis")
			rfTween(KeyMain.Shadow.Image, {ImageTransparency = 0.5}, "Emphasis")
			task.wait(0.05)
			rfTween(KeyMain.Title, {TextTransparency = 0}, "Emphasis")
			rfTween(KeyMain.Subtitle, {TextTransparency = 0}, "Emphasis")
			task.wait(0.05)
			rfTween(KeyMain.KeyNote, {TextTransparency = 0}, "Emphasis")
			rfTween(KeyMain.Input, {BackgroundTransparency = 0}, "Emphasis")
			rfTween(KeyMain.Input.UIStroke, {Transparency = 0}, "Emphasis")
			rfTween(KeyMain.Input.InputBox, {TextTransparency = 0}, "Emphasis")
			task.wait(0.05)
			rfTween(KeyMain.NoteTitle, {TextTransparency = 0}, "Emphasis")
			rfTween(KeyMain.NoteMessage, {TextTransparency = 0}, "Emphasis")
			task.wait(0.15)
			rfTween(KeyMain.Hide, {ImageTransparency = 0.3}, "Emphasis")


			KeyUI.Main.Input.InputBox.FocusLost:Connect(function()
				if #KeyUI.Main.Input.InputBox.Text == 0 then return end
				local KeyFound = false
				local FoundKey = ''
				for _, MKey in ipairs(Settings.KeySettings.Key) do
					--if string.find(KeyMain.Input.InputBox.Text, MKey) then
					--	KeyFound = true
					--	FoundKey = MKey
					--end


					-- stricter key check
					if KeyMain.Input.InputBox.Text == MKey then
						KeyFound = true
						FoundKey = MKey
					end
				end
				if KeyFound then
					fadeOutKeyUI(KeyMain)
					task.wait(0.51)
					Passthrough = true
					KeyMain.Visible = false
					if Settings.KeySettings.SaveKey then
						callSafely(writefile, RayfieldFolder.."/Key System".."/"..Settings.KeySettings.FileName..ConfigurationExtension, FoundKey)
						RayfieldLibrary:Notify({Title = "Key System", Content = "The key for this script has been saved successfully.", Image = 3605522284})
					end
				else
					if AttemptsRemaining == 0 then
						fadeOutKeyUI(KeyMain)
						task.wait(0.45)
						Players.LocalPlayer:Kick("No Attempts Remaining")
						game:Shutdown()
					end
					KeyMain.Input.InputBox.Text = ""
					AttemptsRemaining = AttemptsRemaining - 1
					rfTween(KeyMain, {Size = UDim2.new(0, 467, 0, 175)}, "Emphasis")
					rfTween(KeyMain, {Position = UDim2.new(0.495,0,0.5,0)}, "Elastic")
					task.wait(0.1)
					rfTween(KeyMain, {Position = UDim2.new(0.505,0,0.5,0)}, "Elastic")
					task.wait(0.1)
					rfTween(KeyMain, {Position = UDim2.new(0.5,0,0.5,0)}, "Emphasis")
					rfTween(KeyMain, {Size = UDim2.new(0, 500, 0, 187)}, "Emphasis")
				end
			end)

			KeyMain.Hide.MouseButton1Click:Connect(function()
				fadeOutKeyUI(KeyMain)
				task.wait(0.51)
				Passthrough = true
				RayfieldLibrary:Destroy()
				KeyUI:Destroy()
			end)
		else
			Passthrough = true
		end
	end
	if Settings.KeySystem then
		repeat task.wait() until Passthrough
		if rayfieldDestroyed then return end
	end

	Notifications.Template.Visible = false
	Notifications.Visible = true
	Rayfield.Enabled = true

	task.wait(0.5)
	rfTween(Main, {BackgroundTransparency = 0}, "Emphasis")
	rfTween(Main.Shadow.Image, {ImageTransparency = 0.6}, "Emphasis")
	task.wait(0.1)
	rfTween(LoadingFrame.Title, {TextTransparency = 0}, "Emphasis")
	task.wait(0.05)
	rfTween(LoadingFrame.Subtitle, {TextTransparency = 0}, "Emphasis")
	task.wait(0.05)
	rfTween(LoadingFrame.Version, {TextTransparency = 0}, "Emphasis")


	Elements.Template.LayoutOrder = 100000
	Elements.Template.Visible = false

	Elements.UIPageLayout.FillDirection = Enum.FillDirection.Horizontal
	Elements.UIPageLayout.ScrollWheelInputEnabled = false
	Elements.UIPageLayout.GamepadInputEnabled = false
	Elements.UIPageLayout.TouchInputEnabled = false
	TabList.Template.Visible = false

	-- Tab
	local FirstTab = false
	local Window = {}
	function Window:CreateTab(Name, Image, Ext)
		local SDone = false
		local TabButton = TabList.Template:Clone()
		TabButton.Name = Name
		TabButton.Title.Text = Name
		TabButton.Parent = TabList
		TabButton.Title.TextWrapped = false
		TabButton.Size = UDim2.new(0, TabButton.Title.TextBounds.X + 30, 0, 30)

		if Image and Image ~= 0 then
			local img, rectOffset, rectSize = resolveIcon(Image)
			TabButton.Image.Image = img
			if rectOffset then TabButton.Image.ImageRectOffset = rectOffset end
			if rectSize then TabButton.Image.ImageRectSize = rectSize end

			TabButton.Title.AnchorPoint = Vector2.new(0, 0.5)
			TabButton.Title.Position = UDim2.new(0, 37, 0.5, 0)
			TabButton.Image.Visible = true
			TabButton.Title.TextXAlignment = Enum.TextXAlignment.Left
			TabButton.Size = UDim2.new(0, TabButton.Title.TextBounds.X + 52, 0, 30)
		end



		TabButton.BackgroundTransparency = 1
		TabButton.Title.TextTransparency = 1
		TabButton.Image.ImageTransparency = 1
		TabButton.UIStroke.Transparency = 1

		TabButton.Visible = not Ext or false

		-- Create Elements Page
		local TabPage = Elements.Template:Clone()
		TabPage.Name = Name
		TabPage.Visible = true

		TabPage.LayoutOrder = Ext and 10000 or #Elements:GetChildren()

		for _, TemplateElement in ipairs(TabPage:GetChildren()) do
			if TemplateElement.ClassName == "Frame" and TemplateElement.Name ~= "Placeholder" then
				TemplateElement:Destroy()
			end
		end

		TabPage.Parent = Elements
		if not FirstTab and not Ext then
			Elements.UIPageLayout.Animated = false
			Elements.UIPageLayout:JumpTo(TabPage)
			Elements.UIPageLayout.Animated = true
		end

		TabButton.UIStroke.Color = SelectedTheme.TabStroke

		if Elements.UIPageLayout.CurrentPage == TabPage then
			TabButton.BackgroundColor3 = SelectedTheme.TabBackgroundSelected
			TabButton.Image.ImageColor3 = SelectedTheme.SelectedTabTextColor
			TabButton.Title.TextColor3 = SelectedTheme.SelectedTabTextColor
		else
			TabButton.BackgroundColor3 = SelectedTheme.TabBackground
			TabButton.Image.ImageColor3 = SelectedTheme.TabTextColor
			TabButton.Title.TextColor3 = SelectedTheme.TabTextColor
		end


		-- Animate
		task.wait(0.1)
		if FirstTab or Ext then
			TabButton.BackgroundColor3 = SelectedTheme.TabBackground
			TabButton.Image.ImageColor3 = SelectedTheme.TabTextColor
			TabButton.Title.TextColor3 = SelectedTheme.TabTextColor
			rfTween(TabButton, {BackgroundTransparency = 0.7}, "Emphasis")
			rfTween(TabButton.Title, {TextTransparency = 0.2}, "Emphasis")
			rfTween(TabButton.Image, {ImageTransparency = 0.2}, "Emphasis")
			rfTween(TabButton.UIStroke, {Transparency = 0.5}, "Emphasis")
		elseif not Ext then
			FirstTab = Name
			TabButton.BackgroundColor3 = SelectedTheme.TabBackgroundSelected
			TabButton.Image.ImageColor3 = SelectedTheme.SelectedTabTextColor
			TabButton.Title.TextColor3 = SelectedTheme.SelectedTabTextColor
			rfTween(TabButton.Image, {ImageTransparency = 0}, "Emphasis")
			rfTween(TabButton, {BackgroundTransparency = 0}, "Emphasis")
			rfTween(TabButton.Title, {TextTransparency = 0}, "Emphasis")
		end


		local function selectThisTab()
			if Minimised then return end
			rfTween(TabButton, {BackgroundTransparency = 0}, "Emphasis")
			rfTween(TabButton.UIStroke, {Transparency = 1}, "Emphasis")
			rfTween(TabButton.Title, {TextTransparency = 0}, "Emphasis")
			rfTween(TabButton.Image, {ImageTransparency = 0}, "Emphasis")
			rfTween(TabButton, {BackgroundColor3 = SelectedTheme.TabBackgroundSelected}, "Emphasis")
			rfTween(TabButton.Title, {TextColor3 = SelectedTheme.SelectedTabTextColor}, "Emphasis")
			rfTween(TabButton.Image, {ImageColor3 = SelectedTheme.SelectedTabTextColor}, "Emphasis")

			for _, OtherTabButton in ipairs(TabList:GetChildren()) do
				if OtherTabButton.Name ~= "Template" and OtherTabButton.ClassName == "Frame" and OtherTabButton ~= TabButton and OtherTabButton.Name ~= "Placeholder" then
					rfTween(OtherTabButton, {BackgroundColor3 = SelectedTheme.TabBackground}, "Emphasis")
					rfTween(OtherTabButton.Title, {TextColor3 = SelectedTheme.TabTextColor}, "Emphasis")
					rfTween(OtherTabButton.Image, {ImageColor3 = SelectedTheme.TabTextColor}, "Emphasis")
					rfTween(OtherTabButton, {BackgroundTransparency = 0.7}, "Emphasis")
					rfTween(OtherTabButton.Title, {TextTransparency = 0.2}, "Emphasis")
					rfTween(OtherTabButton.Image, {ImageTransparency = 0.2}, "Emphasis")
					rfTween(OtherTabButton.UIStroke, {Transparency = 0.5}, "Emphasis")
				end
			end

			if Elements.UIPageLayout.CurrentPage ~= TabPage then
				Elements.UIPageLayout:JumpTo(TabPage)
			end
		end

		TabButton.Interact.MouseButton1Click:Connect(selectThisTab)

		if not Ext then
			table.insert(currentWindowTabRegistry, { Name = Name, Activate = selectThisTab })
		end

		local Tab = {}

		-- Button
		function Tab:CreateButton(ButtonSettings)
			local ButtonValue = {}

			local Button = Elements.Template.Button:Clone()
			Button.Name = ButtonSettings.Name
			Button.Title.Text = ButtonSettings.Name
			Button.Visible = true
			Button.Parent = TabPage

			Button.BackgroundTransparency = 1
			Button.UIStroke.Transparency = 1
			Button.Title.TextTransparency = 1

			rfTween(Button, { BackgroundTransparency = 0 }, "Smooth")
			rfTween(Button.UIStroke, { Transparency = 0 }, "Smooth")
			rfTween(Button.Title, { TextTransparency = 0 }, "Smooth")


			Button.Interact.MouseButton1Click:Connect(function()
				local Success, Response = pcall(ButtonSettings.Callback)
				-- Prevents animation from trying to play if the button's callback called RayfieldLibrary:Destroy()
				if rayfieldDestroyed then
					return
				end
				if not Success then
					rfTween(Button, { BackgroundColor3 = Color3.fromRGB(85, 0, 0) }, "Smooth")
					rfTween(Button.ElementIndicator, { TextTransparency = 1 }, "Smooth")
					rfTween(Button.UIStroke, { Transparency = 1 }, "Smooth")
					Button.Title.Text = "Callback Error"
					print("Rayfield | "..ButtonSettings.Name.." Callback Error " ..tostring(Response))
					warn('Check docs.sirius.menu for help with Rayfield specific development.')
					task.wait(0.5)
					Button.Title.Text = ButtonSettings.Name
					rfTween(Button, { BackgroundColor3 = SelectedTheme.ElementBackground }, "Smooth")
					rfTween(Button.ElementIndicator, { TextTransparency = 0.9 }, "Smooth")
					rfTween(Button.UIStroke, { Transparency = 0 }, "Smooth")
				else
					if not ButtonSettings.Ext then
						SaveConfiguration(ButtonSettings.Name..'\n')
					end
					rfTween(Button, { BackgroundColor3 = SelectedTheme.ElementBackgroundHover }, "Fast")
					rfTween(Button.ElementIndicator, { TextTransparency = 1 }, "Fast")
					rfTween(Button.UIStroke, { Transparency = 1 }, "Fast")
					task.wait(0.2)
					rfTween(Button, { BackgroundColor3 = SelectedTheme.ElementBackground }, "Smooth")
					rfTween(Button.ElementIndicator, { TextTransparency = 0.9 }, "Smooth")
					rfTween(Button.UIStroke, { Transparency = 0 }, "Smooth")
				end
			end)

			Button.MouseEnter:Connect(function()
				rfTween(Button, { BackgroundColor3 = SelectedTheme.ElementBackgroundHover }, "Fast")
				rfTween(Button.ElementIndicator, { TextTransparency = 0.7 }, "Fast")
			end)

			Button.MouseLeave:Connect(function()
				rfTween(Button, { BackgroundColor3 = SelectedTheme.ElementBackground }, "Fast")
				rfTween(Button.ElementIndicator, { TextTransparency = 0.9 }, "Fast")
			end)

			function ButtonValue:Set(NewButton)
				Button.Title.Text = NewButton
				Button.Name = NewButton
			end

			return ButtonValue
		end

		-- ColorPicker
		function Tab:CreateColorPicker(ColorPickerSettings) -- by Throit
			ColorPickerSettings.Type = "ColorPicker"
			local ColorPicker = Elements.Template.ColorPicker:Clone()
			local Background = ColorPicker.CPBackground
			local Display = Background.Display
			local Main = Background.MainCP
			local Slider = ColorPicker.ColorSlider
			ColorPicker.ClipsDescendants = true
			ColorPicker.Name = ColorPickerSettings.Name
			ColorPicker.Title.Text = ColorPickerSettings.Name
			ColorPicker.Visible = true
			ColorPicker.Parent = TabPage
			ColorPicker.Size = UDim2.new(1, -10, 0, 45)
			Background.Size = UDim2.new(0, 39, 0, 22)
			Display.BackgroundTransparency = 0
			Main.MainPoint.ImageTransparency = 1
			ColorPicker.Interact.Size = UDim2.new(1, 0, 1, 0)
			ColorPicker.Interact.Position = UDim2.new(0.5, 0, 0.5, 0)
			ColorPicker.RGB.Position = UDim2.new(0, 17, 0, 70)
			ColorPicker.HexInput.Position = UDim2.new(0, 17, 0, 90)
			Main.ImageTransparency = 1
			Background.BackgroundTransparency = 1

			for _, rgbinput in ipairs(ColorPicker.RGB:GetChildren()) do
				if rgbinput:IsA("Frame") then
					rgbinput.BackgroundColor3 = SelectedTheme.InputBackground
					rgbinput.UIStroke.Color = SelectedTheme.InputStroke
				end
			end

			ColorPicker.HexInput.BackgroundColor3 = SelectedTheme.InputBackground
			ColorPicker.HexInput.UIStroke.Color = SelectedTheme.InputStroke

			local opened = false 
			local mouse = Players.LocalPlayer:GetMouse()
			local mainDragging = false 
			local sliderDragging = false 
			ColorPicker.Interact.MouseButton1Down:Connect(function()
				task.spawn(function()
					rfTween(ColorPicker, { BackgroundColor3 = SelectedTheme.ElementBackgroundHover }, "Fast")
					rfTween(ColorPicker.UIStroke, { Transparency = 1 }, "Fast")
					task.wait(0.2)
					rfTween(ColorPicker, { BackgroundColor3 = SelectedTheme.ElementBackground }, "Fast")
					rfTween(ColorPicker.UIStroke, { Transparency = 0 }, "Fast")
				end)

				if not opened then
					opened = true 
					rfTween(Background, { Size = UDim2.new(0, 18, 0, 15) }, "Smooth")
					task.wait(0.1)
					rfTween(ColorPicker, { Size = UDim2.new(1, -10, 0, 120) }, "Smooth")
					rfTween(Background, { Size = UDim2.new(0, 173, 0, 86) }, "Smooth")
					rfTween(Display, { BackgroundTransparency = 1 }, "Smooth")
					rfTween(ColorPicker.Interact, { Position = UDim2.new(0.289, 0, 0.5, 0) }, "Smooth")
					rfTween(ColorPicker.RGB, { Position = UDim2.new(0, 17, 0, 40) }, "Smooth")
					rfTween(ColorPicker.HexInput, { Position = UDim2.new(0, 17, 0, 73) }, "Smooth")
					rfTween(ColorPicker.Interact, { Size = UDim2.new(0.574, 0, 1, 0) }, "Smooth")
					rfTween(Main.MainPoint, { ImageTransparency = 0 }, "Fast")
					rfTween(Main, { ImageTransparency = SelectedTheme ~= RayfieldLibrary.Theme.Default and 0.25 or 0.1 }, "Fast")
					rfTween(Background, { BackgroundTransparency = 0 }, "Smooth")
				else
					opened = false
					rfTween(ColorPicker, { Size = UDim2.new(1, -10, 0, 45) }, "Smooth")
					rfTween(Background, { Size = UDim2.new(0, 39, 0, 22) }, "Smooth")
					rfTween(ColorPicker.Interact, { Size = UDim2.new(1, 0, 1, 0) }, "Smooth")
					rfTween(ColorPicker.Interact, { Position = UDim2.new(0.5, 0, 0.5, 0) }, "Smooth")
					rfTween(ColorPicker.RGB, { Position = UDim2.new(0, 17, 0, 70) }, "Smooth")
					rfTween(ColorPicker.HexInput, { Position = UDim2.new(0, 17, 0, 90) }, "Smooth")
					rfTween(Display, { BackgroundTransparency = 0 }, "Smooth")
					rfTween(Main.MainPoint, { ImageTransparency = 1 }, "Fast")
					rfTween(Main, { ImageTransparency = 1 }, "Fast")
					rfTween(Background, { BackgroundTransparency = 1 }, "Smooth")
				end

			end)

			local colorPickerInputConnection = UserInputService.InputEnded:Connect(function(input, gameProcessed) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					mainDragging = false
					sliderDragging = false
				end end)
			Main.MouseButton1Down:Connect(function()
				if opened then
					mainDragging = true 
				end
			end)
			Main.MainPoint.MouseButton1Down:Connect(function()
				if opened then
					mainDragging = true 
				end
			end)
			Slider.MouseButton1Down:Connect(function()
				sliderDragging = true 
			end)
			Slider.SliderPoint.MouseButton1Down:Connect(function()
				sliderDragging = true 
			end)
			local h,s,v = ColorPickerSettings.Color:ToHSV()
			local color = Color3.fromHSV(h,s,v) 
			local hex = string.format("#%02X%02X%02X",color.R*0xFF,color.G*0xFF,color.B*0xFF)
			ColorPicker.HexInput.InputBox.Text = hex
			local function setDisplay()
				--Main
				Main.MainPoint.Position = UDim2.new(s,-Main.MainPoint.AbsoluteSize.X/2,1-v,-Main.MainPoint.AbsoluteSize.Y/2)
				Main.MainPoint.ImageColor3 = Color3.fromHSV(h,s,v)
				Background.BackgroundColor3 = Color3.fromHSV(h,1,1)
				Display.BackgroundColor3 = Color3.fromHSV(h,s,v)
				--Slider 
				local x = h * Slider.AbsoluteSize.X
				Slider.SliderPoint.Position = UDim2.new(0,x-Slider.SliderPoint.AbsoluteSize.X/2,0.5,0)
				Slider.SliderPoint.ImageColor3 = Color3.fromHSV(h,1,1)
				local color = Color3.fromHSV(h,s,v) 
				local r,g,b = math.floor((color.R*255)+0.5),math.floor((color.G*255)+0.5),math.floor((color.B*255)+0.5)
				ColorPicker.RGB.RInput.InputBox.Text = tostring(r)
				ColorPicker.RGB.GInput.InputBox.Text = tostring(g)
				ColorPicker.RGB.BInput.InputBox.Text = tostring(b)
				hex = string.format("#%02X%02X%02X",color.R*0xFF,color.G*0xFF,color.B*0xFF)
				ColorPicker.HexInput.InputBox.Text = hex
			end
			setDisplay()
			ColorPicker.HexInput.InputBox.FocusLost:Connect(function()
				if not pcall(function()
						local r, g, b = string.match(ColorPicker.HexInput.InputBox.Text, "^#?(%w%w)(%w%w)(%w%w)$")
						local rgbColor = Color3.fromRGB(tonumber(r, 16),tonumber(g, 16), tonumber(b, 16))
						h,s,v = rgbColor:ToHSV()
						hex = ColorPicker.HexInput.InputBox.Text
						setDisplay()
						ColorPickerSettings.Color = rgbColor
					end) 
				then 
					ColorPicker.HexInput.InputBox.Text = hex 
				end
				pcall(function()ColorPickerSettings.Callback(Color3.fromHSV(h,s,v))end)
				local r,g,b = math.floor((h*255)+0.5),math.floor((s*255)+0.5),math.floor((v*255)+0.5)
				ColorPickerSettings.Color = Color3.fromRGB(r,g,b)
				if not ColorPickerSettings.Ext then
					SaveConfiguration()
				end
			end)
			--RGB
			local function rgbBoxes(box,toChange)
				local value = tonumber(box.Text) 
				local color = Color3.fromHSV(h,s,v) 
				local oldR,oldG,oldB = math.floor((color.R*255)+0.5),math.floor((color.G*255)+0.5),math.floor((color.B*255)+0.5)
				local save 
				if toChange == "R" then save = oldR;oldR = value elseif toChange == "G" then save = oldG;oldG = value else save = oldB;oldB = value end
				if value then 
					value = math.clamp(value,0,255)
					h,s,v = Color3.fromRGB(oldR,oldG,oldB):ToHSV()

					setDisplay()
				else 
					box.Text = tostring(save)
				end
				local r,g,b = math.floor((h*255)+0.5),math.floor((s*255)+0.5),math.floor((v*255)+0.5)
				ColorPickerSettings.Color = Color3.fromRGB(r,g,b)
				if not ColorPickerSettings.Ext then
					SaveConfiguration(ColorPickerSettings.Flag..'\n'..tostring(ColorPickerSettings.Color))
				end
			end
			ColorPicker.RGB.RInput.InputBox.FocusLost:connect(function()
				rgbBoxes(ColorPicker.RGB.RInput.InputBox,"R")
				pcall(function()ColorPickerSettings.Callback(Color3.fromHSV(h,s,v))end)
			end)
			ColorPicker.RGB.GInput.InputBox.FocusLost:connect(function()
				rgbBoxes(ColorPicker.RGB.GInput.InputBox,"G")
				pcall(function()ColorPickerSettings.Callback(Color3.fromHSV(h,s,v))end)
			end)
			ColorPicker.RGB.BInput.InputBox.FocusLost:connect(function()
				rgbBoxes(ColorPicker.RGB.BInput.InputBox,"B")
				pcall(function()ColorPickerSettings.Callback(Color3.fromHSV(h,s,v))end)
			end)

			local colorPickerRenderConnection = RunService.RenderStepped:connect(function()
				if mainDragging then
					local localX = math.clamp(mouse.X-Main.AbsolutePosition.X,0,Main.AbsoluteSize.X)
					local localY = math.clamp(mouse.Y-Main.AbsolutePosition.Y,0,Main.AbsoluteSize.Y)
					Main.MainPoint.Position = UDim2.new(0,localX-Main.MainPoint.AbsoluteSize.X/2,0,localY-Main.MainPoint.AbsoluteSize.Y/2)
					s = localX / Main.AbsoluteSize.X
					v = 1 - (localY / Main.AbsoluteSize.Y)
					Display.BackgroundColor3 = Color3.fromHSV(h,s,v)
					Main.MainPoint.ImageColor3 = Color3.fromHSV(h,s,v)
					Background.BackgroundColor3 = Color3.fromHSV(h,1,1)
					local color = Color3.fromHSV(h,s,v) 
					local r,g,b = math.floor((color.R*255)+0.5),math.floor((color.G*255)+0.5),math.floor((color.B*255)+0.5)
					ColorPicker.RGB.RInput.InputBox.Text = tostring(r)
					ColorPicker.RGB.GInput.InputBox.Text = tostring(g)
					ColorPicker.RGB.BInput.InputBox.Text = tostring(b)
					ColorPicker.HexInput.InputBox.Text = string.format("#%02X%02X%02X",color.R*0xFF,color.G*0xFF,color.B*0xFF)
					pcall(function()ColorPickerSettings.Callback(Color3.fromHSV(h,s,v))end)
					ColorPickerSettings.Color = Color3.fromRGB(r,g,b)
					if not ColorPickerSettings.Ext then
						SaveConfiguration()
					end
				end
				if sliderDragging then 
					local localX = math.clamp(mouse.X-Slider.AbsolutePosition.X,0,Slider.AbsoluteSize.X)
					h = localX / Slider.AbsoluteSize.X
					Display.BackgroundColor3 = Color3.fromHSV(h,s,v)
					Slider.SliderPoint.Position = UDim2.new(0,localX-Slider.SliderPoint.AbsoluteSize.X/2,0.5,0)
					Slider.SliderPoint.ImageColor3 = Color3.fromHSV(h,1,1)
					Background.BackgroundColor3 = Color3.fromHSV(h,1,1)
					Main.MainPoint.ImageColor3 = Color3.fromHSV(h,s,v)
					local color = Color3.fromHSV(h,s,v) 
					local r,g,b = math.floor((color.R*255)+0.5),math.floor((color.G*255)+0.5),math.floor((color.B*255)+0.5)
					ColorPicker.RGB.RInput.InputBox.Text = tostring(r)
					ColorPicker.RGB.GInput.InputBox.Text = tostring(g)
					ColorPicker.RGB.BInput.InputBox.Text = tostring(b)
					ColorPicker.HexInput.InputBox.Text = string.format("#%02X%02X%02X",color.R*0xFF,color.G*0xFF,color.B*0xFF)
					pcall(function()ColorPickerSettings.Callback(Color3.fromHSV(h,s,v))end)
					ColorPickerSettings.Color = Color3.fromRGB(r,g,b)
					if not ColorPickerSettings.Ext then
						SaveConfiguration()
					end
				end
			end)

			ColorPicker.Destroying:Connect(function()
				if colorPickerRenderConnection then
					colorPickerRenderConnection:Disconnect()
				end
				if colorPickerInputConnection then
					colorPickerInputConnection:Disconnect()
				end
			end)

			if Settings.ConfigurationSaving then
				if Settings.ConfigurationSaving.Enabled and ColorPickerSettings.Flag then
					RayfieldLibrary.Flags[ColorPickerSettings.Flag] = ColorPickerSettings
				end
			end

			function ColorPickerSettings:Set(RGBColor)
				ColorPickerSettings.Color = RGBColor
				h,s,v = ColorPickerSettings.Color:ToHSV()
				color = Color3.fromHSV(h,s,v)
				setDisplay()
			end

			ColorPicker.MouseEnter:Connect(function()
				rfTween(ColorPicker, { BackgroundColor3 = SelectedTheme.ElementBackgroundHover }, "Fast")
			end)

			ColorPicker.MouseLeave:Connect(function()
				rfTween(ColorPicker, { BackgroundColor3 = SelectedTheme.ElementBackground }, "Fast")
			end)

			Rayfield.Main:GetPropertyChangedSignal('BackgroundColor3'):Connect(function()
				for _, rgbinput in ipairs(ColorPicker.RGB:GetChildren()) do
					if rgbinput:IsA("Frame") then
						rgbinput.BackgroundColor3 = SelectedTheme.InputBackground
						rgbinput.UIStroke.Color = SelectedTheme.InputStroke
					end
				end

				ColorPicker.HexInput.BackgroundColor3 = SelectedTheme.InputBackground
				ColorPicker.HexInput.UIStroke.Color = SelectedTheme.InputStroke
			end)

			return ColorPickerSettings
		end

		-- Section
		function Tab:CreateSection(SectionName)

			local SectionValue = {}

			if SDone then
				local SectionSpace = Elements.Template.SectionSpacing:Clone()
				SectionSpace.Visible = true
				SectionSpace.Parent = TabPage
			end

			local Section = Elements.Template.SectionTitle:Clone()
			Section.Title.Text = SectionName
			Section.Visible = true
			Section.Parent = TabPage

			Section.Title.TextTransparency = 1
			rfTween(Section.Title, { TextTransparency = 0.4 }, "Smooth")

			function SectionValue:Set(NewSection)
				Section.Title.Text = NewSection
			end

			SDone = true

			return SectionValue
		end

		-- Divider
		function Tab:CreateDivider()
			local DividerValue = {}

			local Divider = Elements.Template.Divider:Clone()
			Divider.Visible = true
			Divider.Parent = TabPage

			Divider.Divider.BackgroundTransparency = 1
			rfTween(Divider.Divider, { BackgroundTransparency = 0.85 }, "Smooth")

			function DividerValue:Set(Value)
				Divider.Visible = Value
			end

			return DividerValue
		end

		-- Label
		function Tab:CreateLabel(LabelText : string, Icon: number, Color : Color3, IgnoreTheme : boolean)
			local LabelValue = {}

			local Label = Elements.Template.Label:Clone()
			Label.Title.Text = LabelText
			Label.Visible = true
			Label.Parent = TabPage

			if DesignTokensMod and DesignTokensMod.ApplyTypographyRole then
				DesignTokensMod.ApplyTypographyRole(Label.Title, "Body", SelectedTheme.TextColor)
			end

			Label.BackgroundColor3 = Color or SelectedTheme.SecondaryElementBackground
			Label.UIStroke.Color = Color or SelectedTheme.SecondaryElementStroke

			if Icon then
				local img, rectOffset, rectSize = resolveIcon(Icon)
				Label.Icon.Image = img
				if rectOffset then Label.Icon.ImageRectOffset = rectOffset end
				if rectSize then Label.Icon.ImageRectSize = rectSize end
			else
				Label.Icon.Image = ""
			end

			if Icon and Label:FindFirstChild('Icon') then
				Label.Title.Position = UDim2.new(0, 45, 0.5, 0)
				Label.Title.Size = UDim2.new(1, -100, 0, 14)
				Label.Icon.Visible = true
			end

			Label.Icon.ImageTransparency = 1
			Label.BackgroundTransparency = 1
			Label.UIStroke.Transparency = 1
			Label.Title.TextTransparency = 1

			rfTween(Label, { BackgroundTransparency = Color and 0.8 or 0 }, "Smooth")
			rfTween(Label.UIStroke, { Transparency = Color and 0.7 or 0 }, "Smooth")
			rfTween(Label.Icon, { ImageTransparency = 0.2 }, "Smooth")
			rfTween(Label.Title, { TextTransparency = Color and 0.2 or 0 }, "Smooth")

			function LabelValue:Set(NewLabel, Icon, Color)
				Label.Title.Text = NewLabel

				if Color then
					Label.BackgroundColor3 = Color or SelectedTheme.SecondaryElementBackground
					Label.UIStroke.Color = Color or SelectedTheme.SecondaryElementStroke
				end

				if Icon and Label:FindFirstChild('Icon') then
					Label.Title.Position = UDim2.new(0, 45, 0.5, 0)
					Label.Title.Size = UDim2.new(1, -100, 0, 14)

					local img, rectOffset, rectSize = resolveIcon(Icon)
					Label.Icon.Image = img
					if rectOffset then Label.Icon.ImageRectOffset = rectOffset end
					if rectSize then Label.Icon.ImageRectSize = rectSize end

					Label.Icon.Visible = true
				end
			end

			Rayfield.Main:GetPropertyChangedSignal('BackgroundColor3'):Connect(function()
				Label.BackgroundColor3 = IgnoreTheme and (Color or Label.BackgroundColor3) or SelectedTheme.SecondaryElementBackground
				Label.UIStroke.Color = IgnoreTheme and (Color or Label.BackgroundColor3) or SelectedTheme.SecondaryElementStroke
			end)

			return LabelValue
		end

		-- Paragraph
		function Tab:CreateParagraph(ParagraphSettings)
			local ParagraphValue = {}

			local Paragraph = Elements.Template.Paragraph:Clone()
			Paragraph.Title.Text = ParagraphSettings.Title
			Paragraph.Content.Text = ParagraphSettings.Content
			Paragraph.Visible = true
			Paragraph.Parent = TabPage

			Paragraph.BackgroundTransparency = 1
			Paragraph.UIStroke.Transparency = 1
			Paragraph.Title.TextTransparency = 1
			Paragraph.Content.TextTransparency = 1

			Paragraph.BackgroundColor3 = SelectedTheme.SecondaryElementBackground
			Paragraph.UIStroke.Color = SelectedTheme.SecondaryElementStroke

			if DesignTokensMod and DesignTokensMod.ApplyTypographyRole then
				DesignTokensMod.ApplyTypographyRole(Paragraph.Title, "Subtitle", SelectedTheme.TextColor)
				local muted = SelectedTheme.MutedText or SelectedTheme.TextColor
				DesignTokensMod.ApplyTypographyRole(Paragraph.Content, "Body", muted)
			end

			rfTween(Paragraph, { BackgroundTransparency = 0 }, "Smooth")
			rfTween(Paragraph.UIStroke, { Transparency = 0 }, "Smooth")
			rfTween(Paragraph.Title, { TextTransparency = 0 }, "Smooth")
			rfTween(Paragraph.Content, { TextTransparency = 0 }, "Smooth")

			function ParagraphValue:Set(NewParagraphSettings)
				Paragraph.Title.Text = NewParagraphSettings.Title
				Paragraph.Content.Text = NewParagraphSettings.Content
			end

			Rayfield.Main:GetPropertyChangedSignal('BackgroundColor3'):Connect(function()
				Paragraph.BackgroundColor3 = SelectedTheme.SecondaryElementBackground
				Paragraph.UIStroke.Color = SelectedTheme.SecondaryElementStroke
			end)

			return ParagraphValue
		end

		-- Input
		function Tab:CreateInput(InputSettings)
			local Input = Elements.Template.Input:Clone()
			Input.Name = InputSettings.Name
			Input.Title.Text = InputSettings.Name
			Input.Visible = true
			Input.Parent = TabPage

			Input.BackgroundTransparency = 1
			Input.UIStroke.Transparency = 1
			Input.Title.TextTransparency = 1

			Input.InputFrame.InputBox.Text = InputSettings.CurrentValue or ''

			Input.InputFrame.BackgroundColor3 = SelectedTheme.InputBackground
			Input.InputFrame.UIStroke.Color = SelectedTheme.InputStroke

			rfTween(Input, { BackgroundTransparency = 0 }, "Smooth")
			rfTween(Input.UIStroke, { Transparency = 0 }, "Smooth")
			rfTween(Input.Title, { TextTransparency = 0 }, "Smooth")

			Input.InputFrame.InputBox.PlaceholderText = InputSettings.PlaceholderText
			Input.InputFrame.Size = UDim2.new(0, Input.InputFrame.InputBox.TextBounds.X + 24, 0, 30)

			Input.InputFrame.InputBox.FocusLost:Connect(function()
				local Success, Response = pcall(function()
					InputSettings.Callback(Input.InputFrame.InputBox.Text)
					InputSettings.CurrentValue = Input.InputFrame.InputBox.Text
				end)

				if not Success then
					rfTween(Input, { BackgroundColor3 = Color3.fromRGB(85, 0, 0) }, "Fast")
					rfTween(Input.UIStroke, { Transparency = 1 }, "Fast")
					Input.Title.Text = "Callback Error"
					print("Rayfield | "..InputSettings.Name.." Callback Error " ..tostring(Response))
					warn('Check docs.sirius.menu for help with Rayfield specific development.')
					task.wait(0.5)
					Input.Title.Text = InputSettings.Name
					rfTween(Input, { BackgroundColor3 = SelectedTheme.ElementBackground }, "Smooth")
					rfTween(Input.UIStroke, { Transparency = 0 }, "Smooth")
				end

				if InputSettings.RemoveTextAfterFocusLost then
					Input.InputFrame.InputBox.Text = ""
				end

				if not InputSettings.Ext then
					SaveConfiguration()
				end
			end)

			Input.MouseEnter:Connect(function()
				rfTween(Input, { BackgroundColor3 = SelectedTheme.ElementBackgroundHover }, "Fast")
			end)

			Input.MouseLeave:Connect(function()
				rfTween(Input, { BackgroundColor3 = SelectedTheme.ElementBackground }, "Fast")
			end)

			Input.InputFrame.InputBox:GetPropertyChangedSignal("Text"):Connect(function()
				rfTween(Input.InputFrame, { Size = UDim2.new(0, Input.InputFrame.InputBox.TextBounds.X + 24, 0, 30) }, "Fast")
			end)

			function InputSettings:Set(text)
				Input.InputFrame.InputBox.Text = text
				InputSettings.CurrentValue = text

				local Success, Response = pcall(function()
					InputSettings.Callback(text)
				end)

				if not InputSettings.Ext then
					SaveConfiguration()
				end
			end

			if Settings.ConfigurationSaving then
				if Settings.ConfigurationSaving.Enabled and InputSettings.Flag then
					RayfieldLibrary.Flags[InputSettings.Flag] = InputSettings
				end
			end

			Rayfield.Main:GetPropertyChangedSignal('BackgroundColor3'):Connect(function()
				Input.InputFrame.BackgroundColor3 = SelectedTheme.InputBackground
				Input.InputFrame.UIStroke.Color = SelectedTheme.InputStroke
			end)

			return InputSettings
		end

		function Tab:CreateSearchBox(BoxSettings)
			BoxSettings = BoxSettings or {}
			local deb = BoxSettings.Debounce or 0.22
			local pendingCancel = nil
			local userCb = BoxSettings.Callback or function() end
			local recentPath = RayfieldFolder .. "/SearchRecent.json"
			BoxSettings.Callback = function(text)
				if pendingCancel then
					task.cancel(pendingCancel)
					pendingCancel = nil
				end
				pendingCancel = task.delay(deb, function()
					pendingCancel = nil
					userCb(text)
					if BoxSettings.SaveRecent and writefile and text ~= "" then
						local list = {}
						local ok, raw = pcall(readfile, recentPath)
						if ok and raw and #raw > 0 then
							pcall(function()
								list = HttpService:JSONDecode(raw) or {}
							end)
						end
						table.insert(list, 1, text)
						while #list > 10 do
							table.remove(list)
						end
						pcall(writefile, recentPath, HttpService:JSONEncode(list))
					end
				end)
			end
			local inp = Tab:CreateInput(BoxSettings)
			local root = TabPage:FindFirstChild(BoxSettings.Name)
			if root and BoxSettings.ClearButton ~= false then
				local inputFrame = root:FindFirstChild("InputFrame")
				local inputBox = inputFrame and inputFrame:FindFirstChild("InputBox")
				if inputFrame and inputBox then
					local clear = Instance.new("TextButton")
					clear.Name = "SearchClear"
					clear.Size = UDim2.new(0, 28, 0, 28)
					clear.Position = UDim2.new(1, -32, 0.5, -14)
					clear.BackgroundTransparency = 1
					clear.Text = "✕"
					clear.TextColor3 = SelectedTheme.PlaceholderColor or SelectedTheme.TextColor
					clear.TextSize = 16
					clear.Font = Enum.Font.GothamBold
					clear.ZIndex = inputFrame.ZIndex + 2
					clear.Parent = inputFrame
					clear.MouseButton1Click:Connect(function()
						inputBox.Text = ""
						inp:Set("")
					end)
					local baseTh = inputFrame:FindFirstChildOfClass("UIStroke")
					inputBox.Focused:Connect(function()
						if baseTh then
							rfTween(baseTh, { Thickness = 2, Transparency = 0.25 }, "Fast")
						end
					end)
					inputBox.FocusLost:Connect(function()
						if baseTh then
							rfTween(baseTh, { Thickness = 1, Transparency = 0 }, "Fast")
						end
					end)
				end
			end
			return inp
		end

		-- Dropdown
		function Tab:CreateDropdown(DropdownSettings)
			local Dropdown = Elements.Template.Dropdown:Clone()
			if string.find(DropdownSettings.Name,"closed") then
				Dropdown.Name = "Dropdown"
			else
				Dropdown.Name = DropdownSettings.Name
			end
			Dropdown.Title.Text = DropdownSettings.Name
			Dropdown.Visible = true
			Dropdown.Parent = TabPage

			Dropdown.List.Visible = false
			if DropdownSettings.CurrentOption then
				if type(DropdownSettings.CurrentOption) == "string" then
					DropdownSettings.CurrentOption = {DropdownSettings.CurrentOption}
				end
				if not DropdownSettings.MultipleOptions and type(DropdownSettings.CurrentOption) == "table" then
					DropdownSettings.CurrentOption = {DropdownSettings.CurrentOption[1]}
				end
			else
				DropdownSettings.CurrentOption = {}
			end

			local function multiHeaderText()
				if not DropdownSettings.MultipleOptions then
					return
				end
				local n = #(DropdownSettings.CurrentOption or {})
				if n == 0 then
					Dropdown.Selected.Text = "None"
				elseif n == 1 then
					Dropdown.Selected.Text = DropdownSettings.CurrentOption[1]
				elseif DropdownSettings.ShowSelectionCount then
					Dropdown.Selected.Text = string.format("%d selecionados", n)
				else
					Dropdown.Selected.Text = "Various"
				end
			end

			if DropdownSettings.MultipleOptions then
				if DropdownSettings.CurrentOption and type(DropdownSettings.CurrentOption) == "table" then
					multiHeaderText()
				else
					DropdownSettings.CurrentOption = {}
					Dropdown.Selected.Text = "None"
				end
			else
				Dropdown.Selected.Text = DropdownSettings.CurrentOption[1] or "None"
			end

			local function isDropdownOptionRow(frame)
				return frame.ClassName == "Frame"
					and frame.Name ~= "Placeholder"
					and frame.Name ~= "__RayfieldSearch__"
					and frame.Name ~= "__RayfieldSelectAll__"
					and frame.Name ~= "__RayfieldListFilter__"
			end

			local function syncMultiOptionTitles()
				if not DropdownSettings.MultipleOptions then
					return
				end
				for _, droption in ipairs(Dropdown.List:GetChildren()) do
					if isDropdownOptionRow(droption) then
						local on = table.find(DropdownSettings.CurrentOption, droption.Name)
						droption.Title.Text = (on and "☑ " or "☐ ") .. droption.Name
					end
				end
			end

			Dropdown.Toggle.ImageColor3 = SelectedTheme.TextColor
			rfTween(Dropdown, {BackgroundColor3 = SelectedTheme.ElementBackground}, "Emphasis")

			Dropdown.BackgroundTransparency = 1
			Dropdown.UIStroke.Transparency = 1
			Dropdown.Title.TextTransparency = 1

			Dropdown.Size = UDim2.new(1, -10, 0, 45)

			rfTween(Dropdown, { BackgroundTransparency = 0 }, "Smooth")
			rfTween(Dropdown.UIStroke, { Transparency = 0 }, "Smooth")
			rfTween(Dropdown.Title, { TextTransparency = 0 }, "Smooth")

			for _, ununusedoption in ipairs(Dropdown.List:GetChildren()) do
				if ununusedoption.ClassName == "Frame" and ununusedoption.Name ~= "Placeholder" and ununusedoption.Name ~= "__RayfieldListFilter__" then
					ununusedoption:Destroy()
				end
			end

			Dropdown.Toggle.Rotation = 180

			Dropdown.Interact.MouseButton1Click:Connect(function()
				rfTween(Dropdown, { BackgroundColor3 = SelectedTheme.ElementBackgroundHover }, "Fast")
				rfTween(Dropdown.UIStroke, { Transparency = 1 }, "Fast")
				task.wait(0.1)
				rfTween(Dropdown, { BackgroundColor3 = SelectedTheme.ElementBackground }, "Fast")
				rfTween(Dropdown.UIStroke, { Transparency = 0 }, "Fast")
				if Debounce then return end
				if Dropdown.List.Visible then
					Debounce = true
					rfTween(Dropdown, { Size = UDim2.new(1, -10, 0, 45) }, "Smooth")
					for _, DropdownOpt in ipairs(Dropdown.List:GetChildren()) do
						if isDropdownOptionRow(DropdownOpt) or DropdownOpt.Name == "__RayfieldSelectAll__" then
							rfTween(DropdownOpt, { BackgroundTransparency = 1 }, "Fast")
							rfTween(DropdownOpt.UIStroke, { Transparency = 1 }, "Fast")
							rfTween(DropdownOpt.Title, { TextTransparency = 1 }, "Fast")
						end
					end
					rfTween(Dropdown.List, { ScrollBarImageTransparency = 1 }, "Fast")
					rfTween(Dropdown.Toggle, { Rotation = 180 }, "Smooth")
					task.wait(0.35)
					Dropdown.List.Visible = false
					Debounce = false
				else
					rfTween(Dropdown, { Size = UDim2.new(1, -10, 0, 180) }, "Smooth")
					Dropdown.List.Visible = true
					rfTween(Dropdown.List, { ScrollBarImageTransparency = 0.7 }, "Fast")
					rfTween(Dropdown.Toggle, { Rotation = 0 }, "Smooth")
					for _, DropdownOpt in ipairs(Dropdown.List:GetChildren()) do
						if isDropdownOptionRow(DropdownOpt) or DropdownOpt.Name == "__RayfieldSelectAll__" then
							if DropdownOpt.Name ~= Dropdown.Selected.Text then
								rfTween(DropdownOpt.UIStroke, { Transparency = 0 }, "Fast")
							end
							rfTween(DropdownOpt, { BackgroundTransparency = 0 }, "Fast")
							rfTween(DropdownOpt.Title, { TextTransparency = 0 }, "Fast")
						end
					end
				end
			end)

			Dropdown.MouseEnter:Connect(function()
				if not Dropdown.List.Visible then
					rfTween(Dropdown, { BackgroundColor3 = SelectedTheme.ElementBackgroundHover }, "Fast")
				end
			end)

			Dropdown.MouseLeave:Connect(function()
				rfTween(Dropdown, { BackgroundColor3 = SelectedTheme.ElementBackground }, "Fast")
			end)

			local function SetDropdownOptions()
				local zdi = (DesignTokensMod and DesignTokensMod.ZIndex and DesignTokensMod.ZIndex.DropdownItem) or 50

				if DropdownSettings.SelectAll and DropdownSettings.MultipleOptions then
					local selAll = Elements.Template.Dropdown.List.Template:Clone()
					selAll.Name = "__RayfieldSelectAll__"
					selAll.Title.Text = "Selecionar / limpar tudo"
					selAll.Parent = Dropdown.List
					selAll.Visible = true
					selAll.BackgroundTransparency = 0
					selAll.UIStroke.Transparency = 0
					selAll.Title.TextTransparency = 0
					selAll.BackgroundColor3 = SelectedTheme.SecondaryElementBackground
					selAll.Interact.ZIndex = zdi
					selAll.Interact.MouseButton1Click:Connect(function()
						local allSelected = #DropdownSettings.Options > 0 and #DropdownSettings.CurrentOption == #DropdownSettings.Options
						table.clear(DropdownSettings.CurrentOption)
						if not allSelected then
							for _, o in ipairs(DropdownSettings.Options) do
								table.insert(DropdownSettings.CurrentOption, o)
							end
						end
						multiHeaderText()
						pcall(DropdownSettings.Callback, DropdownSettings.CurrentOption)
						for _, droption in ipairs(Dropdown.List:GetChildren()) do
							if isDropdownOptionRow(droption) then
								droption.BackgroundColor3 = table.find(DropdownSettings.CurrentOption, droption.Name) and SelectedTheme.DropdownSelected
									or SelectedTheme.DropdownUnselected
							end
						end
						syncMultiOptionTitles()
						if not DropdownSettings.Ext then
							SaveConfiguration()
						end
					end)
				end

				for _, Option in ipairs(DropdownSettings.Options) do
					local DropdownOption = Elements.Template.Dropdown.List.Template:Clone()
					DropdownOption.Name = Option
					DropdownOption.Title.Text = DropdownSettings.MultipleOptions
						and ((table.find(DropdownSettings.CurrentOption, Option) and "☑ " or "☐ ") .. Option)
						or Option
					DropdownOption.Parent = Dropdown.List
					DropdownOption.Visible = true

					DropdownOption.BackgroundTransparency = 1
					DropdownOption.UIStroke.Transparency = 1
					DropdownOption.Title.TextTransparency = 1

					DropdownOption.Interact.ZIndex = zdi
					DropdownOption.Interact.MouseButton1Click:Connect(function()
						if not DropdownSettings.MultipleOptions and table.find(DropdownSettings.CurrentOption, Option) then 
							return
						end

						if table.find(DropdownSettings.CurrentOption, Option) then
							table.remove(DropdownSettings.CurrentOption, table.find(DropdownSettings.CurrentOption, Option))
							if DropdownSettings.MultipleOptions then
								multiHeaderText()
							else
								Dropdown.Selected.Text = DropdownSettings.CurrentOption[1]
							end
						else
							if not DropdownSettings.MultipleOptions then
								table.clear(DropdownSettings.CurrentOption)
							end
							table.insert(DropdownSettings.CurrentOption, Option)
							if DropdownSettings.MultipleOptions then
								multiHeaderText()
							else
								Dropdown.Selected.Text = DropdownSettings.CurrentOption[1]
							end
							rfTween(DropdownOption.UIStroke, { Transparency = 1 }, "Fast")
							rfTween(DropdownOption, { BackgroundColor3 = SelectedTheme.DropdownSelected }, "Fast")
							Debounce = true
						end


						local Success, Response = pcall(function()
							DropdownSettings.Callback(DropdownSettings.CurrentOption)
						end)

						if not Success then
							rfTween(Dropdown, {BackgroundColor3 = Color3.fromRGB(85, 0, 0)}, "Emphasis")
							rfTween(Dropdown.UIStroke, {Transparency = 1}, "Emphasis")
							Dropdown.Title.Text = "Callback Error"
							print("Rayfield | "..DropdownSettings.Name.." Callback Error " ..tostring(Response))
							warn('Check docs.sirius.menu for help with Rayfield specific development.')
							task.wait(0.5)
							Dropdown.Title.Text = DropdownSettings.Name
							rfTween(Dropdown, {BackgroundColor3 = SelectedTheme.ElementBackground}, "Emphasis")
							rfTween(Dropdown.UIStroke, {Transparency = 0}, "Emphasis")
						end

						for _, droption in ipairs(Dropdown.List:GetChildren()) do
							if isDropdownOptionRow(droption) and not table.find(DropdownSettings.CurrentOption, droption.Name) then
								rfTween(droption, { BackgroundColor3 = SelectedTheme.DropdownUnselected }, "Fast")
							end
						end
						if not DropdownSettings.MultipleOptions then
							task.wait(0.1)
							rfTween(Dropdown, { Size = UDim2.new(1, -10, 0, 45) }, "Smooth")
							for _, DropdownOpt in ipairs(Dropdown.List:GetChildren()) do
								if isDropdownOptionRow(DropdownOpt) then
									rfTween(DropdownOpt, { BackgroundTransparency = 1 }, "Fast")
									rfTween(DropdownOpt.UIStroke, { Transparency = 1 }, "Fast")
									rfTween(DropdownOpt.Title, { TextTransparency = 1 }, "Fast")
								end
							end
							rfTween(Dropdown.List, { ScrollBarImageTransparency = 1 }, "Fast")
							rfTween(Dropdown.Toggle, { Rotation = 180 }, "Smooth")
							task.wait(0.35)
							Dropdown.List.Visible = false
						end
						Debounce = false
						syncMultiOptionTitles()
						if not DropdownSettings.Ext then
							SaveConfiguration()
						end
					end)

					Rayfield.Main:GetPropertyChangedSignal('BackgroundColor3'):Connect(function()
						DropdownOption.UIStroke.Color = SelectedTheme.ElementStroke
					end)
				end
			end
			SetDropdownOptions()

			if DropdownSettings.ListSearch and not Dropdown.List:FindFirstChild("__RayfieldListFilter__") then
				local sb = Instance.new("TextBox")
				sb.Name = "__RayfieldListFilter__"
				sb.BackgroundColor3 = SelectedTheme.InputBackground
				sb.TextColor3 = SelectedTheme.TextColor
				sb.PlaceholderText = "Filtrar opções…"
				sb.Text = ""
				sb.ClearTextOnFocus = false
				sb.Font = Enum.Font.Gotham
				sb.TextSize = 13
				sb.Size = UDim2.new(1, -6, 0, 26)
				sb.LayoutOrder = -999
				local sbStroke = Instance.new("UIStroke")
				sbStroke.Color = SelectedTheme.InputStroke
				sbStroke.Parent = sb
				sb.Parent = Dropdown.List
				sb:GetPropertyChangedSignal("Text"):Connect(function()
					local q = string.lower(sb.Text)
					for _, ch in ipairs(Dropdown.List:GetChildren()) do
						if isDropdownOptionRow(ch) or ch.Name == "__RayfieldSelectAll__" then
							ch.Visible = q == "" or string.find(string.lower(ch.Name), q, 1, true) ~= nil
						end
					end
				end)
			end

			for _, droption in ipairs(Dropdown.List:GetChildren()) do
				if isDropdownOptionRow(droption) then
					if not table.find(DropdownSettings.CurrentOption, droption.Name) then
						droption.BackgroundColor3 = SelectedTheme.DropdownUnselected
					else
						droption.BackgroundColor3 = SelectedTheme.DropdownSelected
					end

					Rayfield.Main:GetPropertyChangedSignal('BackgroundColor3'):Connect(function()
						if not table.find(DropdownSettings.CurrentOption, droption.Name) then
							droption.BackgroundColor3 = SelectedTheme.DropdownUnselected
						else
							droption.BackgroundColor3 = SelectedTheme.DropdownSelected
						end
					end)
				end
			end

			function DropdownSettings:Set(NewOption)
				DropdownSettings.CurrentOption = NewOption

				if typeof(DropdownSettings.CurrentOption) == "string" then
					DropdownSettings.CurrentOption = {DropdownSettings.CurrentOption}
				end

				if not DropdownSettings.MultipleOptions then
					DropdownSettings.CurrentOption = {DropdownSettings.CurrentOption[1]}
				end

				if DropdownSettings.MultipleOptions then
					multiHeaderText()
				else
					Dropdown.Selected.Text = DropdownSettings.CurrentOption[1]
				end


				local Success, Response = pcall(function()
					DropdownSettings.Callback(NewOption)
				end)
				if not Success then
					rfTween(Dropdown, { BackgroundColor3 = Color3.fromRGB(85, 0, 0) }, "Fast")
					rfTween(Dropdown.UIStroke, { Transparency = 1 }, "Fast")
					Dropdown.Title.Text = "Callback Error"
					print("Rayfield | "..DropdownSettings.Name.." Callback Error " ..tostring(Response))
					warn('Check docs.sirius.menu for help with Rayfield specific development.')
					task.wait(0.5)
					Dropdown.Title.Text = DropdownSettings.Name
					rfTween(Dropdown, { BackgroundColor3 = SelectedTheme.ElementBackground }, "Smooth")
					rfTween(Dropdown.UIStroke, { Transparency = 0 }, "Smooth")
				end

				for _, droption in ipairs(Dropdown.List:GetChildren()) do
					if isDropdownOptionRow(droption) then
						if not table.find(DropdownSettings.CurrentOption, droption.Name) then
							droption.BackgroundColor3 = SelectedTheme.DropdownUnselected
						else
							droption.BackgroundColor3 = SelectedTheme.DropdownSelected
						end
					end
				end
				syncMultiOptionTitles()
				--SaveConfiguration()
			end

			function DropdownSettings:Refresh(optionsTable: table) -- updates a dropdown with new options from optionsTable
				DropdownSettings.Options = optionsTable
				for _, option in Dropdown.List:GetChildren() do
					if option.ClassName == "Frame" and option.Name ~= "Placeholder" and option.Name ~= "__RayfieldListFilter__" then
						option:Destroy()
					end
				end
				SetDropdownOptions()

				-- Apply selected/unselected background colors to new options
				for _, droption in ipairs(Dropdown.List:GetChildren()) do
					if isDropdownOptionRow(droption) then
						if not table.find(DropdownSettings.CurrentOption, droption.Name) then
							droption.BackgroundColor3 = SelectedTheme.DropdownUnselected
						else
							droption.BackgroundColor3 = SelectedTheme.DropdownSelected
						end
					end
				end

				-- If the dropdown is currently open, make new options visible immediately
				if Dropdown.List.Visible then
					for _, DropdownOpt in ipairs(Dropdown.List:GetChildren()) do
						if isDropdownOptionRow(DropdownOpt) or DropdownOpt.Name == "__RayfieldSelectAll__" then
							DropdownOpt.BackgroundTransparency = 0
							DropdownOpt.Title.TextTransparency = 0
							if not table.find(DropdownSettings.CurrentOption, DropdownOpt.Name) then
								DropdownOpt.UIStroke.Transparency = 0
							end
						end
					end
				end
			end

			if Settings.ConfigurationSaving then
				if Settings.ConfigurationSaving.Enabled and DropdownSettings.Flag then
					RayfieldLibrary.Flags[DropdownSettings.Flag] = DropdownSettings
				end
			end

			Rayfield.Main:GetPropertyChangedSignal('BackgroundColor3'):Connect(function()
				Dropdown.Toggle.ImageColor3 = SelectedTheme.TextColor
				rfTween(Dropdown, {BackgroundColor3 = SelectedTheme.ElementBackground}, "Emphasis")
			end)

			return DropdownSettings
		end

		function Tab:CreateMultiDropdown(MultiSettings)
			MultiSettings = MultiSettings or {}
			MultiSettings.MultipleOptions = true
			MultiSettings.SelectAll = MultiSettings.SelectAll ~= false
			MultiSettings.ShowSelectionCount = MultiSettings.ShowSelectionCount ~= false
			return Tab:CreateDropdown(MultiSettings)
		end

		function Tab:CreateConsole(ConsoleSettings)
			ConsoleSettings = ConsoleSettings or {}
			local maxLines = ConsoleSettings.MaxLines or 250
			local wrap = {}
			local holder = Instance.new("Frame")
			holder.Name = ConsoleSettings.Name or "Console"
			holder.Size = UDim2.new(1, -10, 0, 160)
			holder.BackgroundColor3 = SelectedTheme.SecondaryElementBackground
			holder.Parent = TabPage
			local hStroke = Instance.new("UIStroke")
			hStroke.Color = SelectedTheme.SecondaryElementStroke
			hStroke.Parent = holder
			local hCorner = Instance.new("UICorner")
			hCorner.CornerRadius = UDim.new(0, 8)
			hCorner.Parent = holder

			local scroll = Instance.new("ScrollingFrame")
			scroll.Name = "Log"
			scroll.Size = UDim2.new(1, -12, 1, -12)
			scroll.Position = UDim2.new(0, 6, 0, 6)
			scroll.BackgroundTransparency = 1
			scroll.ScrollBarThickness = 4
			scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
			scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
			scroll.Parent = holder

			local layout = Instance.new("UIListLayout")
			layout.Padding = UDim.new(0, 2)
			layout.Parent = scroll

			function wrap:AddLine(text, color)
				local line = Instance.new("TextLabel")
				line.BackgroundTransparency = 1
				line.Size = UDim2.new(1, -4, 0, 16)
				line.Font = Enum.Font.Code
				line.TextSize = 12
				line.TextXAlignment = Enum.TextXAlignment.Left
				line.TextWrapped = true
				line.Text = tostring(text)
				line.TextColor3 = color or SelectedTheme.TextColor
				line.Parent = scroll
				while true do
					local labels = {}
					for _, c in ipairs(scroll:GetChildren()) do
						if c:IsA("TextLabel") then
							table.insert(labels, c)
						end
					end
					if #labels <= maxLines then
						break
					end
					labels[1]:Destroy()
				end
				task.defer(function()
					scroll.CanvasPosition = Vector2.new(0, math.max(0, scroll.AbsoluteCanvasSize.Y - scroll.AbsoluteSize.Y))
				end)
			end

			function wrap:Clear()
				for _, c in ipairs(scroll:GetChildren()) do
					if c:IsA("TextLabel") then
						c:Destroy()
					end
				end
			end

			Rayfield.Main:GetPropertyChangedSignal("BackgroundColor3"):Connect(function()
				holder.BackgroundColor3 = SelectedTheme.SecondaryElementBackground
				hStroke.Color = SelectedTheme.SecondaryElementStroke
			end)

			return wrap
		end

		-- Keybind
		function Tab:CreateKeybind(KeybindSettings)
			local CheckingForKey = false
			local Keybind = Elements.Template.Keybind:Clone()
			Keybind.Name = KeybindSettings.Name
			Keybind.Title.Text = KeybindSettings.Name
			Keybind.Visible = true
			Keybind.Parent = TabPage

			Keybind.BackgroundTransparency = 1
			Keybind.UIStroke.Transparency = 1
			Keybind.Title.TextTransparency = 1

			Keybind.KeybindFrame.BackgroundColor3 = SelectedTheme.InputBackground
			Keybind.KeybindFrame.UIStroke.Color = SelectedTheme.InputStroke

			rfTween(Keybind, { BackgroundTransparency = 0 }, "Smooth")
			rfTween(Keybind.UIStroke, { Transparency = 0 }, "Smooth")
			rfTween(Keybind.Title, { TextTransparency = 0 }, "Smooth")

			Keybind.KeybindFrame.KeybindBox.Text = KeybindSettings.CurrentKeybind
			Keybind.KeybindFrame.Size = UDim2.new(0, Keybind.KeybindFrame.KeybindBox.TextBounds.X + 24, 0, 30)

			Keybind.KeybindFrame.KeybindBox.Focused:Connect(function()
				CheckingForKey = true
				Keybind.KeybindFrame.KeybindBox.Text = ""
			end)
			Keybind.KeybindFrame.KeybindBox.FocusLost:Connect(function()
				CheckingForKey = false
				if Keybind.KeybindFrame.KeybindBox.Text == nil or Keybind.KeybindFrame.KeybindBox.Text == "" then
					Keybind.KeybindFrame.KeybindBox.Text = KeybindSettings.CurrentKeybind
					if not KeybindSettings.Ext then
						SaveConfiguration()
					end
				end
			end)

			Keybind.MouseEnter:Connect(function()
				rfTween(Keybind, { BackgroundColor3 = SelectedTheme.ElementBackgroundHover }, "Fast")
			end)

			Keybind.MouseLeave:Connect(function()
				rfTween(Keybind, { BackgroundColor3 = SelectedTheme.ElementBackground }, "Fast")
			end)

			local connection = UserInputService.InputBegan:Connect(function(input, processed)
				if CheckingForKey then
					if input.KeyCode ~= Enum.KeyCode.Unknown then
						local SplitMessage = string.split(tostring(input.KeyCode), ".")
						local NewKeyNoEnum = SplitMessage[3]
						Keybind.KeybindFrame.KeybindBox.Text = tostring(NewKeyNoEnum)
						KeybindSettings.CurrentKeybind = tostring(NewKeyNoEnum)
						Keybind.KeybindFrame.KeybindBox:ReleaseFocus()
						if not KeybindSettings.Ext then
							SaveConfiguration()
						end

						if KeybindSettings.CallOnChange then
							KeybindSettings.Callback(tostring(NewKeyNoEnum))
						end
					end
				elseif not KeybindSettings.CallOnChange and KeybindSettings.CurrentKeybind ~= nil and (input.KeyCode == Enum.KeyCode[KeybindSettings.CurrentKeybind] and not processed) then -- Test
					local Held = true
					local Connection
					Connection = input.Changed:Connect(function(prop)
						if prop == "UserInputState" then
							Connection:Disconnect()
							Held = false
						end
					end)

					if not KeybindSettings.HoldToInteract then
						local Success, Response = pcall(KeybindSettings.Callback)
						if not Success then
							rfTween(Keybind, { BackgroundColor3 = Color3.fromRGB(85, 0, 0) }, "Fast")
							rfTween(Keybind.UIStroke, { Transparency = 1 }, "Fast")
							Keybind.Title.Text = "Callback Error"
							print("Rayfield | "..KeybindSettings.Name.." Callback Error " ..tostring(Response))
							warn('Check docs.sirius.menu for help with Rayfield specific development.')
							task.wait(0.5)
							Keybind.Title.Text = KeybindSettings.Name
							rfTween(Keybind, { BackgroundColor3 = SelectedTheme.ElementBackground }, "Smooth")
							rfTween(Keybind.UIStroke, { Transparency = 0 }, "Smooth")
						end
					else
						task.wait(0.25)
						if Held then
							local Loop; Loop = RunService.Stepped:Connect(function()
								if not Held then
									KeybindSettings.Callback(false) -- maybe pcall this
									Loop:Disconnect()
								else
									KeybindSettings.Callback(true) -- maybe pcall this
								end
							end)
						end
					end
				end
			end)
			table.insert(keybindConnections, connection)

			Keybind.KeybindFrame.KeybindBox:GetPropertyChangedSignal("Text"):Connect(function()
				rfTween(Keybind.KeybindFrame, { Size = UDim2.new(0, Keybind.KeybindFrame.KeybindBox.TextBounds.X + 24, 0, 30) }, "Fast")
			end)

			function KeybindSettings:Set(NewKeybind)
				Keybind.KeybindFrame.KeybindBox.Text = tostring(NewKeybind)
				KeybindSettings.CurrentKeybind = tostring(NewKeybind)
				Keybind.KeybindFrame.KeybindBox:ReleaseFocus()
				if not KeybindSettings.Ext then
					SaveConfiguration()
				end

				if KeybindSettings.CallOnChange then
					KeybindSettings.Callback(tostring(NewKeybind))
				end
			end

			if Settings.ConfigurationSaving then
				if Settings.ConfigurationSaving.Enabled and KeybindSettings.Flag then
					RayfieldLibrary.Flags[KeybindSettings.Flag] = KeybindSettings
				end
			end

			Rayfield.Main:GetPropertyChangedSignal('BackgroundColor3'):Connect(function()
				Keybind.KeybindFrame.BackgroundColor3 = SelectedTheme.InputBackground
				Keybind.KeybindFrame.UIStroke.Color = SelectedTheme.InputStroke
			end)

			return KeybindSettings
		end

		-- Toggle
		function Tab:CreateToggle(ToggleSettings)
			local ToggleValue = {}

			local Toggle = Elements.Template.Toggle:Clone()
			Toggle.Name = ToggleSettings.Name
			Toggle.Title.Text = ToggleSettings.Name
			Toggle.Visible = true
			Toggle.Parent = TabPage

			Toggle.BackgroundTransparency = 1
			Toggle.UIStroke.Transparency = 1
			Toggle.Title.TextTransparency = 1
			Toggle.Switch.BackgroundColor3 = SelectedTheme.ToggleBackground

			if SelectedTheme ~= RayfieldLibrary.Theme.Default then
				Toggle.Switch.Shadow.Visible = false
			end

			rfTween(Toggle, { BackgroundTransparency = 0 }, "Smooth")
			rfTween(Toggle.UIStroke, { Transparency = 0 }, "Smooth")
			rfTween(Toggle.Title, { TextTransparency = 0 }, "Smooth")

			if ToggleSettings.CurrentValue == true then
				Toggle.Switch.Indicator.Position = UDim2.new(1, -20, 0.5, 0)
				Toggle.Switch.Indicator.UIStroke.Color = SelectedTheme.ToggleEnabledStroke
				Toggle.Switch.Indicator.BackgroundColor3 = SelectedTheme.ToggleEnabled
				Toggle.Switch.UIStroke.Color = SelectedTheme.ToggleEnabledOuterStroke
			else
				Toggle.Switch.Indicator.Position = UDim2.new(1, -40, 0.5, 0)
				Toggle.Switch.Indicator.UIStroke.Color = SelectedTheme.ToggleDisabledStroke
				Toggle.Switch.Indicator.BackgroundColor3 = SelectedTheme.ToggleDisabled
				Toggle.Switch.UIStroke.Color = SelectedTheme.ToggleDisabledOuterStroke
			end

			Toggle.MouseEnter:Connect(function()
				rfTween(Toggle, { BackgroundColor3 = SelectedTheme.ElementBackgroundHover }, "Fast")
			end)

			Toggle.MouseLeave:Connect(function()
				rfTween(Toggle, { BackgroundColor3 = SelectedTheme.ElementBackground }, "Fast")
			end)

			Toggle.Interact.MouseButton1Click:Connect(function()
				if ToggleSettings.CurrentValue == true then
					ToggleSettings.CurrentValue = false
					rfTween(Toggle, { BackgroundColor3 = SelectedTheme.ElementBackgroundHover }, "Fast")
					rfTween(Toggle.UIStroke, { Transparency = 1 }, "Fast")
					rfTween(Toggle.Switch.Indicator, { Position = UDim2.new(1, -40, 0.5, 0) }, "Smooth")
					rfTween(Toggle.Switch.Indicator.UIStroke, { Color = SelectedTheme.ToggleDisabledStroke }, "Smooth")
					rfTween(Toggle.Switch.Indicator, { BackgroundColor3 = SelectedTheme.ToggleDisabled }, "Smooth")
					rfTween(Toggle.Switch.UIStroke, { Color = SelectedTheme.ToggleDisabledOuterStroke }, "Smooth")
					rfTween(Toggle, { BackgroundColor3 = SelectedTheme.ElementBackground }, "Smooth")
					rfTween(Toggle.UIStroke, { Transparency = 0 }, "Smooth")
				else
					ToggleSettings.CurrentValue = true
					rfTween(Toggle, { BackgroundColor3 = SelectedTheme.ElementBackgroundHover }, "Fast")
					rfTween(Toggle.UIStroke, { Transparency = 1 }, "Fast")
					rfTween(Toggle.Switch.Indicator, { Position = UDim2.new(1, -20, 0.5, 0) }, "Smooth")
					rfTween(Toggle.Switch.Indicator.UIStroke, { Color = SelectedTheme.ToggleEnabledStroke }, "Smooth")
					rfTween(Toggle.Switch.Indicator, { BackgroundColor3 = SelectedTheme.ToggleEnabled }, "Smooth")
					rfTween(Toggle.Switch.UIStroke, { Color = SelectedTheme.ToggleEnabledOuterStroke }, "Smooth")
					rfTween(Toggle, { BackgroundColor3 = SelectedTheme.ElementBackground }, "Smooth")
					rfTween(Toggle.UIStroke, { Transparency = 0 }, "Smooth")
				end

				local Success, Response = pcall(function()
					if debugX then warn('Running toggle \''..ToggleSettings.Name..'\' (Interact)') end

					ToggleSettings.Callback(ToggleSettings.CurrentValue)
				end)

				if not Success then
					rfTween(Toggle, { BackgroundColor3 = Color3.fromRGB(85, 0, 0) }, "Fast")
					rfTween(Toggle.UIStroke, { Transparency = 1 }, "Fast")
					Toggle.Title.Text = "Callback Error"
					print("Rayfield | "..ToggleSettings.Name.." Callback Error " ..tostring(Response))
					warn('Check docs.sirius.menu for help with Rayfield specific development.')
					task.wait(0.5)
					Toggle.Title.Text = ToggleSettings.Name
					rfTween(Toggle, { BackgroundColor3 = SelectedTheme.ElementBackground }, "Smooth")
					rfTween(Toggle.UIStroke, { Transparency = 0 }, "Smooth")
				end

				if not ToggleSettings.Ext then
					SaveConfiguration()
				end
			end)

			function ToggleSettings:Set(NewToggleValue)
				if NewToggleValue == true then
					ToggleSettings.CurrentValue = true
					rfTween(Toggle, { BackgroundColor3 = SelectedTheme.ElementBackgroundHover }, "Fast")
					rfTween(Toggle.UIStroke, { Transparency = 1 }, "Fast")
					rfTween(Toggle.Switch.Indicator, { Position = UDim2.new(1, -20, 0.5, 0) }, "Smooth")
					rfTween(Toggle.Switch.Indicator, { Size = UDim2.new(0,12,0,12) }, "Fast")
					rfTween(Toggle.Switch.Indicator.UIStroke, { Color = SelectedTheme.ToggleEnabledStroke }, "Smooth")
					rfTween(Toggle.Switch.Indicator, { BackgroundColor3 = SelectedTheme.ToggleEnabled }, "Smooth")
					rfTween(Toggle.Switch.UIStroke, { Color = SelectedTheme.ToggleEnabledOuterStroke }, "Smooth")
					rfTween(Toggle.Switch.Indicator, { Size = UDim2.new(0,17,0,17) }, "Smooth")
					rfTween(Toggle, { BackgroundColor3 = SelectedTheme.ElementBackground }, "Smooth")
					rfTween(Toggle.UIStroke, { Transparency = 0 }, "Smooth")
				else
					ToggleSettings.CurrentValue = false
					rfTween(Toggle, { BackgroundColor3 = SelectedTheme.ElementBackgroundHover }, "Fast")
					rfTween(Toggle.UIStroke, { Transparency = 1 }, "Fast")
					rfTween(Toggle.Switch.Indicator, { Position = UDim2.new(1, -40, 0.5, 0) }, "Smooth")
					rfTween(Toggle.Switch.Indicator, { Size = UDim2.new(0,12,0,12) }, "Fast")
					rfTween(Toggle.Switch.Indicator.UIStroke, { Color = SelectedTheme.ToggleDisabledStroke }, "Smooth")
					rfTween(Toggle.Switch.Indicator, { BackgroundColor3 = SelectedTheme.ToggleDisabled }, "Smooth")
					rfTween(Toggle.Switch.UIStroke, { Color = SelectedTheme.ToggleDisabledOuterStroke }, "Smooth")
					rfTween(Toggle.Switch.Indicator, { Size = UDim2.new(0,17,0,17) }, "Smooth")
					rfTween(Toggle, { BackgroundColor3 = SelectedTheme.ElementBackground }, "Smooth")
					rfTween(Toggle.UIStroke, { Transparency = 0 }, "Smooth")
				end

				local Success, Response = pcall(function()
					if debugX then warn('Running toggle \''..ToggleSettings.Name..'\' (:Set)') end

					ToggleSettings.Callback(ToggleSettings.CurrentValue)
				end)

				if not Success then
					rfTween(Toggle, { BackgroundColor3 = Color3.fromRGB(85, 0, 0) }, "Fast")
					rfTween(Toggle.UIStroke, { Transparency = 1 }, "Fast")
					Toggle.Title.Text = "Callback Error"
					print("Rayfield | "..ToggleSettings.Name.." Callback Error " ..tostring(Response))
					warn('Check docs.sirius.menu for help with Rayfield specific development.')
					task.wait(0.5)
					Toggle.Title.Text = ToggleSettings.Name
					rfTween(Toggle, { BackgroundColor3 = SelectedTheme.ElementBackground }, "Smooth")
					rfTween(Toggle.UIStroke, { Transparency = 0 }, "Smooth")
				end

				if not ToggleSettings.Ext then
					SaveConfiguration()
				end
			end

			if not ToggleSettings.Ext then
				if Settings.ConfigurationSaving then
					if Settings.ConfigurationSaving.Enabled and ToggleSettings.Flag then
						RayfieldLibrary.Flags[ToggleSettings.Flag] = ToggleSettings
					end
				end
			end


			Rayfield.Main:GetPropertyChangedSignal('BackgroundColor3'):Connect(function()
				Toggle.Switch.BackgroundColor3 = SelectedTheme.ToggleBackground

				if SelectedTheme ~= RayfieldLibrary.Theme.Default then
					Toggle.Switch.Shadow.Visible = false
				end

				task.wait()

				if not ToggleSettings.CurrentValue then
					Toggle.Switch.Indicator.UIStroke.Color = SelectedTheme.ToggleDisabledStroke
					Toggle.Switch.Indicator.BackgroundColor3 = SelectedTheme.ToggleDisabled
					Toggle.Switch.UIStroke.Color = SelectedTheme.ToggleDisabledOuterStroke
				else
					Toggle.Switch.Indicator.UIStroke.Color = SelectedTheme.ToggleEnabledStroke
					Toggle.Switch.Indicator.BackgroundColor3 = SelectedTheme.ToggleEnabled
					Toggle.Switch.UIStroke.Color = SelectedTheme.ToggleEnabledOuterStroke
				end
			end)

			return ToggleSettings
		end

		-- Slider
		function Tab:CreateSlider(SliderSettings)
			local SLDragging = false
			local Slider = Elements.Template.Slider:Clone()
			Slider.Name = SliderSettings.Name
			Slider.Title.Text = SliderSettings.Name
			Slider.Visible = true
			Slider.Parent = TabPage

			Slider.BackgroundTransparency = 1
			Slider.UIStroke.Transparency = 1
			Slider.Title.TextTransparency = 1

			if SelectedTheme ~= RayfieldLibrary.Theme.Default then
				Slider.Main.Shadow.Visible = false
			end

			Slider.Main.BackgroundColor3 = SelectedTheme.SliderBackground
			Slider.Main.UIStroke.Color = SelectedTheme.SliderStroke
			Slider.Main.Progress.UIStroke.Color = SelectedTheme.SliderStroke
			Slider.Main.Progress.BackgroundColor3 = SelectedTheme.SliderProgress

			rfTween(Slider, { BackgroundTransparency = 0 }, "Smooth")
			rfTween(Slider.UIStroke, { Transparency = 0 }, "Smooth")
			rfTween(Slider.Title, { TextTransparency = 0 }, "Smooth")

			Slider.Main.Progress.Size =	UDim2.new(0, Slider.Main.AbsoluteSize.X * ((SliderSettings.CurrentValue - SliderSettings.Range[1]) / (SliderSettings.Range[2] - SliderSettings.Range[1])) > 5 and Slider.Main.AbsoluteSize.X * ((SliderSettings.CurrentValue - SliderSettings.Range[1]) / (SliderSettings.Range[2] - SliderSettings.Range[1])) or 5, 1, 0)

			if not SliderSettings.Suffix then
				Slider.Main.Information.Text = tostring(SliderSettings.CurrentValue)
			else
				Slider.Main.Information.Text = tostring(SliderSettings.CurrentValue) .. " " .. SliderSettings.Suffix
			end

			Slider.MouseEnter:Connect(function()
				rfTween(Slider, { BackgroundColor3 = SelectedTheme.ElementBackgroundHover }, "Fast")
			end)

			Slider.MouseLeave:Connect(function()
				rfTween(Slider, { BackgroundColor3 = SelectedTheme.ElementBackground }, "Fast")
			end)

			Slider.Main.Interact.InputBegan:Connect(function(Input)
				if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then 
					rfTween(Slider.Main.UIStroke, {Transparency = 1}, "Emphasis")
					rfTween(Slider.Main.Progress.UIStroke, {Transparency = 1}, "Emphasis")
					SLDragging = true 
				end 
			end)

			Slider.Main.Interact.InputEnded:Connect(function(Input) 
				if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then 
					rfTween(Slider.Main.UIStroke, {Transparency = 0.4}, "Emphasis")
					rfTween(Slider.Main.Progress.UIStroke, {Transparency = 0.3}, "Emphasis")
					SLDragging = false 
				end 
			end)

			Slider.Main.Interact.MouseButton1Down:Connect(function(X)
				local Current = Slider.Main.Progress.AbsolutePosition.X + Slider.Main.Progress.AbsoluteSize.X
				local Start = Current
				local Location = X
				local Loop; Loop = RunService.Stepped:Connect(function()
					if SLDragging then
						Location = UserInputService:GetMouseLocation().X
						Current = Current + 0.025 * (Location - Start)

						if Location < Slider.Main.AbsolutePosition.X then
							Location = Slider.Main.AbsolutePosition.X
						elseif Location > Slider.Main.AbsolutePosition.X + Slider.Main.AbsoluteSize.X then
							Location = Slider.Main.AbsolutePosition.X + Slider.Main.AbsoluteSize.X
						end

						if Current < Slider.Main.AbsolutePosition.X + 5 then
							Current = Slider.Main.AbsolutePosition.X + 5
						elseif Current > Slider.Main.AbsolutePosition.X + Slider.Main.AbsoluteSize.X then
							Current = Slider.Main.AbsolutePosition.X + Slider.Main.AbsoluteSize.X
						end

						if Current <= Location and (Location - Start) < 0 then
							Start = Location
						elseif Current >= Location and (Location - Start) > 0 then
							Start = Location
						end
						rfTween(Slider.Main.Progress, {Size = UDim2.new(0, Current - Slider.Main.AbsolutePosition.X, 1, 0)}, "Emphasis")
						local NewValue = SliderSettings.Range[1] + (Location - Slider.Main.AbsolutePosition.X) / Slider.Main.AbsoluteSize.X * (SliderSettings.Range[2] - SliderSettings.Range[1])

						NewValue = math.floor(NewValue / SliderSettings.Increment + 0.5) * (SliderSettings.Increment * 10000000) / 10000000
						NewValue = math.clamp(NewValue, SliderSettings.Range[1], SliderSettings.Range[2])

						if not SliderSettings.Suffix then
							Slider.Main.Information.Text = tostring(NewValue)
						else
							Slider.Main.Information.Text = tostring(NewValue) .. " " .. SliderSettings.Suffix
						end

						if SliderSettings.CurrentValue ~= NewValue then
							local Success, Response = pcall(function()
								SliderSettings.Callback(NewValue)
							end)
							if not Success then
								rfTween(Slider, {BackgroundColor3 = Color3.fromRGB(85, 0, 0)}, "Emphasis")
								rfTween(Slider.UIStroke, {Transparency = 1}, "Emphasis")
								Slider.Title.Text = "Callback Error"
								print("Rayfield | "..SliderSettings.Name.." Callback Error " ..tostring(Response))
								warn('Check docs.sirius.menu for help with Rayfield specific development.')
								task.wait(0.5)
								Slider.Title.Text = SliderSettings.Name
								rfTween(Slider, {BackgroundColor3 = SelectedTheme.ElementBackground}, "Emphasis")
								rfTween(Slider.UIStroke, {Transparency = 0}, "Emphasis")
							end

							SliderSettings.CurrentValue = NewValue
							if not SliderSettings.Ext then
								SaveConfiguration()
							end
						end
					else
						rfTween(Slider.Main.Progress, {Size = UDim2.new(0, Location - Slider.Main.AbsolutePosition.X > 5 and Location - Slider.Main.AbsolutePosition.X or 5, 1, 0)}, "Emphasis")
						Loop:Disconnect()
					end
				end)
			end)

			function SliderSettings:Set(NewVal)
				local NewVal = math.clamp(NewVal, SliderSettings.Range[1], SliderSettings.Range[2])

				rfTween(Slider.Main.Progress, { Size = UDim2.new(0, Slider.Main.AbsoluteSize.X * ((NewVal - SliderSettings.Range[1]) / (SliderSettings.Range[2] - SliderSettings.Range[1])) > 5 and Slider.Main.AbsoluteSize.X * ((NewVal - SliderSettings.Range[1]) / (SliderSettings.Range[2] - SliderSettings.Range[1])) or 5, 1, 0) }, "Smooth")
				Slider.Main.Information.Text = tostring(NewVal) .. " " .. (SliderSettings.Suffix or "")

				local Success, Response = pcall(function()
					SliderSettings.Callback(NewVal)
				end)

				if not Success then
					rfTween(Slider, { BackgroundColor3 = Color3.fromRGB(85, 0, 0) }, "Fast")
					rfTween(Slider.UIStroke, { Transparency = 1 }, "Fast")
					Slider.Title.Text = "Callback Error"
					print("Rayfield | "..SliderSettings.Name.." Callback Error " ..tostring(Response))
					warn('Check docs.sirius.menu for help with Rayfield specific development.')
					task.wait(0.5)
					Slider.Title.Text = SliderSettings.Name
					rfTween(Slider, { BackgroundColor3 = SelectedTheme.ElementBackground }, "Smooth")
					rfTween(Slider.UIStroke, { Transparency = 0 }, "Smooth")
				end

				SliderSettings.CurrentValue = NewVal
				if not SliderSettings.Ext then
					SaveConfiguration()
				end
			end

			if Settings.ConfigurationSaving then
				if Settings.ConfigurationSaving.Enabled and SliderSettings.Flag then
					RayfieldLibrary.Flags[SliderSettings.Flag] = SliderSettings
				end
			end

			Rayfield.Main:GetPropertyChangedSignal('BackgroundColor3'):Connect(function()
				if SelectedTheme ~= RayfieldLibrary.Theme.Default then
					Slider.Main.Shadow.Visible = false
				end

				Slider.Main.BackgroundColor3 = SelectedTheme.SliderBackground
				Slider.Main.UIStroke.Color = SelectedTheme.SliderStroke
				Slider.Main.Progress.UIStroke.Color = SelectedTheme.SliderStroke
				Slider.Main.Progress.BackgroundColor3 = SelectedTheme.SliderProgress
			end)

			return SliderSettings
		end

		Rayfield.Main:GetPropertyChangedSignal('BackgroundColor3'):Connect(function()
			TabButton.UIStroke.Color = SelectedTheme.TabStroke

			if Elements.UIPageLayout.CurrentPage == TabPage then
				TabButton.BackgroundColor3 = SelectedTheme.TabBackgroundSelected
				TabButton.Image.ImageColor3 = SelectedTheme.SelectedTabTextColor
				TabButton.Title.TextColor3 = SelectedTheme.SelectedTabTextColor
			else
				TabButton.BackgroundColor3 = SelectedTheme.TabBackground
				TabButton.Image.ImageColor3 = SelectedTheme.TabTextColor
				TabButton.Title.TextColor3 = SelectedTheme.TabTextColor
			end
		end)

		return Tab
	end

	Elements.Visible = true


	task.wait(1.1)
	rfTween(Main, {Size = UDim2.new(0, 390, 0, 90)}, "Emphasis")
	task.wait(0.3)
	rfTween(LoadingFrame.Title, {TextTransparency = 1}, "Emphasis")
	rfTween(LoadingFrame.Subtitle, {TextTransparency = 1}, "Emphasis")
	rfTween(LoadingFrame.Version, {TextTransparency = 1}, "Emphasis")
	task.wait(0.1)
	rfTween(Main, {Size = useMobileSizing and UDim2.new(0, 500, 0, 275) or UDim2.new(0, 500, 0, 475)}, "Emphasis")
	rfTween(Main.Shadow.Image, {ImageTransparency = 0.6}, "Emphasis")

	Topbar.BackgroundTransparency = 1
	Topbar.Divider.Size = UDim2.new(0, 0, 0, 1)
	Topbar.Divider.BackgroundColor3 = SelectedTheme.ElementStroke
	Topbar.CornerRepair.BackgroundTransparency = 1
	Topbar.Title.TextTransparency = 1
	Topbar.Search.ImageTransparency = 1
	if Topbar:FindFirstChild('Settings') then
		Topbar.Settings.ImageTransparency = 1
	end
	Topbar.ChangeSize.ImageTransparency = 1
	Topbar.Hide.ImageTransparency = 1


	task.wait(0.5)
	Topbar.Visible = true
	rfTween(Topbar, {BackgroundTransparency = 0}, "Emphasis")
	rfTween(Topbar.CornerRepair, {BackgroundTransparency = 0}, "Emphasis")
	task.wait(0.1)
	rfTween(Topbar.Divider, {Size = UDim2.new(1, 0, 0, 1)}, "Emphasis")
	rfTween(Topbar.Title, {TextTransparency = 0}, "Emphasis")
	task.wait(0.05)
	rfTween(Topbar.Search, {ImageTransparency = 0.8}, "Emphasis")
	task.wait(0.05)
	if Topbar:FindFirstChild('Settings') then
		rfTween(Topbar.Settings, {ImageTransparency = 0.8}, "Emphasis")
		task.wait(0.05)
	end
	rfTween(Topbar.ChangeSize, {ImageTransparency = 0.8}, "Emphasis")
	task.wait(0.05)
	rfTween(Topbar.Hide, {ImageTransparency = 0.8}, "Emphasis")
	task.wait(0.3)

	if dragBar then
		rfTween(dragBarCosmetic, {BackgroundTransparency = 0.7}, "Emphasis")
	end

	function Window.ModifyTheme(NewTheme)
		local success = pcall(ChangeTheme, NewTheme)
		if not success then
			RayfieldLibrary:Notify({Title = 'Unable to Change Theme', Content = 'We are unable find a theme on file.', Image = 4400704299})
		else
			RayfieldLibrary:Notify({Title = 'Theme Changed', Content = 'Successfully changed theme to '..(typeof(NewTheme) == 'string' and NewTheme or 'Custom Theme')..'.', Image = 4483362748})
		end
	end

	local success, result = pcall(function()
		createSettings(Window)
	end)

	if not success then warn('Rayfield had an issue creating settings.') end

	-- Report after createSettings so loadSettings() has run and usageAnalytics reflects the user's saved preference
	if reporter and getSetting("System", "usageAnalytics") then
		local themeName = "Default"
		if Settings.Theme then
			if type(Settings.Theme) == "string" then
				themeName = Settings.Theme
			elseif type(Settings.Theme) == "table" then
				themeName = "Custom"
			end
		end

		local discordInvite = nil
		if Settings.Discord and Settings.Discord.Enabled and Settings.Discord.Invite and Settings.Discord.Invite ~= "" then
			local raw = tostring(Settings.Discord.Invite)
			-- Normalize: strip URL prefixes to extract just the invite code
			discordInvite = (raw:match("discord%.gg/([%w%-]+)") or raw:match("discord%.com/invite/([%w%-]+)") or raw):sub(1, 32)
		end

		local sampleSend = false

		-- Random Sampling Test
		if not Settings.ScriptID and math.random() > 0.4 then
			sampleSend = true
		end

		--if Settings.ScriptID then
			reporter:windowCreated({
				script_name        = Settings.Name or "Unknown",
				script_version     = Release,
				interface_version  = InterfaceBuild,
				theme              = themeName,
				is_mobile          = useMobileSizing and true or false,
				has_key_system     = Settings.KeySystem and true or false,
				discord_invite     = discordInvite,
				config_saving      = (Settings.ConfigurationSaving and Settings.ConfigurationSaving.Enabled) and true or false,
				script_id          = Settings.ScriptID or sampleSend and 'sid_tzfyxawonjx9' or nil,
				verification_token = Settings.VerificationToken,
			})
		--end
	end

	if Settings.CommandPalette then
		setupCommandPalette()
	end

	return Window
end

local function setVisibility(visibility: boolean, notify: boolean?)
	if Debounce then return end
	if visibility then
		Hidden = false
		Unhide()
	else
		Hidden = true
		Hide(notify)
	end
end

function RayfieldLibrary:SetVisibility(visibility: boolean)
	setVisibility(visibility, false)
end

function RayfieldLibrary:IsVisible(): boolean
	return not Hidden
end

local hideHotkeyConnection -- Has to be initialized here since the connection is made later in the script
function RayfieldLibrary:Destroy()
	rayfieldDestroyed = true
	if hideHotkeyConnection then
		hideHotkeyConnection:Disconnect()
	end
	if paletteInputConnection then
		paletteInputConnection:Disconnect()
		paletteInputConnection = nil
	end
	closeCommandPalette()
	if paletteContentBucket then
		paletteContentBucket:Destroy()
		paletteContentBucket = nil
	end
	palettePanelRoot = nil
	paletteFilterBox = nil
	paletteScroll = nil
	paletteOverlayId = nil
	if devOverlayConn then
		devOverlayConn:Disconnect()
		devOverlayConn = nil
	end
	if devOverlayLabel then
		devOverlayLabel:Destroy()
		devOverlayLabel = nil
	end
	for _, connection in keybindConnections do
		connection:Disconnect()
	end
	Rayfield:Destroy()
end

Topbar.ChangeSize.MouseButton1Click:Connect(function()
	if Debounce then return end
	if Minimised then
		Minimised = false
		Maximise()
	else
		Minimised = true
		Minimise()
	end
end)

Main.Search.Input:GetPropertyChangedSignal('Text'):Connect(function()
	if #Main.Search.Input.Text > 0 then
		if not Elements.UIPageLayout.CurrentPage:FindFirstChild('SearchTitle-fsefsefesfsefesfesfThanks') then 
			local searchTitle = Elements.Template.SectionTitle:Clone()
			searchTitle.Parent = Elements.UIPageLayout.CurrentPage
			searchTitle.Name = 'SearchTitle-fsefsefesfsefesfesfThanks'
			searchTitle.LayoutOrder = -100
			searchTitle.Title.Text = "Results from '"..Elements.UIPageLayout.CurrentPage.Name.."'"
			searchTitle.Visible = true
		end
	else
		local searchTitle = Elements.UIPageLayout.CurrentPage:FindFirstChild('SearchTitle-fsefsefesfsefesfesfThanks')

		if searchTitle then
			searchTitle:Destroy()
		end
	end

	for _, element in ipairs(Elements.UIPageLayout.CurrentPage:GetChildren()) do
		if element.ClassName ~= 'UIListLayout' and element.Name ~= 'Placeholder' and element.Name ~= 'SearchTitle-fsefsefesfsefesfesfThanks' then
			if element.Name == 'SectionTitle' then
				if #Main.Search.Input.Text == 0 then
					element.Visible = true
				else
					element.Visible = false
				end
			else
				if string.lower(element.Name):find(string.lower(Main.Search.Input.Text), 1, true) then
					element.Visible = true
				else
					element.Visible = false
				end
			end
		end
	end
end)

Main.Search.Input.FocusLost:Connect(function(enterPressed)
	if #Main.Search.Input.Text == 0 and searchOpen then
		task.wait(0.12)
		closeSearch()
	end
end)

Topbar.Search.MouseButton1Click:Connect(function()
	task.spawn(function()
		if searchOpen then
			closeSearch()
		else
			openSearch()
		end
	end)
end)

if Topbar:FindFirstChild('Settings') then
	Topbar.Settings.MouseButton1Click:Connect(function()
		task.spawn(function()
			for _, OtherTabButton in ipairs(TabList:GetChildren()) do
				if OtherTabButton.Name ~= "Template" and OtherTabButton.ClassName == "Frame" and OtherTabButton.Name ~= "Placeholder" then
					rfTween(OtherTabButton, {BackgroundColor3 = SelectedTheme.TabBackground}, "Emphasis")
					rfTween(OtherTabButton.Title, {TextColor3 = SelectedTheme.TabTextColor}, "Emphasis")
					rfTween(OtherTabButton.Image, {ImageColor3 = SelectedTheme.TabTextColor}, "Emphasis")
					rfTween(OtherTabButton, {BackgroundTransparency = 0.7}, "Emphasis")
					rfTween(OtherTabButton.Title, {TextTransparency = 0.2}, "Emphasis")
					rfTween(OtherTabButton.Image, {ImageTransparency = 0.2}, "Emphasis")
					rfTween(OtherTabButton.UIStroke, {Transparency = 0.5}, "Emphasis")
				end
			end

			Elements.UIPageLayout:JumpTo(Elements['Rayfield Settings'])
		end)
	end)

end


Topbar.Hide.MouseButton1Click:Connect(function()
	setVisibility(Hidden, not useMobileSizing)
end)

hideHotkeyConnection = UserInputService.InputBegan:Connect(function(input, processed)
	if (input.KeyCode == Enum.KeyCode[getSetting("General", "rayfieldOpen")]) and not processed then
		if Debounce then return end
		if Hidden then
			Hidden = false
			Unhide()
		else
			Hidden = true
			Hide()
		end
	end
end)

if MPrompt then
	MPrompt.Interact.MouseButton1Click:Connect(function()
		if Debounce then return end
		if Hidden then
			Hidden = false
			Unhide()
		end
	end)
end

for _, TopbarButton in ipairs(Topbar:GetChildren()) do
	if TopbarButton.ClassName == "ImageButton" and TopbarButton.Name ~= 'Icon' then
		TopbarButton.MouseEnter:Connect(function()
			rfTween(TopbarButton, {ImageTransparency = 0}, "Emphasis")
		end)

		TopbarButton.MouseLeave:Connect(function()
			rfTween(TopbarButton, {ImageTransparency = 0.8}, "Emphasis")
		end)
	end
end


function RayfieldLibrary:RegisterCommand(spec)
	table.insert(commandRegistry, {
		Title = spec.Title or spec.Name or "Command",
		Callback = spec.Callback or function() end,
	})
end

function RayfieldLibrary:GetDesignTokens()
	return DesignTokensMod
end

function RayfieldLibrary:GetPerformanceTier()
	return performanceTier
end

function RayfieldLibrary:GetIconSize()
	return IconSize
end

-- ══════════════════════════════════════════════════════════════
-- 🚦 GATE CONSISTENCY (Fase Gate)
-- ══════════════════════════════════════════════════════════════
-- Toda nova feature deve obrigatoriamente:
--   1. Usar Tokens.Spacing para padding
--   2. Usar Tokens.ZIndex para camadas
--   3. Usar Tokens.GetMotion ou rfTween para animações
--   4. Usar OverlaySystem para popups/modais
--   5. Usar rfStateColor para cores de estado
--   6. Usar rfApplyShadow para sombras
--   7. Usar DesignTokensMod.ApplyTypographyRole para textos
-- Use GateCheck(featureName) para registrar a feature e garantir que passa pelo checklist.

local GATE_CHECKLIST = {
	"Tokens.Spacing",
	"Tokens.ZIndex", 
	"Tokens.Motion / rfTween",
	"OverlaySystem",
	"rfStateColor / InteractionStates",
	"rfApplyShadow",
	"DesignTokensMod.ApplyTypographyRole",
}

function RayfieldLibrary:GateCheck(featureName)
	local ok, result = pcall(function()
		if not RayfieldLibrary:GetDesignTokens() then
			warn("GATE FAIL [" .. tostring(featureName) .. "]: DesignTokensMod not loaded")
			return false
		end
		return true
	end)
	return ok and result ~= false
end

function RayfieldLibrary:GetGateChecklist()
	return table.clone(GATE_CHECKLIST)
end

-- ══════════════════════════════════════════════════════════════
-- 🎯 A3 — CONTEXT MENU
-- ══════════════════════════════════════════════════════════════
-- Uso:
--   local ctx = RayfieldLibrary:CreateContextMenu({
--       Items = {
--           { Title = "Copy", Callback = function() end },
--           { Title = "Paste", Callback = function() end },
--           { Divider = true },
--           { Title = "Delete", Callback = function() end, Color = Color3.fromRGB(200,70,70) },
--       }
--   })
--   ctx:Show(mouseX, mouseY)
--   ctx:Hide()

local activeContextMenus = {}

function RayfieldLibrary:CreateContextMenu(config)
	config = config or {}
	local menuFrame = Instance.new("Frame")
	menuFrame.Name = "RayfieldContextMenu"
	menuFrame.Size = UDim2.new(0, 180, 0, 0)
	menuFrame.BackgroundColor3 = SelectedTheme.Background
	menuFrame.BorderSizePixel = 0
	menuFrame.Visible = false
	
	local stroke = Instance.new("UIStroke")
	stroke.Color = SelectedTheme.ElementStroke
	stroke.Thickness = 1
	stroke.Parent = menuFrame
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = menuFrame
	
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 2)
	layout.Parent = menuFrame
	
	-- Cria ctx primeiro (vazio) para que os botões possam referenciá-lo
	local ctx = {}
	
	local items = config.Items or {}
	local totalHeight = 8
	
	for _, item in ipairs(items) do
		if item.Divider then
			local div = Instance.new("Frame")
			div.Size = UDim2.new(1, -16, 0, 1)
			div.Position = UDim2.new(0, 8, 0, 0)
			div.BackgroundColor3 = SelectedTheme.ElementStroke
			div.BackgroundTransparency = 0.5
			div.BorderSizePixel = 0
			div.Parent = menuFrame
			totalHeight += 8
		else
			local btn = Instance.new("TextButton")
			btn.Name = "CtxItem"
			btn.Size = UDim2.new(1, -8, 0, 32)
			btn.Position = UDim2.new(0, 4, 0, 0)
			btn.BackgroundColor3 = SelectedTheme.ElementBackground
			btn.BackgroundTransparency = 0
			btn.Text = item.Title or ""
			btn.Font = Enum.Font.Gotham
			btn.TextSize = 14
			btn.TextColor3 = item.Color or SelectedTheme.TextColor
			btn.TextXAlignment = Enum.TextXAlignment.Left
			btn.AutoButtonColor = true
			btn.BorderSizePixel = 0
			btn.Parent = menuFrame
			
			local pad = Instance.new("UIPadding")
			pad.PaddingLeft = UDim.new(0, 12)
			pad.Parent = btn
			
			local btnCorner = Instance.new("UICorner")
			btnCorner.CornerRadius = UDim.new(0, 6)
			btnCorner.Parent = btn
			
			btn.MouseEnter:Connect(function()
				rfTween(btn, { BackgroundColor3 = SelectedTheme.ElementBackgroundHover }, "Fast")
			end)
			btn.MouseLeave:Connect(function()
				rfTween(btn, { BackgroundColor3 = SelectedTheme.ElementBackground }, "Fast")
			end)
			btn.MouseButton1Click:Connect(function()
				pcall(item.Callback)
				if ctx and ctx.Hide then
					ctx:Hide()
				end
			end)
			if DesignTokensMod and DesignTokensMod.ApplyTypographyRole then
				DesignTokensMod.ApplyTypographyRole(btn, "Body", item.Color or SelectedTheme.TextColor)
			end
			
			totalHeight += 36
		end
	end
	
	menuFrame.Size = UDim2.new(0, 180, 0, totalHeight)
	
	-- Adiciona as funções ao ctx
	ctx._show = function(x, y)
		-- Fecha context menus anteriores
		while #activeContextMenus > 0 do
			local old = table.remove(activeContextMenus)
			if old and old.Hide then
				pcall(function() old:Hide() end)
			end
		end
		
		local zTooltip = (DesignTokensMod and DesignTokensMod.ZIndex and DesignTokensMod.ZIndex.Tooltip) or 50
		menuFrame.ZIndex = zTooltip
		
		-- Atualiza tema
		menuFrame.BackgroundColor3 = SelectedTheme.Background
		stroke.Color = SelectedTheme.ElementStroke
		for _, child in ipairs(menuFrame:GetChildren()) do
			if child:IsA("TextButton") then
				child.TextColor3 = SelectedTheme.TextColor
				child.BackgroundColor3 = SelectedTheme.ElementBackground
			end
			if child:IsA("Frame") then
				child.BackgroundColor3 = SelectedTheme.ElementStroke
			end
		end
		
		-- Posiciona
		local absX = x or UserInputService:GetMouseLocation().X
		local absY = y or UserInputService:GetMouseLocation().Y
		menuFrame.Position = UDim2.fromOffset(absX, absY)
		menuFrame.Visible = true
		menuFrame.Parent = Rayfield
		
		table.insert(activeContextMenus, ctx)
	end
	ctx.Hide = function()
		menuFrame.Visible = false
		menuFrame.Parent = nil
		for i, v in ipairs(activeContextMenus) do
			if v == ctx then
				table.remove(activeContextMenus, i)
				break
			end
		end
	end
	
	function ctx:Show(x, y)
		self:_show(x, y)
	end
	
	return ctx
end

-- ══════════════════════════════════════════════════════════════
-- 🔑 A4 — HOTKEY SYSTEM
-- ══════════════════════════════════════════════════════════════
-- Uso:
--   local hkId = RayfieldLibrary:RegisterHotkey({
--       Id = "toggle_esp",
--       Title = "Toggle ESP",
--       DefaultKey = "F",
--       Mode = "Toggle", -- "Toggle" | "Hold"
--       Callback = function()
--           -- ...
--       end
--   })
--   RayfieldLibrary:UnregisterHotkey("toggle_esp")

local hotkeyRegistry = {}
local hotkeyConnection = nil

local function setupHotkeyListener()
	if hotkeyConnection then return end
	hotkeyConnection = UserInputService.InputBegan:Connect(function(input, processed)
		if processed then return end
		for _, hk in pairs(hotkeyRegistry) do
			if hk.Key and input.KeyCode == Enum.KeyCode[hk.Key] then
				if hk.Mode == "Toggle" then
					pcall(hk.Callback)
				elseif hk.Mode == "Hold" then
					pcall(hk.Callback, true)
				end
			end
		end
	end)
	
	if UserInputService.InputEnded then
		UserInputService.InputEnded:Connect(function(input, processed)
			if processed then return end
			for _, hk in pairs(hotkeyRegistry) do
				if hk.Key and input.KeyCode == Enum.KeyCode[hk.Key] then
					if hk.Mode == "Hold" then
						pcall(hk.Callback, false)
					end
				end
			end
		end)
	end
end

function RayfieldLibrary:RegisterHotkey(spec)
	spec = spec or {}
	local id = spec.Id or spec.Title or ("hotkey_" .. tostring(#hotkeyRegistry + 1))
	local key = string.upper(tostring(spec.DefaultKey or "F"))
	for otherId, hk in pairs(hotkeyRegistry) do
		if otherId ~= id and string.upper(tostring(hk.Key)) == key then
			warn("Rayfield | RegisterHotkey: tecla '" .. key .. "' já usada por '" .. tostring(otherId) .. "'. Sobrescreva com SetHotkeyKey ou use Id único.")
		end
	end
	hotkeyRegistry[id] = {
		Id = id,
		Title = spec.Title or "Hotkey",
		Key = key,
		Mode = spec.Mode or "Toggle",
		Callback = spec.Callback or function() end,
	}
	setupHotkeyListener()
	return id
end

function RayfieldLibrary:UnregisterHotkey(id)
	hotkeyRegistry[id] = nil
end

function RayfieldLibrary:GetHotkey(id)
	return hotkeyRegistry[id]
end

function RayfieldLibrary:GetAllHotkeys()
	local list = {}
	for _, hk in pairs(hotkeyRegistry) do
		table.insert(list, { Id = hk.Id, Title = hk.Title, Key = hk.Key, Mode = hk.Mode })
	end
	return list
end

function RayfieldLibrary:SetHotkeyKey(id, newKey)
	if hotkeyRegistry[id] then
		hotkeyRegistry[id].Key = newKey
	end
end

function RayfieldLibrary:EnableDevOverlay()
	if devOverlayConn then
		return
	end
	local label = Instance.new("TextLabel")
	label.Name = "RayfieldDevFPS"
	label.AnchorPoint = Vector2.new(1, 0)
	label.Size = UDim2.new(0, 132, 0, 26)
	label.Position = UDim2.new(1, -10, 0, 10)
	label.BackgroundTransparency = 0.2
	label.BackgroundColor3 = Color3.new(0, 0, 0)
	label.TextColor3 = Color3.new(1, 1, 1)
	label.Font = Enum.Font.GothamMedium
	label.TextSize = 14
	label.Text = "FPS: …"
	label.ZIndex = 200
	label.Parent = Main

	local accum = 0
	local nframes = 0
	devOverlayLabel = label
	devOverlayConn = RunService.RenderStepped:Connect(function(dt)
		accum += dt
		nframes += 1
		if nframes >= 40 then
			local avg = accum / nframes
			local fps = avg > 0 and math.floor((1 / avg) + 0.5) or 0
			label.Text = "FPS: " .. tostring(math.clamp(fps, 0, 999))
			accum = 0
			nframes = 0
		end
	end)
end

function RayfieldLibrary:LoadConfiguration()
	local config

	if debugX then
		warn('Loading Configuration')
	end

	if useStudio then
		config = [[{"Toggle1adwawd":true,"ColorPicker1awd":{"B":255,"G":255,"R":255},"Slider1dawd":100,"ColorPicfsefker1":{"B":255,"G":255,"R":255},"Slidefefsr1":80,"dawdawd":"","Input1":"hh","Keybind1":"B","Dropdown1":["Ocean"]}]]
	end

	if CEnabled then
		local notified
		local loaded

		local success, result = pcall(function()
			if useStudio and config then
				loaded = LoadConfiguration(config)
				return
			end

			if isfile then 
				if callSafely(isfile, ConfigurationFolder .. "/" .. CFileName .. ConfigurationExtension) then
					loaded = LoadConfiguration(callSafely(readfile, ConfigurationFolder .. "/" .. CFileName .. ConfigurationExtension))
				end
			else
				notified = true
				RayfieldLibrary:Notify({Title = "Rayfield Configurations", Content = "We couldn't enable Configuration Saving as you are not using software with filesystem support.", Image = 4384402990})
			end
		end)

		if success and loaded and not notified then
			RayfieldLibrary:Notify({Title = "Rayfield Configurations", Content = "The configuration file for this script has been loaded from a previous session.", Image = 4384403532})
		elseif not success and not notified then
			warn('Rayfield Configurations Error | '..tostring(result))
			RayfieldLibrary:Notify({Title = "Rayfield Configurations", Content = "We've encountered an issue loading your configuration correctly.\n\nCheck the Developer Console for more information.", Image = 4384402990})
		end
	end

	globalLoaded = true
end



if useStudio then
	-- run w/ studio
	-- Feel free to place your own script here to see how it'd work in Roblox Studio before running it on your execution software.


	--local Window = RayfieldLibrary:CreateWindow({
	--	Name = "Rayfield Example Window",
	--	LoadingTitle = "Rayfield Interface Suite",
	--	Theme = 'Default',
	--	Icon = 0,
	--	LoadingSubtitle = "by Sirius",
	--	ConfigurationSaving = {
	--		Enabled = true,
	--		FolderName = nil, -- Create a custom folder for your hub/game
	--		FileName = "Big Hub52"
	--	},
	--	Discord = {
	--		Enabled = false,
	--		Invite = "noinvitelink", -- The Discord invite code, do not include discord.gg/. E.g. discord.gg/ABCD would be ABCD
	--		RememberJoins = true -- Set this to false to make them join the discord every time they load it up
	--	},
	--	KeySystem = false, -- Set this to true to use our key system
	--	KeySettings = {
	--		Title = "Untitled",
	--		Subtitle = "Key System",
	--		Note = "No method of obtaining the key is provided",
	--		FileName = "Key", -- It is recommended to use something unique as other scripts using Rayfield may overwrite your key file
	--		SaveKey = true, -- The user's key will be saved, but if you change the key, they will be unable to use your script
	--		GrabKeyFromSite = false, -- If this is true, set Key below to the RAW site you would like Rayfield to get the key from
	--		Key = {"Hello"} -- List of keys that will be accepted by the system, can be RAW file links (pastebin, github etc) or simple strings ("hello","key22")
	--	}
	--})

	--local Tab = Window:CreateTab("Tab Example", 'key-round') -- Title, Image
	--local Tab2 = Window:CreateTab("Tab Example 2", 4483362458) -- Title, Image

	--local Section = Tab2:CreateSection("Section")


	--local ColorPicker = Tab2:CreateColorPicker({
	--	Name = "Color Picker",
	--	Color = Color3.fromRGB(255,255,255),
	--	Flag = "ColorPicfsefker1", -- A flag is the identifier for the configuration file, make sure every element has a different flag if you're using configuration saving to ensure no overlaps
	--	Callback = function(Value)
	--		-- The function that takes place every time the color picker is moved/changed
	--		-- The variable (Value) is a Color3fromRGB value based on which color is selected
	--	end
	--})

	--local Slider = Tab2:CreateSlider({
	--	Name = "Slider Example",
	--	Range = {0, 100},
	--	Increment = 10,
	--	Suffix = "Bananas",
	--	CurrentValue = 40,
	--	Flag = "Slidefefsr1", -- A flag is the identifier for the configuration file, make sure every element has a different flag if you're using configuration saving to ensure no overlaps
	--	Callback = function(Value)
	--		-- The function that takes place when the slider changes
	--		-- The variable (Value) is a number which correlates to the value the slider is currently at
	--	end,
	--})

	--local Input = Tab2:CreateInput({
	--	Name = "Input Example",
	--	CurrentValue = '',
	--	PlaceholderText = "Input Placeholder",
	--	Flag = 'dawdawd',
	--	RemoveTextAfterFocusLost = false,
	--	Callback = function(Text)
	--		-- The function that takes place when the input is changed
	--		-- The variable (Text) is a string for the value in the text box
	--	end,
	--})


	----RayfieldLibrary:Notify({Title = "Rayfield Interface", Content = "Welcome to Rayfield. These - are the brand new notification design for Rayfield, with custom sizing and Rayfield calculated wait times.", Image = 4483362458})

	--local Section = Tab:CreateSection("Section Example")

	--local Button = Tab:CreateButton({
	--	Name = "Change Theme",
	--	Callback = function()
	--		-- The function that takes place when the button is pressed
	--		Window.ModifyTheme('DarkBlue')
	--	end,
	--})

	--local Toggle = Tab:CreateToggle({
	--	Name = "Toggle Example",
	--	CurrentValue = false,
	--	Flag = "Toggle1adwawd", -- A flag is the identifier for the configuration file, make sure every element has a different flag if you're using configuration saving to ensure no overlaps
	--	Callback = function(Value)
	--		-- The function that takes place when the toggle is pressed
	--		-- The variable (Value) is a boolean on whether the toggle is true or false
	--	end,
	--})

	--local ColorPicker = Tab:CreateColorPicker({
	--	Name = "Color Picker",
	--	Color = Color3.fromRGB(255,255,255),
	--	Flag = "ColorPicker1awd", -- A flag is the identifier for the configuration file, make sure every element has a different flag if you're using configuration saving to ensure no overlaps
	--	Callback = function(Value)
	--		-- The function that takes place every time the color picker is moved/changed
	--		-- The variable (Value) is a Color3fromRGB value based on which color is selected
	--	end
	--})

	--local Slider = Tab:CreateSlider({
	--	Name = "Slider Example",
	--	Range = {0, 100},
	--	Increment = 10,
	--	Suffix = "Bananas",
	--	CurrentValue = 40,
	--	Flag = "Slider1dawd", -- A flag is the identifier for the configuration file, make sure every element has a different flag if you're using configuration saving to ensure no overlaps
	--	Callback = function(Value)
	--		-- The function that takes place when the slider changes
	--		-- The variable (Value) is a number which correlates to the value the slider is currently at
	--	end,
	--})

	--local Input = Tab:CreateInput({
	--	Name = "Input Example",
	--	CurrentValue = "Helo",
	--	PlaceholderText = "Adaptive Input",
	--	RemoveTextAfterFocusLost = false,
	--	Flag = 'Input1',
	--	Callback = function(Text)
	--		-- The function that takes place when the input is changed
	--		-- The variable (Text) is a string for the value in the text box
	--	end,
	--})

	--local thoptions = {}
	--for themename, theme in pairs(RayfieldLibrary.Theme) do
	--	table.insert(thoptions, themename)
	--end

	--local Dropdown = Tab:CreateDropdown({
	--	Name = "Theme",
	--	Options = thoptions,
	--	CurrentOption = {"Default"},
	--	MultipleOptions = false,
	--	Flag = "Dropdown1", -- A flag is the identifier for the configuration file, make sure every element has a different flag if you're using configuration saving to ensure no overlaps
	--	Callback = function(Options)
	--		--Window.ModifyTheme(Options[1])
	--		-- The function that takes place when the selected option is changed
	--		-- The variable (Options) is a table of strings for the current selected options
	--	end,
	--})


	--Window.ModifyTheme({
	--	TextColor = Color3.fromRGB(50, 55, 60),
	--	Background = Color3.fromRGB(240, 245, 250),
	--	Topbar = Color3.fromRGB(215, 225, 235),
	--	Shadow = Color3.fromRGB(200, 210, 220),

	--	NotificationBackground = Color3.fromRGB(210, 220, 230),
	--	NotificationActionsBackground = Color3.fromRGB(225, 230, 240),

	--	TabBackground = Color3.fromRGB(200, 210, 220),
	--	TabStroke = Color3.fromRGB(180, 190, 200),
	--	TabBackgroundSelected = Color3.fromRGB(175, 185, 200),
	--	TabTextColor = Color3.fromRGB(50, 55, 60),
	--	SelectedTabTextColor = Color3.fromRGB(30, 35, 40),

	--	ElementBackground = Color3.fromRGB(210, 220, 230),
	--	ElementBackgroundHover = Color3.fromRGB(220, 230, 240),
	--	SecondaryElementBackground = Color3.fromRGB(200, 210, 220),
	--	ElementStroke = Color3.fromRGB(190, 200, 210),
	--	SecondaryElementStroke = Color3.fromRGB(180, 190, 200),

	--	SliderBackground = Color3.fromRGB(200, 220, 235),  -- Lighter shade
	--	SliderProgress = Color3.fromRGB(70, 130, 180),
	--	SliderStroke = Color3.fromRGB(150, 180, 220),

	--	ToggleBackground = Color3.fromRGB(210, 220, 230),
	--	ToggleEnabled = Color3.fromRGB(70, 160, 210),
	--	ToggleDisabled = Color3.fromRGB(180, 180, 180),
	--	ToggleEnabledStroke = Color3.fromRGB(60, 150, 200),
	--	ToggleDisabledStroke = Color3.fromRGB(140, 140, 140),
	--	ToggleEnabledOuterStroke = Color3.fromRGB(100, 120, 140),
	--	ToggleDisabledOuterStroke = Color3.fromRGB(120, 120, 130),

	--	DropdownSelected = Color3.fromRGB(220, 230, 240),
	--	DropdownUnselected = Color3.fromRGB(200, 210, 220),

	--	InputBackground = Color3.fromRGB(220, 230, 240),
	--	InputStroke = Color3.fromRGB(180, 190, 200),
	--	PlaceholderColor = Color3.fromRGB(150, 150, 150)
	--})

	--local Keybind = Tab:CreateKeybind({
	--	Name = "Keybind Example",
	--	CurrentKeybind = "Q",
	--	HoldToInteract = false,
	--	Flag = "Keybind1", -- A flag is the identifier for the configuration file, make sure every element has a different flag if you're using configuration saving to ensure no overlaps
	--	Callback = function(Keybind)
	--		-- The function that takes place when the keybind is pressed
	--		-- The variable (Keybind) is a boolean for whether the keybind is being held or not (HoldToInteract needs to be true)
	--	end,
	--})

	--local Label = Tab:CreateLabel("Label Example")

	--local Label2 = Tab:CreateLabel("Warning", 4483362458, Color3.fromRGB(255, 159, 49),  true)

	--local Paragraph = Tab:CreateParagraph({Title = "Paragraph Example", Content = "Paragraph ExampleParagraph ExampleParagraph ExampleParagraph ExampleParagraph ExampleParagraph ExampleParagraph ExampleParagraph ExampleParagraph ExampleParagraph ExampleParagraph ExampleParagraph ExampleParagraph ExampleParagraph Example"})
end

if CEnabled and Main:FindFirstChild('Notice') then
	Main.Notice.BackgroundTransparency = 1
	Main.Notice.Title.TextTransparency = 1
	Main.Notice.Size = UDim2.new(0, 0, 0, 0)
	Main.Notice.Position = UDim2.new(0.5, 0, 0, -100)
	Main.Notice.Visible = true


	rfTween(Main.Notice, {Size = UDim2.new(0, 280, 0, 35), Position = UDim2.new(0.5, 0, 0, -50), BackgroundTransparency = 0.5}, "Emphasis")
	rfTween(Main.Notice.Title, {TextTransparency = 0.1}, "Emphasis")
end
-- AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA why :(
--if not useStudio then
--	task.spawn(loadWithTimeout, "https://raw.githubusercontent.com/SiriusSoftwareLtd/Sirius/refs/heads/request/boost.lua")
--end

task.delay(4, function()
	RayfieldLibrary.LoadConfiguration()
	if Main:FindFirstChild('Notice') and Main.Notice.Visible then
		rfTween(Main.Notice, {Size = UDim2.new(0, 100, 0, 25), Position = UDim2.new(0.5, 0, 0, -100), BackgroundTransparency = 1}, "Emphasis")
		rfTween(Main.Notice.Title, {TextTransparency = 1}, "Emphasis")

		task.wait(0.5)
		Main.Notice.Visible = false
	end
end)



-- SIDEBAR EXPANSION A6
local SidebarInstances = {}

function RayfieldLibrary:CreateSidebar(config, windowObj)
    config = config or {}
    if not windowObj then return end
    local zSidebar = (DesignTokensMod and DesignTokensMod.ZIndex and DesignTokensMod.ZIndex.Sidebar) or 5
    local zSidebarChrome = zSidebar + 1
    local zSidebarItem = zSidebar + 2
    local sidebarName = config.Name or 'Sidebar'
    local isCollapsed = config.Collapsed or false
    local sidebarFrame = Instance.new('Frame')
    sidebarFrame.Name = 'Sidebar_' .. sidebarName
    sidebarFrame.Size = UDim2.new(0, isCollapsed and 40 or 180, 1, 0)
    sidebarFrame.Position = UDim2.new(0, 0, 0, 0)
    sidebarFrame.BackgroundColor3 = SelectedTheme.Topbar
    sidebarFrame.BorderSizePixel = 0
    sidebarFrame.ZIndex = zSidebar
    sidebarFrame.Parent = TabList.Parent
    local sidebarStroke = Instance.new('UIStroke')
    sidebarStroke.Color = SelectedTheme.ElementStroke
    sidebarStroke.Thickness = 1
    sidebarStroke.Parent = sidebarFrame
    local title = Instance.new('TextLabel')
    title.Name = 'Title'
    title.Size = UDim2.new(1, -20, 0, 38)
    title.Position = UDim2.new(0, 12, 0, 8)
    title.BackgroundTransparency = 1
    title.Text = isCollapsed and '' or sidebarName
    title.TextColor3 = SelectedTheme.TextColor
    title.Font = Enum.Font.GothamBold
    title.TextSize = 15
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.ZIndex = zSidebarChrome
    title.Parent = sidebarFrame
    local toggleBtn = Instance.new('ImageButton')
    toggleBtn.Name = 'ToggleBtn'
    toggleBtn.Size = UDim2.new(0, 22, 0, 22)
    toggleBtn.Position = UDim2.new(1, -32, 0, 14)
    toggleBtn.BackgroundTransparency = 1
    toggleBtn.Image = isCollapsed and 'rbxassetid://11036884234' or 'rbxassetid://10137941941'
    toggleBtn.ImageColor3 = SelectedTheme.TextColor
    toggleBtn.ZIndex = zSidebarChrome
    toggleBtn.Parent = sidebarFrame
    local list = Instance.new('ScrollingFrame')
    list.Name = 'ItemList'
    list.Size = UDim2.new(1, -8, 1, -56)
    list.Position = UDim2.new(0, 8, 0, 50)
    list.BackgroundTransparency = 1
    list.ScrollBarThickness = 3
    list.CanvasSize = UDim2.new(0, 0, 0, 0)
    list.AutomaticCanvasSize = Enum.AutomaticSize.Y
    list.Visible = not isCollapsed
    list.ZIndex = zSidebarChrome
    list.Parent = sidebarFrame
    local listLayout = Instance.new('UIListLayout')
    listLayout.Padding = UDim.new(0, 2)
    listLayout.Parent = list
    local sidebarObj = {
        Frame = sidebarFrame, IsCollapsed = isCollapsed, List = list, Items = {},
        AddItem = function(self, itemConfig)
            itemConfig = itemConfig or {}
            local btn = Instance.new('TextButton')
            btn.Name = 'SItem_' .. (itemConfig.Name or 'item')
            btn.Size = UDim2.new(1, -4, 0, 34)
            btn.BackgroundColor3 = SelectedTheme.ElementBackground
            btn.BackgroundTransparency = 0
            btn.Text = itemConfig.Name or ''
            btn.Font = Enum.Font.Gotham
            btn.TextSize = 13
            btn.TextColor3 = SelectedTheme.TextColor
            btn.TextXAlignment = Enum.TextXAlignment.Left
            btn.AutoButtonColor = true
            btn.BorderSizePixel = 0
            btn.ZIndex = zSidebarItem
            btn.Parent = list
            local itemPad = Instance.new('UIPadding')
            itemPad.PaddingLeft = UDim.new(0, 14)
            itemPad.Parent = btn
            local itemCorner = Instance.new('UICorner')
            itemCorner.CornerRadius = UDim.new(0, 6)
            itemCorner.Parent = btn
            btn.MouseEnter:Connect(function() rfTween(btn, { BackgroundColor3 = SelectedTheme.ElementBackgroundHover }, 'Fast') end)
            btn.MouseLeave:Connect(function() rfTween(btn, { BackgroundColor3 = SelectedTheme.ElementBackground }, 'Fast') end)
            if itemConfig.Callback then btn.MouseButton1Click:Connect(itemConfig.Callback) end
            if itemConfig.Tab then
                btn.MouseButton1Click:Connect(function()
                    for _, tabBtn in ipairs(TabList:GetChildren()) do
                        if tabBtn:IsA('Frame') and tabBtn.Name == itemConfig.Tab then
                            local interact = tabBtn:FindFirstChild('Interact')
                            if interact then pcall(function() interact:Click() end) end
                            break
                        end
                    end
                end)
            end
            table.insert(self.Items, btn)
            return btn
        end,
        AddCategory = function(self, catConfig)
            local cat = Instance.new('TextLabel')
            cat.Name = 'SCat_' .. (catConfig.Name or 'cat')
            cat.Size = UDim2.new(1, -8, 0, 24)
            cat.BackgroundTransparency = 1
            cat.Text = catConfig.Name or ''
            cat.TextColor3 = SelectedTheme.MutedText or SelectedTheme.PlaceholderColor
            cat.Font = Enum.Font.GothamBold
            cat.TextSize = 11
            cat.TextXAlignment = Enum.TextXAlignment.Left
            cat.ZIndex = zSidebarItem
            cat.Parent = list
            local catPad = Instance.new('UIPadding')
            catPad.PaddingLeft = UDim.new(0, 10)
            catPad.Parent = cat
            if catConfig.Children then
                for _, child in ipairs(catConfig.Children) do
                    self:AddItem({ Name = child, Tab = catConfig.Tab })
                end
            end
            return cat
        end,
        Collapse = function(self)
            if self.IsCollapsed then return end
            self.IsCollapsed = true; list.Visible = false; title.Text = ''
            rfTween(sidebarFrame, { Size = UDim2.new(0, 40, 1, 0) }, 'Fast')
        end,
        Expand = function(self)
            if not self.IsCollapsed then return end
            self.IsCollapsed = false; list.Visible = true; title.Text = sidebarName
            rfTween(sidebarFrame, { Size = UDim2.new(0, 180, 1, 0) }, 'Smooth')
        end,
        Destroy = function(self) sidebarFrame:Destroy() end,
    }
    toggleBtn.MouseButton1Click:Connect(function()
        if sidebarObj.IsCollapsed then sidebarObj:Expand() else sidebarObj:Collapse() end
    end)
    table.insert(SidebarInstances, sidebarObj)
    return sidebarObj
end
function RayfieldLibrary:GetAllSidebars() return SidebarInstances end

return RayfieldLibrary
