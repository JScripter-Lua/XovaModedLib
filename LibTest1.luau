--[[
    Vita UI Library
    Updated: Auto Scaling, Customizable Theme (Hex + Color3), Customizable Size,
             Bindable Toggle Key, Keybind Element, Notifications,
             TabImage Color, ExecutorIdentity Label,
             Unified Real-Time Theme Tracking (Heartbeat watcher),
             Built-in Icon System (name → asset lookup + custom IDs),
             Auto Text Wrapping (no text touches strokes/corners),
             Dropdown / all element color fixes -- No CoreGui
--]]

local Library = {}

-- Services (CoreGui intentionally excluded)
local Players          = game:GetService('Players')
local RunService       = game:GetService('RunService')
local UserInputService = game:GetService('UserInputService')
local TweenService     = game:GetService('TweenService')

local Mobile      = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")

------------------------------------------------------------
-- Parent Helper (no CoreGui)
------------------------------------------------------------
function Library:Parent()
    if not RunService:IsStudio() then
        return (gethui and gethui()) or PlayerGui
    end
    return PlayerGui
end

------------------------------------------------------------
-- Utilities
------------------------------------------------------------

-- Convert a hex string ("#RRGGBB" or "RRGGBB") to Color3
function Library:Hex(hex)
    hex = hex:gsub("#", "")
    local r = tonumber(hex:sub(1, 2), 16) or 0
    local g = tonumber(hex:sub(3, 4), 16) or 0
    local b = tonumber(hex:sub(5, 6), 16) or 0
    return Color3.fromRGB(r, g, b)
end

-- Internal: resolve a value that may be Color3 or a hex string
local function ResolveColor(v)
    if typeof(v) == "Color3" then return v end
    if type(v) == "string"   then return Library:Hex(v) end
    return v
end

-- Detect the executor name
local function GetExecutorName()
    if getexecutorname then
        local ok, name = pcall(getexecutorname)
        if ok and name and name ~= "" then return name end
    end
    if identifyexecutor then
        local ok, name = pcall(identifyexecutor)
        if ok and name and name ~= "" then return name end
    end
    if syn         then return "Synapse X"  end
    if KRNL_LOADED then return "KRNL"       end
    if fluxus      then return "Fluxus"     end
    if electron    then return "Electron"   end
    if robloxmouse then return "Scriptware" end
    return "Unknown Executor"
end

function Library:Create(Class, Props)
    local inst = Instance.new(Class)
    for k, v in Props do
        inst[k] = v
    end
    return inst
end

function Library:Draggable(frame)
    local dragging, dragInput, dragStart, startPos = false, nil, nil, nil
    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging  = true
            dragStart = input.Position
            startPos  = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    frame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            TweenService:Create(frame, TweenInfo.new(0.3), {
                Position = UDim2.new(
                    startPos.X.Scale, startPos.X.Offset + delta.X,
                    startPos.Y.Scale, startPos.Y.Offset + delta.Y
                )
            }):Play()
        end
    end)
end

function Library:Button(parent)
    return Library:Create("TextButton", {
        Name                   = "Click",
        Parent                 = parent,
        BackgroundColor3       = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = 1,
        BorderSizePixel        = 0,
        Size                   = UDim2.new(1, 0, 1, 0),
        Font                   = Enum.Font.SourceSans,
        Text                   = "",
        TextColor3             = Color3.fromRGB(0, 0, 0),
        TextSize               = 14,
        ZIndex                 = parent.ZIndex + 3
    })
end

function Library:Tween(info)
    return TweenService:Create(
        info.v,
        TweenInfo.new(info.t, Enum.EasingStyle[info.s], Enum.EasingDirection[info.d]),
        info.g
    )
end

function Library.Effect(c, p)
    p.ClipsDescendants = true
    local mouse = Players.LocalPlayer:GetMouse()
    local rx = mouse.X - c.AbsolutePosition.X
    local ry = mouse.Y - c.AbsolutePosition.Y
    if rx < 0 or ry < 0 or rx > c.AbsoluteSize.X or ry > c.AbsoluteSize.Y then return end
    local circle = Library:Create("Frame", {
        Parent               = p,
        BackgroundColor3     = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = 0.75,
        BorderSizePixel      = 0,
        AnchorPoint          = Vector2.new(0.5, 0.5),
        Position             = UDim2.new(0, rx, 0, ry),
        Size                 = UDim2.new(0, 0, 0, 0),
        ZIndex               = p.ZIndex
    })
    Library:Create("UICorner", { Parent = circle, CornerRadius = UDim.new(1, 0) })
    local t = TweenService:Create(circle, TweenInfo.new(2.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size                 = UDim2.new(0, c.AbsoluteSize.X * 1.5, 0, c.AbsoluteSize.X * 1.5),
        BackgroundTransparency = 1
    })
    t.Completed:Once(function() circle:Destroy() end)
    t:Play()
end

function Library:Asset(rbx)
    if typeof(rbx) == 'number' then return "rbxassetid://" .. rbx end
    if typeof(rbx) == 'string' and rbx:find('rbxassetid://') then return rbx end
    return rbx
end

------------------------------------------------------------
-- Built-in Icon System
-- Developers can pass a simple name like "eye" or "home",
-- a full "rbxassetid://..." string, or a numeric asset ID.
-- The Icons table maps "lucide-<name>" entries to asset IDs.
------------------------------------------------------------
local IconLibrary = {
    -- Navigation / UI
    ["lucide-home"]           = "rbxassetid://10709752996",
    ["lucide-arrow-left"]     = "rbxassetid://10709735148",
    ["lucide-arrow-right"]    = "rbxassetid://10709735463",
    ["lucide-chevron-down"]   = "rbxassetid://10709737130",
    ["lucide-chevron-up"]     = "rbxassetid://10709737433",
    ["lucide-menu"]           = "rbxassetid://10709751898",
    ["lucide-x"]              = "rbxassetid://10709758254",
    ["lucide-plus"]           = "rbxassetid://10709753532",
    ["lucide-minus"]          = "rbxassetid://10709752228",
    ["lucide-search"]         = "rbxassetid://10709754840",
    ["lucide-settings"]       = "rbxassetid://10709755230",
    ["lucide-sliders"]        = "rbxassetid://10709755578",
    ["lucide-layers"]         = "rbxassetid://10709751356",
    ["lucide-grid"]           = "rbxassetid://10709750454",
    ["lucide-layout"]         = "rbxassetid://10709751665",
    -- People / Social
    ["lucide-user"]           = "rbxassetid://10709754230",
    ["lucide-users"]          = "rbxassetid://10709754434",
    ["lucide-user-plus"]      = "rbxassetid://10709754091",
    ["lucide-user-x"]         = "rbxassetid://10709754129",
    -- Vision
    ["lucide-eye"]            = "rbxassetid://10723344270",
    ["lucide-eye-off"]        = "rbxassetid://10723344463",
    -- Communication
    ["lucide-message-circle"] = "rbxassetid://10709752018",
    ["lucide-message-square"] = "rbxassetid://10709752120",
    ["lucide-bell"]           = "rbxassetid://10709736332",
    ["lucide-bell-off"]       = "rbxassetid://10709736519",
    ["lucide-mail"]           = "rbxassetid://10709751777",
    -- Files / Folders
    ["lucide-folder"]         = "rbxassetid://10709749852",
    ["lucide-folder-open"]    = "rbxassetid://10709749929",
    ["lucide-file"]           = "rbxassetid://10709749378",
    ["lucide-file-text"]      = "rbxassetid://10709749527",
    ["lucide-copy"]           = "rbxassetid://10709738399",
    ["lucide-trash"]          = "rbxassetid://10709756296",
    ["lucide-trash-2"]        = "rbxassetid://10709756404",
    -- Misc / Utility
    ["lucide-star"]           = "rbxassetid://10709756067",
    ["lucide-heart"]          = "rbxassetid://10709750667",
    ["lucide-flag"]           = "rbxassetid://10709749727",
    ["lucide-map-pin"]        = "rbxassetid://10709751892",
    ["lucide-tag"]            = "rbxassetid://10709756120",
    ["lucide-lock"]           = "rbxassetid://10709751726",
    ["lucide-unlock"]         = "rbxassetid://10709756604",
    ["lucide-key"]            = "rbxassetid://10709751065",
    ["lucide-shield"]         = "rbxassetid://10709755332",
    ["lucide-shield-check"]   = "rbxassetid://10709755459",
    ["lucide-alert-triangle"] = "rbxassetid://10709735017",
    ["lucide-alert-circle"]   = "rbxassetid://10709734881",
    ["lucide-info"]           = "rbxassetid://10709750965",
    ["lucide-check"]          = "rbxassetid://10709737010",
    ["lucide-check-circle"]   = "rbxassetid://10709736861",
    ["lucide-zap"]            = "rbxassetid://10709758463",
    ["lucide-flame"]          = "rbxassetid://10709749776",
    ["lucide-cpu"]            = "rbxassetid://10709738531",
    ["lucide-globe"]          = "rbxassetid://10709750194",
    ["lucide-link"]           = "rbxassetid://10709751587",
    ["lucide-map"]            = "rbxassetid://10709751848",
    ["lucide-camera"]         = "rbxassetid://10709737614",
    ["lucide-image"]          = "rbxassetid://10709750819",
    ["lucide-music"]          = "rbxassetid://10709752408",
    ["lucide-volume-2"]       = "rbxassetid://10709757078",
    ["lucide-volume-x"]       = "rbxassetid://10709757178",
    ["lucide-play"]           = "rbxassetid://10709753399",
    ["lucide-pause"]          = "rbxassetid://10709753205",
    ["lucide-stop-circle"]    = "rbxassetid://10709755997",
    ["lucide-refresh-cw"]     = "rbxassetid://10709753844",
    ["lucide-download"]       = "rbxassetid://10709739018",
    ["lucide-upload"]         = "rbxassetid://10709756670",
    ["lucide-external-link"]  = "rbxassetid://10709739155",
    ["lucide-maximize"]       = "rbxassetid://10709751943",
    ["lucide-minimize"]       = "rbxassetid://10709752181",
    ["lucide-log-out"]        = "rbxassetid://10709751730",
    ["lucide-log-in"]         = "rbxassetid://10709751672",
    ["lucide-power"]          = "rbxassetid://10709753612",
    ["lucide-sun"]            = "rbxassetid://10709756119",
    ["lucide-moon"]           = "rbxassetid://10709752284",
    ["lucide-cloud"]          = "rbxassetid://10709738211",
    ["lucide-package"]        = "rbxassetid://10709753103",
    ["lucide-tool"]           = "rbxassetid://10709756219",
    ["lucide-toggle-left"]    = "rbxassetid://10709756145",
    ["lucide-toggle-right"]   = "rbxassetid://10709756196",
    ["lucide-gamepad"]        = "rbxassetid://10709750091",
    ["lucide-sword"]          = "rbxassetid://10709756061",
    ["lucide-target"]         = "rbxassetid://10709756157",
    ["lucide-crosshair"]      = "rbxassetid://10709738607",
    ["lucide-activity"]       = "rbxassetid://10709734746",
    ["lucide-dollar-sign"]    = "rbxassetid://10709739058",
    ["lucide-clock"]          = "rbxassetid://10709738144",
    ["lucide-calendar"]       = "rbxassetid://10709737538",
    ["lucide-code"]           = "rbxassetid://10709738277",
    ["lucide-terminal"]       = "rbxassetid://10709756195",
    ["lucide-bar-chart"]      = "rbxassetid://10709736170",
    ["lucide-pie-chart"]      = "rbxassetid://10709753285",
    ["lucide-trending-up"]    = "rbxassetid://10709756440",
    ["lucide-trending-down"]  = "rbxassetid://10709756374",
    ["lucide-edit"]           = "rbxassetid://10709739066",
    ["lucide-edit-2"]         = "rbxassetid://10709739096",
    ["lucide-pen"]            = "rbxassetid://10709753252",
    ["lucide-scissors"]       = "rbxassetid://10709754693",
    ["lucide-paperclip"]      = "rbxassetid://10709753141",
    ["lucide-bookmark"]       = "rbxassetid://10709736626",
    ["lucide-gift"]           = "rbxassetid://10709750063",
    ["lucide-wifi"]           = "rbxassetid://10709757307",
    ["lucide-wifi-off"]       = "rbxassetid://10709757402",
    ["lucide-bluetooth"]      = "rbxassetid://10709736768",
    ["lucide-battery"]        = "rbxassetid://10709736218",
    ["lucide-loader"]         = "rbxassetid://10709751690",
    ["lucide-more-horizontal"] = "rbxassetid://10709752315",
    ["lucide-more-vertical"]  = "rbxassetid://10709752355",
}

