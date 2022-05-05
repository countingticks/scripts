-- INTERFACE
local menu = fatality.menu
local render = fatality.render
local callback = fatality.callbacks
local input = fatality.input
local config = fatality.config
local globals = csgo.interface_handler:get_global_vars()
local entity_list = csgo.interface_handler:get_entity_list()
local color = csgo.color

-- LOCALS
local tick = 0
local count = 0

local check = false
local invert_state = false

local local_player
local anti_aim
local invert
local jitter
local state

-- MENU 
local aa_state = {
    [0] = {config = config:add_item("aa_stand", 0),     name = "Standing"},
    [1] = {config = config:add_item("aa_move", 0),      name = "Moving"},
    [2] = {config = config:add_item("aa_slow", 0),      name = "Slow walking"},
    [3] = {config = config:add_item("aa_crouch", 0),    name = "Crouching"},
    [4] = {config = config:add_item("aa_air", 0),       name = "Air"}
}

local aa_extra = {
    [0] = {config = config:add_item("aa_jitter", 0),    name = "Jitter"}
}

local aa_invert = {
    [0] = {key = 0x01,  name = "Mouse 1"},
    [1] = {key = 0x02,  name = "Mouse 2"},
    [2] = {key = 0x04,  name = "Mouse 3"},
    [3] = {key = 0x05,  name = "Mouse 4"},
    [4] = {key = 0x06,  name = "Mouse 5"},
    [5] = {key = 0x10,  name = "Shift"},
    [6] = {key = 0x11,  name = "Ctrl"},
    [7] = {key = 0x12,  name = "Alt"},
    [8] = {key = 0x51,  name = "Q"},
    [9] = {key = 0x57,  name = "W"},
    [10] = {key = 0x45, name = "E"},
    [11] = {key = 0x52, name = "R"},
    [12] = {key = 0x54, name = "T"},
    [13] = {key = 0x59, name = "Y"},
    [14] = {key = 0x55, name = "U"},
    [15] = {key = 0x49, name = "I"},
    [16] = {key = 0x4F, name = "O"},
    [17] = {key = 0x50, name = "P"},
    [18] = {key = 0x41, name = "A"},
    [19] = {key = 0x53, name = "S"},
    [20] = {key = 0x44, name = "D"},
    [21] = {key = 0x46, name = "F"},
    [22] = {key = 0x47, name = "G"},
    [23] = {key = 0x48, name = "H"},
    [24] = {key = 0x4A, name = "J"},
    [25] = {key = 0x4B, name = "K"},
    [26] = {key = 0x4C, name = "L"},
    [27] = {key = 0x5A, name = "Z"},
    [28] = {key = 0x58, name = "X"},
    [29] = {key = 0x43, name = "C"},
    [30] = {key = 0x56, name = "V"},
    [31] = {key = 0x42, name = "B"},
    [32] = {key = 0x4E, name = "N"},
    [33] = {key = 0x4D, name = "M"},
}

local menu_items = {
    state_item = config:add_item("aa_state", 0),
    state_multi = menu:add_multi_combo("Anti-aim States", "RAGE", "ANTI-AIM", "Angles", state_item),

    extra_item = config:add_item("aa_extra", 0),
    extra_multi = menu:add_multi_combo("Anti-aim Extra", "RAGE", "ANTI-AIM", "Angles", extra_item),
}

local invert_item = config:add_item("aa_invert", 0)
local invert_combo = menu:add_combo("Invert Key", "RAGE", "ANTI-AIM", "Angles", invert_item)

local roll_item = config:add_item("aa_roll", 0)
local roll_box = menu:add_checkbox("Bypass Anti-roll", "RAGE", "ANTI-AIM", "Angles", roll_item)

for i, item in pairs(aa_state) do
    menu_items.state_multi:add_item(item.name, item.config)
end

for i, item in pairs(aa_extra) do
    menu_items.extra_multi:add_item(item.name, item.config)
end

for i, item in pairs(aa_invert) do
    invert_combo:add_item(item.name, invert_item)
end

