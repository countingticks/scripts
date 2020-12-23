require "havoc_vector"
local success, ntv_hook = pcall(require, "gamesense/netvar_hooks")

if not success then
    error('\n\n - Netvar_hooks library is required \n - https://gamesense.pub/forums/viewtopic.php?id=19103\n')
end

-- localize vars
local type         = type;
local setmetatable = setmetatable;
local tostring     = tostring;

local ui_set = ui.set
local ui_get = ui.get
local ui_new_checkbox = ui.new_checkbox
local ui_new_slider = ui.new_slider
local ui_new_multiselect = ui.new_multiselect
local ui_new_hotkey = ui.new_hotkey
local ui_set_visible = ui.set_visible
local ui_set_callback = ui.set_callback
local ui_reference = ui.reference

local client_draw_text = client.draw_text
local client_screen_size = client.screen_size
local client_camera_angles = client.camera_angles
local client_set_event_callback = client.set_event_callback
local client_trace_line = client.trace_line
local client_trace_bullet = client.trace_bullet
local client_eye_position = client.eye_position
local client_visible = client.visible
local client_userid_to_entindex = client.userid_to_entindex
local client_get_cvar = client.get_cvar
local client_set_cvar = client.set_cvar
local client_log = client.log
local client_screensize = client.screen_size
local client_random_int = client.random_int
local client_key_state = client.key_state


local entity_get_prop = entity.get_prop
local entity_is_enemy = entity.is_enemy
local entity_is_alive = entity.is_alive
local entity_is_dormant = entity.is_dormant
local entity_get_players = entity.get_players
local entity_hitbox_position = entity.hitbox_position
local entity_get_local_player = entity.get_local_player
local entity_get_player_name = entity.get_player_name
local entity_get_player_weapon = entity.get_player_weapon
local entity_get_bounding_box = entity.get_bounding_box
local entity_get_player_resource = entity.get_player_resource

local globals_tickinterval = globals.tickinterval
local globals_tickcount = globals.tickcount
local globals_curtime = globals.curtime
local globals_realtime = globals.realtime
local interval_per_tick = globals.tickinterval

local bit_band = bit.band
local math_pi   = math.pi
local math_min  = math.min
local math_max  = math.max
local math_deg  = math.deg
local math_rad  = math.rad
local math_sqrt = math.sqrt
local math_sin  = math.sin
local math_cos  = math.cos
local math_atan = math.atan
local math_atan2 = math.atan2
local math_acos = math.acos
local math_fmod = math.fmod
local math_ceil = math.ceil
local math_pow = math.pow
local math_abs = math.abs
local math_floor = math.floor

local aa_state = ui_reference("AA", "Anti-aimbot Angles", "Enabled")
local aa_yaw, aa_yaw_offset = ui_reference("AA", "Anti-aimbot Angles", "Yaw")
local aa_pitch = ui_reference("AA", "Anti-aimbot angles", "pitch")
local aa_yaw_jitter, aa_yaw_jitter_offset = ui_reference("AA", "Anti-aimbot Angles", "Yaw jitter")
local aa_yaw_base = ui_reference("AA", "Anti-aimbot Angles", "Yaw base")
local aa_body_yaw, aa_body_yaw_slider = ui_reference("AA", "Anti-aimbot Angles", "Body yaw")
local aa_freestand_body_yaw = ui_reference("AA", "Anti-aimbot Angles", "Freestanding body yaw")
local aa_freestanding = ui_reference("AA", "Anti-aimbot Angles", "Freestanding")
local aa_fake_limit = ui_reference("AA", "Anti-aimbot Angles", "Fake Yaw Limit")
local aa_lby = ui_reference("AA", "Anti-aimbot Angles", "Lower body yaw target")
local aa_edge_yaw = ui_reference("AA", "Anti-aimbot Angles", "Edge yaw")
local aa,fake_walk = ui_reference("AA", "other", "Slow Motion")
local misc_dt, misc_dt_key= ui_reference("Rage", "Other", "Double Tap")
local misc_onshot, misc_onshot_key = ui_reference("AA", "Other", "On shot anti-aim")
local misc_fakeduck_key = ui_reference("RAGE", "Other", "Duck peek assist")
local misc_leg_movement = ui_reference("AA", "Other", "Leg movement")
local fl_amount = ui_reference("AA", "Fake lag", "Amount")
local fl_variance = ui_reference("AA", "Fake lag", "Variance")
local fl_limit = ui_reference("AA", "Fake lag", "Limit")