--[[
    ResolveIcon(iconName) - resolves a name/string to a Roblox asset ID string.

    Logic order (exact spec):
      1. IconLibrary["lucide-" .. iconName]  - "eye" becomes "lucide-eye" lookup
      2. IconLibrary[iconName]               - exact key, e.g. "lucide-home"
      3. string already contains "rbxassetid://" - returned as-is (custom IDs)
      4. nil                                 - no match, caller hides the element

    Usage examples:
        ResolveIcon("eye")                     -- "rbxassetid://10723344270"
        ResolveIcon("lucide-home")             -- "rbxassetid://10709752996"
        ResolveIcon("rbxassetid://1234567890") -- "rbxassetid://1234567890"
        ResolveIcon("unknown")                 -- nil
        ResolveIcon(nil)                       -- nil
--]]
local function ResolveIcon(iconName)
    if not iconName then return nil end
    local n = tostring(iconName)

    -- 1. Lucide prefix shorthand: "eye" -> "lucide-eye"
    if IconLibrary["lucide-" .. n] then
        return IconLibrary["lucide-" .. n]
    end

    -- 2. Exact key: "lucide-home" or any explicit table key
    if IconLibrary[n] then
        return IconLibrary[n]
    end

    -- 3. Direct rbxassetid:// string - pass through unchanged
    if string.find(n, "rbxassetid://") then
        return n
    end

    -- 4. No match -> nil (callers must guard: if iconId then ... end)
    return nil
end

-- Public API: Library:ResolveIcon("eye") and Library:GetIcon("eye") both work
function Library:ResolveIcon(iconName) return ResolveIcon(iconName) end
function Library:GetIcon(iconName)     return ResolveIcon(iconName) end

-- NewRows now accepts a Theme table (T), optional track function, and optional icon (resolved asset string)
-- icon param: pass ResolveIcon(Args.Icon) — if nil, no icon is shown (backward compatible)
function Library:NewRows(parent, title, desc, T, trackFn, icon)
    local tr = trackFn or function() end

    local Rows = Library:Create("Frame", {
        Name             = "Rows",
        Parent           = parent,
        BackgroundColor3 = T.Row,
        BorderSizePixel  = 0,
        AutomaticSize    = Enum.AutomaticSize.Y,
        Size             = UDim2.new(1, 0, 0, 0)
    })
    tr("Row", Rows, "BackgroundColor3")
    Library:Create("UIStroke",  { Parent = Rows, Color = T.Stroke, Thickness = 0.5 })
    tr("Stroke", Rows:FindFirstChildOfClass("UIStroke"), "Color")
    Library:Create("UICorner",  { Parent = Rows, CornerRadius = UDim.new(0, 3) })
    Library:Create("UIListLayout", {
        Parent             = Rows,
        Padding            = UDim.new(0, 6),
        FillDirection      = Enum.FillDirection.Horizontal,
        SortOrder          = Enum.SortOrder.LayoutOrder,
        VerticalAlignment  = Enum.VerticalAlignment.Center
    })
    Library:Create("UIPadding", {
        Parent        = Rows,
        PaddingBottom = UDim.new(0, 8),
        PaddingTop    = UDim.new(0, 8),
        PaddingLeft   = UDim.new(0, 0),
        PaddingRight  = UDim.new(0, 0)
    })

    local Vec = Library:Create("Frame", {
        Name                   = "Vectorize",
        Parent                 = Rows,
        BackgroundTransparency = 1,
        BorderSizePixel        = 0,
        AutomaticSize          = Enum.AutomaticSize.Y,
        Size                   = UDim2.new(1, 0, 0, 0)
    })
    Library:Create("UIPadding", {
        Parent       = Vec,
        PaddingLeft  = UDim.new(0, 10),
        PaddingRight = UDim.new(0, 10)
    })

    local Right = Library:Create("Frame", {
        Name                   = "Right",
        Parent                 = Vec,
        BackgroundTransparency = 1,
        BorderSizePixel        = 0,
        Size                   = UDim2.new(1, 0, 1, 0)
    })
    Library:Create("UIListLayout", {
        Parent               = Right,
        HorizontalAlignment  = Enum.HorizontalAlignment.Right,
        SortOrder            = Enum.SortOrder.LayoutOrder,
        VerticalAlignment    = Enum.VerticalAlignment.Center
    })

    -- Left: when an icon is provided, it uses a horizontal layout so the
    -- icon sits to the left of the title/desc text block.
    local Left = Library:Create("Frame", {
        Name                   = "Left",
        Parent                 = Vec,
        BackgroundTransparency = 1,
        BorderSizePixel        = 0,
        AutomaticSize          = Enum.AutomaticSize.Y,
        Size                   = UDim2.new(1, 0, 0, 0)
    })

    -- Row icon (optional) ─────────────────────────────────────────────
    -- Rendered when the caller passes a resolved asset string.
    -- Adds a horizontal UIListLayout to Left so icon + Text sit side-by-side.
    if icon then
        Library:Create("UIListLayout", {
            Parent            = Left,
            FillDirection     = Enum.FillDirection.Horizontal,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            SortOrder         = Enum.SortOrder.LayoutOrder,
            Padding           = UDim.new(0, 8)
        })
        local RowIcon = Library:Create("ImageLabel", {
            Name                   = "RowIcon",
            Parent                 = Left,
            BackgroundTransparency = 1,
            BorderSizePixel        = 0,
            LayoutOrder            = -10,
            Size                   = UDim2.new(0, 16, 0, 16),
            Image                  = icon,
            ImageColor3            = T.Accent
        })
        tr("Accent", RowIcon, "ImageColor3")
        Library:Create("UIGradient", {
            Parent   = RowIcon,
            Color    = ColorSequence.new{
                ColorSequenceKeypoint.new(0,    Color3.fromRGB(255, 255, 255)),
                ColorSequenceKeypoint.new(0.75, T.SubText),
                ColorSequenceKeypoint.new(1,    Color3.fromRGB(100, 100, 100))
            },
            Rotation = 90
        })
    end
    -- ─────────────────────────────────────────────────────────────────

    local Text = Library:Create("Frame", {
        Name                   = "Text",
        Parent                 = Left,
        BackgroundTransparency = 1,
        BorderSizePixel        = 0,
        AutomaticSize          = Enum.AutomaticSize.Y,
        Size                   = UDim2.new(1, 0, 0, 0)
    })
    Library:Create("UIListLayout", {
        Parent              = Text,
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        SortOrder           = Enum.SortOrder.LayoutOrder,
        VerticalAlignment   = Enum.VerticalAlignment.Center,
        Padding             = UDim.new(0, 2)
    })

    local TitleLbl = Library:Create("TextLabel", {
        Name                   = "Title",
        Parent                 = Text,
        BackgroundTransparency = 1,
        BorderSizePixel        = 0,
        LayoutOrder            = -1,
        Size                   = UDim2.new(1, 0, 0, 0),
        AutomaticSize          = Enum.AutomaticSize.Y,
        Font                   = Enum.Font.GothamSemibold,
        RichText               = true,
        Text                   = title,
        TextColor3             = T.Text,
        TextSize               = 12,
        TextStrokeTransparency = 0.7,
        TextWrapped            = true,
        TextXAlignment         = Enum.TextXAlignment.Left,
        TextYAlignment         = Enum.TextYAlignment.Top
    })
    tr("Text", TitleLbl, "TextColor3")
    Library:Create("UIGradient", {
        Parent   = TitleLbl,
        Color    = ColorSequence.new{
            ColorSequenceKeypoint.new(0,    Color3.fromRGB(255, 255, 255)),
            ColorSequenceKeypoint.new(0.75, T.SubText),
            ColorSequenceKeypoint.new(1,    Color3.fromRGB(100, 100, 100))
        },
        Rotation = 90
    })

    local DescLbl = Library:Create("TextLabel", {
        Name                   = "Desc",
        Parent                 = Text,
        BackgroundTransparency = 1,
        BorderSizePixel        = 0,
        Size                   = UDim2.new(1, 0, 0, 0),
        AutomaticSize          = Enum.AutomaticSize.Y,
        Font                   = Enum.Font.GothamMedium,
        RichText               = true,
        Text                   = desc or "",
        TextColor3             = T.Text,
        TextSize               = 10,
        TextStrokeTransparency = 0.7,
        TextTransparency       = 0.6,
        TextWrapped            = true,
        TextXAlignment         = Enum.TextXAlignment.Left,
        TextYAlignment         = Enum.TextYAlignment.Top
    })
    tr("Text", DescLbl, "TextColor3")

    return Rows
end

------------------------------------------------------------
-- Notification System (module-level, no CoreGui)
------------------------------------------------------------
local NotifGui = Library:Create("ScreenGui", {
    Name             = "VitaNotifications",
    Parent           = Library:Parent(),
    ZIndexBehavior   = Enum.ZIndexBehavior.Global,
    IgnoreGuiInset   = true,
    ResetOnSpawn     = false
})

local NotifHolder = Library:Create("Frame", {
    Name                   = "Holder",
    Parent                 = NotifGui,
    BackgroundTransparency = 1,
    AnchorPoint            = Vector2.new(1, 1),
    Position               = UDim2.new(1, -15, 1, -15),
    Size                   = UDim2.new(0, 270, 1, -30)
})
Library:Create("UIListLayout", {
    Parent            = NotifHolder,
    VerticalAlignment = Enum.VerticalAlignment.Bottom,
    SortOrder         = Enum.SortOrder.LayoutOrder,
    Padding           = UDim.new(0, 8),
    FillDirection     = Enum.FillDirection.Vertical
})

--[[
    Library:Notification(Args)
    Args:
        Title    (string)  - Notification title
        Desc     (string)  - Notification description
        Duration (number)  - Seconds to show (default 3)
        Type     (string)  - "Info" | "Success" | "Warning" | "Error"
--]]
function Library:Notification(Args)
    local Title    = Args.Title    or "Notification"
    local Desc     = Args.Desc     or ""
    local Duration = Args.Duration or 3
    local Type     = Args.Type     or "Info"

    local typeColors = {
        Info    = Color3.fromRGB(100, 149, 237),
        Success = Color3.fromRGB(50,  200, 100),
        Warning = Color3.fromRGB(255, 165, 0),
        Error   = Color3.fromRGB(220, 50,  50),
    }
    local accentColor = typeColors[Type] or typeColors.Info

    local Notif = Library:Create("Frame", {
        Name             = "Notification",
        Parent           = NotifHolder,
        BackgroundColor3 = Color3.fromRGB(13, 13, 13),
        BorderSizePixel  = 0,
        Size             = UDim2.new(1, 0, 0, 0),
        AutomaticSize    = Enum.AutomaticSize.Y,
        ClipsDescendants = false,
        BackgroundTransparency = 1,
    })
    Library:Create("UICorner", { Parent = Notif, CornerRadius = UDim.new(0, 6) })
    Library:Create("UIStroke", { Parent = Notif, Color = Color3.fromRGB(30, 30, 30), Thickness = 0.5 })

    -- Colored left bar
    local Bar = Library:Create("Frame", {
        Parent           = Notif,
        BackgroundColor3 = accentColor,
        BorderSizePixel  = 0,
        Size             = UDim2.new(0, 3, 1, 0),
    })
    Library:Create("UICorner", { Parent = Bar, CornerRadius = UDim.new(0, 2) })

    local Content = Library:Create("Frame", {
        Parent                 = Notif,
        BackgroundTransparency = 1,
        Position               = UDim2.new(0, 12, 0, 0),
        Size                   = UDim2.new(1, -12, 1, 0),
        AutomaticSize          = Enum.AutomaticSize.Y,
    })
    Library:Create("UIPadding", {
        Parent        = Content,
        PaddingTop    = UDim.new(0, 10),
        PaddingBottom = UDim.new(0, 10),
        PaddingRight  = UDim.new(0, 10)
    })
    Library:Create("UIListLayout", {
        Parent    = Content,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding   = UDim.new(0, 4)
    })

    Library:Create("TextLabel", {
        Parent                 = Content,
        BackgroundTransparency = 1,
        BorderSizePixel        = 0,
        Size                   = UDim2.new(1, 0, 0, 14),
        Font                   = Enum.Font.GothamBold,
        Text                   = Title,
        TextColor3             = accentColor,
        TextSize               = 13,
        TextXAlignment         = Enum.TextXAlignment.Left,
        RichText               = true
    })
    Library:Create("TextLabel", {
        Parent                 = Content,
        BackgroundTransparency = 1,
        BorderSizePixel        = 0,
        AutomaticSize          = Enum.AutomaticSize.Y,
        Size                   = UDim2.new(1, 0, 0, 0),
        Font                   = Enum.Font.GothamMedium,
        Text                   = Desc,
        TextColor3             = Color3.fromRGB(200, 200, 200),
        TextSize               = 11,
        TextTransparency       = 0.2,
        TextXAlignment         = Enum.TextXAlignment.Left,
        TextWrapped            = true,
        RichText               = true
    })

    -- Progress bar
    local ProgBg = Library:Create("Frame", {
        Parent           = Content,
        BackgroundColor3 = Color3.fromRGB(30, 30, 30),
        BorderSizePixel  = 0,
        Size             = UDim2.new(1, 0, 0, 2),
    })
    Library:Create("UICorner", { Parent = ProgBg, CornerRadius = UDim.new(1, 0) })
    local ProgFill = Library:Create("Frame", {
        Parent           = ProgBg,
        BackgroundColor3 = accentColor,
        BorderSizePixel  = 0,
        Size             = UDim2.new(1, 0, 1, 0),
    })
    Library:Create("UICorner", { Parent = ProgFill, CornerRadius = UDim.new(1, 0) })

    -- Animate in
    TweenService:Create(Notif, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        BackgroundTransparency = 0
    }):Play()
    TweenService:Create(ProgFill, TweenInfo.new(Duration, Enum.EasingStyle.Linear, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 0, 1, 0)
    }):Play()

    task.delay(Duration, function()
        TweenService:Create(Notif, TweenInfo.new(0.3), { BackgroundTransparency = 1 }):Play()
        task.wait(0.35)
        Notif:Destroy()
    end)

    return Notif
