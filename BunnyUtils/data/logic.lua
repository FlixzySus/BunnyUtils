local gui = require("gui")

local M = {}

-- Teleport
M.teleport_triggered = false
M.teleport_delay_timer = nil
M.teleport_target_name = nil

-- Recorder
M.is_recording = false
M.recorded_path = {}
M.last_position = nil
M.last_record_time = 0
M.sample_delay = 0.1
M.start_position = nil
M.end_position = nil

-- Console Suppressor (global-safe)
_G.__original_console_print = _G.__original_console_print or console.print
_G.__original_console_print_full = _G.__original_console_print_full or console.print_full

local silent_print = function(...) end
local silent_print_full = function(...) end
local suppress_print = false

local function apply_suppress_state()
    if suppress_print then
        console.print = silent_print
        console.print_full = silent_print_full
    else
        console.print = _G.__original_console_print
        console.print_full = _G.__original_console_print_full
    end
end

-- Apply on load
suppress_print = gui.elements.suppress_console_checkbox:get()
apply_suppress_state()

-- Memoized plugin root
local plugin_root = (function()
    local root = string.gmatch(package.path, '.*?\\?')()
    return root:gsub('%?', '')
end)()

local base_folder = plugin_root .. "Recorder\\"
local log_folder = plugin_root .. "Logs\\"

local function ensure_folder(path)
    local f = io.open(path .. "dummy.txt", "a")
    if f then f:close() os.remove(path .. "dummy.txt") return end
    os.execute('mkdir "' .. path .. '"')
end

ensure_folder(base_folder)
ensure_folder(log_folder)

local function get_sequential_path_filename()
    local base_name = "BunnyUtils - Path"
    local ext = ".lua"
    local filename = base_folder .. base_name .. ext
    local i = 2

    while io.open(filename, "r") do
        filename = base_folder .. base_name .. "(" .. i .. ")" .. ext
        i = i + 1
    end

    return filename
end

function M.save_path_to_file(start_pos, path, end_pos)
    local filename = get_sequential_path_filename()
    local file = io.open(filename, "w")
    if not file then
        console.print("Failed to open file:\n" .. filename)
        return
    end

    file:write("local points = {\n")
    local function write_vec(pos)
        file:write(string.format("    vec3(%.6f, %.6f, %.6f),\n", pos:x(), pos:y(), pos:z()))
    end

    if start_pos then write_vec(start_pos) end
    for _, pos in ipairs(path) do write_vec(pos) end
    if end_pos then write_vec(end_pos) end

    file:write("}\n\nreturn points\n")
    file:close()
    console.print("Path saved: " .. filename)
end

function M.perform_teleport()
    local idx = gui.elements.waypoint_selector:get() + 1
    local name = gui.waypoints_enum[idx]
    local id = gui.waypoints_ids[name]

    if id then
        teleport_to_waypoint(id)
        M.teleport_target_name = name
        M.teleport_delay_timer = os.clock() + 13.0
    else
        console.print("Invalid waypoint.")
    end
end

-- Log recording system
local console_log_history = {}
local recording_logs = gui.elements.console_record_toggle:get()

local function capture_log(...)
    local msg = table.concat({...}, " ")
    table.insert(console_log_history, { time = os.time(), text = msg })
end

local function capture_log_full(delay, interval, ...)
    local msg = table.concat({...}, " ")
    table.insert(console_log_history, { time = os.time(), delay = delay, interval = interval, text = msg })
end

-- Override console functions
console.print = function(...)
    if gui.elements.console_record_toggle:get() then
        capture_log(...)
    end
    if not gui.elements.suppress_console_checkbox:get() then
        _G.__original_console_print(...)
    end
end

console.print_full = function(delay, interval, ...)
    if gui.elements.console_record_toggle:get() then
        capture_log_full(delay, interval, ...)
    end
    if not gui.elements.suppress_console_checkbox:get() then
        _G.__original_console_print_full(delay, interval, ...)
    end
end

local function save_console_log_to_file()
    -- base name without extension
    local base_name = "BunnyUtils - Log"
    local ext = ".json"
    local filename = log_folder .. base_name .. ext
    local i = 2

    -- increment until unused file name is found
    while io.open(filename, "r") do
        filename = log_folder .. base_name .. "(" .. i .. ")" .. ext
        i = i + 1
    end

    local file = io.open(filename, "w")
    if file then
        local buffer = {"["}
        for i, entry in ipairs(console_log_history) do
            local line = string.format('"%s"', entry.text:gsub('"', '\\"'))
            table.insert(buffer, line .. (i < #console_log_history and "," or ""))
        end
        table.insert(buffer, "]")
        file:write(table.concat(buffer, "\n"))
        file:close()
        console.print("Saved console log to: " .. filename)
    else
        console.print("Failed to save console log.")
    end
end

function M.handle_update()
    -- Console Suppressor toggle
    local new_state = gui.elements.suppress_console_checkbox:get()
    if new_state ~= suppress_print then
        suppress_print = new_state
        apply_suppress_state()
    end

    -- Console Recorder toggle
    local now_recording = gui.elements.console_record_toggle:get()
    if recording_logs and not now_recording then
        save_console_log_to_file()
        console_log_history = {}
    end
    recording_logs = now_recording

    -- Teleport button logic
    if gui.elements.teleport_button:get() then
        M.teleport_triggered = true
    end

    if M.teleport_triggered then
        M.teleport_triggered = false
        M.perform_teleport()
    end

    if M.teleport_delay_timer and os.clock() >= M.teleport_delay_timer then
        console.print("Teleported to:", M.teleport_target_name)
        M.teleport_delay_timer = nil
        M.teleport_target_name = nil
    end

    -- Path Recorder logic
    if not gui.elements.recording_toggle:get() then return end

    local ped = get_local_player()
    if not ped then return end

    if gui.elements.start_btn:get() then
        M.start_position = ped:get_position()
        console.print(string.format("Start: vec3(%.6f, %.6f, %.6f)", M.start_position:x(), M.start_position:y(), M.start_position:z()))
        M.is_recording = true
        M.recorded_path = {}
        M.last_position = nil
        M.last_record_time = os.clock()
        console.print("Recording started...")
    end

    if gui.elements.stop_btn:get() then
        M.end_position = ped:get_position()
        console.print(string.format("End:   vec3(%.6f, %.6f, %.6f)", M.end_position:x(), M.end_position:y(), M.end_position:z()))
        M.is_recording = false
        M.save_path_to_file(M.start_position, M.recorded_path, M.end_position)
        M.recorded_path = {}
    end

    if M.is_recording and ped:is_moving() then
        local now = os.clock()
        if now - M.last_record_time >= M.sample_delay then
            local pos = ped:get_position()
            if not M.last_position or not pos:equals(M.last_position) then
                table.insert(M.recorded_path, pos)
                M.last_position = pos
                M.last_record_time = now
            end
        end
    end
end

function M.handle_keypress(key)
    if gui.elements.keybind_toggle:get() and key == gui.elements.manual_keybind:get_key() then
        M.teleport_triggered = true
    end
end

return M
