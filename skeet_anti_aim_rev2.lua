local success, ntv_hook = pcall(require, "gamesense/netvar_hooks")

if not success then
    error('\n\n - Netvar_hooks library is required \n - https://gamesense.pub/forums/viewtopic.php?id=19103\n')
end

local type = type;
local setmetatable = setmetatable;
local tostring = tostring;

local ui_set = ui.set
local ui_get = ui.get
local ui_reference = ui.reference
local ui_new_checkbox = ui.new_checkbox
local ui_new_slider = ui.new_slider
local ui_new_multiselect = ui.new_multiselect
local ui_new_hotkey = ui.new_hotkey
local ui_set_visible = ui.set_visible
local ui_set_callback = ui.set_callback

local client_draw_text = client.draw_text
local client_screen_size = client.screen_size
local client_camera_angles = client.camera_angles
local client_set_event_callback = client.set_event_callback
local client_trace_line = client.trace_line
local client_trace_bullet = client.trace_bullet
local client_scale_damage = client.scale_damage
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
local entity_get_classname = entity.get_classname

local globals_tickinterval = globals.tickinterval
local globals_tickcount = globals.tickcount
local globals_curtime = globals.curtime
local globals_realtime = globals.realtime
local interval_per_tick = globals.tickinterval

local bit_band = bit.band
local math_pi = math.pi
local math_min = math.min
local math_max = math.max
local math_deg = math.deg
local math_rad = math.rad
local math_sqrt = math.sqrt
local math_sin = math.sin
local math_cos = math.cos
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
local rage_silent= ui_reference("RAGE", "Aimbot", "Silent aim")
local rage_mindamage = ui.reference("RAGE", "Aimbot", "Minimum damage")

local off_jitter_degree = {
    [0] = "Off"
}

local enable_aa = ui.new_checkbox("lua", "b", "Anti aim")
local auto_direction = ui.new_checkbox("lua", "b", "Auto direction")
local auto_dir_mode = ui.new_combobox("lua", "b", "Auto direction mode", "Adaptive", "Safe head", "Peek out")
local anti_resolve = ui.new_checkbox("lua", "b", "Anti resolve")
local misc_ev4sion = ui.new_checkbox("lua", "b", "Adaptive anti-aim")
local off_jitter = ui.new_slider("lua", "b", "Offset jitter", 0, 120, 10, true, "°", 1, off_jitter_degree)
local aa_indicators = ui.new_multiselect("lua", "b", "Indicators", "Arrows", "Text", "Damage")
local fake_lag = ui.new_checkbox("lua", "b", "Peek fakelag")
local onshot_bodyyaw = ui.new_checkbox("lua", "b", "Onshot desync")
local legit_aa_on_e = ui.new_checkbox("lua", "b", "E desync")
local edge_yaw_detection = ui.new_checkbox("lua", "b", "Edge yaw detection")
local leg_movement = ui.new_checkbox("lua", "b", "Leg movement")
local furia_twist = ui.new_checkbox("lua", "b", "Twist")
local more_traces = ui.new_checkbox("lua", "b", "More traces")

local enemyclosesttocrosshair = nil
local flipJitter = false
local flipJitter2 = false

local available_resolver_information = {}
local enemy_shot_angle = {}
local enemy_shot_time = {}
local anti_brute_FORCE = false
--local anti_PEEK = false

local isFreestanding = false

local stored_freestand = 0
local stored_freestand_v2 = 0
local adaptive_freestand = 0
local realtime_freestand = nil
local realtime_freestand_v2 = nil
local adjusted_freestand = {}

local three_way_timer = 0
local three_way_choke = false
local first_shot_only = false
local aimbot_fired_time = nil

local flip_angle = false
local dangerous_x_offset = false
local dangerous_y_offset = false

local was_moving = false
local time_moving = 0
local should_trigger = false
local jumping_lp = false

local evasion_time = 0
local evasion_ent = nil
local evasion_last_ent = nil
local evasion_vis_ticks = 0
local maxspeed = 0

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

	local dx,dy,dz = vec3_normalize(ox-lx, oy-ly, oz-lz)
	return vec3_dot(dx,dy,dz, vx,vy,vz)
end

local function Angle_Vector(angle_x, angle_y)
	local sp, sy, cp, cy = nil
    sy = math_sin(math_rad(angle_y));
    cy = math_cos(math_rad(angle_y));
    sp = math_sin(math_rad(angle_x));
    cp = math_cos(math_rad(angle_x));
    return cp * cy, cp * sy, -sp;
end

local function CalcAngle(localplayerxpos, localplayerypos, enemyxpos, enemyypos)
   local relativeyaw = math_atan( (localplayerypos - enemyypos) / (localplayerxpos - enemyxpos) )
    return relativeyaw * 180 / math.pi
end

local function normalise_angle(angle)
	angle =  angle % 360 
	angle = (angle + 360) % 360
	if (angle > 180)  then
		angle = angle - 360
	end
	return angle
end

local function GetClosestPoint(A, B, P)
   local a_to_p = { P[1] - A[1], P[2] - A[2] }
   local a_to_b = { B[1] - A[1], B[2] - A[2] }
   local ab = a_to_b[1]^2 + a_to_b[2]^2
   local dots = a_to_p[1]*a_to_b[1] + a_to_p[2]*a_to_b[2]
   local t = dots / ab
    
   return { A[1] + a_to_b[1]*t, A[2] + a_to_b[2]*t }
end

local function time_to_ticks(dt)
	return math_floor(0.5 + dt / globals_tickinterval() - 3)
end

local function clamp(val, lower, upper)
    assert(val and lower and upper, "not very useful error message here")
    if lower > upper then lower, upper = upper, lower end
    return math_max(lower, math_min(upper, val))
end

local function get_lerp_time()
	local ud_rate = client_get_cvar("cl_updaterate")
	
	local min_ud_rate = client_get_cvar("sv_minupdaterate")
	local max_ud_rate = client_get_cvar("sv_maxupdaterate")

	if (min_ud_rate and max_ud_rate) then
		ud_rate = max_ud_rate
	end
	
	local ratio = client_get_cvar("cl_interp_ratio")

	if (ratio == 0) then
		ratio = 1
	end
	
	local lerp = client_get_cvar("cl_interp")
	local c_min_ratio = client_get_cvar("sv_client_min_interp_ratio")
	local c_max_ratio = client_get_cvar("sv_client_max_interp_ratio")

	if (c_min_ratio and  c_max_ratio and  c_min_ratio ~= 1) then
		ratio = clamp(ratio, c_min_ratio, c_max_ratio)
	end
	
	return math_max(lerp, (ratio / ud_rate));