end

------------------------------------------------------------
-- Window
------------------------------------------------------------
--[[
    Library:Window(Args)
    Args:
        Title             (string)         - Window title
        SubTitle          (string)         - Subtitle text
        Size              (UDim2)          - Custom window size (optional)
        ToggleKey         (Enum.KeyCode)   - Key to show/hide window (default LeftControl)
        AutoScale         (bool)           - Auto-scale to screen size (default true)
        Scale             (number)         - Base scale multiplier (default 1.45)
        ExecIdentifyShown (bool)           - Show executor name label bottom-right (default true)
        Theme             (table)          - Color overrides — accepts Color3 OR hex strings like "#FF007F"

    Theme fields (all optional, Color3 or "#RRGGBB"):
        Accent     - Main accent / highlight color   (default: hot pink)
        Background - Window background               (default: near-black)
        Row        - Element row background          (default: dark gray)
        RowAlt     - Toggle-off / keybind bg         (default: darker gray)
        Stroke     - Border stroke color             (default: very dark gray)
        Text       - Primary text color              (default: white)
        SubText    - Gradient / secondary text       (default: light gray)
        TabBg      - Tab card background             (default: very dark)
        TabStroke  - Tab card border color           (default: dark maroon)
        TabImage   - Tab card banner image tint      (default: same as Accent)
        DropBg     - Dropdown popup background       (default: near-black)
        DropStroke - Dropdown popup border           (default: dark gray)
        PillBg     - Toggle pill button background   (default: near-black)

    Shorthand setters (all accept Color3 or hex string):
        BG       = "#0D0D0D"   -- sets Background
        Tab      = "#0A0A0A"   -- sets TabBg
        TabImage = "#FF007F"   -- sets TabImage tint

    Icon system — ResolveIcon(name) logic (exact order):
        1. IconLibrary["lucide-" .. name]   -- "eye"    -> lucide-eye asset
        2. IconLibrary[name]                -- "lucide-shield" exact key
        3. string.find(name,"rbxassetid://") -- direct asset, returned as-is
        4. nil                              -- no match, element hidden

    Supported on every element via Args.Icon:
        NewPage    { Icon = "eye" }         -- tab card icon
        Section    { Text="X", Icon="eye" } -- heading icon  (or plain string)
        Toggle     { Icon = "eye" }         -- row left icon
        Button     { Icon = "eye" }         -- row left icon  +  button pill icon
        Dropdown   { Icon = "eye" }         -- row left icon
        Keybind    { Icon = "key" }         -- row left icon
        Paragraph  { Image = "info" }       -- right-side decorative icon
                   { RowIcon = "eye" }      -- row left icon (Paragraph-specific)

    Public API:
        Library:ResolveIcon("eye")          -- "rbxassetid://10723344270"
        Library:GetIcon("eye")              -- alias for ResolveIcon
--]]
function Library:Window(Args)
    local Title             = Args.Title     or "Vita UI"
    local SubTitle          = Args.SubTitle  or "Made by vita6it"
    local ToggleKey         = Args.ToggleKey or Enum.KeyCode.LeftControl
    local AutoScale         = Args.AutoScale ~= false
    local BaseScale         = Args.Scale     or 1.45
    local CustomSize        = Args.Size
    local ExecIdentifyShown = Args.ExecIdentifyShown ~= false  -- default true

    -- Build theme — resolve every value: accepts Color3 or "#RRGGBB" hex strings
    -- Also support shorthand keys: BG → Background, Tab → TabBg, TabImage → TabImage, TabStroke → TabStroke
    local uT = Args.Theme or {}

    -- Apply shorthands from top-level Args (e.g. Args.BG, Args.Tab, Args.TabImage, Args.TabStroke)
    if Args.BG        then uT.Background = Args.BG        end
    if Args.Tab       then uT.TabBg      = Args.Tab       end
    if Args.TabImage  then uT.TabImage   = Args.TabImage  end
    if Args.TabStroke then uT.TabStroke  = Args.TabStroke end

    local T = {
        Accent     = ResolveColor(uT.Accent     or Color3.fromRGB(255, 0, 127)),
        Background = ResolveColor(uT.Background or Color3.fromRGB(11, 11, 11)),
        Row        = ResolveColor(uT.Row        or Color3.fromRGB(15, 15, 15)),
        RowAlt     = ResolveColor(uT.RowAlt     or Color3.fromRGB(10, 10, 10)),
        Stroke     = ResolveColor(uT.Stroke     or Color3.fromRGB(25, 25, 25)),
        Text       = ResolveColor(uT.Text       or Color3.fromRGB(255, 255, 255)),
        SubText    = ResolveColor(uT.SubText    or Color3.fromRGB(163, 163, 163)),
        TabBg      = ResolveColor(uT.TabBg      or Color3.fromRGB(10, 10, 10)),
        TabStroke  = ResolveColor(uT.TabStroke  or Color3.fromRGB(75, 0, 38)),
        TabImage   = ResolveColor(uT.TabImage   or uT.Accent or Color3.fromRGB(255, 0, 127)),
        DropBg     = ResolveColor(uT.DropBg     or Color3.fromRGB(18, 18, 18)),
        DropStroke = ResolveColor(uT.DropStroke or Color3.fromRGB(30, 30, 30)),
        PillBg     = ResolveColor(uT.PillBg     or Color3.fromRGB(11, 11, 11)),
    }

    ----------------------------------------------------------------
    -- Unified Theme Tracking
    -- _refs[themeKey] = { {instance, property}, ... }
    -- track(key, inst, prop) → registers inst[prop] to update when T[key] changes
    ----------------------------------------------------------------
    local _refs = {}
    local function track(key, inst, prop)
        if not _refs[key] then _refs[key] = {} end
        table.insert(_refs[key], {inst, prop})
        return inst
    end

    -- Convenience aliases used throughout the code
    local function trackAccent(inst, prop)    return track("Accent",     inst, prop) end
    local function trackBg(inst, prop)        return track("Background", inst, prop) end
    local function trackTabImage(inst, prop)  return track("TabImage",   inst, prop) end
    local function trackTabBg(inst, prop)     return track("TabBg",      inst, prop) end
    local function trackTabStroke(inst, prop) return track("TabStroke",  inst, prop) end

    ----------------------------------------------------------------
    -- Real-Time Theme Watcher
    -- Snapshots T every frame; if any key changed externally (e.g. T.Accent = ...)
    -- it automatically flushes all tracked refs for that key.
    ----------------------------------------------------------------
    local _prevT = {}
    for k, v in pairs(T) do _prevT[k] = v end

    local function _flushKey(key)
        if not _refs[key] then return end
        local color = T[key]
        for i = #_refs[key], 1, -1 do
            local ref = _refs[key][i]
            local inst, prop = ref[1], ref[2]
            if inst and inst.Parent then
                pcall(function() inst[prop] = color end)
            else
                table.remove(_refs[key], i)  -- prune destroyed instances
            end
        end
    end

    RunService.Heartbeat:Connect(function()
        for k, v in pairs(T) do
            if _prevT[k] ~= v then
                _prevT[k] = v
                _flushKey(k)
            end
        end
    end)

    -- Main ScreenGui (no CoreGui)
    local Xova = Library:Create("ScreenGui", {
        Name           = "Xova",
        Parent         = Library:Parent(),
        ZIndexBehavior = Enum.ZIndexBehavior.Global,
        IgnoreGuiInset = true,
        ResetOnSpawn   = false
    })

    -- Background frame
    local Background = Library:Create("Frame", {
        Name             = "Background",
        Parent           = Xova,
        AnchorPoint      = Vector2.new(0.5, 0.5),
        BackgroundColor3 = T.Background,
        BorderSizePixel  = 0,
        Position         = UDim2.new(0.5, 0, 0.5, 0),
        Size             = CustomSize or UDim2.new(0, 500, 0, 350)
    })
    trackBg(Background, "BackgroundColor3")
    Library:Create("UICorner", { Parent = Background })
    Library:Create("ImageLabel", {
        Name                 = "Shadow",
        Parent               = Background,
        AnchorPoint          = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        BorderSizePixel      = 0,
        Position             = UDim2.new(0.5, 0, 0.5, 0),
        Size                 = UDim2.new(1, 120, 1, 120),
        ZIndex               = 0,
        Image                = "rbxassetid://8992230677",
        ImageColor3          = Color3.fromRGB(0, 0, 0),
        ImageTransparency    = 0.5,
        ScaleType            = Enum.ScaleType.Slice,
        SliceCenter          = Rect.new(99, 99, 99, 99)
    })

    function Library:IsDropdownOpen()
        for _, v in pairs(Background:GetChildren()) do
            if v.Name == "Dropdown" and v.Visible then return true end
        end
        return false
    end

    -- Header
    local Header = Library:Create("Frame", {
        Name                   = "Header",
        Parent                 = Background,
        BackgroundTransparency = 1,
        BorderSizePixel        = 0,
        Size                   = UDim2.new(1, 0, 0, 40)
    })

    local ReturnBtn = Library:Create("ImageLabel", {
        Name                   = "Return",
        Parent                 = Header,
        AnchorPoint            = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        BorderSizePixel        = 0,
        Position               = UDim2.new(0, 25, 0.5, 1),
        Size                   = UDim2.new(0, 27, 0, 27),
        Image                  = "rbxassetid://130391877219356",
        ImageColor3            = T.Accent,
        Visible                = false
    })
    trackAccent(ReturnBtn, "ImageColor3")
    Library:Create("UIGradient", {
        Parent   = ReturnBtn,
        Rotation = 90,
        Color    = ColorSequence.new{
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(56,  56,  56))
        }
    })

    local HeadScale = Library:Create("Frame", {
        Name                   = "HeadScale",
        Parent                 = Header,
        AnchorPoint            = Vector2.new(1, 0),
        BackgroundTransparency = 1,
        BorderSizePixel        = 0,
        Position               = UDim2.new(1, 0, 0, 0),
        Size                   = UDim2.new(1, 0, 1, 0)
    })
    Library:Create("UIListLayout", {
        Parent            = HeadScale,
        FillDirection     = Enum.FillDirection.Horizontal,
        SortOrder         = Enum.SortOrder.LayoutOrder,
        VerticalAlignment = Enum.VerticalAlignment.Center
    })
    Library:Create("UIPadding", {
        Parent        = HeadScale,
        PaddingBottom = UDim.new(0, 15),
        PaddingLeft   = UDim.new(0, 15),
        PaddingRight  = UDim.new(0, 15),
        PaddingTop    = UDim.new(0, 20)
    })

    -- Title + subtitle info
    local Info = Library:Create("Frame", {
        Name                   = "Info",
        Parent                 = HeadScale,
        BackgroundTransparency = 1,
        BorderSizePixel        = 0,
        Size                   = UDim2.new(1, -100, 0, 28)
    })
    Library:Create("UIListLayout", {
        Parent              = Info,
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        SortOrder           = Enum.SortOrder.LayoutOrder
    })

    local TitleLabel = Library:Create("TextLabel", {
        Name                   = "Title",
        Parent                 = Info,
        AnchorPoint            = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        BorderSizePixel        = 0,
        Position               = UDim2.new(0.5, 0, 0.5, 0),
        Size                   = UDim2.new(1, 0, 0, 14),
        Font                   = Enum.Font.GothamBold,
        RichText               = true,
        Text                   = Title,
        TextColor3             = T.Accent,
        TextSize               = 14,
        TextStrokeTransparency = 0.7,
        TextXAlignment         = Enum.TextXAlignment.Left
    })
    trackAccent(TitleLabel, "TextColor3")
    Library:Create("UIGradient", {
        Parent   = TitleLabel,
        Color    = ColorSequence.new{
            ColorSequenceKeypoint.new(0,    Color3.fromRGB(255, 255, 255)),
            ColorSequenceKeypoint.new(0.75, T.SubText),
            ColorSequenceKeypoint.new(1,    Color3.fromRGB(100, 100, 100))
        },
        Rotation = 90
    })

    Library:Create("TextLabel", {
        Name                   = "SubTitle",
        Parent                 = Info,
        AnchorPoint            = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        BorderSizePixel        = 0,
        Position               = UDim2.new(0.5, 0, 0.5, 0),
        Size                   = UDim2.new(1, 0, 0, 10),
        Font                   = Enum.Font.GothamMedium,
        RichText               = true,
        Text                   = SubTitle,
        TextColor3             = T.Text,
        TextSize               = 10,
        TextStrokeTransparency = 0.7,
        TextTransparency       = 0.6,
        TextXAlignment         = Enum.TextXAlignment.Left
    })

    -- Expires section
    local Expires = Library:Create("Frame", {
        Name                   = "Expires",
        Parent                 = HeadScale,
        BackgroundTransparency = 1,
        BorderSizePixel        = 0,
        Position               = UDim2.new(0.787, 0, -3.5, 0),
        Size                   = UDim2.new(0, 100, 0, 40)
    })
    Library:Create("UIListLayout", {
        Parent              = Expires,
        Padding             = UDim.new(0, 10),
        FillDirection       = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        SortOrder           = Enum.SortOrder.LayoutOrder,
        VerticalAlignment   = Enum.VerticalAlignment.Center
    })

    local ExpiresIcon = Library:Create("ImageLabel", {
        Name                   = "Asset",
        Parent                 = Expires,
        BackgroundTransparency = 1,
        BorderSizePixel        = 0,
        Size                   = UDim2.new(0, 20, 0, 20),
        Image                  = "rbxassetid://100865348188048",
        ImageColor3            = T.Accent,
        LayoutOrder            = 1
    })
    trackAccent(ExpiresIcon, "ImageColor3")
    Library:Create("UIGradient", {
        Parent   = ExpiresIcon,
        Color    = ColorSequence.new{
            ColorSequenceKeypoint.new(0,    Color3.fromRGB(255, 255, 255)),
            ColorSequenceKeypoint.new(0.75, T.SubText),
            ColorSequenceKeypoint.new(1,    Color3.fromRGB(100, 100, 100))
        },
        Rotation = 90
    })

    local ExpiresInfo = Library:Create("Frame", {
        Name                   = "Info",
        Parent                 = Expires,
        AnchorPoint            = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        BorderSizePixel        = 0,
        Position               = UDim2.new(0.5, 0, 0.5, 0),
        Size                   = UDim2.new(1, 0, 0, 28)
    })
    Library:Create("UIListLayout", {
        Parent              = ExpiresInfo,
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        SortOrder           = Enum.SortOrder.LayoutOrder
    })

    local ExpiresTitle = Library:Create("TextLabel", {
        Name                   = "Title",
        Parent                 = ExpiresInfo,
        AnchorPoint            = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        BorderSizePixel        = 0,
        Position               = UDim2.new(0.5, 0, 0.5, 0),
        Size                   = UDim2.new(1, 0, 0, 14),
        Font                   = Enum.Font.GothamSemibold,
        RichText               = true,
        Text                   = "Expires at",
        TextColor3             = T.Accent,
        TextSize               = 13,
        TextStrokeTransparency = 0.7,
        TextXAlignment         = Enum.TextXAlignment.Right
    })
    trackAccent(ExpiresTitle, "TextColor3")
    Library:Create("UIGradient", {
        Parent   = ExpiresTitle,
        Color    = ColorSequence.new{
            ColorSequenceKeypoint.new(0,    Color3.fromRGB(255, 255, 255)),
            ColorSequenceKeypoint.new(0.75, T.SubText),
            ColorSequenceKeypoint.new(1,    Color3.fromRGB(100, 100, 100))
        },
        Rotation = 90
    })

    local THETIME = Library:Create("TextLabel", {
        Name                   = "Time",
        Parent                 = ExpiresInfo,
        AnchorPoint            = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        BorderSizePixel        = 0,
        Position               = UDim2.new(0.5, 0, 0.5, 0),
        Size                   = UDim2.new(1, 0, 0, 10),
        Font                   = Enum.Font.GothamMedium,
        RichText               = true,
        Text                   = "00:00:00 Hours",
        TextColor3             = T.Text,
        TextSize               = 10,
        TextStrokeTransparency = 0.7,
        TextTransparency       = 0.6,
        TextXAlignment         = Enum.TextXAlignment.Right
    })

    -- Body
    local Scale = Library:Create("Frame", {
        Name                   = "Scale",
        Parent                 = Background,
        AnchorPoint            = Vector2.new(0, 1),
        BackgroundTransparency = 1,
        BorderSizePixel        = 0,
        Position               = UDim2.new(0, 0, 1, 0),
        Size                   = UDim2.new(1, 0, 1, -40)
    })
    Scale.ClipsDescendants = true

    local Home = Library:Create("Frame", {
        Name                   = "Home",
        Parent                 = Scale,
        BackgroundTransparency = 1,
        BorderSizePixel        = 0,
        Size                   = UDim2.new(1, 0, 1, 0)
    })
    Library:Create("UIPadding", {
        Parent        = Home,
        PaddingBottom = UDim.new(0, 15),
        PaddingLeft   = UDim.new(0, 14),
        PaddingRight  = UDim.new(0, 14)
    })

    local MainTabsScrolling = Library:Create("ScrollingFrame", {
        Name                   = "ScrollingFrame",
        Parent                 = Home,
        Active                 = true,
        BackgroundTransparency = 1,
        BorderSizePixel        = 0,
        Size                   = UDim2.new(1, 0, 1, 0),
        ClipsDescendants       = true,
        AutomaticCanvasSize    = Enum.AutomaticSize.None,
        BottomImage            = "rbxasset://textures/ui/Scroll/scroll-bottom.png",
        CanvasPosition         = Vector2.new(0, 0),
        ElasticBehavior        = Enum.ElasticBehavior.WhenScrollable,
        MidImage               = "rbxasset://textures/ui/Scroll/scroll-middle.png",
        ScrollBarImageColor3   = Color3.fromRGB(0, 0, 0),
        ScrollBarThickness     = 0,
        ScrollingDirection     = Enum.ScrollingDirection.XY,
        TopImage               = "rbxasset://textures/ui/Scroll/scroll-top.png",
        VerticalScrollBarPosition = Enum.VerticalScrollBarPosition.Right
    })
    Library:Create("UIPadding", {
        Parent        = MainTabsScrolling,
        PaddingBottom = UDim.new(0, 1),
        PaddingLeft   = UDim.new(0, 1),
        PaddingRight  = UDim.new(0, 1),
        PaddingTop    = UDim.new(0, 1)
    })
    local TabsLayout = Library:Create("UIListLayout", {
        Parent        = MainTabsScrolling,
        Padding       = UDim.new(0, 10),
        FillDirection = Enum.FillDirection.Horizontal,
        SortOrder     = Enum.SortOrder.LayoutOrder,
        Wraps         = true
    })
    TabsLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        MainTabsScrolling.CanvasSize = UDim2.new(0, 0, 0, TabsLayout.AbsoluteContentSize.Y + 15)
    end)

    local PageService = Library:Create("UIPageLayout", { Parent = Scale })

    ----------------------------------------------------------------
    -- Auto Scale / UIScale
    ----------------------------------------------------------------
    local function GetAutoScaleValue()
        local cam = workspace.CurrentCamera
        if not cam then return BaseScale end
        local vp    = cam.ViewportSize
        local ratio = math.min(vp.X / 1920, vp.Y / 1080)
        return math.clamp(ratio * BaseScale * 1.5, 0.4, BaseScale * 1.5)
    end

    local Scaler = Library:Create("UIScale", {
        Parent = Xova,
        Scale  = Mobile and 1 or (AutoScale and GetAutoScaleValue() or BaseScale)
    })

    if AutoScale and not Mobile then
        workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
            -- Don't override if user manually set via AddSizeSlider
            if not Scaler:GetAttribute("ManualScale") then
                Scaler.Scale = GetAutoScaleValue()
            end
        end)
    end

    ----------------------------------------------------------------
    -- Toggle Pill (no CoreGui)
    ----------------------------------------------------------------
    local ToggleScreen = Library:Create("ScreenGui", {
        Name           = "VitaToggle",
        Parent         = Library:Parent(),
        ZIndexBehavior = Enum.ZIndexBehavior.Global,
        IgnoreGuiInset = true,
        ResetOnSpawn   = false
    })
    local Pillow = Library:Create("TextButton", {
        Name             = "Pillow",
        Parent           = ToggleScreen,
        BackgroundColor3 = T.PillBg,
        BorderSizePixel  = 0,
        Position         = UDim2.new(0.06, 0, 0.15, 0),
        Size             = UDim2.new(0, 50, 0, 50),
        Text             = ""
    })
    trackBg(Pillow, "BackgroundColor3")
    Library:Create("UICorner", { Parent = Pillow, CornerRadius = UDim.new(1, 0) })
    Library:Create("ImageLabel", {
        Name                   = "Logo",
        Parent                 = Pillow,
        AnchorPoint            = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        BorderSizePixel        = 0,
        Position               = UDim2.new(0.5, 0, 0.5, 0),
        Size                   = UDim2.new(0.5, 0, 0.5, 0),
        Image                  = "rbxassetid://104055321996495"
    })
    Library:Draggable(Pillow)
    Pillow.MouseButton1Click:Connect(function()
        Background.Visible = not Background.Visible
    end)
    UserInputService.InputBegan:Connect(function(Input, Processed)
        if Processed then return end
        if Input.KeyCode == ToggleKey then
            Background.Visible = not Background.Visible
        end
    end)

    -- Return button logic
    local ReturnClickBtn = Library:Button(ReturnBtn)
    local function OnReturn()
        ReturnBtn.Visible = false
        Library:Tween({ v = HeadScale, t = 0.3, s = "Exponential", d = "Out", g = { Size = UDim2.new(1, 0, 1, 0) } }):Play()
        PageService:JumpTo(Home)
    end
    ReturnClickBtn.MouseButton1Click:Connect(OnReturn)

    PageService:JumpTo(Home)
    Library:Draggable(Background)
    PageService.HorizontalAlignment     = Enum.HorizontalAlignment.Left
    PageService.EasingStyle             = Enum.EasingStyle.Exponential
    PageService.TweenTime               = 0.5
    PageService.GamepadInputEnabled     = false
    PageService.ScrollWheelInputEnabled = false
    PageService.TouchInputEnabled       = false
    Library.PageService                 = PageService

    ----------------------------------------------------------------
    -- Executor Identity Label (bottom-right of window)
    ----------------------------------------------------------------
    local ExecLabel = Library:Create("TextLabel", {
        Name                   = "ExecIdentity",
        Parent                 = Background,
        AnchorPoint            = Vector2.new(1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel        = 0,
        Position               = UDim2.new(1, -8, 1, -5),
        Size                   = UDim2.new(0, 200, 0, 12),
        Font                   = Enum.Font.GothamMedium,
        Text                   = GetExecutorName(),
        TextColor3             = Color3.fromRGB(255, 255, 255),
        TextSize               = 9,
        TextTransparency       = 0.5,
        TextXAlignment         = Enum.TextXAlignment.Right,
        ZIndex                 = 10,
        Visible                = ExecIdentifyShown
    })

    ----------------------------------------------------------------
    -- Window Object
    ----------------------------------------------------------------
    local Window = {}

    function Window:NewPage(Args)
        local PageTitle = Args.Title or "Page"
        local PageDesc  = Args.Desc  or "Description"
        -- Icon supports: "eye", "lucide-home", "rbxassetid://...", or numeric ID
        local PageIcon  = ResolveIcon(Args.Icon or "layers")

        -- Tab card
        local NewTabs = Library:Create("Frame", {
            Name             = "NewTabs",
            Parent           = MainTabsScrolling,
            BackgroundColor3 = T.TabBg,
            BorderSizePixel  = 0,
            Size             = UDim2.new(0, 230, 0, 55)
        })
        trackTabBg(NewTabs, "BackgroundColor3")
        local TabClick = Library:Button(NewTabs)
        Library:Create("UICorner", { Parent = NewTabs, CornerRadius = UDim.new(0, 5) })
        local TabStrokeInst = Library:Create("UIStroke", { Parent = NewTabs, Color = T.TabStroke, Thickness = 1 })
        trackTabStroke(TabStrokeInst, "Color")

        local TabBanner = Library:Create("ImageLabel", {
            Name                   = "Banner",
            Parent                 = NewTabs,
            BackgroundTransparency = 1,
            BorderSizePixel        = 0,
            Size                   = UDim2.new(1, 0, 1, 0),
            Image                  = "rbxassetid://125411502674016",
            ImageColor3            = T.TabImage,
            ScaleType              = Enum.ScaleType.Crop
        })
        trackTabImage(TabBanner, "ImageColor3")
        Library:Create("UICorner", { Parent = TabBanner, CornerRadius = UDim.new(0, 2) })

        local TabInfo = Library:Create("Frame", {
            Name                   = "Info",
            Parent                 = NewTabs,
            BackgroundTransparency = 1,
            BorderSizePixel        = 0,
            Size                   = UDim2.new(1, 0, 1, 0)
        })
        Library:Create("UIListLayout", {
            Parent            = TabInfo,
            Padding           = UDim.new(0, 10),
            FillDirection     = Enum.FillDirection.Horizontal,
            SortOrder         = Enum.SortOrder.LayoutOrder,
            VerticalAlignment = Enum.VerticalAlignment.Center
        })
        Library:Create("UIPadding", { Parent = TabInfo, PaddingLeft = UDim.new(0, 15) })

        local TabIcon = Library:Create("ImageLabel", {
            Name                   = "Icon",
            Parent                 = TabInfo,
            BackgroundTransparency = 1,
            BorderSizePixel        = 0,
            LayoutOrder            = -1,
            Size                   = UDim2.new(0, 25, 0, 25),
            Image                  = PageIcon,   -- already resolved via GetIcon
            ImageColor3            = T.Accent
        })
        trackAccent(TabIcon, "ImageColor3")
        Library:Create("UIGradient", {
            Parent   = TabIcon,
            Color    = ColorSequence.new{
                ColorSequenceKeypoint.new(0,    Color3.fromRGB(255, 255, 255)),
                ColorSequenceKeypoint.new(0.75, T.SubText),
                ColorSequenceKeypoint.new(1,    Color3.fromRGB(100, 100, 100))
            },
            Rotation = 90
        })

        local TabText = Library:Create("Frame", {
            Name                   = "Text",
            Parent                 = TabInfo,
            BackgroundTransparency = 1,
            BorderSizePixel        = 0,
            Position               = UDim2.new(0.11, 0, 0.14, 0),
            Size                   = UDim2.new(0, 150, 0, 32)
        })
        Library:Create("UIListLayout", {
            Parent            = TabText,
            Padding           = UDim.new(0, 2),
            SortOrder         = Enum.SortOrder.LayoutOrder,
            VerticalAlignment = Enum.VerticalAlignment.Center
        })

        local TabTitleLabel = Library:Create("TextLabel", {
            Name                   = "Title",
            Parent                 = TabText,
            BackgroundTransparency = 1,
            BorderSizePixel        = 0,
            Size                   = UDim2.new(0, 150, 0, 14),
            Font                   = Enum.Font.GothamBold,
            RichText               = true,
            Text                   = PageTitle,
            TextColor3             = T.Accent,
            TextSize               = 15,
            TextStrokeTransparency = 0.45,
            TextXAlignment         = Enum.TextXAlignment.Left
        })
        trackAccent(TabTitleLabel, "TextColor3")
        Library:Create("UIGradient", {
            Parent   = TabTitleLabel,
            Color    = ColorSequence.new{
                ColorSequenceKeypoint.new(0,    Color3.fromRGB(255, 255, 255)),
                ColorSequenceKeypoint.new(0.75, T.SubText),
                ColorSequenceKeypoint.new(1,    Color3.fromRGB(100, 100, 100))
            },
            Rotation = 90
        })
        Library:Create("TextLabel", {
            Name                   = "Desc",
            Parent                 = TabText,
            BackgroundTransparency = 1,
            BorderSizePixel        = 0,
            Size                   = UDim2.new(0.9, 0, 0, 10),
            Font                   = Enum.Font.GothamMedium,
            RichText               = true,
            Text                   = PageDesc,
            TextColor3             = T.Text,
            TextSize               = 10,
            TextStrokeTransparency = 0.5,
            TextTransparency       = 0.2,
            TextXAlignment         = Enum.TextXAlignment.Left
        })

        -- Page frame
        local NewPage = Library:Create("Frame", {
            Name                   = "NewPage",
            Parent                 = Scale,
            BackgroundTransparency = 1,
            BorderSizePixel        = 0,
            Size                   = UDim2.new(1, 0, 1, 0)
        })
        local PageScrolling = Library:Create("ScrollingFrame", {
            Name                      = "PageScrolling",
            Parent                    = NewPage,
            Active                    = true,
            BackgroundTransparency    = 1,
            BorderSizePixel           = 0,
            Size                      = UDim2.new(1, 0, 1, 0),
            ClipsDescendants          = true,
            AutomaticCanvasSize       = Enum.AutomaticSize.None,
            BottomImage               = "rbxasset://textures/ui/Scroll/scroll-bottom.png",
            CanvasPosition            = Vector2.new(0, 0),
            ElasticBehavior           = Enum.ElasticBehavior.WhenScrollable,
            MidImage                  = "rbxasset://textures/ui/Scroll/scroll-middle.png",
            ScrollBarImageColor3      = Color3.fromRGB(0, 0, 0),
            ScrollBarThickness        = 0,
            ScrollingDirection        = Enum.ScrollingDirection.XY,
            TopImage                  = "rbxasset://textures/ui/Scroll/scroll-top.png",
            VerticalScrollBarPosition = Enum.VerticalScrollBarPosition.Right
        })
        Library:Create("UIPadding", {
            Parent       = PageScrolling,
            PaddingBottom = UDim.new(0, 1),
            PaddingLeft  = UDim.new(0, 15),
            PaddingRight = UDim.new(0, 15),
            PaddingTop   = UDim.new(0, 1)
        })
        local PageLayout = Library:Create("UIListLayout", {
            Parent        = PageScrolling,
            Padding       = UDim.new(0, 5),
            FillDirection = Enum.FillDirection.Vertical,
            SortOrder     = Enum.SortOrder.LayoutOrder
        })
        PageLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            PageScrolling.CanvasSize = UDim2.new(0, 0, 0, PageLayout.AbsoluteContentSize.Y + 15)
        end)

        local function OnChangePage()
            Library:Tween({ v = HeadScale, t = 0.2, s = "Exponential", d = "Out", g = { Size = UDim2.new(1, -30, 1, 0) } }):Play()
            ReturnBtn.Visible = true
            PageService:JumpTo(NewPage)
        end
        TabClick.MouseButton1Click:Connect(OnChangePage)

        -- Page API
        local Page = {}

        --[[
            Page:Section(Args)
            Accepts:
                "Section Name"                 -- plain string (backward compatible)
                { Text = "Name", Icon = "eye" } -- table with optional icon
                { Title = "Name", Icon = "shield-check" }
        --]]
        function Page:Section(Args)
            local SectionText, SectionIcon
            if type(Args) == "string" then
                SectionText = Args
                SectionIcon = nil
            else
                SectionText = Args.Text or Args.Title or ""
                SectionIcon = ResolveIcon(Args.Icon)
            end

            -- Container frame so icon + label sit side-by-side
            local Container = Library:Create("Frame", {
                Name                   = "Section",
                Parent                 = PageScrolling,
                BackgroundTransparency = 1,
                BorderSizePixel        = 0,
                LayoutOrder            = 0,
                AutomaticSize          = Enum.AutomaticSize.Y,
                Size                   = UDim2.new(1, 0, 0, 0)
            })
            Library:Create("UIListLayout", {
                Parent            = Container,
                FillDirection     = Enum.FillDirection.Horizontal,
                VerticalAlignment = Enum.VerticalAlignment.Center,
                SortOrder         = Enum.SortOrder.LayoutOrder,
                Padding           = UDim.new(0, 6)
            })
            Library:Create("UIPadding", {
                Parent        = Container,
                PaddingLeft   = UDim.new(0, 4),
                PaddingRight  = UDim.new(0, 4),
                PaddingTop    = UDim.new(0, 2),
                PaddingBottom = UDim.new(0, 2)
            })

            -- Section icon (shown only when provided)
            if SectionIcon then
                local SIcon = Library:Create("ImageLabel", {
                    Name                   = "SectionIcon",
                    Parent                 = Container,
                    BackgroundTransparency = 1,
                    BorderSizePixel        = 0,
                    LayoutOrder            = -1,
                    Size                   = UDim2.new(0, 14, 0, 14),
                    Image                  = SectionIcon,
                    ImageColor3            = T.Accent
                })
                track("Accent", SIcon, "ImageColor3")
                Library:Create("UIGradient", {
                    Parent   = SIcon,
                    Color    = ColorSequence.new{
                        ColorSequenceKeypoint.new(0,    Color3.fromRGB(255, 255, 255)),
                        ColorSequenceKeypoint.new(0.75, T.SubText),
                        ColorSequenceKeypoint.new(1,    Color3.fromRGB(100, 100, 100))
                    },
                    Rotation = 90
                })
            end

            -- Section label
            local Lbl = Library:Create("TextLabel", {
                Name                   = "Title",
                Parent                 = Container,
                BackgroundTransparency = 1,
                BorderSizePixel        = 0,
                LayoutOrder            = 0,
                AutomaticSize          = Enum.AutomaticSize.XY,
                Size                   = UDim2.new(0, 0, 0, 0),
                Font                   = Enum.Font.GothamBold,
                RichText               = true,
                Text                   = SectionText,
                TextColor3             = T.Text,
                TextSize               = 15,
                TextStrokeTransparency = 0.7,
                TextWrapped            = false,
                TextXAlignment         = Enum.TextXAlignment.Left,
                TextYAlignment         = Enum.TextYAlignment.Center
            })
            track("Text", Lbl, "TextColor3")
            Library:Create("UIGradient", {
                Parent   = Lbl,
                Color    = ColorSequence.new{
                    ColorSequenceKeypoint.new(0,    Color3.fromRGB(255, 255, 255)),
                    ColorSequenceKeypoint.new(0.75, T.SubText),
                    ColorSequenceKeypoint.new(1,    Color3.fromRGB(100, 100, 100))
                },
                Rotation = 90
            })

            return Container
        end

        function Page:Paragraph(Args)
            local Title  = Args.Title
            local Desc   = Args.Desc
            local Icon   = Args.Image or Args.Icon   -- right-side decorative image
            local RowIcon = ResolveIcon(Args.RowIcon) -- optional left-side row icon
            local Rows   = Library:NewRows(PageScrolling, Title, Desc, T, track, RowIcon)
            local Right  = Rows.Vectorize.Right
            local Left   = Rows.Vectorize.Left.Text

            local IconLbl = Library:Create("ImageLabel", {
                Parent                 = Right,
                AnchorPoint            = Vector2.new(0.5, 0.5),
                BackgroundTransparency = 1,
                BorderSizePixel        = 0,
                Position               = UDim2.new(0, 0.5, 0.5, 1),
                Size                   = UDim2.new(0, 20, 0, 20),
                Image                  = ResolveIcon(Icon),
                ImageColor3            = T.Accent
            })
            trackAccent(IconLbl, "ImageColor3")
            Library:Create("UIGradient", {
                Parent   = IconLbl,
                Color    = ColorSequence.new{
                    ColorSequenceKeypoint.new(0,    Color3.fromRGB(255, 255, 255)),
                    ColorSequenceKeypoint.new(0.75, T.SubText),
                    ColorSequenceKeypoint.new(1,    Color3.fromRGB(100, 100, 100))
                },
                Rotation = 90
            })
            local Data = { Title = Title, Desc = Desc, Icon = IconLbl, Instance = Rows }
            return setmetatable({}, {
                __newindex = function(t, k, v)
                    rawset(Data, k, v)
                    if k == "Title" then Left.Title.Text = tostring(v)
                    elseif k == "Desc" then Left.Desc.Text = tostring(v) end
                end,
                __index = Data
            })
        end

        function Page:RightLabel(Args)
            local Title     = Args.Title
            local Desc      = Args.Desc
            local RightText = Args.Right or "None"
            local Rows      = Library:NewRows(PageScrolling, Title, Desc, T, track)
            local Right     = Rows.Vectorize.Right

            local Lbl = Library:Create("TextLabel", {
                Name                   = "Title",
                Parent                 = Right,
                BackgroundTransparency = 1,
                BorderSizePixel        = 0,
                LayoutOrder            = -1,
                Size                   = UDim2.new(0, 90, 0, 0),  -- fixed width, auto height
                AutomaticSize          = Enum.AutomaticSize.Y,
                Selectable             = false,
                Font                   = Enum.Font.GothamSemibold,
                RichText               = true,
                Text                   = RightText,
                TextColor3             = T.Text,
                TextSize               = 12,
                TextStrokeTransparency = 0.7,
                TextWrapped            = true,
                TextXAlignment         = Enum.TextXAlignment.Right,
                TextYAlignment         = Enum.TextYAlignment.Top
            })
            track("Text", Lbl, "TextColor3")
            Library:Create("UIGradient", {
                Parent   = Lbl,
                Color    = ColorSequence.new{
                    ColorSequenceKeypoint.new(0,    Color3.fromRGB(255, 255, 255)),
                    ColorSequenceKeypoint.new(0.75, T.SubText),
                    ColorSequenceKeypoint.new(1,    Color3.fromRGB(100, 100, 100))
                },
                Rotation = 90
            })
            return Lbl
        end

        function Page:Button(Args)
            local Title    = Args.Title
            local Desc     = Args.Desc
            local BtnText  = Args.Text or "Click"
            local Callback = Args.Callback
            local RowIcon  = ResolveIcon(Args.Icon)   -- optional row-level icon
            local Rows     = Library:NewRows(PageScrolling, Title, Desc, T, track, RowIcon)
            local Right    = Rows.Vectorize.Right

            local Btn = Library:Create("Frame", {
                Name             = "Button",
                Parent           = Right,
                BackgroundColor3 = T.Accent,
                BorderSizePixel  = 0,
                Position         = UDim2.new(0.73, 0, 0.167, 0),
                Size             = UDim2.new(0, 75, 0, 25)
            })
            trackAccent(Btn, "BackgroundColor3")
            Library:Create("UICorner", { Parent = Btn, CornerRadius = UDim.new(0, 3) })
            Library:Create("UIGradient", {
                Parent   = Btn,
                Color    = ColorSequence.new{
                    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(56,  56,  56))
                },
                Rotation = 90
            })

            -- Button inner layout: icon (optional) + label side by side
            Library:Create("UIListLayout", {
                Parent            = Btn,
                FillDirection     = Enum.FillDirection.Horizontal,
                VerticalAlignment = Enum.VerticalAlignment.Center,
                HorizontalAlignment = Enum.HorizontalAlignment.Center,
                SortOrder         = Enum.SortOrder.LayoutOrder,
                Padding           = UDim.new(0, 4)
            })
            Library:Create("UIPadding", {
                Parent       = Btn,
                PaddingLeft  = UDim.new(0, 8),
                PaddingRight = UDim.new(0, 8)
            })

            -- Button icon (inside the pill, left of text)
            local btnIconId = ResolveIcon(Args.ButtonIcon or Args.Icon)
            if btnIconId then
                local BtnIcon = Library:Create("ImageLabel", {
                    Name                   = "BtnIcon",
                    Parent                 = Btn,
                    BackgroundTransparency = 1,
                    BorderSizePixel        = 0,
                    LayoutOrder            = -1,
                    Size                   = UDim2.new(0, 12, 0, 12),
                    Image                  = btnIconId,
                    ImageColor3            = T.Text
                })
                track("Text", BtnIcon, "ImageColor3")
            end

            local BtnLbl = Library:Create("TextLabel", {
                Name                   = "Title",
                Parent                 = Btn,
                BackgroundTransparency = 1,
                BorderSizePixel        = 0,
                LayoutOrder            = 0,
                AutomaticSize          = Enum.AutomaticSize.XY,
                Size                   = UDim2.new(0, 0, 0, 0),
                Font                   = Enum.Font.GothamSemibold,
                RichText               = true,
                Text                   = BtnText,
                TextColor3             = T.Text,
                TextSize               = 11,
                TextStrokeTransparency = 0.7,
                TextXAlignment         = Enum.TextXAlignment.Center
            })
            track("Text", BtnLbl, "TextColor3")

            -- Auto-size the button frame to fit its contents
            task.defer(function()
                if Btn and Btn.Parent then
                    Btn.AutomaticSize = Enum.AutomaticSize.X
                    Btn.Size = UDim2.new(0, 0, 0, 25)
                end
            end)

            local Click = Library:Button(Btn)
            Click.MouseButton1Click:Connect(function()
                if Library:IsDropdownOpen() then return end
                task.spawn(Library.Effect, Click, Btn)
                if Callback then Callback() end
            end)
            return Click
        end

        function Page:Toggle(Args)
            local Title    = Args.Title
            local Desc     = Args.Desc
            local Value    = Args.Value or false
            local Callback = Args.Callback or function() end
            local RowIcon  = ResolveIcon(Args.Icon)   -- optional row icon
            local Rows     = Library:NewRows(PageScrolling, Title, Desc, T, track, RowIcon)
            local Left     = Rows.Vectorize.Left.Text
            local Right    = Rows.Vectorize.Right
            local TitleLbl = Left.Title

            local Bg = Library:Create("Frame", {
                Name             = "Background",
                Parent           = Right,
                BackgroundColor3 = T.RowAlt,
                BorderSizePixel  = 0,
                Size             = UDim2.new(0, 20, 0, 20)
            })
            track("RowAlt", Bg, "BackgroundColor3")
            local Stroke = Library:Create("UIStroke", { Parent = Bg, Color = T.Stroke, Thickness = 0.5 })
            track("Stroke", Stroke, "Color")
            Library:Create("UICorner", { Parent = Bg, CornerRadius = UDim.new(0, 5) })

            local Highlight = Library:Create("Frame", {
                Name             = "Highligh",
                Parent           = Bg,
                AnchorPoint      = Vector2.new(0.5, 0.5),
                BackgroundColor3 = T.Accent,
                BorderSizePixel  = 0,
                Position         = UDim2.new(0.5, 0, 0.5, 0),
                Size             = UDim2.new(0, 20, 0, 20)
            })
            trackAccent(Highlight, "BackgroundColor3")
            Library:Create("UICorner", { Parent = Highlight, CornerRadius = UDim.new(0, 5) })
            Library:Create("UIGradient", {
                Parent   = Highlight,
                Color    = ColorSequence.new{
                    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(56,  56,  56))
                },
                Rotation = 90
            })
            local CheckImg = Library:Create("ImageLabel", {
                Parent                 = Highlight,
                AnchorPoint            = Vector2.new(0.5, 0.5),
                BackgroundTransparency = 1,
                BorderSizePixel        = 0,
                Position               = UDim2.new(0.5, 0, 0.5, 0),
                Size                   = UDim2.new(0.45, 0, 0.45, 0),
                Image                  = "rbxassetid://86682186031062"
            })

            local ClickBtn = Library:Button(Bg)
            local Data = { Title = Title, Desc = Desc, Value = Value }

            local function OnChanged(val)
                Data.Value = val
                if val then
                    Callback(val)
                    CheckImg.Size        = UDim2.new(0.85, 0, 0.85, 0)
                    TitleLbl.TextColor3  = T.Accent
                    Library:Tween({ v = Highlight, t = 0.5, s = "Exponential", d = "Out", g = { BackgroundTransparency = 0 } }):Play()
                    Library:Tween({ v = CheckImg,  t = 0.5, s = "Exponential", d = "Out", g = { ImageTransparency = 0 } }):Play()
                    Library:Tween({ v = CheckImg,  t = 0.3, s = "Exponential", d = "Out", g = { Size = UDim2.new(0.5, 0, 0.5, 0) } }):Play()
                    Stroke.Thickness = 0
                else
                    Callback(val)
                    TitleLbl.TextColor3 = T.Text
                    Library:Tween({ v = Highlight, t = 0.5, s = "Exponential", d = "Out", g = { BackgroundTransparency = 1 } }):Play()
                    Library:Tween({ v = CheckImg,  t = 0.5, s = "Exponential", d = "Out", g = { ImageTransparency = 1 } }):Play()
                    Stroke.Thickness = 0.5
                end
            end

            ClickBtn.MouseButton1Click:Connect(function()
                if Library:IsDropdownOpen() then return end
                OnChanged(not Data.Value)
            end)
            OnChanged(Value)

            return setmetatable({}, {
                __newindex = function(t, k, v)
                    rawset(Data, k, v)
                    if k == "Title" then Left.Title.Text = tostring(v)
                    elseif k == "Desc" then Left.Desc.Text = tostring(v)
                    elseif k == "Value" then OnChanged(v) end
                end,
                __index = Data
            })
        end

        function Page:Slider(Args)
            local Title    = Args.Title
            local Min      = Args.Min
            local Max      = Args.Max
            local Rounding = Args.Rounding or 0
            local Value    = Args.Value or Min
            local Callback = Args.Callback or function() end

            local SliderFrame = Library:Create("Frame", {
                Name             = "Slider",
                Parent           = PageScrolling,
                BackgroundColor3 = T.Row,
                BorderSizePixel  = 0,
                AutomaticSize    = Enum.AutomaticSize.None,
                Size             = UDim2.new(1, 0, 0, 42),
                Selectable       = false
            })
            track("Row", SliderFrame, "BackgroundColor3")
            Library:Create("UICorner", { Parent = SliderFrame, CornerRadius = UDim.new(0, 3) })
            local SliderStroke = Library:Create("UIStroke", { Parent = SliderFrame, Color = T.Stroke, Thickness = 0.5 })
            track("Stroke", SliderStroke, "Color")
            Library:Create("UIPadding", {
                Parent        = SliderFrame,
                PaddingBottom = UDim.new(0, 1),
                PaddingLeft   = UDim.new(0, 10),
                PaddingRight  = UDim.new(0, 10)
            })

            local TextF = Library:Create("Frame", {
                Name                   = "Text",
                Parent                 = SliderFrame,
                BackgroundTransparency = 1,
                BorderSizePixel        = 0,
                Position               = UDim2.new(0, 0, 0.1, 0),
                Size                   = UDim2.new(0, 111, 0, 22),
                Selectable             = false
            })
            Library:Create("UIListLayout", { Parent = TextF, SortOrder = Enum.SortOrder.LayoutOrder, VerticalAlignment = Enum.VerticalAlignment.Center })
            Library:Create("UIPadding", { Parent = TextF, PaddingBottom = UDim.new(0, 3) })

            local TitleLbl = Library:Create("TextLabel", {
                Name                   = "Title",
                Parent                 = TextF,
                BackgroundTransparency = 1,
                BorderSizePixel        = 0,
                LayoutOrder            = -1,
                Size                   = UDim2.new(1, 0, 0, 0),
                AutomaticSize          = Enum.AutomaticSize.Y,
                Selectable             = false,
                Font                   = Enum.Font.GothamSemibold,
                RichText               = true,
                Text                   = Title,
                TextColor3             = T.Text,
                TextSize               = 12,
                TextStrokeTransparency = 0.7,
                TextWrapped            = true,
                TextXAlignment         = Enum.TextXAlignment.Left,
                TextYAlignment         = Enum.TextYAlignment.Top
            })
            track("Text", TitleLbl, "TextColor3")
            Library:Create("UIGradient", {
                Parent   = TitleLbl,
                Color    = ColorSequence.new{
                    ColorSequenceKeypoint.new(0,    Color3.fromRGB(255, 255, 255)),
                    ColorSequenceKeypoint.new(0.75, T.SubText),
                    ColorSequenceKeypoint.new(1,    Color3.fromRGB(100, 100, 100))
                },
                Rotation = 90
            })

            local Scaling  = Library:Create("Frame", { Name = "Scaling",  Parent = SliderFrame, BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.new(1, 0, 1, 0), Selectable = false })
            local Slide    = Library:Create("Frame", { Name = "Slide",    Parent = Scaling,     AnchorPoint = Vector2.new(0, 1), BackgroundTransparency = 1, BorderSizePixel = 0, Position = UDim2.new(0, 0, 1, 0), Size = UDim2.new(1, 0, 0, 23), Selectable = false })
            local ColorBar = Library:Create("Frame", { Name = "ColorBar", Parent = Slide,       AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = Color3.fromRGB(10, 10, 10), BorderSizePixel = 0, Position = UDim2.new(0.5, 0, 0.5, 0), Size = UDim2.new(1, 0, 0, 5), Selectable = false })
            Library:Create("UICorner", { Parent = ColorBar, CornerRadius = UDim.new(0, 3) })

            local Fill = Library:Create("Frame", {
                Name             = "ColorBar",
                Parent           = ColorBar,
                BackgroundColor3 = T.Accent,
                BorderSizePixel  = 0,
                Size             = UDim2.new(0, 0, 1, 0),
                Selectable       = false
            })
            trackAccent(Fill, "BackgroundColor3")
            Library:Create("UICorner", { Parent = Fill, CornerRadius = UDim.new(0, 3) })
            Library:Create("UIGradient", { Parent = Fill, Color = ColorSequence.new{ ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)), ColorSequenceKeypoint.new(1, Color3.fromRGB(47, 47, 47)) }, Rotation = 90 })
            Library:Create("Frame", { Name = "Circle", Parent = Fill, AnchorPoint = Vector2.new(1, 0.5), BackgroundColor3 = Color3.fromRGB(255, 255, 255), BorderSizePixel = 0, Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.new(0, 5, 0, 11), Selectable = false })

            local ValueBox = Library:Create("TextBox", {
                Name                   = "Boxvalue",
                Parent                 = Scaling,
                AnchorPoint            = Vector2.new(1, 0.5),
                BackgroundTransparency = 1,
                BorderSizePixel        = 0,
                Position               = UDim2.new(1, -5, 0.449, -2),
                Size                   = UDim2.new(0, 60, 0, 15),
                ZIndex                 = 5,
                Font                   = Enum.Font.GothamMedium,
                Text                   = tostring(Value),
                TextColor3             = T.Text,
                TextSize               = 11,
                TextTransparency       = 0.5,
                TextTruncate           = Enum.TextTruncate.AtEnd,
                TextXAlignment         = Enum.TextXAlignment.Right
            })

            local dragging = false
            local function Round(n, d) return math.floor(n * (10 ^ d) + 0.5) / (10 ^ d) end
            local function UpdateSlider(val)
                val = math.clamp(val, Min, Max)
                val = Round(val, Rounding)
                local ratio = (val - Min) / (Max - Min)
                Library:Tween({ v = Fill, t = 0.1, s = "Linear", d = "Out", g = { Size = UDim2.new(ratio, 0, 1, 0) } }):Play()
                ValueBox.Text = tostring(val)
                Callback(val)
                return val
            end
            local function GetVal(input)
                local ax = ColorBar.AbsolutePosition.X
                local aw = ColorBar.AbsoluteSize.X
                return math.clamp((input.Position.X - ax) / aw, 0, 1) * (Max - Min) + Min
            end
            local function SetDragging(state)
                dragging = state
                local color = state and T.Accent or T.Text
                Library:Tween({ v = ValueBox, t = state and 0.3 or 0.3, s = "Back", d = "Out", g = { TextSize = state and 15 or 11 } }):Play()
                Library:Tween({ v = ValueBox, t = 0.2, s = "Exponential", d = "Out", g = { TextColor3 = color } }):Play()
                Library:Tween({ v = TitleLbl, t = 0.2, s = "Exponential", d = "Out", g = { TextColor3 = color } }):Play()
            end

            local ClickBtn = Library:Button(SliderFrame)
            ClickBtn.InputBegan:Connect(function(input)
                if Library:IsDropdownOpen() then return end
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    SetDragging(true); UpdateSlider(GetVal(input))
                end
            end)
            ClickBtn.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    SetDragging(false)
                end
            end)
            UserInputService.InputChanged:Connect(function(input)
                if Library:IsDropdownOpen() then return end
                if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                    UpdateSlider(GetVal(input))
                end
            end)
            ValueBox.Focused:Connect(function()
                Library:Tween({ v = ValueBox, t = 0.2, s = "Exponential", d = "Out", g = { TextColor3 = T.Accent } }):Play()
                Library:Tween({ v = TitleLbl, t = 0.2, s = "Exponential", d = "Out", g = { TextColor3 = T.Accent } }):Play()
            end)
            ValueBox.FocusLost:Connect(function()
                Library:Tween({ v = ValueBox, t = 0.2, s = "Exponential", d = "Out", g = { TextColor3 = T.Text } }):Play()
                Library:Tween({ v = TitleLbl, t = 0.2, s = "Exponential", d = "Out", g = { TextColor3 = T.Text } }):Play()
                Value = UpdateSlider(tonumber(ValueBox.Text) or Value)
            end)
            UpdateSlider(Value)
        end

        function Page:Input(Args)
            local Value    = Args.Value    or ""
            local Callback = Args.Callback or function() end
            local Title    = Args.Title
            local Desc     = Args.Desc

            local InputFrame = Library:Create("Frame", {
                Name                   = "Input",
                Parent                 = PageScrolling,
                BackgroundTransparency = 1,
                BorderSizePixel        = 0,
                Size                   = UDim2.new(1, 0, 0, 30),
                Selectable             = false
            })
            Library:Create("UIListLayout", { Parent = InputFrame, Padding = UDim.new(0, 5), FillDirection = Enum.FillDirection.Horizontal, SortOrder = Enum.SortOrder.LayoutOrder, VerticalAlignment = Enum.VerticalAlignment.Center })

            local Front = Library:Create("Frame", {
                Name             = "Front",
                Parent           = InputFrame,
                BackgroundColor3 = T.Row,
                BorderSizePixel  = 0,
                Size             = UDim2.new(1, -35, 1, 0),
                Selectable       = false
            })
            track("Row", Front, "BackgroundColor3")
            Library:Create("UICorner", { Parent = Front, CornerRadius = UDim.new(0, 2) })
            local FrontStroke = Library:Create("UIStroke", { Parent = Front, Color = T.Stroke, Thickness = 0.5 })
            track("Stroke", FrontStroke, "Color")

            local TextBox = Library:Create("TextBox", {
                Parent                 = Front,
                AnchorPoint            = Vector2.new(0.5, 0.5),
                BackgroundTransparency = 1,
                BorderSizePixel        = 0,
                Position               = UDim2.new(0.5, 0, 0.5, 0),
                Size                   = UDim2.new(1, -20, 1, 0),
                Font                   = Enum.Font.GothamMedium,
                PlaceholderColor3      = Color3.fromRGB(55, 55, 55),
                PlaceholderText        = Title and (Title .. (Desc and (" — " .. Desc) or "")) or "Type here and press Enter",
                Text                   = tostring(Value),
                TextColor3             = Color3.fromRGB(100, 100, 100),
                TextSize               = 11,
                TextXAlignment         = Enum.TextXAlignment.Left
            })

            local Enter = Library:Create("Frame", {
                Name             = "Enter",
                Parent           = InputFrame,
                BackgroundColor3 = T.Accent,
                BorderSizePixel  = 0,
                Size             = UDim2.new(0, 30, 0, 30),
                Selectable       = false
            })
            trackAccent(Enter, "BackgroundColor3")
            Library:Create("UICorner", { Parent = Enter, CornerRadius = UDim.new(0, 3) })
            Library:Create("UIGradient", { Parent = Enter, Color = ColorSequence.new{ ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)), ColorSequenceKeypoint.new(1, Color3.fromRGB(56, 56, 56)) }, Rotation = 90 })

            local EnterIcon = Library:Create("ImageLabel", {
                Name                   = "Asset",
                Parent                 = Enter,
                AnchorPoint            = Vector2.new(0.5, 0.5),
                BackgroundTransparency = 1,
                BorderSizePixel        = 0,
                Position               = UDim2.new(0.5, 0, 0.5, 0),
                Size                   = UDim2.new(0, 15, 0, 15),
                Image                  = "rbxassetid://78020815235467"
            })
            local CopyBtn = Library:Button(Enter)
            TextBox.FocusLost:Connect(function(entered)
                if entered then Callback(TextBox.Text) end
            end)
            CopyBtn.MouseButton1Click:Connect(function()
                if Library:IsDropdownOpen() then return end
                pcall(setclipboard, TextBox.Text)
                EnterIcon.Image = "rbxassetid://121742282171603"
                delay(3, function() EnterIcon.Image = "rbxassetid://78020815235467" end)
            end)
            return TextBox
        end

        function Page:Dropdown(Args)
            local Title    = Args.Title
            local List     = Args.List
            local Value    = Args.Value
            local Callback = Args.Callback
            local IsMulti  = typeof(Value) == "table"
            local RowIcon  = ResolveIcon(Args.Icon)   -- optional row icon

            local Rows = Library:NewRows(PageScrolling, Title, "N/A", T, track, RowIcon)
            local Right = Rows.Vectorize.Right
            local Left  = Rows.Vectorize.Left.Text

            Library:Create("ImageLabel", { Parent = Right, BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.new(0, 20, 0, 20), Image = "rbxassetid://132291592681506", ImageTransparency = 0.5 })

            local Open = Library:Button(Rows.Vectorize)

            local function GetText()
                if IsMulti then return table.concat(type(Value) == "table" and Value or {}, ", ") end
                return tostring(Value)
            end
            Left.Desc.Text = GetText()

            do
                local DropFrame = Library:Create("Frame", {
                    Name             = "Dropdown",
                    Parent           = Background,
                    AnchorPoint      = Vector2.new(0.5, 0.5),
                    BackgroundColor3 = T.DropBg,
                    BorderSizePixel  = 0,
                    Position         = UDim2.new(0.5, 0, 0.3, 0),
                    Size             = UDim2.new(0, 300, 0, 250),
                    ZIndex           = 500,
                    Selectable       = false,
                    Visible          = false
                })
                track("DropBg", DropFrame, "BackgroundColor3")
                Library:Create("UICorner", { Parent = DropFrame, CornerRadius = UDim.new(0, 3) })
                local DropStrokeInst = Library:Create("UIStroke", { Parent = DropFrame, Color = T.DropStroke, Thickness = 0.5 })
                track("DropStroke", DropStrokeInst, "Color")
                Library:Create("UIListLayout", { Parent = DropFrame, Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder, HorizontalAlignment = Enum.HorizontalAlignment.Center })
                Library:Create("UIPadding", { Parent = DropFrame, PaddingBottom = UDim.new(0, 10), PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10), PaddingTop = UDim.new(0, 10) })

                local DropText = Library:Create("Frame", { Name = "Text", Parent = DropFrame, BackgroundTransparency = 1, BorderSizePixel = 0, LayoutOrder = -5, Size = UDim2.new(1, 0, 0, 30), ZIndex = 500, Selectable = false })
                Library:Create("UIListLayout", { Parent = DropText, Padding = UDim.new(0, 1), SortOrder = Enum.SortOrder.LayoutOrder, HorizontalAlignment = Enum.HorizontalAlignment.Center, VerticalAlignment = Enum.VerticalAlignment.Center })

                local DropTitleLbl = Library:Create("TextLabel", { Name = "Title", Parent = DropText, BackgroundTransparency = 1, BorderSizePixel = 0, LayoutOrder = -1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, ZIndex = 500, Selectable = false, Font = Enum.Font.GothamSemibold, RichText = true, Text = Title, TextColor3 = T.Accent, TextSize = 14, TextStrokeTransparency = 0.7, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top })
                track("Accent", DropTitleLbl, "TextColor3")
                Library:Create("UIGradient", { Parent = DropTitleLbl, Color = ColorSequence.new{ ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)), ColorSequenceKeypoint.new(0.75, T.SubText), ColorSequenceKeypoint.new(1, Color3.fromRGB(100, 100, 100)) }, Rotation = 90 })

                local Desc1 = Library:Create("TextLabel", { Name = "Desc", Parent = DropText, BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, ZIndex = 500, Selectable = false, Font = Enum.Font.GothamMedium, RichText = true, Text = GetText(), TextColor3 = T.Text, TextSize = 10, TextStrokeTransparency = 0.7, TextTransparency = 0.6, TextWrapped = true, TextTruncate = Enum.TextTruncate.None, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top })
                track("Text", Desc1, "TextColor3")

                local InputF  = Library:Create("Frame",  { Name = "Input", Parent = DropFrame, BackgroundTransparency = 1, BorderSizePixel = 0, LayoutOrder = -4, Size = UDim2.new(1, 0, 0, 25), ZIndex = 500, Selectable = false })
                Library:Create("UIListLayout", { Parent = InputF, Padding = UDim.new(0, 5), FillDirection = Enum.FillDirection.Horizontal, SortOrder = Enum.SortOrder.LayoutOrder, VerticalAlignment = Enum.VerticalAlignment.Center })
                local FrontF  = Library:Create("Frame",  { Name = "Front",  Parent = InputF, BackgroundColor3 = T.Row, BorderSizePixel = 0, Size = UDim2.new(1, 0, 1, 0), ZIndex = 500, Selectable = false })
                track("Row", FrontF, "BackgroundColor3")
                Library:Create("UICorner", { Parent = FrontF, CornerRadius = UDim.new(0, 2) })
                local FrontStroke = Library:Create("UIStroke", { Parent = FrontF, Color = T.Stroke, Thickness = 0.5 })
                track("Stroke", FrontStroke, "Color")
                local SearchBox = Library:Create("TextBox", { Name = "Search", Parent = FrontF, AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1, BorderSizePixel = 0, CursorPosition = -1, Position = UDim2.new(0.5, 0, 0.5, 0), Size = UDim2.new(1, -20, 1, 0), ZIndex = 500, Font = Enum.Font.GothamMedium, PlaceholderColor3 = Color3.fromRGB(55, 55, 55), PlaceholderText = "Search", Text = "", TextColor3 = T.Text, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left })
                track("Text", SearchBox, "TextColor3")

                local List1 = Library:Create("ScrollingFrame", { Name = "List", Parent = DropFrame, BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 160), ZIndex = 500, ScrollBarThickness = 0 })
                local ScrollL = Library:Create("UIListLayout", { Parent = List1, Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder, HorizontalAlignment = Enum.HorizontalAlignment.Center })
                Library:Create("UIPadding", { Parent = List1, PaddingLeft = UDim.new(0, 1), PaddingRight = UDim.new(0, 1) })
                ScrollL:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()
                    List1.CanvasSize = UDim2.new(0, 0, 0, ScrollL.AbsoluteContentSize.Y + 15)
                end)

                local selectedValues = {}
                local selectedOrder  = 0

                local function isInTable(val, tbl)
                    if type(tbl) ~= "table" then return false end
                    for _, v in pairs(tbl) do if v == val then return true end end
                    return false
                end
                local function Settext()
                    if IsMulti then
                        Desc1.Text     = table.concat(Value, ", ")
                        Left.Desc.Text = table.concat(Value, ", ")
                    else
                        Desc1.Text     = tostring(Value)
                        Left.Desc.Text = tostring(Value)
                    end
                end

                local isOpen = false
                UserInputService.InputBegan:Connect(function(A)
                    if not isOpen then return end
                    local mouse = LocalPlayer:GetMouse()
                    local mx, my = mouse.X, mouse.Y
                    local dp, ds = DropFrame.AbsolutePosition, DropFrame.AbsoluteSize
                    if A.UserInputType == Enum.UserInputType.MouseButton1 or A.UserInputType == Enum.UserInputType.Touch then
                        if not (mx >= dp.X and mx <= dp.X + ds.X and my >= dp.Y and my <= dp.Y + ds.Y) then
                            isOpen = false; DropFrame.Visible = false; DropFrame.Position = UDim2.new(0.5, 0, 0.3, 0)
                        end
                    end
                end)
                Open.MouseButton1Click:Connect(function()
                    if Library:IsDropdownOpen() then return end
                    isOpen = not isOpen
                    if isOpen then
                        DropFrame.Visible = true
                        Library:Tween({ v = DropFrame, t = 0.3, s = "Back", d = "Out", g = { Position = UDim2.new(0.5, 0, 0.5, 0) } }):Play()
                    else
                        DropFrame.Visible = false; DropFrame.Position = UDim2.new(0.5, 0, 0.3, 0)
                    end
                end)

                local Setting = {}
                function Setting:Clear(a)
                    for _, v in ipairs(List1:GetChildren()) do
                        if v:IsA("Frame") then
                            local should = a == nil or (type(a) == "string" and v.Title.Text == a) or (type(a) == "table" and isInTable(v.Title.Text, a))
                            if should then v:Destroy() end
                        end
                    end
                    if a == nil then Value = nil; selectedValues = {}; selectedOrder = 0; Desc1.Text = "None"; Left.Desc.Text = "None" end
                end
                function Setting:AddList(Name)
                    local Item = Library:Create("Frame", { Name = "NewList", Parent = List1, BackgroundColor3 = Color3.fromRGB(0, 0, 0), BackgroundTransparency = 1, BorderSizePixel = 0, LayoutOrder = 0, Size = UDim2.new(1, 0, 0, 25), ZIndex = 500, Selectable = false })
                    Library:Create("UICorner", { Parent = Item, CornerRadius = UDim.new(0, 2) })
                    local ItemTitle = Library:Create("TextLabel", { Name = "Title", Parent = Item, AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1, BorderSizePixel = 0, LayoutOrder = -1, Position = UDim2.new(0.5, 0, 0.5, 0), Size = UDim2.new(1, -15, 1, 0), ZIndex = 500, Selectable = false, Font = Enum.Font.GothamSemibold, RichText = true, Text = tostring(Name), TextColor3 = T.Text, TextSize = 11, TextStrokeTransparency = 0.7, TextXAlignment = Enum.TextXAlignment.Left })
                    -- track unselected text color; selected state overrides in OnValue
                    track("Text", ItemTitle, "TextColor3")
                    Library:Create("UIGradient", { Parent = ItemTitle, Color = ColorSequence.new{ ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)), ColorSequenceKeypoint.new(0.75, T.SubText), ColorSequenceKeypoint.new(1, Color3.fromRGB(100, 100, 100)) }, Rotation = 90 })

                    local function OnValue(val)
                        ItemTitle.TextColor3 = val and T.Accent or T.Text
                        Library:Tween({ v = Item, t = 0.2, s = "Linear", d = "Out", g = { BackgroundTransparency = val and 0.85 or 1 } }):Play()
                    end
                    local ItemClick = Library:Button(Item)
                    local function OnSelected()
                        if IsMulti then
                            if selectedValues[Name] then
                                selectedValues[Name] = nil; Item.LayoutOrder = 0; OnValue(false)
                            else
                                selectedOrder = selectedOrder - 1; selectedValues[Name] = selectedOrder; Item.LayoutOrder = selectedOrder; OnValue(true)
                            end
                            local sel = {}; for i in pairs(selectedValues) do table.insert(sel, i) end
                            if #sel > 0 then table.sort(sel); Value = sel; Settext() else Desc1.Text = "N/A"; Left.Desc.Text = "N/A" end
                            pcall(Callback, sel)
                        else
                            for _, v in pairs(List1:GetChildren()) do
                                if v:IsA("Frame") and v.Name == "NewList" then
                                    v.Title.TextColor3 = T.Text
                                    Library:Tween({ v = v, t = 0.2, s = "Linear", d = "Out", g = { BackgroundTransparency = 1 } }):Play()
                                end
                            end
                            OnValue(true); Value = Name; Settext(); pcall(Callback, Value)
                        end
                    end
                    delay(0, function()
                        if IsMulti then
                            if isInTable(Name, Value) then
                                selectedOrder = selectedOrder - 1; selectedValues[Name] = selectedOrder; Item.LayoutOrder = selectedOrder; OnValue(true)
                                local sel = {}; for i in pairs(selectedValues) do table.insert(sel, i) end
                                if #sel > 0 then table.sort(sel); Settext() else Desc1.Text = "N/A"; Left.Desc.Text = "N/A" end
                                pcall(Callback, sel)
                            end
                        else
                            if Name == Value then OnValue(true); Settext(); pcall(Callback, Value) end
                        end
                    end)
                    ItemClick.MouseButton1Click:Connect(OnSelected)
                end
                SearchBox.Changed:Connect(function()
                    local s = string.lower(SearchBox.Text)
                    for _, v in pairs(List1:GetChildren()) do
                        if v:IsA("Frame") and v.Name == "NewList" then
                            v.Visible = string.find(string.lower(v.Title.Text), s, 1, true) ~= nil
                        end
                    end
                end)
                for _, name in ipairs(List) do Setting:AddList(name) end
                return Setting
            end
        end

        ----------------------------------------------------------
        -- NEW: Keybind
        ----------------------------------------------------------
        --[[
            Page:Keybind(Args)
            Args:
                Title    (string)        - Row title
                Desc     (string)        - Row description
                Value    (Enum.KeyCode)  - Default key
                Callback (function)      - Called on key press in-game
        --]]
        function Page:Keybind(Args)
            local Title    = Args.Title
            local Desc     = Args.Desc
            local Value    = Args.Value or Enum.KeyCode.Unknown
            local Callback = Args.Callback or function() end
            local RowIcon  = ResolveIcon(Args.Icon)   -- optional row icon
            local Rows     = Library:NewRows(PageScrolling, Title, Desc, T, track, RowIcon)
            local Right    = Rows.Vectorize.Right
            local Left     = Rows.Vectorize.Left.Text

            local KeyBtn = Library:Create("Frame", {
                Name             = "KeyBind",
                Parent           = Right,
                BackgroundColor3 = T.RowAlt,
                BorderSizePixel  = 0,
                Size             = UDim2.new(0, 80, 0, 22)
            })
            track("RowAlt", KeyBtn, "BackgroundColor3")
            Library:Create("UICorner", { Parent = KeyBtn, CornerRadius = UDim.new(0, 3) })
            local KBStroke = Library:Create("UIStroke", { Parent = KeyBtn, Color = T.Stroke, Thickness = 0.5 })
            track("Stroke", KBStroke, "Color")

            local KeyLabel = Library:Create("TextLabel", {
                Parent                 = KeyBtn,
                AnchorPoint            = Vector2.new(0.5, 0.5),
                BackgroundTransparency = 1,
                BorderSizePixel        = 0,
                Position               = UDim2.new(0.5, 0, 0.5, 0),
                Size                   = UDim2.new(1, -8, 1, 0),
                Font                   = Enum.Font.GothamSemibold,
                Text                   = tostring(Value.Name),
                TextColor3             = T.Accent,
                TextSize               = 11,
                TextTruncate           = Enum.TextTruncate.AtEnd
            })
            trackAccent(KeyLabel, "TextColor3")

            local ClickBtn  = Library:Button(KeyBtn)
            local listening = false
            local Data      = { Title = Title, Desc = Desc, Value = Value }

            local function SetKey(key)
                Data.Value         = key
                KeyLabel.Text      = tostring(key.Name)
                KeyLabel.TextColor3 = T.Accent
                Library:Tween({ v = KeyBtn, t = 0.2, s = "Exponential", d = "Out", g = { BackgroundColor3 = T.RowAlt } }):Play()
                pcall(Callback, key)
            end

            ClickBtn.MouseButton1Click:Connect(function()
                if Library:IsDropdownOpen() then return end
                if listening then return end
                listening          = true
                KeyLabel.Text      = "..."
                KeyLabel.TextColor3 = T.Text
                Library:Tween({ v = KeyBtn, t = 0.2, s = "Exponential", d = "Out", g = { BackgroundColor3 = T.Stroke } }):Play()

                local conn
                conn = UserInputService.InputBegan:Connect(function(input, processed)
                    if processed then return end
                    if input.UserInputType == Enum.UserInputType.Keyboard then
                        listening = false
                        conn:Disconnect()
                        SetKey(input.KeyCode)
                    end
                end)
            end)

            -- Fire callback when key pressed in-game (not listening)
            UserInputService.InputBegan:Connect(function(input, processed)
                if processed or listening then return end
                if input.KeyCode == Data.Value then
                    pcall(Callback, Data.Value)
                end
            end)

            return setmetatable({}, {
                __newindex = function(t, k, v)
                    rawset(Data, k, v)
                    if k == "Title" then Left.Title.Text = tostring(v)
                    elseif k == "Desc" then Left.Desc.Text = tostring(v)
                    elseif k == "Value" then SetKey(v) end
                end,
                __index = Data
            })
        end

        function Page:Banner(Assets)
            local Banner = Library:Create("ImageLabel", {
                Name                   = "NewBanner",
                Parent                 = PageScrolling,
                BackgroundTransparency = 1,
                BorderSizePixel        = 0,
                Size                   = UDim2.new(1, 0, 0, 235),
                Image                  = Library:Asset(Assets),
                ScaleType              = Enum.ScaleType.Crop
            })
            Library:Create("UICorner", { Parent = Banner, CornerRadius = UDim.new(0, 3) })
            return Banner
        end

        return Page
    end

    ----------------------------------------------------------------
    -- Library methods scoped to this Window instance
    ----------------------------------------------------------------

    function Library:SetTimeValue(Value)
        THETIME.Text = Value
    end

    --[[
        Library:AddSizeSlider(Page)
        Adds an Interface Scale slider to any Page.
        Disables auto-scale once the user manually moves it.
    --]]
    function Library:AddSizeSlider(Page)
        return Page:Slider({
            Title    = "Interface Scale",
            Min      = 0.5,
            Max      = 2.5,
            Rounding = 1,
            Value    = Scaler.Scale,
            Callback = function(v)
                Scaler:SetAttribute("ManualScale", true)
                Scaler.Scale = v
            end
        })
    end

    --[[
        Library:SetTheme(newTheme)
        Updates theme colors immediately. Accepts Color3 or hex strings.
        All tracked instances refresh in real-time via the Heartbeat watcher too —
        so even direct assignments like  T.Accent = "#FF007F"  auto-apply.

        Supports shorthand keys: BG, Tab, TabImage, TabStroke.

        Examples:
            Library:SetTheme({ Accent = "#FF007F" })
            Library:SetTheme({ BG = "#0D0D0D", Tab = "#0A0A0A", TabImage = "#FF007F", TabStroke = "#4B0026" })
            Library:SetTheme({ Accent = Color3.fromRGB(50, 130, 255) })
    --]]
    function Library:SetTheme(newTheme)
        -- Resolve shorthands
        if newTheme.BG        then newTheme.Background = newTheme.BG;        newTheme.BG        = nil end
        if newTheme.Tab       then newTheme.TabBg      = newTheme.Tab;       newTheme.Tab       = nil end

        -- Write into T (Heartbeat watcher will detect diffs and flush refs automatically)
        for k, v in pairs(newTheme) do
            T[k] = ResolveColor(v)
        end
        -- Also flush immediately so changes are visible this frame
        for k in pairs(newTheme) do
            _flushKey(k)
            _prevT[k] = T[k]  -- sync snapshot so watcher doesn't double-fire
        end
    end

    --[[
        Library:SetExecutorIdentity(visible)
        Show or hide the executor identity label at the bottom-right of the window.
        Example:
            Library:SetExecutorIdentity(false)  -- hide it
            Library:SetExecutorIdentity(true)   -- show it
    --]]
    function Library:SetExecutorIdentity(visible)
        ExecLabel.Visible = visible == true
    end

    --[[
        Library:Destroy()
        Cleans up all GUIs created by this window.
    --]]
    function Library:Destroy()
        pcall(function() Xova:Destroy() end)
        pcall(function() ToggleScreen:Destroy() end)
        pcall(function() NotifGui:Destroy() end)
    end

    return Window
end

return Library
