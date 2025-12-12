--[[
    DH-Maps Server
    Optimized marker data management
    
    EXPORTS:
    -- Add marker to all maps in player's inventory
    exports['dh-maps']:AddMarkerToPlayer(playerId, markerData)
    
    -- markerData format:
    -- {
    --     name = "Drug Deal Location",  -- Required: marker name
    --     x = 123.45,                    -- Required: x coordinate
    --     y = 678.90,                    -- Required: y coordinate  
    --     z = 21.0,                      -- Optional: z coordinate (defaults to 0)
    --     sprite = 1,                    -- Optional: blip sprite (defaults to Config.DefaultMarker.sprite)
    --     color = 2,                     -- Optional: blip color (defaults to Config.DefaultMarker.color)
    --     scale = 1.0                    -- Optional: blip scale (defaults to Config.DefaultMarker.scale)
    -- }
    
    -- Returns: number of maps the marker was added to (0 if player has no maps)
    
    -- Example usage from another script:
    -- local mapsUpdated = exports['dh-maps']:AddMarkerToPlayer(source, {
    --     name = "Weed Farm",
    --     x = 2220.15,
    --     y = 5577.82,
    --     z = 53.73,
    --     sprite = 469,
    --     color = 2
    -- })
]]

local QBCore = exports['qb-core']:GetCoreObject()

-- Helpers
local function ensureMetadata(meta)
    meta = meta or {}
    meta.dhMaps = meta.dhMaps or {version = 1, mapId = ('%d_%d'):format(os.time(), math.random(100000, 999999)), markers = {}}
    return meta
end

local function getItem(src, slot)
    if Config.InventorySystem == 'qb-inventory' then
        local Player = QBCore.Functions.GetPlayer(src)
        return Player and Player.Functions.GetItemBySlot(slot)
    end
    if Config.InventorySystem == 'qs-inventory' or GetResourceState('qs-inventory') == 'started' then
        local ok, inv = pcall(function() return exports['qs-inventory']:GetInventory(src) end)
        return ok and inv and inv[tonumber(slot)]
    end
    local Player = QBCore.Functions.GetPlayer(src)
    return Player and Player.Functions.GetItemBySlot(slot)
end

local function setMetadata(src, slot, meta)
    if Config.InventorySystem == 'qb-inventory' then
        local Player = QBCore.Functions.GetPlayer(src)
        if Player then Player.Functions.SetItemData(slot, 'info', meta) end
        return
    end
    if Config.InventorySystem == 'qs-inventory' or GetResourceState('qs-inventory') == 'started' then
        pcall(function() exports['qs-inventory']:SetItemMetadata(src, tonumber(slot), meta) end)
        return
    end
    pcall(function() exports['qs-inventory']:SetItemMetadata(src, tonumber(slot), meta) end)
end

