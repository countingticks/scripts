-- REFERENCES
local ref = {
	aa_state           = ui.reference("aa", "anti-aimbot angles", "enabled"),

	aa_pitch           = ui.reference("aa", "Anti-aimbot angles", "pitch"),
	aa_yaw_base        = ui.reference("aa", "Anti-aimbot angles", "yaw base"),
	aa_yaw             = { ui.reference("aa", "anti-aimbot angles", "yaw") },
	aa_yaw_jitter      = { ui.reference("aa", "anti-aimbot angles", "yaw jitter") },

	aa_fake_yaw        = { ui.reference("aa", "anti-aimbot angles", "body yaw") },
	aa_fs_byaw         = ui.reference("aa", "anti-aimbot angles", "freestanding body yaw"),
	aa_lby             = ui.reference("aa", "anti-aimbot angles", "lower body yaw target"),

	aa_body_limit      = ui.reference("aa", "anti-aimbot angles", "fake yaw limit"),
	aa_edge            = ui.reference("aa", "anti-aimbot angles", "edge yaw"),
	aa_fs_triggers     = { ui.reference("aa", "anti-aimbot angles", "freestanding") },

	misc_fakeduck      = ui.reference("rage", "other", "duck peek assist"),
	misc_legs          = ui.reference("aa", "other", "leg movement"),
	fake_walk          = { ui.reference("aa", "other", "slow motion") },

	misc_doubletap     = { ui.reference("rage", "other", "double tap") },
	misc_onshot        = { ui.reference("aa", "other", "on shot anti-aim") },

	player_list        = ui.reference('players', 'players' , 'player list')
}

local off_jitter_degree = {
    [0] = "Off"
}

-- MENU
local menu = {
	enable_aa          = ui.new_checkbox("aa", "anti-aimbot angles", "Anti aim"),

	aa_ev4sion         = ui.new_checkbox("aa", "anti-aimbot angles", "Evasion"),
	aa_ev4sion_slider  = ui.new_slider("aa", "anti-aimbot angles", "Chance to block hit", 40, 100, 50, true, "%"),
	aa_base            = ui.new_combobox("aa", "anti-aimbot angles", "Yaw base", "Local view", "At targets"),
	aa_dir_mode        = ui.new_combobox("aa", "anti-aimbot angles", "Body yaw", "Freestand", "Reversed"),

	aa_addons          = ui.new_multiselect("aa", "anti-aimbot angles", "Body yaw adds", "Prefer safe angles", "Anti resolve"),
	aa_jitter 		   = ui.new_multiselect("aa", "anti-aimbot angles", "Jitter", "Synced", "Full", "Weapon based"),
	aa_update          = ui.new_checkbox("aa", "anti-aimbot angles", "Always update freestand"),
	aa_off_jitter      = ui.new_slider("aa", "anti-aimbot angles", "Offset jitter", 0, 120, 20, true, "°", 1, off_jitter_degree),

	misc_legit_aa      = ui.new_checkbox("aa", "anti-aimbot angles", "E desync"),
	aa_onshot          = ui.new_checkbox("aa", "anti-aimbot angles", "Onshot desync"),
	misc_legmovement   = ui.new_checkbox("aa", "anti-aimbot angles", "Leg movement"),

	aa_low_delta       = ui.new_hotkey("aa", "anti-aimbot angles", "Low delta"),
	misc_edge_yaw      = ui.new_hotkey("aa", "anti-aimbot angles", "Edge yaw"),
	misc_ind           = ui.new_multiselect("aa", "anti-aimbot angles", "Indicators", "Arrows", "Gradient", "Doubletap", "Extra"),

	plist_adds         = ui.new_multiselect("players", "adjustments", "unique anti-aims", "custom slow mode", "low delta"),
	plist_slow         = ui.new_combobox("players", "adjustments", "mode", "anti-neverlose", "jitter", "canary")
}

-- GLOBALS
local CHECKBOX = 1
local MODE = 1
local KEYBIND = 2
local VALUE = 2

local local_player
local local_velocity
local local_jumping
local enemies
local enemyclosesttocrosshair
local scrsize_x, scrsize_y

local near_walls = {}
local closest_wall_side
local nearest_wall_index
local freestanding_angle
local stored_freestanding_angle
local freestanding_angle2
local stored_freestanding_angle2
local fs_angle
local holdingE
local flipJitter
local should_edge
local safe_edge
local flip_onshot = false
local isFreestanding = true
local isLowDelta = false
local enemies_visible = false

local aa_player_list = {}
local firedthistick = {}
local lastshottime = {}
local available_resolver_information = {}
local enemy_shot_angle = {}
local enemy_shot_time = {}
local anti_brute_FORCE = false
local jitter_backwards = false

local evasion_time = 0
local evasion_ent = nil
local evasion_last_ent = nil
local evasion_vis_ticks = 0
local maxspeed = 0
local flip_evasion = false
local height_advantage = false
local waterlevel_prev, movetype_prev

local wpn_auto = false
local wpn_awp = false
local wpn_ssg = false
local wpn_def = false

-- SOME FUNCTIONS
local function contains(table, val)
    for i = 1, #table do
        if table[i] == val then
            return true
        end
    end
    return false
end

for i = 1 , 64 do 
	aa_player_list[i] = {chk = false}
end

local function plist_add_element(name , menu_ref , elem_type , def)
	local callback = function()
		aa_player_list[ui.get(ref.player_list)]["" .. name] = ui.get(menu_ref)
	end 
	ui.set_callback(menu_ref,callback)

	local default = def 

	if default == nil then 
		if elem_type == "checkbox" then 
			default = true 
		elseif elem_type == "combo" or elem_type == "slider" then 
			default = 0
		else
			default = {}
		end 
	end

	for i = 1 , 64 do 
		aa_player_list[i]["" .. name] = default
	end 
end 

plist_add_element("plist_adds",menu.plist_adds , "multi")
plist_add_element("plist_slow",menu.plist_slow , "combo" , "canary")

local function set_plist()
	ui.set(menu.plist_adds,aa_player_list[ui.get(ref.player_list)]["plist_adds"]) 
	ui.set(menu.plist_slow,aa_player_list[ui.get(ref.player_list)]["plist_slow"]) 
end 
ui.set_callback(ref.player_list,set_plist)

local function Vector(x,y,z) 
	return {x=x or 0,y=y or 0,z=z or 0} 
end

local function Vector_distance(ax, ay, az, bx, by, bz)
    return math.sqrt(math.pow((ax-bx), 2) + math.pow((ay-by), 2) + math.pow((az-bz), 2))
end

local function vec3_normalize(x, y, z)
	local len = math.sqrt(x * x + y * y + z * z)
	if len == 0 then
		return 0, 0, 0
	end
	local r = 1 / len
	return x*r, y*r, z*r
end

local function vec3_dot(ax, ay, az, bx, by, bz)
	return ax*bx + ay*by + az*bz
end

local function angle_to_vec(pitch, yaw)
	local p, y = math.rad(pitch), math.rad(yaw)
	local sp, cp, sy, cy = math.sin(p), math.cos(p), math.sin(y), math.cos(y)
	return cp*cy, cp*sy, -sp
end

local function get_fov_cos(ent, vx,vy,vz, lx,ly,lz)
	local ox,oy,oz = entity.get_origin(ent)
	if ox == nil then
		return -1
	end

	local dx,dy,dz = vec3_normalize(ox-lx, oy-ly, oz-lz)
	return vec3_dot(dx,dy,dz, vx,vy,vz)
end

local function CalcAngle(localplayerxpos, localplayerypos, enemyxpos, enemyypos)
   local relativeyaw = math.atan((localplayerypos - enemyypos) / (localplayerxpos - enemyxpos))
    return relativeyaw * 180 / math.pi