local off_jitter_degree = {
    [0] = "Off"
}

local enable_aa = ui.new_checkbox("lua", "b", "Anti aim")
local auto_direction = ui.new_checkbox("lua", "b", "Auto direction")
local auto_dir_mode = ui.new_combobox("lua", "b", "Auto direction mode", "Safe head", "Peek out")
local anti_resolve = ui.new_checkbox("lua", "b", "Anti resolve")
local off_jitter = ui.new_slider("lua", "b", "Offset jitter", 0, 120, 10, true, "°", 1, off_jitter_degree)
local edge_yaw_detection = ui.new_checkbox("lua", "b", "Edge yaw detection")
local legit_aa_on_e = ui.new_checkbox("lua", "b", "Legit aa on e")
local fake_lag = ui.new_checkbox("lua", "b", "Fake lag")
local leg_movement = ui.new_checkbox("lua", "b", "Leg movement")

local enemyclosesttocrosshair = nil
local desync_standing = false
local enemy_shot_time = {}

local player_mt = {}
local function player(ent_index)
	local player_object = {}
	player_object.ent_index = ent_index
	player_object.desync = 60 
	player_object.round_start_desync = 60
	player_object.old_desync_amounts = { } -- PT ANTI BRUTEFORCE
	player_object.side = 1 -- 1 SAU -1 
	player_object.invert_side = false 
	player_object.last_shot_time = 0
	setmetatable(player_object,player_mt)
	return player_object
end

player_data = {}
for i = 1 , 64 do 
	player_data[i] = player(i) -- AICI INITIALIZAM TOTI PLAYERII DAR UNII O SA FIE NIL PT CA NU SUNT 64
end 

local function get_velocity(player)
	local x,y,z = entity_get_prop(player, "m_vecVelocity")
	if x == nil then return end
	return math_sqrt(x*x + y*y + z*z)
end

local function extrapolate_position(xpos,ypos,zpos,ticks,player)
	local x,y,z = entity_get_prop(player, "m_vecVelocity")
	for i=0, ticks do
		xpos =  xpos + (x*globals_tickinterval())
		ypos =  ypos + (y*globals_tickinterval())
		zpos =  zpos + (z*globals_tickinterval())
	end
	return xpos,ypos,zpos
end

local function contains(table, val)
    for i = 1, #table do
        if table[i] == val then
            return true
        end
    end
    return false
end

local function vec3_dot(ax, ay, az, bx, by, bz)
	return ax*bx + ay*by + az*bz
end

local function vec3_normalize(x, y, z)
	local len = math_sqrt(x * x + y * y + z * z)
	if len == 0 then
		return 0, 0, 0
	end
	local r = 1 / len
	return x*r, y*r, z*r
end

local function angle_to_vec(pitch, yaw)
	local p, y = math_rad(pitch), math_rad(yaw)
	local sp, cp, sy, cy = math_sin(p), math_cos(p), math_sin(y), math_cos(y)
	return cp*cy, cp*sy, -sp
end

local function get_fov_cos(ent, vx,vy,vz, lx,ly,lz)
	local ox,oy,oz = entity_get_prop(ent, "m_vecOrigin")
	if ox == nil then
		return -1
	end

	-- get direction to player
	local dx,dy,dz = vec3_normalize(ox-lx, oy-ly, oz-lz)
	return vec3_dot(dx,dy,dz, vx,vy,vz)
end

local function is_visible(x,y,z,player)
	local local_player = entity_get_local_player()
	for i = 0 , 8 do
		local fr , entindex = client_trace_line(local_player ,x,y,z,entity_hitbox_position(player,i))
		if fr > 0.9 then
			return true
		end
	end
	return false
end

