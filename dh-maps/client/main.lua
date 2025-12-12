--[[
    DH-Maps Client
    Optimized map marker system with big map support
    
    If Config.RequireMapForPauseMenu is true:
    - ESC opens normal pause menu ONLY if player has a map in inventory
    - When they click on MAP tab in pause menu, it shows their custom markers
    - If no map in inventory, pause menu is blocked entirely
    
    If Config.RequireMapForPauseMenu is false:
    - Normal pause menu works as usual
    - Map only opens when using the paper_map item directly
]]

local QBCore = exports['qb-core']:GetCoreObject()

-- State
local activeSlot, activeMapData, sessionActive = nil, nil, false
local spawnedBlips = {}
local editor = {active = false, slot = nil, pos = nil, data = nil}
local preview = {blip = nil, pos = nil, data = nil}
local keyFlags = {spriteUp = false, spriteDown = false, colorUp = false, colorDown = false, scaleUp = false, scaleDown = false}
local isTyping = false
local hasMap = false
local mapSlot = nil
local mapProp = nil

-- Helpers
local function clamp(v, min, max) return v < min and min or (v > max and max or v) end
local function getDefault(key) return Config.DefaultMarker[key] or (key == 'sprite' and 1 or key == 'color' and 0 or 0.8) end
local function clampScale(v) return clamp(v, Config.MarkerLimits.minScale, Config.MarkerLimits.maxScale) end
local function resetKeyFlags() for k in pairs(keyFlags) do keyFlags[k] = false end end

-- Animation & Prop helpers
local function loadAnimDict(dict)
    if HasAnimDictLoaded(dict) then return true end
    RequestAnimDict(dict)
    local timeout = 0
    while not HasAnimDictLoaded(dict) and timeout < 1000 do
        Wait(10)
        timeout = timeout + 10
    end
    return HasAnimDictLoaded(dict)
end

local function loadModel(model)
    local hash = type(model) == 'string' and GetHashKey(model) or model
    if HasModelLoaded(hash) then return true end
    RequestModel(hash)
    local timeout = 0
    while not HasModelLoaded(hash) and timeout < 1000 do
        Wait(10)
        timeout = timeout + 10
    end
    return HasModelLoaded(hash)
end

local function startMapAnimation()
    -- Check if animation is enabled
    if not Config.Animation.enabled then return end
    
    local ped = PlayerPedId()
    
    -- Don't play animation if in vehicle
    if IsPedInAnyVehicle(ped, false) then return end
    
    -- Load animation
    local animDict = Config.Animation.dict
    local animName = Config.Animation.name
    
    if not loadAnimDict(animDict) then return end
    
    -- Load and create prop
    local propModel = Config.Animation.prop
    if loadModel(propModel) then
        local propHash = GetHashKey(propModel)
        local boneIndex = GetPedBoneIndex(ped, Config.Animation.propBone)
        
        mapProp = CreateObject(propHash, 0.0, 0.0, 0.0, true, true, true)
        AttachEntityToEntity(mapProp, ped, boneIndex, 
            Config.Animation.propOffset.x, 
            Config.Animation.propOffset.y, 
            Config.Animation.propOffset.z,
            Config.Animation.propRotation.x, 
            Config.Animation.propRotation.y, 
            Config.Animation.propRotation.z,
            true, true, false, true, 1, true)
        
        SetModelAsNoLongerNeeded(propHash)
    end
    
    -- Play animation
    TaskPlayAnim(ped, animDict, animName, 8.0, -8.0, -1, Config.Animation.flag, 0, false, false, false)
end

local function stopMapAnimation()
    local ped = PlayerPedId()
    
    -- Delete prop
    if mapProp and DoesEntityExist(mapProp) then
        DeleteEntity(mapProp)
        mapProp = nil
    end
    
    -- Stop animation
    if not IsPedInAnyVehicle(ped, false) then
        ClearPedTasks(ped)
    end
end

