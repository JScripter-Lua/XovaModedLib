--[[
    Vita UI Library  —  Clean Rewrite
    ─────────────────────────────────────────────────────────────────────────
    Features:
      • Window with customizable Theme (hex "#RRGGBB" or Color3)
      • Real-time SetTheme — all elements update immediately
      • Per-tab banner tint  (Args.TabImage per NewPage)
      • Customizable pill icon  (Args.BbIcon + Library:SetPillIcon)
      • 822 Lucide icons — just pass name: Icon = "eye"  (no rbxassetid needed)
      • GetIcon resolver: "eye" → lucide-eye → rbxassetid
      • No CoreGui anywhere  (gethui / PlayerGui)
      • All callbacks pcall-protected
      • Button: no stretch on click, text always inside pill
      • Dropdown single + multi select with search
      • Full proxy returns on every element
      • Keybind, Slider, Toggle, Input, Paragraph, RightLabel
      • Section (plain string or {Text, Icon}), Separator, Label, Banner
      • Notifications (Info / Success / Warning / Error)
      • Auto-scale + manual UIScale slider
      • Executor identity label
    ─────────────────────────────────────────────────────────────────────────
]]

local Library = {}

--------------------------------------------------------------------
-- Services
--------------------------------------------------------------------
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")
local Mobile      = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

--------------------------------------------------------------------
-- Parent helper — never CoreGui
--------------------------------------------------------------------
function Library:Parent()
    if not RunService:IsStudio() then
        return (gethui and gethui()) or PlayerGui
    end
    return PlayerGui
end

--------------------------------------------------------------------
-- Utilities
--------------------------------------------------------------------
function Library:Hex(hex)
    hex = hex:gsub("#","")
    local r = tonumber(hex:sub(1,2),16) or 0
    local g = tonumber(hex:sub(3,4),16) or 0
    local b = tonumber(hex:sub(5,6),16) or 0
    return Color3.fromRGB(r,g,b)
end

local function ResolveColor(v)
    if typeof(v) == "Color3" then return v end
    if type(v)   == "string" then return Library:Hex(v) end
    return v
end

local function GetExecutorName()
    for _, fn in ipairs({ getexecutorname, identifyexecutor }) do
        if fn then
            local ok, n = pcall(fn)
            if ok and n and n ~= "" then return n end
        end
    end
    if syn         then return "Synapse X"  end
    if KRNL_LOADED then return "KRNL"       end
    if fluxus      then return "Fluxus"     end
    if electron    then return "Electron"   end
    if robloxmouse then return "Scriptware" end
    return "Unknown Executor"
end

function Library:Create(class, props)
    local inst = Instance.new(class)
    for k,v in pairs(props) do inst[k] = v end
    return inst
end

function Library:Asset(v)
    if type(v) == "number" then return "rbxassetid://" .. v end
    if type(v) == "string" and v:find("rbxassetid://") then return v end
    return tostring(v)
end

function Library:Tween(info)
    return TweenService:Create(
        info.v,
        TweenInfo.new(info.t, Enum.EasingStyle[info.s], Enum.EasingDirection[info.d]),
        info.g
    )
end

-- Transparent click button overlay
function Library:Button(parent)
    return Library:Create("TextButton", {
        Name                   = "Click",
        Parent                 = parent,
        BackgroundTransparency = 1,
        BorderSizePixel        = 0,
        Size                   = UDim2.new(1,0,1,0),
        Text                   = "",
        Font                   = Enum.Font.SourceSans,
        TextSize               = 14,
        TextColor3             = Color3.new(),
        ZIndex                 = parent.ZIndex + 3,
    })
end

-- Drag support
function Library:Draggable(frame)
    local dragging, dragInput, dragStart, startPos
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
            local d = input.Position - dragStart
            TweenService:Create(frame, TweenInfo.new(0.18), {
                Position = UDim2.new(
                    startPos.X.Scale, startPos.X.Offset + d.X,
                    startPos.Y.Scale, startPos.Y.Offset + d.Y
                )
            }):Play()
        end
    end)
end

-- Ripple click effect — freezes AutomaticSize to prevent button stretch
function Library.Effect(clickBtn, container)
    local wasAuto = container.AutomaticSize
    local frozen  = container.AbsoluteSize
    -- Lock size so the growing ripple child cannot stretch the container
    if wasAuto ~= Enum.AutomaticSize.None then
        container.AutomaticSize = Enum.AutomaticSize.None
        container.Size = UDim2.new(0, frozen.X, 0, frozen.Y)
    end
    container.ClipsDescendants = true

    local mouse = Players.LocalPlayer:GetMouse()
    local rx = mouse.X - container.AbsolutePosition.X
    local ry = mouse.Y - container.AbsolutePosition.Y
    local inBounds = rx >= 0 and ry >= 0
                  and rx <= container.AbsoluteSize.X
                  and ry <= container.AbsoluteSize.Y

    if not inBounds then
        if wasAuto ~= Enum.AutomaticSize.None then
            container.AutomaticSize = wasAuto
            container.Size = UDim2.new(0, 0, 0, frozen.Y)
        end
        return
    end

    local circle = Library:Create("Frame", {
        Parent                 = container,
        BackgroundColor3       = Color3.fromRGB(255,255,255),
        BackgroundTransparency = 0.8,
        BorderSizePixel        = 0,
        AnchorPoint            = Vector2.new(0.5, 0.5),
        Position               = UDim2.new(0, rx, 0, ry),
        Size                   = UDim2.new(0, 0, 0, 0),
        ZIndex                 = container.ZIndex + 1,
    })
    Library:Create("UICorner", { Parent = circle, CornerRadius = UDim.new(1, 0) })

    local targetSize = frozen.X * 2
    TweenService:Create(circle, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size                   = UDim2.new(0, targetSize, 0, targetSize),
        BackgroundTransparency = 1,
    }):Play()

    task.delay(0.55, function()
        if circle and circle.Parent then circle:Destroy() end
        -- Restore AutomaticSize after ripple is gone
        if wasAuto ~= Enum.AutomaticSize.None and container and container.Parent then
            container.AutomaticSize = wasAuto
            container.Size = UDim2.new(0, 0, 0, frozen.Y)
        end
    end)
end

