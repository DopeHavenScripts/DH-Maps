Config = {}

-- ============================================================================
-- INVENTORY SETTINGS
-- ============================================================================

Config.MapItemName = 'paper_map'                    -- Item name that triggers the map
Config.InventorySystem = 'auto'                     -- 'auto', 'qs-inventory', or 'qb-inventory'

-- ============================================================================
-- PAUSE MENU BEHAVIOR
-- ============================================================================
Config.RequireMapForPauseMenu = true                -- If true, pause menu is blocked without a map
                                                    -- If false, normal pause menu works, map only via item use, and shows customs blips
Config.NoMapMessage = 'You need a ~b~Paper Map~w~ to view the map'  -- Message shown when trying to open pause menu without map
Config.UseQBNotify = false                          -- true = use QBCore notification, false = use native help text

-- ============================================================================
-- ANIMATION & PROP SETTINGS
-- ============================================================================
Config.Animation = {
    enabled = true,                                 -- Enable/disable map holding animation
    dict = 'missheistdockssetup1clipboard@base',    -- Animation dictionary
    name = 'base',                                  -- Animation name
    flag = 49,                                      -- Animation flag (49 = upper body, loop)
    
    prop = 'prop_tourist_map_01',                   -- Map prop model
    propBone = 36029,                               -- Bone to attach prop (left hand)
    propOffset = {x = 0.0, y = 0.0, z = 0.0},       -- Prop position offset
    propRotation = {x = 0.0, y = 0.0, z = 0.0}      -- Prop rotation offset
}

-- ============================================================================
-- CONTROL BLOCKING
-- ============================================================================
Config.BlockedControls = {199, 244}                 -- 199=P, 244=M (prevent normal pause/map)
Config.CloseControl = 200                           -- ESC to close map
Config.CreateMarkerControl = 47                     -- G key
Config.DeleteMarkerControl = 74                     -- H key
Config.ConfirmControl = 201                         -- Enter
Config.CancelControl = 177                          -- Backspace

-- Numpad controls for marker editing
Config.Controls = {
    spriteUp = 'NUMPAD7',
    spriteDown = 'NUMPAD4',
    colorUp = 'NUMPAD9',
    colorDown = 'NUMPAD6',
    scaleUp = 'NUMPAD8',
    scaleDown = 'NUMPAD5'
}

-- ============================================================================
-- MARKER DEFAULTS
-- ============================================================================
Config.DefaultMarker = {
    sprite = 1,                                     -- Default blip sprite
    color = 2,                                      -- Default blip color
    scale = 1.0,                                    -- Default blip scale
    shortRange = false                              -- Show on minimap from any distance
}

Config.MarkerLimits = {
    minScale = 0.1,
    maxScale = 2.0,
    scaleStep = 0.1,
    maxNameLength = 30,
    searchRadius = 75.0                             -- Max distance to find nearest marker
}

-- ============================================================================
-- BLIP DISPLAY
-- ============================================================================
Config.ShowMarkersOnlyWhileUsingMap = true          -- Only show blips when map is open
Config.BlipDisplay = 4                              -- Display type (4 = both map and minimap)
Config.BlipHighDetail = true                        -- High detail blips

-- ============================================================================
-- UI SETTINGS (all size values in vh - viewport height percentage)
-- ============================================================================
Config.UI = {
    enabled = true,                                 -- Enable/disable the controls bar
    bottomOffset = 5.0,                             -- vh from bottom (sits just above native GTA controls)
    align = 'right',                                -- 'left', 'center', or 'right'
    sideMargin = 3.0,                               -- vh margin from right edge
    
    -- Bar dimensions (vh)
    barHeight = 3.2,                                -- Height of the control bar
    barRadius = 0.3,                                -- Corner radius
    barBlur = 2,                                    -- Backdrop blur in px (blur works better in px)
    
    -- Colors
    barBackground = 'rgba(0,0,0,0.75)',
    textColor = 'rgba(255,255,255,0.92)',
    textColorDim = 'rgba(255,255,255,0.70)',
    keyBackground = 'rgba(255,255,255,0.95)',
    keyTextColor = 'rgba(0,0,0,0.92)',
    keyBorderColor = 'rgba(0,0,0,0.35)',
    
    -- Font sizes (vh)
    fontSize = 1.4,                                 -- Label text size
    keyFontSize = 1.2,                              -- Key badge text size
    
    title = 'DH MAPS'                               -- Bar title text
}

-- Control labels shown in UI
Config.UILabels = {
    -- Normal mode
    newMarker = 'New marker',
    deleteNearest = 'Delete nearest', 
    close = 'Close',
    
    -- Edit mode
    sprite = 'Sprite +/-',
    color = 'Color +/-',
    scale = 'Scale +/-',
    save = 'Save',
    cancel = 'Cancel'
}

-- Control key display text
Config.UIKeys = {
    newMarker = 'G',
    deleteNearest = 'H',
    close = 'Esc',
    spriteAdjust = 'NUM7/4',
    colorAdjust = 'NUM9/6',
    scaleAdjust = 'NUM8/5',
    save = 'Enter',
    cancel = 'Back'
}

-- ============================================================================
-- KEYBOARD INPUT
-- ============================================================================
Config.KeyboardPrompt = 'Enter marker name'         -- Prompt shown when naming marker
