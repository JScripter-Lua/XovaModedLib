# Xova Library - Enhanced Edition

## 🎯 What's New - Complete Enhancement Summary

### 1. ✅ Full Lucide Icon System (823 Icons)
- **Complete icon integration** with all 823 Lucide icons from the uploaded file
- **Auto-resolution system**: Just pass `Icon = "eye"` and it automatically finds `lucide-eye`
- **Three ways to specify icons**:
  ```lua
  Icon = "eye"              -- Auto-resolves to lucide-eye
  Icon = "lucide-star"      -- Direct lookup
  Icon = 123456789          -- Raw asset ID (no rbxassetid:// needed!)
  ```

### 2. ✅ No CoreGui Anywhere
- **Completely removed** all CoreGui usage
- Uses `PlayerGui` or `gethui()` exclusively
- Safer and more compatible with executors

### 3. ✅ GitHub Integration
- Synced best features from the GitHub source
- Includes:
  - Notification system
  - Keybind element
  - Runtime theme changes
  - Executor identity display
  - Auto-scaling system

### 4. ✅ Fixed Auto Text Insertion Bug
- **Removed** all systems that automatically insert `\n` into text
- **Uses only**:
  - `TextWrapped = true`
  - `AutomaticSize = Enum.AutomaticSize.Y`
- Text content is never modified by the UI

### 5. ✅ Customizable Toggle Pill Icon
- **New `BbIcon` argument** in `Library:Window()`
  ```lua
  BbIcon = "settings"  -- Auto-resolves to lucide-settings
  ```
- **Runtime method**: `Library:SetPillIcon(icon)`
  ```lua
  Library:SetPillIcon("star")  -- Change icon on the fly
  ```

### 6. ✅ Four Critical Bug Fixes

#### Fix #1: Button Stretching After Click
- Added `ClipsDescendants = true` to all buttons
- Text properly constrained within button bounds
- No more overflow or stretching

#### Loader
```lua
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/JScripter-Lua/XovaModedLib/refs/heads/main/VitaLib_Enhanced.lua"))()
```

#### Fix #2: Customizable Per-Tab Banner Color
- **New `TabImage` argument** per page:
  ```lua
  Window:NewPage({
      Title = "My Page",
      TabImage = "#FF007F"  -- Custom pink banner
  })
  ```
- Each tab can have its own unique banner color

#### Fix #3: Text Going Outside Button Pill
- All text elements now use:
  - `TextWrapped = true`
  - `AutomaticSize = Enum.AutomaticSize.Y`
  - Proper size constraints
- No text overflow anywhere in the UI

#### Fix #4: Icon Auto-Resolution
- **No more `rbxassetid://` prefix needed!**
  ```lua
  -- OLD WAY (still works)
  Icon = "rbxassetid://10734966248"
  
  -- NEW WAY (much easier)
  Icon = "eye"  -- Automatically finds lucide-eye
  Icon = 10734966248  -- Automatically adds rbxassetid://
  ```

---

## 📦 All Available Elements

### Basic Elements
- **Section** - Headers for organizing content
- **Paragraph** - Text with icon display
- **RightLabel** - Label with right-aligned text
- **Toggle** - On/off switch with callback
- **Button** - Clickable button with effect
- **Banner** - Image display

### Input Elements
- **Slider** - Value slider with min/max/rounding
- **Input** - Text input with copy button
- **Dropdown** - Single or multi-select dropdown
- **Keybind** - Keyboard binding element

### System Features
- **Notifications** - Alert system (Info, Success, Warning, Error)
- **Window Scaling** - Auto or manual UI scaling
- **Runtime Theme** - Change colors on the fly
- **Executor Identity** - Display executor name

---

## 🎨 Theme Customization

### Full Theme Object
```lua
Theme = {
    Accent     = "#FF007F",  -- Main accent color
    Background = "#0D0D0D",  -- Window background
    Row        = "#0F0F0F",  -- Element background
    RowAlt     = "#0A0A0A",  -- Toggle-off / keybind bg
    Stroke     = "#191919",  -- Border color
    Text       = "#FFFFFF",  -- Primary text
    SubText    = "#A3A3A3",  -- Secondary text
    TabBg      = "#0A0A0A",  -- Tab card background
    TabStroke  = "#4B0026",  -- Tab card border
    TabImage   = "#FF007F",  -- Tab banner tint
    DropBg     = "#121212",  -- Dropdown background
    DropStroke = "#1E1E1E",  -- Dropdown border
    PillBg     = "#0B0B0B",  -- Toggle pill background
}
```