end

local function GetClosestPoint(A, B, P)
   local a_to_p = { P[1] - A[1], P[2] - A[2] }
   local a_to_b = { B[1] - A[1], B[2] - A[2] }

   local atb2 = a_to_b[1]^2 + a_to_b[2]^2

   local atp_dot_atb = a_to_p[1]*a_to_b[1] + a_to_p[2]*a_to_b[2]
   local t = atp_dot_atb / atb2
    
    return { A[1] + a_to_b[1]*t, A[2] + a_to_b[2]*t }
end

-- OTHER FUNCTIONS
local function time_to_ticks(dt)
	return math.floor(0.5 + dt / globals.tickinterval() - 3)
end

function clamp(val, lower, upper)
    assert(val and lower and upper, "not very useful error message here")
    if lower > upper then lower, upper = upper, lower end
    return math.max(lower, math.min(upper, val))
end

local function get_lerp_time()
	local ud_rate = client.get_cvar("cl_updaterate")
	
	local min_ud_rate = client.get_cvar("sv_minupdaterate")
	local max_ud_rate = client.get_cvar("sv_maxupdaterate")

	if (min_ud_rate and max_ud_rate) then
		ud_rate = max_ud_rate
	end
	
	local ratio = client.get_cvar("cl_interp_ratio")

	if (ratio == 0) then
		ratio = 1
	end
	
	local lerp = client.get_cvar("cl_interp")
	local c_min_ratio = client.get_cvar("sv_client_min_interp_ratio")
	local c_max_ratio = client.get_cvar("sv_client_max_interp_ratio")

	if (c_min_ratio and  c_max_ratio and  c_min_ratio ~= 1) then
		ratio = clamp(ratio, c_min_ratio, c_max_ratio)
	end
	
	return math.max(lerp, (ratio / ud_rate));
end

local function is_record_valid(player_time,ms)
	local correct = 0
	local sv_maxunlag = 0.2
	
	correct = correct + get_lerp_time()
	correct = correct + client.latency()
	correct = clamp(correct, 0, ms);
	
	local delta = correct - (globals.curtime() - player_time);
	
	if math.abs(delta) > ms then
		return false
	end
	
	return true
end

local function extrapolate_position(xpos,ypos,zpos,ticks,player)
	local x,y,z = entity.get_prop(player, "m_vecVelocity")
	for i=0, ticks do
		xpos =  xpos + (x*globals.tickinterval())
		ypos =  ypos + (y*globals.tickinterval())
		zpos =  zpos + (z*globals.tickinterval())
	end
	return xpos,ypos,zpos
end

local function normalise_angle(angle)
	angle =  angle % 360 
	angle = (angle + 360) % 360
	if (angle > 180)  then
		angle = angle - 360
	end
	return angle
end

local function get_velocity(player)
	local x,y,z = entity.get_prop(player, "m_vecVelocity")
	if x == nil then return end
	return math.sqrt(x*x + y*y + z*z)
end

local function get_body_yaw(player)
	local _, model_yaw = entity.get_prop(player, "m_angAbsRotation")
	local _, eye_yaw = entity.get_prop(player, "m_angEyeAngles")
	if model_yaw == nil or eye_yaw ==nil then return 0 end
	return normalise_angle(model_yaw - eye_yaw)
end

local function in_air(player)
	local flags = entity.get_prop(player, "m_fFlags")
	
	if bit.band(flags, 1) == 0 then
		return true
	end
	
	return false
end

local function is_crouching(player)
	local flags = entity.get_prop(player, "m_fFlags")
	
	if bit.band(flags, 4) == 4 then
		return true
	end
	
	return false
end

-- WEAPONS
local weapons, weapons_index = {}, {}
local weapons_data, weapons_data_types = {[1]={"deagle",1,230,700,"Desert Eagle",7,0.225},[2]={"elite",1,240,400,"Dual Berettas",30,0.12},[3]={"fiveseven",1,240,500,"Five-SeveN",20,0.15},[4]={"glock",1,240,200,"Glock-18",20,0.15},[7]={"ak47",2,215,2700,"AK-47",30,0.1},[8]={"aug",2,220,3300,"AUG",30,0.09},[9]={"awp",2,200,4750,"AWP",10,1.455},[10]={"famas",2,220,2250,"FAMAS",25,0.09},[11]={"g3sg1",2,215,5000,"G3SG1",20,0.25},[13]={"galilar",2,215,2000,"Galil AR",35,0.09},[14]={"m249",3,195,5200,"M249",100,0.08},[16]={"m4a1",2,225,3100,"M4A4",30,0.09},[17]={"mac10",4,240,1050,"MAC-10",30,0.075},[19]={"p90",4,230,2350,"P90",50,0.07},[23]={"mp5sd",4,235,1500,"MP5-SD",30,0.08},[24]={"ump45",4,230,1200,"UMP-45",25,0.09},[25]={"xm1014",3,215,2000,"XM1014",7,0.35},[26]={"bizon",4,240,1400,"PP-Bizon",64,0.08},[27]={"mag7",3,225,1300,"MAG-7",5,0.85},[28]={"negev",3,150,1700,"Negev",150,0.075},[29]={"sawedoff",3,210,1100,"Sawed-Off",7,0.85},[30]={"tec9",1,240,500,"Tec-9",18,0.12},[31]={"taser",5,220,200,"Zeus x27",1,0.15},[32]={"hkp2000",1,240,200,"P2000",13,0.17},[33]={"mp7",4,220,1500,"MP7",30,0.08},[34]={"mp9",4,240,1250,"MP9",30,0.07},[35]={"nova",3,220,1050,"Nova",8,0.88},[36]={"p250",1,240,300,"P250",13,0.15},[38]={"scar20",2,215,5000,"SCAR-20",20,0.25},[39]={"sg556",2,210,2750,"SG 553",30,0.09},[40]={"ssg08",2,230,1700,"SSG 08",10,1.25},[41]={"knifegg",6,250,0,"Knife",-1,0.15},[42]={"knife",6,250,0,"Knife",-1,0.15},[43]={"flashbang",7,245,200,"Flashbang",-1,0.15},[44]={"hegrenade",7,245,300,"High Explosive Grenade",-1,0.15},[45]={"smokegrenade",7,245,300,"Smoke Grenade",-1,0.15},[46]={"molotov",7,245,400,"Molotov",-1,0.15},[47]={"decoy",7,245,50,"Decoy Grenade",-1,0.15},[48]={"incgrenade",7,245,600,"Incendiary Grenade",-1,0.15},[49]={"c4",8,250,0,"C4 Explosive",-1,0.15},[50]={"item_kevlar",5,1,650,"Kevlar Vest",-1,0.15},[51]={"item_assaultsuit",5,1,1000,"Kevlar + Helmet",-1,0.15},[52]={"item_heavyassaultsuit",5,1,6000,"Heavy Assault Suit",-1,0.15},[55]={"item_defuser",5,1,400,"Defuse Kit",-1,0.15},[56]={"item_cutters",5,1,400,"Rescue Kit",-1,0.15},[57]={"healthshot",9,250,0,"Medi-Shot",-1,0.15},[59]={"knife_t",6,250,0,"Knife",-1,0.15},[60]={"m4a1_silencer",2,225,3100,"M4A1-S",25,0.1},[61]={"usp_silencer",1,240,200,"USP-S",12,0.17},[63]={"cz75a",1,240,500,"CZ75-Auto",12,0.1},[64]={"revolver",1,180,600,"R8 Revolver",8,0.5},[68]={"tagrenade",7,245,100,"Tactical Awareness Grenade",-1,0.15},[69]={"fists",6,275,0,"Bare Hands",-1,0.15},[70]={"breachcharge",8,245,300,"Breach Charge",3,0.15},[72]={"tablet",10,220,300,"Tablet",1,0.15},[74]={"melee",6,250,0,"Knife",-1,0.15},[75]={"axe",6,250,0,"Axe",-1,0.15},[76]={"hammer",6,250,0,"Hammer",-1,0.15},[78]={"spanner",6,250,0,"Wrench",-1,0.15},[80]={"knife_ghost",6,250,0,"Spectral Shiv",-1,0.15},[81]={"firebomb",7,245,400,"Fire Bomb",-1,0.15},[82]={"diversion",7,245,50,"Diversion Device",-1,0.15},[83]={"frag_grenade",7,245,300,"Frag Grenade",-1,0.15},[84]={"snowball",7,245,100,"Snowball",-1,0.15},[500]={"bayonet",6,250,0,"Bayonet",-1,0.15},[505]={"knife_flip",6,250,0,"Flip Knife",-1,0.15},[506]={"knife_gut",6,250,0,"Gut Knife",-1,0.15},[507]={"knife_karambit",6,250,0,"Karambit",-1,0.15},[508]={"knife_m9_bayonet",6,250,0,"M9 Bayonet",-1,0.15},[509]={"knife_tactical",6,250,0,"Huntsman Knife",-1,0.15},[512]={"knife_falchion",6,250,0,"Falchion Knife",-1,0.15},[514]={"knife_survival_bowie",6,250,0,"Bowie Knife",-1,0.15},[515]={"knife_butterfly",6,250,0,"Butterfly Knife",-1,0.15},[516]={"knife_push",6,250,0,"Shadow Daggers",-1,0.15},[519]={"knife_ursus",6,250,0,"Ursus Knife",-1,0.15},[520]={"knife_gypsy_jackknife",6,250,0,"Navaja Knife",-1,0.15},[522]={"knife_stiletto",6,250,0,"Stiletto Knife",-1,0.15},[523]={"knife_widowmaker",6,250,0,"Talon Knife",-1,0.15},[1349]={"spraypaint",11,250,0,"Graffiti",0,0}}, {"secondary","rifle","heavy","smg","equipment","melee","grenade","c4","boost","utility","spray"}

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
		idx = bit.band(idx, 0xFFFF)
		return rawget(weapons, idx)
	end
