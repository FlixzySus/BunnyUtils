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

local base_folder = "D:\\OneDrive\\Desktop\\D4 Lua\\diablo_qqt\\scripts\\BunnyUtils\\"

local function ensure_subfolder(subfolder)
    local path = base_folder .. subfolder .. "\\"
    os.execute("mkdir \"" .. path .. "\"")
    return path
end

local function get_sequential_filename(subfolder, base)
    local folder = ensure_subfolder(subfolder)
    local i = 1
    local filename
    repeat
        filename = string.format("%s%s%d.lua", folder, base, i)
        local f = io.open(filename, "r")
        if f then f:close() i = i + 1 else break end
    until false
    return filename
end

function M.save_path_to_file(start_pos, path, end_pos)
    local filename = get_sequential_filename("Recorded", "RecordedPath")
    local file = io.open(filename, "w")
    if not file then
        console.print("Failed to open file:\n" .. filename)
        return
    end
    file:write("local points = {\n")
    if start_pos then
        file:write(string.format("    vec3(%.6f, %.6f, %.6f),\n", start_pos:x(), start_pos:y(), start_pos:z()))
    end
    for _, pos in ipairs(path) do
        file:write(string.format("    vec3(%.6f, %.6f, %.6f),\n", pos:x(), pos:y(), pos:z()))
    end
    if end_pos then
        file:write(string.format("    vec3(%.6f, %.6f, %.6f),\n", end_pos:x(), end_pos:y(), end_pos:z()))
    end
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

    if gui.elements.recording_toggle:get() then
        if gui.elements.start_btn:get() then
            local ped = get_local_player()
            if ped then
                M.start_position = ped:get_position()
                console.print(string.format("Start: vec3(%.6f, %.6f, %.6f)", M.start_position:x(), M.start_position:y(), M.start_position:z()))
            end
            M.is_recording = true
            M.recorded_path = {}
            M.last_position = nil
            M.last_record_time = os.clock()
            console.print("Recording started...")
        end

        if gui.elements.stop_btn:get() then
            local ped = get_local_player()
            if ped then
                M.end_position = ped:get_position()
                console.print(string.format("End: vec3(%.6f, %.6f, %.6f)", M.end_position:x(), M.end_position:y(), M.end_position:z()))
            end
            M.is_recording = false
            console.print("Recording ended...")
            M.save_path_to_file(M.start_position, M.recorded_path, M.end_position)
            M.recorded_path = {}
        end

        if M.is_recording then
            local ped = get_local_player()
            if ped and ped:is_moving() then
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
    end
end

function M.handle_keypress(key)
    if gui.elements.keybind_toggle:get() and key == gui.elements.manual_keybind:get_key() then
        M.teleport_triggered = true
    end
end

return M
