# DH Maps Paper Map System

DH Maps is an item based map system that allows players to place and manage custom map markers using the GTA pause menu map. Marker data is stored directly inside the map item metadata, allowing markers to persist and travel with the item when dropped, transferred, or stored.

The system was built with qb core and qb inventory in mind but is framework agnostic and can be adapted to other setups with minimal changes.

---

## Features

• Item based access to the pause menu map  
• Custom markers with name icon color and scale  
• Real time marker preview before saving  
• Marker data stored in item metadata  
• Optional restriction that disables the pause menu map without a map item  
• Server synchronized storage  
• Lightweight and optimized  
• Export support for external script integration  

---

## Installation

1. Place the resource in your server resources folder  
2. Add a usable map item to your inventory system  
```lua
paper_map = { name = 'paper_map', label = 'Paper Map', weight = 100, type = 'item', image = 'paper_map.png', unique = true, useable = true, shouldClose = false, description = 'A worn paper map. Marked locations can be written on it.' },
```
3. add provided ```paper_map``` item image into your inventory scripts html/images folder
4. Configure options in `shared/config.lua` to your liking
5. Start the resource

---

## Map Item

The map item can be named anything.  
Set the item name in `Config.MapItemName` inside `shared/config.lua`.

Markers will be stored inside the metadata of this item.

---

## Exports

The following server side exports are available for integration with other scripts.

---

### AddMarkerToPlayer

Adds a marker to every map item owned by the player.

#### Export
```lua
exports['dh-maps']:AddMarkerToPlayer(playerId, markerData)
```

#### Parameters

| Name | Type | Description |
|-----|------|-------------|
| playerId | number | Server ID of the player |
| markerData | table | Marker configuration |

#### Marker Data Structure
```lua
{
    name   = "Hidden Camp",
    sprite = 417,
    color  = 1,
    scale  = 1.0,
    coords = vector3(123.4, 456.7, 32.1)
}
```

#### Example
```lua
RegisterCommand('givecampmarker', function(source)
    exports['dh-maps']:AddMarkerToPlayer(source, {
        name   = "Hidden Camp",
        sprite = 417,
        color  = 1,
        scale  = 1.0,
        coords = vector3(123.4, 456.7, 32.1)
    })
end)
```

---

### RemoveMarkerFromPlayer

Removes markers with a matching name from all map items owned by the player.

#### Export
```lua
exports['dh-maps']:RemoveMarkerFromPlayer(playerId, markerName)
```

#### Parameters

| Name | Type | Description |
|-----|------|-------------|
| playerId | number | Server ID of the player |
| markerName | string | Name of the marker to remove |

#### Example
```lua
RegisterCommand('removecampmarker', function(source)
    exports['dh-maps']:RemoveMarkerFromPlayer(source, "Hidden Camp")
end)
```

---

### PlayerHasMarker

Checks if a player owns a map item containing a marker with a matching name.

#### Export
```lua
exports['dh-maps']:PlayerHasMarker(playerId, markerName)
```

#### Returns

| Type | Description |
|------|-------------|
| boolean | True if the player owns the marker |

#### Example
```lua
RegisterCommand('checkmarker', function(source)
    local hasMarker = exports['dh-maps']:PlayerHasMarker(source, "Hidden Camp")

    if hasMarker then
        print("Player owns the marker")
    else
        print("Marker not found")
    end
end)
```

---

## Notes

• Marker names are used as identifiers when removing or checking markers  
• Markers persist through restarts as they are stored in item metadata  
• Markers added through exports are immediately synced to the client  
• Multiple map items can exist per player  

---

## Configuration

All settings can be found in `shared/config.lua`.

This includes marker limits, UI behavior, animation options, and pause menu restrictions.

---

## Gallery

<img width="1920" height="1080" alt="Desktop Screenshot 2025 12 12 - 05 01 42 50" src="https://github.com/user-attachments/assets/0113abd5-008b-4122-bd85-c03b8f6c6242" />
<img width="1920" height="1080" alt="Desktop Screenshot 2025 12 12 - 05 01 27 70" src="https://github.com/user-attachments/assets/5bd524cb-216b-4347-998f-4989f39d4fb8" />
<img width="1920" height="1080" alt="Desktop Screenshot 2025 12 12 - 05 00 59 97" src="https://github.com/user-attachments/assets/42e15168-3f26-44e3-899c-3c41cce5eae7" />
<img width="1920" height="1080" alt="Desktop Screenshot 2025 12 12 - 05 00 54 98" src="https://github.com/user-attachments/assets/896b5a85-fa1a-4d0b-98cd-0602b88e22aa" />


## Support

This resource is intended for intermediate server owners and developers.  
Support is provided for installation and configuration issues.
