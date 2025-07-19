# BunnyUtils
Utility Script for QQT

# Teleport & Path Recorder Module

## 🛰️ Teleport Features
- **Enable Teleport Keybind** – `checkbox` to toggle use of a hotkey for teleporting  
- **Teleport Key** – `keybind` picker to assign which key triggers teleport  
- **Waypoint Selector** – `combo_box` dropdown listing all predefined waypoints  
- **Teleport Button** – `button` you click to instantly teleport to the selected waypoint  

## 📸 Path Recorder Features
- **Enable Path Recording** – `checkbox` to enable/disable recording mode  
- **Start Path** – `button` to begin capturing your movement (records at set sample delay)  
- **End Path** – `button` to stop recording and automatically save the path as a `.lua` file with `vec3` coordinates  
  - Recorded path saves to folder `Recorded` in script location (creates the folder upon saving a path)  
  - Paths save in format of ↓ (used in Helltide scripts)  

## Example
```
local points = {
    vec3:new(216.226562, -601.409180, 6.959961),
    vec3:new(215.982910, -605.318481, 7.081403),
    vec3:new(216.792801, -601.609680, 7.002403),
    vec3:new(217.345123, -600.123456, 7.123456),
    vec3:new(218.000000, -599.000000, 7.000000),
}

return points
```

# Required
Inside of `logic.lua` change the `local base_folder` to match your path to inside the BunnyUtils script folder default is set to `C:\\diablo_qqt\\scripts\\BunnyUtils\\`
