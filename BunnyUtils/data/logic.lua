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

-- Memorized plugin root
local plugin_root = (function()
    local root = string.gmatch(package.path, '.*?\\?')()
    return root:gsub('%?', '')
end)()

local base_folder = plugin_root .. "Recorder\\"

local function ensure_folder(path)
    local f = io.open(path .. "dummy.txt", "a")
    if f then f:close() os.remove(path .. "dummy.txt") return end
    os.execute('mkdir "' .. path .. '"')
end

ensure_folder(base_folder)

local function get_sequential_filename(base)
    local i, file, filename = 1
    repeat
        filename = string.format("%s%s%d.lua", base_folder, base, i)
        file = io.open(filename, "r")
        if file then file:close() i = i + 1 end
    until not file
    return filename
end

function M.save_path_to_file(start_pos, path, end_pos)
    local filename = get_sequential_filename("RecordedPath")
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

function M.handle_update()
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