--------------------------------------------------------------------
-- Icon System  (822 Lucide icons)
-- Usage: just pass the name — no rbxassetid prefix needed
--   GetIcon("eye")               → "rbxassetid://10723346959"
--   GetIcon("lucide-home")       → "rbxassetid://10723407389"
--   GetIcon("rbxassetid://999")  → "rbxassetid://999"  (passthrough)
--   GetIcon(nil) or GetIcon("")  → nil  (safe — nothing shown)
--------------------------------------------------------------------
local LucideIcons = {
	["lucide-mouse-2"]                                        = "rbxassetid://10088146939",
	["lucide-internet"]                                       = "rbxassetid://12785195438",
	["lucide-earth"]                                          = "rbxassetid://115986292591138",
	["lucide-settings-3"]                                     = "rbxassetid://14007344336",
	["lucide-accessibility"]                                  = "rbxassetid://10709751939",
	["lucide-activity"]                                       = "rbxassetid://10709752035",
	["lucide-air-vent"]                                       = "rbxassetid://10709752131",
	["lucide-airplay"]                                        = "rbxassetid://10709752254",
	["lucide-alarm-check"]                                    = "rbxassetid://10709752405",
	["lucide-alarm-clock"]                                    = "rbxassetid://10709752630",
	["lucide-alarm-clock-off"]                                = "rbxassetid://10709752508",
	["lucide-alarm-minus"]                                    = "rbxassetid://10709752732",
	["lucide-alarm-plus"]                                     = "rbxassetid://10709752825",
	["lucide-album"]                                          = "rbxassetid://10709752906",
	["lucide-alert-circle"]                                   = "rbxassetid://10709752996",
	["lucide-alert-octagon"]                                  = "rbxassetid://10709753064",
	["lucide-alert-triangle"]                                 = "rbxassetid://10709753149",
	["lucide-align-center"]                                   = "rbxassetid://10709753570",
	["lucide-align-center-horizontal"]                        = "rbxassetid://10709753272",
	["lucide-align-center-vertical"]                          = "rbxassetid://10709753421",
	["lucide-align-end-horizontal"]                           = "rbxassetid://10709753692",
	["lucide-align-end-vertical"]                             = "rbxassetid://10709753808",
	["lucide-align-horizontal-distribute-center"]             = "rbxassetid://10747779791",
	["lucide-align-horizontal-distribute-end"]                = "rbxassetid://10747784534",
	["lucide-align-horizontal-distribute-start"]              = "rbxassetid://10709754118",
	["lucide-align-horizontal-justify-center"]                = "rbxassetid://10709754204",
	["lucide-align-horizontal-justify-end"]                   = "rbxassetid://10709754317",
	["lucide-align-horizontal-justify-start"]                 = "rbxassetid://10709754436",
	["lucide-align-horizontal-space-around"]                  = "rbxassetid://10709754590",
	["lucide-align-horizontal-space-between"]                 = "rbxassetid://10709754749",
	["lucide-align-justify"]                                  = "rbxassetid://10709759610",
	["lucide-align-left"]                                     = "rbxassetid://10709759764",
	["lucide-align-right"]                                    = "rbxassetid://10709759895",
	["lucide-align-start-horizontal"]                         = "rbxassetid://10709760051",
	["lucide-align-start-vertical"]                           = "rbxassetid://10709760244",
	["lucide-align-vertical-distribute-center"]               = "rbxassetid://10709760351",
	["lucide-align-vertical-distribute-end"]                  = "rbxassetid://10709760434",
	["lucide-align-vertical-distribute-start"]                = "rbxassetid://10709760612",
	["lucide-align-vertical-justify-center"]                  = "rbxassetid://10709760814",
	["lucide-align-vertical-justify-end"]                     = "rbxassetid://10709761003",
	["lucide-align-vertical-justify-start"]                   = "rbxassetid://10709761176",
	["lucide-align-vertical-space-around"]                    = "rbxassetid://10709761324",
	["lucide-align-vertical-space-between"]                   = "rbxassetid://10709761434",
	["lucide-anchor"]                                         = "rbxassetid://10709761530",
	["lucide-angry"]                                          = "rbxassetid://10709761629",
	["lucide-annoyed"]                                        = "rbxassetid://10709761722",
	["lucide-aperture"]                                       = "rbxassetid://10709761813",
	["lucide-apple"]                                          = "rbxassetid://10709761889",
	["lucide-archive"]                                        = "rbxassetid://10709762233",
	["lucide-archive-restore"]                                = "rbxassetid://10709762058",
	["lucide-armchair"]                                       = "rbxassetid://10709762327",
	["lucide-arrow-big-down"]                                 = "rbxassetid://10747796644",
	["lucide-arrow-big-left"]                                 = "rbxassetid://10709762574",
	["lucide-arrow-big-right"]                                = "rbxassetid://10709762727",
	["lucide-arrow-big-up"]                                   = "rbxassetid://10709762879",
	["lucide-arrow-down"]                                     = "rbxassetid://10709767827",
	["lucide-arrow-down-circle"]                              = "rbxassetid://10709763034",
	["lucide-arrow-down-left"]                                = "rbxassetid://10709767656",
	["lucide-arrow-down-right"]                               = "rbxassetid://10709767750",
	["lucide-arrow-left"]                                     = "rbxassetid://10709768114",
	["lucide-arrow-left-circle"]                              = "rbxassetid://10709767936",
	["lucide-arrow-left-right"]                               = "rbxassetid://10709768019",
	["lucide-arrow-right"]                                    = "rbxassetid://10709768347",
	["lucide-arrow-right-circle"]                             = "rbxassetid://10709768226",
	["lucide-arrow-up"]                                       = "rbxassetid://10709768939",
	["lucide-arrow-up-circle"]                                = "rbxassetid://10709768432",
	["lucide-arrow-up-down"]                                  = "rbxassetid://10709768538",
	["lucide-arrow-up-left"]                                  = "rbxassetid://10709768661",
	["lucide-arrow-up-right"]                                 = "rbxassetid://10709768787",
	["lucide-asterisk"]                                       = "rbxassetid://10709769095",
	["lucide-at-sign"]                                        = "rbxassetid://10709769286",
	["lucide-award"]                                          = "rbxassetid://10709769406",
	["lucide-axe"]                                            = "rbxassetid://10709769508",
	["lucide-axis-3d"]                                        = "rbxassetid://10709769598",
	["lucide-baby"]                                           = "rbxassetid://10709769732",
	["lucide-backpack"]                                       = "rbxassetid://10709769841",
	["lucide-baggage-claim"]                                  = "rbxassetid://10709769935",
	["lucide-banana"]                                         = "rbxassetid://10709770005",
	["lucide-banknote"]                                       = "rbxassetid://10709770178",
	["lucide-bar-chart"]                                      = "rbxassetid://10709773755",
	["lucide-bar-chart-2"]                                    = "rbxassetid://10709770317",
	["lucide-bar-chart-3"]                                    = "rbxassetid://10709770431",
	["lucide-bar-chart-4"]                                    = "rbxassetid://10709770560",
	["lucide-bar-chart-horizontal"]                           = "rbxassetid://10709773669",
	["lucide-barcode"]                                        = "rbxassetid://10747360675",
	["lucide-baseline"]                                       = "rbxassetid://10709773863",
	["lucide-bath"]                                           = "rbxassetid://10709773963",
	["lucide-battery"]                                        = "rbxassetid://10709774640",
	["lucide-battery-charging"]                               = "rbxassetid://10709774068",
	["lucide-battery-full"]                                   = "rbxassetid://10709774206",
	["lucide-battery-low"]                                    = "rbxassetid://10709774370",
	["lucide-battery-medium"]                                 = "rbxassetid://10709774513",
	["lucide-beaker"]                                         = "rbxassetid://10709774756",
	["lucide-bed"]                                            = "rbxassetid://10709775036",
	["lucide-bed-double"]                                     = "rbxassetid://10709774864",
	["lucide-bed-single"]                                     = "rbxassetid://10709774968",
	["lucide-beer"]                                           = "rbxassetid://10709775167",
	["lucide-bell"]                                           = "rbxassetid://10709775704",
	["lucide-bell-minus"]                                     = "rbxassetid://10709775241",
	["lucide-bell-off"]                                       = "rbxassetid://10709775320",
	["lucide-bell-plus"]                                      = "rbxassetid://10709775448",
	["lucide-bell-ring"]                                      = "rbxassetid://10709775560",
	["lucide-bike"]                                           = "rbxassetid://10709775894",
	["lucide-binary"]                                         = "rbxassetid://10709776050",
	["lucide-bitcoin"]                                        = "rbxassetid://10709776126",
	["lucide-bluetooth"]                                      = "rbxassetid://10709776655",
	["lucide-bluetooth-connected"]                            = "rbxassetid://10709776240",
	["lucide-bluetooth-off"]                                  = "rbxassetid://10709776344",
	["lucide-bluetooth-searching"]                            = "rbxassetid://10709776501",
	["lucide-bold"]                                           = "rbxassetid://10747813908",
	["lucide-bomb"]                                           = "rbxassetid://10709781460",
	["lucide-bone"]                                           = "rbxassetid://10709781605",
	["lucide-book"]                                           = "rbxassetid://10709781824",
	["lucide-book-open"]                                      = "rbxassetid://10709781717",
	["lucide-bookmark"]                                       = "rbxassetid://10709782154",
	["lucide-bookmark-minus"]                                 = "rbxassetid://10709781919",
	["lucide-bookmark-plus"]                                  = "rbxassetid://10709782044",
	["lucide-bot"]                                            = "rbxassetid://10709782230",
	["lucide-box"]                                            = "rbxassetid://10709782497",
	["lucide-box-select"]                                     = "rbxassetid://10709782342",
	["lucide-boxes"]                                          = "rbxassetid://10709782582",
	["lucide-briefcase"]                                      = "rbxassetid://10709782662",
	["lucide-brush"]                                          = "rbxassetid://10709782758",
	["lucide-bug"]                                            = "rbxassetid://10709782845",
	["lucide-building"]                                       = "rbxassetid://10709783051",
	["lucide-building-2"]                                     = "rbxassetid://10709782939",
	["lucide-bus"]                                            = "rbxassetid://10709783137",
	["lucide-cake"]                                           = "rbxassetid://10709783217",
	["lucide-calculator"]                                     = "rbxassetid://10709783311",
	["lucide-calendar"]                                       = "rbxassetid://10709789505",
	["lucide-calendar-check"]                                 = "rbxassetid://10709783474",
	["lucide-calendar-check-2"]                               = "rbxassetid://10709783392",
	["lucide-calendar-clock"]                                 = "rbxassetid://10709783577",
	["lucide-calendar-days"]                                  = "rbxassetid://10709783673",
	["lucide-calendar-heart"]                                 = "rbxassetid://10709783835",
	["lucide-calendar-minus"]                                 = "rbxassetid://10709783959",
	["lucide-calendar-off"]                                   = "rbxassetid://10709788784",
	["lucide-calendar-plus"]                                  = "rbxassetid://10709788937",
	["lucide-calendar-range"]                                 = "rbxassetid://10709789053",
	["lucide-calendar-search"]                                = "rbxassetid://10709789200",
	["lucide-calendar-x"]                                     = "rbxassetid://10709789407",
	["lucide-calendar-x-2"]                                   = "rbxassetid://10709789329",
	["lucide-camera"]                                         = "rbxassetid://10709789686",
	["lucide-camera-off"]                                     = "rbxassetid://10747822677",
	["lucide-car"]                                            = "rbxassetid://10709789810",
	["lucide-carrot"]                                         = "rbxassetid://10709789960",
	["lucide-cast"]                                           = "rbxassetid://10709790097",
	["lucide-charge"]                                         = "rbxassetid://10709790202",
	["lucide-check"]                                          = "rbxassetid://10709790644",
	["lucide-check-circle"]                                   = "rbxassetid://10709790387",
	["lucide-check-circle-2"]                                 = "rbxassetid://10709790298",
	["lucide-check-square"]                                   = "rbxassetid://10709790537",
	["lucide-chef-hat"]                                       = "rbxassetid://10709790757",
	["lucide-cherry"]                                         = "rbxassetid://10709790875",
	["lucide-chevron-down"]                                   = "rbxassetid://10709790948",
	["lucide-chevron-first"]                                  = "rbxassetid://10709791015",
	["lucide-chevron-last"]                                   = "rbxassetid://10709791130",
	["lucide-chevron-left"]                                   = "rbxassetid://10709791281",
	["lucide-chevron-right"]                                  = "rbxassetid://10709791437",
	["lucide-chevron-up"]                                     = "rbxassetid://10709791523",
	["lucide-chevrons-down"]                                  = "rbxassetid://10709796864",
	["lucide-chevrons-down-up"]                               = "rbxassetid://10709791632",
	["lucide-chevrons-left"]                                  = "rbxassetid://10709797151",
	["lucide-chevrons-left-right"]                            = "rbxassetid://10709797006",
	["lucide-chevrons-right"]                                 = "rbxassetid://10709797382",
	["lucide-chevrons-right-left"]                            = "rbxassetid://10709797274",
	["lucide-chevrons-up"]                                    = "rbxassetid://10709797622",
	["lucide-chevrons-up-down"]                               = "rbxassetid://10709797508",
	["lucide-chrome"]                                         = "rbxassetid://10709797725",
	["lucide-circle"]                                         = "rbxassetid://10709798174",
	["lucide-circle-dot"]                                     = "rbxassetid://10709797837",
	["lucide-circle-ellipsis"]                                = "rbxassetid://10709797985",
	["lucide-circle-slashed"]                                 = "rbxassetid://10709798100",
	["lucide-citrus"]                                         = "rbxassetid://10709798276",
	["lucide-clapperboard"]                                   = "rbxassetid://10709798350",
	["lucide-clipboard"]                                      = "rbxassetid://10709799288",
	["lucide-clipboard-check"]                                = "rbxassetid://10709798443",
	["lucide-clipboard-copy"]                                 = "rbxassetid://10709798574",
	["lucide-clipboard-edit"]                                 = "rbxassetid://10709798682",
	["lucide-clipboard-list"]                                 = "rbxassetid://10709798792",
	["lucide-clipboard-signature"]                            = "rbxassetid://10709798890",
	["lucide-clipboard-type"]                                 = "rbxassetid://10709798999",
	["lucide-clipboard-x"]                                    = "rbxassetid://10709799124",
	["lucide-clock"]                                          = "rbxassetid://10709805144",
	["lucide-clock-1"]                                        = "rbxassetid://10709799535",
	["lucide-clock-10"]                                       = "rbxassetid://10709799718",
	["lucide-clock-11"]                                       = "rbxassetid://10709799818",
	["lucide-clock-12"]                                       = "rbxassetid://10709799962",
	["lucide-clock-2"]                                        = "rbxassetid://10709803876",
	["lucide-clock-3"]                                        = "rbxassetid://10709803989",
	["lucide-clock-4"]                                        = "rbxassetid://10709804164",
	["lucide-clock-5"]                                        = "rbxassetid://10709804291",
	["lucide-clock-6"]                                        = "rbxassetid://10709804435",
	["lucide-clock-7"]                                        = "rbxassetid://10709804599",
	["lucide-clock-8"]                                        = "rbxassetid://10709804784",
	["lucide-clock-9"]                                        = "rbxassetid://10709804996",
	["lucide-cloud"]                                          = "rbxassetid://10709806740",
	["lucide-cloud-cog"]                                      = "rbxassetid://10709805262",
	["lucide-cloud-drizzle"]                                  = "rbxassetid://10709805371",
	["lucide-cloud-fog"]                                      = "rbxassetid://10709805477",
	["lucide-cloud-hail"]                                     = "rbxassetid://10709805596",
	["lucide-cloud-lightning"]                                = "rbxassetid://10709805727",
	["lucide-cloud-moon"]                                     = "rbxassetid://10709805942",
	["lucide-cloud-moon-rain"]                                = "rbxassetid://10709805838",
	["lucide-cloud-off"]                                      = "rbxassetid://10709806060",
	["lucide-cloud-rain"]                                     = "rbxassetid://10709806277",
	["lucide-cloud-rain-wind"]                                = "rbxassetid://10709806166",
	["lucide-cloud-snow"]                                     = "rbxassetid://10709806374",
	["lucide-cloud-sun"]                                      = "rbxassetid://10709806631",
	["lucide-cloud-sun-rain"]                                 = "rbxassetid://10709806475",
	["lucide-cloudy"]                                         = "rbxassetid://10709806859",
	["lucide-clover"]                                         = "rbxassetid://10709806995",
	["lucide-code"]                                           = "rbxassetid://10709810463",
	["lucide-code-2"]                                         = "rbxassetid://10709807111",
	["lucide-codepen"]                                        = "rbxassetid://10709810534",
	["lucide-codesandbox"]                                    = "rbxassetid://10709810676",
	["lucide-coffee"]                                         = "rbxassetid://10709810814",
	["lucide-cog"]                                            = "rbxassetid://10709810948",
	["lucide-coins"]                                          = "rbxassetid://10709811110",
	["lucide-columns"]                                        = "rbxassetid://10709811261",
	["lucide-command"]                                        = "rbxassetid://10709811365",
	["lucide-compass"]                                        = "rbxassetid://10709811445",
	["lucide-component"]                                      = "rbxassetid://10709811595",
	["lucide-concierge-bell"]                                 = "rbxassetid://10709811706",
	["lucide-connection"]                                     = "rbxassetid://10747361219",
	["lucide-contact"]                                        = "rbxassetid://10709811834",
	["lucide-contrast"]                                       = "rbxassetid://10709811939",
	["lucide-cookie"]                                         = "rbxassetid://10709812067",
	["lucide-copy"]                                           = "rbxassetid://10709812159",
	["lucide-copyleft"]                                       = "rbxassetid://10709812251",
	["lucide-copyright"]                                      = "rbxassetid://10709812311",
	["lucide-corner-down-left"]                               = "rbxassetid://10709812396",
	["lucide-corner-down-right"]                              = "rbxassetid://10709812485",
	["lucide-corner-left-down"]                               = "rbxassetid://10709812632",
	["lucide-corner-left-up"]                                 = "rbxassetid://10709812784",
	["lucide-corner-right-down"]                              = "rbxassetid://10709812939",
	["lucide-corner-right-up"]                                = "rbxassetid://10709813094",
	["lucide-corner-up-left"]                                 = "rbxassetid://10709813185",
	["lucide-corner-up-right"]                                = "rbxassetid://10709813281",
	["lucide-cpu"]                                            = "rbxassetid://10709813383",
	["lucide-croissant"]                                      = "rbxassetid://10709818125",
	["lucide-crop"]                                           = "rbxassetid://10709818245",
	["lucide-cross"]                                          = "rbxassetid://10709818399",
	["lucide-crosshair"]                                      = "rbxassetid://10709818534",
	["lucide-crown"]                                          = "rbxassetid://10709818626",
	["lucide-cup-soda"]                                       = "rbxassetid://10709818763",
	["lucide-curly-braces"]                                   = "rbxassetid://10709818847",
	["lucide-currency"]                                       = "rbxassetid://10709818931",
	["lucide-database"]                                       = "rbxassetid://10709818996",
	["lucide-delete"]                                         = "rbxassetid://10709819059",
	["lucide-diamond"]                                        = "rbxassetid://10709819149",
	["lucide-dice-1"]                                         = "rbxassetid://10709819266",
	["lucide-dice-2"]                                         = "rbxassetid://10709819361",
	["lucide-dice-3"]                                         = "rbxassetid://10709819508",
	["lucide-dice-4"]                                         = "rbxassetid://10709819670",
	["lucide-dice-5"]                                         = "rbxassetid://10709819801",
	["lucide-dice-6"]                                         = "rbxassetid://10709819896",
	["lucide-dices"]                                          = "rbxassetid://10723343321",
	["lucide-diff"]                                           = "rbxassetid://10723343416",
	["lucide-disc"]                                           = "rbxassetid://10723343537",
	["lucide-divide"]                                         = "rbxassetid://10723343805",
	["lucide-divide-circle"]                                  = "rbxassetid://10723343636",
	["lucide-divide-square"]                                  = "rbxassetid://10723343737",
	["lucide-dollar-sign"]                                    = "rbxassetid://10723343958",
	["lucide-download"]                                       = "rbxassetid://10723344270",
	["lucide-download-cloud"]                                 = "rbxassetid://10723344088",
	["lucide-droplet"]                                        = "rbxassetid://10723344432",
	["lucide-droplets"]                                       = "rbxassetid://10734883356",
	["lucide-drumstick"]                                      = "rbxassetid://10723344737",
	["lucide-edit"]                                           = "rbxassetid://10734883598",
	["lucide-edit-2"]                                         = "rbxassetid://10723344885",
	["lucide-edit-3"]                                         = "rbxassetid://10723345088",
	["lucide-egg"]                                            = "rbxassetid://10723345518",
	["lucide-egg-fried"]                                      = "rbxassetid://10723345347",
	["lucide-electricity"]                                    = "rbxassetid://10723345749",
	["lucide-electricity-off"]                                = "rbxassetid://10723345643",
	["lucide-equal"]                                          = "rbxassetid://10723345990",
	["lucide-equal-not"]                                      = "rbxassetid://10723345866",
	["lucide-eraser"]                                         = "rbxassetid://10723346158",
	["lucide-euro"]                                           = "rbxassetid://10723346372",
	["lucide-expand"]                                         = "rbxassetid://10723346553",
	["lucide-external-link"]                                  = "rbxassetid://10723346684",
	["lucide-eye"]                                            = "rbxassetid://10723346959",
	["lucide-eye-off"]                                        = "rbxassetid://10723346871",
	["lucide-factory"]                                        = "rbxassetid://10723347051",
	["lucide-fan"]                                            = "rbxassetid://10723354359",
	["lucide-fast-forward"]                                   = "rbxassetid://10723354521",
	["lucide-feather"]                                        = "rbxassetid://10723354671",
	["lucide-figma"]                                          = "rbxassetid://10723354801",
	["lucide-file"]                                           = "rbxassetid://10723374641",
	["lucide-file-archive"]                                   = "rbxassetid://10723354921",
	["lucide-file-audio"]                                     = "rbxassetid://10723355148",
	["lucide-file-audio-2"]                                   = "rbxassetid://10723355026",
	["lucide-file-axis-3d"]                                   = "rbxassetid://10723355272",
	["lucide-file-badge"]                                     = "rbxassetid://10723355622",
	["lucide-file-badge-2"]                                   = "rbxassetid://10723355451",
	["lucide-file-bar-chart"]                                 = "rbxassetid://10723355887",
	["lucide-file-bar-chart-2"]                               = "rbxassetid://10723355746",
	["lucide-file-box"]                                       = "rbxassetid://10723355989",
	["lucide-file-check"]                                     = "rbxassetid://10723356210",
	["lucide-file-check-2"]                                   = "rbxassetid://10723356100",
	["lucide-file-clock"]                                     = "rbxassetid://10723356329",
	["lucide-file-code"]                                      = "rbxassetid://10723356507",
	["lucide-file-cog"]                                       = "rbxassetid://10723356830",
	["lucide-file-cog-2"]                                     = "rbxassetid://10723356676",
	["lucide-file-diff"]                                      = "rbxassetid://10723357039",
	["lucide-file-digit"]                                     = "rbxassetid://10723357151",
	["lucide-file-down"]                                      = "rbxassetid://10723357322",
	["lucide-file-edit"]                                      = "rbxassetid://10723357495",
	["lucide-file-heart"]                                     = "rbxassetid://10723357637",
	["lucide-file-image"]                                     = "rbxassetid://10723357790",
	["lucide-file-input"]                                     = "rbxassetid://10723357933",
	["lucide-file-json"]                                      = "rbxassetid://10723364435",
	["lucide-file-json-2"]                                    = "rbxassetid://10723364361",
	["lucide-file-key"]                                       = "rbxassetid://10723364605",
	["lucide-file-key-2"]                                     = "rbxassetid://10723364515",
	["lucide-file-line-chart"]                                = "rbxassetid://10723364725",
	["lucide-file-lock"]                                      = "rbxassetid://10723364957",
	["lucide-file-lock-2"]                                    = "rbxassetid://10723364861",
	["lucide-file-minus"]                                     = "rbxassetid://10723365254",
	["lucide-file-minus-2"]                                   = "rbxassetid://10723365086",
	["lucide-file-output"]                                    = "rbxassetid://10723365457",
	["lucide-file-pie-chart"]                                 = "rbxassetid://10723365598",
	["lucide-file-plus"]                                      = "rbxassetid://10723365877",
	["lucide-file-plus-2"]                                    = "rbxassetid://10723365766",
	["lucide-file-question"]                                  = "rbxassetid://10723365987",
	["lucide-file-scan"]                                      = "rbxassetid://10723366167",
	["lucide-file-search"]                                    = "rbxassetid://10723366550",
	["lucide-file-search-2"]                                  = "rbxassetid://10723366340",
	["lucide-file-signature"]                                 = "rbxassetid://10723366741",
	["lucide-file-spreadsheet"]                               = "rbxassetid://10723366962",
	["lucide-file-symlink"]                                   = "rbxassetid://10723367098",
	["lucide-file-terminal"]                                  = "rbxassetid://10723367244",
	["lucide-file-text"]                                      = "rbxassetid://10723367380",
	["lucide-file-type"]                                      = "rbxassetid://10723367606",
	["lucide-file-type-2"]                                    = "rbxassetid://10723367509",
	["lucide-file-up"]                                        = "rbxassetid://10723367734",
	["lucide-file-video"]                                     = "rbxassetid://10723373884",
	["lucide-file-video-2"]                                   = "rbxassetid://10723367834",
	["lucide-file-volume"]                                    = "rbxassetid://10723374172",
	["lucide-file-volume-2"]                                  = "rbxassetid://10723374030",
	["lucide-file-warning"]                                   = "rbxassetid://10723374276",
	["lucide-file-x"]                                         = "rbxassetid://10723374544",
	["lucide-file-x-2"]                                       = "rbxassetid://10723374378",
	["lucide-files"]                                          = "rbxassetid://10723374759",
	["lucide-film"]                                           = "rbxassetid://10723374981",
	["lucide-filter"]                                         = "rbxassetid://10723375128",
	["lucide-fingerprint"]                                    = "rbxassetid://10723375250",
	["lucide-flag"]                                           = "rbxassetid://10723375890",
	["lucide-flag-off"]                                       = "rbxassetid://10723375443",
	["lucide-flag-triangle-left"]                             = "rbxassetid://10723375608",
	["lucide-flag-triangle-right"]                            = "rbxassetid://10723375727",
	["lucide-flame"]                                          = "rbxassetid://10723376114",
	["lucide-flashlight"]                                     = "rbxassetid://10723376471",
	["lucide-flashlight-off"]                                 = "rbxassetid://10723376365",
	["lucide-flask-conical"]                                  = "rbxassetid://10734883986",
	["lucide-flask-round"]                                    = "rbxassetid://10723376614",
	["lucide-flip-horizontal"]                                = "rbxassetid://10723376884",
	["lucide-flip-horizontal-2"]                              = "rbxassetid://10723376745",
	["lucide-flip-vertical"]                                  = "rbxassetid://10723377138",
	["lucide-flip-vertical-2"]                                = "rbxassetid://10723377026",
	["lucide-flower"]                                         = "rbxassetid://10747830374",
	["lucide-flower-2"]                                       = "rbxassetid://10723377305",
	["lucide-focus"]                                          = "rbxassetid://10723377537",
	["lucide-folder"]                                         = "rbxassetid://10723387563",
	["lucide-folder-archive"]                                 = "rbxassetid://10723384478",
	["lucide-folder-check"]                                   = "rbxassetid://10723384605",
	["lucide-folder-clock"]                                   = "rbxassetid://10723384731",
	["lucide-folder-closed"]                                  = "rbxassetid://10723384893",
	["lucide-folder-cog"]                                     = "rbxassetid://10723385213",
	["lucide-folder-cog-2"]                                   = "rbxassetid://10723385036",
	["lucide-folder-down"]                                    = "rbxassetid://10723385338",
	["lucide-folder-edit"]                                    = "rbxassetid://10723385445",
	["lucide-folder-heart"]                                   = "rbxassetid://10723385545",
	["lucide-folder-input"]                                   = "rbxassetid://10723385721",
	["lucide-folder-key"]                                     = "rbxassetid://10723385848",
	["lucide-folder-lock"]                                    = "rbxassetid://10723386005",
	["lucide-folder-minus"]                                   = "rbxassetid://10723386127",
	["lucide-folder-open"]                                    = "rbxassetid://10723386277",
	["lucide-folder-output"]                                  = "rbxassetid://10723386386",
	["lucide-folder-plus"]                                    = "rbxassetid://10723386531",
	["lucide-folder-search"]                                  = "rbxassetid://10723386787",
	["lucide-folder-search-2"]                                = "rbxassetid://10723386674",
	["lucide-folder-symlink"]                                 = "rbxassetid://10723386930",
	["lucide-folder-tree"]                                    = "rbxassetid://10723387085",
	["lucide-folder-up"]                                      = "rbxassetid://10723387265",
	["lucide-folder-x"]                                       = "rbxassetid://10723387448",
	["lucide-folders"]                                        = "rbxassetid://10723387721",
	["lucide-form-input"]                                     = "rbxassetid://10723387841",
	["lucide-forward"]                                        = "rbxassetid://10723388016",
	["lucide-frame"]                                          = "rbxassetid://10723394389",
	["lucide-framer"]                                         = "rbxassetid://10723394565",
	["lucide-frown"]                                          = "rbxassetid://10723394681",
	["lucide-fuel"]                                           = "rbxassetid://10723394846",
	["lucide-function-square"]                                = "rbxassetid://10723395041",
	["lucide-gamepad"]                                        = "rbxassetid://10723395457",
	["lucide-gamepad-2"]                                      = "rbxassetid://10723395215",
	["lucide-gauge"]                                          = "rbxassetid://10723395708",
	["lucide-gavel"]                                          = "rbxassetid://10723395896",
	["lucide-gem"]                                            = "rbxassetid://10723396000",
	["lucide-ghost"]                                          = "rbxassetid://10723396107",
	["lucide-gift"]                                           = "rbxassetid://10723396402",
	["lucide-gift-card"]                                      = "rbxassetid://10723396225",
	["lucide-git-branch"]                                     = "rbxassetid://10723396676",
	["lucide-git-branch-plus"]                                = "rbxassetid://10723396542",
	["lucide-git-commit"]                                     = "rbxassetid://10723396812",
	["lucide-git-compare"]                                    = "rbxassetid://10723396954",
	["lucide-git-fork"]                                       = "rbxassetid://10723397049",
	["lucide-git-merge"]                                      = "rbxassetid://10723397165",
	["lucide-git-pull-request"]                               = "rbxassetid://10723397431",
	["lucide-git-pull-request-closed"]                        = "rbxassetid://10723397268",
	["lucide-git-pull-request-draft"]                         = "rbxassetid://10734884302",
	["lucide-glass"]                                          = "rbxassetid://10723397788",
	["lucide-glass-2"]                                        = "rbxassetid://10723397529",
	["lucide-glass-water"]                                    = "rbxassetid://10723397678",
	["lucide-glasses"]                                        = "rbxassetid://10723397895",
	["lucide-globe"]                                          = "rbxassetid://10723404337",
	["lucide-globe-2"]                                        = "rbxassetid://10723398002",
	["lucide-grab"]                                           = "rbxassetid://10723404472",
	["lucide-graduation-cap"]                                 = "rbxassetid://10723404691",
	["lucide-grape"]                                          = "rbxassetid://10723404822",
	["lucide-grid"]                                           = "rbxassetid://10723404936",
	["lucide-grip-horizontal"]                                = "rbxassetid://10723405089",
	["lucide-grip-vertical"]                                  = "rbxassetid://10723405236",
	["lucide-hammer"]                                         = "rbxassetid://10723405360",
	["lucide-hand"]                                           = "rbxassetid://10723405649",
	["lucide-hand-metal"]                                     = "rbxassetid://10723405508",
	["lucide-hard-drive"]                                     = "rbxassetid://10723405749",
	["lucide-hard-hat"]                                       = "rbxassetid://10723405859",
	["lucide-hash"]                                           = "rbxassetid://10723405975",
	["lucide-haze"]                                           = "rbxassetid://10723406078",
	["lucide-headphones"]                                     = "rbxassetid://10723406165",
	["lucide-heart"]                                          = "rbxassetid://10723406885",
	["lucide-heart-crack"]                                    = "rbxassetid://10723406299",
	["lucide-heart-handshake"]                                = "rbxassetid://10723406480",
	["lucide-heart-off"]                                      = "rbxassetid://10723406662",
	["lucide-heart-pulse"]                                    = "rbxassetid://10723406795",
	["lucide-help-circle"]                                    = "rbxassetid://10723406988",
	["lucide-hexagon"]                                        = "rbxassetid://10723407092",
	["lucide-highlighter"]                                    = "rbxassetid://10723407192",
	["lucide-history"]                                        = "rbxassetid://10723407335",
	["lucide-home"]                                           = "rbxassetid://10723407389",
	["lucide-hourglass"]                                      = "rbxassetid://10723407498",
	["lucide-ice-cream"]                                      = "rbxassetid://10723414308",
	["lucide-image"]                                          = "rbxassetid://10723415040",
	["lucide-image-minus"]                                    = "rbxassetid://10723414487",
	["lucide-image-off"]                                      = "rbxassetid://10723414677",
	["lucide-image-plus"]                                     = "rbxassetid://10723414827",
	["lucide-import"]                                         = "rbxassetid://10723415205",
	["lucide-inbox"]                                          = "rbxassetid://10723415335",
	["lucide-indent"]                                         = "rbxassetid://10723415494",
	["lucide-indian-rupee"]                                   = "rbxassetid://10723415642",
	["lucide-infinity"]                                       = "rbxassetid://10723415766",
	["lucide-info"]                                           = "rbxassetid://10723415903",
	["lucide-inspect"]                                        = "rbxassetid://10723416057",
	["lucide-italic"]                                         = "rbxassetid://10723416195",
	["lucide-japanese-yen"]                                   = "rbxassetid://10723416363",
	["lucide-joystick"]                                       = "rbxassetid://10723416527",
	["lucide-key"]                                            = "rbxassetid://10723416652",
	["lucide-keyboard"]                                       = "rbxassetid://10723416765",
	["lucide-lamp"]                                           = "rbxassetid://10723417513",
	["lucide-lamp-ceiling"]                                   = "rbxassetid://10723416922",
	["lucide-lamp-desk"]                                      = "rbxassetid://10723417016",
	["lucide-lamp-floor"]                                     = "rbxassetid://10723417131",
	["lucide-lamp-wall-down"]                                 = "rbxassetid://10723417240",
	["lucide-lamp-wall-up"]                                   = "rbxassetid://10723417356",
	["lucide-landmark"]                                       = "rbxassetid://10723417608",
	["lucide-languages"]                                      = "rbxassetid://10723417703",
	["lucide-laptop"]                                         = "rbxassetid://10723423881",
	["lucide-laptop-2"]                                       = "rbxassetid://10723417797",
	["lucide-lasso"]                                          = "rbxassetid://10723424235",
	["lucide-lasso-select"]                                   = "rbxassetid://10723424058",
	["lucide-laugh"]                                          = "rbxassetid://10723424372",
	["lucide-layers"]                                         = "rbxassetid://10723424505",
	["lucide-layout"]                                         = "rbxassetid://10723425376",
	["lucide-layout-dashboard"]                               = "rbxassetid://10723424646",
	["lucide-layout-grid"]                                    = "rbxassetid://10723424838",
	["lucide-layout-list"]                                    = "rbxassetid://10723424963",
	["lucide-layout-template"]                                = "rbxassetid://10723425187",
	["lucide-leaf"]                                           = "rbxassetid://10723425539",
	["lucide-library"]                                        = "rbxassetid://10723425615",
	["lucide-life-buoy"]                                      = "rbxassetid://10723425685",
	["lucide-lightbulb"]                                      = "rbxassetid://10723425852",
	["lucide-lightbulb-off"]                                  = "rbxassetid://10723425762",
	["lucide-line-chart"]                                     = "rbxassetid://10723426393",
	["lucide-link"]                                           = "rbxassetid://10723426722",
	["lucide-link-2"]                                         = "rbxassetid://10723426595",
	["lucide-link-2-off"]                                     = "rbxassetid://10723426513",
	["lucide-list"]                                           = "rbxassetid://10723433811",
	["lucide-list-checks"]                                    = "rbxassetid://10734884548",
	["lucide-list-end"]                                       = "rbxassetid://10723426886",
	["lucide-list-minus"]                                     = "rbxassetid://10723426986",
	["lucide-list-music"]                                     = "rbxassetid://10723427081",
	["lucide-list-ordered"]                                   = "rbxassetid://10723427199",
	["lucide-list-plus"]                                      = "rbxassetid://10723427334",
	["lucide-list-start"]                                     = "rbxassetid://10723427494",
	["lucide-list-video"]                                     = "rbxassetid://10723427619",
	["lucide-list-x"]                                         = "rbxassetid://10723433655",
	["lucide-loader"]                                         = "rbxassetid://10723434070",
	["lucide-loader-2"]                                       = "rbxassetid://10723433935",
	["lucide-locate"]                                         = "rbxassetid://10723434557",
	["lucide-locate-fixed"]                                   = "rbxassetid://10723434236",
	["lucide-locate-off"]                                     = "rbxassetid://10723434379",
	["lucide-lock"]                                           = "rbxassetid://10723434711",
	["lucide-log-in"]                                         = "rbxassetid://10723434830",
	["lucide-log-out"]                                        = "rbxassetid://10723434906",
	["lucide-luggage"]                                        = "rbxassetid://10723434993",
	["lucide-magnet"]                                         = "rbxassetid://10723435069",
	["lucide-mail"]                                           = "rbxassetid://10734885430",
	["lucide-mail-check"]                                     = "rbxassetid://10723435182",
	["lucide-mail-minus"]                                     = "rbxassetid://10723435261",
	["lucide-mail-open"]                                      = "rbxassetid://10723435342",
	["lucide-mail-plus"]                                      = "rbxassetid://10723435443",
	["lucide-mail-question"]                                  = "rbxassetid://10723435515",
	["lucide-mail-search"]                                    = "rbxassetid://10734884739",
	["lucide-mail-warning"]                                   = "rbxassetid://10734885015",
	["lucide-mail-x"]                                         = "rbxassetid://10734885247",
	["lucide-mails"]                                          = "rbxassetid://10734885614",
	["lucide-map"]                                            = "rbxassetid://10734886202",
	["lucide-map-pin"]                                        = "rbxassetid://10734886004",
	["lucide-map-pin-off"]                                    = "rbxassetid://10734885803",
	["lucide-maximize"]                                       = "rbxassetid://10734886735",
	["lucide-maximize-2"]                                     = "rbxassetid://10734886496",
	["lucide-medal"]                                          = "rbxassetid://10734887072",
	["lucide-megaphone"]                                      = "rbxassetid://10734887454",
	["lucide-megaphone-off"]                                  = "rbxassetid://10734887311",
	["lucide-meh"]                                            = "rbxassetid://10734887603",
	["lucide-menu"]                                           = "rbxassetid://10734887784",
	["lucide-message-circle"]                                 = "rbxassetid://10734888000",
	["lucide-message-square"]                                 = "rbxassetid://10734888228",
	["lucide-mic"]                                            = "rbxassetid://10734888864",
	["lucide-mic-2"]                                          = "rbxassetid://10734888430",
	["lucide-mic-off"]                                        = "rbxassetid://10734888646",
	["lucide-microscope"]                                     = "rbxassetid://10734889106",
	["lucide-microwave"]                                      = "rbxassetid://10734895076",
	["lucide-milestone"]                                      = "rbxassetid://10734895310",
	["lucide-minimize"]                                       = "rbxassetid://10734895698",
	["lucide-minimize-2"]                                     = "rbxassetid://10734895530",
	["lucide-minus"]                                          = "rbxassetid://10734896206",
	["lucide-minus-circle"]                                   = "rbxassetid://10734895856",
	["lucide-minus-square"]                                   = "rbxassetid://10734896029",
	["lucide-monitor"]                                        = "rbxassetid://10734896881",
	["lucide-monitor-off"]                                    = "rbxassetid://10734896360",
	["lucide-monitor-speaker"]                                = "rbxassetid://10734896512",
	["lucide-moon"]                                           = "rbxassetid://10734897102",
	["lucide-more-horizontal"]                                = "rbxassetid://10734897250",
	["lucide-more-vertical"]                                  = "rbxassetid://10734897387",
	["lucide-mountain"]                                       = "rbxassetid://10734897956",
	["lucide-mountain-snow"]                                  = "rbxassetid://10734897665",
	["lucide-mouse"]                                          = "rbxassetid://10734898592",
	["lucide-mouse-pointer"]                                  = "rbxassetid://10734898476",
	["lucide-mouse-pointer-2"]                                = "rbxassetid://10734898194",
	["lucide-mouse-pointer-click"]                            = "rbxassetid://10734898355",
	["lucide-move"]                                           = "rbxassetid://10734900011",
	["lucide-move-3d"]                                        = "rbxassetid://10734898756",
	["lucide-move-diagonal"]                                  = "rbxassetid://10734899164",
	["lucide-move-diagonal-2"]                                = "rbxassetid://10734898934",
	["lucide-move-horizontal"]                                = "rbxassetid://10734899414",
	["lucide-move-vertical"]                                  = "rbxassetid://10734899821",
	["lucide-music"]                                          = "rbxassetid://10734905958",
	["lucide-music-2"]                                        = "rbxassetid://10734900215",
	["lucide-music-3"]                                        = "rbxassetid://10734905665",
	["lucide-music-4"]                                        = "rbxassetid://10734905823",
	["lucide-navigation"]                                     = "rbxassetid://10734906744",
	["lucide-navigation-2"]                                   = "rbxassetid://10734906332",
	["lucide-navigation-2-off"]                               = "rbxassetid://10734906144",
	["lucide-navigation-off"]                                 = "rbxassetid://10734906580",
	["lucide-network"]                                        = "rbxassetid://10734906975",
	["lucide-newspaper"]                                      = "rbxassetid://10734907168",
	["lucide-octagon"]                                        = "rbxassetid://10734907361",
	["lucide-option"]                                         = "rbxassetid://10734907649",
	["lucide-outdent"]                                        = "rbxassetid://10734907933",
	["lucide-package"]                                        = "rbxassetid://10734909540",
	["lucide-package-2"]                                      = "rbxassetid://10734908151",
	["lucide-package-check"]                                  = "rbxassetid://10734908384",
	["lucide-package-minus"]                                  = "rbxassetid://10734908626",
	["lucide-package-open"]                                   = "rbxassetid://10734908793",
	["lucide-package-plus"]                                   = "rbxassetid://10734909016",
	["lucide-package-search"]                                 = "rbxassetid://10734909196",
	["lucide-package-x"]                                      = "rbxassetid://10734909375",
	["lucide-paint-bucket"]                                   = "rbxassetid://10734909847",
	["lucide-paintbrush"]                                     = "rbxassetid://10734910187",
	["lucide-paintbrush-2"]                                   = "rbxassetid://10734910030",
	["lucide-palette"]                                        = "rbxassetid://10734910430",
	["lucide-palmtree"]                                       = "rbxassetid://10734910680",
	["lucide-paperclip"]                                      = "rbxassetid://10734910927",
	["lucide-party-popper"]                                   = "rbxassetid://10734918735",
	["lucide-pause"]                                          = "rbxassetid://10734919336",
	["lucide-pause-circle"]                                   = "rbxassetid://10735024209",
	["lucide-pause-octagon"]                                  = "rbxassetid://10734919143",
	["lucide-pen-tool"]                                       = "rbxassetid://10734919503",
	["lucide-pencil"]                                         = "rbxassetid://10734919691",
	["lucide-percent"]                                        = "rbxassetid://10734919919",
	["lucide-person-standing"]                                = "rbxassetid://10734920149",
	["lucide-phone"]                                          = "rbxassetid://10734921524",
	["lucide-phone-call"]                                     = "rbxassetid://10734920305",
	["lucide-phone-forwarded"]                                = "rbxassetid://10734920508",
	["lucide-phone-incoming"]                                 = "rbxassetid://10734920694",
	["lucide-phone-missed"]                                   = "rbxassetid://10734920845",
	["lucide-phone-off"]                                      = "rbxassetid://10734921077",
	["lucide-phone-outgoing"]                                 = "rbxassetid://10734921288",
	["lucide-pie-chart"]                                      = "rbxassetid://10734921727",
	["lucide-piggy-bank"]                                     = "rbxassetid://10734921935",
	["lucide-pin"]                                            = "rbxassetid://10734922324",
	["lucide-pin-off"]                                        = "rbxassetid://10734922180",
	["lucide-pipette"]                                        = "rbxassetid://10734922497",
	["lucide-pizza"]                                          = "rbxassetid://10734922774",
	["lucide-plane"]                                          = "rbxassetid://10734922971",
	["lucide-play"]                                           = "rbxassetid://10734923549",
	["lucide-play-circle"]                                    = "rbxassetid://10734923214",
	["lucide-plus"]                                           = "rbxassetid://10734924532",
	["lucide-plus-circle"]                                    = "rbxassetid://10734923868",
	["lucide-plus-square"]                                    = "rbxassetid://10734924219",
	["lucide-podcast"]                                        = "rbxassetid://10734929553",
	["lucide-pointer"]                                        = "rbxassetid://10734929723",
	["lucide-pound-sterling"]                                 = "rbxassetid://10734929981",
	["lucide-power"]                                          = "rbxassetid://10734930466",
	["lucide-power-off"]                                      = "rbxassetid://10734930257",
	["lucide-printer"]                                        = "rbxassetid://10734930632",
	["lucide-puzzle"]                                         = "rbxassetid://10734930886",
	["lucide-quote"]                                          = "rbxassetid://10734931234",
	["lucide-radio"]                                          = "rbxassetid://10734931596",
	["lucide-radio-receiver"]                                 = "rbxassetid://10734931402",
	["lucide-rectangle-horizontal"]                           = "rbxassetid://10734931777",
	["lucide-rectangle-vertical"]                             = "rbxassetid://10734932081",
	["lucide-recycle"]                                        = "rbxassetid://10734932295",
	["lucide-redo"]                                           = "rbxassetid://10734932822",
	["lucide-redo-2"]                                         = "rbxassetid://10734932586",
	["lucide-refresh-ccw"]                                    = "rbxassetid://10734933056",
	["lucide-refresh-cw"]                                     = "rbxassetid://10734933222",
	["lucide-refrigerator"]                                   = "rbxassetid://10734933465",
	["lucide-regex"]                                          = "rbxassetid://10734933655",
	["lucide-repeat"]                                         = "rbxassetid://10734933966",
	["lucide-repeat-1"]                                       = "rbxassetid://10734933826",
	["lucide-reply"]                                          = "rbxassetid://10734934252",
	["lucide-reply-all"]                                      = "rbxassetid://10734934132",
	["lucide-rewind"]                                         = "rbxassetid://10734934347",
	["lucide-rocket"]                                         = "rbxassetid://10734934585",
	["lucide-rocking-chair"]                                  = "rbxassetid://10734939942",
	["lucide-rotate-3d"]                                      = "rbxassetid://10734940107",
	["lucide-rotate-ccw"]                                     = "rbxassetid://10734940376",
	["lucide-rotate-cw"]                                      = "rbxassetid://10734940654",
	["lucide-rss"]                                            = "rbxassetid://10734940825",
	["lucide-ruler"]                                          = "rbxassetid://10734941018",
	["lucide-russian-ruble"]                                  = "rbxassetid://10734941199",
	["lucide-sailboat"]                                       = "rbxassetid://10734941354",
	["lucide-save"]                                           = "rbxassetid://10734941499",
	["lucide-scale"]                                          = "rbxassetid://10734941912",
	["lucide-scale-3d"]                                       = "rbxassetid://10734941739",
	["lucide-scaling"]                                        = "rbxassetid://10734942072",
	["lucide-scan"]                                           = "rbxassetid://10734942565",
	["lucide-scan-face"]                                      = "rbxassetid://10734942198",
	["lucide-scan-line"]                                      = "rbxassetid://10734942351",
	["lucide-scissors"]                                       = "rbxassetid://10734942778",
	["lucide-screen-share"]                                   = "rbxassetid://10734943193",
	["lucide-screen-share-off"]                               = "rbxassetid://10734942967",
	["lucide-scroll"]                                         = "rbxassetid://10734943448",
	["lucide-search"]                                         = "rbxassetid://10734943674",
	["lucide-send"]                                           = "rbxassetid://10734943902",
	["lucide-separator-horizontal"]                           = "rbxassetid://10734944115",
	["lucide-separator-vertical"]                             = "rbxassetid://10734944326",
	["lucide-server"]                                         = "rbxassetid://10734949856",
	["lucide-server-cog"]                                     = "rbxassetid://10734944444",
	["lucide-server-crash"]                                   = "rbxassetid://10734944554",
	["lucide-server-off"]                                     = "rbxassetid://10734944668",
	["lucide-settings"]                                       = "rbxassetid://10734950309",
	["lucide-settings-2"]                                     = "rbxassetid://10734950020",
	["lucide-share"]                                          = "rbxassetid://10734950813",
	["lucide-share-2"]                                        = "rbxassetid://10734950553",
	["lucide-sheet"]                                          = "rbxassetid://10734951038",
	["lucide-shield"]                                         = "rbxassetid://10734951847",
	["lucide-shield-alert"]                                   = "rbxassetid://10734951173",
	["lucide-shield-check"]                                   = "rbxassetid://10734951367",
	["lucide-shield-close"]                                   = "rbxassetid://10734951535",
	["lucide-shield-off"]                                     = "rbxassetid://10734951684",
	["lucide-shirt"]                                          = "rbxassetid://10734952036",
	["lucide-shopping-bag"]                                   = "rbxassetid://10734952273",
	["lucide-shopping-cart"]                                  = "rbxassetid://10734952479",
	["lucide-shovel"]                                         = "rbxassetid://10734952773",
	["lucide-shower-head"]                                    = "rbxassetid://10734952942",
	["lucide-shrink"]                                         = "rbxassetid://10734953073",
	["lucide-shrub"]                                          = "rbxassetid://10734953241",
	["lucide-shuffle"]                                        = "rbxassetid://10734953451",
	["lucide-sidebar"]                                        = "rbxassetid://10734954301",
	["lucide-sidebar-close"]                                  = "rbxassetid://10734953715",
	["lucide-sidebar-open"]                                   = "rbxassetid://10734954000",
	["lucide-sigma"]                                          = "rbxassetid://10734954538",
	["lucide-signal"]                                         = "rbxassetid://10734961133",
	["lucide-signal-high"]                                    = "rbxassetid://10734954807",
	["lucide-signal-low"]                                     = "rbxassetid://10734955080",
	["lucide-signal-medium"]                                  = "rbxassetid://10734955336",
	["lucide-signal-zero"]                                    = "rbxassetid://10734960878",
	["lucide-siren"]                                          = "rbxassetid://10734961284",
	["lucide-skip-back"]                                      = "rbxassetid://10734961526",
	["lucide-skip-forward"]                                   = "rbxassetid://10734961809",
	["lucide-skull"]                                          = "rbxassetid://10734962068",
	["lucide-slack"]                                          = "rbxassetid://10734962339",
	["lucide-slash"]                                          = "rbxassetid://10734962600",
	["lucide-slice"]                                          = "rbxassetid://10734963024",
	["lucide-sliders"]                                        = "rbxassetid://10734963400",
	["lucide-sliders-horizontal"]                             = "rbxassetid://10734963191",
	["lucide-smartphone"]                                     = "rbxassetid://10734963940",
	["lucide-smartphone-charging"]                            = "rbxassetid://10734963671",
	["lucide-smile"]                                          = "rbxassetid://10734964441",
	["lucide-smile-plus"]                                     = "rbxassetid://10734964188",
	["lucide-snowflake"]                                      = "rbxassetid://10734964600",
	["lucide-sofa"]                                           = "rbxassetid://10734964852",
	["lucide-sort-asc"]                                       = "rbxassetid://10734965115",
	["lucide-sort-desc"]                                      = "rbxassetid://10734965287",
	["lucide-speaker"]                                        = "rbxassetid://10734965419",
	["lucide-sprout"]                                         = "rbxassetid://10734965572",
	["lucide-square"]                                         = "rbxassetid://10734965702",
	["lucide-star"]                                           = "rbxassetid://10734966248",
	["lucide-star-half"]                                      = "rbxassetid://10734965897",
	["lucide-star-off"]                                       = "rbxassetid://10734966097",
	["lucide-stethoscope"]                                    = "rbxassetid://10734966384",
	["lucide-sticker"]                                        = "rbxassetid://10734972234",
	["lucide-sticky-note"]                                    = "rbxassetid://10734972463",
	["lucide-stop-circle"]                                    = "rbxassetid://10734972621",
	["lucide-stretch-horizontal"]                             = "rbxassetid://10734972862",
	["lucide-stretch-vertical"]                               = "rbxassetid://10734973130",
	["lucide-strikethrough"]                                  = "rbxassetid://10734973290",
	["lucide-subscript"]                                      = "rbxassetid://10734973457",
	["lucide-sun"]                                            = "rbxassetid://10734974297",
	["lucide-sun-dim"]                                        = "rbxassetid://10734973645",
	["lucide-sun-medium"]                                     = "rbxassetid://10734973778",
	["lucide-sun-moon"]                                       = "rbxassetid://10734973999",
	["lucide-sun-snow"]                                       = "rbxassetid://10734974130",
	["lucide-sunrise"]                                        = "rbxassetid://10734974522",
	["lucide-sunset"]                                         = "rbxassetid://10734974689",
	["lucide-superscript"]                                    = "rbxassetid://10734974850",
	["lucide-swiss-franc"]                                    = "rbxassetid://10734975024",
	["lucide-switch-camera"]                                  = "rbxassetid://10734975214",
	["lucide-sword"]                                          = "rbxassetid://10734975486",
	["lucide-swords"]                                         = "rbxassetid://10734975692",
	["lucide-syringe"]                                        = "rbxassetid://10734975932",
	["lucide-table"]                                          = "rbxassetid://10734976230",
	["lucide-table-2"]                                        = "rbxassetid://10734976097",
	["lucide-tablet"]                                         = "rbxassetid://10734976394",
	["lucide-tag"]                                            = "rbxassetid://10734976528",
	["lucide-tags"]                                           = "rbxassetid://10734976739",
	["lucide-target"]                                         = "rbxassetid://10734977012",
	["lucide-tent"]                                           = "rbxassetid://10734981750",
	["lucide-terminal"]                                       = "rbxassetid://10734982144",
	["lucide-terminal-square"]                                = "rbxassetid://10734981995",
	["lucide-text-cursor"]                                    = "rbxassetid://10734982395",
	["lucide-text-cursor-input"]                              = "rbxassetid://10734982297",
	["lucide-thermometer"]                                    = "rbxassetid://10734983134",
	["lucide-thermometer-snowflake"]                          = "rbxassetid://10734982571",
	["lucide-thermometer-sun"]                                = "rbxassetid://10734982771",
	["lucide-thumbs-down"]                                    = "rbxassetid://10734983359",
	["lucide-thumbs-up"]                                      = "rbxassetid://10734983629",
	["lucide-ticket"]                                         = "rbxassetid://10734983868",
	["lucide-timer"]                                          = "rbxassetid://10734984606",
	["lucide-timer-off"]                                      = "rbxassetid://10734984138",
	["lucide-timer-reset"]                                    = "rbxassetid://10734984355",
	["lucide-toggle-left"]                                    = "rbxassetid://10734984834",
	["lucide-toggle-right"]                                   = "rbxassetid://10734985040",
	["lucide-tornado"]                                        = "rbxassetid://10734985247",
	["lucide-toy-brick"]                                      = "rbxassetid://10747361919",
	["lucide-train"]                                          = "rbxassetid://10747362105",
	["lucide-trash"]                                          = "rbxassetid://10747362393",
	["lucide-trash-2"]                                        = "rbxassetid://10747362241",
	["lucide-tree-deciduous"]                                 = "rbxassetid://10747362534",
	["lucide-tree-pine"]                                      = "rbxassetid://10747362748",
	["lucide-trees"]                                          = "rbxassetid://10747363016",
	["lucide-trending-down"]                                  = "rbxassetid://10747363205",
	["lucide-trending-up"]                                    = "rbxassetid://10747363465",
	["lucide-triangle"]                                       = "rbxassetid://10747363621",
	["lucide-trophy"]                                         = "rbxassetid://10747363809",
	["lucide-truck"]                                          = "rbxassetid://10747364031",
	["lucide-tv"]                                             = "rbxassetid://10747364593",
	["lucide-tv-2"]                                           = "rbxassetid://10747364302",
	["lucide-type"]                                           = "rbxassetid://10747364761",
	["lucide-umbrella"]                                       = "rbxassetid://10747364971",
	["lucide-underline"]                                      = "rbxassetid://10747365191",
	["lucide-undo"]                                           = "rbxassetid://10747365484",
	["lucide-undo-2"]                                         = "rbxassetid://10747365359",
	["lucide-unlink"]                                         = "rbxassetid://10747365771",
	["lucide-unlink-2"]                                       = "rbxassetid://10747397871",
	["lucide-unlock"]                                         = "rbxassetid://10747366027",
	["lucide-upload"]                                         = "rbxassetid://10747366434",
	["lucide-upload-cloud"]                                   = "rbxassetid://10747366266",
	["lucide-usb"]                                            = "rbxassetid://10747366606",
	["lucide-user"]                                           = "rbxassetid://10747373176",
	["lucide-user-check"]                                     = "rbxassetid://10747371901",
	["lucide-user-cog"]                                       = "rbxassetid://10747372167",
	["lucide-user-minus"]                                     = "rbxassetid://10747372346",
	["lucide-user-plus"]                                      = "rbxassetid://10747372702",
	["lucide-user-x"]                                         = "rbxassetid://10747372992",
	["lucide-users"]                                          = "rbxassetid://10747373426",
	["lucide-utensils"]                                       = "rbxassetid://10747373821",
	["lucide-utensils-crossed"]                               = "rbxassetid://10747373629",
	["lucide-venetian-mask"]                                  = "rbxassetid://10747374003",
	["lucide-verified"]                                       = "rbxassetid://10747374131",
	["lucide-vibrate"]                                        = "rbxassetid://10747374489",
	["lucide-vibrate-off"]                                    = "rbxassetid://10747374269",
	["lucide-video"]                                          = "rbxassetid://10747374938",
	["lucide-video-off"]                                      = "rbxassetid://10747374721",
	["lucide-view"]                                           = "rbxassetid://10747375132",
	["lucide-voicemail"]                                      = "rbxassetid://10747375281",
	["lucide-volume"]                                         = "rbxassetid://10747376008",
	["lucide-volume-1"]                                       = "rbxassetid://10747375450",
	["lucide-volume-2"]                                       = "rbxassetid://10747375679",
	["lucide-volume-x"]                                       = "rbxassetid://10747375880",
	["lucide-wallet"]                                         = "rbxassetid://10747376205",
	["lucide-wand"]                                           = "rbxassetid://10747376565",
	["lucide-wand-2"]                                         = "rbxassetid://10747376349",
	["lucide-watch"]                                          = "rbxassetid://10747376722",
	["lucide-waves"]                                          = "rbxassetid://10747376931",
	["lucide-webcam"]                                         = "rbxassetid://10747381992",
	["lucide-wifi"]                                           = "rbxassetid://10747382504",
	["lucide-wifi-off"]                                       = "rbxassetid://10747382268",
	["lucide-wind"]                                           = "rbxassetid://10747382750",
	["lucide-wrap-text"]                                      = "rbxassetid://10747383065",
	["lucide-wrench"]                                         = "rbxassetid://10747383470",
	["lucide-x"]                                              = "rbxassetid://10747384394",
	["lucide-x-circle"]                                       = "rbxassetid://10747383819",
	["lucide-x-octagon"]                                      = "rbxassetid://10747384037",
	["lucide-x-square"]                                       = "rbxassetid://10747384217",
	["lucide-zoom-in"]                                        = "rbxassetid://10747384552",
	["lucide-zoom-out"]                                       = "rbxassetid://10747384679",
}