end

-- HVH SHIT
local function return_wall_info(facing_offset) 
    local camera_angles = Vector(client.camera_angles())
    local resulted_direction = Vector(angle_to_vec(0, camera_angles.y + facing_offset))

    local local_player_origin = Vector(entity.get_origin(local_player))

    if is_crouching(local_player) then
        local_player_origin.z = local_player_origin.z + 46 
    else
        local_player_origin.z = local_player_origin.z + 60
    end
    
    local trace_stop = Vector(local_player_origin.x + resulted_direction.x * 8192, local_player_origin.y + resulted_direction.y * 8192, local_player_origin.z + resulted_direction.z * 8192)
    local trace_start = Vector(local_player_origin.x + resulted_direction.x * 5, local_player_origin.y + resulted_direction.y * 5, local_player_origin.z + resulted_direction.z * 5)
    local trace_result_fraction, trace_result_entity_index = client.trace_line(local_player, trace_start.x, trace_start.y, trace_start.z, trace_stop.x, trace_stop.y, trace_stop.z)

    local startx, starty = renderer.world_to_screen(trace_start.x, trace_start.y, trace_start.z)
    local stopx, stopy = renderer.world_to_screen(trace_stop.x, trace_stop.y, trace_stop.z)

    if trace_result_fraction == 1 then
        return {false, 0, 0, 0}
    end

    return {true, local_player_origin.x + resulted_direction.x * trace_result_fraction * 8192, local_player_origin.y + resulted_direction.y * trace_result_fraction * 8192, local_player_origin.z + resulted_direction.z * trace_result_fraction * 8192, trace_result_fraction}
end

local function compute_directions()
	if ui.get(menu.aa_low_delta) then
		isLowDelta, isFreestanding = true, false
	else
		isLowDelta, isFreestanding = false, true
	end
end

local function compute_traces()
    near_walls[1] = return_wall_info(45)
    near_walls[2] = return_wall_info(90)
    near_walls[3] = return_wall_info(135)
    near_walls[4] = return_wall_info(-45)
    near_walls[5] = return_wall_info(-90)
    near_walls[6] = return_wall_info(-135)
end

local function get_closest_wall_side()
    local min_trace_id = -1

    for i = 1, #near_walls do
        if near_walls[i][1] then
            if min_trace_id == -1 or near_walls[i][5] < near_walls[min_trace_id][5] then
                min_trace_id = i
            end
        end
    end

    nearest_wall_index = min_trace_id

    if min_trace_id == -1 then
        return 3
    end

    if min_trace_id < 3 then
        return 0
    end

    return 1
end

local function enemy_visible(idx)
    for i=0, 8 do
        local cx, cy, cz = entity.hitbox_position(idx, i)
        if client.visible(cx, cy, cz) then
            return true
        end
    end
    return false
end

local function enemy_is_visile()
	local players = entity.get_players(true)

    for i=1, #players do

        local idx = players[i]

        if enemy_visible(idx) then
            enemies_visible = true
        end
	end
end

local function get_ticks_amount(max_ticks_number)
	local ticks_to_extrapolate
	if (local_velocity < 50) then
		ticks_to_extrapolate = max_ticks_number
	elseif (local_velocity >= 50 and local_velocity < 120) then
		ticks_to_extrapolate = max_ticks_number / 1.5
	elseif (local_velocity >= 120 and local_velocity < 190) then
		ticks_to_extrapolate = max_ticks_number / 2
	elseif (local_velocity >= 190) then
		ticks_to_extrapolate = max_ticks_number / 3
	else
		ticks_to_extrapolate = 16
	end
	return ticks_to_extrapolate
end

local function return_freestanding(enemy, ...)
	if enemy == nil then
		return
	end
	
	local local_player_origin = Vector(entity.get_origin(local_player))
	local enemy_origin = Vector(entity.get_origin(enemy))
	local bestangle = nil
	local lowest_dmg = math.huge

	if(entity.is_alive(enemy)) then
		local ForwardOffset = CalcAngle(local_player_origin.x, local_player_origin.y, enemy_origin.x, enemy_origin.y)
		for i,v in pairs({...}) do
			local new_direction = Vector(angle_to_vec(0, (ForwardOffset + v)))
			local trace_stop = Vector(local_player_origin.x + new_direction.x * 55, local_player_origin.y + new_direction.y * 55, local_player_origin.z + 80)
			
			local _, damage1 = client.trace_bullet(enemy, enemy_origin.x, enemy_origin.y, enemy_origin.z + 70, trace_stop.x, trace_stop.y, trace_stop.z, true)
			local _, damage2 = client.trace_bullet(enemy, enemy_origin.x, enemy_origin.y, enemy_origin.z + 70, trace_stop.x + 12, trace_stop.y, trace_stop.z, true)
			local _, damage3 = client.trace_bullet(enemy, enemy_origin.x, enemy_origin.y, enemy_origin.z + 70, trace_stop.x - 12, trace_stop.y, trace_stop.z, true)

			if(damage1 < lowest_dmg) then
				lowest_dmg = damage1
			if(damage2 > damage1) then
				lowest_dmg = damage2
			end
			if(damage3 > damage1) then
				lowest_dmg = damage3
			end	
			if(local_player_origin.x - enemy_origin.x > 0) then
				bestangle = v
			else
				bestangle = v * -1
			end
			elseif(damage1 == lowest_dmg) then
				return 0
			end
		end
	end
	return bestangle