-- REFERENCE
local reference = {
    yaw = menu:get_reference("RAGE", "ANTI-AIM", "Angles", "Yaw add"),
    yaw_add = menu:get_reference("RAGE", "ANTI-AIM", "Angles", "Add"),
    spin = menu:get_reference("RAGE", "ANTI-AIM", "Angles", "Spin"),
    jitter = menu:get_reference("RAGE", "ANTI-AIM", "Angles", "Jitter"),
    fake = menu:get_reference("RAGE", "ANTI-AIM", "Desync", "Fake amount"),
    fake_flip = menu:get_reference("RAGE", "ANTI-AIM", "Desync", "Flip fake with jitter"),
    compensate_angle = menu:get_reference("RAGE", "ANTI-AIM", "Desync", "Compensate angle"),
    freestand_fake = menu:get_reference("RAGE", "ANTI-AIM", "Desync", "Freestand fake"),
    leg_slide = menu:get_reference("RAGE", "ANTI-AIM", "Desync", "Leg slide"),
    roll = menu:get_reference("RAGE", "ANTI-AIM", "Desync", "Roll lean"),
    lean = menu:get_reference("RAGE", "ANTI-AIM", "Desync", "Lean amount"),
    ensure_lean = menu:get_reference("RAGE", "ANTI-AIM", "Desync", "Ensure lean"),
    lean_flip = menu:get_reference("RAGE", "ANTI-AIM", "Desync", "Flip lean with jitter"),
    slow_walk = menu:get_reference("MISC", "MOVEMENT", "Movement", "Slide"),
    fake_duck = menu:get_reference("MISC", "MOVEMENT", "Movement", "Fake duck"),

    override = menu:get_reference("RAGE", "ANTI-AIM", "Angles", "Antiaim override"),
    override_left = menu:get_reference("RAGE", "ANTI-AIM", "Angles", "Left"),
    override_right = menu:get_reference("RAGE", "ANTI-AIM", "Angles", "Right"),

    doubletap = menu:get_reference("Rage", "Aimbot", "Aimbot", "Double tap"),
    hideshot = menu:get_reference("Rage", "Aimbot", "Aimbot", "Hide shot"),
    freestand = menu:get_reference("Rage", "Anti-aim", "Angles", "Freestand")
}

-- KEYBINDS
local key = {
    W = 0x57,
    A = 0x41,
    S = 0x53,
    D = 0x44,
    E = 0x45,
    CTRL = 0x11,
    SHIFT = 0x10,
    SPACE = 0x20,
    INVERT = 0x58
}

-- INVERTS THE ANTIAIM SIDE ON KEY PRESSED
local invert_antiaim = function(key)
    if input:is_key_down(key) then
        if check then 
            invert_state = not invert_state
            check = false
        end
    else
        check = true
    end

    return invert_state
end

-- UPDATES KEYBIND SINCE WE DONT WANNA UPDATE IT EVERY FRAME
local invert_key_update = function()
    for i, item in pairs(aa_invert) do 
        if invert_item:get_int() == i then 

            return item.key
        end
    end
end