local function in_air(player)
	local flags = entity_get_prop(player, "m_fFlags")
	
	if bit_band(flags, 1) == 0 then
		return true
	end
	
	return false
end

local function is_crouching(player)
	local flags = entity_get_prop(player, "m_fFlags")
	
	if bit_band(flags, 4) == 4 then
		return true
	end
	
	return false
end

local function can_enemy_hit_head(ent)
	if ent == nil then return end
	if in_air(ent) then return false end
	
	local origin_x, origin_y, origin_z = vector_c.eye_position(enemy):unpack()
	if origin_z == nil then return end

	local hx,hy,hz = entity_hitbox_position(entity_get_local_player(), 0) 
	local _, head_dmg = client_trace_bullet(ent, origin_x, origin_y, origin_z, hx, hy, hz)
		
	return head_dmg ~= nil and head_dmg > 15
end

local function extrapolate(player,ticks,x,y,z , xv ,yv ,zv)
	xv = (xv > -10 and xv < 10) and 0 or yv
	yv = (yv > -10 and yv < 10) and 0 or xv
	local new_x = x + globals.tickinterval() * xv  * ticks
	local new_y = y + globals.tickinterval() * yv  * ticks
	local new_z = z + globals.tickinterval() * zv  * ticks
	return new_x,new_y,new_z
end

local function set_crouching_aa_backwards()
	local velo = get_velocity(entity_get_local_player())
	local crouching_ct = is_crouching(entity_get_local_player()) and entity_get_prop(entity_get_local_player(),"m_iTeamNum") == 3
	local crouching_t = is_crouching(entity_get_local_player()) and entity_get_prop(entity_get_local_player(),"m_iTeamNum") == 2

	if ui_get(aa_fake_limit) ~= 0 then
		if crouching_t then
			ui_set(aa_yaw_offset, 13)
			ui_set(aa_fake_limit, 58)
		elseif crouching_ct then
			ui_set(aa_yaw_offset, 0)
			ui_set(aa_fake_limit, client_random_int(32,35))
		elseif ui_get(fake_walk) and velo > 5 then
			ui_set(aa_yaw_offset, 17)
			ui_set(aa_fake_limit, 23)
		else
			ui_set(aa_yaw_offset, 15)
			ui_set(aa_fake_limit, 33)
		end
	end
end

local function set_crouching_aa_sides()
	local velo = get_velocity(entity_get_local_player())
	local crouching_ct = is_crouching(entity_get_local_player()) and entity_get_prop(entity_get_local_player(),"m_iTeamNum") == 3
	local crouching_t = is_crouching(entity_get_local_player()) and entity_get_prop(entity_get_local_player(),"m_iTeamNum") == 2

	if ui_get(aa_fake_limit) ~= 0 then
		if crouching_t then
			ui_set(aa_yaw_offset, 13)
			ui_set(aa_fake_limit, 58)
		elseif crouching_ct then
			ui_set(aa_yaw_offset, 0)
			ui_set(aa_fake_limit, client_random_int(32,35))
		elseif ui_get(fake_walk) and velo > 5 then
			ui_set(aa_yaw_offset, 17)
			ui_set(aa_fake_limit, 23)
		else
			ui_set(aa_yaw_offset, 0)
			ui_set(aa_fake_limit, 60)
		end
	end
end

local function set_left()
	set_crouching_aa_sides()
	ui_set(aa_body_yaw, "static")
	ui_set(aa_body_yaw_slider, 180)
    ui_set(aa_lby, "Eye yaw") 
	ui_set(aa_yaw_jitter, "off")
	ui_set(aa_yaw_jitter_offset, 0)
end

local function set_right()
	set_crouching_aa_sides()
	ui_set(aa_body_yaw, "static")
	ui_set(aa_body_yaw_slider, -180)
    ui_set(aa_lby, "Eye yaw") 
	ui_set(aa_yaw_jitter, "off")
	ui_set(aa_yaw_jitter_offset, 0)
end