local function GetIcon(name)
    if not name or name == "" then return nil end
    local n = tostring(name)
    -- 1. Shorthand: "eye" → LucideIcons["lucide-eye"]
    local v = LucideIcons["lucide-" .. n]
    if v then return v end
    -- 2. Exact key: "lucide-home" → LucideIcons["lucide-home"]
    v = LucideIcons[n]
    if v then return v end
    -- 3. Raw passthrough: "rbxassetid://..." or numeric string
    return n
end

function Library:GetIcon(name)    return GetIcon(name) end
function Library:ResolveIcon(name) return GetIcon(name) end

--------------------------------------------------------------------
-- Notification System
--------------------------------------------------------------------
local NotifGui    = Library:Create("ScreenGui", {
    Name           = "VitaNotifications",
    Parent         = Library:Parent(),
    ZIndexBehavior = Enum.ZIndexBehavior.Global,
    IgnoreGuiInset = true,
    ResetOnSpawn   = false,
})
local NotifHolder = Library:Create("Frame", {
    Name                   = "Holder",
    Parent                 = NotifGui,
    BackgroundTransparency = 1,
    AnchorPoint            = Vector2.new(1, 1),
    Position               = UDim2.new(1,-15,1,-15),
    Size                   = UDim2.new(0, 275, 1,-30),
})
Library:Create("UIListLayout", {
    Parent            = NotifHolder,
    VerticalAlignment = Enum.VerticalAlignment.Bottom,
    FillDirection     = Enum.FillDirection.Vertical,
    SortOrder         = Enum.SortOrder.LayoutOrder,
    Padding           = UDim.new(0, 8),
})

