local engine_client= csgo.interface_handler:get_engine_client()
local entity_list = csgo.interface_handler:get_entity_list()
local menu= fatality.menu
local render= fatality.render
local input= fatality.input
local config = fatality.config
local callbacks = fatality.callbacks
local fatalMath = fatality.math

print ("lua made by bogdan#0007")

local silent = csgo.color(255,255,255,255)
local doubletap = csgo.color(255,255,255,255)
local fallback = csgo.color(255,255,255,255)

local blue = colorinactiv

local screensize = render:screen_size()

local autoSilent = config:get_weapon_setting( "autosniper", "silent")
local autoDoubletap = config:get_weapon_setting( "autosniper", "double_tap")
local autoFallback =  config:get_weapon_setting( "autosniper", "fallback_mode")

local awpSilent = config:get_weapon_setting( "awp", "silent")
local awpDoubletap = config:get_weapon_setting( "awp", "double_tap")
local awpFallback = config:get_weapon_setting( "awp", "fallback_mode")

local scoutSilent = config:get_weapon_setting( "scout", "silent")
local scoutDoubletap = config:get_weapon_setting( "scout", "double_tap")
local scoutFallback = config:get_weapon_setting( "scout", "fallback_mode")

local heavyPistolSilent = config:get_weapon_setting( "heavy_pistol", "silent")
local heavyPistolDoubletap = config:get_weapon_setting( "heavy_pistol", "double_tap")
local heavyPistolFallback = config:get_weapon_setting( "heavy_pistol", "fallback_mode")

local pistolSilent = config:get_weapon_setting( "pistol", "silent")
local pistolDoubletap = config:get_weapon_setting( "pistol", "double_tap")
local pistolFallback = config:get_weapon_setting( "pistol", "fallback_mode")

local otherSilent = config:get_weapon_setting( "other", "silent")
local otherDoubletap = config:get_weapon_setting( "other", "double_tap")
local otherFallback = config:get_weapon_setting( "other", "fallback_mode")

local stand_pitch_ref = menu:get_reference("RAGE", "ANTI-AIM", "Standing", "Pitch")
local stand_yaw_ref = menu:get_reference("RAGE", "ANTI-AIM", "Standing", "Yaw")
local stand_add1_ref = menu:get_reference("RAGE", "ANTI-AIM", "Standing", "Add")
local stand_dir_ref = menu:get_reference("RAGE", "ANTI-AIM", "Standing", "Fake amount")
local stand_add_ref = menu:get_reference("RAGE", "ANTI-AIM", "Standing", "Fake type")
local stand_at_target_ref = menu:get_reference("RAGE", "ANTI-AIM", "Standing", "At Fov Target")
local stand_enable_yaw_ref = menu:get_reference("RAGE", "ANTI-AIM", "Standing", "Yaw add")
local stand_freestand_ref = menu:get_reference("RAGE", "ANTI-AIM", "Standing", "Freestand")
local stand_freestand_fake_ref = menu:get_reference("RAGE", "ANTI-AIM", "Standing", "Freestand fake")
local stand_lag_ref = menu:get_reference("RAGE", "ANTI-AIM", "Standing", "Fake lag")
local stand_amount_lag_ref = menu:get_reference("RAGE", "ANTI-AIM", "Standing", "Base amount")
local stand_spin_ref = menu:get_reference("RAGE", "ANTI-AIM", "Standing", "Spin")
local stand_jitter_ref = menu:get_reference("RAGE", "ANTI-AIM", "Standing", "Jitter")
local stand_jitter_range_ref = menu:get_reference("RAGE", "ANTI-AIM", "Standing", "Range")

