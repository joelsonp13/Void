# -*- coding: utf-8 -*-
# Preferir migrate_tweens_v2.py (parser com chaves balanceadas). Este ficheiro mantém-se por compat.
import re

with open('source.lua', 'r', encoding='utf-8') as f:
    content = f.read()

count = 0
pattern = r'TweenService:Create\(([^,]+),\s*TweenInfo\.new\(([^)]+)\)\s*,\s*({[^}]+})\)\s*\):Play\(\)'

def custom_mapping(easing_str, dir_str):
    if 'Exponential' in easing_str and 'InOut' in dir_str:
        return 'Emphasis'
    if 'Quint' in easing_str:
        return 'Smooth'
    if 'Back' in easing_str:
        return 'Bouncy'
    if 'Elastic' in easing_str:
        return 'Elastic'
    if 'Quad' in easing_str:
        return 'Fast'
    if 'Sine' in easing_str:
        return 'Fast'
    return 'Smooth'

def replace_tween(m):
    global count
    target = m.group(1).strip()
    tween_params = m.group(2).strip()
    props = m.group(3).strip()
    count += 1
    parts = [p.strip() for p in tween_params.split(',')]
    easing = parts[1] if len(parts) > 1 else 'Enum.EasingStyle.Quint'
    direction = parts[2] if len(parts) > 2 else 'Enum.EasingDirection.Out'
    easing_name = 'Quint'
    if 'Enum.EasingStyle.' in easing:
        easing_name = easing.split('Enum.EasingStyle.')[1].split(',')[0].strip()
    direction_name = 'Out'
    if 'Enum.EasingDirection.' in direction:
        direction_name = direction.split('Enum.EasingDirection.')[1].split(',')[0].strip()
    motion = custom_mapping(easing_name, direction_name)
    if motion == 'Smooth':
        return 'rfTween(' + target + ', ' + props + ', "Smooth")'
    else:
        return 'rfTween(' + target + ', ' + props + ', "' + motion + '")'

new_content, subs = re.subn(pattern, replace_tween, content)
remaining = len(re.findall(r'TweenService:Create\(', new_content))

sidebar_code = """

-- SIDEBAR EXPANSION A6
local SidebarInstances = {}

function RayfieldLibrary:CreateSidebar(config, windowObj)
    config = config or {}
    if not windowObj then return end
    local sidebarName = config.Name or 'Sidebar'
    local isCollapsed = config.Collapsed or false
    local sidebarFrame = Instance.new('Frame')
    sidebarFrame.Name = 'Sidebar_' .. sidebarName
    sidebarFrame.Size = UDim2.new(0, isCollapsed and 40 or 180, 1, 0)
    sidebarFrame.Position = UDim2.new(0, 0, 0, 0)
    sidebarFrame.BackgroundColor3 = SelectedTheme.Topbar
    sidebarFrame.BorderSizePixel = 0
    sidebarFrame.ZIndex = 5
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
    title.ZIndex = 6
    title.Parent = sidebarFrame
    local toggleBtn = Instance.new('ImageButton')
    toggleBtn.Name = 'ToggleBtn'
    toggleBtn.Size = UDim2.new(0, 22, 0, 22)
    toggleBtn.Position = UDim2.new(1, -32, 0, 14)
    toggleBtn.BackgroundTransparency = 1
    toggleBtn.Image = isCollapsed and 'rbxassetid://11036884234' or 'rbxassetid://10137941941'
    toggleBtn.ImageColor3 = SelectedTheme.TextColor
    toggleBtn.ZIndex = 6
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
    list.ZIndex = 6
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
            btn.ZIndex = 7
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
            cat.ZIndex = 7
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
"""

insert_pos = new_content.rfind('return RayfieldLibrary')
if insert_pos > 0 and 'function RayfieldLibrary:CreateSidebar' not in new_content:
    new_content = new_content[:insert_pos] + sidebar_code + '\n' + new_content[insert_pos:]

with open('source.lua', 'w', encoding='utf-8') as f:
    f.write(new_content)

print(f"Migrated {subs} TweenService->rfTween")
print(f"Remaining: {remaining}")
print(f"A6 Sidebar added")