function Library:Notification(args)
    local title    = args.Title    or "Notification"
    local desc     = args.Desc     or ""
    local duration = args.Duration or 3
    local ntype    = args.Type     or "Info"

    local colors = {
        Info    = Color3.fromRGB(100,149,237),
        Success = Color3.fromRGB(50, 200,100),
        Warning = Color3.fromRGB(255,165,0),
        Error   = Color3.fromRGB(220,50, 50),
    }
    local accent = colors[ntype] or colors.Info

    local notif = Library:Create("Frame", {
        Name                   = "Notif",
        Parent                 = NotifHolder,
        BackgroundColor3       = Color3.fromRGB(13,13,13),
        BackgroundTransparency = 1,
        BorderSizePixel        = 0,
        AutomaticSize          = Enum.AutomaticSize.Y,
        Size                   = UDim2.new(1,0,0,0),
        ClipsDescendants       = false,
    })
    Library:Create("UICorner",  { Parent = notif, CornerRadius = UDim.new(0,6) })
    Library:Create("UIStroke",  { Parent = notif, Color = Color3.fromRGB(30,30,30), Thickness = 0.5 })

    Library:Create("Frame", {
        Parent           = notif,
        BackgroundColor3 = accent,
        BorderSizePixel  = 0,
        Size             = UDim2.new(0,3,1,0),
    })

    local content = Library:Create("Frame", {
        Parent                 = notif,
        BackgroundTransparency = 1,
        Position               = UDim2.new(0,12,0,0),
        Size                   = UDim2.new(1,-12,1,0),
        AutomaticSize          = Enum.AutomaticSize.Y,
    })
    Library:Create("UIPadding",    { Parent = content, PaddingTop = UDim.new(0,10), PaddingBottom = UDim.new(0,10), PaddingRight = UDim.new(0,10) })
    Library:Create("UIListLayout", { Parent = content, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0,4) })

    Library:Create("TextLabel", {
        Parent                 = content,
        BackgroundTransparency = 1,
        BorderSizePixel        = 0,
        Size                   = UDim2.new(1,0,0,14),
        Font                   = Enum.Font.GothamBold,
        Text                   = title,
        TextColor3             = accent,
        TextSize               = 13,
        TextXAlignment         = Enum.TextXAlignment.Left,
        RichText               = true,
    })
    Library:Create("TextLabel", {
        Parent                 = content,
        BackgroundTransparency = 1,
        BorderSizePixel        = 0,
        AutomaticSize          = Enum.AutomaticSize.Y,
        Size                   = UDim2.new(1,0,0,0),
        Font                   = Enum.Font.GothamMedium,
        Text                   = desc,
        TextColor3             = Color3.fromRGB(200,200,200),
        TextSize               = 11,
        TextTransparency       = 0.15,
        TextXAlignment         = Enum.TextXAlignment.Left,
        TextWrapped            = true,
        RichText               = true,
    })

    local progBg = Library:Create("Frame", {
        Parent           = content,
        BackgroundColor3 = Color3.fromRGB(30,30,30),
        BorderSizePixel  = 0,
        Size             = UDim2.new(1,0,0,2),
    })
    Library:Create("UICorner", { Parent = progBg, CornerRadius = UDim.new(1,0) })
    local progFill = Library:Create("Frame", {
        Parent           = progBg,
        BackgroundColor3 = accent,
        BorderSizePixel  = 0,
        Size             = UDim2.new(1,0,1,0),
    })
    Library:Create("UICorner", { Parent = progFill, CornerRadius = UDim.new(1,0) })

    TweenService:Create(notif, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { BackgroundTransparency = 0 }):Play()
    TweenService:Create(progFill, TweenInfo.new(duration, Enum.EasingStyle.Linear), { Size = UDim2.new(0,0,1,0) }):Play()

    task.delay(duration, function()
        TweenService:Create(notif, TweenInfo.new(0.3), { BackgroundTransparency = 1 }):Play()
        task.wait(0.35)
        if notif and notif.Parent then notif:Destroy() end
    end)

    return notif
end