end

local function is_record_valid(player_time,ms)
	local correct = 0
	local sv_maxunlag = 0.2
	
	correct = correct + get_lerp_time()
	correct = correct + client.latency()
	correct = clamp(correct, 0, ms);
	
	local delta = correct - (globals_curtime() - player_time);
	
	if math_abs(delta) > ms then
		return false
	end
	
	return true
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

local function get_velocity(player)
	local x,y,z = entity_get_prop(player, "m_vecVelocity")
	if x == nil then return end
	return math_sqrt(x*x + y*y + z*z)
end

local function get_max_body_yaw(player)
	local x,y,z = entity_get_prop(player, "m_vecVelocity")
	return 58 - 58 * math_sqrt(x ^ 2 + y ^ 2) / 580
end

local function get_body_yaw(player)
	local _, model_yaw = entity_get_prop(player, "m_angAbsRotation")
	local _, eye_yaw = entity_get_prop(player, "m_angEyeAngles")
	if model_yaw == nil or eye_yaw ==nil then return 0 end
	return normalise_angle(model_yaw - eye_yaw)
end

local function on_ground(player)
	local flags = entity_get_prop(player, "m_fFlags")
	
	if bit_band(flags, 1) == 1 then
		return true
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

weapons, weapons_index = {}, {}
weapons_data, weapons_data_types = {[1]={"deagle",1,230,700,"Desert Eagle",7,0.225},[2]={"elite",1,240,400,"Dual Berettas",30,0.12},[3]={"fiveseven",1,240,500,"Five-SeveN",20,0.15},[4]={"glock",1,240,200,"Glock-18",20,0.15},[7]={"ak47",2,215,2700,"AK-47",30,0.1},[8]={"aug",2,220,3300,"AUG",30,0.09},[9]={"awp",2,200,4750,"AWP",10,1.455},[10]={"famas",2,220,2250,"FAMAS",25,0.09},[11]={"g3sg1",2,215,5000,"G3SG1",20,0.25},[13]={"galilar",2,215,2000,"Galil AR",35,0.09},[14]={"m249",3,195,5200,"M249",100,0.08},[16]={"m4a1",2,225,3100,"M4A4",30,0.09},[17]={"mac10",4,240,1050,"MAC-10",30,0.075},[19]={"p90",4,230,2350,"P90",50,0.07},[23]={"mp5sd",4,235,1500,"MP5-SD",30,0.08},[24]={"ump45",4,230,1200,"UMP-45",25,0.09},[25]={"xm1014",3,215,2000,"XM1014",7,0.35},[26]={"bizon",4,240,1400,"PP-Bizon",64,0.08},[27]={"mag7",3,225,1300,"MAG-7",5,0.85},[28]={"negev",3,150,1700,"Negev",150,0.075},[29]={"sawedoff",3,210,1100,"Sawed-Off",7,0.85},[30]={"tec9",1,240,500,"Tec-9",18,0.12},[31]={"taser",5,220,200,"Zeus x27",1,0.15},[32]={"hkp2000",1,240,200,"P2000",13,0.17},[33]={"mp7",4,220,1500,"MP7",30,0.08},[34]={"mp9",4,240,1250,"MP9",30,0.07},[35]={"nova",3,220,1050,"Nova",8,0.88},[36]={"p250",1,240,300,"P250",13,0.15},[38]={"scar20",2,215,5000,"SCAR-20",20,0.25},[39]={"sg556",2,210,2750,"SG 553",30,0.09},[40]={"ssg08",2,230,1700,"SSG 08",10,1.25},[41]={"knifegg",6,250,0,"Knife",-1,0.15},[42]={"knife",6,250,0,"Knife",-1,0.15},[43]={"flashbang",7,245,200,"Flashbang",-1,0.15},[44]={"hegrenade",7,245,300,"High Explosive Grenade",-1,0.15},[45]={"smokegrenade",7,245,300,"Smoke Grenade",-1,0.15},[46]={"molotov",7,245,400,"Molotov",-1,0.15},[47]={"decoy",7,245,50,"Decoy Grenade",-1,0.15},[48]={"incgrenade",7,245,600,"Incendiary Grenade",-1,0.15},[49]={"c4",8,250,0,"C4 Explosive",-1,0.15},[50]={"item_kevlar",5,1,650,"Kevlar Vest",-1,0.15},[51]={"item_assaultsuit",5,1,1000,"Kevlar + Helmet",-1,0.15},[52]={"item_heavyassaultsuit",5,1,6000,"Heavy Assault Suit",-1,0.15},[55]={"item_defuser",5,1,400,"Defuse Kit",-1,0.15},[56]={"item_cutters",5,1,400,"Rescue Kit",-1,0.15},[57]={"healthshot",9,250,0,"Medi-Shot",-1,0.15},[59]={"knife_t",6,250,0,"Knife",-1,0.15},[60]={"m4a1_silencer",2,225,3100,"M4A1-S",25,0.1},[61]={"usp_silencer",1,240,200,"USP-S",12,0.17},[63]={"cz75a",1,240,500,"CZ75-Auto",12,0.1},[64]={"revolver",1,180,600,"R8 Revolver",8,0.5},[68]={"tagrenade",7,245,100,"Tactical Awareness Grenade",-1,0.15},[69]={"fists",6,275,0,"Bare Hands",-1,0.15},[70]={"breachcharge",8,245,300,"Breach Charge",3,0.15},[72]={"tablet",10,220,300,"Tablet",1,0.15},[74]={"melee",6,250,0,"Knife",-1,0.15},[75]={"axe",6,250,0,"Axe",-1,0.15},[76]={"hammer",6,250,0,"Hammer",-1,0.15},[78]={"spanner",6,250,0,"Wrench",-1,0.15},[80]={"knife_ghost",6,250,0,"Spectral Shiv",-1,0.15},[81]={"firebomb",7,245,400,"Fire Bomb",-1,0.15},[82]={"diversion",7,245,50,"Diversion Device",-1,0.15},[83]={"frag_grenade",7,245,300,"Frag Grenade",-1,0.15},[84]={"snowball",7,245,100,"Snowball",-1,0.15},[500]={"bayonet",6,250,0,"Bayonet",-1,0.15},[505]={"knife_flip",6,250,0,"Flip Knife",-1,0.15},[506]={"knife_gut",6,250,0,"Gut Knife",-1,0.15},[507]={"knife_karambit",6,250,0,"Karambit",-1,0.15},[508]={"knife_m9_bayonet",6,250,0,"M9 Bayonet",-1,0.15},[509]={"knife_tactical",6,250,0,"Huntsman Knife",-1,0.15},[512]={"knife_falchion",6,250,0,"Falchion Knife",-1,0.15},[514]={"knife_survival_bowie",6,250,0,"Bowie Knife",-1,0.15},[515]={"knife_butterfly",6,250,0,"Butterfly Knife",-1,0.15},[516]={"knife_push",6,250,0,"Shadow Daggers",-1,0.15},[519]={"knife_ursus",6,250,0,"Ursus Knife",-1,0.15},[520]={"knife_gypsy_jackknife",6,250,0,"Navaja Knife",-1,0.15},[522]={"knife_stiletto",6,250,0,"Stiletto Knife",-1,0.15},[523]={"knife_widowmaker",6,250,0,"Talon Knife",-1,0.15},[1349]={"spraypaint",11,250,0,"Graffiti",0,0}}, {"secondary","rifle","heavy","smg","equipment","melee","grenade","c4","boost","utility","spray"}