end

local function early_freestanding(enemy, ...)
	if enemy == nil then
		return
	end

	local local_player_origin = Vector(entity.get_origin(local_player))
	local enemy_origin = Vector(entity.get_origin(enemy))
	local bestangle = nil
	local lowest_dmg = math.huge
	local last_moving_time = 0
	local stored_eyepos_x, stored_eyepos_y, stored_eyepos_z = nil
	-- I DONT EVEN KNOW WHY THIS WORKS
	if(entity.is_alive(enemy)) then
		local ForwardOffset = CalcAngle(local_player_origin.x, local_player_origin.y, enemy_origin.x, enemy_origin.y)
		for i,v in pairs({...}) do
			local new_direction = Vector(angle_to_vec(0, (ForwardOffset + v)))
			local trace_stop = Vector(local_player_origin.x + new_direction.x * 55, local_player_origin.y + new_direction.y * 55, local_player_origin.z + 80)
			-- EXTRAPOLATE
			local eyepos = Vector(client.eye_position())
			local stored_eyepos = Vector(client.eye_position())
			local ticks_to_extrapolate = get_ticks_amount(64)

			if local_velocity > 15 then
				eyepos = Vector(extrapolate_position(eyepos.x, eyepos.y, eyepos.z, ticks_to_extrapolate, local_player))
				stored_eyepos_x, stored_eyepos_y, stored_eyepos_z = eyepos.x, eyepos.y, eyepos.z
				last_moving_time = globals.curtime() + 1
			else
				if last_moving_time ~= 0 then
					if globals.curtime() > last_moving_time then
						last_moving_time = 0
						stored_eyepos_x, stored_eyepos_y, stored_eyepos_z = nil
					else
						eyepos.x, eyepos.y, eyepos.z = stored_eyepos_x, stored_eyepos_y, stored_eyepos_z
					end
				else
					eyepos.x, eyepos.y, eyepos.z = extrapolate_position(eyepos.x, eyepos.y, eyepos.z, ticks_to_extrapolate, local_player)
				end
			end
			
			local _, damage1 = client.trace_bullet(local_player, enemy_origin.x, enemy_origin.y, enemy_origin.z + 70, trace_stop.x, trace_stop.y, trace_stop.z, true)
			local _, damage2 = client.trace_bullet(local_player, enemy_origin.x, enemy_origin.y, enemy_origin.z + 70, trace_stop.x + 12, trace_stop.y, trace_stop.z, true)
			local _, damage3 = client.trace_bullet(local_player, enemy_origin.x, enemy_origin.y, enemy_origin.z + 70, trace_stop.x - 12, trace_stop.y, trace_stop.z, true)

			if stored_eyepos_x ~= nil then
				_, damage1 = client.trace_bullet(local_player, stored_eyepos_x, stored_eyepos_y, stored_eyepos_z + 70, trace_stop.x, trace_stop.y, trace_stop.z, true)
				_, damage2 = client.trace_bullet(local_player, stored_eyepos_x, stored_eyepos_y, stored_eyepos_z + 70, trace_stop.x + 12, trace_stop.y, trace_stop.z, true)
				_, damage3 = client.trace_bullet(local_player, stored_eyepos_x, stored_eyepos_y, stored_eyepos_z + 70, trace_stop.y - 12, trace_stop.y, trace_stop.z, true)
			end

			if(damage1 < lowest_dmg) then
				lowest_dmg = damage1
			if(damage2 > damage1) then
				lowest_dmg = damage2
			end
			if(damage3 > damage1) then
				lowest_dmg = damage3
			end	
			if(local_player_origin.x - enemy_origin.x > 0) then
				bestangle = v
			else
				bestangle = v * -1
			end
			elseif(damage1 == lowest_dmg) then
				return 0 
			end
		end
	end
	return bestangle
end

local function is_Feet_Exposed(enemy,ticks)	
	if enemy == nil then
		return
	end	
	
	local enemy_origin = Vector(entity.get_origin(enemy))
	
	local hitbox1 = Vector(entity.hitbox_position(local_player, 11))
	local hitbox2 = Vector(entity.hitbox_position(local_player, 12))

	local fakelag_hitbox1 = Vector(extrapolate_position(hitbox1.x, hitbox1.y, hitbox1.z, ticks, local_player))
	local fakelag_hitbox2 = Vector(extrapolate_position(hitbox2.x, hitbox2.y, hitbox2.z, ticks, local_player))
	
	local _, dmg1 = client.trace_bullet(enemy, enemy_origin.x, enemy_origin.y, enemy_origin.z, fakelag_hitbox1.x, fakelag_hitbox1.y, fakelag_hitbox1.z, true)
	local _, dmg2 = client.trace_bullet(enemy, enemy_origin.x, enemy_origin.y, enemy_origin.z, fakelag_hitbox2.x, fakelag_hitbox2.y, fakelag_hitbox2.z, true)

	local left_hittable = dmg1 ~= nil and dmg1 > 12
	local right_hittable = dmg2 ~= nil and dmg2 > 12
	local hittable = (left_hittable or right_hittable) and local_velocity > 32
	
	return hittable
end

local function can_enemy_hit_head(ent)
	if ent == nil then return end
	if in_air(ent) then return false end
	
	local origin_x, origin_y, origin_z = entity.get_prop(ent, "m_vecOrigin")
	if origin_z == nil then return end
	origin_z = origin_z + 64

	local hx,hy,hz = entity.hitbox_position(entity.get_local_player(), 0) 
	local _, head_dmg = client.trace_bullet(ent, origin_x, origin_y, origin_z, hx, hy, hz, true)
		
	return head_dmg ~= nil and head_dmg > 25
end

local function ShouldPreserve(enemy)
	if enemy == nil then
		return
	end
	
	local lp_origin = Vector(entity.get_origin(local_player))
	local enemy_origin = Vector(entity.get_origin(enemy))

    local distanceToEnemy = Vector_distance(lp_origin.x, lp_origin.y, lp_origin.z, enemy_origin.x, enemy_origin.y, enemy_origin.z)
    local distanceToWall = Vector_distance(lp_origin.x, lp_origin.y, lp_origin.z, near_walls[nearest_wall_index][2], near_walls[nearest_wall_index][3], near_walls[nearest_wall_index][4])

	local standing = local_velocity < 3
    local first = (standing and nearest_wall_index ~= -1 and distanceToWall < 100)
    local second = (nearest_wall_index ~= -1 and distanceToWall < 100 and distanceToEnemy < 250)
    
    if ( first or second ) then
        return true
	end
	
    return false
end

local function is_edge_safe(enemy)
	if enemy == nil then
		return
	end
	
	local enemy_origin = Vector(entity.get_origin(enemy))
	local enemy_predict = Vector(extrapolate_position(enemy_origin.x, enemy_origin.y, enemy_origin.z, 16, enemy))
	
	local head_hitbox = Vector(entity.hitbox_position(local_player, 0))
	
	local _, damage1 = client.trace_bullet(enemy, enemy_origin.x, enemy_origin.y, enemy_origin.z, head_hitbox.x, head_hitbox.y, head_hitbox.z, true)
	local _, damage2 = client.trace_bullet(enemy, enemy_predict.x, enemy_predict.y, enemy_predict.z, head_hitbox.x, head_hitbox.y, head_hitbox.z, true)
	
    if (damage2 > 25) then
        return false
	end

    if (damage1 < 25) then
        return true
	end
		
    return false
end

local function aim_fire()
	if not ui.get(menu.enable_aa) then
		return
	end
	
	if ui.get(menu.aa_onshot) then
		flip_onshot = true
	end
