--[[
    Vita UI Library - Comprehensive Usage Example
    
    This example demonstrates all features including:
    - Window creation with custom theme
    - All UI elements (Toggle, Slider, Input, Dropdown, Keybind, Button, etc.)
    - Lucide icon system (auto-resolution)
    - Per-tab banner customization
    - Notifications
    - Runtime theme changes
    - Toggle pill icon customization
--]]

-- Load the library
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/JScripter-Lua/XovaModedLib/refs/heads/main/VitaLib_Enhanced.lua"))()

-- Create a window with custom theme and settings
local Window = Library:Window({
    Title = "Vita UI Showcase",
    SubTitle = "Enhanced Edition v2.0",
    Size = UDim2.new(0, 550, 0, 400),  -- Custom size
    ToggleKey = Enum.KeyCode.RightControl,  -- Custom toggle key
    BbIcon = "settings",  -- Pill icon (auto-resolves to lucide-settings)
    AutoScale = true,  -- Auto-scale to screen size
    Scale = 1.45,  -- Base scale
    ExecIdentifyShown = true,  -- Show executor name
    
    -- Custom theme with hex colors
    Theme = {
        Accent = "#FF007F",  -- Hot pink
        Background = "#0D0D0D",
        Row = "#0F0F0F",
        Text = "#FFFFFF",
        SubText = "#A3A3A3"
    },
    
    -- OR use shorthand theme properties
    BG = "#0D0D0D",
    Tab = "#0A0A0A",
    TabImage = "#FF007F",
    TabStroke = "#4B0026"
})

------------------------------------------------------------
-- Page 1: Basic Elements
------------------------------------------------------------
local Page1 = Window:NewPage({
    Title = "Basic Elements",
    Desc = "Toggles, Buttons, Inputs",
    Icon = "home",  -- Auto-resolves to lucide-home
    TabImage = "#FF007F"  -- Custom tab banner color
})

-- Section
Page1:Section("Toggles & Buttons")

-- Toggle
local MyToggle = Page1:Toggle({
    Title = "Enable Feature",
    Desc = "Turn this feature on/off",
    Value = false,
    Callback = function(value)
        print("Toggle state:", value)
    end
})

-- Change toggle value programmatically
-- MyToggle.Value = true

-- Button
Page1:Button({
    Title = "Execute Action",
    Desc = "Click to perform action",
    Text = "Click Me!",
    Callback = function()
        Library:Notification({
            Title = "Success!",
            Desc = "Button was clicked successfully",
            Duration = 3,
            Type = "Success"  -- Info, Success, Warning, Error
        })
    end
})

-- Right Label
Page1:RightLabel({
    Title = "Status",
    Desc = "Current state",
    Right = "Active"
})

-- Paragraph with icon
Page1:Paragraph({
    Title = "Information",
    Desc = "This is a paragraph element with an icon",
    Icon = "info"  -- Auto-resolves to lucide-info
})

------------------------------------------------------------
-- Page 2: Advanced Input
------------------------------------------------------------
local Page2 = Window:NewPage({
    Title = "Input Elements",
    Desc = "Sliders, Inputs, Dropdowns",
    Icon = "sliders",  -- lucide-sliders
    TabImage = "#00BFFF"  -- Custom blue banner
})

Page2:Section("Sliders & Inputs")

-- Slider
Page2:Slider({
    Title = "Speed Multiplier",
    Min = 0,
    Max = 100,
    Rounding = 1,
    Value = 50,
    Callback = function(value)
        print("Slider value:", value)
    end
})

-- Input Box
Page2:Input({
    Title = "Username",
    Desc = "Enter your username",
    Value = "",
    Callback = function(text)
        print("Input text:", text)
    end
})

-- Dropdown (Single Select)
local MyDropdown = Page2:Dropdown({
    Title = "Select Mode",
    List = {"Mode A", "Mode B", "Mode C", "Mode D"},
    Value = "Mode A",
    Callback = function(selected)
        print("Selected:", selected)
    end
})

-- Add items to dropdown
-- MyDropdown:AddList("Mode E")

-- Clear dropdown
-- MyDropdown:Clear()

-- Dropdown (Multi Select)
Page2:Dropdown({
    Title = "Select Features",
    List = {"Feature 1", "Feature 2", "Feature 3", "Feature 4"},
    Value = {"Feature 1", "Feature 2"},  -- Table = multi-select
    Callback = function(selected)
        print("Selected features:", table.concat(selected, ", "))
    end
})

------------------------------------------------------------
-- Page 3: Keybinds & Advanced
------------------------------------------------------------
local Page3 = Window:NewPage({
    Title = "Keybinds",
    Desc = "Custom key bindings",
    Icon = "keyboard",
    TabImage = "#FFD700"  -- Gold banner
})

Page3:Section("Keybind Configuration")

-- Keybind
local MyKeybind = Page3:Keybind({
    Title = "Toggle Speed",
    Desc = "Press key to toggle",
    Value = Enum.KeyCode.F,
    Callback = function(key)
        print("Keybind pressed:", key.Name)
        Library:Notification({
            Title = "Keybind Activated",
            Desc = "You pressed " .. key.Name,
            Duration = 2,
            Type = "Info"
        })
    end
})

-- Change keybind programmatically
-- MyKeybind.Value = Enum.KeyCode.G

-- Banner
Page3:Banner("rbxassetid://123456789")  -- Add custom banner image

------------------------------------------------------------
-- Page 4: Settings & Utilities
------------------------------------------------------------
local Page4 = Window:NewPage({
    Title = "Settings",
    Desc = "UI Configuration",
    Icon = "settings",
    TabImage = "#9370DB"  -- Purple banner
})

