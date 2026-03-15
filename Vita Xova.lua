--[[
    Vita UI Library
    Updated: Auto Scaling, Customizable Theme (Hex + Color3), Customizable Size,
             Bindable Toggle Key, Keybind Element, Notifications,
             TabImage Color, ExecutorIdentity Label,
             Unified Real-Time Theme Tracking (Heartbeat watcher),
             Full Lucide Icon System (818 icons, WindUI-compatible GetIcon),
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
-- Built-in Icon System  (818 Lucide icons — WindUI compatible)
-- Sourced from the official Lucide Roblox asset table.
-- GetIcon() is the single resolver used by every UI element.
------------------------------------------------------------
local LucideIcons = {
	["lucide-mouse-2"]                                      = "rbxassetid://10088146939",
	["lucide-internet"]                                     = "rbxassetid://12785195438",
	["lucide-earth"]                                        = "rbxassetid://115986292591138",
	["lucide-settings-3"]                                   = "rbxassetid://14007344336",
	["lucide-accessibility"]                                = "rbxassetid://10709751939",
	["lucide-activity"]                                     = "rbxassetid://10709752035",
	["lucide-air-vent"]                                     = "rbxassetid://10709752131",
	["lucide-airplay"]                                      = "rbxassetid://10709752254",
	["lucide-alarm-check"]                                  = "rbxassetid://10709752405",
	["lucide-alarm-clock"]                                  = "rbxassetid://10709752630",
	["lucide-alarm-clock-off"]                              = "rbxassetid://10709752508",
	["lucide-alarm-minus"]                                  = "rbxassetid://10709752732",
	["lucide-alarm-plus"]                                   = "rbxassetid://10709752825",
	["lucide-album"]                                        = "rbxassetid://10709752906",
	["lucide-alert-circle"]                                 = "rbxassetid://10709752996",
	["lucide-alert-octagon"]                                = "rbxassetid://10709753064",
	["lucide-alert-triangle"]                               = "rbxassetid://10709753149",
	["lucide-align-center"]                                 = "rbxassetid://10709753570",
	["lucide-align-center-horizontal"]                      = "rbxassetid://10709753272",
	["lucide-align-center-vertical"]                        = "rbxassetid://10709753421",
	["lucide-align-end-horizontal"]                         = "rbxassetid://10709753692",
	["lucide-align-end-vertical"]                           = "rbxassetid://10709753808",
	["lucide-align-horizontal-distribute-center"]           = "rbxassetid://10747779791",
	["lucide-align-horizontal-distribute-end"]              = "rbxassetid://10747784534",
	["lucide-align-horizontal-distribute-start"]            = "rbxassetid://10709754118",
	["lucide-align-horizontal-justify-center"]              = "rbxassetid://10709754204",
	["lucide-align-horizontal-justify-end"]                 = "rbxassetid://10709754317",
	["lucide-align-horizontal-justify-start"]               = "rbxassetid://10709754436",
	["lucide-align-horizontal-space-around"]                = "rbxassetid://10709754590",
	["lucide-align-horizontal-space-between"]               = "rbxassetid://10709754749",
	["lucide-align-justify"]                                = "rbxassetid://10709759610",
	["lucide-align-left"]                                   = "rbxassetid://10709759764",
	["lucide-align-right"]                                  = "rbxassetid://10709759895",
	["lucide-align-start-horizontal"]                       = "rbxassetid://10709760051",
	["lucide-align-start-vertical"]                         = "rbxassetid://10709760244",
	["lucide-align-vertical-distribute-center"]             = "rbxassetid://10709760351",
	["lucide-align-vertical-distribute-end"]                = "rbxassetid://10709760434",
	["lucide-align-vertical-distribute-start"]              = "rbxassetid://10709760612",
	["lucide-align-vertical-justify-center"]                = "rbxassetid://10709760814",
	["lucide-align-vertical-justify-end"]                   = "rbxassetid://10709761003",
	["lucide-align-vertical-justify-start"]                 = "rbxassetid://10709761176",
	["lucide-align-vertical-space-around"]                  = "rbxassetid://10709761324",
	["lucide-align-vertical-space-between"]                 = "rbxassetid://10709761434",
	["lucide-anchor"]                                       = "rbxassetid://10709761530",
	["lucide-angry"]                                        = "rbxassetid://10709761629",
	["lucide-annoyed"]                                      = "rbxassetid://10709761722",
	["lucide-aperture"]                                     = "rbxassetid://10709761813",
	["lucide-apple"]                                        = "rbxassetid://10709761889",
	["lucide-archive"]                                      = "rbxassetid://10709762233",
	["lucide-archive-restore"]                              = "rbxassetid://10709762058",
	["lucide-armchair"]                                     = "rbxassetid://10709762327",
	["lucide-arrow-big-down"]                               = "rbxassetid://10747796644",
	["lucide-arrow-big-left"]                               = "rbxassetid://10709762574",
	["lucide-arrow-big-right"]                              = "rbxassetid://10709762727",
	["lucide-arrow-big-up"]                                 = "rbxassetid://10709762879",
	["lucide-arrow-down"]                                   = "rbxassetid://10709767827",
	["lucide-arrow-down-circle"]                            = "rbxassetid://10709763034",
	["lucide-arrow-down-left"]                              = "rbxassetid://10709767656",
	["lucide-arrow-down-right"]                             = "rbxassetid://10709767750",
	["lucide-arrow-left"]                                   = "rbxassetid://10709768114",
	["lucide-arrow-left-circle"]                            = "rbxassetid://10709767936",
	["lucide-arrow-left-right"]                             = "rbxassetid://10709768019",
	["lucide-arrow-right"]                                  = "rbxassetid://10709768347",
	["lucide-arrow-right-circle"]                           = "rbxassetid://10709768226",
	["lucide-arrow-up"]                                     = "rbxassetid://10709768939",
	["lucide-arrow-up-circle"]                              = "rbxassetid://10709768432",
	["lucide-arrow-up-down"]                                = "rbxassetid://10709768538",
	["lucide-arrow-up-left"]                                = "rbxassetid://10709768661",
	["lucide-arrow-up-right"]                               = "rbxassetid://10709768787",
	["lucide-asterisk"]                                     = "rbxassetid://10709769095",
	["lucide-at-sign"]                                      = "rbxassetid://10709769286",
	["lucide-award"]                                        = "rbxassetid://10709769406",
	["lucide-axe"]                                          = "rbxassetid://10709769508",
	["lucide-axis-3d"]                                      = "rbxassetid://10709769598",
	["lucide-baby"]                                         = "rbxassetid://10709769732",
	["lucide-backpack"]                                     = "rbxassetid://10709769841",
	["lucide-baggage-claim"]                                = "rbxassetid://10709769935",
	["lucide-banana"]                                       = "rbxassetid://10709770005",
	["lucide-banknote"]                                     = "rbxassetid://10709770178",
	["lucide-bar-chart"]                                    = "rbxassetid://10709773755",
	["lucide-bar-chart-2"]                                  = "rbxassetid://10709770317",
	["lucide-bar-chart-3"]                                  = "rbxassetid://10709770431",
	["lucide-bar-chart-4"]                                  = "rbxassetid://10709770560",
	["lucide-bar-chart-horizontal"]                         = "rbxassetid://10709773669",
	["lucide-barcode"]                                      = "rbxassetid://10747360675",
	["lucide-baseline"]                                     = "rbxassetid://10709773863",
	["lucide-bath"]                                         = "rbxassetid://10709773963",
	["lucide-battery"]                                      = "rbxassetid://10709774640",
	["lucide-battery-charging"]                             = "rbxassetid://10709774068",
	["lucide-battery-full"]                                 = "rbxassetid://10709774206",
	["lucide-battery-low"]                                  = "rbxassetid://10709774370",
	["lucide-battery-medium"]                               = "rbxassetid://10709774513",
	["lucide-beaker"]                                       = "rbxassetid://10709774756",
	["lucide-bed"]                                          = "rbxassetid://10709775036",
	["lucide-bed-double"]                                   = "rbxassetid://10709774864",
	["lucide-bed-single"]                                   = "rbxassetid://10709774968",
	["lucide-beer"]                                         = "rbxassetid://10709775167",
	["lucide-bell"]                                         = "rbxassetid://10709775704",
	["lucide-bell-minus"]                                   = "rbxassetid://10709775241",
	["lucide-bell-off"]                                     = "rbxassetid://10709775320",
	["lucide-bell-plus"]                                    = "rbxassetid://10709775448",
	["lucide-bell-ring"]                                    = "rbxassetid://10709775560",
	["lucide-bike"]                                         = "rbxassetid://10709775894",
	["lucide-binary"]                                       = "rbxassetid://10709776050",
	["lucide-bitcoin"]                                      = "rbxassetid://10709776126",
	["lucide-bluetooth"]                                    = "rbxassetid://10709776655",
	["lucide-bluetooth-connected"]                          = "rbxassetid://10709776240",
	["lucide-bluetooth-off"]                                = "rbxassetid://10709776344",
	["lucide-bluetooth-searching"]                          = "rbxassetid://10709776501",
	["lucide-bold"]                                         = "rbxassetid://10747813908",
	["lucide-bomb"]                                         = "rbxassetid://10709781460",
	["lucide-bone"]                                         = "rbxassetid://10709781605",
	["lucide-book"]                                         = "rbxassetid://10709781824",
	["lucide-book-open"]                                    = "rbxassetid://10709781717",
	["lucide-bookmark"]                                     = "rbxassetid://10709782154",
	["lucide-bookmark-minus"]                               = "rbxassetid://10709781919",
	["lucide-bookmark-plus"]                                = "rbxassetid://10709782044",
	["lucide-bot"]                                          = "rbxassetid://10709782230",
	["lucide-box"]                                          = "rbxassetid://10709782497",
	["lucide-box-select"]                                   = "rbxassetid://10709782342",
	["lucide-boxes"]                                        = "rbxassetid://10709782582",
	["lucide-briefcase"]                                    = "rbxassetid://10709782662",
	["lucide-brush"]                                        = "rbxassetid://10709782758",
	["lucide-bug"]                                          = "rbxassetid://10709782845",
	["lucide-building"]                                     = "rbxassetid://10709783051",
	["lucide-building-2"]                                   = "rbxassetid://10709782939",
	["lucide-bus"]                                          = "rbxassetid://10709783137",
	["lucide-cake"]                                         = "rbxassetid://10709783217",
	["lucide-calculator"]                                   = "rbxassetid://10709783311",
	["lucide-calendar"]                                     = "rbxassetid://10709789505",
	["lucide-calendar-check"]                               = "rbxassetid://10709783474",
	["lucide-calendar-check-2"]                             = "rbxassetid://10709783392",
	["lucide-calendar-clock"]                               = "rbxassetid://10709783577",
	["lucide-calendar-days"]                                = "rbxassetid://10709783673",
	["lucide-calendar-heart"]                               = "rbxassetid://10709783835",
	["lucide-calendar-minus"]                               = "rbxassetid://10709783959",
	["lucide-calendar-off"]                                 = "rbxassetid://10709788784",
	["lucide-calendar-plus"]                                = "rbxassetid://10709788937",
	["lucide-calendar-range"]                               = "rbxassetid://10709789053",
	["lucide-calendar-search"]                              = "rbxassetid://10709789200",
	["lucide-calendar-x"]                                   = "rbxassetid://10709789407",
	["lucide-calendar-x-2"]                                 = "rbxassetid://10709789329",
	["lucide-camera"]                                       = "rbxassetid://10709789686",
	["lucide-camera-off"]                                   = "rbxassetid://10747822677",
	["lucide-car"]                                          = "rbxassetid://10709789810",
	["lucide-carrot"]                                       = "rbxassetid://10709789960",
	["lucide-cast"]                                         = "rbxassetid://10709790097",
	["lucide-charge"]                                       = "rbxassetid://10709790202",
	["lucide-check"]                                        = "rbxassetid://10709790644",
	["lucide-check-circle"]                                 = "rbxassetid://10709790387",
	["lucide-check-circle-2"]                               = "rbxassetid://10709790298",
	["lucide-check-square"]                                 = "rbxassetid://10709790537",
	["lucide-chef-hat"]                                     = "rbxassetid://10709790757",
	["lucide-cherry"]                                       = "rbxassetid://10709790875",
	["lucide-chevron-down"]                                 = "rbxassetid://10709790948",
	["lucide-chevron-first"]                                = "rbxassetid://10709791015",
	["lucide-chevron-last"]                                 = "rbxassetid://10709791130",
	["lucide-chevron-left"]                                 = "rbxassetid://10709791281",
	["lucide-chevron-right"]                                = "rbxassetid://10709791437",
	["lucide-chevron-up"]                                   = "rbxassetid://10709791523",
	["lucide-chevrons-down"]                                = "rbxassetid://10709796864",
	["lucide-chevrons-down-up"]                             = "rbxassetid://10709791632",
	["lucide-chevrons-left"]                                = "rbxassetid://10709797151",
	["lucide-chevrons-left-right"]                          = "rbxassetid://10709797006",
	["lucide-chevrons-right"]                               = "rbxassetid://10709797382",
	["lucide-chevrons-right-left"]                          = "rbxassetid://10709797274",
	["lucide-chevrons-up"]                                  = "rbxassetid://10709797622",
	["lucide-chevrons-up-down"]                             = "rbxassetid://10709797508",
	["lucide-chrome"]                                       = "rbxassetid://10709797725",
	["lucide-circle"]                                       = "rbxassetid://10709798174",
	["lucide-circle-dot"]                                   = "rbxassetid://10709797837",
	["lucide-circle-ellipsis"]                              = "rbxassetid://10709797985",
	["lucide-circle-slashed"]                               = "rbxassetid://10709798100",
	["lucide-citrus"]                                       = "rbxassetid://10709798276",
	["lucide-clapperboard"]                                 = "rbxassetid://10709798350",
	["lucide-clipboard"]                                    = "rbxassetid://10709799288",
	["lucide-clipboard-check"]                              = "rbxassetid://10709798443",
	["lucide-clipboard-copy"]                               = "rbxassetid://10709798574",
	["lucide-clipboard-edit"]                               = "rbxassetid://10709798682",
	["lucide-clipboard-list"]                               = "rbxassetid://10709798792",
	["lucide-clipboard-signature"]                          = "rbxassetid://10709798890",
	["lucide-clipboard-type"]                               = "rbxassetid://10709798999",
	["lucide-clipboard-x"]                                  = "rbxassetid://10709799124",
	["lucide-clock"]                                        = "rbxassetid://10709805144",
	["lucide-clock-1"]                                      = "rbxassetid://10709799535",
	["lucide-clock-10"]                                     = "rbxassetid://10709799718",
	["lucide-clock-11"]                                     = "rbxassetid://10709799818",
	["lucide-clock-12"]                                     = "rbxassetid://10709799962",
	["lucide-clock-2"]                                      = "rbxassetid://10709803876",
	["lucide-clock-3"]                                      = "rbxassetid://10709803989",
	["lucide-clock-4"]                                      = "rbxassetid://10709804164",
	["lucide-clock-5"]                                      = "rbxassetid://10709804291",
	["lucide-clock-6"]                                      = "rbxassetid://10709804435",
	["lucide-clock-7"]                                      = "rbxassetid://10709804599",
	["lucide-clock-8"]                                      = "rbxassetid://10709804784",
	["lucide-clock-9"]                                      = "rbxassetid://10709804996",
	["lucide-cloud"]                                        = "rbxassetid://10709806740",
	["lucide-cloud-cog"]                                    = "rbxassetid://10709805262",
	["lucide-cloud-drizzle"]                                = "rbxassetid://10709805371",
	["lucide-cloud-fog"]                                    = "rbxassetid://10709805477",
	["lucide-cloud-hail"]                                   = "rbxassetid://10709805596",
	["lucide-cloud-lightning"]                              = "rbxassetid://10709805727",
	["lucide-cloud-moon"]                                   = "rbxassetid://10709805942",
	["lucide-cloud-moon-rain"]                              = "rbxassetid://10709805838",
	["lucide-cloud-off"]                                    = "rbxassetid://10709806060",
	["lucide-cloud-rain"]                                   = "rbxassetid://10709806277",
	["lucide-cloud-rain-wind"]                              = "rbxassetid://10709806166",
	["lucide-cloud-snow"]                                   = "rbxassetid://10709806374",
	["lucide-cloud-sun"]                                    = "rbxassetid://10709806631",
	["lucide-cloud-sun-rain"]                               = "rbxassetid://10709806475",
	["lucide-cloudy"]                                       = "rbxassetid://10709806859",
	["lucide-clover"]                                       = "rbxassetid://10709806995",
	["lucide-code"]                                         = "rbxassetid://10709810463",
	["lucide-code-2"]                                       = "rbxassetid://10709807111",
	["lucide-codepen"]                                      = "rbxassetid://10709810534",
	["lucide-codesandbox"]                                  = "rbxassetid://10709810676",
	["lucide-coffee"]                                       = "rbxassetid://10709810814",
	["lucide-cog"]                                          = "rbxassetid://10709810948",
	["lucide-coins"]                                        = "rbxassetid://10709811110",
	["lucide-columns"]                                      = "rbxassetid://10709811261",
	["lucide-command"]                                      = "rbxassetid://10709811365",
	["lucide-compass"]                                      = "rbxassetid://10709811445",
	["lucide-component"]                                    = "rbxassetid://10709811595",
	["lucide-concierge-bell"]                               = "rbxassetid://10709811706",
	["lucide-connection"]                                   = "rbxassetid://10747361219",
	["lucide-contact"]                                      = "rbxassetid://10709811834",
	["lucide-contrast"]                                     = "rbxassetid://10709811939",
	["lucide-cookie"]                                       = "rbxassetid://10709812067",
	["lucide-copy"]                                         = "rbxassetid://10709812159",
	["lucide-copyleft"]                                     = "rbxassetid://10709812251",
	["lucide-copyright"]                                    = "rbxassetid://10709812311",
	["lucide-corner-down-left"]                             = "rbxassetid://10709812396",
	["lucide-corner-down-right"]                            = "rbxassetid://10709812485",
	["lucide-corner-left-down"]                             = "rbxassetid://10709812632",
	["lucide-corner-left-up"]                               = "rbxassetid://10709812784",
	["lucide-corner-right-down"]                            = "rbxassetid://10709812939",
	["lucide-corner-right-up"]                              = "rbxassetid://10709813094",
	["lucide-corner-up-left"]                               = "rbxassetid://10709813185",
	["lucide-corner-up-right"]                              = "rbxassetid://10709813281",
	["lucide-cpu"]                                          = "rbxassetid://10709813383",
	["lucide-croissant"]                                    = "rbxassetid://10709818125",
	["lucide-crop"]                                         = "rbxassetid://10709818245",
	["lucide-cross"]                                        = "rbxassetid://10709818399",
	["lucide-crosshair"]                                    = "rbxassetid://10709818534",
	["lucide-crown"]                                        = "rbxassetid://10709818626",
	["lucide-cup-soda"]                                     = "rbxassetid://10709818763",
	["lucide-curly-braces"]                                 = "rbxassetid://10709818847",
	["lucide-currency"]                                     = "rbxassetid://10709818931",
	["lucide-database"]                                     = "rbxassetid://10709818996",
	["lucide-delete"]                                       = "rbxassetid://10709819059",
	["lucide-diamond"]                                      = "rbxassetid://10709819149",
	["lucide-dice-1"]                                       = "rbxassetid://10709819266",
	["lucide-dice-2"]                                       = "rbxassetid://10709819361",
	["lucide-dice-3"]                                       = "rbxassetid://10709819508",
	["lucide-dice-4"]                                       = "rbxassetid://10709819670",
	["lucide-dice-5"]                                       = "rbxassetid://10709819801",
	["lucide-dice-6"]                                       = "rbxassetid://10709819896",
	["lucide-dices"]                                        = "rbxassetid://10723343321",
	["lucide-diff"]                                         = "rbxassetid://10723343416",
	["lucide-disc"]                                         = "rbxassetid://10723343537",
	["lucide-divide"]                                       = "rbxassetid://10723343805",
	["lucide-divide-circle"]                                = "rbxassetid://10723343636",
	["lucide-divide-square"]                                = "rbxassetid://10723343737",
	["lucide-dollar-sign"]                                  = "rbxassetid://10723343958",
	["lucide-download"]                                     = "rbxassetid://10723344270",
	["lucide-download-cloud"]                               = "rbxassetid://10723344088",
	["lucide-droplet"]                                      = "rbxassetid://10723344432",
	["lucide-droplets"]                                     = "rbxassetid://10734883356",
	["lucide-drumstick"]                                    = "rbxassetid://10723344737",
	["lucide-edit"]                                         = "rbxassetid://10734883598",
	["lucide-edit-2"]                                       = "rbxassetid://10723344885",
	["lucide-edit-3"]                                       = "rbxassetid://10723345088",
	["lucide-egg"]                                          = "rbxassetid://10723345518",
	["lucide-egg-fried"]                                    = "rbxassetid://10723345347",
	["lucide-electricity"]                                  = "rbxassetid://10723345749",
	["lucide-electricity-off"]                              = "rbxassetid://10723345643",
	["lucide-equal"]                                        = "rbxassetid://10723345990",
	["lucide-equal-not"]                                    = "rbxassetid://10723345866",
	["lucide-eraser"]                                       = "rbxassetid://10723346158",
	["lucide-euro"]                                         = "rbxassetid://10723346372",
	["lucide-expand"]                                       = "rbxassetid://10723346553",
	["lucide-external-link"]                                = "rbxassetid://10723346684",
	["lucide-eye"]                                          = "rbxassetid://10723346959",
	["lucide-eye-off"]                                      = "rbxassetid://10723346871",
	["lucide-factory"]                                      = "rbxassetid://10723347051",
	["lucide-fan"]                                          = "rbxassetid://10723354359",
	["lucide-fast-forward"]                                 = "rbxassetid://10723354521",
	["lucide-feather"]                                      = "rbxassetid://10723354671",
	["lucide-figma"]                                        = "rbxassetid://10723354801",
	["lucide-file"]                                         = "rbxassetid://10723374641",
	["lucide-file-archive"]                                 = "rbxassetid://10723354921",
	["lucide-file-audio"]                                   = "rbxassetid://10723355148",
	["lucide-file-audio-2"]                                 = "rbxassetid://10723355026",
	["lucide-file-axis-3d"]                                 = "rbxassetid://10723355272",
	["lucide-file-badge"]                                   = "rbxassetid://10723355622",
	["lucide-file-badge-2"]                                 = "rbxassetid://10723355451",
	["lucide-file-bar-chart"]                               = "rbxassetid://10723355887",
	["lucide-file-bar-chart-2"]                             = "rbxassetid://10723355746",
	["lucide-file-box"]                                     = "rbxassetid://10723355989",
	["lucide-file-check"]                                   = "rbxassetid://10723356210",
	["lucide-file-check-2"]                                 = "rbxassetid://10723356100",
	["lucide-file-clock"]                                   = "rbxassetid://10723356329",
	["lucide-file-code"]                                    = "rbxassetid://10723356507",
	["lucide-file-cog"]                                     = "rbxassetid://10723356830",
	["lucide-file-cog-2"]                                   = "rbxassetid://10723356676",
	["lucide-file-diff"]                                    = "rbxassetid://10723357039",
	["lucide-file-digit"]                                   = "rbxassetid://10723357151",
	["lucide-file-down"]                                    = "rbxassetid://10723357322",
	["lucide-file-edit"]                                    = "rbxassetid://10723357495",
	["lucide-file-heart"]                                   = "rbxassetid://10723357637",
	["lucide-file-image"]                                   = "rbxassetid://10723357790",
	["lucide-file-input"]                                   = "rbxassetid://10723357933",
	["lucide-file-json"]                                    = "rbxassetid://10723364435",
	["lucide-file-json-2"]                                  = "rbxassetid://10723364361",
	["lucide-file-key"]                                     = "rbxassetid://10723364605",
	["lucide-file-key-2"]                                   = "rbxassetid://10723364515",
	["lucide-file-line-chart"]                              = "rbxassetid://10723364725",
	["lucide-file-lock"]                                    = "rbxassetid://10723364957",
	["lucide-file-lock-2"]                                  = "rbxassetid://10723364861",
	["lucide-file-minus"]                                   = "rbxassetid://10723365254",
	["lucide-file-minus-2"]                                 = "rbxassetid://10723365086",
	["lucide-file-output"]                                  = "rbxassetid://10723365457",
	["lucide-file-pie-chart"]                               = "rbxassetid://10723365598",
	["lucide-file-plus"]                                    = "rbxassetid://10723365877",
	["lucide-file-plus-2"]                                  = "rbxassetid://10723365766",
	["lucide-file-question"]                                = "rbxassetid://10723365987",
	["lucide-file-scan"]                                    = "rbxassetid://10723366167",
	["lucide-file-search"]                                  = "rbxassetid://10723366550",
	["lucide-file-search-2"]                                = "rbxassetid://10723366340",
	["lucide-file-signature"]                               = "rbxassetid://10723366741",
	["lucide-file-spreadsheet"]                             = "rbxassetid://10723366962",
	["lucide-file-symlink"]                                 = "rbxassetid://10723367098",
	["lucide-file-terminal"]                                = "rbxassetid://10723367244",
	["lucide-file-text"]                                    = "rbxassetid://10723367380",
	["lucide-file-type"]                                    = "rbxassetid://10723367606",
	["lucide-file-type-2"]                                  = "rbxassetid://10723367509",
	["lucide-file-up"]                                      = "rbxassetid://10723367734",
	["lucide-file-video"]                                   = "rbxassetid://10723373884",
	["lucide-file-video-2"]                                 = "rbxassetid://10723367834",
	["lucide-file-volume"]                                  = "rbxassetid://10723374172",
	["lucide-file-volume-2"]                                = "rbxassetid://10723374030",
	["lucide-file-warning"]                                 = "rbxassetid://10723374276",
	["lucide-file-x"]                                       = "rbxassetid://10723374544",
	["lucide-file-x-2"]                                     = "rbxassetid://10723374378",
	["lucide-files"]                                        = "rbxassetid://10723374759",
	["lucide-film"]                                         = "rbxassetid://10723374981",
	["lucide-filter"]                                       = "rbxassetid://10723375128",
	["lucide-fingerprint"]                                  = "rbxassetid://10723375250",
	["lucide-flag"]                                         = "rbxassetid://10723375890",
	["lucide-flag-off"]                                     = "rbxassetid://10723375443",
	["lucide-flag-triangle-left"]                           = "rbxassetid://10723375608",
	["lucide-flag-triangle-right"]                          = "rbxassetid://10723375727",
	["lucide-flame"]                                        = "rbxassetid://10723376114",
	["lucide-flashlight"]                                   = "rbxassetid://10723376471",
	["lucide-flashlight-off"]                               = "rbxassetid://10723376365",
	["lucide-flask-conical"]                                = "rbxassetid://10734883986",
	["lucide-flask-round"]                                  = "rbxassetid://10723376614",
	["lucide-flip-horizontal"]                              = "rbxassetid://10723376884",
	["lucide-flip-horizontal-2"]                            = "rbxassetid://10723376745",
	["lucide-flip-vertical"]                                = "rbxassetid://10723377138",
	["lucide-flip-vertical-2"]                              = "rbxassetid://10723377026",
	["lucide-flower"]                                       = "rbxassetid://10747830374",
	["lucide-flower-2"]                                     = "rbxassetid://10723377305",
	["lucide-focus"]                                        = "rbxassetid://10723377537",
	["lucide-folder"]                                       = "rbxassetid://10723387563",
	["lucide-folder-archive"]                               = "rbxassetid://10723384478",
	["lucide-folder-check"]                                 = "rbxassetid://10723384605",
	["lucide-folder-clock"]                                 = "rbxassetid://10723384731",
	["lucide-folder-closed"]                                = "rbxassetid://10723384893",
	["lucide-folder-cog"]                                   = "rbxassetid://10723385213",
	["lucide-folder-cog-2"]                                 = "rbxassetid://10723385036",
	["lucide-folder-down"]                                  = "rbxassetid://10723385338",
	["lucide-folder-edit"]                                  = "rbxassetid://10723385445",
	["lucide-folder-heart"]                                 = "rbxassetid://10723385545",
	["lucide-folder-input"]                                 = "rbxassetid://10723385721",
	["lucide-folder-key"]                                   = "rbxassetid://10723385848",
	["lucide-folder-lock"]                                  = "rbxassetid://10723386005",
	["lucide-folder-minus"]                                 = "rbxassetid://10723386127",
	["lucide-folder-open"]                                  = "rbxassetid://10723386277",
	["lucide-folder-output"]                                = "rbxassetid://10723386386",
	["lucide-folder-plus"]                                  = "rbxassetid://10723386531",
	["lucide-folder-search"]                                = "rbxassetid://10723386787",
	["lucide-folder-search-2"]                              = "rbxassetid://10723386674",
	["lucide-folder-symlink"]                               = "rbxassetid://10723386930",
	["lucide-folder-tree"]                                  = "rbxassetid://10723387085",
	["lucide-folder-up"]                                    = "rbxassetid://10723387265",
	["lucide-folder-x"]                                     = "rbxassetid://10723387448",
	["lucide-folders"]                                      = "rbxassetid://10723387721",
	["lucide-form-input"]                                   = "rbxassetid://10723387841",
	["lucide-forward"]                                      = "rbxassetid://10723388016",
	["lucide-frame"]                                        = "rbxassetid://10723394389",
	["lucide-framer"]                                       = "rbxassetid://10723394565",
	["lucide-frown"]                                        = "rbxassetid://10723394681",
	["lucide-fuel"]                                         = "rbxassetid://10723394846",
	["lucide-function-square"]                              = "rbxassetid://10723395041",
	["lucide-gamepad"]                                      = "rbxassetid://10723395457",
	["lucide-gamepad-2"]                                    = "rbxassetid://10723395215",
	["lucide-gauge"]                                        = "rbxassetid://10723395708",
	["lucide-gavel"]                                        = "rbxassetid://10723395896",
	["lucide-gem"]                                          = "rbxassetid://10723396000",
	["lucide-ghost"]                                        = "rbxassetid://10723396107",
	["lucide-gift"]                                         = "rbxassetid://10723396402",
	["lucide-gift-card"]                                    = "rbxassetid://10723396225",
	["lucide-git-branch"]                                   = "rbxassetid://10723396676",
	["lucide-git-branch-plus"]                              = "rbxassetid://10723396542",
	["lucide-git-commit"]                                   = "rbxassetid://10723396812",
	["lucide-git-compare"]                                  = "rbxassetid://10723396954",
	["lucide-git-fork"]                                     = "rbxassetid://10723397049",
	["lucide-git-merge"]                                    = "rbxassetid://10723397165",
	["lucide-git-pull-request"]                             = "rbxassetid://10723397431",
	["lucide-git-pull-request-closed"]                      = "rbxassetid://10723397268",
	["lucide-git-pull-request-draft"]                       = "rbxassetid://10734884302",
	["lucide-glass"]                                        = "rbxassetid://10723397788",
	["lucide-glass-2"]                                      = "rbxassetid://10723397529",
	["lucide-glass-water"]                                  = "rbxassetid://10723397678",
	["lucide-glasses"]                                      = "rbxassetid://10723397895",
	["lucide-globe"]                                        = "rbxassetid://10723404337",
	["lucide-globe-2"]                                      = "rbxassetid://10723398002",
	["lucide-grab"]                                         = "rbxassetid://10723404472",
	["lucide-graduation-cap"]                               = "rbxassetid://10723404691",
	["lucide-grape"]                                        = "rbxassetid://10723404822",
	["lucide-grid"]                                         = "rbxassetid://10723404936",
	["lucide-grip-horizontal"]                              = "rbxassetid://10723405089",
	["lucide-grip-vertical"]                                = "rbxassetid://10723405236",
	["lucide-hammer"]                                       = "rbxassetid://10723405360",
	["lucide-hand"]                                         = "rbxassetid://10723405649",
	["lucide-hand-metal"]                                   = "rbxassetid://10723405508",
	["lucide-hard-drive"]                                   = "rbxassetid://10723405749",
	["lucide-hard-hat"]                                     = "rbxassetid://10723405859",
	["lucide-hash"]                                         = "rbxassetid://10723405975",
	["lucide-haze"]                                         = "rbxassetid://10723406078",
	["lucide-headphones"]                                   = "rbxassetid://10723406165",
	["lucide-heart"]                                        = "rbxassetid://10723406885",
	["lucide-heart-crack"]                                  = "rbxassetid://10723406299",
	["lucide-heart-handshake"]                              = "rbxassetid://10723406480",
	["lucide-heart-off"]                                    = "rbxassetid://10723406662",
	["lucide-heart-pulse"]                                  = "rbxassetid://10723406795",
	["lucide-help-circle"]                                  = "rbxassetid://10723406988",
	["lucide-hexagon"]                                      = "rbxassetid://10723407092",
	["lucide-highlighter"]                                  = "rbxassetid://10723407192",
	["lucide-history"]                                      = "rbxassetid://10723407335",
	["lucide-home"]                                         = "rbxassetid://10723407389",
	["lucide-hourglass"]                                    = "rbxassetid://10723407498",
	["lucide-ice-cream"]                                    = "rbxassetid://10723414308",
	["lucide-image"]                                        = "rbxassetid://10723415040",
	["lucide-image-minus"]                                  = "rbxassetid://10723414487",
	["lucide-image-off"]                                    = "rbxassetid://10723414677",
	["lucide-image-plus"]                                   = "rbxassetid://10723414827",
	["lucide-import"]                                       = "rbxassetid://10723415205",
	["lucide-inbox"]                                        = "rbxassetid://10723415335",
	["lucide-indent"]                                       = "rbxassetid://10723415494",
	["lucide-indian-rupee"]                                 = "rbxassetid://10723415642",
	["lucide-infinity"]                                     = "rbxassetid://10723415766",
	["lucide-info"]                                         = "rbxassetid://10723415903",
	["lucide-inspect"]                                      = "rbxassetid://10723416057",
	["lucide-italic"]                                       = "rbxassetid://10723416195",
	["lucide-japanese-yen"]                                 = "rbxassetid://10723416363",
	["lucide-joystick"]                                     = "rbxassetid://10723416527",
	["lucide-key"]                                          = "rbxassetid://10723416652",
	["lucide-keyboard"]                                     = "rbxassetid://10723416765",
	["lucide-lamp"]                                         = "rbxassetid://10723417513",
	["lucide-lamp-ceiling"]                                 = "rbxassetid://10723416922",
	["lucide-lamp-desk"]                                    = "rbxassetid://10723417016",
	["lucide-lamp-floor"]                                   = "rbxassetid://10723417131",
	["lucide-lamp-wall-down"]                               = "rbxassetid://10723417240",
	["lucide-lamp-wall-up"]                                 = "rbxassetid://10723417356",
	["lucide-landmark"]                                     = "rbxassetid://10723417608",
	["lucide-languages"]                                    = "rbxassetid://10723417703",
	["lucide-laptop"]                                       = "rbxassetid://10723423881",
	["lucide-laptop-2"]                                     = "rbxassetid://10723417797",
	["lucide-lasso"]                                        = "rbxassetid://10723424235",
	["lucide-lasso-select"]                                 = "rbxassetid://10723424058",
	["lucide-laugh"]                                        = "rbxassetid://10723424372",
	["lucide-layers"]                                       = "rbxassetid://10723424505",
	["lucide-layout"]                                       = "rbxassetid://10723425376",
	["lucide-layout-dashboard"]                             = "rbxassetid://10723424646",
	["lucide-layout-grid"]                                  = "rbxassetid://10723424838",
	["lucide-layout-list"]                                  = "rbxassetid://10723424963",
	["lucide-layout-template"]                              = "rbxassetid://10723425187",
	["lucide-leaf"]                                         = "rbxassetid://10723425539",
	["lucide-library"]                                      = "rbxassetid://10723425615",
	["lucide-life-buoy"]                                    = "rbxassetid://10723425685",
	["lucide-lightbulb"]                                    = "rbxassetid://10723425852",
	["lucide-lightbulb-off"]                                = "rbxassetid://10723425762",
	["lucide-line-chart"]                                   = "rbxassetid://10723426393",
	["lucide-link"]                                         = "rbxassetid://10723426722",
	["lucide-link-2"]                                       = "rbxassetid://10723426595",
	["lucide-link-2-off"]                                   = "rbxassetid://10723426513",
	["lucide-list"]                                         = "rbxassetid://10723433811",
	["lucide-list-checks"]                                  = "rbxassetid://10734884548",
	["lucide-list-end"]                                     = "rbxassetid://10723426886",
	["lucide-list-minus"]                                   = "rbxassetid://10723426986",
	["lucide-list-music"]                                   = "rbxassetid://10723427081",
	["lucide-list-ordered"]                                 = "rbxassetid://10723427199",
	["lucide-list-plus"]                                    = "rbxassetid://10723427334",
	["lucide-list-start"]                                   = "rbxassetid://10723427494",
	["lucide-list-video"]                                   = "rbxassetid://10723427619",
	["lucide-list-x"]                                       = "rbxassetid://10723433655",
	["lucide-loader"]                                       = "rbxassetid://10723434070",
	["lucide-loader-2"]                                     = "rbxassetid://10723433935",
	["lucide-locate"]                                       = "rbxassetid://10723434557",
	["lucide-locate-fixed"]                                 = "rbxassetid://10723434236",
	["lucide-locate-off"]                                   = "rbxassetid://10723434379",
	["lucide-lock"]                                         = "rbxassetid://10723434711",
	["lucide-log-in"]                                       = "rbxassetid://10723434830",
	["lucide-log-out"]                                      = "rbxassetid://10723434906",
	["lucide-luggage"]                                      = "rbxassetid://10723434993",
	["lucide-magnet"]                                       = "rbxassetid://10723435069",
	["lucide-mail"]                                         = "rbxassetid://10734885430",
	["lucide-mail-check"]                                   = "rbxassetid://10723435182",
	["lucide-mail-minus"]                                   = "rbxassetid://10723435261",
	["lucide-mail-open"]                                    = "rbxassetid://10723435342",
	["lucide-mail-plus"]                                    = "rbxassetid://10723435443",
	["lucide-mail-question"]                                = "rbxassetid://10723435515",
	["lucide-mail-search"]                                  = "rbxassetid://10734884739",
	["lucide-mail-warning"]                                 = "rbxassetid://10734885015",
	["lucide-mail-x"]                                       = "rbxassetid://10734885247",
	["lucide-mails"]                                        = "rbxassetid://10734885614",
	["lucide-map"]                                          = "rbxassetid://10734886202",
	["lucide-map-pin"]                                      = "rbxassetid://10734886004",
	["lucide-map-pin-off"]                                  = "rbxassetid://10734885803",
	["lucide-maximize"]                                     = "rbxassetid://10734886735",
	["lucide-maximize-2"]                                   = "rbxassetid://10734886496",
	["lucide-medal"]                                        = "rbxassetid://10734887072",
	["lucide-megaphone"]                                    = "rbxassetid://10734887454",
	["lucide-megaphone-off"]                                = "rbxassetid://10734887311",
	["lucide-meh"]                                          = "rbxassetid://10734887603",
	["lucide-menu"]                                         = "rbxassetid://10734887784",
	["lucide-message-circle"]                               = "rbxassetid://10734888000",
	["lucide-message-square"]                               = "rbxassetid://10734888228",
	["lucide-mic"]                                          = "rbxassetid://10734888864",
	["lucide-mic-2"]                                        = "rbxassetid://10734888430",
	["lucide-mic-off"]                                      = "rbxassetid://10734888646",
	["lucide-microscope"]                                   = "rbxassetid://10734889106",
	["lucide-microwave"]                                    = "rbxassetid://10734895076",
	["lucide-milestone"]                                    = "rbxassetid://10734895310",
	["lucide-minimize"]                                     = "rbxassetid://10734895698",
	["lucide-minimize-2"]                                   = "rbxassetid://10734895530",
	["lucide-minus"]                                        = "rbxassetid://10734896206",
	["lucide-minus-circle"]                                 = "rbxassetid://10734895856",
	["lucide-minus-square"]                                 = "rbxassetid://10734896029",
	["lucide-monitor"]                                      = "rbxassetid://10734896881",
	["lucide-monitor-off"]                                  = "rbxassetid://10734896360",
	["lucide-monitor-speaker"]                              = "rbxassetid://10734896512",
	["lucide-moon"]                                         = "rbxassetid://10734897102",
	["lucide-more-horizontal"]                              = "rbxassetid://10734897250",
	["lucide-more-vertical"]                                = "rbxassetid://10734897387",
	["lucide-mountain"]                                     = "rbxassetid://10734897956",
	["lucide-mountain-snow"]                                = "rbxassetid://10734897665",
	["lucide-mouse"]                                        = "rbxassetid://10734898592",
	["lucide-mouse-pointer"]                                = "rbxassetid://10734898476",
	["lucide-mouse-pointer-2"]                              = "rbxassetid://10734898194",
	["lucide-mouse-pointer-click"]                          = "rbxassetid://10734898355",
	["lucide-move"]                                         = "rbxassetid://10734900011",
	["lucide-move-3d"]                                      = "rbxassetid://10734898756",
	["lucide-move-diagonal"]                                = "rbxassetid://10734899164",
	["lucide-move-diagonal-2"]                              = "rbxassetid://10734898934",
	["lucide-move-horizontal"]                              = "rbxassetid://10734899414",
	["lucide-move-vertical"]                                = "rbxassetid://10734899821",
	["lucide-music"]                                        = "rbxassetid://10734905958",
	["lucide-music-2"]                                      = "rbxassetid://10734900215",
	["lucide-music-3"]                                      = "rbxassetid://10734905665",
	["lucide-music-4"]                                      = "rbxassetid://10734905823",
	["lucide-navigation"]                                   = "rbxassetid://10734906744",
	["lucide-navigation-2"]                                 = "rbxassetid://10734906332",
	["lucide-navigation-2-off"]                             = "rbxassetid://10734906144",
	["lucide-navigation-off"]                               = "rbxassetid://10734906580",
	["lucide-network"]                                      = "rbxassetid://10734906975",
	["lucide-newspaper"]                                    = "rbxassetid://10734907168",
	["lucide-octagon"]                                      = "rbxassetid://10734907361",
	["lucide-option"]                                       = "rbxassetid://10734907649",
	["lucide-outdent"]                                      = "rbxassetid://10734907933",
	["lucide-package"]                                      = "rbxassetid://10734909540",
	["lucide-package-2"]                                    = "rbxassetid://10734908151",
	["lucide-package-check"]                                = "rbxassetid://10734908384",
	["lucide-package-minus"]                                = "rbxassetid://10734908626",
	["lucide-package-open"]                                 = "rbxassetid://10734908793",
	["lucide-package-plus"]                                 = "rbxassetid://10734909016",
	["lucide-package-search"]                               = "rbxassetid://10734909196",
	["lucide-package-x"]                                    = "rbxassetid://10734909375",
	["lucide-paint-bucket"]                                 = "rbxassetid://10734909847",
	["lucide-paintbrush"]                                   = "rbxassetid://10734910187",
	["lucide-paintbrush-2"]                                 = "rbxassetid://10734910030",
	["lucide-palette"]                                      = "rbxassetid://10734910430",
	["lucide-palmtree"]                                     = "rbxassetid://10734910680",
	["lucide-paperclip"]                                    = "rbxassetid://10734910927",
	["lucide-party-popper"]                                 = "rbxassetid://10734918735",
	["lucide-pause"]                                        = "rbxassetid://10734919336",
	["lucide-pause-circle"]                                 = "rbxassetid://10735024209",
	["lucide-pause-octagon"]                                = "rbxassetid://10734919143",
	["lucide-pen-tool"]                                     = "rbxassetid://10734919503",
	["lucide-pencil"]                                       = "rbxassetid://10734919691",
	["lucide-percent"]                                      = "rbxassetid://10734919919",
	["lucide-person-standing"]                              = "rbxassetid://10734920149",
	["lucide-phone"]                                        = "rbxassetid://10734921524",
	["lucide-phone-call"]                                   = "rbxassetid://10734920305",
	["lucide-phone-forwarded"]                              = "rbxassetid://10734920508",
	["lucide-phone-incoming"]                               = "rbxassetid://10734920694",
	["lucide-phone-missed"]                                 = "rbxassetid://10734920845",
	["lucide-phone-off"]                                    = "rbxassetid://10734921077",
	["lucide-phone-outgoing"]                               = "rbxassetid://10734921288",
	["lucide-pie-chart"]                                    = "rbxassetid://10734921727",
	["lucide-piggy-bank"]                                   = "rbxassetid://10734921935",
	["lucide-pin"]                                          = "rbxassetid://10734922324",
	["lucide-pin-off"]                                      = "rbxassetid://10734922180",
	["lucide-pipette"]                                      = "rbxassetid://10734922497",
	["lucide-pizza"]                                        = "rbxassetid://10734922774",
	["lucide-plane"]                                        = "rbxassetid://10734922971",
	["lucide-play"]                                         = "rbxassetid://10734923549",
	["lucide-play-circle"]                                  = "rbxassetid://10734923214",
	["lucide-plus"]                                         = "rbxassetid://10734924532",
	["lucide-plus-circle"]                                  = "rbxassetid://10734923868",
	["lucide-plus-square"]                                  = "rbxassetid://10734924219",
	["lucide-podcast"]                                      = "rbxassetid://10734929553",
	["lucide-pointer"]                                      = "rbxassetid://10734929723",
	["lucide-pound-sterling"]                               = "rbxassetid://10734929981",
	["lucide-power"]                                        = "rbxassetid://10734930466",
	["lucide-power-off"]                                    = "rbxassetid://10734930257",
	["lucide-printer"]                                      = "rbxassetid://10734930632",
	["lucide-puzzle"]                                       = "rbxassetid://10734930886",
	["lucide-quote"]                                        = "rbxassetid://10734931234",
	["lucide-radio"]                                        = "rbxassetid://10734931596",
	["lucide-radio-receiver"]                               = "rbxassetid://10734931402",
	["lucide-rectangle-horizontal"]                         = "rbxassetid://10734931777",
	["lucide-rectangle-vertical"]                           = "rbxassetid://10734932081",
	["lucide-recycle"]                                      = "rbxassetid://10734932295",
	["lucide-redo"]                                         = "rbxassetid://10734932822",
	["lucide-redo-2"]                                       = "rbxassetid://10734932586",
	["lucide-refresh-ccw"]                                  = "rbxassetid://10734933056",
	["lucide-refresh-cw"]                                   = "rbxassetid://10734933222",
	["lucide-refrigerator"]                                 = "rbxassetid://10734933465",
	["lucide-regex"]                                        = "rbxassetid://10734933655",
	["lucide-repeat"]                                       = "rbxassetid://10734933966",
	["lucide-repeat-1"]                                     = "rbxassetid://10734933826",
	["lucide-reply"]                                        = "rbxassetid://10734934252",
	["lucide-reply-all"]                                    = "rbxassetid://10734934132",
	["lucide-rewind"]                                       = "rbxassetid://10734934347",
	["lucide-rocket"]                                       = "rbxassetid://10734934585",
	["lucide-rocking-chair"]                                = "rbxassetid://10734939942",
	["lucide-rotate-3d"]                                    = "rbxassetid://10734940107",
	["lucide-rotate-ccw"]                                   = "rbxassetid://10734940376",
	["lucide-rotate-cw"]                                    = "rbxassetid://10734940654",
	["lucide-rss"]                                          = "rbxassetid://10734940825",
	["lucide-ruler"]                                        = "rbxassetid://10734941018",
	["lucide-russian-ruble"]                                = "rbxassetid://10734941199",
	["lucide-sailboat"]                                     = "rbxassetid://10734941354",
	["lucide-save"]                                         = "rbxassetid://10734941499",
	["lucide-scale"]                                        = "rbxassetid://10734941912",
	["lucide-scale-3d"]                                     = "rbxassetid://10734941739",
	["lucide-scaling"]                                      = "rbxassetid://10734942072",
	["lucide-scan"]                                         = "rbxassetid://10734942565",
	["lucide-scan-face"]                                    = "rbxassetid://10734942198",
	["lucide-scan-line"]                                    = "rbxassetid://10734942351",
	["lucide-scissors"]                                     = "rbxassetid://10734942778",
	["lucide-screen-share"]                                 = "rbxassetid://10734943193",
	["lucide-screen-share-off"]                             = "rbxassetid://10734942967",
	["lucide-scroll"]                                       = "rbxassetid://10734943448",
	["lucide-search"]                                       = "rbxassetid://10734943674",
	["lucide-send"]                                         = "rbxassetid://10734943902",
	["lucide-separator-horizontal"]                         = "rbxassetid://10734944115",
	["lucide-separator-vertical"]                           = "rbxassetid://10734944326",
	["lucide-server"]                                       = "rbxassetid://10734949856",
	["lucide-server-cog"]                                   = "rbxassetid://10734944444",
	["lucide-server-crash"]                                 = "rbxassetid://10734944554",
	["lucide-server-off"]                                   = "rbxassetid://10734944668",
	["lucide-settings"]                                     = "rbxassetid://10734950309",
	["lucide-settings-2"]                                   = "rbxassetid://10734950020",
	["lucide-share"]                                        = "rbxassetid://10734950813",
	["lucide-share-2"]                                      = "rbxassetid://10734950553",
	["lucide-sheet"]                                        = "rbxassetid://10734951038",
	["lucide-shield"]                                       = "rbxassetid://10734951847",
	["lucide-shield-alert"]                                 = "rbxassetid://10734951173",
	["lucide-shield-check"]                                 = "rbxassetid://10734951367",
	["lucide-shield-close"]                                 = "rbxassetid://10734951535",
	["lucide-shield-off"]                                   = "rbxassetid://10734951684",
	["lucide-shirt"]                                        = "rbxassetid://10734952036",
	["lucide-shopping-bag"]                                 = "rbxassetid://10734952273",
	["lucide-shopping-cart"]                                = "rbxassetid://10734952479",
	["lucide-shovel"]                                       = "rbxassetid://10734952773",
	["lucide-shower-head"]                                  = "rbxassetid://10734952942",
	["lucide-shrink"]                                       = "rbxassetid://10734953073",
	["lucide-shrub"]                                        = "rbxassetid://10734953241",
	["lucide-shuffle"]                                      = "rbxassetid://10734953451",
	["lucide-sidebar"]                                      = "rbxassetid://10734954301",
	["lucide-sidebar-close"]                                = "rbxassetid://10734953715",
	["lucide-sidebar-open"]                                 = "rbxassetid://10734954000",
	["lucide-sigma"]                                        = "rbxassetid://10734954538",
	["lucide-signal"]                                       = "rbxassetid://10734961133",
	["lucide-signal-high"]                                  = "rbxassetid://10734954807",
	["lucide-signal-low"]                                   = "rbxassetid://10734955080",
	["lucide-signal-medium"]                                = "rbxassetid://10734955336",
	["lucide-signal-zero"]                                  = "rbxassetid://10734960878",
	["lucide-siren"]                                        = "rbxassetid://10734961284",
	["lucide-skip-back"]                                    = "rbxassetid://10734961526",
	["lucide-skip-forward"]                                 = "rbxassetid://10734961809",
	["lucide-skull"]                                        = "rbxassetid://10734962068",
	["lucide-slack"]                                        = "rbxassetid://10734962339",
	["lucide-slash"]                                        = "rbxassetid://10734962600",
	["lucide-slice"]                                        = "rbxassetid://10734963024",
	["lucide-sliders"]                                      = "rbxassetid://10734963400",
	["lucide-sliders-horizontal"]                           = "rbxassetid://10734963191",
	["lucide-smartphone"]                                   = "rbxassetid://10734963940",
	["lucide-smartphone-charging"]                          = "rbxassetid://10734963671",
	["lucide-smile"]                                        = "rbxassetid://10734964441",
	["lucide-smile-plus"]                                   = "rbxassetid://10734964188",
	["lucide-snowflake"]                                    = "rbxassetid://10734964600",
	["lucide-sofa"]                                         = "rbxassetid://10734964852",
	["lucide-sort-asc"]                                     = "rbxassetid://10734965115",
	["lucide-sort-desc"]                                    = "rbxassetid://10734965287",
	["lucide-speaker"]                                      = "rbxassetid://10734965419",
	["lucide-sprout"]                                       = "rbxassetid://10734965572",
	["lucide-square"]                                       = "rbxassetid://10734965702",
	["lucide-star"]                                         = "rbxassetid://10734966248",
	["lucide-star-half"]                                    = "rbxassetid://10734965897",
	["lucide-star-off"]                                     = "rbxassetid://10734966097",
	["lucide-stethoscope"]                                  = "rbxassetid://10734966384",
	["lucide-sticker"]                                      = "rbxassetid://10734972234",
	["lucide-sticky-note"]                                  = "rbxassetid://10734972463",
	["lucide-stop-circle"]                                  = "rbxassetid://10734972621",
	["lucide-stretch-horizontal"]                           = "rbxassetid://10734972862",
	["lucide-stretch-vertical"]                             = "rbxassetid://10734973130",
	["lucide-strikethrough"]                                = "rbxassetid://10734973290",
	["lucide-subscript"]                                    = "rbxassetid://10734973457",
	["lucide-sun"]                                          = "rbxassetid://10734974297",
	["lucide-sun-dim"]                                      = "rbxassetid://10734973645",
	["lucide-sun-medium"]                                   = "rbxassetid://10734973778",
	["lucide-sun-moon"]                                     = "rbxassetid://10734973999",
	["lucide-sun-snow"]                                     = "rbxassetid://10734974130",
	["lucide-sunrise"]                                      = "rbxassetid://10734974522",
	["lucide-sunset"]                                       = "rbxassetid://10734974689",
	["lucide-superscript"]                                  = "rbxassetid://10734974850",
	["lucide-swiss-franc"]                                  = "rbxassetid://10734975024",
	["lucide-switch-camera"]                                = "rbxassetid://10734975214",
	["lucide-sword"]                                        = "rbxassetid://10734975486",
	["lucide-swords"]                                       = "rbxassetid://10734975692",
	["lucide-syringe"]                                      = "rbxassetid://10734975932",
	["lucide-table"]                                        = "rbxassetid://10734976230",
	["lucide-table-2"]                                      = "rbxassetid://10734976097",
	["lucide-tablet"]                                       = "rbxassetid://10734976394",
	["lucide-tag"]                                          = "rbxassetid://10734976528",
	["lucide-tags"]                                         = "rbxassetid://10734976739",
	["lucide-target"]                                       = "rbxassetid://10734977012",
	["lucide-tent"]                                         = "rbxassetid://10734981750",
	["lucide-terminal"]                                     = "rbxassetid://10734982144",
	["lucide-terminal-square"]                              = "rbxassetid://10734981995",
	["lucide-text-cursor"]                                  = "rbxassetid://10734982395",
	["lucide-text-cursor-input"]                            = "rbxassetid://10734982297",
	["lucide-thermometer"]                                  = "rbxassetid://10734983134",
	["lucide-thermometer-snowflake"]                        = "rbxassetid://10734982571",
	["lucide-thermometer-sun"]                              = "rbxassetid://10734982771",
	["lucide-thumbs-down"]                                  = "rbxassetid://10734983359",
	["lucide-thumbs-up"]                                    = "rbxassetid://10734983629",
	["lucide-ticket"]                                       = "rbxassetid://10734983868",
	["lucide-timer"]                                        = "rbxassetid://10734984606",
	["lucide-timer-off"]                                    = "rbxassetid://10734984138",
	["lucide-timer-reset"]                                  = "rbxassetid://10734984355",
	["lucide-toggle-left"]                                  = "rbxassetid://10734984834",
	["lucide-toggle-right"]                                 = "rbxassetid://10734985040",
	["lucide-tornado"]                                      = "rbxassetid://10734985247",
	["lucide-toy-brick"]                                    = "rbxassetid://10747361919",
	["lucide-train"]                                        = "rbxassetid://10747362105",
	["lucide-trash"]                                        = "rbxassetid://10747362393",
	["lucide-trash-2"]                                      = "rbxassetid://10747362241",
	["lucide-tree-deciduous"]                               = "rbxassetid://10747362534",
	["lucide-tree-pine"]                                    = "rbxassetid://10747362748",
	["lucide-trees"]                                        = "rbxassetid://10747363016",
	["lucide-trending-down"]                                = "rbxassetid://10747363205",
	["lucide-trending-up"]                                  = "rbxassetid://10747363465",
	["lucide-triangle"]                                     = "rbxassetid://10747363621",
	["lucide-trophy"]                                       = "rbxassetid://10747363809",
	["lucide-truck"]                                        = "rbxassetid://10747364031",
	["lucide-tv"]                                           = "rbxassetid://10747364593",
	["lucide-tv-2"]                                         = "rbxassetid://10747364302",
	["lucide-type"]                                         = "rbxassetid://10747364761",
	["lucide-umbrella"]                                     = "rbxassetid://10747364971",
	["lucide-underline"]                                    = "rbxassetid://10747365191",
	["lucide-undo"]                                         = "rbxassetid://10747365484",
	["lucide-undo-2"]                                       = "rbxassetid://10747365359",
	["lucide-unlink"]                                       = "rbxassetid://10747365771",
	["lucide-unlink-2"]                                     = "rbxassetid://10747397871",
	["lucide-unlock"]                                       = "rbxassetid://10747366027",
	["lucide-upload"]                                       = "rbxassetid://10747366434",
	["lucide-upload-cloud"]                                 = "rbxassetid://10747366266",
	["lucide-usb"]                                          = "rbxassetid://10747366606",
	["lucide-user"]                                         = "rbxassetid://10747373176",
	["lucide-user-check"]                                   = "rbxassetid://10747371901",
	["lucide-user-cog"]                                     = "rbxassetid://10747372167",
	["lucide-user-minus"]                                   = "rbxassetid://10747372346",
	["lucide-user-plus"]                                    = "rbxassetid://10747372702",
	["lucide-user-x"]                                       = "rbxassetid://10747372992",
	["lucide-users"]                                        = "rbxassetid://10747373426",
	["lucide-utensils"]                                     = "rbxassetid://10747373821",
	["lucide-utensils-crossed"]                             = "rbxassetid://10747373629",
	["lucide-venetian-mask"]                                = "rbxassetid://10747374003",
	["lucide-verified"]                                     = "rbxassetid://10747374131",
	["lucide-vibrate"]                                      = "rbxassetid://10747374489",
	["lucide-vibrate-off"]                                  = "rbxassetid://10747374269",
	["lucide-video"]                                        = "rbxassetid://10747374938",
	["lucide-video-off"]                                    = "rbxassetid://10747374721",
	["lucide-view"]                                         = "rbxassetid://10747375132",
	["lucide-voicemail"]                                    = "rbxassetid://10747375281",
	["lucide-volume"]                                       = "rbxassetid://10747376008",
	["lucide-volume-1"]                                     = "rbxassetid://10747375450",
	["lucide-volume-2"]                                     = "rbxassetid://10747375679",
	["lucide-volume-x"]                                     = "rbxassetid://10747375880",
	["lucide-wallet"]                                       = "rbxassetid://10747376205",
	["lucide-wand"]                                         = "rbxassetid://10747376565",
	["lucide-wand-2"]                                       = "rbxassetid://10747376349",
	["lucide-watch"]                                        = "rbxassetid://10747376722",
	["lucide-waves"]                                        = "rbxassetid://10747376931",
	["lucide-webcam"]                                       = "rbxassetid://10747381992",
	["lucide-wifi"]                                         = "rbxassetid://10747382504",
	["lucide-wifi-off"]                                     = "rbxassetid://10747382268",
	["lucide-wind"]                                         = "rbxassetid://10747382750",
	["lucide-wrap-text"]                                    = "rbxassetid://10747383065",
	["lucide-wrench"]                                       = "rbxassetid://10747383470",
	["lucide-x"]                                            = "rbxassetid://10747384394",
	["lucide-x-circle"]                                     = "rbxassetid://10747383819",
	["lucide-x-octagon"]                                    = "rbxassetid://10747384037",
	["lucide-x-square"]                                     = "rbxassetid://10747384217",
	["lucide-zoom-in"]                                      = "rbxassetid://10747384552",
	["lucide-zoom-out"]                                     = "rbxassetid://10747384679",
}

--[[
    GetIcon(name) - Lucide-style icon resolver (WindUI compatible).

    Lookup order (exact spec):
      1.  LucideIcons["lucide-" .. name]  ->  "eye"          resolves lucide-eye
      2.  LucideIcons[name]               ->  "lucide-home"  exact key lookup
      3.  tostring(name)                  ->  "rbxassetid://..." or any custom string
          (returns the original value so custom asset IDs always work)

    Examples:
        GetIcon("eye")                     -> "rbxassetid://10723346959"
        GetIcon("lucide-home")             -> "rbxassetid://10723407389"
        GetIcon("rbxassetid://1234567890") -> "rbxassetid://1234567890"
        GetIcon("unknown-name")            -> "unknown-name"
        GetIcon(nil)                       -> ""
--]]
local function GetIcon(name)
    if not name then return "" end
    local n = tostring(name)
    return LucideIcons["lucide-" .. n]
        or LucideIcons[n]
        or n
end

-- Public aliases
function Library:GetIcon(name)     return GetIcon(name) end
function Library:ResolveIcon(name)  return GetIcon(name) end  -- WindUI alias
-- NewRows now accepts a Theme table (T), optional track function, and optional icon (resolved asset string)
-- icon param: pass GetIcon(Args.Icon) — if nil, no icon is shown (backward compatible)
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

    -- When icon is present, Left has a horizontal UIListLayout (icon 16px + gap 8px = 24px).
    -- Text fills the remaining width: UDim2.new(1, -24, 0, 0) so labels inside get real width.
    -- Without icon: Text fills full width of Left.
    local Text = Library:Create("Frame", {
        Name                   = "Text",
        Parent                 = Left,
        BackgroundTransparency = 1,
        BorderSizePixel        = 0,
        AutomaticSize          = Enum.AutomaticSize.Y,
        Size                   = icon and UDim2.new(1, -24, 0, 0) or UDim2.new(1, 0, 0, 0),
        LayoutOrder            = 0
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

    Icon system — GetIcon(name) logic (exact order):
        1. LucideIcons["lucide-" .. name]   -- "eye"    -> "rbxassetid://10723346959"
        2. LucideIcons[name]                -- "lucide-shield" exact key
        3. tostring(name)                   -- "rbxassetid://..." passthrough

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
        Library:GetIcon("eye")              -- "rbxassetid://10723346959"
        Library:GetIcon("eye")              -- alias for GetIcon
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
        local PageIcon  = GetIcon(Args.Icon or "layers")

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
                SectionIcon = GetIcon(Args.Icon)
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
            local Title   = Args.Title
            local Desc    = Args.Desc
            local Icon    = Args.Image or Args.Icon   -- right-side decorative image (optional)
            local RowIcon = GetIcon(Args.RowIcon)     -- left-side row icon (optional)
            local Rows    = Library:NewRows(PageScrolling, Title, Desc, T, track, RowIcon)
            local Right   = Rows.Vectorize.Right
            local Left    = Rows.Vectorize.Left.Text

            -- Only create the right-side icon ImageLabel when an image is actually provided
            local resolvedIcon = Icon and GetIcon(Icon) or nil
            local IconLbl = nil
            if resolvedIcon and resolvedIcon ~= "" then
                IconLbl = Library:Create("ImageLabel", {
                    Parent                 = Right,
                    AnchorPoint            = Vector2.new(0.5, 0.5),
                    BackgroundTransparency = 1,
                    BorderSizePixel        = 0,
                    Position               = UDim2.new(0, 0.5, 0.5, 1),
                    Size                   = UDim2.new(0, 20, 0, 20),
                    Image                  = resolvedIcon,
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
            end

            local Data = { Title = Title, Desc = Desc, Icon = IconLbl, Instance = Rows }
            return setmetatable({}, {
                __newindex = function(t, k, v)
                    rawset(Data, k, v)
                    if k == "Title" then Left.Title.Text = tostring(v)
                    elseif k == "Desc"  then Left.Desc.Text = tostring(v)
                    elseif k == "Image" or k == "Icon" then
                        -- Update the right-side icon image at runtime
                        local id = v and GetIcon(v) or nil
                        if IconLbl and id and id ~= "" then IconLbl.Image = id end
                    end
                end,
                __index = Data
            })
        end

        function Page:RightLabel(Args)
            local Title     = Args.Title
            local Desc      = Args.Desc
            local RightText = Args.Right or "None"
            local RowIcon   = GetIcon(Args.Icon)   -- optional left-side row icon
            local Rows      = Library:NewRows(PageScrolling, Title, Desc, T, track, RowIcon)
            local Right     = Rows.Vectorize.Right
            local Left      = Rows.Vectorize.Left.Text

            local Lbl = Library:Create("TextLabel", {
                Name                   = "RightLbl",
                Parent                 = Right,
                BackgroundTransparency = 1,
                BorderSizePixel        = 0,
                LayoutOrder            = -1,
                Size                   = UDim2.new(0, 90, 0, 0),
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

            -- Return a proxy so the developer can update any field at runtime:
            --   local lbl = Page:RightLabel({...})
            --   lbl.Right = "New Value"   -- updates the right-side text
            --   lbl.Title = "New Title"   -- updates the row title
            local Data = { Title = Title, Desc = Desc, Right = RightText, Instance = Rows }
            return setmetatable({}, {
                __newindex = function(t, k, v)
                    rawset(Data, k, v)
                    if k == "Right" or k == "Text" then Lbl.Text = tostring(v)
                    elseif k == "Title" then Left.Title.Text = tostring(v)
                    elseif k == "Desc"  then Left.Desc.Text  = tostring(v)
                    end
                end,
                __index = Data
            })
        end

        function Page:Button(Args)
            local Title    = Args.Title
            local Desc     = Args.Desc
            local BtnText  = Args.Text or "Click"
            local Callback = Args.Callback
            local RowIcon  = GetIcon(Args.Icon)   -- optional row-level icon
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
            local btnIconId = GetIcon(Args.ButtonIcon or Args.Icon)
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

            -- Auto-size button to fit icon + label contents immediately
            Btn.AutomaticSize = Enum.AutomaticSize.X
            Btn.Size = UDim2.new(0, 0, 0, 25)

            local Click = Library:Button(Btn)
            Click.MouseButton1Click:Connect(function()
                if Library:IsDropdownOpen() then return end
                task.spawn(Library.Effect, Click, Btn)
                if Callback then pcall(Callback) end
            end)
            return Click
        end

        function Page:Toggle(Args)
            local Title    = Args.Title
            local Desc     = Args.Desc
            local Value    = Args.Value or false
            local Callback = Args.Callback or function() end
            local RowIcon  = GetIcon(Args.Icon)   -- optional row icon
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
                -- Apply state colors using current T values (safe after SetTheme)
                local targetColor = val and T.Accent or T.Text
                TitleLbl.TextColor3 = targetColor
                if val then
                    pcall(Callback, val)
                    CheckImg.Size = UDim2.new(0.85, 0, 0.85, 0)
                    Library:Tween({ v = Highlight, t = 0.5, s = "Exponential", d = "Out", g = { BackgroundTransparency = 0 } }):Play()
                    Library:Tween({ v = CheckImg,  t = 0.5, s = "Exponential", d = "Out", g = { ImageTransparency = 0 } }):Play()
                    Library:Tween({ v = CheckImg,  t = 0.3, s = "Exponential", d = "Out", g = { Size = UDim2.new(0.5, 0, 0.5, 0) } }):Play()
                    Stroke.Thickness = 0
                else
                    pcall(Callback, val)
                    Library:Tween({ v = Highlight, t = 0.5, s = "Exponential", d = "Out", g = { BackgroundTransparency = 1 } }):Play()
                    Library:Tween({ v = CheckImg,  t = 0.5, s = "Exponential", d = "Out", g = { ImageTransparency = 1 } }):Play()
                    Stroke.Thickness = 0.5
                end
            end
            -- Keep TitleLbl color correct after SetTheme changes T.Accent or T.Text
            RunService.Heartbeat:Connect(function()
                if not TitleLbl or not TitleLbl.Parent then return end
                local want = Data.Value and T.Accent or T.Text
                if TitleLbl.TextColor3 ~= want then
                    TitleLbl.TextColor3 = want
                end
            end)

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
            local RowIcon  = GetIcon(Args.Icon)   -- optional row icon

            -- When an icon is provided, wrap the slider in a NewRows container
            -- so it gets the same row chrome (bg, stroke, corner, icon) as other elements.
            -- Without an icon, the slider renders in its own standalone frame (original behaviour).
            local SliderParent = PageScrolling
            local SliderRowContainer = nil
            if RowIcon then
                SliderRowContainer = Library:NewRows(PageScrolling, Title, nil, T, track, RowIcon)
                SliderParent = SliderRowContainer
                Title = nil  -- title already in the row; don't duplicate in slider's own TextF
            end

            local SliderFrame = Library:Create("Frame", {
                Name             = "Slider",
                Parent           = SliderParent,
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
                pcall(Callback, val)
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
            Value = UpdateSlider(Value)

            -- Return a proxy so callers can read/write Value programmatically:
            --   local s = Page:Slider({...})
            --   s.Value = 50   -- updates slider instantly + fires Callback
            local SliderData = { Value = Value, Title = Args.Title, Min = Min, Max = Max }
            return setmetatable({}, {
                __newindex = function(t, k, v)
                    rawset(SliderData, k, v)
                    if k == "Value" then
                        Value = UpdateSlider(tonumber(v) or Min)
                    elseif k == "Title" then
                        TitleLbl.Text = tostring(v)
                    end
                end,
                __index = SliderData
            })
        end

        function Page:Input(Args)
            local Value    = Args.Value    or ""
            local Callback = Args.Callback or function() end
            local Title    = Args.Title
            local Desc     = Args.Desc
            local InputIcon = GetIcon(Args.Icon)   -- optional icon shown left of text field

            local InputFrame = Library:Create("Frame", {
                Name                   = "Input",
                Parent                 = PageScrolling,
                BackgroundTransparency = 1,
                BorderSizePixel        = 0,
                Size                   = UDim2.new(1, 0, 0, 30),
                Selectable             = false
            })
            Library:Create("UIListLayout", { Parent = InputFrame, Padding = UDim.new(0, 5), FillDirection = Enum.FillDirection.Horizontal, SortOrder = Enum.SortOrder.LayoutOrder, VerticalAlignment = Enum.VerticalAlignment.Center })

            -- Icon label (shown left of text field when Args.Icon is provided)
            local iconOffset = 0
            if InputIcon then
                local IcoLbl = Library:Create("ImageLabel", {
                    Name                   = "InputIcon",
                    Parent                 = InputFrame,
                    BackgroundTransparency = 1,
                    BorderSizePixel        = 0,
                    LayoutOrder            = -1,
                    Size                   = UDim2.new(0, 18, 0, 18),
                    Image                  = InputIcon,
                    ImageColor3            = T.Accent
                })
                track("Accent", IcoLbl, "ImageColor3")
                iconOffset = 23  -- shrink Front so icon + gap fits
            end

            local Front = Library:Create("Frame", {
                Name             = "Front",
                Parent           = InputFrame,
                BackgroundColor3 = T.Row,
                BorderSizePixel  = 0,
                Size             = UDim2.new(1, -(35 + iconOffset), 1, 0),
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
                task.delay(3, function() EnterIcon.Image = "rbxassetid://78020815235467" end)
            end)
            return TextBox
        end

        function Page:Dropdown(Args)
            local Title    = Args.Title
            local List     = Args.List
            local Value    = Args.Value
            local Callback = Args.Callback
            local IsMulti  = typeof(Value) == "table"
            local RowIcon  = GetIcon(Args.Icon)   -- optional row icon

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
                    task.delay(0, function()
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
            local RowIcon  = GetIcon(Args.Icon)   -- optional row icon
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

        --[[
            Page:Separator()
            A thin horizontal rule that visually divides sections.
            Optional Args:
                Color   (Color3 or hex string) — line color (default: T.Stroke)
                Height  (number)               — total frame height in px (default: 14)
        --]]
        function Page:Separator(Args)
            Args = Args or {}
            local lineColor = Args.Color and ResolveColor(Args.Color) or T.Stroke
            local height    = Args.Height or 14

            local Sep = Library:Create("Frame", {
                Name                   = "Separator",
                Parent                 = PageScrolling,
                BackgroundTransparency = 1,
                BorderSizePixel        = 0,
                Size                   = UDim2.new(1, 0, 0, height)
            })
            local Line = Library:Create("Frame", {
                Name             = "Line",
                Parent           = Sep,
                AnchorPoint      = Vector2.new(0.5, 0.5),
                BackgroundColor3 = lineColor,
                BorderSizePixel  = 0,
                Position         = UDim2.new(0.5, 0, 0.5, 0),
                Size             = UDim2.new(1, -20, 0, 1)
            })
            Library:Create("UICorner", { Parent = Line, CornerRadius = UDim.new(1, 0) })
            track("Stroke", Line, "BackgroundColor3")
            return Sep
        end

        --[[
            Page:Label(Args)
            A standalone text label — no row chrome, just styled text.
            Args:
                Text    (string)            — label content
                Size    (number)            — font size (default 12)
                Color   (Color3 or hex)     — text color (default T.Text)
                Align   ("Left"|"Center"|"Right") — alignment (default "Left")
                Bold    (bool)              — use GothamBold (default false)
        --]]
        function Page:Label(Args)
            local LabelText  = Args.Text  or ""
            local TextSize   = Args.Size  or 12
            local TextColor  = Args.Color and ResolveColor(Args.Color) or T.Text
            local Align      = Args.Align or "Left"
            local Bold       = Args.Bold  == true

            local alignMap = {
                Left   = Enum.TextXAlignment.Left,
                Center = Enum.TextXAlignment.Center,
                Right  = Enum.TextXAlignment.Right
            }

            local Lbl = Library:Create("TextLabel", {
                Name                   = "Label",
                Parent                 = PageScrolling,
                BackgroundTransparency = 1,
                BorderSizePixel        = 0,
                AutomaticSize          = Enum.AutomaticSize.Y,
                Size                   = UDim2.new(1, 0, 0, 0),
                Font                   = Bold and Enum.Font.GothamBold or Enum.Font.GothamMedium,
                RichText               = true,
                Text                   = LabelText,
                TextColor3             = TextColor,
                TextSize               = TextSize,
                TextStrokeTransparency = 0.7,
                TextTransparency       = 0.15,
                TextWrapped            = true,
                TextXAlignment         = alignMap[Align] or Enum.TextXAlignment.Left,
                TextYAlignment         = Enum.TextYAlignment.Top
            })
            Library:Create("UIPadding", {
                Parent       = Lbl,
                PaddingLeft  = UDim.new(0, 4),
                PaddingRight = UDim.new(0, 4)
            })
            track("Text", Lbl, "TextColor3")

            -- Proxy: lbl.Text = "new text" / lbl.Color = "#FF0000"
            local Data = { Text = LabelText }
            return setmetatable({}, {
                __newindex = function(t, k, v)
                    rawset(Data, k, v)
                    if k == "Text"  then Lbl.Text      = tostring(v)
                    elseif k == "Color" then Lbl.TextColor3 = ResolveColor(v)
                    end
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