end

local function weapon_fire(c)
	if not ui.get(menu.enable_aa) then
		return
	end
	
	if not ui.get(menu.aa_ev4sion) then
		return
	end
	
	local entindex = client.userid_to_entindex(c.userid)
	if not entity.is_enemy(entindex) then
		return
	end
	
	lastshottime[entindex] = globals.curtime()  - 0.03125
end

local function can_hit(entity)
	return (flip_evasion and enemyclosesttocrosshair == entity and not height_advantage)
end
local function has_height(entity)
	return (height_advantage and enemyclosesttocrosshair == entity)
end
local function shot_rn(entity)
	return (firedthistick[enemyclosesttocrosshair] and enemyclosesttocrosshair == entity)
end

local function apply_offsets(mode,offset)
	local eschiva = flip_evasion and not is_crouching(local_player) and not shot_rn(enemyclosesttocrosshair) and not height_advantage
	local duckamt = entity.get_prop(local_player,"m_flDuckAmount")
	local crouching_ct = duckamt >= 0.9 and is_crouching(local_player) and entity.get_prop(local_player,"m_iTeamNum") == 3 and not local_jumping
	local crouching_t = duckamt >= 0.9 and is_crouching(local_player) and entity.get_prop(local_player,"m_iTeamNum") == 2 and not local_jumping
	local set_plist_adds = {}
	local set_plist_slow = false

	if enemyclosesttocrosshair ~= nil and not entity.is_dormant(enemyclosesttocrosshair) then
		set_plist_adds = aa_player_list[enemyclosesttocrosshair]["plist_adds"]
		set_plist_slow = aa_player_list[enemyclosesttocrosshair]["plist_slow"]
	end

	ui.set(ref.aa_yaw[MODE], "180")
	ui.set(ref.aa_yaw_base, ui.get(menu.aa_base) == "Local view" and "Local view" or "At targets")
	if mode == 1 then
		-- LOW DELTA
		ui.set(ref.aa_yaw[VALUE], 15)
		ui.set(ref.aa_body_limit, 23)
		ui.set(ref.aa_yaw_jitter[MODE], "offset")
		ui.set(ref.aa_yaw_jitter[VALUE], 0) 
		ui.set(ref.aa_fake_yaw[MODE], "static")
		ui.set(ref.aa_fake_yaw[VALUE], 180)
	elseif mode == 5 then
		-- ANTI-NEVERLOSE
		ui.set(ref.aa_yaw[VALUE], 1)
		ui.set(ref.aa_body_limit, 2)
		ui.set(ref.aa_yaw_jitter[MODE], "center")
		ui.set(ref.aa_yaw_jitter[VALUE], 44) 
		ui.set(ref.aa_fake_yaw[MODE], "jitter")
		ui.set(ref.aa_fake_yaw[VALUE], 60)
	elseif mode == 6 then
		-- JITTER 
		ui.set(ref.aa_yaw[VALUE], 7)
		ui.set(ref.aa_body_limit, 54)
		ui.set(ref.aa_yaw_jitter[MODE], "center")
		ui.set(ref.aa_yaw_jitter[VALUE], 5) 
		ui.set(ref.aa_fake_yaw[MODE], "jitter")
		ui.set(ref.aa_fake_yaw[VALUE], 118)
	elseif mode == 7 then
		-- CANARY
		ui.set(ref.aa_yaw[VALUE], 1)
		ui.set(ref.aa_body_limit, 15)
		ui.set(ref.aa_yaw_jitter[MODE], "offset")
		ui.set(ref.aa_yaw_jitter[VALUE], -25) 
		ui.set(ref.aa_fake_yaw[MODE], "static")
		ui.set(ref.aa_fake_yaw[VALUE], -90)
	elseif mode == 4 then
		-- JITTER NEBUNATIC
		ui.set(ref.aa_yaw[VALUE], offset)
		ui.set(ref.aa_fake_yaw[MODE], "jitter")
		ui.set(ref.aa_fake_yaw[VALUE], 0)
		ui.set(ref.aa_body_limit, 48)
	else
		-- IDEAL YAW
		ui.set(ref.aa_yaw[VALUE], (mode == 3 and crouching_ct and 17) or 0)
		ui.set(ref.aa_fake_yaw[MODE], contains(ui.get(menu.aa_jitter), "Synced") and not (crouching_ct or crouching_t) and not (should_edge and safe_edge) and "jitter" or "static")
		
		if anti_brute_FORCE and not eschiva then ui.set(ref.aa_fake_yaw[MODE], "static") offset = -enemy_shot_angle[enemyclosesttocrosshair] end
		if eschiva then offset = -offset end
		ui.set(ref.aa_fake_yaw[VALUE], (flip_onshot and -offset) or (jitter_backwards and 0 or offset))

		-- SET DESYNC LIMIT
		if mode == 3 and crouching_ct then
			ui.set(ref.aa_body_limit,30 + client.random_int(3,6))
		else
			ui.set(ref.aa_body_limit, holdingE and 58 or (contains(set_plist_adds, "low delta") and 23 or 60))
		end

		-- SET LOWER BODY YAW
		ui.set(ref.aa_lby, ui.get(ref.misc_doubletap[CHECKBOX]) and ui.get(ref.misc_doubletap[KEYBIND]) and "eye yaw" or "sway")
	end
end

-- MAIN THREADS
local function bullet_impact(e)
	if not ui.get(menu.enable_aa) then
		return
	end
	
	if contains(ui.get(menu.aa_addons),"Anti resolve") and entity.is_alive(local_player) then
        local entity_index = client.userid_to_entindex(e.userid)
		if not entity.is_alive(entity_index) then
			return
		end
		
        if not entity.is_dormant(entity_index) and entity.is_enemy(entity_index) and entity_index == enemyclosesttocrosshair then	
            local shot_origin = { entity.get_origin(entity_index) }
            shot_origin[3] = shot_origin[3] + entity.get_prop(entity_index, "m_vecViewOffset[2]")
			
            local hitbox_pos = { entity.hitbox_position(entity.get_local_player(), 0) }
            local closest = GetClosestPoint(shot_origin, { e.x, e.y, e.z }, hitbox_pos)
			
            local delta = { hitbox_pos[1]-closest[1], hitbox_pos[2]-closest[2] }
            local delta_2d = math.sqrt(delta[1]^2+delta[2]^2)
			
            if math.abs(delta_2d) < 32 and ui.get(ref.aa_yaw[VALUE]) == 0 and ui.get(ref.aa_body_limit) > 40 then
                available_resolver_information[entity_index] = true
				enemy_shot_angle[entity_index] = ui.get(ref.aa_fake_yaw[VALUE])
				enemy_shot_time[entity_index] = globals.curtime() + 3.1
			else
				available_resolver_information[entity_index] = false
            end
		else
			available_resolver_information[entity_index] = false
        end
    end
end

