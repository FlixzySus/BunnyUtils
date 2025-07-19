local plugin_label = "BunnyUtils"

local gui = {}
gui.elements = {}
gui.root = tree_node:new(0)
gui.subtree_teleport = tree_node:new(1)
gui.subtree_recorder = tree_node:new(2)

local waypoint_data = require("data.enums")

-- TELEPORT GUI
gui.elements.teleport_button = button:new(get_hash(plugin_label .. "_teleport_button"))
gui.elements.waypoint_selector = combo_box:new(0, get_hash(plugin_label .. "_waypoint_selector"))
gui.elements.keybind_toggle = checkbox:new(false, get_hash(plugin_label .. "_keybind_enabled"))
gui.elements.manual_keybind = keybind:new(0x0A, true, get_hash(plugin_label .. "_manual_keybind"))
local keybind_data = checkbox:new(false, get_hash(plugin_label .. "_keybind_data"))

-- RECORDER GUI
gui.elements.recording_toggle = checkbox:new(false, get_hash(plugin_label .. "_recording_toggle"))
gui.elements.start_btn = button:new(get_hash(plugin_label .. "_record_start"))
gui.elements.stop_btn = button:new(get_hash(plugin_label .. "_record_stop"))

-- Waypoints from Enums
gui.waypoints_enum = waypoint_data.waypoints_enum
gui.waypoints_ids = waypoint_data.waypoints_ids

function gui.render()
    if not gui.root:push(plugin_label) then return end

    -- TELEPORT SUBTREE
    if gui.subtree_teleport:push("Teleport") then
        gui.elements.keybind_toggle:render("Enable Teleport Keybind", "Use a key to teleport to selected waypoint")
        gui.elements.manual_keybind:render("Teleport Key", "Press to set keybind")
        gui.elements.waypoint_selector:render("Waypoint", gui.waypoints_enum, "Choose destination")
        gui.elements.teleport_button:render("Teleport Button", "Teleport to selected waypoint", 0.0)
        gui.subtree_teleport:pop()
    end

    -- RECORDER SUBTREE
    if gui.subtree_recorder:push("Path Recorder") then
        gui.elements.recording_toggle:render("Enable Path Recording", "Enable to record player routes")
        if gui.elements.recording_toggle:get() then
            gui.elements.start_btn:render("Start Path", "Begin recording path", 0, button_click.lmb)
            gui.elements.stop_btn:render("End Path", "Stop and save path", 0, button_click.lmb)
        end
        gui.subtree_recorder:pop()
    end

    gui.root:pop()
end

function gui.pulse()
    if PERSISTENT_MODE ~= nil and PERSISTENT_MODE ~= false then
        if keybind_data:get() ~= (gui.elements.keybind_toggle:get_state() == 1) then
            keybind_data:set(gui.elements.keybind_toggle:get_state() == 1)
        end
    end
end

return gui