for idx, weapon in pairs(weapons_data) do
	local console_name, weapon_type = ("weapon_" .. weapon[1]):gsub("weapon_item_", "item_"), weapons_data_types[weapon[2]]
	weapons[idx] = {
		console_name = console_name,
		idx = idx,
		type = weapon_type,
		max_speed = weapon[3],
		price = weapon[4],
		name = weapon[5],
		primary_clip_size = weapon[6],
		cycletime = weapon[7]
	}
	weapons_index[console_name] = weapons[idx]
end

local function get_weapon(idx)
	if type(idx) == "string" then
		return weapons_index[idx]
	elseif type(idx) == "number" then
		idx = bit_band(idx, 0xFFFF)
		return rawget(weapons, idx)
	end
end

client_set_event_callback("aim_fire", function (c)
	aimbot_fired_time = globals.curtime()
end)

client_set_event_callback("bullet_impact", function(c)
    if not ui_get(enable_aa) and not ui_get(auto_direction) then return end
	if ui_get(anti_resolve) and entity_is_alive(entity_get_local_player()) then
        local ent = client_userid_to_entindex(c.userid)
        if not entity.is_dormant(ent) and entity.is_enemy(ent) and ent == enemyclosesttocrosshair then
            local ent_shoot = { entity_get_prop(ent, "m_vecOrigin") }
            ent_shoot[3] = ent_shoot[3] + entity_get_prop(ent, "m_vecViewOffset[2]")
            local player_head = { entity_hitbox_position(entity_get_local_player(), 0) }
            local closest = GetClosestPoint(ent_shoot, { c.x, c.y, c.z }, player_head)
            local delta = { player_head[1]-closest[1], player_head[2]-closest[2] }
            local delta_2d = math.sqrt(delta[1]^2+delta[2]^2)
			
            if math.abs(delta_2d) < 32 and ui_get(aa_yaw_offset) == 0 and ui_get(aa_fake_limit) > 40 then
                available_resolver_information[ent] = true
				enemy_shot_angle[ent] = ui_get(aa_body_yaw_slider)
				enemy_shot_time[ent] = globals_curtime() + 3.1
			else
				available_resolver_information[ent] = false
            end
		else
			available_resolver_information[ent] = false
        end
    end
end)

local function DoFreestanding(enemy, ...)
	local lx, ly, lz = entity_get_prop(entity_get_local_player(), "m_vecOrigin")
	local viewangle_x, viewangle_y, roll = client_camera_angles()
	local headx, heady, headz = entity_hitbox_position(entity.get_local_player(), 0)
	local enemyx, enemyy, enemyz = entity_get_prop(enemy, "m_vecOrigin")
	local bestangle = nil
	local lowest_dmg = math.huge

	if(entity_is_alive(enemy)) then
		local yaw = CalcAngle(lx, ly, enemyx, enemyy)
		for i,v in pairs({...}) do
			local dir_x, dir_y, dir_z = Angle_Vector(0, (yaw + v))
			local end_x = lx + dir_x * 55
			local end_y = ly + dir_y * 55
			local end_z = lz + 80			
			
			local index, damage = client_trace_bullet(enemy, enemyx, enemyy, enemyz + 70, end_x, end_y, end_z,true)
			local index2, damage2 = client_trace_bullet(enemy, enemyx, enemyy, enemyz + 70, end_x + 12, end_y, end_z,true)
			local index3, damage3 = client_trace_bullet(enemy, enemyx, enemyy, enemyz + 70, end_x - 12, end_y, end_z,true)

			if(damage < lowest_dmg) then
				lowest_dmg = damage
				if(damage2 > damage) then
					lowest_dmg = damage2
				end
				if(damage3 > damage) then
					lowest_dmg = damage3
				end	
				if(lx - enemyx > 0) then
					bestangle = v
				else
					bestangle = v * -1
				end
			elseif(damage == lowest_dmg) then
					return 0
			end
		end
	end
	return bestangle
end