### Shorthand Theme Properties
```lua
BG        = "#0D0D0D"  -- Sets Background
Tab       = "#0A0A0A"  -- Sets TabBg
TabImage  = "#FF007F"  -- Sets TabImage
TabStroke = "#4B0026"  -- Sets TabStroke
```

### Runtime Theme Changes
```lua
Library:SetTheme({
    Accent = "#0066FF",
    TabImage = "#0066FF"
})
```

---

## 🔧 Window Configuration

```lua
local Window = Library:Window({
    -- Basic Settings
    Title = "My UI",
    SubTitle = "v1.0",
    Size = UDim2.new(0, 550, 0, 400),  -- Custom size (optional)
    
    -- Toggle Settings
    ToggleKey = Enum.KeyCode.RightControl,  -- Key to show/hide
    BbIcon = "settings",  -- Toggle pill icon
    
    -- Scaling Settings
    AutoScale = true,   -- Auto-scale to screen
    Scale = 1.45,       -- Base scale multiplier
    
    -- Display Settings
    ExecIdentifyShown = true,  -- Show executor name
    
    -- Theme (see above for full options)
    Theme = { ... },
    
    -- OR use shorthand
    BG = "#0D0D0D",
    Tab = "#0A0A0A",
    TabImage = "#FF007F",
    TabStroke = "#4B0026"
})
```

---

## 🌟 Lucide Icon System

### Complete Icon List (823 Total)
All icons are available with the `lucide-` prefix, or just use the name directly!

**Popular Icons:**
- `home`, `settings`, `user`, `bell`, `star`, `heart`
- `eye`, `eye-off`, `search`, `filter`, `calendar`
- `check`, `x`, `plus`, `minus`, `info`, `alert-circle`
- `arrow-right`, `arrow-left`, `chevron-down`, `chevron-up`
- `file`, `folder`, `image`, `video`, `music`
- `mail`, `phone`, `message-circle`, `share`
- `download`, `upload`, `save`, `trash`, `edit`
- `lock`, `unlock`, `key`, `shield`, `alert-triangle`

**And 800+ more!** See the full list in the library source code.

### Usage Examples
```lua
-- All three formats work:
Icon = "eye"                    -- Auto-resolves to lucide-eye
Icon = "lucide-settings"        -- Direct lookup
Icon = 10734966248              -- Raw asset ID
```

---

## 📋 Complete Element Reference

### Page:Section(text)
```lua
Page:Section("My Section Title")
```

### Page:Paragraph(Args)
```lua
Page:Paragraph({
    Title = "Info",
    Desc = "Description text",
    Icon = "info"  -- Lucide icon
})
```

### Page:RightLabel(Args)
```lua
Page:RightLabel({
    Title = "Status",
    Desc = "Description",
    Right = "Active"
})
```

### Page:Toggle(Args)
```lua
local Toggle = Page:Toggle({
    Title = "Enable Feature",
    Desc = "Toggle description",
    Value = false,
    Callback = function(value) end
})
-- Change programmatically: Toggle.Value = true
```

### Page:Button(Args)
```lua
Page:Button({
    Title = "Action",
    Desc = "Description",
    Text = "Click Me",
    Callback = function() end
})
```

### Page:Slider(Args)
```lua
Page:Slider({
    Title = "Speed",
    Min = 0,
    Max = 100,
    Rounding = 1,
    Value = 50,
    Callback = function(value) end
})
```

### Page:Input(Args)
```lua
Page:Input({
    Title = "Username",
    Desc = "Enter name",
    Value = "",
    Callback = function(text) end
})
```