-- Get all map items from player inventory
local function getPlayerMaps(src)
    local maps = {}
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return maps end
    
    local items = Player.PlayerData.items
    if not items then return maps end
    
    for slot, item in pairs(items) do
        if item and item.name == Config.MapItemName then
            maps[#maps + 1] = {slot = slot, item = item}
        end
    end
    
    return maps
end

-- Generate unique marker ID
local function generateMarkerId()
    return ('mk_%d_%d'):format(os.time(), math.random(1000, 9999))
end

-- ============================================================================
-- EXPORTS
-- ============================================================================

-- Add a marker to all maps in a player's inventory
-- Returns: number of maps updated
local function AddMarkerToPlayer(playerId, markerData)
    if not playerId or not markerData then return 0 end
    if not markerData.name or not markerData.x or not markerData.y then
        print('[dh-maps] AddMarkerToPlayer: Missing required fields (name, x, y)')
        return 0
    end
    
    local maps = getPlayerMaps(playerId)
    if #maps == 0 then return 0 end
    
    local marker = {
        id = generateMarkerId(),
        name = markerData.name,
        x = markerData.x + 0.0,
        y = markerData.y + 0.0,
        z = (markerData.z or 0.0) + 0.0,
        sprite = markerData.sprite or Config.DefaultMarker.sprite,
        color = markerData.color or Config.DefaultMarker.color,
        scale = markerData.scale or Config.DefaultMarker.scale
    }
    
    local updatedCount = 0
    
    for _, mapInfo in ipairs(maps) do
        local item = getItem(playerId, mapInfo.slot)
        if item and item.name == Config.MapItemName then
            local meta = ensureMetadata(item.info or item.metadata or {})
            table.insert(meta.dhMaps.markers, marker)
            setMetadata(playerId, mapInfo.slot, meta)
            updatedCount = updatedCount + 1
        end
    end
    
    -- Notify client to refresh if they have the map open
    TriggerClientEvent('dh-maps:client:markerAdded', playerId, marker)
    
    return updatedCount
end

-- Remove a marker from all maps in a player's inventory by marker name
-- Returns: number of maps updated
local function RemoveMarkerFromPlayer(playerId, markerName)
    if not playerId or not markerName then return 0 end
    
    local maps = getPlayerMaps(playerId)
    if #maps == 0 then return 0 end
    
    local updatedCount = 0
    
    for _, mapInfo in ipairs(maps) do
        local item = getItem(playerId, mapInfo.slot)
        if item and item.name == Config.MapItemName then
            local meta = ensureMetadata(item.info or item.metadata or {})
            local filtered = {}
            local removed = false
            for _, mk in ipairs(meta.dhMaps.markers) do
                if mk.name ~= markerName then 
                    filtered[#filtered + 1] = mk 
                else
                    removed = true
                end
            end
            if removed then
                meta.dhMaps.markers = filtered
                setMetadata(playerId, mapInfo.slot, meta)
                updatedCount = updatedCount + 1
            end
        end
    end
    
    -- Notify client to refresh
    TriggerClientEvent('dh-maps:client:markerRemoved', playerId, markerName)
    
    return updatedCount
end

-- Check if player has a specific marker (by name) on any of their maps
-- Returns: boolean
local function PlayerHasMarker(playerId, markerName)
    if not playerId or not markerName then return false end
    
    local maps = getPlayerMaps(playerId)
    for _, mapInfo in ipairs(maps) do
        local item = getItem(playerId, mapInfo.slot)
        if item and item.name == Config.MapItemName then
            local meta = item.info or item.metadata or {}
            if meta.dhMaps and meta.dhMaps.markers then
                for _, mk in ipairs(meta.dhMaps.markers) do
                    if mk.name == markerName then return true end
                end
            end
        end
    end
    
    return false
end

-- Export the functions
exports('AddMarkerToPlayer', AddMarkerToPlayer)
exports('RemoveMarkerFromPlayer', RemoveMarkerFromPlayer)
exports('PlayerHasMarker', PlayerHasMarker)

-- ============================================================================
-- REGISTER USABLE ITEM
-- ============================================================================

CreateThread(function()
    if GetResourceState('qs-inventory') == 'started' then
        local ok = pcall(function()
            exports['qs-inventory']:CreateUsableItem(Config.MapItemName, function(source, item)
                TriggerClientEvent('dh-maps:client:useMap', source, item)
            end)
        end)
        if ok then print('[dh-maps] Registered via qs-inventory') return end
    end
    QBCore.Functions.CreateUseableItem(Config.MapItemName, function(source, item)
        TriggerClientEvent('dh-maps:client:useMap', source, item)
    end)
    print('[dh-maps] Registered via QBCore')
end)

-- ============================================================================
-- EVENTS
-- ============================================================================

RegisterNetEvent('dh-maps:server:getData', function(slot)
    local src = source
    local item = getItem(src, slot)
    if not item or item.name ~= Config.MapItemName then
        TriggerClientEvent('dh-maps:client:receiveData', src, slot, nil)
        return
    end
    local meta = ensureMetadata(item.info or item.metadata or {})
    setMetadata(src, slot, meta)
    TriggerClientEvent('dh-maps:client:receiveData', src, slot, meta.dhMaps)
end)

RegisterNetEvent('dh-maps:server:addMarker', function(slot, marker)
    local src = source
    local item = getItem(src, slot)
    if not item or item.name ~= Config.MapItemName then return end
    local meta = ensureMetadata(item.info or item.metadata or {})
    table.insert(meta.dhMaps.markers, marker)
    setMetadata(src, slot, meta)
    TriggerClientEvent('dh-maps:client:receiveData', src, slot, meta.dhMaps)
end)

RegisterNetEvent('dh-maps:server:deleteMarker', function(slot, markerId)
    local src = source
    local item = getItem(src, slot)
    if not item or item.name ~= Config.MapItemName then return end
    local meta = ensureMetadata(item.info or item.metadata or {})
    local filtered = {}
    for _, mk in ipairs(meta.dhMaps.markers) do
        if mk.id ~= markerId then filtered[#filtered + 1] = mk end
    end
    meta.dhMaps.markers = filtered
    setMetadata(src, slot, meta)
    TriggerClientEvent('dh-maps:client:receiveData', src, slot, meta.dhMaps)
end)

RegisterNetEvent('dh-maps:server:updateMarker', function(slot, markerId, patch)
    local src = source
    local item = getItem(src, slot)
    if not item or item.name ~= Config.MapItemName then return end
    local meta = ensureMetadata(item.info or item.metadata or {})
    for _, mk in ipairs(meta.dhMaps.markers) do
        if mk.id == markerId then for k, v in pairs(patch) do mk[k] = v end break end
    end
    setMetadata(src, slot, meta)
    TriggerClientEvent('dh-maps:client:receiveData', src, slot, meta.dhMaps)
end)