local move_pitch_ref = menu:get_reference("RAGE", "ANTI-AIM", "Moving", "Pitch")
local move_yaw_ref = menu:get_reference("RAGE", "ANTI-AIM", "Moving", "Yaw")
local move_enable_yaw_ref = menu:get_reference("RAGE", "ANTI-AIM", "Moving", "Yaw add")
local move_add1_ref = menu:get_reference("RAGE", "ANTI-AIM", "Moving", "Add")
local move_dir_ref = menu:get_reference("RAGE", "ANTI-AIM", "Moving", "Fake amount")
local move_add_ref = menu:get_reference("RAGE", "ANTI-AIM", "Moving", "Fake type")
local move_at_target_ref = menu:get_reference("RAGE", "ANTI-AIM", "Moving", "At Fov Target")
local move_freestand_ref = menu:get_reference("RAGE", "ANTI-AIM", "Moving", "Freestand")
local move_freestand_fake_ref = menu:get_reference("RAGE", "ANTI-AIM", "Moving", "Freestand fake")
local move_lag_ref = menu:get_reference("RAGE", "ANTI-AIM", "Moving", "Fake lag")
local move_amount_lag_ref = menu:get_reference("RAGE", "ANTI-AIM", "Moving", "Base amount")
local move_limit_lag_ref = menu:get_reference("RAGE", "ANTI-AIM", "Moving", "Limit")
local move_spin_ref = menu:get_reference("RAGE", "ANTI-AIM", "Moving", "Spin")
local move_jitter_ref = menu:get_reference("RAGE", "ANTI-AIM", "Moving", "Jitter")
local move_jitter_range_ref = menu:get_reference("RAGE", "ANTI-AIM", "Moving", "Range")

local air_pitch_ref = menu:get_reference("RAGE", "ANTI-AIM", "Air", "Pitch")
local air_yaw_ref = menu:get_reference("RAGE", "ANTI-AIM", "Air", "Yaw")
local air_enable_yaw_ref = menu:get_reference("RAGE", "ANTI-AIM", "Air", "Yaw add")
local air_at_target_ref = menu:get_reference("RAGE", "ANTI-AIM", "Air", "At Fov Target")
local air_freestand_ref = menu:get_reference("RAGE", "ANTI-AIM", "Air", "Freestand")
local air_add_ref = menu:get_reference("RAGE", "ANTI-AIM", "Air", "Fake type")
local air_dir_ref = menu:get_reference("RAGE", "ANTI-AIM", "Air", "Fake amount")
local air_freestand_fake_ref = menu:get_reference("RAGE", "ANTI-AIM", "Air", "Freestand fake")
local air_lag_ref = menu:get_reference("RAGE", "ANTI-AIM", "Air", "Fake lag")
local air_amount_lag_ref = menu:get_reference("RAGE", "ANTI-AIM", "Air", "Base amount")
local air_adptive_lag_ref = menu:get_reference("RAGE", "ANTI-AIM", "Air", "Adaptive")
local air_spin_ref = menu:get_reference("RAGE", "ANTI-AIM", "Air", "Spin")
local air_jitter_ref = menu:get_reference("RAGE", "ANTI-AIM", "Air", "Jitter")

local fallbacktest,ref = menu:get_reference( 'rage', 'aimbot', 'aimbot', 'Force fallback' )
local onshotaa = menu:get_reference( 'RAGE', 'ANTI-AIM', 'General', 'Shot Antiaim' )

local side = false
local left_key = 0x5A
local left_held = false
local right_key = 0x58
local right_held = false
local backwards_key = 0x04
local backwards_held = false

local coloractiv = csgo.color(209, 139, 230, 255)
local colorinactiv = csgo.color(255,255,255,255)
local colordt = csgo.color(255, 194, 133,255)
local coloroff = csgo.color(255, 194, 133,0)
local coloraa = csgo.color(130, 201, 255,255)
local coloronshot = csgo.color(209, 139, 230, 255)
local colorantiaim = csgo.color(215, 114, 44, 255)

local textsef = "normal"