local function DoEarlyFreestanding(enemy, ...)
	if not ui_get(more_traces) then return end

	local lx, ly, lz = entity_get_prop(enemy, "m_vecOrigin") 
	local viewangle_x, viewangle_y, roll = client_camera_angles()
	local localplayer = entity_get_local_player()
	local headx, heady, headz = entity_hitbox_position(localplayer, 0)
	local enemyx, enemyy, enemyz = entity_get_prop(localplayer, "m_vecOrigin")
	local bestangle = nil
	local lowest_dmg = math.huge
	local last_moved = 0
	local fs_stored_eyepos_x, fs_stored_eyepos_y, fs_stored_eyepos_z = nil

	if(entity_is_alive(enemy)) then
		local yaw = CalcAngle(enemyx, enemyy, lx, ly)
		for i,v in pairs({...}) do
			local dir_x, dir_y, dir_z = Angle_Vector(0, (yaw + v))
			local end_x = lx + dir_x * 55
			local end_y = ly + dir_y * 55
			local end_z = lz + 80

			local eyepos_x, eyepos_y, eyepos_z = client_eye_position()
			local local_velocity = get_velocity(entity_get_local_player())
			local can_be_extrapolated = local_velocity > 15
			local ticks_to_extrapolate = 11
			if (local_velocity < 50) then
				ticks_to_extrapolate = 90
			elseif (local_velocity >= 50 and local_velocity < 120) then
				ticks_to_extrapolate = 50
			elseif (local_velocity >= 120 and local_velocity < 190) then
				ticks_to_extrapolate = 40
			elseif (local_velocity >= 190) then
				ticks_to_extrapolate = 20
			end

			if can_be_extrapolated then
				eyepos_x, eyepos_y, eyepos_z = extrapolate_position(eyepos_x, eyepos_y, eyepos_z, ticks_to_extrapolate, entity_get_local_player())
				fs_stored_eyepos_x, fs_stored_eyepos_y, fs_stored_eyepos_z = eyepos_x, eyepos_y, eyepos_z
				last_moved = globals_curtime() + 1
			else
				if last_moved ~= 0 then
					if globals_curtime() > last_moved then
						last_moved = 0
						fs_stored_eyepos_x, fs_stored_eyepos_y, fs_stored_eyepos_z = nil
					else
						eyepos_x, eyepos_y, eyepos_z = fs_stored_eyepos_x, fs_stored_eyepos_y, fs_stored_eyepos_z
					end
				else
					eyepos_x, eyepos_y, eyepos_z = extrapolate_position(eyepos_x, eyepos_y, eyepos_z, ticks_to_extrapolate, entity_get_local_player())
				end
			end
			
			local index, damage = client_trace_bullet(localplayer, enemyx, enemyy, enemyz + 70, end_x, end_y, end_z,true)
			local index2, damage2 = client_trace_bullet(localplayer, enemyx, enemyy, enemyz + 70, end_x + 12, end_y, end_z,true)
			local index3, damage3 = client_trace_bullet(localplayer, enemyx, enemyy, enemyz + 70, end_x - 12, end_y, end_z,true)

			if fs_stored_eyepos_x ~= nil then
				index, damage = client_trace_bullet(localplayer, fs_stored_eyepos_x, fs_stored_eyepos_y, fs_stored_eyepos_z + 70, end_x, end_y, end_z,true)
				index2, damage2 = client_trace_bullet(localplayer, fs_stored_eyepos_x, fs_stored_eyepos_y, fs_stored_eyepos_z + 70, end_x + 12, end_y, end_z,true) 
				index3, damage3 = client_trace_bullet(localplayer, fs_stored_eyepos_x, fs_stored_eyepos_y, fs_stored_eyepos_z + 70, end_x - 12, end_y, end_z,true) 
			end

			if(damage < lowest_dmg) then
				lowest_dmg = damage
				if(damage2 > damage) then
					lowest_dmg = damage2
				end
				if(damage3 > damage) then
					lowest_dmg = damage3
				end	
				if(enemyx - lx > 0) then
					bestangle = v
				else
				bestangle = v * -1
				end
			elseif(damage == lowest_dmg) then
				return 0
			end
		end
	end
	return bestangle
end

local function can_hit(entity,lx,ly,lz,px,py,pz)
	local entindex, dmg = client_trace_bullet(entity,lx,ly,lz,px,py,pz)
	
	if entindex == entity or entindex == nil or entindex ~= entity_get_local_player() then 
		entindex, dmg = nil
	end
	
	if dmg ~= nil and dmg <= 0 then
		entindex, dmg = nil
	end
	
	return entindex, dmg
end

local function can_enemy_hit_on_peek(ent,ticks)	
	if ent == nil then return end
	
	local origin_x, origin_y, origin_z = entity_get_prop(ent, "m_vecOrigin")
	if origin_z == nil then return end
	
	local sx,sy,sz = entity_hitbox_position(entity_get_local_player(), 11)
	local dx,dy,dz = entity_hitbox_position(entity_get_local_player(), 12)

	sx,sy,sz = extrapolate_position(sx, sy, sz, ticks, entity_get_local_player())
	dx,dy,dz = extrapolate_position(dx, dy, dz, ticks, entity_get_local_player())
	
	local ___, left_dmg = client_trace_bullet(ent, origin_x, origin_y, origin_z, sx, sy, sz, true)
	local __, right_dmg = client_trace_bullet(ent, origin_x, origin_y, origin_z, dx, dy, dz, true)

	local left_hittable = left_dmg ~= nil and left_dmg > 12
	local right_hittable = right_dmg ~= nil and right_dmg > 12
	local hittable = (left_hittable or right_hittable) and get_velocity(entity_get_local_player()) > 32
	
	return hittable
end

local function can_enemy_hit_head(ent)
	if ent == nil then return end
	if in_air(ent) then return false end
	
	local origin_x, origin_y, origin_z = entity_get_prop(ent, "m_vecOrigin")
	if origin_z == nil then return end
	origin_z = origin_z + 64

	local hx,hy,hz = entity_hitbox_position(entity_get_local_player(), 0) 
	local _, head_dmg = client_trace_bullet(ent, origin_x, origin_y, origin_z, hx, hy, hz, true)
		
	return head_dmg ~= nil and head_dmg > 25
end

local function enemy_is_peeking_and_can_hit_us(ent)
	if ent == nil then return end
	local origin_x, origin_y, origin_z = entity_get_prop(ent, "m_vecOrigin")
	local vx,vy,vz = entity_get_prop(enemyclosesttocrosshair, "m_vecViewOffset")
	if origin_z == nil then return end
	origin_x,origin_y,origin_z = origin_x+vx,origin_y+vy,origin_z+vz

	local lp = entity_get_local_player()
	
	if (get_velocity(ent) < 20) or in_air(ent) or in_air(entity_get_local_player()) then return false end

	local extrapolated_x, extrapolated_y, extrapolated_z = extrapolate_position(origin_x, origin_y, origin_z, 16, ent)

	local hx,hy,hz = entity_hitbox_position(lp, 0)
	local lx,ly,lz = client_eye_position()
	lz = hz
	
	local _, eye_yaw = entity_get_prop(lp, "m_angEyeAngles")
	local desync = normalise_angle(eye_yaw + (get_body_yaw(lp)))
	local real_x = lx + math_cos(math_rad(desync)) * 20
	local real_y = ly + math_sin(math_rad(desync)) * 12
	
	local desynced = normalise_angle(eye_yaw - (get_body_yaw(lp)))
	local fake_x = lx + math_cos(math_rad(desynced)) * 20
	local fake_y = ly + math_sin(math_rad(desynced)) * 12
	local head_idx, head_dmg = client_trace_bullet(ent, extrapolated_x, extrapolated_y, extrapolated_z, real_x, real_y, lz,true)
	local fake_idx, fake_dmg = client_trace_bullet(ent, extrapolated_x, extrapolated_y, extrapolated_z, fake_x, fake_y, lz,true)

	local predicted_damage = 0
	local desynced_damage = 0
	local timer = 0

	if head_dmg ~= nil and head_dmg > 0 then
		predicted_damage = head_dmg
	else
		predicted_damage = 0
	end
	
	if fake_dmg ~= nil and fake_dmg > 0 then
		desynced_damage = fake_dmg
	else
		desynced_damage = 0
	end

	if predicted_damage <= desynced_damage then return false end

	return predicted_damage ~= nil and predicted_damage > 58