local function set_normal_aa()
	set_crouching_aa_backwards()
	ui_set(aa_body_yaw, "jitter")
	ui_set(aa_body_yaw_slider, 109)
	if not ui_get(auto_direction) then
		ui_set(aa_yaw_jitter,"off")
	else
		if ui_get(off_jitter) > 0 then
			ui_set(aa_yaw_jitter, "offset")
			ui_set(aa_yaw_jitter_offset, -ui_get(off_jitter))
		else
			ui_set(aa_yaw_jitter,"off")
		end
	end
	ui_set(aa_lby, "Eye yaw") 
end 

local function set_fake_duck()
	ui_set(aa_body_yaw, "opposite")
    ui_set(aa_lby, "Eye yaw") 
	ui_set(aa_yaw_jitter, "off")
	ui_set(aa_yaw_jitter_offset, 0)
	ui_set(aa_fake_limit , 27)
end

local function set_legit_aa()
	ui_set(aa_body_yaw, "static")
	ui_set(aa_body_yaw_slider, 180)
	ui_set(aa_yaw_jitter, "off")
	ui_set(aa_yaw_jitter_offset, 0)
	ui_set(aa_fake_limit , 60)
end

local legit_aa_counter = 0 
local current_side = 0
local function set_antiaim(cmd)
	if(not ui_get(enable_aa)) then return end 

	local local_pl = entity_get_local_player()
	if(not local_pl or not entity_is_alive(local_pl)) then return end -- local players doesnt exist or is dead
	local player_list = entity_get_players(true) -- get enemies 
	local did_auto_direction = false
	
	local lx,ly,lz = client_eye_position()
	local cur_xv,cur_yv,cur_zv =  entity_get_prop(local_pl, "m_vecVelocity")
	local speed = math_sqrt(cur_xv * cur_xv + cur_yv * cur_yv + cur_zv * cur_zv)

	local velocities = { {xv = cur_xv, yv = cur_yv }, {xv = 255 , yv = 255} ,
						 {xv = 255 , yv = 0} , {xv = 0 , yv = 255} , 
						 {xv = -255 , yv = -255}, {xv = -255, yv = 0},
						 {xv = 0 , yv = -255} , {xv = -255 , yv = 255} , {xv = 255 , yv = -255} }


	local using_legit_aa = false 
	if ui_get(legit_aa_on_e) then
		if cmd.in_use == 1 then 	
			legit_aa_counter = legit_aa_counter + 1 
            if(legit_aa_counter > 5) then 

                cmd.in_use = 0

                ui_set(aa_yaw, "Off")
				ui_set(aa_pitch , "Off")

                using_legit_aa = true 
            end 
        else 
            legit_aa_counter = 0 
        end
	end 
	if(not using_legit_aa) then 
		ui_set(aa_yaw, "180")
		ui_set(aa_pitch , "Minimal")
	end 
	local jumping = (client_key_state(0x20) and speed > 100) or in_air(local_pl)
	if(ui_get(edge_yaw_detection)) then 
		local pitch, yaw = client_camera_angles()
		local vx, vy, vz = angle_to_vec(pitch, yaw)

		local closest_fov = 0
		local closest_enemy = -1
		for i = 1 , #player_list do 

			local enemy = player_list[i]
			if(entity_is_alive(enemy) and not entity_is_dormant(enemy)) then
				local cur_fov = get_fov_cos(enemy, vx,vy,vz, lx,ly,lz)
				-- Print the field of view from the player to the enemy's head.
				if( closest_fov < cur_fov )then 
					closest_fov = cur_fov 
					closest_enemy = enemy
				end 
			end
		end 
		if(closest_enemy ~= -1) and not ui_get(misc_fakeduck_key) and not can_enemy_hit_head(enemyclosesttocrosshair) then 
			ui_set(aa_edge_yaw,not is_visible(lx,ly,lz,closest_enemy) and not jumping and not using_legit_aa)
		end
	end
	if(player_list ~= nil and ui_get(auto_direction)) and not ui_get(misc_fakeduck_key) then
		for i = 1 , #player_list do 

			local enemy = player_list[i]
			local enemy_data = player_data[enemy]
			local freestand_side = get_side(enemy)
			if(ui.get(auto_dir_mode) == "Safe head") then 
				freestand_side = -freestand_side
			end 
			if(enemy_data.invert_side) then 
				freestand_side = -freestand_side
			end

			if(entity_is_alive(enemy) and not entity_is_dormant(enemy)) then  -- daca inamicul e viu si nu e dormant
				local ex, ey, ez = entity_hitbox_position(enemy, 4)
			
				for i = 1 , #velocities do -- mergem prin toate velocity-urile posibile inclusiv cel curent

					local cur_velocity = velocities[i]

					local xv = cur_velocity.xv 
					local yv = cur_velocity.yv

					for ticks = 15 , 45, 15 do 

						local x , y , z = extrapolate(local_pl, ticks , lx , ly , lz , xv , yv , cur_zv)
						local ent_index, current_damage = client_trace_bullet(local_pl, x,y,z, ex, ey, ez)

						if(current_damage > 0) then 

							ui_set(aa_fake_limit, enemy_data.desync)

							if(is_visible(lx,ly,lz,enemy)) then 
								freestand_side = enemy_data.side 
							end 

							if not ui_get(misc_fakeduck_key) then
								if freestand_side == 1 then
									set_right()
								else
									set_left()
								end

								if ui_get(aa_fake_limit) ~= 0 and speed < 5 then
									desync_standing = true
									ui_set(aa_fake_limit, 15)
								else 
									desync_standing = false
								end 
							else
								set_fake_duck()
							end
							current_side = freestand_side
							enemy_data.side = freestand_side
							
							if using_legit_aa then
								set_legit_aa()
							end
							return
						end 
					end
				end 
				
			end 
		end 
	end
	
	if(not did_auto_direction) then 
		if ui_get(misc_fakeduck_key) then
			set_fake_duck()
		else
			set_normal_aa()
		end
		current_side = 0
	end
	
	if using_legit_aa then
		set_legit_aa()
	end