-- Check if player has a map in inventory
local function checkForMap()
    local Player = QBCore.Functions.GetPlayerData()
    if not Player or not Player.items then 
        hasMap = false
        mapSlot = nil
        return 
    end
    
    for slot, item in pairs(Player.items) do
        if item and item.name == Config.MapItemName then
            hasMap = true
            mapSlot = slot
            return
        end
    end
    
    hasMap = false
    mapSlot = nil
end

-- NUI Controls
local function sendUI(show, editing)
    if not Config.UI.enabled then return end
    local items = editing and {
        {label = Config.UILabels.sprite, key = Config.UIKeys.spriteAdjust},
        {label = Config.UILabels.color, key = Config.UIKeys.colorAdjust},
        {label = Config.UILabels.scale, key = Config.UIKeys.scaleAdjust},
        {label = Config.UILabels.save, key = Config.UIKeys.save},
        {label = Config.UILabels.cancel, key = Config.UIKeys.cancel}
    } or {
        {label = Config.UILabels.newMarker, key = Config.UIKeys.newMarker},
        {label = Config.UILabels.deleteNearest, key = Config.UIKeys.deleteNearest},
        {label = Config.UILabels.close, key = Config.UIKeys.close}
    }
    SendNUIMessage({type = 'dhmaps:controls', show = show, config = Config.UI, items = items})
end

-- Blip Management
local function clearBlips()
    for _, blip in pairs(spawnedBlips) do if DoesBlipExist(blip) then RemoveBlip(blip) end end
    spawnedBlips = {}
end

local function createBlip(x, y, z, sprite, color, scale, name)
    local blip = AddBlipForCoord(x + 0.0, y + 0.0, (z or 0.0) + 0.0)
    SetBlipDisplay(blip, Config.BlipDisplay)
    SetBlipHighDetail(blip, Config.BlipHighDetail)
    SetBlipAsShortRange(blip, Config.DefaultMarker.shortRange)
    SetBlipSprite(blip, sprite or getDefault('sprite'))
    SetBlipColour(blip, color or getDefault('color'))
    SetBlipScale(blip, clampScale(scale or getDefault('scale')))
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString(name or 'Marker')
    EndTextCommandSetBlipName(blip)
    return blip
end

local function spawnBlips(data)
    clearBlips()
    if not data or not data.markers then return end
    for _, mk in ipairs(data.markers) do
        spawnedBlips[mk.id] = createBlip(mk.x, mk.y, mk.z, mk.sprite, mk.color, mk.scale, mk.name)
    end
end

-- Preview Blip
local function destroyPreview()
    if preview.blip and DoesBlipExist(preview.blip) then RemoveBlip(preview.blip) end
    preview = {blip = nil, pos = nil, data = nil}
end

local function updatePreview()
    if not preview.pos or not preview.data then return end
    if preview.blip and DoesBlipExist(preview.blip) then RemoveBlip(preview.blip) end
    preview.blip = createBlip(preview.pos.x, preview.pos.y, preview.pos.z, preview.data.sprite, preview.data.color, preview.data.scale, preview.data.name)
end

-- Map Controls
local function getCursorPosition()
    local pos = GetPauseMapPointerWorldPosition()
    if pos and not (pos.x == 0.0 and pos.y == 0.0 and pos.z == 0.0) then return vector3(pos.x, pos.y, pos.z) end
    if IsWaypointActive() then
        local blip = GetFirstBlipInfoId(8)
        if blip ~= 0 then local c = GetBlipInfoIdCoord(blip) return vector3(c.x, c.y, c.z) end
    end
    return nil
end

local function findNearestMarker(pos)
    if not activeMapData or not activeMapData.markers then return nil end
    local best, bestDist = nil, Config.MarkerLimits.searchRadius
    for _, mk in ipairs(activeMapData.markers) do
        local d = math.sqrt((mk.x - pos.x)^2 + (mk.y - pos.y)^2)
        if d < bestDist then bestDist, best = d, mk end
    end
    return best
end