end

local function setSpeed(newSpeed)
	if newSpeed == 245 then
		return
	end
	local vx, vy = entity_get_prop(entity_get_local_player(), "m_vecVelocity")
	local velocity = math_floor(math_min(10000, math_sqrt(vx*vx + vy*vy) + 0.5))
	local maxvelo = newSpeed
	
	if(velocity<maxvelo) then
		client.set_cvar("cl_sidespeed", maxvelo)
		client_set_cvar("cl_forwardspeed", maxvelo)
		client_set_cvar("cl_backspeed", maxvelo)
	end
	
	if(velocity>=maxvelo) then
		kat=math_atan2(client_get_cvar("cl_forwardspeed"), client_get_cvar("cl_sidespeed"))
		forward=math_cos(kat)*maxvelo;
		side=math_sin(kat)*maxvelo;
		client_set_cvar("cl_sidespeed", side)
		client_set_cvar("cl_forwardspeed", forward)
		client_set_cvar("cl_backspeed", forward)
	end
end

local function handle_directions()
    if ui_get(auto_direction) then
        isFreestanding = true
    else
        isFreestanding = false
    end
end

local function handle_indicators(type,mode)
	local scrsize_x, scrsize_y = client_screensize()
	local center_x, center_y = scrsize_x / 2, scrsize_y / 2

	local r,g,b
    if anti_brute_FORCE then
		r,g,b = 0,100,0
	--elseif anti_PEEK then
	--	r,g,b = 100,0,0
    else 
        r,g,b = 89,119,239
	end

	local r2,g2,b2 
	if anti_brute_FORCE then
		r2,g2,b2 = 0,100,0
	else
		r2,g2,b2 = 255,255,255
	end

	if contains(ui_get(aa_indicators),"Damage") then
		client.draw_text(c, center_x, center_y + 40, 255, 255, 255, 255, "c", 0, ui_get(rage_mindamage))
	end

	if type == 1 then 
		if contains(ui_get(aa_indicators),"Text") then
			if anti_brute_FORCE then 
				client.draw_text(c, center_x, center_y + 28, r2,g2,b2,255, "c", 0, "DODGE")
			elseif holdingE then 
				client.draw_text(c, center_x, center_y + 28, r2,g2,b2,255, "c", 0, "LEGIT AA")
			else
				client.draw_text(c, center_x, center_y + 28, 255, 255, 255, 255, "c", 0, "DEFAULT")
			end
		end
		if contains(ui_get(aa_indicators),"Arrows") then
			if mode == 1 then 
				client.draw_text(c, center_x - 45, center_y, 163,160,163,255, "cb+", 0, "⯇")
				client.draw_text(c, center_x + 45, center_y, 163,160,163,255, "cb+", 0, "⯈")
			elseif mode == 2 then
				client.draw_text(c, center_x - 45, center_y, 163,160,163,255, "cb+", 0, "<")
				client.draw_text(c, center_x + 45, center_y, 163,160,163,255, "cb+", 0, ">")
			end
		end
	elseif type == 2 then 
		if contains(ui_get(aa_indicators),"Text") then
			if anti_brute_FORCE then 
				client.draw_text(c, center_x, center_y + 28, r2,g2,b2,255, "c", 0, "DODGE")
			elseif holdingE then 
				client.draw_text(c, center_x, center_y + 28, r2,g2,b2,255, "c", 0, "LEGIT AA")
			else
				client.draw_text(c, center_x, center_y + 28, r2,g2,b2,255, "c", 0, "DYNAMIC")
			end
		end
		if contains(ui_get(aa_indicators),"Arrows") then
			if mode == 1 then 
				client.draw_text(c, center_x - 45, center_y, r,g,b,255, "cb+", 0, "⯇")
				client.draw_text(c, center_x + 45, center_y, 163,160,163,255, "cb+", 0, "⯈")
			elseif mode == 2 then
				client.draw_text(c, center_x - 45, center_y, r,g,b,255, "cb+", 0, "<")
				client.draw_text(c, center_x + 45, center_y, 163,160,163,255, "cb+", 0, ">")
			end
		end
	elseif type == 3 then 
		if contains(ui_get(aa_indicators),"Text") then
			if anti_brute_FORCE then 
				client.draw_text(c, center_x, center_y + 28, r2,g2,b2,255, "c", 0, "DODGE")
			elseif holdingE then 
				client.draw_text(c, center_x, center_y + 28, r2,g2,b2,255, "c", 0, "LEGIT AA")
			else
				client.draw_text(c, center_x, center_y + 28, r2,g2,b2,255, "c", 0, "DYNAMIC")
			end
		end
		if contains(ui_get(aa_indicators),"Arrows") then
			if mode == 1 then 
				client.draw_text(c, center_x - 45, center_y, 163,160,163,255, "cb+", 0, "⯇")
				client.draw_text(c, center_x + 45, center_y, r,g,b,255, "cb+", 0, "⯈")
			elseif mode == 2 then
				client.draw_text(c, center_x - 60, center_y, 163,160,163,255, "cb+", 0, "<")
				client.draw_text(c, center_x + 45, center_y, r,g,b,255, "cb+", 0, ">")
			end
		end
	end
end

local function jitterSpumant()
	ui_set(aa_yaw, "180")
	ui_set(aa_yaw_offset, 0)
	ui_set(aa_body_yaw, "jitter")
	ui_set(aa_body_yaw_slider, 0)
	ui_set(aa_fake_limit,60)
end