-- HERE WE SET OUR ANTIAIM SETTING
local update_antiaim = function()
    anti_aim = {
        ["global"] = {
            yaw = true,
            yaw_add = function ()
                return 0
            end,
            fake = function ()
                return invert and -80 or 80
            end,
            compensate_angle = 0,
            ensure_lean = false
        },

        ["standing"] = {
            yaw = true,
            yaw_add = function ()
                if aa_extra[0].config:get_bool() then 
                    return jitter and 24 or 7
                else
                    return invert and -3 or 8
                end
            end,
            fake = function ()
                if aa_extra[0].config:get_bool() then 
                    return jitter and 57 or -68
                else
                    if invert then 
                        return jitter and -78 or -74 
                    else 
                        return jitter and 90 or 86
                    end
                end
            end,
            compensate_angle = 0,
            ensure_lean = false
        },

        ["moving"] = {
            yaw = true,
            yaw_add = function ()
                if aa_extra[0].config:get_bool() then 
                    return jitter and 28 or -9
                else
                    return invert and -3 or 8
                end
            end,
            fake = function ()
                if aa_extra[0].config:get_bool() then 
                    return jitter and 57 or -68
                else
                    if invert then 
                        return jitter and -78 or -74 
                    else 
                        return jitter and 90 or 86
                    end
                end
            end,
            compensate_angle = 0,
            ensure_lean = false
        },

        ["slow walking"] = {
            yaw = true,
            yaw_add = function ()
                if aa_extra[0].config:get_bool() then 
                    return jitter and 24 or 7
                else
                    return invert and -3 or 8
                end
            end,
            fake = function ()
                if aa_extra[0].config:get_bool() then 
                    return jitter and 57 or -68
                else
                    if invert then 
                        return jitter and -78 or -74 
                    else 
                        return jitter and 90 or 86
                    end
                end
            end,
            compensate_angle = 25,
            ensure_lean = true
        },

        ["crouching"] = {
            yaw = true,
            yaw_add = function ()
                if aa_extra[0].config:get_bool() then 
                    return jitter and 24 or 7
                else
                    return invert and -3 or 8
                end
            end,
            fake = function ()
                if aa_extra[0].config:get_bool() then 
                    return jitter and 57 or -68
                else
                    if invert then 
                        return jitter and -78 or -74 
                    else 
                        return jitter and 90 or 86
                    end
                end
            end,
            compensate_angle = 0,
            ensure_lean = true
        },

        ["air"] = {
            yaw = true,
            yaw_add = function ()
                if aa_extra[0].config:get_bool() then 
                    return jitter and 24 or 7
                else
                    return invert and -3 or 8
                end
            end,
            fake = function ()
                if aa_extra[0].config:get_bool() then 
                    return jitter and 57 or -68
                else
                    if invert then 
                        return jitter and -78 or -74 
                    else 
                        return jitter and 90 or 86
                    end
                end
            end,
            compensate_angle = 0,
            ensure_lean = false
        }
    }
end

-- HERE WE APPLY OUR ANTIAIM SETTING AND DO MORE MAGIC STUFF
local apply_antiaim = function()
    
    local_player = entity_list:get_localplayer()
    if local_player == nil then 
        return
    end

    if not local_player:is_alive() then
        return
    end
    
    update_antiaim()
    jitter = (globals.tickcount % 4 >= 2 and not input:is_key_down(key.E)) and true or false
    invert = not aa_extra[0].config:get_bool() and invert_antiaim(invert_key_update())

    local jumping = input:is_key_down(key.SPACE)
    local crouching = input:is_key_down(key.CTRL) or reference.fake_duck:get_bool()
    local slow_walking = reference.slow_walk:get_bool()
    local moving = false

    if input:is_key_down(key.W) or input:is_key_down(key.A) or input:is_key_down(key.S) or input:is_key_down(key.D) then 
        tick = tick + 1 
        moving = tick > 150 and true or false
    else
        tick = 0
    end

    if jumping then 
        state = aa_state[4].config:get_bool() and "air" or "global"
    elseif crouching then 
        state = aa_state[3].config:get_bool() and "crouching" or "global"
    elseif slow_walking then 
        state = aa_state[2].config:get_bool() and "slow walking" or "global"
    elseif moving then 
        state = aa_state[1].config:get_bool() and "moving" or "global"
    else 
        state = aa_state[0].config:get_bool() and "standing" or "global"
    end

    local stack = anti_aim[state]
    reference.yaw:set_bool(stack.yaw)
    reference.yaw_add:set_int(stack.yaw_add())
    reference.fake:set_int(stack.fake())
    reference.compensate_angle:set_int(stack.compensate_angle)
    reference.roll:set_int(roll_item:get_bool() and (jumping and 0 or 2) or 2)
    reference.ensure_lean:set_bool(stack.ensure_lean)
    
end

-- TEXT OUTLINE CUZ FATALITY'S ONE IS SHIT
local text_outline = function(font, x, y, text, color, outline_alpha)

    render:text(font, x - 1, y - 1, text, csgo.color(0,0,0,outline_alpha))
    render:text(font, x - 1, y, text, csgo.color(0,0,0,outline_alpha))
    render:text(font, x - 1, y + 1, text, csgo.color(0,0,0,outline_alpha))

    render:text(font, x, y - 1, text, csgo.color(0,0,0,outline_alpha))
    render:text(font, x, y + 1, text, csgo.color(0,0,0,outline_alpha))

    render:text(font, x + 1, y - 1, text, csgo.color(0,0,0,outline_alpha))
    render:text(font, x + 1, y, text, csgo.color(0,0,0,outline_alpha))
    render:text(font, x + 1, y + 1, text, csgo.color(0,0,0,outline_alpha))

    render:text(font, x, y, text, color)