local function keyboardInput(title, default, maxLen)
    isTyping = true
    
    -- Small delay to let the G key release
    Wait(100)
    
    AddTextEntry('DHMAPS_INPUT', title)
    DisplayOnscreenKeyboard(1, 'DHMAPS_INPUT', '', default or '', '', '', '', maxLen or Config.MarkerLimits.maxNameLength)
    
    while UpdateOnscreenKeyboard() == 0 do 
        DisableAllControlActions(0)
        Wait(0) 
    end
    
    isTyping = false
    
    return UpdateOnscreenKeyboard() == 1 and GetOnscreenKeyboardResult() or nil
end

-- Session Management
local function endSession()
    sendUI(false, false)
    sessionActive = false
    activeSlot = nil
    activeMapData = nil
    editor = {active = false, slot = nil, pos = nil, data = nil}
    resetKeyFlags()
    destroyPreview()
    if Config.ShowMarkersOnlyWhileUsingMap then clearBlips() end
    
    -- Close frontend
    SetFrontendActive(false)
    
    -- Stop animation and remove prop
    stopMapAnimation()
end

local function startSession(slot)
    if sessionActive then 
        sendUI(true, editor.active) 
        return 
    end
    
    activeSlot = slot
    sessionActive = true
    
    -- Start animation and prop
    startMapAnimation()
    
    -- Request map data from server
    TriggerServerEvent('dh-maps:server:getData', activeSlot)
    
    -- Open the pause menu
    ActivateFrontendMenu(GetHashKey('FE_MENU_VERSION_MP_PAUSE'), false, -1)
    
    -- Wait for pause menu to be fully loaded
    while not IsPauseMenuActive() or IsPauseMenuRestarting() do
        Wait(0)
    end
    
    -- Small delay to ensure menu is ready
    Wait(100)
    
    -- Go directly to the big map view
    PauseMenuceptionGoDeeper(0)
    
    -- Another small delay for the map transition
    Wait(50)
    
    -- Now show the UI
    sendUI(true, false)
    
    -- Session loop
    CreateThread(function()
        while sessionActive do
            Wait(0)
            
            -- Block Q and E (tab navigation) while in map (except when typing)
            if not isTyping then
                -- Frontend tab controls (Q=205, E=206) - disable on all input groups
                for i = 0, 3 do
                    DisableControlAction(i, 205, true)   -- INPUT_FRONTEND_LB (Q)
                    DisableControlAction(i, 206, true)   -- INPUT_FRONTEND_RB (E)
                end
            end
            
            -- Skip other control blocking while typing
            if isTyping then
                goto continue
            end
            
            -- Check if pause menu was closed externally
            if not IsPauseMenuActive() then 
                endSession() 
                break 
            end
            
            -- Don't process close controls if editor is active (editor handles its own cancel)
            if not editor.active then
                -- Block close controls
                DisableControlAction(0, Config.CloseControl, true)  -- ESC
                DisableControlAction(0, Config.CancelControl, true) -- Backspace
                DisableControlAction(0, 202, true)                   -- Frontend cancel
                
                -- Close on ESC, Backspace, or frontend cancel
                if IsDisabledControlJustPressed(0, Config.CloseControl) or 
                   IsDisabledControlJustPressed(0, Config.CancelControl) or 
                   IsDisabledControlJustPressed(0, 202) then 
                    endSession() 
                    break 
                end
            end
            
            ::continue::
        end
    end)
end

-- Editor
local function cancelEditor()
    editor.active = false
    destroyPreview()
    resetKeyFlags()
    sendUI(true, false)
end

local function saveEditor()
    if not editor.active or not editor.slot or not editor.data or not editor.pos then return end
    local mk = {
        id = ('mk_%d_%d'):format(GetGameTimer(), math.random(1000, 9999)),
        name = editor.data.name or 'Marker',
        sprite = tonumber(editor.data.sprite) or getDefault('sprite'),
        color = tonumber(editor.data.color) or getDefault('color'),
        scale = clampScale(tonumber(editor.data.scale) or getDefault('scale')),
        x = editor.pos.x, y = editor.pos.y, z = editor.pos.z
    }
    TriggerServerEvent('dh-maps:server:addMarker', editor.slot, mk)
    TriggerServerEvent('dh-maps:server:getData', editor.slot)
    cancelEditor()