local function handle_aa(type,offset)
	local duckamt = entity_get_prop(entity_get_local_player(),"m_flDuckAmount")
	local crouching_ct = duckamt >= 0.9 and is_crouching(entity_get_local_player()) and entity_get_prop(entity_get_local_player(),"m_iTeamNum") == 3 and not jumping_lp
	local crouching_t = duckamt >= 0.9 and is_crouching(entity_get_local_player()) and entity_get_prop(entity_get_local_player(),"m_iTeamNum") == 2 and not jumping_lp
    local weap = entity_get_player_weapon(entity_get_local_player())
    
    local lp_vel = get_velocity(entity_get_local_player())

    if weap ~= nil then
		local shot_time = entity_get_prop(entity_get_player_weapon(entity_get_local_player()), "m_fLastShotTime")

		if globals_curtime() - shot_time >= 3 then
			three_way_timer = globals_curtime() + 0.11
			first_shot_only = false
			three_way_choke = true
		else
			if three_way_choke then	
				if globals_curtime() > three_way_timer then
					first_shot_only = false
				else
					first_shot_only = true
				end
			end
		end
	end

    local desync_onshot = 
                        (
                            ui_get(onshot_bodyyaw) and aimbot_fired_time ~= nil 
                        and 
                            not crouching_t and not ui_get(misc_fakeduck_key) and not ui_get(misc_onshot_key)
                        and 
                            (is_record_valid(aimbot_fired_time,first_shot_only and 1 or 0.008))
						)	                       
    ui_set(aa_yaw, "180")
    ui_set(aa_lby, "Eye yaw")

    local should_flip = flip_angle and not is_crouching(entity_get_local_player())

    if type == 1 then 
        if isFreestanding and crouching_t and not jumping_lp then
            ui_set(aa_yaw_offset, 13)
            ui_set(aa_fake_limit, 58)
        elseif ui_get(fake_walk) and lp_vel > 5 then
            ui_set(aa_yaw_offset, 17)
            ui_set(aa_fake_limit, 23)
        else
            ui_set(aa_yaw_offset, lp_vel > 95 and 0 or 13)
            ui_set(aa_fake_limit, 33)
        end
        ui_set(aa_body_yaw, lp_vel > 95 and "jitter" or "static")
        ui_set(aa_body_yaw_slider, lp_vel > 95 and 109 or 180)
    else
        if not isFreestanding then 
            ui_set(aa_yaw_offset, type == 2 and 0 or type == 3 and 0)
            ui_set(aa_body_yaw, "static")
            ui_set(aa_body_yaw_slider, -180)
        else
            ui_set(aa_yaw_offset, (crouching_t and 13) or (type == 3 and crouching_ct and 17) or 0)
            ui_set(aa_body_yaw, "static")
			if anti_brute_FORCE then offset = -enemy_shot_angle[enemyclosesttocrosshair] end
			--if anti_PEEK then offset = -ui_get(aa_body_yaw_slider) end
			ui_set(aa_body_yaw_slider, 
									(desync_onshot and should_flip and offset) 
									or
									(desync_onshot and -offset)
									or
									(should_flip and -offset) or offset)	
        end

		local max_limit = holdingE and 58 or 60

		if type == 2 and not crouching_t and not jumping_lp then
			ui_set(aa_fake_limit, max_limit)
		elseif type == 3 and crouching_ct then
			ui_set(aa_fake_limit,max_limit/2 + client_random_int(3,6))
        else 
            ui_set(aa_fake_limit, max_limit)
        end
    end
end

