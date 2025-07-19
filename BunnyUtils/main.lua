local gui = require("gui")
local logic = require("data.logic")

on_update(function()
    logic.handle_update()
end)

on_key_press(function(key)
    logic.handle_keypress(key)
end)

on_update(gui.pulse)
on_render_menu(gui.render)