local function setup_command(cmd)
	if not ui.get(menu.enable_aa) then
		return
	end
	
	local_player = entity.get_local_player()
	local_velocity = get_velocity(local_player)
	flipJitter = not flipJitter

    enemies = entity.get_players(true)
	local pitch, yaw = client.camera_angles()
	local vx, vy, vz = angle_to_vec(pitch, yaw)
	local local_player_origin = Vector(entity.get_origin(local_player))
	
	if local_player_origin.x == nil then
		return
	end

	local closest_fov_cos = -1
	enemyclosesttocrosshair = nil
	for i=1, #enemies do
		local idx = enemies[i]
		if entity.is_alive(idx) then
			local fov_cos = get_fov_cos(idx, vx,vy,vz, local_player_origin.x,local_player_origin.y,local_player_origin.z)
			if fov_cos > closest_fov_cos then
				closest_fov_cos = fov_cos
				enemyclosesttocrosshair = idx
			end
		end
	end
	
	if enemyclosesttocrosshair ~= nil then
		local eo = Vector(entity.get_origin(enemyclosesttocrosshair))
		height_advantage = eo.z > local_player_origin.z * 1.5
	end
	
	local_jumping = (client.key_state(0x20) and local_velocity > 100) or in_air(local_player)
	
	local weapon = entity.get_player_weapon(local_player)
	local carrying_c4 = weapon ~= nil and entity.get_classname(weapon) == "CC4"

	-- LEGIT AA
	if ui.get(menu.misc_legit_aa) and not carrying_c4 and client.key_state(0x45) then
		if cmd.chokedcommands == 0 then
			cmd.in_use = 0
			holdingE = true
		end
	else
		holdingE = false
	end

    -- EDGE YAW
	if ui.get(menu.misc_edge_yaw) and not can_enemy_hit_head(enemyclosesttocrosshair) and isFreestanding and not local_jumping and not ui.get(ref.misc_fakeduck) and not holdingE then
		ui.set(ref.aa_edge,true)
	else
		ui.set(ref.aa_edge,false)
	end

	-- LEG MOVEMENT
	local leg_exposed = is_Feet_Exposed(enemyclosesttocrosshair,16)
	if ui.get(menu.misc_legmovement) then 
		if leg_exposed then
			ui.set(ref.misc_legs,"off")
		else
			ui.set(ref.misc_legs,flipJitter and local_velocity > 100 and "always slide" or "never slide")
		end
	else
		ui.set(ref.misc_legs,"never slide")
	end

	-- OTHER STUFF
	if enemyclosesttocrosshair ~= nil then

		local active_weapon = entity.get_prop(enemyclosesttocrosshair, "m_hActiveWeapon")
		if active_weapon ~= nil then
		
			local active_idx = entity.get_prop(active_weapon, "m_iItemDefinitionIndex")
			if active_idx ~= nil then
				active_idx = bit.band(active_idx, 0xFFFF)
				
				maxspeed = weapons[active_idx].max_speed
				local weaponname = weapons[active_idx].console_name
				local scoped = entity.get_prop(enemyclosesttocrosshair, "m_bIsScoped") == 1
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
				
				if firedthistick[enemyclosesttocrosshair] == nil then firedthistick[enemyclosesttocrosshair] = false end
				
				local shot_time = entity.get_prop(active_weapon, "m_fLastShotTime")

				if lastshottime[enemyclosesttocrosshair] ~= nil then
					if (is_record_valid(lastshottime[enemyclosesttocrosshair],0.2)) then
						firedthistick[enemyclosesttocrosshair] = true
					else
						firedthistick[enemyclosesttocrosshair] = false
					end
				end
			end
		end
	end			
	
	if ui.get(menu.aa_ev4sion) then
		if(enemyclosesttocrosshair ~= nil and #enemies ~= 0 ) then

			if entity.is_dormant(enemyclosesttocrosshair) then
				return
			end
			
			local hx,hy,hz = entity.hitbox_position(local_player, 0)
			local lx,ly,lz = client.eye_position()
			lz = hz
			local _, eye_yaw = entity.get_prop(local_player, "m_angEyeAngles")
			local desync = normalise_angle(eye_yaw - get_body_yaw(local_player))
			lx = lx + math.cos(math.rad(desync)) * 20
			ly = ly + math.sin(math.rad(desync)) * 12	
			
			local ex,ey,ez = entity.get_prop(enemyclosesttocrosshair, "m_vecOrigin")
			local vx,vy,vz = entity.get_prop(enemyclosesttocrosshair, "m_vecViewOffset")
			ex,ey,ez = ex+vx,ey+vy,ez+vz
			
			local lp_hp = entity.get_prop(local_player, "m_iHealth")
			local ent,damage = client.trace_bullet(enemyclosesttocrosshair, ex, ey, ez, lx, ly, lz,true)
			local scaled_dmg = client.scale_damage(enemyclosesttocrosshair, 1, damage)

			if damage > (ui.get(menu.aa_ev4sion_slider) * lp_hp) / 100 then
				evasion_last_ent = evasion_ent
				evasion_ent = enemyclosesttocrosshair
			else
				evasion_last_ent = evasion_ent
				evasion_ent = nil
			end	
		end
	end

	-- GET ENEMY WEAPON
	if enemyclosesttocrosshair ~= nil then
		if contains(ui.get(menu.aa_jitter), "Weapon based") then 
			local enemy_weapon = entity.get_player_weapon(enemyclosesttocrosshair)
			local enemy_item = nil 

			if enemy_weapon ~= nil then 
				enemy_item = bit.band(entity.get_prop(enemy_weapon, "m_iItemDefinitionIndex"), 0xFFFF)

				wpn_auto = enemy_item == 11 or enemy_item == 38
				wpn_awp = enemy_item == 9
				wpn_ssg = enemy_item == 40
				wpn_def = not wpn_auto and not wpn_awp and not wpn_ssg
			end
		end
	end
end

local function weapon_auto(entity)
	if not contains(ui.get(menu.aa_jitter), "Weapon based") or not ui.get(menu.enable_aa) then return false end
	return (wpn_auto and enemyclosesttocrosshair == entity)
end
local function weapon_awp(entity)
	if not contains(ui.get(menu.aa_jitter), "Weapon based") or not ui.get(menu.enable_aa) then return false end
	return (wpn_awp and enemyclosesttocrosshair == entity)
end
local function weapon_ssg(entity)
	if not contains(ui.get(menu.aa_jitter), "Weapon based") or not ui.get(menu.enable_aa) then return false end
	return (wpn_ssg and enemyclosesttocrosshair == entity)
end
local function weapon_def(entity)
	if not contains(ui.get(menu.aa_jitter), "Weapon based") or not ui.get(menu.enable_aa) then return false end
	return (wpn_def and enemyclosesttocrosshair == entity)
end

local function run_command()
	if not ui.get(menu.enable_aa) then
		return
	end	
	
	local lp_origin = Vector(entity.get_origin(local_player))
	if lp_origin.x == nil then
		return
	end

	if ui.get(menu.aa_ev4sion) then
		if evasion_time <= globals.realtime() then 
			if enemyclosesttocrosshair ~= nil and evasion_ent ~= nil and local_velocity > 5  and evasion_ent ~= evasion_last_ent then
				local player_resource = entity.get_player_resource()
				if player_resource == nil then
					return
				end
                local ping = entity.get_prop(player_resource, "m_iPing", evasion_ent)
				local evasion_pingticks = time_to_ticks(ping / 1000) + 1
				if get_velocity(enemyclosesttocrosshair) <= maxspeed + 1 then
					evasion_vis_ticks = evasion_vis_ticks + 1
				end
				
				if evasion_vis_ticks > evasion_pingticks then
					evasion_time = globals.realtime() + 0.5
					flip_evasion = true
				end
			else	
				evasion_vis_ticks = 0
				flip_evasion = false
			end
		end
	end

	compute_directions()
    compute_traces()
    closest_wall_side = get_closest_wall_side()
	anti_brute_FORCE = contains(ui.get(menu.aa_addons),"Anti resolve") and available_resolver_information[enemyclosesttocrosshair] and enemy_shot_angle[enemyclosesttocrosshair] ~= nil and (enemy_shot_time[enemyclosesttocrosshair] ~= nil and enemy_shot_time[enemyclosesttocrosshair] > globals.curtime())
	jitter_backwards = can_enemy_hit_head(enemyclosesttocrosshair) and local_velocity < 40 and contains(ui.get(menu.aa_jitter), "Full") and not local_jumping

	if(enemyclosesttocrosshair ~= nil and #enemies ~= 0) then
		freestanding_angle = return_freestanding(enemyclosesttocrosshair,-90,90)
		freestanding_angle2 = early_freestanding(enemyclosesttocrosshair,-90,90)

		if freestanding_angle ~= 0 and freestanding_angle ~= nil then
			stored_freestanding_angle = freestanding_angle
		end
		
		if freestanding_angle2 ~= 0 and freestanding_angle2 ~= nil then
			stored_freestanding_angle2 = freestanding_angle2
		end
	end
	
	if freestanding_angle ~= nil then
		fs_angle = ui.get(menu.aa_update) and freestanding_angle or stored_freestanding_angle
	elseif freestanding_angle2 ~= nil then
		fs_angle = ui.get(menu.aa_update) and freestanding_angle2 or stored_freestanding_angle2
	end
	
	should_edge = ShouldPreserve(enemyclosesttocrosshair)
	safe_edge = is_edge_safe(enemyclosesttocrosshair)

	if isLowDelta then
		apply_offsets(1,0)
	elseif isFreestanding then
		if contains(ui.get(menu.aa_addons),"Prefer safe angles") then
			if should_edge then
				if closest_wall_side == 0 then
					apply_offsets(2, 180)
				elseif closest_wall_side == 1 then
					apply_offsets(3, -180)
				end
			end
			if should_edge and safe_edge then
				flip_evasion = false
				ui.set(ref.aa_yaw_jitter[MODE], "center")
				ui.set(ref.aa_yaw_jitter[VALUE], 2)
				return
			end
		end
		
		if fs_angle == nil then
			return
		elseif fs_angle == -90 then
			apply_offsets(2, ui.get(menu.aa_dir_mode) == "Freestand" and 180 or -180)
		elseif fs_angle == 90 then
			apply_offsets(3, ui.get(menu.aa_dir_mode) == "Freestand" and -180 or 180)
		else
			apply_offsets(4, 0)
		end
	end

	if (#enemies == 0 and ui.get(menu.aa_off_jitter) > 0) then
		ui.set(ref.aa_yaw_jitter[MODE], "offset")
		ui.set(ref.aa_yaw_jitter[VALUE], -ui.get(menu.aa_off_jitter))
	elseif jitter_backwards then
		ui.set(ref.aa_yaw_jitter[MODE], "center")
		ui.set(ref.aa_yaw_jitter[VALUE], ui.get(menu.aa_off_jitter))
	elseif wpn_auto and not anti_brute_FORCE and not eschiva then
		ui.set(ref.aa_yaw_jitter[MODE], local_velocity < 5 and "off" or "center")	
		ui.set(ref.aa_yaw_jitter[VALUE], local_jumping and 0 or 40)
	elseif wpn_awp and not anti_brute_FORCE and not eschiva then
		ui.set(ref.aa_yaw_jitter[MODE], local_velocity < 5 and "off" or "center")
		ui.set(ref.aa_yaw_jitter[VALUE], local_jumping and 0 or 65)
	elseif wpn_ssg and not anti_brute_FORCE and not eschiva then
		ui.set(ref.aa_yaw_jitter[MODE], "Center")
		ui.set(ref.aa_yaw_jitter[VALUE], 8)
	else
		ui.set(ref.aa_yaw_jitter[MODE], "off")
	end

	if enemyclosesttocrosshair ~= nil and not entity.is_dormant(enemyclosesttocrosshair) then
		local set_plist_adds = aa_player_list[enemyclosesttocrosshair]["plist_adds"]
		local set_plist_slow = aa_player_list[enemyclosesttocrosshair]["plist_slow"]
	
		if contains(set_plist_adds, "custom slow mode") and ui.get(ref.fake_walk[KEYBIND]) then
			if set_plist_slow == "anti-neverlose" then
				apply_offsets(5, 0)
			elseif set_plist_slow == "jitter" then 
				apply_offsets(6, 0)
			elseif set_plist_slow == "canary" then 
				apply_offsets(7, 0)
			end
		end
	end

	flip_onshot = false
end

-- INDICATOARE BOMBA
local function apply_indicators(ind)
	scrsize_x, scrsize_y = client.screen_size()
	local center_x, center_y = scrsize_x / 2, scrsize_y / 2

	if not entity.is_alive(entity.get_local_player()) then
		return
	end

	local next_attack = math.max(entity.get_prop(entity.get_prop(entity.get_local_player(), "m_hActiveWeapon"), "m_flNextPrimaryAttack") + 0.25 or 0, entity.get_prop(entity.get_local_player(), "m_flNextAttack") or 0)
	local body_yaw = math.floor(math.min(58, math.abs(entity.get_prop(entity.get_local_player(), "m_flPoseParameter", 11)*120-60)))
	local alpha = math.floor(math.sin(globals.realtime() % 3 * 4) * (255 / 2 - 1) + 255 / 2)

	local h_index = 25
	local r,g,b
	if anti_brute_FORCE then
		r,g,b = 0,100,0
	elseif contains(ui.get(menu.aa_addons),"Prefer safe angles") and should_edge and safe_edge then
		r,g,b = 200,100,0
	elseif fs_angle == 90 or fs_angle == -90 then
		r,g,b = 89,119,239
	else
		r,g,b = 163,160,163
	end

	if ind == "left" then
		client.draw_text(c, center_x - 45, center_y, r,g,b,alpha, "c+", 0, "⯇")
		client.draw_text(c, center_x + 45, center_y, 163,160,163,255, "c+", 0, "⯈")
	end

	if ind == "right" then
		client.draw_text(c, center_x + 45, center_y, r,g,b,alpha, "c+", 0, "⯈")
		client.draw_text(c, center_x - 45, center_y, 163,160,163,255, "c+", 0, "⯇")
	end

	if ind == "neutral" then 
		client.draw_text(c, center_x + 45, center_y, 163,160,163,255, "c+", 0, "⯈")
		client.draw_text(c, center_x - 45, center_y, 163,160,163,255, "c+", 0, "⯇")
	end

	if ind == "gradient" then
		renderer.gradient(center_x, center_y + h_index, -body_yaw, 3, r,g,b,255, 0, 0, 0, 0, true)
		renderer.gradient(center_x, center_y + h_index, body_yaw, 3, r,g,b,255, 0, 0, 0, 0, true)
	end

	if contains(ui.get(menu.misc_ind),"Gradient") then
		h_index = h_index + 10
	end

	if ind == "doubletap" then
		if ui.get(ref.misc_doubletap[KEYBIND]) and ui.get(ref.misc_doubletap[CHECKBOX]) then
			local weapon = entity.get_player_weapon(entity.get_local_player())
			if weapon ~= nil then 
				renderer.text(center_x, center_y + h_index, 163,160,163,255, "c", 0, "[          ]")
				if next_attack <= globals.curtime() then
					renderer.text(center_x, center_y + h_index, 255,255,255,alpha, "c", 0, "RAPID")
				else
					renderer.circle_outline(center_x + 25, center_y + h_index, 255,255,255,90, 5, 270, 1.0 - (3 * math.abs(math.max(next_attack) - globals.curtime())), 2)
					renderer.text(center_x, center_y + h_index, 255,255,255,255, "c", 0, "RAPID")
				end
			end
		end
	end

	if contains(ui.get(menu.misc_ind),"Doubletap") and ui.get(ref.misc_doubletap[KEYBIND]) and ui.get(ref.misc_doubletap[CHECKBOX]) then
		h_index = h_index + 15
	end

	if ind == "extra" then 
		if jitter_backwards then 
			renderer.text(center_x, center_y + h_index, 155,171,232,alpha, "c", 0, "backwards")
			h_index = h_index + 15
		end
		if flip_evasion then 
			renderer.text(center_x, center_y + h_index, 155,171,232,alpha, "c", 0, "evasion")
			h_index = h_index + 15
		end
		if ui.get(menu.aa_low_delta) then
			renderer.text(center_x, center_y + h_index, 155,171,232,alpha, "c", 0, "low delta")
		end
	end
end

-- PRINT SEXY INDICATORS :) 
local function paint(c)
	if not ui.get(menu.enable_aa) then
		return
	end

	if not entity.is_alive(local_player) then
		return
	end

	if ui.get(menu.misc_edge_yaw) then
		renderer.indicator(110,200,60,200, "EDGE")
	end

	if ui.get(ref.misc_onshot[KEYBIND]) then
		renderer.indicator(255,255,255,200, "ONSHOT")
	end

	if contains(ui.get(menu.misc_ind),"Gradient") then
		apply_indicators("gradient")
	end

	if contains(ui.get(menu.misc_ind),"Doubletap") then
		apply_indicators("doubletap")
	end

	if contains(ui.get(menu.misc_ind),"Extra") then
		apply_indicators("extra")
	end

	if contains(ui.get(menu.misc_ind),"Arrows") then
		if contains(ui.get(menu.aa_addons),"Prefer safe angles") then
			if should_edge then
				if closest_wall_side == 0 then
					apply_indicators("left")
				elseif closest_wall_side == 1 then
					apply_indicators("right")
				end		
			end
			
			if should_edge and safe_edge then
				return
			end
		end
		if fs_angle == -90 then
			apply_indicators(ui.get(menu.aa_dir_mode) == "Freestand" and "left" or "right")
		elseif fs_angle == 90 then
			apply_indicators(ui.get(menu.aa_dir_mode) == "Freestand" and "right" or "left")
		else
			apply_indicators("neutral")
		end	
	end
end

-- CALLBACKS
client.register_esp_flag("AUTO", 250,133,0, weapon_auto)
client.register_esp_flag("AWP", 250,133,0, weapon_awp)
client.register_esp_flag("SSG", 250,133,0, weapon_ssg)
client.register_esp_flag("DEFAULT", 250,133,0, weapon_def)

client.set_event_callback("round_start", function (e)
	firedthistick = {}
	lastshottime = {}
	available_resolver_information = {}
	enemy_shot_angle = {}
	enemy_shot_time = {}
end)

client.set_event_callback("cs_game_disconnected", function (e)
	firedthistick = {}
	lastshottime = {}
	available_resolver_information = {}
	enemy_shot_angle = {}
	enemy_shot_time = {}
end)

client.set_event_callback("game_newmap", function (e)
	firedthistick = {}
	lastshottime = {}
	available_resolver_information = {}
	enemy_shot_angle = {}
	enemy_shot_time = {}
end)

client.set_event_callback("aim_fire", aim_fire)
client.set_event_callback("weapon_fire", weapon_fire)
client.set_event_callback("bullet_impact", bullet_impact)
client.set_event_callback("setup_command", setup_command)
client.set_event_callback("run_command", run_command)
client.set_event_callback("paint", paint)

local function loadDefault()
	ui.set(menu.aa_base, "At targets")
	ui.set(menu.aa_ev4sion, true)
	ui.set(menu.aa_ev4sion_slider, 70)
	ui.set(menu.aa_dir_mode, "Freestand")
	ui.set(menu.aa_addons, "Prefer safe angles", "Anti resolve")
	ui.set(menu.aa_jitter, "Synced", "Full")
	ui.set(menu.aa_update, false)
	ui.set(menu.aa_off_jitter, 20)
	ui.set(menu.misc_legit_aa, true)
	ui.set(menu.aa_onshot, true)
	ui.set(menu.misc_legmovement, false)
	ui.set(menu.misc_ind, "Arrows", "Doubletap")
	ui.set(ref.aa_state, true)
	ui.set(ref.aa_pitch, "minimal")
	ui.set(ref.aa_fs_triggers[CHECKBOX], "-")
	ui.set(ref.aa_lby, "eye yaw")
end

local def_cfg = ui.new_button("aa", "anti-aimbot angles", "Load CFG", loadDefault)

local function handle_menu()
	if ui.is_menu_open() then
		local state_aa = ui.get(menu.enable_aa)
		local evesion = ui.get(menu.aa_ev4sion)

		-- MENU
		ui.set_visible(menu.aa_dir_mode, state_aa)

		ui.set_visible(menu.aa_base, state_aa)
		ui.set_visible(menu.aa_ev4sion, state_aa)
		ui.set_visible(menu.aa_ev4sion_slider, state_aa and evesion)

		ui.set_visible(menu.aa_addons, state_aa)
		ui.set_visible(menu.aa_jitter, state_aa)

		ui.set_visible(menu.aa_update, state_aa)
		ui.set_visible(menu.aa_off_jitter, state_aa)
		ui.set_visible(menu.misc_legit_aa, state_aa)

		ui.set_visible(menu.aa_onshot, state_aa)
		ui.set_visible(menu.misc_legmovement, state_aa)
		ui.set_visible(menu.aa_low_delta, state_aa)

		ui.set_visible(menu.misc_edge_yaw, state_aa)
		ui.set_visible(menu.misc_ind, state_aa)
		ui.set_visible(def_cfg, state_aa)

		ui.set_visible(menu.plist_adds, state_aa)
		ui.set_visible(menu.plist_slow, state_aa and contains(ui.get(menu.plist_adds), "custom slow mode"))
		
		-- REFERENCES
		ui.set_visible(ref.aa_state, not state_aa)

		ui.set_visible(ref.aa_pitch, not state_aa)
		ui.set_visible(ref.aa_yaw_base, not state_aa)

		ui.set_visible(ref.aa_yaw[MODE], not state_aa)
		ui.set_visible(ref.aa_yaw[VALUE], not state_aa)

		ui.set_visible(ref.aa_yaw_jitter[MODE], not state_aa)
		ui.set_visible(ref.aa_yaw_jitter[VALUE], not state_aa)

		ui.set_visible(ref.aa_fake_yaw[MODE], not state_aa)
		ui.set_visible(ref.aa_fake_yaw[VALUE], not state_aa)

		ui.set_visible(ref.aa_fs_byaw, not state_aa)
		ui.set_visible(ref.aa_lby, not state_aa)
		ui.set_visible(ref.aa_body_limit, not state_aa)
		
		ui.set_visible(ref.aa_edge, not state_aa)
		ui.set_visible(ref.aa_fs_triggers[CHECKBOX], not state_aa)
		ui.set_visible(ref.aa_fs_triggers[KEYBIND], not state_aa)
	end
end

ui.set_visible(menu.aa_dir_mode, false)

ui.set_visible(menu.aa_base, false)
ui.set_visible(menu.aa_ev4sion, false)
ui.set_visible(menu.aa_ev4sion_slider, false)

ui.set_visible(menu.aa_addons, false)
ui.set_visible(menu.aa_jitter, false)

ui.set_visible(menu.aa_update, false)
ui.set_visible(menu.aa_off_jitter, false)
ui.set_visible(menu.misc_legit_aa, false)

ui.set_visible(menu.aa_onshot, false)
ui.set_visible(menu.misc_legmovement, false)
ui.set_visible(menu.aa_low_delta, false)

ui.set_visible(menu.misc_edge_yaw, false)
ui.set_visible(menu.misc_ind, false)
ui.set_visible(def_cfg, false)

ui.set_visible(menu.plist_adds, false)
ui.set_visible(menu.plist_slow, false)

client.set_event_callback("paint", handle_menu)