end

local lerp = function(a, b, percentage) 
    return a + (b - a) * percentage 
end

local indicators = {
    [0] = {name = "doubletap", alpha = 0, offset = 0},
    [1] = {name = "hide shot", alpha = 0, offset = 0},
    [2] = {name = "freestand", alpha = 0, offset = 0}
}

-- FONTS
local title_font = render:create_font("Verdana Bold", 17, 500, false)
local text_font = render:create_font("Tahoma", 14, 500, false)
local arrow_font = render:create_font("ActaSymbolsW95-Arrows", 20, 500, false)

-- RENDER INDICATORS
local draw = function()

    if local_player == nil then 
        return
    end

    if not local_player:is_alive() then
        return
    end

    -- SCREEN SIZE
    local screen_size = render:screen_size()
    local center_x, center_y = screen_size.x / 2, screen_size.y / 2

    -- SCRIPT LOCALS
    local name = "delusion"
    local name_size = render:text_size(title_font, name)
    local name_spacing = 0

    -- DEBUG
    text_outline(text_font, 60, center_y - 40, string.format("Antiaim: side_info -> %s", aa_extra[0].config:get_bool() and "jitter" or (invert and "1" or "0")), color(150, 130, 200, 255), 255)
    text_outline(text_font, 60, center_y - 25, string.format("L_Player: state_info -> %s", state), color(180, 200, 170, 255), 255)

    -- SCRIPT NAME
    for i = 1, #name do  
        local char = string.sub(name, i, i) 
        local pulse = math.floor(math.sin(math.abs(-3.14 + (globals.curtime + i / 10) * 0.5 % (3.14 * 2))) * 255)

        render:text(title_font, center_x - name_size.x / 2 + name_spacing + 1, center_y + 20 + 1, char, csgo.color(0,0,0,255))
        render:text(title_font, center_x - name_size.x / 2 + name_spacing, center_y + 20, char, csgo.color(89,119,239,255))
        render:text(title_font, center_x - name_size.x / 2 + name_spacing, center_y + 20, char, csgo.color(255,255,255,pulse))

        name_spacing = name_spacing + render:text_size(title_font, char).x
    end
    
    -- ADDITIONAL IND
    local offset = 25
    for i, item in pairs(indicators) do

        local value = (i == 0 and reference.doubletap:get_bool()) or (i == 1 and reference.hideshot:get_bool()) or (i == 2 and reference.freestand:get_bool()) or nil

        indicators[i].alpha = value and lerp(indicators[i].alpha, 255, 0.3) or lerp(indicators[i].alpha, 0, 0.3)
        indicators[i].offset = value and lerp(indicators[i].offset, 255, 0.1) or lerp(indicators[i].offset, 0, 0.1)
        
        if item.offset > 250 then 
            indicators[i].offset = 255
        end

        local size = render:text_size(text_font, indicators[i].name)
        offset = offset + (value and 3 or 0) + 12 * (math.floor(item.offset) / 255)

        text_outline(text_font, center_x - size.x / 2, center_y + offset, item.name, color(255,255,255,math.floor(item.alpha)), math.floor(item.alpha))     
    end

    -- ARROW
    render:rect_filled(center_x - 1 - 45, center_y - 11, 2, 22, (invert or aa_extra[0].config:get_bool()) and color(175,255,100,255) or color(163,160,163,255))
    render:rect_filled(center_x - 1 + 45, center_y - 11, 2, 22, (not invert or aa_extra[0].config:get_bool()) and color(175,255,100,255) or color(163,160,163,255))

    render:text(arrow_font, center_x - (render:text_size(arrow_font, "Q").x / 2) - 59, center_y - (render:text_size(arrow_font, "Q").y / 2), "Q", (reference.override:get_bool() and reference.override_left:get_bool()) and color(89,119,239,255) or color(163,160,163,35))
    render:text(arrow_font, center_x - (render:text_size(arrow_font, "Q").x / 2) + 59, center_y - (render:text_size(arrow_font, "Q").y / 2), "R", (reference.override:get_bool() and reference.override_right:get_bool()) and color(89,119,239,255) or color(163,160,163,35))
end

callback:add("paint", apply_antiaim)
callback:add("paint", draw)