end 

local hitboxes_enum = {
	"HITBOX_HEAD" ,
    "HITBOX_NECK" ,
    "HITBOX_LOWER_NECK", 
    "HITBOX_PELVIS"  ,
    "HITBOX_BODY" ,
    "HITBOX_THORAX" ,
    "HITBOX_CHEST",
    "HITBOX_UPPER_CHEST" ,
}

local function miss_in_range(range , enemy_pos , data)
	local local_player = entity.get_local_player()
	local closest_hitbox = nil
	local closest_hitbox_dist = 999
	for i = 0 , 7 do 
		local hitbox = vector(entity.hitbox_position(local_player,i))
		local closest_point = hitbox:closest_ray_point(enemy_pos, data)
		local dist = closest_point:distance2(hitbox)
		
		if dist < closest_hitbox_dist  then 
			closest_hitbox_dist = dist 
			closest_hitbox = hitboxes_enum[i + 1] or "GENERIC"
			if closest_hitbox == "HITBOX_LOWER NECK" or closest_hitbox == "HITBOX_NECK" then 
				closest_hitbox = "HITBOX_UPPER_CHEST"
			end 
			
		end 
	end 
	if closest_hitbox_dist <= range then 
		return true , closest_hitbox , closest_hitbox_dist
	else 
		return false , nil , nil
	end 
end 