--------------------------------------------------------------------
-- Row builder (shared by Toggle, Button, Dropdown, Keybind, etc.)
-- Returns the Rows frame. Children: Rows.Vec.Left.Text, Rows.Vec.Right
--------------------------------------------------------------------
local function MakeRows(parent, title, desc, T, trackFn, iconName)
    local tr = trackFn or function() end
    local icon = GetIcon(iconName)  -- nil when no icon given

    local rows = Library:Create("Frame", {
        Name             = "Rows",
        Parent           = parent,
        BackgroundColor3 = T.Row,
        BorderSizePixel  = 0,
        AutomaticSize    = Enum.AutomaticSize.Y,
        Size             = UDim2.new(1,0,0,0),
    })
    tr("Row",    rows, "BackgroundColor3")
    local stroke = Library:Create("UIStroke",  { Parent = rows, Color = T.Stroke, Thickness = 0.5 })
    tr("Stroke", stroke, "Color")
    Library:Create("UICorner",     { Parent = rows, CornerRadius = UDim.new(0,4) })
    Library:Create("UIListLayout", {
        Parent            = rows,
        FillDirection     = Enum.FillDirection.Horizontal,
        SortOrder         = Enum.SortOrder.LayoutOrder,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        Padding           = UDim.new(0,6),
    })
    Library:Create("UIPadding", {
        Parent        = rows,
        PaddingLeft   = UDim.new(0,10),
        PaddingRight  = UDim.new(0,10),
        PaddingTop    = UDim.new(0,8),
        PaddingBottom = UDim.new(0,8),
    })

    -- Vec: full-width container for Left + Right
    local vec = Library:Create("Frame", {
        Name                   = "Vec",
        Parent                 = rows,
        BackgroundTransparency = 1,
        BorderSizePixel        = 0,
        AutomaticSize          = Enum.AutomaticSize.Y,
        Size                   = UDim2.new(1,0,0,0),
    })

    -- Right: aligns elements (toggle, button pill, etc.) to the right edge
    local right = Library:Create("Frame", {
        Name                   = "Right",
        Parent                 = vec,
        BackgroundTransparency = 1,
        BorderSizePixel        = 0,
        Size                   = UDim2.new(1,0,1,0),
    })
    Library:Create("UIListLayout", {
        Parent              = right,
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        VerticalAlignment   = Enum.VerticalAlignment.Center,
        SortOrder           = Enum.SortOrder.LayoutOrder,
    })

    -- Left: holds optional row icon + text stack
    local left = Library:Create("Frame", {
        Name                   = "Left",
        Parent                 = vec,
        BackgroundTransparency = 1,
        BorderSizePixel        = 0,
        AutomaticSize          = Enum.AutomaticSize.Y,
        Size                   = UDim2.new(1,0,0,0),
    })

    if icon then
        Library:Create("UIListLayout", {
            Parent            = left,
            FillDirection     = Enum.FillDirection.Horizontal,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            SortOrder         = Enum.SortOrder.LayoutOrder,
            Padding           = UDim.new(0,8),
        })
        local ico = Library:Create("ImageLabel", {
            Name                   = "RowIcon",
            Parent                 = left,
            BackgroundTransparency = 1,
            BorderSizePixel        = 0,
            LayoutOrder            = -1,
            Size                   = UDim2.new(0,16,0,16),
            Image                  = icon,
            ImageColor3            = T.Accent,
        })
        tr("Accent", ico, "ImageColor3")
    end

    -- Text frame: fills remaining width after optional icon
    local textW = icon and UDim2.new(1,-24,0,0) or UDim2.new(1,0,0,0)
    local textFrame = Library:Create("Frame", {
        Name                   = "Text",
        Parent                 = left,
        BackgroundTransparency = 1,
        BorderSizePixel        = 0,
        AutomaticSize          = Enum.AutomaticSize.Y,
        Size                   = textW,
        LayoutOrder            = 0,
    })
    Library:Create("UIListLayout", {
        Parent              = textFrame,
        SortOrder           = Enum.SortOrder.LayoutOrder,
        VerticalAlignment   = Enum.VerticalAlignment.Center,
        HorizontalAlignment = Enum.HorizontalAlignment.Left,
        Padding             = UDim.new(0,2),
    })

    local titleLbl = Library:Create("TextLabel", {
        Name                   = "Title",
        Parent                 = textFrame,
        BackgroundTransparency = 1,
        BorderSizePixel        = 0,
        LayoutOrder            = -1,
        AutomaticSize          = Enum.AutomaticSize.Y,
        Size                   = UDim2.new(1,0,0,0),
        Font                   = Enum.Font.GothamSemibold,
        RichText               = true,
        Text                   = title or "",
        TextColor3             = T.Text,
        TextSize               = 12,
        TextStrokeTransparency = 0.7,
        TextWrapped            = true,
        TextXAlignment         = Enum.TextXAlignment.Left,
        TextYAlignment         = Enum.TextYAlignment.Top,
    })
    tr("Text", titleLbl, "TextColor3")
    Library:Create("UIGradient", {
        Parent   = titleLbl,
        Color    = ColorSequence.new{ ColorSequenceKeypoint.new(0, Color3.new(1,1,1)), ColorSequenceKeypoint.new(0.75, T.SubText), ColorSequenceKeypoint.new(1, Color3.fromRGB(100,100,100)) },
        Rotation = 90,
    })

    if desc and desc ~= "" then
        local descLbl = Library:Create("TextLabel", {
            Name                   = "Desc",
            Parent                 = textFrame,
            BackgroundTransparency = 1,
            BorderSizePixel        = 0,
            AutomaticSize          = Enum.AutomaticSize.Y,
            Size                   = UDim2.new(1,0,0,0),
            Font                   = Enum.Font.GothamMedium,
            RichText               = true,
            Text                   = desc,
            TextColor3             = T.Text,
            TextSize               = 10,
            TextStrokeTransparency = 0.7,
            TextTransparency       = 0.55,
            TextWrapped            = true,
            TextXAlignment         = Enum.TextXAlignment.Left,
            TextYAlignment         = Enum.TextYAlignment.Top,
        })
        tr("Text", descLbl, "TextColor3")
    end

    -- Expose named children for element builders
    rows.Vec   = vec
    rows.Right = right
    rows.Left  = left
    rows.Text  = textFrame
    return rows
end

