local plugin_label = "BunnyUtils"

local gui = {}
gui.elements = {}
gui.root = tree_node:new(0)
gui.subtree_teleport = tree_node:new(1)
gui.subtree_recorder = tree_node:new(2)
gui.subtree_console = tree_node:new(3)

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

-- CONSOLE GUI
gui.elements.suppress_console_checkbox = checkbox:new(false, get_hash("console_suppressor_qqt_suppress_console"))
gui.elements.console_record_toggle = checkbox:new(false, get_hash("console_suppressor_qqt_record_logs"))

-- Waypoints
gui.waypoints_enum = waypoint_data.waypoints_enum
gui.waypoints_ids = waypoint_data.waypoints_ids

function gui.render()
    if not gui.root:push(plugin_label) then return end

    if gui.subtree_teleport:push("Teleport") then
        gui.elements.keybind_toggle:render("Enable Teleport Keybind", "Use a key to teleport to selected waypoint")
        gui.elements.manual_keybind:render("Teleport Key", "Press to set keybind")
        gui.elements.waypoint_selector:render("Waypoint", gui.waypoints_enum, "Choose destination")
        gui.elements.teleport_button:render("Teleport Button", "Teleport to selected waypoint", 0.0)
        gui.subtree_teleport:pop()
    end

    if gui.subtree_recorder:push("Path Recorder") then
        gui.elements.recording_toggle:render("Enable Path Recording", "Enable to record player routes")
        if gui.elements.recording_toggle:get() then
            gui.elements.start_btn:render("Start Path", "Begin recording path", 0, button_click.lmb)
            gui.elements.stop_btn:render("End Path", "Stop and save path", 0, button_click.lmb)
        end
        gui.subtree_recorder:pop()
    end

    if gui.subtree_console:push("Console Options") then
        gui.elements.suppress_console_checkbox:render("Suppress Console Logs", "Toggle on to disable console logs / Toggle off to turn back on")
        gui.elements.console_record_toggle:render("Record Console Logs", "Toggle on to start recording logs / Toggle off to save logs")
        gui.subtree_console:pop()
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