client.set_event_callback("bullet_impact", function(data)
	if not ui.get(enable_aa) then return end
	if not ui.get(anti_resolve) then return end

	local shooter = client.userid_to_entindex(data.userid)
  
	if (not entity.is_enemy(shooter)) then return end

	local last_shot_time = player_data[shooter].last_shot_time

	local valid_shot = last_shot_time == 0 or globals.tickcount() - last_shot_time >= 6
	local in_range , closest_hitbox , closest_hitbox_dist = miss_in_range(20 , vector_c.eye_position(shooter) , vector(data.x, data.y, data.z))

	  
	if not valid_shot or not in_range then return end 
	 
	player_data[shooter].old_desync_amounts[#player_data[shooter].old_desync_amounts] = player_data[shooter].desync
	player_data[shooter].last_shot_time = globals.tickcount()  

	if closest_hitbox == "HITBOX_HEAD" or closest_hitbox == "HITBOX_LOWER_NECK" or closest_hitbox == "HITBOX_NECK" or closest_hitbox == "HITBOX_UPPER_CHEST" then 
		player_data[shooter].desync = 0
	else 
		player_data[shooter].invert_side = not player_data[shooter].invert_side
	end 
	-- MISS 0 GRADE SAU MISS FREESTAND = EI CRED CA TU AI PEEK OUT SI CA DEFAPT DESYNCU TAU E ASCUNS SI FACI PEEK CU REALU
end)

local hitgroup_names = { "generic", "head", "chest", "stomach", "left arm", "right arm", "left leg", "right leg", "neck", "?", "gear" }

client.set_event_callback("player_hurt", function(data)
	if not ui_get(enable_aa) then return end
	if not ui_get(anti_resolve) then return end

	local victim = client.userid_to_entindex(data.userid)
	local shooter = client.userid_to_entindex(data.attacker)

	local group = hitgroup_names[data.hitgroup + 1] or "?"
	if shooter == nil then return end

	if (shooter == entity.get_local_player() or victim == shooter or victim ~= entity.get_local_player() ) then
		return
	end

	if player_data[shooter] == nil then return end

	if(group ~= "head") then 
		player_data[shooter].invert_side = not player_data[shooter].invert_side -- THEY HIT BODY SO INVERT BACK
		player_data[shooter].desync = 0
	else 
		player_data[shooter].invert_side = not player_data[shooter].invert_side -- INVERT CUZ THEY HIT HEAD
		local old_desync = player_data[shooter].old_desync_amounts[#player_data[shooter].old_desync_amounts]

		if(old_desync == 0) then 
			player_data[shooter].desync = 60
			player_data[shooter].round_start_desync = 60
		elseif (old_desync == 60) then 
			player_data[shooter].desync = 27
			player_data[shooter].round_start_desync = 27
		elseif (old_desync == 27) then
			player_data[shooter].desync = 60
			player_data[shooter].round_start_desync = 60
		end 
	end 
end)

client.set_event_callback("run_command", function(e)
	if not ui_get(enable_aa) then return end
	if not ui_get(anti_resolve) then return end
	for i = 1 , #player_data do
		if player_data[i].last_shot_time ~= nil and globals.tickcount() - player_data[i].last_shot_time > 320 then
			player_data[i].desync = player_data[i].round_start_desync
		end
	end
end)

local function on_round_start(data)
	for i = 1 , #player_data do
		player_data[i].desync = player_data[i].round_start_desync
		player_data[i].last_shot_time = 0
	end
end
client_set_event_callback("round_start", on_round_start)


client_set_event_callback("bomb_begindefuse" , function(e)
	local defuser = client_userid_to_entindex(e.userid)
	if (defuser == entity_get_local_player()) then 
		legit_aa_counter = -9999
	end
end)

client_set_event_callback("bomb_abortdefuse" , function(e)
	local defuser = client_userid_to_entindex(e.userid)
	if (defuser == entity_get_local_player()) then
		legit_aa_counter = 0
	end
end)

client_set_event_callback("bomb_defused" , function(e)
	local defuser = client_userid_to_entindex(e.userid)
	if (defuser == entity_get_local_player()) then 
		legit_aa_counter = 0
	end

end)

local flip = true

local function can_enemy_shoot_legs()
	local lp = entity_get_local_player()

	local sx,sy,sz = entity_hitbox_position(lp, 11)
	local dx,dy,dz = entity_hitbox_position(lp, 12)
	local player_list = entity.get_players(true)

	if not player_list then return false end 

	for i = 1 , #player_list do 
		local enemy = player_list[i]

		local origin_x, origin_y, origin_z = vector_c.eye_position(enemy):unpack()
		local _1, left_dmg = client_trace_bullet(enemy, origin_x, origin_y, origin_z, sx, sy, sz)
		local _2, right_dmg = client_trace_bullet(enemy, origin_x, origin_y, origin_z, dx, dy, dz)

		if left_dmg > 10 or right_dmg > 10 then 
			return true 
		end
	end

	return false 
end 

local function on_run_command()
	if(not ui_get(enable_aa)) then return end
	
	flip = not flip

	local lp = entity_get_local_player()

	if lp == nil or not entity_is_alive(lp) then return end
	
	local lp_vel = get_velocity(lp)
	local jumping = (client_key_state(0x20) and lp_vel > 100) or in_air(lp)
	local hit = can_enemy_shoot_legs()
	local fakeduck = ui_get(misc_fakeduck_key)

	-- LEGS 
	if ui_get(leg_movement) then
		if hit then
			ui_set(misc_leg_movement,"off")
		else
			ui_set(misc_leg_movement,flip and "always slide" or "never slide")
		end	
	else
		ui_set(misc_leg_movement,"never slide")
	end

	-- FAKE LAG 
	if ui_get(fake_lag) then
		if not fakeduck then
			if hit or jumping then
				ui_set(fl_amount,"Fluctuate")	
				ui_set(fl_variance, 0)
				ui_set(fl_limit, 14)
			else
				ui_set(fl_amount,"Maximum")
				ui_set(fl_variance, 15)
				ui_set(fl_limit, 10)
			end
		else
			ui_set(fl_limit, 14)
		end
	end
end

local function on_paint()
	if(not ui_get(enable_aa)) then return end
	if not entity_get_local_player() or not entity_is_alive(entity_get_local_player()) then return end

	local center_x,center_y = client.screen_size()
 	center_x = center_x / 2
	center_y = center_y / 2
	 
	local r,g,b
	if ui_get(aa_fake_limit) < 5 then
		r,g,b = 0,100,0
	elseif desync_standing then
		r,g,b = 235,64,52
	else
		r,g,b = 89,119,239
	end
	local alpha = 255

	if(current_side == 1) then -- RIGHT
		client.draw_text(c, center_x - 60, center_y, 163,160,163,255, "cb+", 0, "⯇")
		client.draw_text(c, center_x + 60, center_y, r,g,b,alpha, "cb+", 0, "⯈")
	else if(current_side == -1) then -- LEFT
		client.draw_text(c, center_x - 60, center_y, r,g,b,alpha, "cb+", 0, "⯇")
		client.draw_text(c, center_x + 60, center_y, 163,160,163,255, "cb+", 0, "⯈")
	else -- BACKWARDS
		client.draw_text(c, center_x - 60, center_y, 163,160,163,255, "cb+", 0, "⯇")
		client.draw_text(c, center_x + 60, center_y, 163,160,163,255, "cb+", 0, "⯈")
	end
end
end

ntv_hook.hook_prop("DT_CSRagdoll", "m_vecForce", function(val,idx)
	local force = 5000
	val[ 0 ] = val[ 0 ]
	val[ 1 ] = val[ 1 ]
	val[ 2 ] = val[ 2 ] * force * 100000
	
	if val[ 2 ] <= 1 then
		val[ 2 ] = 2
	end
	
	val[ 2 ] = val[ 2 ] * 2
end)

local function handle_menu()
	local state_aa = ui_get(enable_aa)
	local state_dir = ui_get(auto_direction)
	ui_set_visible(auto_direction , state_aa)
	ui_set_visible(auto_dir_mode , state_aa and state_dir)
	ui_set_visible(anti_resolve, state_aa and state_dir)
	ui_set_visible(off_jitter, state_aa and state_dir)
	ui_set_visible(edge_yaw_detection , state_aa)
	ui_set_visible(legit_aa_on_e , state_aa)
	ui_set_visible(fake_lag , state_aa)
	ui_set_visible(leg_movement , state_aa)
end 

ui_set_visible(auto_direction , false)
ui_set_visible(auto_dir_mode , false)
ui_set_visible(anti_resolve , false)
ui_set_visible(off_jitter , false)
ui_set_visible(edge_yaw_detection , false)
ui_set_visible(legit_aa_on_e , false)
ui_set_visible(fake_lag , false)
ui_set_visible(leg_movement , false)

ui_set_callback(enable_aa, handle_menu)
ui_set_callback(auto_direction, handle_menu)

client_set_event_callback("setup_command",set_antiaim)
client_set_event_callback("run_command",on_run_command)
client_set_event_callback("paint",on_paint)