--------------------------------------------------------------------
-- Window
--------------------------------------------------------------------
--[[
    Library:Window(Args)
    ─────────────────────
    Title             string         Header title
    SubTitle          string         Header subtitle
    ToggleKey         Enum.KeyCode   Key to show/hide  (default LeftControl)
    AutoScale         bool           Auto UIScale       (default true)
    Scale             number         Base UIScale       (default 1.45)
    Size              UDim2          Window size        (default 500×350)
    ExecIdentifyShown bool           Show executor label (default true)
    BbIcon            string         Pill icon — Lucide name, "lucide-*", or rbxassetid
                                     e.g. BbIcon = "home"

    Theme table  (all fields: Color3 or "#RRGGBB"):
        Accent      main highlight         (#FF007F)
        Background  window bg              (#0B0B0B)
        Row         element row bg         (#0F0F0F)
        RowAlt      toggle-off / keybind   (#0A0A0A)
        Stroke      border                 (#191919)
        Text        primary text           (#FFFFFF)
        SubText     gradient/secondary     (#A3A3A3)
        TabBg       tab card bg            (#0A0A0A)
        TabStroke   tab card border        (#4B0026)
        TabImage    tab banner tint        (= Accent)
        DropBg      dropdown popup bg      (#121212)
        DropStroke  dropdown popup border  (#1E1E1E)
        PillBg      pill bg                (#0B0B0B)

    Shorthand: BG → Background,  Tab → TabBg

    NewPage Args:
        Title    string
        Desc     string
        Icon     string         Lucide name (no rbxassetid needed): "eye", "home"
        TabImage Color3/"#hex"  Per-tab banner tint (overrides global T.TabImage)
--]]
function Library:Window(Args)
    local title     = Args.Title    or "Vita UI"
    local subtitle  = Args.SubTitle or "Made by vita6it"
    local toggleKey = Args.ToggleKey or Enum.KeyCode.LeftControl
    local autoScale = Args.AutoScale ~= false
    local baseScale = Args.Scale    or 1.45
    local customSz  = Args.Size
    local showExec  = Args.ExecIdentifyShown ~= false

    -- Theme setup
    local uT = Args.Theme or {}
    if Args.BG       then uT.Background = Args.BG       end
    if Args.Tab      then uT.TabBg      = Args.Tab      end
    if Args.TabImage then uT.TabImage   = Args.TabImage end
    if Args.TabStroke then uT.TabStroke = Args.TabStroke end

    local T = {
        Accent     = ResolveColor(uT.Accent     or "#FF007F"),
        Background = ResolveColor(uT.Background or "#0B0B0B"),
        Row        = ResolveColor(uT.Row        or "#0F0F0F"),
        RowAlt     = ResolveColor(uT.RowAlt     or "#0A0A0A"),
        Stroke     = ResolveColor(uT.Stroke     or "#191919"),
        Text       = ResolveColor(uT.Text       or "#FFFFFF"),
        SubText    = ResolveColor(uT.SubText    or "#A3A3A3"),
        TabBg      = ResolveColor(uT.TabBg      or "#0A0A0A"),
        TabStroke  = ResolveColor(uT.TabStroke  or "#4B0026"),
        TabImage   = ResolveColor(uT.TabImage   or uT.Accent or "#FF007F"),
        DropBg     = ResolveColor(uT.DropBg     or "#121212"),
        DropStroke = ResolveColor(uT.DropStroke or "#1E1E1E"),
        PillBg     = ResolveColor(uT.PillBg     or "#0B0B0B"),
    }

    -- Unified theme tracking: _refs[key] = {{inst, prop}, ...}
    local _refs  = {}
    local _prevT = {}
    for k,v in pairs(T) do _prevT[k] = v end

    local function track(key, inst, prop)
        if not inst or not prop then return end
        if not _refs[key] then _refs[key] = {} end
        table.insert(_refs[key], {inst, prop})
    end

    local function flushKey(key)
        if not _refs[key] then return end
        local color = T[key]
        for i = #_refs[key], 1, -1 do
            local ref = _refs[key][i]
            if ref[1] and ref[1].Parent then
                pcall(function() ref[1][ref[2]] = color end)
            else
                table.remove(_refs[key], i)
            end
        end
    end

    -- Heartbeat watcher: any T[key] assignment auto-flushes
    RunService.Heartbeat:Connect(function()
        for k,v in pairs(T) do
            if _prevT[k] ~= v then
                _prevT[k] = v
                flushKey(k)
            end
        end
    end)

    -- Convenience trackers
    local function tAccent(i,p)    track("Accent",     i,p) end
    local function tBg(i,p)        track("Background", i,p) end
    local function tTabBg(i,p)     track("TabBg",      i,p) end
    local function tTabImg(i,p)    track("TabImage",   i,p) end
    local function tTabStroke(i,p) track("TabStroke",  i,p) end

    -------------------------------------------------------------------
    -- GUI Root
    -------------------------------------------------------------------
    local Xova = Library:Create("ScreenGui", {
        Name           = "Xova",
        Parent         = Library:Parent(),
        ZIndexBehavior = Enum.ZIndexBehavior.Global,
        IgnoreGuiInset = true,
        ResetOnSpawn   = false,
    })

    local Background = Library:Create("Frame", {
        Name             = "Background",
        Parent           = Xova,
        AnchorPoint      = Vector2.new(0.5, 0.5),
        BackgroundColor3 = T.Background,
        BorderSizePixel  = 0,
        Position         = UDim2.new(0.5, 0, 0.5, 0),
        Size             = customSz or UDim2.new(0, 500, 0, 350),
    })
    tBg(Background, "BackgroundColor3")
    Library:Create("UICorner", { Parent = Background })
    Library:Create("ImageLabel", {
        Name                   = "Shadow",
        Parent                 = Background,
        AnchorPoint            = Vector2.new(0.5,0.5),
        BackgroundTransparency = 1,
        BorderSizePixel        = 0,
        Position               = UDim2.new(0.5,0,0.5,0),
        Size                   = UDim2.new(1,120,1,120),
        ZIndex                 = 0,
        Image                  = "rbxassetid://8992230677",
        ImageColor3            = Color3.new(),
        ImageTransparency      = 0.5,
        ScaleType              = Enum.ScaleType.Slice,
        SliceCenter            = Rect.new(99,99,99,99),
    })

    function Library:IsDropdownOpen()
        for _,v in pairs(Background:GetChildren()) do
            if v.Name == "Dropdown" and v.Visible then return true end
        end
        return false
    end

    -------------------------------------------------------------------
    -- Header
    -------------------------------------------------------------------
    local Header = Library:Create("Frame", {
        Name                   = "Header",
        Parent                 = Background,
        BackgroundTransparency = 1,
        BorderSizePixel        = 0,
        Size                   = UDim2.new(1,0,0,40),
    })

    local ReturnBtn = Library:Create("ImageLabel", {
        Name                   = "Return",
        Parent                 = Header,
        AnchorPoint            = Vector2.new(0.5,0.5),
        BackgroundTransparency = 1,
        BorderSizePixel        = 0,
        Position               = UDim2.new(0,25,0.5,1),
        Size                   = UDim2.new(0,27,0,27),
        Image                  = "rbxassetid://130391877219356",
        ImageColor3            = T.Accent,
        Visible                = false,
    })
    tAccent(ReturnBtn, "ImageColor3")

    local HeadScale = Library:Create("Frame", {
        Name                   = "HeadScale",
        Parent                 = Header,
        BackgroundTransparency = 1,
        BorderSizePixel        = 0,
        Position               = UDim2.new(0,0,0,0),
        Size                   = UDim2.new(1,0,1,0),
    })
    Library:Create("UIListLayout", {
        Parent            = HeadScale,
        FillDirection     = Enum.FillDirection.Horizontal,
        SortOrder         = Enum.SortOrder.LayoutOrder,
        VerticalAlignment = Enum.VerticalAlignment.Center,
    })
    Library:Create("UIPadding", {
        Parent        = HeadScale,
        PaddingLeft   = UDim.new(0,15),
        PaddingRight  = UDim.new(0,15),
        PaddingTop    = UDim.new(0,20),
        PaddingBottom = UDim.new(0,15),
    })

    local InfoFrame = Library:Create("Frame", {
        Parent                 = HeadScale,
        BackgroundTransparency = 1,
        BorderSizePixel        = 0,
        Size                   = UDim2.new(1,-100,0,28),
    })
    Library:Create("UIListLayout", { Parent = InfoFrame, SortOrder = Enum.SortOrder.LayoutOrder })

    local TitleLabel = Library:Create("TextLabel", {
        Parent                 = InfoFrame,
        BackgroundTransparency = 1,
        BorderSizePixel        = 0,
        Size                   = UDim2.new(1,0,0,14),
        Font                   = Enum.Font.GothamBold,
        RichText               = true,
        Text                   = title,
        TextColor3             = T.Accent,
        TextSize               = 14,
        TextStrokeTransparency = 0.7,
        TextXAlignment         = Enum.TextXAlignment.Left,
    })
    tAccent(TitleLabel, "TextColor3")
    Library:Create("UIGradient", {
        Parent   = TitleLabel,
        Color    = ColorSequence.new{ColorSequenceKeypoint.new(0,Color3.new(1,1,1)),ColorSequenceKeypoint.new(0.75,T.SubText),ColorSequenceKeypoint.new(1,Color3.fromRGB(100,100,100))},
        Rotation = 90,
    })

    Library:Create("TextLabel", {
        Parent                 = InfoFrame,
        BackgroundTransparency = 1,
        BorderSizePixel        = 0,
        Size                   = UDim2.new(1,0,0,10),
        Font                   = Enum.Font.GothamMedium,
        RichText               = true,
        Text                   = subtitle,
        TextColor3             = T.Text,
        TextSize               = 10,
        TextStrokeTransparency = 0.7,
        TextTransparency       = 0.55,
        TextXAlignment         = Enum.TextXAlignment.Left,
    })

    -- Expires / time area
    local ExpiresFrame = Library:Create("Frame", {
        Name                   = "Expires",
        Parent                 = HeadScale,
        BackgroundTransparency = 1,
        BorderSizePixel        = 0,
        Size                   = UDim2.new(0,100,0,40),
    })
    Library:Create("UIListLayout", {
        Parent              = ExpiresFrame,
        FillDirection       = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        VerticalAlignment   = Enum.VerticalAlignment.Center,
        Padding             = UDim.new(0,6),
        SortOrder           = Enum.SortOrder.LayoutOrder,
    })

    local exIcon = Library:Create("ImageLabel", {
        Parent                 = ExpiresFrame,
        BackgroundTransparency = 1,
        BorderSizePixel        = 0,
        LayoutOrder            = 1,
        Size                   = UDim2.new(0,18,0,18),
        Image                  = "rbxassetid://100865348188048",
        ImageColor3            = T.Accent,
    })
    tAccent(exIcon, "ImageColor3")

    local exInfo = Library:Create("Frame", {
        Parent                 = ExpiresFrame,
        BackgroundTransparency = 1,
        BorderSizePixel        = 0,
        LayoutOrder            = 2,
        Size                   = UDim2.new(0,72,0,28),
    })
    Library:Create("UIListLayout", { Parent = exInfo, SortOrder = Enum.SortOrder.LayoutOrder })

    local exTitle = Library:Create("TextLabel", {
        Parent                 = exInfo,
        BackgroundTransparency = 1,
        BorderSizePixel        = 0,
        Size                   = UDim2.new(1,0,0,14),
        Font                   = Enum.Font.GothamSemibold,
        Text                   = "Expires at",
        TextColor3             = T.Accent,
        TextSize               = 12,
        TextStrokeTransparency = 0.7,
        TextXAlignment         = Enum.TextXAlignment.Right,
    })
    tAccent(exTitle, "TextColor3")

    local THETIME = Library:Create("TextLabel", {
        Name                   = "Time",
        Parent                 = exInfo,
        BackgroundTransparency = 1,
        BorderSizePixel        = 0,
        Size                   = UDim2.new(1,0,0,10),
        Font                   = Enum.Font.GothamMedium,
        Text                   = "00:00:00",
        TextColor3             = T.Text,
        TextSize               = 10,
        TextTransparency       = 0.55,
        TextXAlignment         = Enum.TextXAlignment.Right,
    })

    -------------------------------------------------------------------
    -- Body / Pages
    -------------------------------------------------------------------
    local Body = Library:Create("Frame", {
        Name                   = "Body",
        Parent                 = Background,
        AnchorPoint            = Vector2.new(0,1),
        BackgroundTransparency = 1,
        BorderSizePixel        = 0,
        Position               = UDim2.new(0,0,1,0),
        Size                   = UDim2.new(1,0,1,-40),
        ClipsDescendants       = true,
    })

    local Home = Library:Create("Frame", {
        Name                   = "Home",
        Parent                 = Body,
        BackgroundTransparency = 1,
        BorderSizePixel        = 0,
        Size                   = UDim2.new(1,0,1,0),
    })
    Library:Create("UIPadding", {
        Parent        = Home,
        PaddingLeft   = UDim.new(0,14),
        PaddingRight  = UDim.new(0,14),
        PaddingBottom = UDim.new(0,15),
    })

    local TabScroll = Library:Create("ScrollingFrame", {
        Name                   = "TabScroll",
        Parent                 = Home,
        Active                 = true,
        BackgroundTransparency = 1,
        BorderSizePixel        = 0,
        Size                   = UDim2.new(1,0,1,0),
        ScrollBarThickness     = 0,
        AutomaticCanvasSize    = Enum.AutomaticSize.None,
        ScrollingDirection     = Enum.ScrollingDirection.XY,
        CanvasPosition         = Vector2.new(0,0),
    })
    local TabLayout = Library:Create("UIListLayout", {
        Parent        = TabScroll,
        Padding       = UDim.new(0,10),
        FillDirection = Enum.FillDirection.Horizontal,
        SortOrder     = Enum.SortOrder.LayoutOrder,
        Wraps         = true,
    })
    TabLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        TabScroll.CanvasSize = UDim2.new(0,0,0,TabLayout.AbsoluteContentSize.Y+15)
    end)

    local PageService = Library:Create("UIPageLayout", { Parent = Body })
    PageService.HorizontalAlignment     = Enum.HorizontalAlignment.Left
    PageService.EasingStyle             = Enum.EasingStyle.Exponential
    PageService.TweenTime               = 0.45
    PageService.GamepadInputEnabled     = false
    PageService.ScrollWheelInputEnabled = false
    PageService.TouchInputEnabled       = false
    Library.PageService = PageService

    -------------------------------------------------------------------
    -- Auto Scale
    -------------------------------------------------------------------
    local function autoScaleVal()
        local cam = workspace.CurrentCamera
        if not cam then return baseScale end
        local vp = cam.ViewportSize
        return math.clamp(math.min(vp.X/1920, vp.Y/1080) * baseScale * 1.5, 0.4, baseScale * 1.5)
    end

    local Scaler = Library:Create("UIScale", {
        Parent = Xova,
        Scale  = Mobile and 1 or (autoScale and autoScaleVal() or baseScale),
    })

    if autoScale and not Mobile then
        workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
            if not Scaler:GetAttribute("ManualScale") then
                Scaler.Scale = autoScaleVal()
            end
        end)
    end

    -------------------------------------------------------------------
    -- Toggle Pill  (BbIcon support)
    -------------------------------------------------------------------
    local ToggleScreen = Library:Create("ScreenGui", {
        Name           = "VitaToggle",
        Parent         = Library:Parent(),
        ZIndexBehavior = Enum.ZIndexBehavior.Global,
        IgnoreGuiInset = true,
        ResetOnSpawn   = false,
    })

    local Pillow = Library:Create("TextButton", {
        Name             = "Pillow",
        Parent           = ToggleScreen,
        BackgroundColor3 = T.PillBg,
        BorderSizePixel  = 0,
        Position         = UDim2.new(0.06,0,0.15,0),
        Size             = UDim2.new(0,50,0,50),
        Text             = "",
    })
    tBg(Pillow, "BackgroundColor3")
    Library:Create("UICorner", { Parent = Pillow, CornerRadius = UDim.new(1,0) })
    Library:Create("UIStroke", { Parent = Pillow, Color = T.Stroke, Thickness = 1.5 })

    local defaultPillImg = "rbxassetid://104055321996495"
    local pillIconImg    = Args.BbIcon and GetIcon(Args.BbIcon) or nil
    local PillLogo = Library:Create("ImageLabel", {
        Name                   = "Logo",
        Parent                 = Pillow,
        AnchorPoint            = Vector2.new(0.5,0.5),
        BackgroundTransparency = 1,
        BorderSizePixel        = 0,
        Position               = UDim2.new(0.5,0,0.5,0),
        Size                   = UDim2.new(0.55,0,0.55,0),
        Image                  = (pillIconImg and pillIconImg ~= "" and pillIconImg) or defaultPillImg,
        ImageColor3            = T.Accent,
    })
    tAccent(PillLogo, "ImageColor3")

    Library:Draggable(Pillow)
    Pillow.MouseButton1Click:Connect(function()
        Background.Visible = not Background.Visible
    end)
    UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        if input.KeyCode == toggleKey then
            Background.Visible = not Background.Visible
        end
    end)

    -------------------------------------------------------------------
    -- Return button
    -------------------------------------------------------------------
    local ReturnClick = Library:Button(ReturnBtn)
    ReturnClick.MouseButton1Click:Connect(function()
        ReturnBtn.Visible = false
        Library:Tween({ v = HeadScale, t = 0.3, s = "Exponential", d = "Out",
            g = { Size = UDim2.new(1,0,1,0) } }):Play()
        PageService:JumpTo(Home)
    end)
    PageService:JumpTo(Home)
    Library:Draggable(Background)

    -------------------------------------------------------------------
    -- Executor label
    -------------------------------------------------------------------
    local ExecLabel = Library:Create("TextLabel", {
        Name                   = "ExecIdentity",
        Parent                 = Background,
        AnchorPoint            = Vector2.new(1,1),
        BackgroundTransparency = 1,
        BorderSizePixel        = 0,
        Position               = UDim2.new(1,-8,1,-5),
        Size                   = UDim2.new(0,200,0,12),
        Font                   = Enum.Font.GothamMedium,
        Text                   = GetExecutorName(),
        TextColor3             = Color3.new(1,1,1),
        TextSize               = 9,
        TextTransparency       = 0.5,
        TextXAlignment         = Enum.TextXAlignment.Right,
        ZIndex                 = 10,
        Visible                = showExec,
    })

    -------------------------------------------------------------------
    -- Window object
    -------------------------------------------------------------------
    local Window = {}

    function Window:NewPage(args)
        local pageTitle = args.Title or "Page"
        local pageDesc  = args.Desc  or "Description"
        local pageIcon  = GetIcon(args.Icon or "layers")
        -- Per-tab banner tint: overrides global T.TabImage for this tab only
        local pageTabImg = args.TabImage and ResolveColor(args.TabImage) or nil

        -- Tab card
        local tab = Library:Create("Frame", {
            Name             = "Tab",
            Parent           = TabScroll,
            BackgroundColor3 = T.TabBg,
            BorderSizePixel  = 0,
            Size             = UDim2.new(0,230,0,55),
        })
        tTabBg(tab, "BackgroundColor3")
        local tabClick = Library:Button(tab)
        Library:Create("UICorner", { Parent = tab, CornerRadius = UDim.new(0,5) })
        local tabStroke = Library:Create("UIStroke", { Parent = tab, Color = T.TabStroke, Thickness = 1 })
        tTabStroke(tabStroke, "Color")

        local tabBanner = Library:Create("ImageLabel", {
            Name                   = "Banner",
            Parent                 = tab,
            BackgroundTransparency = 1,
            BorderSizePixel        = 0,
            Size                   = UDim2.new(1,0,1,0),
            Image                  = "rbxassetid://125411502674016",
            ImageColor3            = pageTabImg or T.TabImage,
            ScaleType              = Enum.ScaleType.Crop,
        })
        Library:Create("UICorner", { Parent = tabBanner, CornerRadius = UDim.new(0,2) })
        -- Only track global TabImage if no per-page override
        if not pageTabImg then tTabImg(tabBanner, "ImageColor3") end

        local tabInfo = Library:Create("Frame", {
            Name                   = "Info",
            Parent                 = tab,
            BackgroundTransparency = 1,
            BorderSizePixel        = 0,
            Size                   = UDim2.new(1,0,1,0),
        })
        Library:Create("UIListLayout", {
            Parent            = tabInfo,
            FillDirection     = Enum.FillDirection.Horizontal,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            Padding           = UDim.new(0,10),
            SortOrder         = Enum.SortOrder.LayoutOrder,
        })
        Library:Create("UIPadding", { Parent = tabInfo, PaddingLeft = UDim.new(0,15) })

        local tabIcon = Library:Create("ImageLabel", {
            Name                   = "Icon",
            Parent                 = tabInfo,
            BackgroundTransparency = 1,
            BorderSizePixel        = 0,
            LayoutOrder            = -1,
            Size                   = UDim2.new(0,25,0,25),
            Image                  = pageIcon or defaultPillImg,
            ImageColor3            = T.Accent,
        })
        tAccent(tabIcon, "ImageColor3")
        Library:Create("UIGradient", {
            Parent   = tabIcon,
            Color    = ColorSequence.new{ColorSequenceKeypoint.new(0,Color3.new(1,1,1)),ColorSequenceKeypoint.new(0.75,T.SubText),ColorSequenceKeypoint.new(1,Color3.fromRGB(100,100,100))},
            Rotation = 90,
        })

        local tabTextFrame = Library:Create("Frame", {
            Parent                 = tabInfo,
            BackgroundTransparency = 1,
            BorderSizePixel        = 0,
            Size                   = UDim2.new(0,150,0,32),
        })
        Library:Create("UIListLayout", {
            Parent            = tabTextFrame,
            Padding           = UDim.new(0,2),
            VerticalAlignment = Enum.VerticalAlignment.Center,
            SortOrder         = Enum.SortOrder.LayoutOrder,
        })

        local tabTitleLbl = Library:Create("TextLabel", {
            Parent                 = tabTextFrame,
            BackgroundTransparency = 1,
            BorderSizePixel        = 0,
            Size                   = UDim2.new(1,0,0,15),
            Font                   = Enum.Font.GothamBold,
            RichText               = true,
            Text                   = pageTitle,
            TextColor3             = T.Accent,
            TextSize               = 15,
            TextStrokeTransparency = 0.45,
            TextXAlignment         = Enum.TextXAlignment.Left,
        })
        tAccent(tabTitleLbl, "TextColor3")
        Library:Create("UIGradient", {
            Parent   = tabTitleLbl,
            Color    = ColorSequence.new{ColorSequenceKeypoint.new(0,Color3.new(1,1,1)),ColorSequenceKeypoint.new(0.75,T.SubText),ColorSequenceKeypoint.new(1,Color3.fromRGB(100,100,100))},
            Rotation = 90,
        })
        Library:Create("TextLabel", {
            Parent                 = tabTextFrame,
            BackgroundTransparency = 1,
            BorderSizePixel        = 0,
            Size                   = UDim2.new(0.9,0,0,10),
            Font                   = Enum.Font.GothamMedium,
            RichText               = true,
            Text                   = pageDesc,
            TextColor3             = T.Text,
            TextSize               = 10,
            TextTransparency       = 0.2,
            TextXAlignment         = Enum.TextXAlignment.Left,
        })

        -- Page frame + scrolling content
        local page = Library:Create("Frame", {
            Name                   = "Page",
            Parent                 = Body,
            BackgroundTransparency = 1,
            BorderSizePixel        = 0,
            Size                   = UDim2.new(1,0,1,0),
        })
        local pageScroll = Library:Create("ScrollingFrame", {
            Name                   = "PageScroll",
            Parent                 = page,
            Active                 = true,
            BackgroundTransparency = 1,
            BorderSizePixel        = 0,
            Size                   = UDim2.new(1,0,1,0),
            ScrollBarThickness     = 0,
            AutomaticCanvasSize    = Enum.AutomaticSize.None,
            ScrollingDirection     = Enum.ScrollingDirection.XY,
            CanvasPosition         = Vector2.new(0,0),
        })
        Library:Create("UIPadding", {
            Parent        = pageScroll,
            PaddingLeft   = UDim.new(0,15),
            PaddingRight  = UDim.new(0,15),
            PaddingTop    = UDim.new(0,4),
            PaddingBottom = UDim.new(0,4),
        })
        local pageLayout = Library:Create("UIListLayout", {
            Parent        = pageScroll,
            Padding       = UDim.new(0,5),
            FillDirection = Enum.FillDirection.Vertical,
            SortOrder     = Enum.SortOrder.LayoutOrder,
        })
        pageLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            pageScroll.CanvasSize = UDim2.new(0,0,0,pageLayout.AbsoluteContentSize.Y+15)
        end)

        tabClick.MouseButton1Click:Connect(function()
            Library:Tween({ v = HeadScale, t = 0.2, s = "Exponential", d = "Out",
                g = { Size = UDim2.new(1,-30,1,0) } }):Play()
            ReturnBtn.Visible = true
            PageService:JumpTo(page)
        end)

        -------------------------------------------------------------------
        -- Element builders
        -------------------------------------------------------------------
        local Page = {}

        -- Section
        function Page:Section(args)
            local txt, iconName
            if type(args) == "string" then
                txt, iconName = args, nil
            else
                txt      = args.Text or args.Title or ""
                iconName = args.Icon
            end
            local icon = GetIcon(iconName)

            local cont = Library:Create("Frame", {
                Name                   = "Section",
                Parent                 = pageScroll,
                BackgroundTransparency = 1,
                BorderSizePixel        = 0,
                AutomaticSize          = Enum.AutomaticSize.Y,
                Size                   = UDim2.new(1,0,0,0),
            })
            Library:Create("UIListLayout", {
                Parent            = cont,
                FillDirection     = Enum.FillDirection.Horizontal,
                VerticalAlignment = Enum.VerticalAlignment.Center,
                SortOrder         = Enum.SortOrder.LayoutOrder,
                Padding           = UDim.new(0,5),
            })
            Library:Create("UIPadding", {
                Parent        = cont,
                PaddingTop    = UDim.new(0,2),
                PaddingBottom = UDim.new(0,2),
                PaddingLeft   = UDim.new(0,2),
            })

            if icon then
                local si = Library:Create("ImageLabel", {
                    Parent                 = cont,
                    BackgroundTransparency = 1,
                    BorderSizePixel        = 0,
                    LayoutOrder            = -1,
                    Size                   = UDim2.new(0,14,0,14),
                    Image                  = icon,
                    ImageColor3            = T.Accent,
                })
                track("Accent", si, "ImageColor3")
            end

            local lbl = Library:Create("TextLabel", {
                Name                   = "Label",
                Parent                 = cont,
                BackgroundTransparency = 1,
                BorderSizePixel        = 0,
                AutomaticSize          = Enum.AutomaticSize.Y,
                Size                   = UDim2.new(0,0,0,0),
                Font                   = Enum.Font.GothamBold,
                RichText               = true,
                Text                   = txt,
                TextColor3             = T.Text,
                TextSize               = 14,
                TextStrokeTransparency = 0.7,
                TextWrapped            = false,
                TextXAlignment         = Enum.TextXAlignment.Left,
            })
            track("Text", lbl, "TextColor3")
            Library:Create("UIGradient", {
                Parent   = lbl,
                Color    = ColorSequence.new{ColorSequenceKeypoint.new(0,Color3.new(1,1,1)),ColorSequenceKeypoint.new(0.75,T.SubText),ColorSequenceKeypoint.new(1,Color3.fromRGB(100,100,100))},
                Rotation = 90,
            })
            return cont
        end

        -- Separator
        function Page:Separator(args)
            args = args or {}
            local col = args.Color and ResolveColor(args.Color) or T.Stroke
            local h   = args.Height or 14
            local sep = Library:Create("Frame", {
                Name                   = "Separator",
                Parent                 = pageScroll,
                BackgroundTransparency = 1,
                BorderSizePixel        = 0,
                Size                   = UDim2.new(1,0,0,h),
            })
            local line = Library:Create("Frame", {
                Parent           = sep,
                AnchorPoint      = Vector2.new(0.5,0.5),
                BackgroundColor3 = col,
                BorderSizePixel  = 0,
                Position         = UDim2.new(0.5,0,0.5,0),
                Size             = UDim2.new(1,-20,0,1),
            })
            Library:Create("UICorner", { Parent = line, CornerRadius = UDim.new(1,0) })
            track("Stroke", line, "BackgroundColor3")
            return sep
        end

        -- Label
        function Page:Label(args)
            local alignMap = { Left = Enum.TextXAlignment.Left, Center = Enum.TextXAlignment.Center, Right = Enum.TextXAlignment.Right }
            local lbl = Library:Create("TextLabel", {
                Name                   = "Label",
                Parent                 = pageScroll,
                BackgroundTransparency = 1,
                BorderSizePixel        = 0,
                AutomaticSize          = Enum.AutomaticSize.Y,
                Size                   = UDim2.new(1,0,0,0),
                Font                   = args.Bold and Enum.Font.GothamBold or Enum.Font.GothamMedium,
                RichText               = true,
                Text                   = args.Text or "",
                TextColor3             = args.Color and ResolveColor(args.Color) or T.Text,
                TextSize               = args.Size or 12,
                TextStrokeTransparency = 0.7,
                TextTransparency       = 0.1,
                TextWrapped            = true,
                TextXAlignment         = alignMap[args.Align or "Left"] or Enum.TextXAlignment.Left,
                TextYAlignment         = Enum.TextYAlignment.Top,
            })
            Library:Create("UIPadding", { Parent = lbl, PaddingLeft = UDim.new(0,4), PaddingRight = UDim.new(0,4) })
            if not args.Color then track("Text", lbl, "TextColor3") end
            local D = { Text = args.Text or "" }
            return setmetatable({}, {
                __newindex = function(_,k,v) rawset(D,k,v)
                    if k == "Text"  then lbl.Text       = tostring(v)
                    elseif k == "Color" then lbl.TextColor3 = ResolveColor(v) end
                end, __index = D })
        end

        -- Paragraph
        function Page:Paragraph(args)
            local rows     = MakeRows(pageScroll, args.Title, args.Desc, T, track, args.RowIcon)
            local rightF   = rows.Right
            local textF    = rows.Text

            local imgName  = args.Image or args.Icon
            local imgAsset = imgName and GetIcon(imgName) or nil
            local iconLbl  = nil
            if imgAsset and imgAsset ~= "" then
                iconLbl = Library:Create("ImageLabel", {
                    Parent                 = rightF,
                    BackgroundTransparency = 1,
                    BorderSizePixel        = 0,
                    Size                   = UDim2.new(0,20,0,20),
                    Image                  = imgAsset,
                    ImageColor3            = T.Accent,
                })
                track("Accent", iconLbl, "ImageColor3")
            end

            local D = { Title = args.Title, Desc = args.Desc }
            return setmetatable({}, {
                __newindex = function(_,k,v) rawset(D,k,v)
                    if k == "Title" then
                        local t = textF:FindFirstChild("Title")
                        if t then t.Text = tostring(v) end
                    elseif k == "Desc" then
                        local d = textF:FindFirstChild("Desc")
                        if d then d.Text = tostring(v) end
                    elseif (k == "Image" or k == "Icon") and iconLbl then
                        local id = GetIcon(v)
                        if id then iconLbl.Image = id end
                    end
                end, __index = D })
        end

        -- RightLabel
        function Page:RightLabel(args)
            local rows  = MakeRows(pageScroll, args.Title, args.Desc, T, track, args.Icon)
            local rightF = rows.Right
            local textF  = rows.Text

            local lbl = Library:Create("TextLabel", {
                Name                   = "RightLbl",
                Parent                 = rightF,
                BackgroundTransparency = 1,
                BorderSizePixel        = 0,
                LayoutOrder            = -1,
                Size                   = UDim2.new(0,90,0,0),
                AutomaticSize          = Enum.AutomaticSize.Y,
                Font                   = Enum.Font.GothamSemibold,
                RichText               = true,
                Text                   = args.Right or "N/A",
                TextColor3             = T.Text,
                TextSize               = 12,
                TextStrokeTransparency = 0.7,
                TextWrapped            = true,
                TextXAlignment         = Enum.TextXAlignment.Right,
                TextYAlignment         = Enum.TextYAlignment.Top,
            })
            track("Text", lbl, "TextColor3")
            Library:Create("UIGradient", {
                Parent   = lbl,
                Color    = ColorSequence.new{ColorSequenceKeypoint.new(0,Color3.new(1,1,1)),ColorSequenceKeypoint.new(0.75,T.SubText),ColorSequenceKeypoint.new(1,Color3.fromRGB(100,100,100))},
                Rotation = 90,
            })
            local D = { Title = args.Title, Desc = args.Desc, Right = args.Right or "N/A" }
            return setmetatable({}, {
                __newindex = function(_,k,v) rawset(D,k,v)
                    if k == "Right" or k == "Text" then lbl.Text = tostring(v)
                    elseif k == "Title" then
                        local t = textF:FindFirstChild("Title"); if t then t.Text = tostring(v) end
                    elseif k == "Desc" then
                        local d = textF:FindFirstChild("Desc"); if d then d.Text = tostring(v) end
                    end
                end, __index = D })
        end

        -- Button
        function Page:Button(args)
            local btnText  = args.Text or "Click"
            local callback = args.Callback
            local rows     = MakeRows(pageScroll, args.Title, args.Desc, T, track, args.Icon)
            local rightF   = rows.Right

            local pill = Library:Create("Frame", {
                Name             = "Pill",
                Parent           = rightF,
                BackgroundColor3 = T.Accent,
                BorderSizePixel  = 0,
                AutomaticSize    = Enum.AutomaticSize.X,
                Size             = UDim2.new(0,0,0,24),
                ClipsDescendants = true,
            })
            track("Accent", pill, "BackgroundColor3")
            Library:Create("UICorner",  { Parent = pill, CornerRadius = UDim.new(0,4) })
            Library:Create("UIGradient", { Parent = pill,
                Color    = ColorSequence.new{ColorSequenceKeypoint.new(0,Color3.new(1,1,1)),ColorSequenceKeypoint.new(1,Color3.fromRGB(56,56,56))},
                Rotation = 90 })
            Library:Create("UIListLayout", {
                Parent              = pill,
                FillDirection       = Enum.FillDirection.Horizontal,
                VerticalAlignment   = Enum.VerticalAlignment.Center,
                HorizontalAlignment = Enum.HorizontalAlignment.Center,
                SortOrder           = Enum.SortOrder.LayoutOrder,
                Padding             = UDim.new(0,4),
            })
            Library:Create("UIPadding", {
                Parent       = pill,
                PaddingLeft  = UDim.new(0,10),
                PaddingRight = UDim.new(0,10),
            })

            -- ButtonIcon: icon inside the pill (separate from row Icon)
            local pillIconId = args.ButtonIcon and GetIcon(args.ButtonIcon) or nil
            if pillIconId and pillIconId ~= "" then
                local bi = Library:Create("ImageLabel", {
                    Name                   = "PillIcon",
                    Parent                 = pill,
                    BackgroundTransparency = 1,
                    BorderSizePixel        = 0,
                    LayoutOrder            = -1,
                    Size                   = UDim2.new(0,12,0,12),
                    Image                  = pillIconId,
                    ImageColor3            = T.Text,
                })
                track("Text", bi, "ImageColor3")
            end

            -- Label: AutomaticSize.X only — height is fixed to pill height
            Library:Create("TextLabel", {
                Name                   = "BtnText",
                Parent                 = pill,
                BackgroundTransparency = 1,
                BorderSizePixel        = 0,
                LayoutOrder            = 0,
                AutomaticSize          = Enum.AutomaticSize.X,
                Size                   = UDim2.new(0,0,1,-4),
                Font                   = Enum.Font.GothamSemibold,
                RichText               = true,
                Text                   = btnText,
                TextColor3             = T.Text,
                TextSize               = 11,
                TextStrokeTransparency = 0.7,
                TextXAlignment         = Enum.TextXAlignment.Center,
                TextYAlignment         = Enum.TextYAlignment.Center,
                TextScaled             = false,
                TextTruncate           = Enum.TextTruncate.None,
            })

            local click = Library:Button(pill)
            click.MouseButton1Click:Connect(function()
                if Library:IsDropdownOpen() then return end
                task.spawn(Library.Effect, click, pill)
                if callback then pcall(callback) end
            end)
            return click
        end

        -- Toggle
        function Page:Toggle(args)
            local value    = args.Value or false
            local callback = args.Callback or function() end
            local rows     = MakeRows(pageScroll, args.Title, args.Desc, T, track, args.Icon)
            local rightF   = rows.Right
            local textF    = rows.Text
            local titleLbl = textF:FindFirstChild("Title")

            local box = Library:Create("Frame", {
                Name             = "Box",
                Parent           = rightF,
                BackgroundColor3 = T.RowAlt,
                BorderSizePixel  = 0,
                Size             = UDim2.new(0,20,0,20),
            })
            track("RowAlt", box, "BackgroundColor3")
            local boxStroke = Library:Create("UIStroke", { Parent = box, Color = T.Stroke, Thickness = 0.5 })
            track("Stroke", boxStroke, "Color")
            Library:Create("UICorner", { Parent = box, CornerRadius = UDim.new(0,5) })

            local fill = Library:Create("Frame", {
                Name             = "Fill",
                Parent           = box,
                AnchorPoint      = Vector2.new(0.5,0.5),
                BackgroundColor3 = T.Accent,
                BackgroundTransparency = 1,
                BorderSizePixel  = 0,
                Position         = UDim2.new(0.5,0,0.5,0),
                Size             = UDim2.new(1,0,1,0),
            })
            track("Accent", fill, "BackgroundColor3")
            Library:Create("UICorner", { Parent = fill, CornerRadius = UDim.new(0,5) })
            Library:Create("UIGradient", { Parent = fill,
                Color    = ColorSequence.new{ColorSequenceKeypoint.new(0,Color3.new(1,1,1)),ColorSequenceKeypoint.new(1,Color3.fromRGB(56,56,56))},
                Rotation = 90 })
            local checkImg = Library:Create("ImageLabel", {
                Parent                 = fill,
                AnchorPoint            = Vector2.new(0.5,0.5),
                BackgroundTransparency = 1,
                BorderSizePixel        = 0,
                Position               = UDim2.new(0.5,0,0.5,0),
                Size                   = UDim2.new(0.45,0,0.45,0),
                Image                  = "rbxassetid://86682186031062",
                ImageTransparency      = 1,
            })

            local D = { Value = value, Title = args.Title, Desc = args.Desc }

            local function apply(val)
                D.Value = val
                local want = val and T.Accent or T.Text
                if titleLbl then titleLbl.TextColor3 = want end
                if val then
                    Library:Tween({ v = fill,     t = 0.3, s = "Exponential", d = "Out", g = { BackgroundTransparency = 0 } }):Play()
                    Library:Tween({ v = checkImg, t = 0.3, s = "Exponential", d = "Out", g = { ImageTransparency = 0, Size = UDim2.new(0.55,0,0.55,0) } }):Play()
                    boxStroke.Thickness = 0
                else
                    Library:Tween({ v = fill,     t = 0.3, s = "Exponential", d = "Out", g = { BackgroundTransparency = 1 } }):Play()
                    Library:Tween({ v = checkImg, t = 0.3, s = "Exponential", d = "Out", g = { ImageTransparency = 1, Size = UDim2.new(0.45,0,0.45,0) } }):Play()
                    boxStroke.Thickness = 0.5
                end
            end

            -- Sync title color when T.Accent/T.Text change via SetTheme
            RunService.Heartbeat:Connect(function()
                if not titleLbl or not titleLbl.Parent then return end
                local want = D.Value and T.Accent or T.Text
                if titleLbl.TextColor3 ~= want then titleLbl.TextColor3 = want end
            end)

            local click = Library:Button(box)
            click.MouseButton1Click:Connect(function()
                if Library:IsDropdownOpen() then return end
                apply(not D.Value)
                pcall(callback, D.Value)
            end)
            apply(value)

            return setmetatable({}, {
                __newindex = function(_,k,v) rawset(D,k,v)
                    if k == "Value" then apply(v); pcall(callback, v)
                    elseif k == "Title" and titleLbl then titleLbl.Text = tostring(v)
                    elseif k == "Desc" then
                        local d = textF:FindFirstChild("Desc"); if d then d.Text = tostring(v) end
                    end
                end, __index = D })
        end

        -- Slider
        function Page:Slider(args)
            local mn       = args.Min or 0
            local mx       = args.Max or 100
            local rnd      = args.Rounding or 0
            local value    = math.clamp(args.Value or mn, mn, mx)
            local callback = args.Callback or function() end

            local sf = Library:Create("Frame", {
                Name             = "Slider",
                Parent           = pageScroll,
                BackgroundColor3 = T.Row,
                BorderSizePixel  = 0,
                Size             = UDim2.new(1,0,0,46),
            })
            track("Row", sf, "BackgroundColor3")
            Library:Create("UICorner", { Parent = sf, CornerRadius = UDim.new(0,4) })
            local sfStroke = Library:Create("UIStroke", { Parent = sf, Color = T.Stroke, Thickness = 0.5 })
            track("Stroke", sfStroke, "Color")
            Library:Create("UIPadding", {
                Parent       = sf,
                PaddingLeft  = UDim.new(0,12),
                PaddingRight = UDim.new(0,12),
            })

            local titleLbl = Library:Create("TextLabel", {
                Name                   = "Title",
                Parent                 = sf,
                BackgroundTransparency = 1,
                BorderSizePixel        = 0,
                Position               = UDim2.new(0,0,0.08,0),
                Size                   = UDim2.new(0.6,0,0,18),
                Font                   = Enum.Font.GothamSemibold,
                RichText               = true,
                Text                   = args.Title or "",
                TextColor3             = T.Text,
                TextSize               = 12,
                TextStrokeTransparency = 0.7,
                TextWrapped            = false,
                TextXAlignment         = Enum.TextXAlignment.Left,
            })
            track("Text", titleLbl, "TextColor3")
            Library:Create("UIGradient", { Parent = titleLbl,
                Color    = ColorSequence.new{ColorSequenceKeypoint.new(0,Color3.new(1,1,1)),ColorSequenceKeypoint.new(0.75,T.SubText),ColorSequenceKeypoint.new(1,Color3.fromRGB(100,100,100))},
                Rotation = 90 })

            local function doRound(n) return math.floor(n*(10^rnd)+0.5)/(10^rnd) end

            local valBox = Library:Create("TextBox", {
                Name                   = "ValBox",
                Parent                 = sf,
                AnchorPoint            = Vector2.new(1,0),
                BackgroundTransparency = 1,
                BorderSizePixel        = 0,
                Position               = UDim2.new(1,0,0.08,0),
                Size                   = UDim2.new(0,55,0,18),
                Font                   = Enum.Font.GothamMedium,
                Text                   = tostring(doRound(value)),
                TextColor3             = T.Text,
                TextSize               = 11,
                TextTransparency       = 0.45,
                TextTruncate           = Enum.TextTruncate.AtEnd,
                TextXAlignment         = Enum.TextXAlignment.Right,
                ZIndex                 = 5,
            })

            local track2 = Library:Create("Frame", {
                Name             = "Track",
                Parent           = sf,
                AnchorPoint      = Vector2.new(0,1),
                BackgroundColor3 = Color3.fromRGB(30,30,30),
                BorderSizePixel  = 0,
                Position         = UDim2.new(0,0,1,-8),
                Size             = UDim2.new(1,0,0,4),
            })
            Library:Create("UICorner", { Parent = track2, CornerRadius = UDim.new(1,0) })

            local fillBar = Library:Create("Frame", {
                Name             = "Fill",
                Parent           = track2,
                BackgroundColor3 = T.Accent,
                BorderSizePixel  = 0,
                Size             = UDim2.new(0,0,1,0),
            })
            track("Accent", fillBar, "BackgroundColor3")
            Library:Create("UICorner", { Parent = fillBar, CornerRadius = UDim.new(1,0) })
            Library:Create("UIGradient", { Parent = fillBar,
                Color    = ColorSequence.new{ColorSequenceKeypoint.new(0,Color3.new(1,1,1)),ColorSequenceKeypoint.new(1,Color3.fromRGB(47,47,47))},
                Rotation = 90 })

            Library:Create("Frame", {
                Parent           = fillBar,
                AnchorPoint      = Vector2.new(1,0.5),
                BackgroundColor3 = Color3.new(1,1,1),
                BorderSizePixel  = 0,
                Position         = UDim2.new(1,0,0.5,0),
                Size             = UDim2.new(0,5,0,10),
            })

            local D = { Value = doRound(value), Min = mn, Max = mx, Title = args.Title }
            local dragging = false

            local function updateSlider(v)
                v = doRound(math.clamp(v, mn, mx))
                D.Value = v
                local ratio = (v - mn) / ((mx - mn) == 0 and 1 or (mx - mn))
                Library:Tween({ v = fillBar, t = 0.08, s = "Linear", d = "Out",
                    g = { Size = UDim2.new(ratio,0,1,0) } }):Play()
                valBox.Text = tostring(v)
                pcall(callback, v)
                return v
            end

            local function valFromInput(input)
                local ax = track2.AbsolutePosition.X
                local aw = track2.AbsoluteSize.X
                if aw == 0 then return mn end
                return math.clamp((input.Position.X - ax) / aw, 0, 1) * (mx - mn) + mn
            end

            local clickBtn = Library:Button(sf)
            clickBtn.InputBegan:Connect(function(input)
                if Library:IsDropdownOpen() then return end
                if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = true
                    Library:Tween({ v = titleLbl, t = 0.15, s = "Linear", d = "Out", g = { TextColor3 = T.Accent } }):Play()
                    Library:Tween({ v = valBox,   t = 0.15, s = "Linear", d = "Out", g = { TextColor3 = T.Accent, TextTransparency = 0, TextSize = 14 } }):Play()
                    updateSlider(valFromInput(input))
                end
            end)
            clickBtn.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = false
                    Library:Tween({ v = titleLbl, t = 0.15, s = "Linear", d = "Out", g = { TextColor3 = T.Text } }):Play()
                    Library:Tween({ v = valBox,   t = 0.15, s = "Linear", d = "Out", g = { TextColor3 = T.Text, TextTransparency = 0.45, TextSize = 11 } }):Play()
                end
            end)
            UserInputService.InputChanged:Connect(function(input)
                if Library:IsDropdownOpen() then return end
                if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
                              or input.UserInputType == Enum.UserInputType.Touch) then
                    updateSlider(valFromInput(input))
                end
            end)
            valBox.Focused:Connect(function()
                Library:Tween({ v = valBox, t = 0.15, s = "Linear", d = "Out", g = { TextColor3 = T.Accent, TextTransparency = 0 } }):Play()
            end)
            valBox.FocusLost:Connect(function()
                Library:Tween({ v = valBox, t = 0.15, s = "Linear", d = "Out", g = { TextColor3 = T.Text, TextTransparency = 0.45 } }):Play()
                updateSlider(tonumber(valBox.Text) or D.Value)
            end)
            updateSlider(value)

            return setmetatable({}, {
                __newindex = function(_,k,v) rawset(D,k,v)
                    if k == "Value" then updateSlider(tonumber(v) or mn)
                    elseif k == "Title" then titleLbl.Text = tostring(v) end
                end, __index = D })
        end

        -- Input
        function Page:Input(args)
            local callback = args.Callback or function() end
            local icon     = GetIcon(args.Icon)

            local wrap = Library:Create("Frame", {
                Name                   = "InputWrap",
                Parent                 = pageScroll,
                BackgroundTransparency = 1,
                BorderSizePixel        = 0,
                Size                   = UDim2.new(1,0,0,30),
            })
            Library:Create("UIListLayout", {
                Parent            = wrap,
                FillDirection     = Enum.FillDirection.Horizontal,
                VerticalAlignment = Enum.VerticalAlignment.Center,
                SortOrder         = Enum.SortOrder.LayoutOrder,
                Padding           = UDim.new(0,5),
            })

            if icon and icon ~= "" then
                local icoLbl = Library:Create("ImageLabel", {
                    Parent                 = wrap,
                    BackgroundTransparency = 1,
                    BorderSizePixel        = 0,
                    LayoutOrder            = -1,
                    Size                   = UDim2.new(0,18,0,18),
                    Image                  = icon,
                    ImageColor3            = T.Accent,
                })
                track("Accent", icoLbl, "ImageColor3")
            end

            local frontWidth = icon and icon ~= "" and UDim2.new(1,-58,1,0) or UDim2.new(1,-35,1,0)
            local front = Library:Create("Frame", {
                Name             = "Front",
                Parent           = wrap,
                BackgroundColor3 = T.Row,
                BorderSizePixel  = 0,
                Size             = frontWidth,
            })
            track("Row", front, "BackgroundColor3")
            Library:Create("UICorner", { Parent = front, CornerRadius = UDim.new(0,3) })
            local fStroke = Library:Create("UIStroke", { Parent = front, Color = T.Stroke, Thickness = 0.5 })
            track("Stroke", fStroke, "Color")

            local ph = (args.Title or "Type here") .. (args.Desc and (" — " .. args.Desc) or "")
            local tb = Library:Create("TextBox", {
                Parent                 = front,
                AnchorPoint            = Vector2.new(0.5,0.5),
                BackgroundTransparency = 1,
                BorderSizePixel        = 0,
                Position               = UDim2.new(0.5,0,0.5,0),
                Size                   = UDim2.new(1,-16,1,0),
                Font                   = Enum.Font.GothamMedium,
                PlaceholderColor3      = Color3.fromRGB(80,80,80),
                PlaceholderText        = ph,
                Text                   = tostring(args.Value or ""),
                TextColor3             = T.Text,
                TextSize               = 11,
                TextXAlignment         = Enum.TextXAlignment.Left,
            })
            track("Text", tb, "TextColor3")
            tb.FocusLost:Connect(function(entered)
                if entered then pcall(callback, tb.Text) end
            end)

            local enterBtn = Library:Create("Frame", {
                Name             = "Enter",
                Parent           = wrap,
                BackgroundColor3 = T.Accent,
                BorderSizePixel  = 0,
                Size             = UDim2.new(0,30,0,30),
            })
            track("Accent", enterBtn, "BackgroundColor3")
            Library:Create("UICorner",   { Parent = enterBtn, CornerRadius = UDim.new(0,4) })
            Library:Create("UIGradient", { Parent = enterBtn,
                Color    = ColorSequence.new{ColorSequenceKeypoint.new(0,Color3.new(1,1,1)),ColorSequenceKeypoint.new(1,Color3.fromRGB(56,56,56))},
                Rotation = 90 })
            local enterIcon = Library:Create("ImageLabel", {
                Parent                 = enterBtn,
                AnchorPoint            = Vector2.new(0.5,0.5),
                BackgroundTransparency = 1,
                BorderSizePixel        = 0,
                Position               = UDim2.new(0.5,0,0.5,0),
                Size                   = UDim2.new(0,14,0,14),
                Image                  = "rbxassetid://78020815235467",
            })
            local copyClick = Library:Button(enterBtn)
            copyClick.MouseButton1Click:Connect(function()
                if Library:IsDropdownOpen() then return end
                pcall(setclipboard, tb.Text)
                enterIcon.Image = "rbxassetid://121742282171603"
                task.delay(3, function()
                    if enterIcon and enterIcon.Parent then
                        enterIcon.Image = "rbxassetid://78020815235467"
                    end
                end)
            end)
            return tb
        end

        -- Dropdown
        function Page:Dropdown(args)
            local listItems = args.List     or {}
            local callback  = args.Callback or function() end
            local isMulti   = typeof(args.Value) == "table"
            local value     = args.Value

            local rows   = MakeRows(pageScroll, args.Title, nil, T, track, args.Icon)
            local rightF = rows.Right
            local textF  = rows.Text
            local descLbl -- will be the "N/A" desc we manage

            -- Show current selection in the Desc slot
            local function getSelText()
                if isMulti then
                    return type(value) == "table" and #value > 0 and table.concat(value, ", ") or "None"
                end
                return value and tostring(value) or "None"
            end

            -- Add/replace desc label
            local descEl = textF:FindFirstChild("Desc")
            if not descEl then
                descEl = Library:Create("TextLabel", {
                    Name                   = "Desc",
                    Parent                 = textF,
                    BackgroundTransparency = 1,
                    BorderSizePixel        = 0,
                    AutomaticSize          = Enum.AutomaticSize.Y,
                    Size                   = UDim2.new(1,0,0,0),
                    Font                   = Enum.Font.GothamMedium,
                    Text                   = getSelText(),
                    TextColor3             = T.Text,
                    TextSize               = 10,
                    TextTransparency       = 0.55,
                    TextWrapped            = true,
                    TextXAlignment         = Enum.TextXAlignment.Left,
                })
                track("Text", descEl, "TextColor3")
            else
                descEl.Text = getSelText()
            end

            Library:Create("ImageLabel", {
                Parent                 = rightF,
                BackgroundTransparency = 1,
                BorderSizePixel        = 0,
                Size                   = UDim2.new(0,18,0,18),
                Image                  = "rbxassetid://132291592681506",
                ImageTransparency      = 0.5,
            })
            local openClick = Library:Button(rows.Vec)

            -- Dropdown popup
            local drop = Library:Create("Frame", {
                Name             = "Dropdown",
                Parent           = Background,
                AnchorPoint      = Vector2.new(0.5,0.5),
                BackgroundColor3 = T.DropBg,
                BorderSizePixel  = 0,
                Position         = UDim2.new(0.5,0,0.3,0),
                Size             = UDim2.new(0,300,0,250),
                ZIndex           = 500,
                Visible          = false,
            })
            track("DropBg", drop, "BackgroundColor3")
            Library:Create("UICorner", { Parent = drop, CornerRadius = UDim.new(0,4) })
            local dStroke = Library:Create("UIStroke", { Parent = drop, Color = T.DropStroke, Thickness = 0.5 })
            track("DropStroke", dStroke, "Color")
            Library:Create("UIListLayout", {
                Parent              = drop,
                Padding             = UDim.new(0,6),
                HorizontalAlignment = Enum.HorizontalAlignment.Center,
                SortOrder           = Enum.SortOrder.LayoutOrder,
            })
            Library:Create("UIPadding", {
                Parent        = drop,
                PaddingTop    = UDim.new(0,10),
                PaddingBottom = UDim.new(0,10),
                PaddingLeft   = UDim.new(0,10),
                PaddingRight  = UDim.new(0,10),
            })

            -- Drop header
            local dropHdr = Library:Create("Frame", {
                Parent                 = drop,
                BackgroundTransparency = 1,
                BorderSizePixel        = 0,
                LayoutOrder            = -5,
                Size                   = UDim2.new(1,0,0,30),
                ZIndex                 = 500,
            })
            Library:Create("UIListLayout", { Parent = dropHdr, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0,1) })
            local dropTitle = Library:Create("TextLabel", {
                Parent                 = dropHdr,
                BackgroundTransparency = 1,
                BorderSizePixel        = 0,
                LayoutOrder            = -1,
                Size                   = UDim2.new(1,0,0,14),
                ZIndex                 = 500,
                Font                   = Enum.Font.GothamSemibold,
                Text                   = args.Title or "",
                TextColor3             = T.Accent,
                TextSize               = 13,
                TextXAlignment         = Enum.TextXAlignment.Left,
            })
            track("Accent", dropTitle, "TextColor3")
            local dropSel = Library:Create("TextLabel", {
                Parent                 = dropHdr,
                BackgroundTransparency = 1,
                BorderSizePixel        = 0,
                Size                   = UDim2.new(1,0,0,11),
                ZIndex                 = 500,
                Font                   = Enum.Font.GothamMedium,
                Text                   = getSelText(),
                TextColor3             = T.Text,
                TextSize               = 10,
                TextTransparency       = 0.55,
                TextXAlignment         = Enum.TextXAlignment.Left,
            })
            track("Text", dropSel, "TextColor3")

            -- Search box
            local searchWrap = Library:Create("Frame", {
                Parent                 = drop,
                BackgroundColor3       = T.Row,
                BorderSizePixel        = 0,
                LayoutOrder            = -4,
                Size                   = UDim2.new(1,0,0,24),
                ZIndex                 = 500,
            })
            track("Row", searchWrap, "BackgroundColor3")
            Library:Create("UICorner", { Parent = searchWrap, CornerRadius = UDim.new(0,3) })
            local swStroke = Library:Create("UIStroke", { Parent = searchWrap, Color = T.Stroke, Thickness = 0.5 })
            track("Stroke", swStroke, "Color")
            local searchBox = Library:Create("TextBox", {
                Parent                 = searchWrap,
                AnchorPoint            = Vector2.new(0.5,0.5),
                BackgroundTransparency = 1,
                BorderSizePixel        = 0,
                Position               = UDim2.new(0.5,0,0.5,0),
                Size                   = UDim2.new(1,-16,1,0),
                ZIndex                 = 500,
                Font                   = Enum.Font.GothamMedium,
                PlaceholderColor3      = Color3.fromRGB(80,80,80),
                PlaceholderText        = "Search…",
                Text                   = "",
                TextColor3             = T.Text,
                TextSize               = 11,
                TextXAlignment         = Enum.TextXAlignment.Left,
            })
            track("Text", searchBox, "TextColor3")

            -- List
            local listScroll = Library:Create("ScrollingFrame", {
                Parent                 = drop,
                BackgroundTransparency = 1,
                BorderSizePixel        = 0,
                LayoutOrder            = 0,
                Size                   = UDim2.new(1,0,0,155),
                ZIndex                 = 500,
                ScrollBarThickness     = 0,
            })
            local listLayout = Library:Create("UIListLayout", {
                Parent    = listScroll,
                Padding   = UDim.new(0,3),
                SortOrder = Enum.SortOrder.LayoutOrder,
                HorizontalAlignment = Enum.HorizontalAlignment.Center,
            })
            Library:Create("UIPadding", { Parent = listScroll, PaddingLeft = UDim.new(0,1), PaddingRight = UDim.new(0,1) })
            listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                listScroll.CanvasSize = UDim2.new(0,0,0,listLayout.AbsoluteContentSize.Y+10)
            end)

            local function setTexts()
                local s = getSelText()
                descEl.Text  = s
                dropSel.Text = s
            end

            local isOpen    = false
            local selValues = {}
            local selOrder  = 0

            local function inTable(v, t)
                if type(t) ~= "table" then return false end
                for _,x in pairs(t) do if x == v then return true end end
                return false
            end

            UserInputService.InputBegan:Connect(function(inp)
                if not isOpen then return end
                if inp.UserInputType == Enum.UserInputType.MouseButton1
                or inp.UserInputType == Enum.UserInputType.Touch then
                    local mx2 = inp.Position
                    local dp  = drop.AbsolutePosition
                    local ds  = drop.AbsoluteSize
                    if not (mx2.X >= dp.X and mx2.X <= dp.X+ds.X and mx2.Y >= dp.Y and mx2.Y <= dp.Y+ds.Y) then
                        isOpen = false
                        drop.Visible   = false
                        drop.Position  = UDim2.new(0.5,0,0.3,0)
                    end
                end
            end)
            openClick.MouseButton1Click:Connect(function()
                if Library:IsDropdownOpen() then return end
                isOpen = not isOpen
                if isOpen then
                    drop.Visible = true
                    Library:Tween({ v = drop, t = 0.3, s = "Back", d = "Out",
                        g = { Position = UDim2.new(0.5,0,0.5,0) } }):Play()
                else
                    drop.Visible  = false
                    drop.Position = UDim2.new(0.5,0,0.3,0)
                end
            end)
            searchBox.Changed:Connect(function()
                local q = string.lower(searchBox.Text)
                for _,child in pairs(listScroll:GetChildren()) do
                    if child:IsA("Frame") and child:FindFirstChild("Lbl") then
                        child.Visible = string.find(string.lower(child.Lbl.Text), q, 1, true) ~= nil
                    end
                end
            end)

            local Setting = {}

            function Setting:AddList(name)
                local item = Library:Create("Frame", {
                    Name             = "Item",
                    Parent           = listScroll,
                    BackgroundColor3 = Color3.new(),
                    BackgroundTransparency = 1,
                    BorderSizePixel  = 0,
                    Size             = UDim2.new(1,0,0,24),
                    ZIndex           = 500,
                })
                Library:Create("UICorner", { Parent = item, CornerRadius = UDim.new(0,3) })
                local itemLbl = Library:Create("TextLabel", {
                    Name                   = "Lbl",
                    Parent                 = item,
                    AnchorPoint            = Vector2.new(0.5,0.5),
                    BackgroundTransparency = 1,
                    BorderSizePixel        = 0,
                    Position               = UDim2.new(0.5,0,0.5,0),
                    Size                   = UDim2.new(1,-12,1,0),
                    ZIndex                 = 500,
                    Font                   = Enum.Font.GothamSemibold,
                    Text                   = tostring(name),
                    TextColor3             = T.Text,
                    TextSize               = 11,
                    TextStrokeTransparency = 0.7,
                    TextXAlignment         = Enum.TextXAlignment.Left,
                })
                Library:Create("UIGradient", { Parent = itemLbl,
                    Color = ColorSequence.new{ColorSequenceKeypoint.new(0,Color3.new(1,1,1)),ColorSequenceKeypoint.new(0.75,T.SubText),ColorSequenceKeypoint.new(1,Color3.fromRGB(100,100,100))},
                    Rotation = 90 })

                local function setActive(on)
                    itemLbl.TextColor3 = on and T.Accent or T.Text
                    Library:Tween({ v = item, t = 0.15, s = "Linear", d = "Out",
                        g = { BackgroundTransparency = on and 0.8 or 1 } }):Play()
                end

                local itemClick = Library:Button(item)
                itemClick.MouseButton1Click:Connect(function()
                    if isMulti then
                        if selValues[name] then
                            selValues[name] = nil; item.LayoutOrder = 0; setActive(false)
                        else
                            selOrder = selOrder - 1; selValues[name] = selOrder
                            item.LayoutOrder = selOrder; setActive(true)
                        end
                        local sel = {}
                        for k in pairs(selValues) do table.insert(sel, k) end
                        table.sort(sel)
                        value = sel
                        setTexts()
                        pcall(callback, sel)
                    else
                        for _,ch in pairs(listScroll:GetChildren()) do
                            if ch:IsA("Frame") and ch:FindFirstChild("Lbl") then
                                ch.Lbl.TextColor3 = T.Text
                                Library:Tween({ v = ch, t = 0.15, s = "Linear", d = "Out",
                                    g = { BackgroundTransparency = 1 } }):Play()
                            end
                        end
                        setActive(true)
                        value = name
                        setTexts()
                        pcall(callback, value)
                    end
                end)

                -- Restore state from initial value
                task.delay(0, function()
                    if isMulti then
                        if inTable(name, value) then
                            selOrder = selOrder - 1; selValues[name] = selOrder
                            item.LayoutOrder = selOrder; setActive(true)
                            local sel = {}
                            for k in pairs(selValues) do table.insert(sel, k) end
                            table.sort(sel); setTexts()
                        end
                    else
                        if name == value then setActive(true); setTexts() end
                    end
                end)
            end

            function Setting:Clear(target)
                for _,ch in pairs(listScroll:GetChildren()) do
                    if ch:IsA("Frame") then
                        local lbl = ch:FindFirstChild("Lbl")
                        if lbl then
                            local match = target == nil
                                or (type(target) == "string" and lbl.Text == target)
                                or (type(target) == "table" and inTable(lbl.Text, target))
                            if match then ch:Destroy() end
                        end
                    end
                end
                if target == nil then
                    value = isMulti and {} or nil
                    selValues = {}; selOrder = 0
                    descEl.Text = "None"; dropSel.Text = "None"
                end
            end

            for _,name in ipairs(listItems) do Setting:AddList(name) end
            return Setting
        end

        -- Keybind
        function Page:Keybind(args)
            local value    = args.Value or Enum.KeyCode.Unknown
            local callback = args.Callback or function() end
            local rows     = MakeRows(pageScroll, args.Title, args.Desc, T, track, args.Icon)
            local rightF   = rows.Right
            local textF    = rows.Text

            local keyBtn = Library:Create("Frame", {
                Name             = "KeyBtn",
                Parent           = rightF,
                BackgroundColor3 = T.RowAlt,
                BorderSizePixel  = 0,
                Size             = UDim2.new(0,80,0,22),
            })
            track("RowAlt", keyBtn, "BackgroundColor3")
            Library:Create("UICorner", { Parent = keyBtn, CornerRadius = UDim.new(0,4) })
            local kbStroke = Library:Create("UIStroke", { Parent = keyBtn, Color = T.Stroke, Thickness = 0.5 })
            track("Stroke", kbStroke, "Color")

            local keyLbl = Library:Create("TextLabel", {
                Parent                 = keyBtn,
                AnchorPoint            = Vector2.new(0.5,0.5),
                BackgroundTransparency = 1,
                BorderSizePixel        = 0,
                Position               = UDim2.new(0.5,0,0.5,0),
                Size                   = UDim2.new(1,-8,1,0),
                Font                   = Enum.Font.GothamSemibold,
                Text                   = value.Name,
                TextColor3             = T.Accent,
                TextSize               = 11,
                TextTruncate           = Enum.TextTruncate.AtEnd,
            })
            track("Accent", keyLbl, "TextColor3")

            local D = { Value = value, Title = args.Title, Desc = args.Desc }
            local listening = false

            local function setKey(key)
                D.Value    = key
                keyLbl.Text      = key.Name
                keyLbl.TextColor3 = T.Accent
                Library:Tween({ v = keyBtn, t = 0.15, s = "Exponential", d = "Out",
                    g = { BackgroundColor3 = T.RowAlt } }):Play()
            end

            local click = Library:Button(keyBtn)
            click.MouseButton1Click:Connect(function()
                if Library:IsDropdownOpen() or listening then return end
                listening = true
                keyLbl.Text      = "…"
                keyLbl.TextColor3 = T.Text
                Library:Tween({ v = keyBtn, t = 0.15, s = "Exponential", d = "Out",
                    g = { BackgroundColor3 = T.Stroke } }):Play()
                local conn
                conn = UserInputService.InputBegan:Connect(function(inp, proc)
                    if proc then return end
                    if inp.UserInputType == Enum.UserInputType.Keyboard then
                        listening = false; conn:Disconnect()
                        setKey(inp.KeyCode)
                        pcall(callback, inp.KeyCode)
                    end
                end)
            end)
            UserInputService.InputBegan:Connect(function(inp, proc)
                if proc or listening then return end
                if inp.KeyCode == D.Value then pcall(callback, D.Value) end
            end)

            return setmetatable({}, {
                __newindex = function(_,k,v) rawset(D,k,v)
                    if k == "Value" then setKey(v)
                    elseif k == "Title" then
                        local t = textF:FindFirstChild("Title"); if t then t.Text = tostring(v) end
                    elseif k == "Desc" then
                        local d = textF:FindFirstChild("Desc"); if d then d.Text = tostring(v) end
                    end
                end, __index = D })
        end

        -- Banner
        function Page:Banner(asset)
            local b = Library:Create("ImageLabel", {
                Name                   = "Banner",
                Parent                 = pageScroll,
                BackgroundTransparency = 1,
                BorderSizePixel        = 0,
                Size                   = UDim2.new(1,0,0,230),
                Image                  = Library:Asset(asset),
                ScaleType              = Enum.ScaleType.Crop,
            })
            Library:Create("UICorner", { Parent = b, CornerRadius = UDim.new(0,4) })
            return b
        end

        return Page
    end  -- NewPage

    -------------------------------------------------------------------
    -- Library window-level methods
    -------------------------------------------------------------------
    function Library:SetTimeValue(v)   THETIME.Text = tostring(v) end

    function Library:AddSizeSlider(pg)
        return pg:Slider({
            Title    = "Interface Scale",
            Min      = 0.4, Max = 2.5, Rounding = 1,
            Value    = Scaler.Scale,
            Callback = function(v)
                Scaler:SetAttribute("ManualScale", true)
                Scaler.Scale = v
            end,
        })
    end

    function Library:SetTheme(newT)
        if newT.BG  then newT.Background = newT.BG;  newT.BG  = nil end
        if newT.Tab then newT.TabBg      = newT.Tab; newT.Tab = nil end
        for k,v in pairs(newT) do T[k] = ResolveColor(v) end
        for k in pairs(newT) do flushKey(k); _prevT[k] = T[k] end
    end

    function Library:SetExecutorIdentity(visible)
        ExecLabel.Visible = visible == true
    end

    --[[  Library:SetPillIcon(name)
         Changes the toggle pill icon at runtime.
           "eye"               Lucide shorthand
           "lucide-home"       exact key
           "rbxassetid://..."  raw asset
           nil                 restore default Vita logo
    --]]
    function Library:SetPillIcon(name)
        if not name then
            PillLogo.Image = defaultPillImg
        else
            local id = GetIcon(name)
            PillLogo.Image = (id and id ~= "") and id or defaultPillImg
        end
    end

    function Library:Destroy()
        pcall(function() Xova:Destroy() end)
        pcall(function() ToggleScreen:Destroy() end)
        pcall(function() NotifGui:Destroy() end)
    end

    return Window
end  -- Library:Window

return Library