end

local function runEditor()
    CreateThread(function()
        while editor.active do
            Wait(0)
            
            -- Block and check confirm/cancel controls
            DisableControlAction(0, Config.ConfirmControl, true)  -- Enter
            DisableControlAction(0, Config.CancelControl, true)   -- Backspace
            DisableControlAction(0, 202, true)                     -- Frontend cancel
            
            -- Save on Enter
            if IsDisabledControlJustPressed(0, Config.ConfirmControl) then 
                saveEditor() 
                break 
            end
            
            -- Cancel on Backspace or frontend cancel
            if IsDisabledControlJustPressed(0, Config.CancelControl) or IsDisabledControlJustPressed(0, 202) then 
                cancelEditor() 
                break 
            end
            
            -- Handle sprite/color/scale adjustments
            local changed = false
            if keyFlags.spriteUp then editor.data.sprite = (editor.data.sprite or 0) + 1 changed = true end
            if keyFlags.spriteDown then editor.data.sprite = math.max(0, (editor.data.sprite or 0) - 1) changed = true end
            if keyFlags.colorUp then editor.data.color = (editor.data.color or 0) + 1 changed = true end
            if keyFlags.colorDown then editor.data.color = math.max(0, (editor.data.color or 0) - 1) changed = true end
            if keyFlags.scaleUp then editor.data.scale = clampScale((editor.data.scale or getDefault('scale')) + Config.MarkerLimits.scaleStep) changed = true end
            if keyFlags.scaleDown then editor.data.scale = clampScale((editor.data.scale or getDefault('scale')) - Config.MarkerLimits.scaleStep) changed = true end
            
            resetKeyFlags()
            if changed then preview.data = editor.data updatePreview() end
        end
    end)
end

-- Actions
local function createMarker()
    if not sessionActive or not activeSlot or editor.active or isTyping then return end
    local pos = getCursorPosition()
    if not pos then return end
    
    local name = keyboardInput(Config.KeyboardPrompt, '', Config.MarkerLimits.maxNameLength)
    if not name or name == '' then return end
    
    editor = {active = true, slot = activeSlot, pos = pos, data = {name = name, sprite = getDefault('sprite'), color = getDefault('color'), scale = getDefault('scale')}}
    preview = {blip = nil, pos = pos, data = editor.data}
    updatePreview()
    sendUI(true, true)
    runEditor()
end

local function deleteNearest()
    if not sessionActive or not activeSlot or editor.active or isTyping then return end
    local pos = getCursorPosition()
    if not pos then return end
    local mk = findNearestMarker(pos)
    if mk then
        TriggerServerEvent('dh-maps:server:deleteMarker', activeSlot, mk.id)
        TriggerServerEvent('dh-maps:server:getData', activeSlot)
    end
end

-- Commands & Keybinds
RegisterCommand('dhmaps_create', createMarker, false)
RegisterCommand('dhmaps_delete', deleteNearest, false)
RegisterCommand('dhmaps_sprite_up', function() keyFlags.spriteUp = true end, false)
RegisterCommand('dhmaps_sprite_down', function() keyFlags.spriteDown = true end, false)
RegisterCommand('dhmaps_color_up', function() keyFlags.colorUp = true end, false)
RegisterCommand('dhmaps_color_down', function() keyFlags.colorDown = true end, false)
RegisterCommand('dhmaps_scale_up', function() keyFlags.scaleUp = true end, false)
RegisterCommand('dhmaps_scale_down', function() keyFlags.scaleDown = true end, false)