### Page:Dropdown(Args)
```lua
-- Single Select
Page:Dropdown({
    Title = "Mode",
    List = {"A", "B", "C"},
    Value = "A",
    Callback = function(selected) end
})

-- Multi Select
Page:Dropdown({
    Title = "Features",
    List = {"1", "2", "3"},
    Value = {"1", "2"},  -- Table = multi-select
    Callback = function(selected) end
})
```

### Page:Keybind(Args)
```lua
local Keybind = Page:Keybind({
    Title = "Toggle Speed",
    Desc = "Press key",
    Value = Enum.KeyCode.F,
    Callback = function(key) end
})
-- Change programmatically: Keybind.Value = Enum.KeyCode.G
```

### Page:Banner(assetId)
```lua
Page:Banner("rbxassetid://123456789")
-- OR
Page:Banner(123456789)  -- Auto-adds rbxassetid://
```

---

## 🔔 Notification System

```lua
Library:Notification({
    Title = "Success!",
    Desc = "Operation completed",
    Duration = 3,  -- Seconds
    Type = "Info"  -- Info, Success, Warning, Error
})
```

**Types:**
- `Info` - Blue accent
- `Success` - Green accent
- `Warning` - Orange accent  
- `Error` - Red accent

---

## 🛠️ Library Methods

### Library:SetTimeValue(text)
Update the time display in the header
```lua
Library:SetTimeValue("12:34:56 Hours")
```

### Library:AddSizeSlider(Page)
Add interface scale slider to a page
```lua
Library:AddSizeSlider(Page)
```

### Library:SetTheme(newTheme)
Change theme colors at runtime
```lua
Library:SetTheme({
    Accent = "#0066FF",
    TabImage = "#0066FF"
})
```

### Library:SetPillIcon(icon)
Change toggle pill button icon
```lua
Library:SetPillIcon("star")
```

### Library:SetExecutorIdentity(visible)
Show/hide executor name label
```lua
Library:SetExecutorIdentity(false)
```

### Library:Destroy()
Clean up and remove all UI elements
```lua
Library:Destroy()
```

---

## 📝 Important Notes

1. **No CoreGui**: This library never uses CoreGui
2. **Text Wrapping**: All text uses `TextWrapped = true` - no manual `\n` needed
3. **Icon Resolution**: Icons auto-resolve - just use the name!
4. **Mobile Support**: Full touch controls and auto-scaling
5. **Theme Changes**: Update colors anytime with `SetTheme()`
6. **Per-Tab Colors**: Each tab can have custom `TabImage` color

---

## 🐛 Bug Fixes Applied

1. ✅ **Button stretching** - Fixed with ClipsDescendants
2. ✅ **Tab banner colors** - Added per-tab `TabImage` arg
3. ✅ **Text overflow** - All text uses TextWrapped + AutomaticSize
4. ✅ **Icon syntax** - Auto-resolution system implemented
5. ✅ **CoreGui usage** - Completely removed
6. ✅ **Auto text insertion** - Removed all `\n` insertion systems

---

## 📄 Files Included

1. **VitaLib_Enhanced.lua** - The complete library (30KB+)
2. **Example_Usage.lua** - Comprehensive example demonstrating all features
3. **README.md** - This file

---

## 🚀 Quick Start

```lua
-- Load library
local Library = loadstring(game:HttpGet("YOUR_URL"))()

-- Create window
local Window = Library:Window({
    Title = "My UI",
    BbIcon = "settings"
})

-- Create page
local Page = Window:NewPage({
    Title = "Main",
    Icon = "home",
    TabImage = "#FF007F"
})

-- Add elements
Page:Toggle({
    Title = "Enable",
    Value = false,
    Callback = function(v) print(v) end
})

-- Show notification
Library:Notification({
    Title = "Ready!",
    Desc = "UI loaded successfully",
    Type = "Success"
})
```

---

## 💡 Tips

1. Use short icon names: `Icon = "eye"` instead of `Icon = "lucide-eye"`
2. Theme colors accept hex strings: `Accent = "#FF007F"`
3. Each tab can have custom colors: `TabImage = "#0066FF"`
4. Update themes on the fly: `Library:SetTheme({ Accent = "#new" })`
5. Mobile users get auto-scaling - no manual adjustment needed

---

Made with ❤️ Moded by the_url_linker
Enhanced Edition v2.0