Page4:Section("UI Settings")

-- Interface Scale Slider
Library:AddSizeSlider(Page4)

-- Time Display (optional)
Page4:RightLabel({
    Title = "Session Time",
    Desc = "Current runtime",
    Right = "00:00:00"
})

-- Update time display
spawn(function()
    local startTime = tick()
    while wait(1) do
        local elapsed = tick() - startTime
        local hours = math.floor(elapsed / 3600)
        local minutes = math.floor((elapsed % 3600) / 60)
        local seconds = math.floor(elapsed % 60)
        Library:SetTimeValue(string.format("%02d:%02d:%02d Hours", hours, minutes, seconds))
    end
end)

------------------------------------------------------------
-- Icon System Examples
------------------------------------------------------------
local Page5 = Window:NewPage({
    Title = "Icon System",
    Desc = "Lucide Icons Demo",
    Icon = "eye",  -- Just "eye" - auto-resolves to lucide-eye
    TabImage = "#32CD32"  -- Green banner
})

Page5:Section("Icon Resolution Examples")

Page5:Paragraph({
    Title = "Icon: Simple Name",
    Desc = "Icon = 'heart' → lucide-heart",
    Icon = "heart"  -- Auto-resolves
})

Page5:Paragraph({
    Title = "Icon: Lucide Prefix",
    Desc = "Icon = 'lucide-star' → lucide-star",
    Icon = "lucide-star"  -- Direct lookup
})

Page5:Paragraph({
    Title = "Icon: Asset ID",
    Desc = "Icon = 123456789 → rbxassetid://123456789",
    Icon = 10734966248  -- lucide-star asset ID
})

------------------------------------------------------------
-- Runtime Customization Examples
------------------------------------------------------------
Page5:Section("Runtime Customization")

-- Change theme at runtime
Page5:Button({
    Title = "Dark Blue Theme",
    Desc = "Switch to blue accent",
    Text = "Apply",
    Callback = function()
        Library:SetTheme({
            Accent = "#0066FF",
            TabImage = "#0066FF"
        })
    end
})

Page5:Button({
    Title = "Purple Theme",
    Desc = "Switch to purple accent",
    Text = "Apply",
    Callback = function()
        Library:SetTheme({
            Accent = "#9370DB",
            TabImage = "#9370DB"
        })
    end
})

-- Change pill icon at runtime
Page5:Button({
    Title = "Change Pill Icon",
    Desc = "Update toggle button icon",
    Text = "Change",
    Callback = function()
        Library:SetPillIcon("star")  -- Change to star icon
    end
})

-- Hide/Show executor label
Page5:Button({
    Title = "Toggle Executor Label",
    Desc = "Show/hide executor name",
    Text = "Toggle",
    Callback = function()
        local current = Page5.Instance.Parent.Parent.Parent.ExecIdentity.Visible
        Library:SetExecutorIdentity(not current)
    end
})

------------------------------------------------------------
-- Notification Examples
------------------------------------------------------------
local Page6 = Window:NewPage({
    Title = "Notifications",
    Desc = "Alert System Demo",
    Icon = "bell",
    TabImage = "#FF6347"  -- Tomato red banner
})

Page6:Section("Notification Types")

Page6:Button({
    Title = "Info Notification",
    Desc = "Show info alert",
    Text = "Show",
    Callback = function()
        Library:Notification({
            Title = "Information",
            Desc = "This is an informational message",
            Duration = 3,
            Type = "Info"
        })
    end
})

Page6:Button({
    Title = "Success Notification",
    Desc = "Show success alert",
    Text = "Show",
    Callback = function()
        Library:Notification({
            Title = "Success!",
            Desc = "Operation completed successfully",
            Duration = 3,
            Type = "Success"
        })
    end
})

Page6:Button({
    Title = "Warning Notification",
    Desc = "Show warning alert",
    Text = "Show",
    Callback = function()
        Library:Notification({
            Title = "Warning",
            Desc = "Please check your settings",
            Duration = 3,
            Type = "Warning"
        })
    end
})

Page6:Button({
    Title = "Error Notification",
    Desc = "Show error alert",
    Text = "Show",
    Callback = function()
        Library:Notification({
            Title = "Error",
            Desc = "Something went wrong!",
            Duration = 3,
            Type = "Error"
        })
    end
})

------------------------------------------------------------
-- Advanced Features
------------------------------------------------------------
Page6:Section("Advanced Features")

Page6:Paragraph({
    Title = "Text Wrapping",
    Desc = "All text elements automatically wrap using TextWrapped = true and AutomaticSize = Enum.AutomaticSize.Y. No manual \\n insertion!",
    Icon = "align-left"
})

Page6:Paragraph({
    Title = "No CoreGui",
    Desc = "This library never uses CoreGui anywhere. Everything is placed in PlayerGui or gethui().",
    Icon = "shield-check"
})

Page6:Paragraph({
    Title = "Mobile Support",
    Desc = "Fully supports mobile devices with touch controls and auto-scaling.",
    Icon = "smartphone"
})

------------------------------------------------------------
-- Clean Up (Optional)
------------------------------------------------------------
-- To destroy the UI completely:
-- Library:Destroy()

------------------------------------------------------------
-- Print Available Lucide Icons (First 20)
------------------------------------------------------------
print("Available Lucide Icons (sample):")
local iconCount = 0
for iconName in pairs(getgenv().Lucide or {}) do
    if iconCount < 20 then
        print("  " .. iconName)
        iconCount = iconCount + 1
    end
end
print("... and " .. (823 - 20) .. " more icons!")

print("Vita UI Library loaded successfully!")
print("Press", Window.ToggleKey or "RightControl", "to toggle UI")