local font = render:create_font('Verdana', 42, 100, true)
local font2 = render:create_font('Arial', 15, 500, true)
local colors = { colorinactiv,coloractiv,colordt,coloroff,coloraa,coloronshot,colorantiaim}
local counter = 255
local sign = -1
fatality.callbacks:add("paint", function()

	local localPlayer = entity_list:get_localplayer()

	local screen_size = render:screen_size()
	local x, y = screen_size.x / 2, screen_size.y / 2

	if localPlayer == nil then
		return end

	local weapon = csgo.interface_handler:get_entity_list():get_from_handle(localPlayer:get_var_handle( "CBaseCombatCharacter->m_hActiveWeapon" ) )

	if weapon == nil then
		return end

	local currentWeapon = weapon:get_class_id()

		if currentWeapon == 244 or currentWeapon == 238 or currentWeapon == 257 or currentWeapon == 268  or currentWeapon == 245 or currentWeapon == 257 or currentWeapon == 240 then
			currentWeapon = 'pistol'
		elseif  currentWeapon == 46 then
			currentWeapon = 'heavy pistol'
		elseif currentWeapon == 266 then
			currentWeapon = 'scout'
		elseif currentWeapon == 260 or currentWeapon == 241 then
			currentWeapon = 'auto'
		elseif currentWeapon == 232 then
			currentWeapon = 'awp'
		elseif currentWeapon == 107 then
			currentWeapon = 'knife'
		else
			currentWeapon = 'other'
		end
		local is_silent_on = false
		local is_teleport_on = 0
		if currentWeapon == 'auto' then
			if autoSilent:get_bool() then
				silent = colors[6]
				is_silent_on = true
			else
				silent = colors[1]
			end
			if autoDoubletap:get_int() == 1 or autoDoubletap:get_int() == 2 then
				doubletap = colors[3]
			else
				doubletap = colors[1]
			end

			if autoFallback:get_bool() then
				fallback = colors[6]
			else
				fallback = colors[1]
			end

		elseif currentWeapon == 'awp' then
			if awpSilent:get_bool() then
				silent = colors[6]
				is_silent_on = true
			else
				silent = colors[1]
			end
			doubletap = colors[4]
			if awpFallback:get_bool() then
				fallback = colors[6]
			else
				fallback = colors[1]
			end
		elseif currentWeapon == 'scout' then

			if scoutSilent:get_bool() then
				silent = colors[6]
				is_silent_on = true
			else
				silent = colors[1]
				is_silent_on = false
			end
			doubletap = colors[4]
			if scoutFallback:get_bool() then
 				fallback = colors[6]
 			else
 				fallback = colors[1]
 			end
		elseif currentWeapon == 'pistol' then
			if pistolSilent:get_bool() then
				silent = colors[6]
				is_silent_on = true
			else
				silent = colors[1]
				is_silent_on = false
			end
			if pistolDoubletap:get_int() == 1 or pistolDoubletap:get_int() == 2 then
				doubletap = colors[3]
			else
				doubletap = colors[1]
			end
			if pistolFallback:get_bool() then
				fallback = colors[6]
			else
				fallback = colors[1]
			end
		elseif currentWeapon == 'heavy pistol' then
			if heavyPistolSilent:get_bool() then
				silent = colors[6]
				is_silent_on = true
			else
				silent = colors[1]
				is_silent_on = false
			end
			if heavyPistolDoubletap:get_int() == 1 or heavyPistolDoubletap:get_int() == 2 then
				doubletap = colors[3]
			else
				doubletap = colors[1]
			end
			if heavyPistolFallback:get_bool() then
				fallback = colors[6]
			else
				fallback = colors[1]
			end
		elseif currentWeapon == 'knife' then
				silent = colorinactiv
				doubletap = colors[3]
				fallback = colorinactiv
				is_silent_on = false
		else
			if otherSilent:get_bool() then
				silent = colors[6]
				is_silent_on = true
			else
				silent = colorinactiv
				is_silent_on = false
			end
			if otherDoubletap:get_int() == 1 or otherDoubletap:get_int() == 2 then
				doubletap = colors[3]
			else
				doubletap = colors[1]
			end
			if otherFallback:get_bool() then
				fallback = colors[6]
			else
				fallback = colors[1]
			end
		end

		if currentWeapon == 'auto' then
			if autoDoubletap:get_int() == 1 then

				is_teleport_on = 1
			elseif autoDoubletap:get_int() == 2 then

				is_teleport_on = 2
			else

				is_teleport_on = 0
			end
		elseif currentWeapon == 'heavy pistol' then
			if heavyPistolDoubletap:get_int() == 1 then

				is_teleport_on = 1
			elseif heavyPistolDoubletap:get_int() == 2 then

				is_teleport_on = 2
			else

				is_teleport_on = 0
			end
		elseif currentWeapon == 'pistol' then
			if pistolDoubletap:get_int() == 1 then

				is_teleport_on = 1
			elseif pistolDoubletap:get_int() == 2 then

				is_teleport_on = 2
			else

				is_teleport_on = 0
			end
		elseif currentWeapon == 'other' then
			if otherDoubletap:get_int() == 1 then

				is_teleport_on = 1
			elseif otherDoubletap:get_int() == 2 then

				is_teleport_on = 2
			else

				is_teleport_on = 0
			end
		end

    if(engine_client:is_in_game()) then
        -- Logic
      if input:is_key_down(right_key) then

				right_held = true
				lefT_held = false
				backwards_held = false
				textsef = "left"
				onshotaa:set_int(2)

				-- STANDING --
				stand_pitch_ref:set_int(1)
				stand_yaw_ref:set_int(1)
    		stand_dir_ref:set_int(75)
    		stand_add_ref:set_int(2)
    		stand_at_target_ref:set_int(1)
  			stand_freestand_ref:set_int(0)
    		stand_freestand_fake_ref:set_int(0)
    		stand_spin_ref:set_int(0)
				stand_jitter_ref:set_int(0)

    		-- MOVING --
				move_pitch_ref:set_int(1)
				move_yaw_ref:set_int(1)
    		move_dir_ref:set_int(75)
				move_add_ref:set_int(2)
				move_at_target_ref:set_int(1)
				move_freestand_ref:set_int(0)
				move_freestand_fake_ref:set_int(0)
				move_spin_ref:set_int(0)
				move_jitter_ref:set_int(0)
				move_add_ref:set_int(2)

				-- AIR --
				air_pitch_ref:set_int(1)
				air_yaw_ref:set_int(1)
				air_enable_yaw_ref:set_int(0)
				air_at_target_ref:set_int(1)
				air_freestand_ref:set_int(0)
				air_add_ref:set_int(3)
				air_dir_ref:set_int(70)
				air_freestand_fake_ref:set_int(0)
				air_spin_ref:set_int(0)
				air_jitter_ref:set_int(0)

      elseif input:is_key_down(left_key) then
          -- RIGHT --
					right_held = false
					lefT_held = true
					backwards_held = false
					textsef = "right"
					onshotaa:set_int(2)

					-- STANDING --
					stand_pitch_ref:set_int(1)
					stand_yaw_ref:set_int(1)
          stand_dir_ref:set_int(-75)
          stand_add_ref:set_int(2)
          stand_at_target_ref:set_int(1)
          stand_freestand_ref:set_int(0)
          stand_freestand_fake_ref:set_int(0)
          stand_spin_ref:set_int(0)
					stand_jitter_ref:set_int(0)

          -- MOVING --
					move_pitch_ref:set_int(1)
					move_yaw_ref:set_int(1)
          move_dir_ref:set_int(-75)
					move_at_target_ref:set_int(1)
					move_freestand_ref:set_int(0)
					move_freestand_fake_ref:set_int(0)
					move_spin_ref:set_int(0)
					move_jitter_ref:set_int(0)
					move_add_ref:set_int(2)

					-- AIR --
					air_pitch_ref:set_int(1)
					air_yaw_ref:set_int(1)
					air_enable_yaw_ref:set_int(0)
					air_at_target_ref:set_int(1)
					air_freestand_ref:set_int(0)
					air_add_ref:set_int(3)
					air_dir_ref:set_int(70)
					air_freestand_fake_ref:set_int(0)
					air_spin_ref:set_int(0)
					air_jitter_ref:set_int(0)

			elseif input:is_key_down(backwards_key) then
          -- BACKWARDS --
					right_held = false
					lefT_held = false
					backwards_held = true
					textsef = "normal"
					onshotaa:set_int(3)

					-- STANDING --
					stand_pitch_ref:set_int(1)
					stand_yaw_ref:set_int(1)
          stand_dir_ref:set_int(75)
          stand_add_ref:set_int(3)
          stand_at_target_ref:set_int(1)
          stand_freestand_ref:set_int(0)
          stand_freestand_fake_ref:set_int(0)
          stand_spin_ref:set_int(0)
					stand_jitter_ref:set_int(1)
					stand_jitter_range_ref:set_int(0)

          -- MOVING --
					move_pitch_ref:set_int(1)
					move_yaw_ref:set_int(1)
          move_dir_ref:set_int(75)
					move_at_target_ref:set_int(1)
					move_freestand_ref:set_int(0)
					move_freestand_fake_ref:set_int(0)
					move_spin_ref:set_int(0)
					move_jitter_ref:set_int(1)
					move_jitter_range_ref:set_int(0)
					move_add_ref:set_int(3)

					-- AIR --
					air_pitch_ref:set_int(1)
					air_yaw_ref:set_int(1)
					air_enable_yaw_ref:set_int(0)
					air_at_target_ref:set_int(1)
					air_freestand_ref:set_int(0)
					air_add_ref:set_int(3)
					air_dir_ref:set_int(70)
					air_freestand_fake_ref:set_int(0)
					air_spin_ref:set_int(0)
					air_jitter_ref:set_int(0)

			end

    -- Drawing

		    -- render
			if counter >= 255 then
				sign = -1
			elseif counter <= 0 then
				sign = 1
			end
			if is_silent_on or is_teleport_on then
				counter = counter + sign
			end
			local use_colordt = csgo.color(255, 194, 133,math.floor(counter))
			if is_teleport_on == 1 then
				render:text( font2, x - 27, y + 78, 'no teleport', use_colordt )
			elseif is_teleport_on == 2 then
				render:text( font2, x - 19, y + 78, 'teleport', use_colordt )
			end


			if backwards_held then
				render:text(font, x - 66, y - 23, '<', csgo.color(64, 64, 64, 185))
				render:text(font, x + 37, y - 23, '>', csgo.color(64, 64, 64, 185))
			elseif lefT_held then
				render:text(font, x - 66, y - 23, '<', csgo.color(44, 106, 212, 255))
				render:text(font, x + 37, y - 23, '>', csgo.color(64, 64, 64, 185))
			elseif right_held then
				render:text(font, x - 66, y - 23, '<', csgo.color(64, 64, 64, 185))
				render:text(font, x + 37, y - 23, '>', csgo.color(44, 106, 212, 255))
			end

			if textsef == "right" then
				render:text( font2, x - 12, y + 30, textsef, colors[7] )
			elseif textsef == "left" then
				render:text( font2, x - 8, y + 30, textsef, colors[7] )
			elseif textsef == "normal" then
				render:text( font2, x - 18, y + 30, textsef, colors[7] )
			end
			if is_silent_on then
			local use_color = csgo.color(255, 135, 251,math.floor(counter))
				render:text( font2, x - 14, y + 54, 'silent', use_color )
			else
				render:text( font2, x - 14, y + 54, 'silent', colorinactiv )
			end
			if fallbacktest:get_int() == 1 then
				render:text( font2, x - 19, y + 42, 'fallback', coloractiv )
			else
				render:text( font2, x - 19, y + 42, 'fallback', colorinactiv )
			end
			if onshotaa:get_int() == 1 then
				render:text( font2, x - 22, y + 66, "opposite", colors[5] )
			elseif onshotaa:get_int() == 2 then
				render:text( font2, x - 27, y + 66, "same side", colors[5] )
			elseif onshotaa:get_int() == 3 then
				render:text( font2, x - 17, y + 66, "neutral", colors[5] )
			elseif onshotaa:get_int() == 0 then
				render:text( font2, x - 12, y + 66, "auto", colors[5] )
			end




    end




end)

callbacks:add('paint', paint)