local function on_paint(c)	
	flipJitter2 = not flipJitter2
    if not ui_get(enable_aa) then return end

    if entity_get_prop(entity_get_local_player(), "m_lifeState") ~= 0 then 
		return 
    end

    handle_directions()

    local players = entity_get_players(true)

	if(enemyclosesttocrosshair ~= nil and #players ~= 0) then
		realtime_freestand = DoFreestanding(enemyclosesttocrosshair, -90, 90)
		realtime_freestand_v2 = DoEarlyFreestanding(enemyclosesttocrosshair, -90, 90)
		
		if realtime_freestand ~= 0 and realtime_freestand ~= nil then
			stored_freestand = realtime_freestand
		end
		
		if realtime_freestand_v2 ~= 0 and realtime_freestand_v2 ~= nil then
			stored_freestand_v2 = realtime_freestand_v2
		end	
		
		if (realtime_freestand ~= 0 and realtime_freestand ~= nil) and realtime_freestand == 90 or realtime_freestand == -90 then
			adaptive_freestand = realtime_freestand
		elseif (realtime_freestand_v2 ~= 0 and realtime_freestand_v2 ~= nil) and realtime_freestand_v2 == 90 or realtime_freestand_v2 == -90 then
			adaptive_freestand = realtime_freestand_v2
		end
	end

	if ui_get(misc_ev4sion) then
		if evasion_time <= globals_realtime() then 
			if enemyclosesttocrosshair ~= nil and evasion_ent ~= nil and get_velocity(entity_get_local_player()) > 5  and evasion_ent ~= evasion_last_ent then
				local player_resource = entity_get_player_resource()
				if player_resource == nil then return end
                local ping = entity_get_prop(player_resource, "m_iPing", evasion_ent)
				local evasion_pingticks = time_to_ticks(ping / 1000) + 1
				if get_velocity(enemyclosesttocrosshair) <= maxspeed + 1 then
					evasion_vis_ticks = evasion_vis_ticks + 1
				end
				
				if evasion_vis_ticks > evasion_pingticks then
					evasion_time = globals_realtime() + 0.5
					flip_angle = true
				end
			else	
				evasion_vis_ticks = 0
				flip_angle = false
			end
		end
	end

    local no_angle = not (realtime_freestand ~= 0 and realtime_freestand ~= nil or realtime_freestand_v2 ~= 0 and realtime_freestand_v2)
	local direct_mode = ui_get(auto_dir_mode)

	anti_brute_FORCE = ui_get(anti_resolve) and available_resolver_information[enemyclosesttocrosshair] and enemy_shot_angle[enemyclosesttocrosshair] ~= nil and (enemy_shot_time[enemyclosesttocrosshair] ~= nil and enemy_shot_time[enemyclosesttocrosshair] > globals_curtime())
	--anti_PEEK = (realtime_freestand == 90 or realtime_freestand_v2 == 90 or realtime_freestand == -90 or realtime_freestand_v2 == -90) and not enemy_is_peeking_and_can_hit_us(enemyclosesttocrosshair) and not #players == 0 and not anti_brute_FORCE and not jumping_lp and get_velocity(entity_get_local_player()) < 80

	if #players == 0 and ui_get(off_jitter) > 0 and isFreestanding then
		ui_set(aa_yaw_jitter, "offset")
		ui_set(aa_yaw_jitter_offset, -ui_get(off_jitter))
	else
		ui_set(aa_yaw_jitter, "off")
	end

	if enemyclosesttocrosshair ~= nil and adjusted_freestand[enemyclosesttocrosshair] == nil then
		adjusted_freestand[enemyclosesttocrosshair] = 0
	end

    if isFreestanding then
		if (no_angle and dangerous_x_offset and dangerous_y_offset and not flip_angle and not jumping_lp and get_velocity(entity_get_local_player()) < 130) then
            handle_aa(1,0)
			handle_indicators(1,2)
		elseif (no_angle and dangerous_x_offset and dangerous_y_offset and not flip_angle and not jumping_lp and get_velocity(entity_get_local_player()) > 130) then
			jitterSpumant()
			handle_indicators(1,2)
		elseif direct_mode == "Adaptive" then
			if adaptive_freestand < 0 then
				if enemy_is_peeking_and_can_hit_us(enemyclosesttocrosshair) and (adjusted_freestand[enemyclosesttocrosshair] < globals_curtime()) then
					adjusted_freestand[enemyclosesttocrosshair] = globals_curtime() + 5
                    handle_aa(3,flipJitter and -2 or 0)
					handle_indicators(1,1)
				else
					if (adjusted_freestand[enemyclosesttocrosshair] ~= nil and adjusted_freestand[enemyclosesttocrosshair] > globals_curtime()) then
                        handle_aa(3,-180)
						handle_indicators(3,1)
					else
                        handle_aa(2,180)
						handle_indicators(2,1)
					end
				end	
			elseif adaptive_freestand > 0 then
				if enemy_is_peeking_and_can_hit_us(enemyclosesttocrosshair) and (adjusted_freestand[enemyclosesttocrosshair] < globals_curtime()) then
					adjusted_freestand[enemyclosesttocrosshair] = globals_curtime() + 5
                    handle_aa(2,flipJitter and 0 or 2)
					handle_indicators(1,1)
				else
					if (adjusted_freestand[enemyclosesttocrosshair] ~= nil and adjusted_freestand[enemyclosesttocrosshair] > globals_curtime()) then
                        handle_aa(2,180)
						handle_indicators(2,1)
					else
                        handle_aa(3,-180)
						handle_indicators(3,1)
					end
				end
			else
                handle_aa(1,0)
				handle_indicators(1,2)
			end
		elseif realtime_freestand == -90 or realtime_freestand_v2 == -90 then
			if direct_mode == "Safe head" then
                handle_aa(2,180)
				handle_indicators(2,1)
			elseif direct_mode == "Peek out" then
                handle_aa(3,-180)
				handle_indicators(3,1)
			end
		elseif realtime_freestand == 90 or realtime_freestand_v2 == 90 then
			if direct_mode == "Safe head" then
                handle_aa(3,-180)
				handle_indicators(3,1)
			elseif direct_mode == "Peek out" then
                handle_aa(2,180)
				handle_indicators(2,1)
			end
		else
            jitterSpumant()
			handle_indicators(1,2)
		end	
    end
end

local jitter = false
local jitter2 = true

client_set_event_callback("run_command", function ()
    if not ui_get(enable_aa) then return end

    flipJitter = not flipJitter

	local lp = entity_get_local_player()
	if lp == nil or not entity_is_alive(lp) then return end
	
	local lp_vel = get_velocity(lp)
	local jumping_lp = (client_key_state(0x20) and lp_vel > 100) or in_air(lp)
	local hit = can_enemy_hit_on_peek(enemyclosesttocrosshair,16) and not in_air(entity_get_local_player())
	local fakeduck = ui_get(misc_fakeduck_key)
    
    -- EDGE YAW
	if ui_get(edge_yaw_detection) and not can_enemy_hit_head(enemyclosesttocrosshair) and not jumping_lp and not ui_get(misc_fakeduck_key) and not holdingE then
		ui_set(aa_edge_yaw,true)
	else
		ui_set(aa_edge_yaw,false)
	end

    -- LEGS 
	if ui_get(leg_movement) then
		if hit then
			ui_set(misc_leg_movement,"off")
		else
			ui_set(misc_leg_movement,flipJitter and lp_vel > 100 and "always slide" or "never slide")
		end	
	else
		ui_set(misc_leg_movement,"never slide")
	end

	-- FAKE LAG 
	if ui_get(fake_lag) then
		if hit or jumping_lp then
			ui_set(fl_amount,"Fluctuate")	
			ui_set(fl_variance, 0)
		else
			ui_set(fl_amount,"Maximum")
			ui_set(fl_variance, 15)
		end
    end

	-- JITTER VELOCITY
	jitter = not jitter
	jitter2 = not jitter2

	if not ui_get(furia_twist) or jumping_lp then 
		setSpeed(450)
		return 
	end
	
	local standing_speed = nil
	local maximum_speed = nil
	local weaponname = "x"
	if lp ~= nil then
		local active_weapon = entity_get_prop(lp, "m_hActiveWeapon")
		if active_weapon ~= nil then
		
			local active_idx = entity_get_prop(active_weapon, "m_iItemDefinitionIndex")
			if active_idx ~= nil then

				active_idx = bit_band(active_idx, 0xFFFF)
				
				maximum_speed = weapons[active_idx].max_speed

				weaponname = weapons[active_idx].console_name
				local scoped = entity_get_prop(lp, "m_bIsScoped") == 1
				if (weaponname == "weapon_scar20" or weaponname == "weapon_g3sg1") then
					if scoped then
						maximum_speed = maximum_speed - 95
					end
				else
					if weaponname == "weapon_awp" then
						if scoped then
							maximum_speed = maximum_speed - 100
						end
					end
				end
				
				standing_speed = (maximum_speed / 100) * 33
			end
		end
	end
	
	if not ui_get(fake_walk) then
		if maximum_speed ~= nil and weaponname ~= "weapon_awp" then
			setSpeed(maximum_speed-(jitter and client_random_int(3,6) or client_random_int(7,10)))
		else
			setSpeed(450)
		end
	else
		if standing_speed ~= nil then
			setSpeed(standing_speed-(jitter2 and 4 or 2))
		else
			setSpeed(40)
		end
	end	
end)

client_set_event_callback("setup_command", function (e)
	local entindex = entity_get_local_player()
	if entindex == nil then return end
	local lx,ly,lz = entity_get_prop(entindex, "m_vecOrigin")
	if lx == nil then return end

	local weapz = entity_get_player_weapon(entity_get_local_player())
	local is_bomb = weapz ~= nil and entity_get_classname(weapz) == "CC4"

	if ui_get(legit_aa_on_e) and not is_bomb and client_key_state(0x45) then
		if e.chokedcommands == 0 then
			e.in_use = 0
			holdingE = true
		end
	else
		holdingE = false
	end

	local my_velo = get_velocity(entity_get_local_player())
	if (my_velo > 80 and not ui_get(fake_walk)) then
		was_moving = true
		should_trigger = false
		time_moving = globals_curtime() + 0.15
	else
		if was_moving then
			if globals_curtime() > time_moving then
				should_trigger = false
				was_moving = false
			else
				should_trigger = true				
			end
		end
	end
	
	local players = entity_get_players(true)	
	local pitch, yaw = client_camera_angles()
	local vx, vy, vz = angle_to_vec(pitch, yaw)
    
    local closest_fov_cos = -1
	enemyclosesttocrosshair = nil
	for i=1, #players do
		local idx = players[i]
		if entity_is_alive(idx) then
			local fov_cos = get_fov_cos(idx, vx,vy,vz, lx,ly,lz)
			if fov_cos > closest_fov_cos then
				closest_fov_cos = fov_cos
				enemyclosesttocrosshair = idx
			end
		end
	end

	if enemyclosesttocrosshair ~= nil then
		local active_weapon = entity_get_prop(enemyclosesttocrosshair, "m_hActiveWeapon")
		
		if active_weapon ~= nil then
		
			local active_idx = entity_get_prop(active_weapon, "m_iItemDefinitionIndex")
			if active_idx ~= nil then
				active_idx = bit_band(active_idx, 0xFFFF)
				
				maxspeed = weapons[active_idx].max_speed
				local weaponname = weapons[active_idx].console_name
				local scoped = entity_get_prop(enemyclosesttocrosshair, "m_bIsScoped") == 1
				if (weaponname == "weapon_scar20" or weaponname == "weapon_g3sg1") then
					if scoped then
						maxspeed = maxspeed - 95
					end
				else
					if weaponname == "weapon_awp" then
						if scoped then
							maxspeed = maxspeed - 100
						end
					end
				end

				maxspeed = (maxspeed / 100) * 33
			end
		end
	end

	if(enemyclosesttocrosshair ~= nil and #players ~= 0 ) then
		if entity_is_dormant(enemyclosesttocrosshair) then return end
		local hx,hy,hz = entity_hitbox_position(entity_get_local_player(), 0)
		local lx,ly,lz = client_eye_position()
		lz = hz
		local _, eye_yaw = entity_get_prop(entity_get_local_player(), "m_angEyeAngles")
		local desync = normalise_angle(eye_yaw - get_body_yaw(entity_get_local_player()))
		lx = lx + math_cos(math_rad(desync)) * 20
		ly = ly + math_sin(math_rad(desync)) * 12	
		
		local ex,ey,ez = entity_get_prop(enemyclosesttocrosshair, "m_vecOrigin")
		local vx,vy,vz = entity_get_prop(enemyclosesttocrosshair, "m_vecViewOffset")
		ex,ey,ez = ex+vx,ey+vy,ez+vz
		
		local ent,damage = client_trace_bullet(enemyclosesttocrosshair, ex, ey, ez, lx, ly, lz,true)
		local input_dmg = 80
		local scaled_dmg = client_scale_damage(enemyclosesttocrosshair, 1, damage)

		if scaled_dmg > input_dmg then
			evasion_last_ent = evasion_ent
			evasion_ent = enemyclosesttocrosshair
		else
			evasion_last_ent = evasion_ent
			evasion_ent = nil
		end

		local left_dsy = normalise_angle(desync - get_max_body_yaw(entity_get_local_player()))
		local right_dsy = normalise_angle(desync - -(get_max_body_yaw(entity_get_local_player())))
		local lx_left = lx + math_cos(math_rad(left_dsy)) * 20
		local ly_left = ly + math_sin(math_rad(left_dsy)) * 15
		local lx_right = lx + math_cos(math_rad(right_dsy)) * 20
		local ly_right = ly + math_sin(math_rad(right_dsy)) * 15

		local ent1,damage1 = client_trace_bullet(enemyclosesttocrosshair, ex, ey, ez, lx_left, ly_left, lz,true)
		local ent2,damage2 = client_trace_bullet(enemyclosesttocrosshair, ex, ey, ez, lx_right, ly_right, lz,true)
		
		local is_moving = get_velocity(enemyclosesttocrosshair) > 20
		local extra_x, extra_y, extra_z = extrapolate_position(ex, ey, ez, 20, enemyclosesttocrosshair)

		if damage1 > 55 then
			dangerous_x_offset = true
		else
			local ent1,damage1 = client_trace_bullet(enemyclosesttocrosshair, extra_x, extra_y, extra_z, lx_left, ly_left, lz,true)
			if damage1 > 35 and is_moving and not in_air(enemyclosesttocrosshair) then 
				dangerous_x_offset = true
			else
				dangerous_x_offset = false
			end
		end

		if damage2 > 55 then
			dangerous_y_offset = true
		else 
			local ent2,damage2 = client_trace_bullet(enemyclosesttocrosshair, extra_x, extra_y, extra_z, lx_right, ly_right, lz,true)
			if damage2 > 35 and is_moving and not in_air(enemyclosesttocrosshair) then 
				dangerous_y_offset = true
			else
				dangerous_y_offset = false
			end			
		end
	end
end)

client_set_event_callback("paint", on_paint)

client_set_event_callback("round_start", function (e)
	available_resolver_information = {}
	enemy_shot_angle = {}
	enemy_shot_time = {}
	adjusted_freestand = {}
end)

client_set_event_callback("cs_game_disconnected", function (e)
	available_resolver_information = {}
	enemy_shot_angle = {}
	enemy_shot_time = {}
	adjusted_freestand = {}
end)

client_set_event_callback("game_newmap", function (e)
	available_resolver_information = {}
	enemy_shot_angle = {}
	enemy_shot_time = {}
	adjusted_freestand = {}
end)

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
	ui_set_visible(misc_ev4sion, state_aa and state_dir)
	ui_set_visible(onshot_bodyyaw, state_aa)
	ui_set_visible(furia_twist, state_aa)
	ui_set_visible(legit_aa_on_e, state_aa)
	ui_set_visible(edge_yaw_detection, state_aa)
	ui_set_visible(fake_lag, state_aa)
	ui_set_visible(leg_movement, state_aa)
	ui_set_visible(more_traces, state_aa)
	ui_set_visible(aa_indicators, state_aa and state_dir)
end 

ui_set_visible(auto_direction, false)
ui_set_visible(auto_dir_mode, false)
ui_set_visible(anti_resolve, false)
ui_set_visible(off_jitter, false)
ui_set_visible(onshot_bodyyaw, false)
ui_set_visible(furia_twist, false)
ui_set_visible(legit_aa_on_e, false)
ui_set_visible(edge_yaw_detection, false)
ui_set_visible(misc_ev4sion, false)
ui_set_visible(fake_lag, false)
ui_set_visible(leg_movement, false)
ui_set_visible(more_traces, false)
ui_set_visible(aa_indicators, false)

ui_set_callback(enable_aa, handle_menu)
ui_set_callback(auto_direction, handle_menu)