RegisterKeyMapping('dhmaps_create', 'DH Maps: Create marker', 'keyboard', 'G')
RegisterKeyMapping('dhmaps_delete', 'DH Maps: Delete marker', 'keyboard', 'H')
RegisterKeyMapping('dhmaps_sprite_up', 'DH Maps: Sprite +', 'keyboard', Config.Controls.spriteUp)
RegisterKeyMapping('dhmaps_sprite_down', 'DH Maps: Sprite -', 'keyboard', Config.Controls.spriteDown)
RegisterKeyMapping('dhmaps_color_up', 'DH Maps: Color +', 'keyboard', Config.Controls.colorUp)
RegisterKeyMapping('dhmaps_color_down', 'DH Maps: Color -', 'keyboard', Config.Controls.colorDown)
RegisterKeyMapping('dhmaps_scale_up', 'DH Maps: Scale +', 'keyboard', Config.Controls.scaleUp)
RegisterKeyMapping('dhmaps_scale_down', 'DH Maps: Scale -', 'keyboard', Config.Controls.scaleDown)

-- Events
RegisterNetEvent('dh-maps:client:useMap', function(item)
    local slot = item and (item.slot or item.slotId)
    if not slot then return end
    startSession(slot)
end)

RegisterNetEvent('dh-maps:client:receiveData', function(slot, data)
    if not activeSlot or tonumber(slot) ~= tonumber(activeSlot) then return end
    activeMapData = data or {markers = {}}
    if sessionActive or not Config.ShowMarkersOnlyWhileUsingMap then spawnBlips(activeMapData) end
end)

-- Handle markers added externally (from exports)
RegisterNetEvent('dh-maps:client:markerAdded', function(marker)
    -- If map is currently open, refresh the blips
    if sessionActive and activeSlot then
        TriggerServerEvent('dh-maps:server:getData', activeSlot)
    end
end)

-- Handle markers removed externally (from exports)
RegisterNetEvent('dh-maps:client:markerRemoved', function(markerName)
    -- If map is currently open, refresh the blips
    if sessionActive and activeSlot then
        TriggerServerEvent('dh-maps:server:getData', activeSlot)
    end
end)

-- Update map status when inventory changes
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    checkForMap()
end)

RegisterNetEvent('inventory:client:ItemBox', function()
    Wait(100)
    checkForMap()
end)

RegisterNetEvent('QBCore:Player:SetPlayerData', function(PlayerData)
    Wait(100)
    checkForMap()
end)

-- Show notification that map is required
local lastNotify = 0
local function showMapRequiredNotification()
    -- Throttle notifications to prevent spam
    local now = GetGameTimer()
    if now - lastNotify < 2000 then return end
    lastNotify = now
    
    -- Use QBCore notification if available, otherwise use native
    if Config.UseQBNotify then
        QBCore.Functions.Notify(Config.NoMapMessage, 'error', 3000)
    else
        -- Native help text
        BeginTextCommandDisplayHelp('STRING')
        AddTextComponentSubstringPlayerName(Config.NoMapMessage)
        EndTextCommandDisplayHelp(0, false, true, 3000)
    end
end

-- Pause menu blocking thread (only if RequireMapForPauseMenu is enabled)
-- This ONLY blocks the pause menu if player has NO map
-- If they have a map, pause menu works normally
CreateThread(function()
    Wait(500)
    
    if not Config.RequireMapForPauseMenu then
        return
    end
    
    while true do
        Wait(0)
        
        -- Don't interfere if session is active or typing
        if sessionActive or isTyping then
            goto continue
        end
        
        -- Check if pause menu just opened
        if IsPauseMenuActive() then
            checkForMap()
            
            -- If no map, close the pause menu and show notification
            if not hasMap then
                SetFrontendActive(false)
                showMapRequiredNotification()
            end
            -- If they have a map, let the pause menu stay open normally
        end
        
        ::continue::
    end
end)

-- Periodic check for map in inventory (every 1 second)
CreateThread(function()
    Wait(1000)
    while true do
        checkForMap()
        Wait(1000)
    end
end)

-- Cleanup on resource stop
AddEventHandler('onResourceStop', function(res) 
    if res == GetCurrentResourceName() then 
        sendUI(false, false)
        stopMapAnimation()
    end 
end)
