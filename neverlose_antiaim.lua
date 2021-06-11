-- REFERENCES
local ref = {
	aa_enable = g_Config:FindVar("Aimbot", "Anti Aim", "Main", "Enable Anti Aim"),

	aa_pitch = g_Config:FindVar("Aimbot", "Anti Aim", "Main", "Pitch"),
	aa_yaw_base = g_Config:FindVar("Aimbot", "Anti Aim", "Main", "Yaw Base"),
	aa_yaw_add = g_Config:FindVar("Aimbot", "Anti Aim", "Main", "Yaw Add"),
	aa_yaw_modifier = g_Config:FindVar("Aimbot", "Anti Aim", "Main", "Yaw Modifier"),
	aa_modifier_degree = g_Config:FindVar("Aimbot", "Anti Aim", "Main", "Modifier Degree"),

	aa_enable_fake = g_Config:FindVar("Aimbot", "Anti Aim", "Fake Angle", "Enable Fake Angle"),
	aa_invertor = g_Config:FindVar("Aimbot", "Anti Aim", "Fake Angle", "Inverter"),
	aa_left_limit = g_Config:FindVar("Aimbot", "Anti Aim", "Fake Angle", "Left Limit"),
	aa_right_limit = g_Config:FindVar("Aimbot", "Anti Aim", "Fake Angle", "Right Limit"),
	aa_fake_options = g_Config:FindVar("Aimbot", "Anti Aim", "Fake Angle", "Fake Options"),
	aa_lby_mode = g_Config:FindVar("Aimbot", "Anti Aim", "Fake Angle", "LBY Mode"),
	aa_freestanding_desync = g_Config:FindVar("Aimbot", "Anti Aim", "Fake Angle", "Freestanding Desync"),
	aa_desync_on_shot = g_Config:FindVar("Aimbot", "Anti Aim", "Fake Angle", "Desync On Shot"),

	aa_fake_duck = g_Config:FindVar("Aimbot", "Anti Aim", "Misc", "Fake Duck"),

	misc_doubletap = g_Config:FindVar("Aimbot", "Ragebot", "Exploits", "Double Tap"),
	misc_leg = g_Config:FindVar("Aimbot", "Anti Aim", "Misc", "Leg Movement")
}

local menu = {
	enable_misc = menu.Switch("Misc", "Enable misc", false),

	misc_legit_aa = menu.Switch("Misc", "Legit aa on use", false),
	misc_leg_movement = menu.Combo("Misc", "Leg movement", {"Off", "Adaptive", "Break anim"}, 0),
	misc_clan_tag = menu.Switch("Misc", "Clan tag", false),
	misc_def_cfg = menu.Button("Misc", "Load default settings"),


	enable_aa = menu.Switch("Anti aim", "Enable anti aim", false),

	aa_yaw = menu.Combo("Anti aim", "Yaw base", {"Local view", "At targets", "Lowdelta back", "Right", "Left"}, 0),
	aa_freestand = menu.MultiCombo("Anti aim", "Freestand", {"Always update"}, 0),
	aa_body_yaw = menu.MultiCombo("Anti aim", "Body yaw", {"Anti bruteforce", "Safe angles"}, 0),
	aa_lby = menu.Combo("Anti aim", "Lower body yaw", {"Normal", "Eye yaw"}, 0),
	aa_evasion = menu.Switch("Anti aim", "Evasion", false),
	aa_evasion_slider = menu.SliderInt("Anti aim", "Chance to dodge hit", 50, 40, 100),
	aa_set_limit = menu.SliderInt("Anti aim", "Desync limit", 58, 0, 58),
	aa_max_dsy = menu.Switch("Anti aim", "Max desync standing", false),
	aa_edge_yaw = menu.Switch("Anti aim", "Edge yaw", false),
	aa_onshot = menu.Switch("Anti aim", "Change onshot angle", false),


	enable_visauls = menu.Switch("Visuals", "Enable visuals", false),

	visuals_arrows = menu.SwitchColor("Visuals", "Indicators", false, Color.new(89/255, 119/255, 239/255, 255/255)),
	visuals_arrows_type = menu.Combo("Visuals", "Arrows", {"Off", "Type 1", "Type 2"}, 0),
	visuals_indicators = menu.MultiCombo("Visuals", "Indicators+", {"AA state", "Doubletap"}, 0)
}

-- GLOBALS
local local_player
local local_player_ent
local local_player_getplayer
local local_player_isplayer
local enemies
local local_velocity
local local_jumping
local enemyclosesttocrosshair
local enemyclosesttocrosshairindex

local near_walls = {}
local closest_wall_side
local nearest_wall_index
local freestanding_angle
local stored_freestanding_angle
local freestanding_angle2
local stored_freestanding_angle2
local fs_angle
local flipJitter
local should_edge
local safe_edge
local legit_aa_timer = 0 
local flip_onshot = false
local eschiva = false
local anti_brute_FORCE = false
local safe_angles = false
local max_dsy = false

local firedthistick = {}
local lastshottime = {}
local available_resolver_information = {}
local enemy_shot_angle = {}
local enemy_shot_time = {}

local evasion_time = 0
local evasion_ent = nil
local evasion_last_ent = nil
local evasion_vis_ticks = 0
local maxspeed = 0
local flip_evasion = false
local height_advantage = false

-- FUNCTIONS
local Vectors = function(x,y,z) 
	return {x=x or 0,y=y or 0,z=z or 0} 
end

local Vector_distance = function(ax, ay, az, bx, by, bz)
    return math.sqrt(math.pow((ax-bx), 2) + math.pow((ay-by), 2) + math.pow((az-bz), 2))
end

local vec3_normalize = function(x, y, z)
	local len = math.sqrt(x * x + y * y + z * z)
	if len == 0 then
		return 0, 0, 0
	end
	local r = 1 / len
	return x*r, y*r, z*r
end

local vec3_dot = function(ax, ay, az, bx, by, bz)
	return ax*bx + ay*by + az*bz
end

local vector_lerp = function(vecSource, vecDestination, flPercentage)
	return vecSource + (vecDestination - vecSource) * flPercentage
end

local normalize_yaw = function(fl_yaw)
	while fl_yaw > 180 do fl_yaw = fl_yaw - 360 end
	while fl_yaw < -180 do fl_yaw = fl_yaw + 360 end
	return fl_yaw
end

local angle_to_vec = function(pitch, yaw)
	local p = math.rad(pitch)
	local y = math.rad(yaw)
	local sp = math.sin(p)
	local cp = math.cos(p)
	local sy = math.sin(y)
	local cy = math.cos(y)
	return cp*cy, cp*sy, -sp
end

local get_fov_cos = function(ent, vx,vy,vz, lx,ly,lz)
	local origin = ent:GetRenderOrigin()
	local ox = origin.x
	local oy = origin.y
	local oz = origin.z

	if ox == nil then
		return -1
	end
	
	-- get direction to player
	local dx,dy,dz = vec3_normalize(ox-lx, oy-ly, oz-lz)
	return vec3_dot(dx,dy,dz, vx,vy,vz)
end

local CalcAngle = function(localplayerxpos, localplayerypos, enemyxpos, enemyypos)
   local relativeyaw = math.atan((localplayerypos - enemyypos) / (localplayerxpos - enemyxpos))
    return relativeyaw * 180 / math.pi
end

local GetClosestPoint = function(A, B, P)
   local a_to_p = { P[1] - A[1], P[2] - A[2] }
   local a_to_b = { B[1] - A[1], B[2] - A[2] }

   local atb2 = a_to_b[1]^2 + a_to_b[2]^2

   local atp_dot_atb = a_to_p[1]*a_to_b[1] + a_to_p[2]*a_to_b[2]
   local t = atp_dot_atb / atb2
    
    return { A[1] + a_to_b[1]*t, A[2] + a_to_b[2]*t }
end

-- OTHER FUNCTIONS
local time_to_ticks = function(dt)
	return math.floor(0.5 + dt / g_GlobalVars.interval_per_tick - 3)
end

local clamp = function(val, lower, upper)
    assert(val and lower and upper, "not very useful error message here")
    if lower > upper then lower, upper = upper, lower end -- swap if boundaries supplied the wrong way
    return math.max(lower, math.min(upper, val))
end

local get_lerp_time = function()
	local ud_rate = g_CVar:FindVar("cl_updaterate"):GetInt()
	
	local min_ud_rate = g_CVar:FindVar("sv_minupdaterate"):GetInt()
	local max_ud_rate = g_CVar:FindVar("sv_maxupdaterate"):GetInt()

	if (min_ud_rate and max_ud_rate) then
		ud_rate = max_ud_rate
	end
	
	local ratio = g_CVar:FindVar("cl_interp_ratio"):GetInt()

	if (ratio == 0) then
		ratio = 1
	end
	
	local lerp = g_CVar:FindVar("cl_interp"):GetInt()
	local c_min_ratio = g_CVar:FindVar("sv_client_min_interp_ratio"):GetInt()
	local c_max_ratio = g_CVar:FindVar("sv_client_max_interp_ratio"):GetInt()

	if (c_min_ratio and  c_max_ratio and  c_min_ratio ~= 1) then
		ratio = clamp(ratio, c_min_ratio, c_max_ratio)
	end
	
	return math.max(lerp, (ratio / ud_rate));
end

local is_record_valid = function(player_time,ms)
	local correct = 0
	local sv_maxunlag = 0.2
	local GetNetChannelInfo = g_EngineClient:GetNetChannelInfo()
	
	correct = correct + get_lerp_time()
	correct = correct + GetNetChannelInfo:GetLatency(0)
	correct = clamp(correct, 0, ms);
	
	local delta = correct - (g_GlobalVars.curtime - player_time);
	
	if math.abs(delta) > ms then
		return false
	end
	
	return true
end

local extrapolate_position = function(xpos,ypos,zpos,ticks,player)
	local x = player:GetProp("DT_BasePlayer", "m_vecVelocity[0]")
	local y = player:GetProp("DT_BasePlayer", "m_vecVelocity[1]")
	local z = player:GetProp("DT_BasePlayer", "m_vecVelocity[2]")
	for i=0, ticks do
		xpos =  xpos + (x*g_GlobalVars.interval_per_tick)
		ypos =  ypos + (y*g_GlobalVars.interval_per_tick)
		zpos =  zpos + (z*g_GlobalVars.interval_per_tick)
	end
	return xpos,ypos,zpos
end

local normalise_angle = function(angle)
	angle = angle % 360 
	angle = (angle + 360) % 360
	if (angle > 180)  then
		angle = angle - 360
	end
	return angle
end

local get_velocity = function(player)
	local x = player:GetProp("DT_BasePlayer", "m_vecVelocity[0]")
	local y = player:GetProp("DT_BasePlayer", "m_vecVelocity[1]")
	local z = player:GetProp("DT_BasePlayer", "m_vecVelocity[2]")
	if x == nil then return end
	return math.sqrt(x*x + y*y + z*z)
end

local get_body_yaw = function(player)
	local model_yaw = math.floor(antiaim.GetCurrentRealRotation() - antiaim.GetFakeRotation())
	if model_yaw == nil then return 0 end
	return normalise_angle(model_yaw)
end

local in_air = function(player)
	local flags = player:GetProp("m_fFlags")
	
	if bit.band(flags, 1) == 0 then
		return true
	end
	
	return false
end

local is_crouching = function(player)
	local flags = player:GetProp("m_fFlags")
	
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

local get_weapon = function(idx)
	if type(idx) == "string" then
		return weapons_index[idx]
	elseif type(idx) == "number" then
		idx = bit.band(idx, 0xFFFF)
		return rawget(weapons, idx)
	end
end

local isLeft, isRight, isBack, isFreestanding = false, false, false, true
local function compute_directions()
	if menu.aa_yaw:GetInt() == 2 then
		isLeft, isRight, isBack, isFreestanding = false, false, true, false
	elseif menu.aa_yaw:GetInt() == 4 then
		isLeft, isRight, isBack, isFreestanding = true, false, false, false
	elseif menu.aa_yaw:GetInt() == 3 then
		isLeft, isRight, isBack, isFreestanding = false, true, false, false
	else
		isLeft, isRight, isBack, isFreestanding = false, false, false, true
	end
end

-- HvH Functions
local return_wall_info = function(facing_offset) 
    local camera_angles = g_EngineClient:GetViewAngles()
    local resulted_direction = Vectors(angle_to_vec(0, camera_angles.yaw + facing_offset))

	local local_player_origin = local_player_getplayer:GetEyePosition()
    
    local trace_stop = Vectors(local_player_origin.x + resulted_direction.x * 8192, local_player_origin.y + resulted_direction.y * 8192, local_player_origin.z + resulted_direction.z * 8192)
    local trace_start = Vectors(local_player_origin.x + resulted_direction.x * 5, local_player_origin.y + resulted_direction.y * 5, local_player_origin.z + resulted_direction.z * 5)

    local trace = g_EngineTrace:TraceRay(Vector.new(trace_start.x, trace_start.y, trace_start.z), Vector.new(trace_stop.x, trace_stop.y, trace_stop.z), local_player_ent, 0xFFFFFFFF)
	local trace_result_fraction = trace.fraction
	local trace_result_entity_index = trace.hit_entity

    -- local start = g_Render:ScreenPosition(Vector.new(trace_start.x, trace_start.y, trace_start.z))
    -- local stop = g_Render:ScreenPosition(Vector.new(trace_stop.x, trace_stop.y, trace_stop.z))

	-- g_Render:Line(Vector2.new(start.x, start.y), Vector2.new(stop.x, stop.y), Color.new(1.0, 1.0, 1.0, 1.0))

    if trace_result_fraction == 1 then
        return {false, 0, 0, 0}
    end

	return {true, local_player_origin.x + resulted_direction.x * trace_result_fraction * 8192, local_player_origin.y + resulted_direction.y * trace_result_fraction * 8192, local_player_origin.z + resulted_direction.z * trace_result_fraction * 8192, trace_result_fraction}
end

local compute_traces = function()
    near_walls[1] = return_wall_info(45)
    near_walls[2] = return_wall_info(90)
    near_walls[3] = return_wall_info(135)
    near_walls[4] = return_wall_info(-45)
    near_walls[5] = return_wall_info(-90)
    near_walls[6] = return_wall_info(-135)
end

local get_closest_wall_side = function()
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
        return 3 -- NU STIM DC
    end

    if min_trace_id < 3 then
        return 0 -- STANGA
    end

    return 1 -- DREAPTA
end

local get_ticks_amount = function(max_ticks_number)
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

local return_freestanding = function(enemy, ...)
	if enemy == nil then
		return
	end

	local local_player_origin = local_player_ent:GetRenderOrigin()
	local enemy_origin = enemy:GetRenderOrigin()
	local bestangle = nil
	local lowest_dmg = math.huge
	local enemy_alive = enemy:GetProp("m_iHealth")

	if(enemy_alive > 0) then
		local ForwardOffset = CalcAngle(local_player_origin.x, local_player_origin.y, enemy_origin.x, enemy_origin.y)
		for i,v in pairs({...}) do
			local new_direction = Vectors(angle_to_vec(0, (ForwardOffset + v)))
			local trace_stop = Vectors(local_player_origin.x + new_direction.x * 55, local_player_origin.y + new_direction.y * 55, local_player_origin.z + 80)
			
			local damage1 = cheat.FireBullet(enemy, Vector.new(enemy_origin.x, enemy_origin.y, enemy_origin.z + 70), Vector.new(trace_stop.x, trace_stop.y, trace_stop.z))
			local damage2 = cheat.FireBullet(enemy, Vector.new(enemy_origin.x, enemy_origin.y, enemy_origin.z + 70), Vector.new(trace_stop.x + 12, trace_stop.y, trace_stop.z))
			local damage3 = cheat.FireBullet(enemy, Vector.new(enemy_origin.x, enemy_origin.y, enemy_origin.z + 70), Vector.new(trace_stop.x - 12, trace_stop.y, trace_stop.z))

			if(damage1.damage < lowest_dmg) then
				lowest_dmg = damage1.damage
				if(damage2.damage > damage1.damage) then
					lowest_dmg = damage2.damage
				end
				if(damage3.damage > damage1.damage) then
					lowest_dmg = damage3.damage
				end	
				if(local_player_origin.x - enemy_origin.x > 0) then
					bestangle = v
				else
					bestangle = v * -1
				end
			elseif(damage1.damage == lowest_dmg) then
				return 0 -- BACKWARDS
			end
			-- print("D1: ",damage1.damage, " D2: ", damage2.damage, " D3: ",damage3.damage)
		end
	end
	return bestangle
end

local early_freestanding = function(enemy, ...)
	if enemy == nil then
		return
	end

	local local_player_origin = local_player_ent:GetRenderOrigin()
	local enemy_origin = enemy:GetRenderOrigin()
	local bestangle = nil
	local lowest_dmg = math.huge
	local last_moving_time = 0
	local stored_eyepos_x, stored_eyepos_y, stored_eyepos_z = nil
	local enemy_alive = enemy:GetProp("m_iHealth")
	-- I DONT EVEN KNOW WHY THIS WORKS
	if(enemy_alive > 0) then
		local ForwardOffset = CalcAngle(local_player_origin.x, local_player_origin.y, enemy_origin.x, enemy_origin.y)
		for i,v in pairs({...}) do
			local new_direction = Vectors(angle_to_vec(0, (ForwardOffset + v)))
			local trace_stop = Vectors(local_player_origin.x + new_direction.x * 55, local_player_origin.y + new_direction.y * 55, local_player_origin.z + 80)
			-- EXTRAPOLATE
			local eyepos = local_player_getplayer:GetEyePosition()
			local stored_eyepos = local_player_getplayer:GetEyePosition()
			local ticks_to_extrapolate = get_ticks_amount(64)

			if local_velocity > 15 then
				eyepos = Vectors(extrapolate_position(eyepos.x, eyepos.y, eyepos.z, ticks_to_extrapolate, local_player_ent))
				stored_eyepos_x, stored_eyepos_y, stored_eyepos_z = eyepos.x, eyepos.y, eyepos.z
				last_moving_time = g_GlobalVars.curtime + 1
			else
				if last_moving_time ~= 0 then
					if g_GlobalVars.curtime > last_moving_time then
						last_moving_time = 0
						stored_eyepos_x, stored_eyepos_y, stored_eyepos_z = nil
					else
						eyepos.x, eyepos.y, eyepos.z = stored_eyepos_x, stored_eyepos_y, stored_eyepos_z
					end
				else
					eyepos.x, eyepos.y, eyepos.z = extrapolate_position(eyepos.x, eyepos.y, eyepos.z, ticks_to_extrapolate, local_player_ent)
				end
			end
			
			local damage1 = cheat.FireBullet(local_player_getplayer, Vector.new(enemy_origin.x, enemy_origin.y, enemy_origin.z + 70), Vector.new(trace_stop.x, trace_stop.y, trace_stop.z))
			local damage2 = cheat.FireBullet(local_player_getplayer, Vector.new(enemy_origin.x, enemy_origin.y, enemy_origin.z + 70), Vector.new(trace_stop.x + 12, trace_stop.y, trace_stop.z))
			local damage3 = cheat.FireBullet(local_player_getplayer, Vector.new(enemy_origin.x, enemy_origin.y, enemy_origin.z + 70), Vector.new(trace_stop.x - 12, trace_stop.y, trace_stop.z))

			if stored_eyepos_x ~= nil then
				damage1 = cheat.FireBullet(local_player_getplayer, Vector.new(stored_eyepos_x, stored_eyepos_y, stored_eyepos_z + 70), Vector.new(trace_stop.x, trace_stop.y, trace_stop.z))
				damage2 = cheat.FireBullet(local_player_getplayer, Vector.new(stored_eyepos_x, stored_eyepos_y, stored_eyepos_z + 70), Vector.new(trace_stop.x + 12, trace_stop.y, trace_stop.z))
				damage3 = cheat.FireBullet(local_player_getplayer, Vector.new(stored_eyepos_x, stored_eyepos_y, stored_eyepos_z + 70), Vector.new(trace_stop.x - 12, trace_stop.y, trace_stop.z))
			end

			if(damage1.damage < lowest_dmg) then
				lowest_dmg = damage1.damage
			if(damage2.damage > damage1.damage) then
				lowest_dmg = damage2.damage
			end
			if(damage3.damage > damage1.damage) then
				lowest_dmg = damage3.damage
			end	
			if(local_player_origin.x - enemy_origin.x > 0) then
				bestangle = v
			else
				bestangle = v * -1
			end
			elseif(damage1.damage == lowest_dmg) then
				return 0 -- backward
			end
			-- print("D1: ",damage1.damage, " D2: ", damage2.damage, " D3: ",damage3.damage)
		end
	end
	return bestangle
end

local is_Feet_Exposed = function(enemy,ticks)	
	if enemy == nil then
		return
	end
	
	local enemy_origin = enemy:GetRenderOrigin()
	
	local hitbox1 = local_player_getplayer:GetHitboxCenter(11)
	local hitbox2 = local_player_getplayer:GetHitboxCenter(12)

	local fakelag_hitbox1 = Vectors(extrapolate_position(hitbox1.x, hitbox1.y, hitbox1.z, ticks, local_player_ent))
	local fakelag_hitbox2 = Vectors(extrapolate_position(hitbox2.x, hitbox2.y, hitbox2.z, ticks, local_player_ent))
	
	local dmg1 = cheat.FireBullet(enemy, Vector.new(enemy_origin.x, enemy_origin.y, enemy_origin.z), Vector.new(fakelag_hitbox1.x, fakelag_hitbox1.y, fakelag_hitbox1.z))
	local dmg2 = cheat.FireBullet(enemy, Vector.new(enemy_origin.x, enemy_origin.y, enemy_origin.z), Vector.new(fakelag_hitbox2.x, fakelag_hitbox2.y, fakelag_hitbox2.z))

	local left_hittable = dmg1.damage ~= nil and dmg1.damage > 12
	local right_hittable = dmg2.damage ~= nil and dmg2.damage > 12
	local hittable = (left_hittable or right_hittable) and local_velocity > 32
	
	return hittable
end

local can_enemy_hit_head = function(ent)
	if ent == nil then return end
	if in_air(ent) then return false end
	
	local origin = ent:GetRenderOrigin()
	if origin.z == nil then return end

	local h = local_player_getplayer:GetHitboxCenter(0)
	local head_dmg = cheat.FireBullet(ent, Vector.new(origin.x, origin.y, origin.z), Vector.new(h.x, h.y, h.z))

	return head_dmg.damage ~= nil and head_dmg.damage > 25
end

local ShouldPreserve = function(enemy)
	if enemy == nil then
		return
	end
	
	local lp_origin = local_player_ent:GetRenderOrigin()
	local enemy_origin = enemy:GetRenderOrigin()

    local distanceToEnemy = Vector_distance(lp_origin.x, lp_origin.y, lp_origin.z, enemy_origin.x, enemy_origin.y, enemy_origin.z)
    local distanceToWall = Vector_distance(lp_origin.x, lp_origin.y, lp_origin.z, near_walls[nearest_wall_index][2], near_walls[nearest_wall_index][3], near_walls[nearest_wall_index][4])

	local standing = local_velocity < 3
    local first = (standing and nearest_wall_index ~= -1 and distanceToWall < 100)
    local second = (nearest_wall_index ~= -1 and distanceToWall < 100 and distanceToEnemy < 250)
    
    if ( first or second ) then
		-- print("First: ", first, " Second: ", second)
        return true
	end
	
    return false
end

local is_edge_safe = function(enemy)
	if enemy == nil then
		return
	end

	local enemy_origin = enemy:GetRenderOrigin()
	local enemy_predict = Vectors(extrapolate_position(enemy_origin.x, enemy_origin.y, enemy_origin.z, 16, enemy))
	
	local head_hitbox = local_player_getplayer:GetHitboxCenter(0)
	
	local damage1 = cheat.FireBullet(enemy, Vector.new(enemy_origin.x, enemy_origin.y, enemy_origin.z), Vector.new(head_hitbox.x, head_hitbox.y, head_hitbox.z))
	local damage2 = cheat.FireBullet(enemy, Vector.new(enemy_predict.x, enemy_predict.y, enemy_predict.z), Vector.new(head_hitbox.x, head_hitbox.y, head_hitbox.z))

    if (damage2.damage > 25) then
        return false
	end

    if (damage1.damage < 25) then
        return true
	end
		
    return false
end

local ragebot_shot = function()

	if not menu.enable_aa:GetBool() then
		return
	end

	if menu.aa_onshot:GetBool() then
		flip_onshot = true
	end
end

local weapon_fire = function()

	local player = g_EngineClient:GetPlayerForUserId(user_id)
	local entindex = g_EntityList:GetClientEntity(player)

	if entindex == nil then
		return
	end

	local player_ = entindex:GetPlayer()
	if player_:IsTeamMate() then
		return
	end

	lastshottime[entindex] = g_GlobalVars.curtime - 0.03125
end

local can_hit = function(entity)
	return (flip_evasion and enemyclosesttocrosshair == entity and not height_advantage)
end
local has_height = function(entity)
	return (height_advantage and enemyclosesttocrosshair == entity)
end
local shot_rn = function(entity)
	return (firedthistick[enemyclosesttocrosshairindex] and enemyclosesttocrosshair == entity)
end

local apply_offsets = function(mode,offset)

	local duckamt = local_player_ent:GetProp("m_flDuckAmount")
	local crouching_ct = duckamt >= 0.9 and is_crouching(local_player_ent) and local_player_ent:GetProp("m_iTeamNum") == 3 and not local_jumping
	local crouching_t = duckamt >= 0.9 and is_crouching(local_player_ent) and local_player_ent:GetProp("m_iTeamNum") == 2 and not local_jumping
	
	if mode == 1 then
		-- LOW DELTA
		if not holdingE then ref.aa_yaw_add:SetInt(0) end
		ref.aa_fake_options:SetInt(2)
		antiaim.OverrideLimit(58)
	elseif mode == 4 then
		-- JITTER
		if not holdingE then ref.aa_yaw_add:SetInt(local_velocity > 95 and 0 or 13) end
		ref.aa_fake_options:SetInt(0)
		antiaim.OverrideLimit(23)
	else
		if isFreestanding == false then
			-- MANUAL
			if not holdingE then ref.aa_yaw_add:SetInt(mode == 2 and -100 or mode == 3 and 90) end
			antiaim.OverrideInverter(false)
		else
			-- IDEAL YAW
			if not holdingE then ref.aa_yaw_add:SetInt((mode == 3 and crouching_ct and 17) or 0) end
			if anti_brute_FORCE and not eschiva then offset = not enemy_shot_angle[enemyclosesttocrosshairindex] end
			if eschiva then offset = not offset end
			if holdingE then offset = not offset end
			antiaim.OverrideInverter((flip_onshot and not offset) or offset)
		end

		-- SET YAW MODIFIER
		ref.aa_yaw_modifier:SetInt(0)

		-- SET LBY
		if menu.aa_lby:GetInt() == 0 then
			ref.aa_lby_mode:SetInt(ref.misc_doubletap:GetBool() and 0 or 2)
		else
			ref.aa_lby_mode:SetInt(0)
		end
		
		-- SET DESYNC
		if mode == 3 and crouching_ct then
			antiaim.OverrideLimit(30 + math.random(3,6))
		elseif holdingE then
			antiaim.OverrideLimit(58)
		else
			antiaim.OverrideLimit(max_dsy and 58 or menu.aa_set_limit:GetInt())
		end

		-- OTHERS
		ref.aa_fake_options:SetInt(0)
		ref.aa_freestanding_desync:SetInt(0)
	end
end

-- MAIN THREADS
local bullet_impact = function()
	local entity_idx = g_EngineClient:GetPlayerForUserId(user_id)
	local player = g_EntityList:GetClientEntity(entity_idx)
	local enitity_alive = player:GetProp("m_iHealth")

	if not (enitity_alive > 0) then
		return
	end

	local entity_index = player:GetPlayer()

	if not entity_index:IsDormant() and not entity_index:IsTeamMate() and entity_index == enemyclosesttocrosshair then

		local shot_origin_ = player:GetRenderOrigin()
		shot_origin_.z = shot_origin_.z + player:GetProp("m_vecViewOffset[2]")
		local shot_origin = { shot_origin_.x, shot_origin_.y, shot_origin_.z}
		
		local head_center = local_player_getplayer:GetHitboxCenter(0)
		local hitbox_pos = { head_center.x , head_center.y , head_center.z }

		local closest = GetClosestPoint(shot_origin, { event_x, event_y, event_z }, hitbox_pos)
		
		local delta = { hitbox_pos[1]-closest[1], hitbox_pos[2]-closest[2] }
		local delta_2d = math.sqrt(delta[1]^2+delta[2]^2)
		
		if math.abs(delta_2d) < 32 and ref.aa_yaw_add:GetInt() == 0 then
			available_resolver_information[entity_idx] = true
			enemy_shot_angle[entity_idx] = antiaim.GetInverterState()
			enemy_shot_time[entity_idx] = g_GlobalVars.curtime + 3.1
		else
			available_resolver_information[entity_idx] = false
		end
	else
		available_resolver_information[entity_idx] = false
	end
end

local setup_command = function(cmd)

	if not menu.enable_aa:GetBool() then return end

	local_player = g_EngineClient:GetLocalPlayer()
	local_player_ent = g_EntityList:GetClientEntity(local_player)
	local_player_getplayer = local_player_ent:GetPlayer()
	local_player_isplayer = local_player_ent:IsPlayer()
	local_velocity = get_velocity(local_player_ent)
	flipJitter = not flipJitter

	--GET ALL VALID ENEMIES
	enemies = g_EntityList:GetPlayers()
	local viewangles = g_EngineClient:GetViewAngles()
	local pitch = viewangles.pitch
	local yaw = viewangles.yaw
	local vx, vy, vz = angle_to_vec(pitch, yaw)

	local local_player_origin = local_player_ent:GetRenderOrigin()
	if local_player_origin.x == nil then return end

	local closest_fov_cos = -1
	enemyclosesttocrosshair = nil
	for i=1, #enemies do
		local idx = enemies[i]
		local idx_alive = idx:GetProp("m_iHealth")
		if (idx_alive > 0) then
			local idx_player = idx:GetPlayer()
			if not idx_player:IsTeamMate() then
				local fov_cos = get_fov_cos(idx, vx,vy,vz, local_player_origin.x,local_player_origin.y,local_player_origin.z)
				if fov_cos > closest_fov_cos then
					closest_fov_cos = fov_cos
					enemyclosesttocrosshairindex = idx:EntIndex()
					enemyclosesttocrosshair = idx
				end
			end
		end
	end
		

	if enemyclosesttocrosshair ~= nil then
		local eo = enemyclosesttocrosshair:GetRenderOrigin()
		height_advantage = eo.z > local_player_origin.z * 1.5
	end

	local_jumping = (cheat.IsKeyDown(0x20) and local_velocity > 100) or in_air(local_player_ent)

	if menu.enable_misc:GetBool() then
		-- LEG MOVEMENT
		local leg_exposed = is_Feet_Exposed(enemyclosesttocrosshair,16)
		if menu.misc_leg_movement:GetInt() == 0 then
			ref.misc_leg:SetInt(2)
		elseif menu.misc_leg_movement:GetInt() == 1 then
			if leg_exposed then
				ref.misc_leg:SetInt(0)
			else
				ref.misc_leg:SetInt(1)
			end
		else
			if leg_exposed then
				ref.misc_leg:SetInt(0)
			else
				ref.misc_leg:SetInt(flipJitter and local_velocity > 100 and 1 or 0)
			end
		end

		-- LEGIT AA
		if menu.misc_legit_aa:GetBool() and cheat.IsKeyDown(0x45) then
			if bit.band(cmd.buttons, bit.lshift(1,5)) == bit.lshift(1,5) then
				if legit_aa_timer > 5 then
					holdingE = true

					ref.aa_pitch:SetInt(0)
					ref.aa_yaw_add:SetInt(180)

					cmd.buttons = bit.band(cmd.buttons, bit.bnot(bit.lshift(1,5)))
				end
				legit_aa_timer = legit_aa_timer + 1
			end
		else
			holdingE = false

			ref.aa_pitch:SetInt(1)

			legit_aa_timer = 0
		end
	end

	-- AT TARGETS
	if menu.enable_aa:GetBool() then
		if menu.aa_yaw:GetInt() == 0 or holdingE or isLeft or isRight then
			ref.aa_yaw_base:SetInt(1)
		else
			ref.aa_yaw_base:SetInt(4)
		end
	end

	-- EDGE YAW
	local trace_start_edge = Vector.new()
	if menu.aa_edge_yaw:GetBool() and not can_enemy_hit_head(enemyclosesttocrosshair) and not local_jumping and not holdingE and not ref.aa_fake_duck:GetBool() and isFreestanding then	
		if g_ClientState.m_choked_commands == 0 then trace_start_edge = local_player_getplayer:GetEyePosition() end
		local trace_end = {}
	
		local view_ang = g_EngineClient:GetViewAngles()
		for fl_yaw = 18, 360, 18 do
			fl_yaw = normalize_yaw(fl_yaw)
	
			local edge_angle = QAngle.new(0, fl_yaw, 0)
	
			local vec_trace_end = trace_start_edge + cheat.AngleToForward(edge_angle) * 0x60
	
			local trace_info = g_EngineTrace:TraceRay(trace_start_edge, vec_trace_end, local_player_ent, 0x200400B)
	
			local fraction = trace_info.fraction
			local entity = trace_info.hit_entity
	
			if entity and entity:GetClassName() == 'CWorld' and fraction < 0.3 then
				trace_end[#trace_end+1] = {
					vec_trace_end = trace_info.endpos,
					fl_yaw = fl_yaw
				}
			end
		end
	
		table.sort(trace_end, function(a, b)
			return a.fl_yaw < b.fl_yaw
		end)
	
		local edge_angle
	
		if #trace_end >= 2 then
			local vec_trace_center = vector_lerp(trace_end[1].vec_trace_end, trace_end[#trace_end].vec_trace_end, 0.5)
	
			edge_angle = cheat.VectorToAngle(trace_start_edge - vec_trace_center)
		end
		
		if edge_angle then
			local fl_yaw = view_ang.yaw
			local edge_yaw = edge_angle.yaw
	
			local fl_diff = normalize_yaw(edge_yaw - fl_yaw)
	
			if math.abs(fl_diff) < 90 then 
				fl_diff = 0
				fl_yaw = normalize_yaw(edge_yaw + 180)
			end
	
			-- STATIC YAW
			local new_yaw = -fl_yaw
	
			-- APPLY EDGE YAW
			new_yaw = normalize_yaw(new_yaw + edge_yaw + 180)
			new_yaw = normalize_yaw(new_yaw + fl_diff)
	
			antiaim.OverrideYawOffset(math.floor(new_yaw))
		end
	end

	-- ONSHOT ANGLE
	if menu.aa_onshot:GetBool() then
		antiaim.OverrideDesyncOnShot(4)
	else
		antiaim.OverrideDesyncOnShot(0)
	end

	-- OTHER STUFF
	-- GET SLOW WALK SPEED
	if enemyclosesttocrosshair ~= nil then
	
		local active_weapon = enemyclosesttocrosshair:GetActiveWeapon()
		
		if active_weapon ~= nil then
		
			local active_idx = active_weapon:GetProp("m_iItemDefinitionIndex")
			if active_idx ~= nil then
				active_idx = bit.band(active_idx, 0xFFFF)
				
				maxspeed = weapons[active_idx].max_speed
				local weaponname = weapons[active_idx].console_name
				local scoped = enemyclosesttocrosshair:GetProp("m_bIsScoped") == 1
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
				
				--31% = STANDING SPREAD
				maxspeed = (maxspeed / 100) * 33
				
				if firedthistick[enemyclosesttocrosshairindex] == nil then firedthistick[enemyclosesttocrosshairindex] = false end
				
				local shot_time = active_weapon:GetProp("m_fLastShotTime")

				if lastshottime[enemyclosesttocrosshairindex] ~= nil then
					if (is_record_valid(lastshottime[enemyclosesttocrosshairindex],0.2)) then
						firedthistick[enemyclosesttocrosshairindex] = true
					else
						firedthistick[enemyclosesttocrosshairindex] = false
					end
				end
			end
		end
	end	

	if menu.aa_evasion:GetBool() then
		if(enemyclosesttocrosshair ~= nil and #enemies ~= 0 ) then
			-- EVASION AA BASED ON FAKE ANGLE (DESYNC)
			if enemyclosesttocrosshair:IsDormant() then
				return
			end
			
			local h = local_player_getplayer:GetHitboxCenter(0)
			local l = local_player_getplayer:GetEyePosition()
			l.z = h.z

			local desync = get_body_yaw(local_player_ent)
			
			l.x = l.x + math.cos(math.rad(desync)) * 20
			l.y = l.y + math.sin(math.rad(desync)) * 12	
			
			local enemyclosesttocrosshair_player = enemyclosesttocrosshair:GetPlayer()
			local e = enemyclosesttocrosshair_player:GetEyePosition()
			
			local lp_hp = local_player_ent:GetProp("m_iHealth")
			local damage = cheat.FireBullet(enemyclosesttocrosshair, Vector.new(e.x, e.y, e.z), Vector.new(l.x, l.y, l.z))
			-- print(damage.damage)
			-- print((menu.aa_evasion_slider:GetInt() * lp_hp) / 100)
			if damage.damage > (menu.aa_evasion_slider:GetInt() * lp_hp) / 100 then
				evasion_last_ent = evasion_ent
				evasion_ent = enemyclosesttocrosshair
			else
				evasion_last_ent = evasion_ent
				evasion_ent = nil
			end	
		end
	end
end

local run_command = function()

	if not menu.enable_aa:GetBool() then return end

	local lp_origin = local_player_ent:GetRenderOrigin()
	if lp_origin.x == nil then return end

	if menu.aa_evasion:GetBool() then
		if evasion_time <= g_GlobalVars.realtime then 
			if enemyclosesttocrosshair ~= nil and evasion_ent ~= nil and local_velocity > 5  and evasion_ent ~= evasion_last_ent then
				local player_resource = g_EntityList:GetPlayerResource()
				if player_resource == nil then
					return
				end

				local evasion_ent_index = evasion_ent:EntIndex()
				local ping = player_resource:GetProp("DT_CSPlayerResource", "m_iPing")[evasion_ent_index]

				local evasion_pingticks = time_to_ticks(ping / 1000) + 1
				if get_velocity(enemyclosesttocrosshair) <= maxspeed + 1 then
					evasion_vis_ticks = evasion_vis_ticks + 1
				end
				
				if evasion_vis_ticks > evasion_pingticks then
					evasion_time = g_GlobalVars.realtime + 0.5
					flip_evasion = true
				end
			else	
				evasion_vis_ticks = 0
				flip_evasion = false
			end
		end
	end

	-- FREESTAND
	compute_directions()
	compute_traces()
	closest_wall_side = get_closest_wall_side()
	anti_brute_FORCE = menu.aa_body_yaw:GetBool(0) and available_resolver_information[enemyclosesttocrosshairindex] and enemy_shot_angle[enemyclosesttocrosshairindex] ~= nil and (enemy_shot_time[enemyclosesttocrosshairindex] ~= nil and enemy_shot_time[enemyclosesttocrosshairindex] > g_GlobalVars.curtime)
	eschiva = flip_evasion and not is_crouching(local_player_ent) and not shot_rn(enemyclosesttocrosshair) and not height_advantage
	safe_angles = should_edge and safe_edge
	max_dsy = menu.aa_max_dsy:GetBool() and local_velocity < 3 and menu.aa_set_limit:GetInt() < 58

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
		fs_angle = (menu.aa_freestand:GetBool(0)) and freestanding_angle or stored_freestanding_angle
	elseif freestanding_angle2 ~= nil then
		fs_angle = (menu.aa_freestand:GetBool(0)) and freestanding_angle2 or stored_freestanding_angle2
	end
	-- print(fs_angle)

	should_edge = ShouldPreserve(enemyclosesttocrosshair)
	safe_edge = is_edge_safe(enemyclosesttocrosshair)

	if isFreestanding then 
		if menu.aa_body_yaw:GetBool(1) then 
			if should_edge then
				-- print("Preserving")
				if closest_wall_side == 0 then
					apply_offsets(2, false)
				elseif closest_wall_side == 1 then
					apply_offsets(3, true)
				end
			end
			if safe_angles then
				flip_evasion = false
				ref.aa_yaw_modifier:SetInt(1)
				ref.aa_modifier_degree:SetInt(-2)
				return
			end
		end

		if fs_angle == nil then
			return
		elseif fs_angle == -90 then
			apply_offsets(2, false)
		elseif fs_angle == 90 then
			apply_offsets(3, true)
		else
			apply_offsets(1, false)
		end	
	elseif isLeft then
		apply_offsets(2, false)
	elseif isRight then
		apply_offsets(3, true)
	elseif isBack then
		apply_offsets(4, false)
	end

	flip_onshot = false
end

ffi.cdef[[
    typedef int(__fastcall* clantag_t)(const char*, const char*);
]]
local fn_change_clantag = utils.PatternScan("engine.dll", "53 56 57 8B DA 8B F9 FF 15")
local set_clantag = ffi.cast("clantag_t", fn_change_clantag)
local animation = {
    "phoenix",
    "p7o3n1x"
}

local animation2 = {
	" ",
}

local old_time = 0
local clantag = function()
    if menu.misc_clan_tag:GetBool() then
    local curtime = math.floor(g_GlobalVars.curtime)
    if old_time ~= curtime then
        set_clantag(animation[curtime % #animation+1], animation[curtime % #animation+1])
    end
    old_time = curtime
	end
	
	local set_clantag = ffi.cast("clantag_t", fn_change_clantag)
	if not menu.misc_clan_tag:GetBool() then
	local curtime = math.floor(g_GlobalVars.curtime)
    if old_time ~= curtime then
	set_clantag(animation2[curtime % #animation2+1], animation2[curtime % #animation2+1])
	end
	old_time = curtime
	end
end

local draw_outline_text = function(text, x, y, color, size, font)
	g_Render:Text(text, Vector2.new(x - 1, y - 1), Color.new(0, 0, 0, 1), size, font)
	g_Render:Text(text, Vector2.new(x - 1, y), Color.new(0, 0, 0, 1), size, font)
	g_Render:Text(text, Vector2.new(x - 1, y + 1), Color.new(0, 0, 0, 1), size, font)

	g_Render:Text(text, Vector2.new(x, y + 1), Color.new(0, 0, 0, 1), size, font)
	g_Render:Text(text, Vector2.new(x, y - 1), Color.new(0, 0, 0, 1), size, font)

	g_Render:Text(text, Vector2.new(x + 1, y - 1), Color.new(0, 0, 0, 1), size, font)
	g_Render:Text(text, Vector2.new(x + 1, y), Color.new(0, 0, 0, 1), size, font)
	g_Render:Text(text, Vector2.new(x + 1, y + 1), Color.new(0, 0, 0, 1), size, font)

	g_Render:Text(text, Vector2.new(x, y), color, size, font)
end

local font = g_Render:InitFont("Smallest Pixel-7", 20)
local on_draw = function()
	if not local_player_ent then return end

	if not g_EngineClient:IsConnected() then return end

	clantag()
	local screen_size = g_EngineClient:GetScreenSize()
	local center_x = screen_size.x / 2 
	local center_y = screen_size.y / 2

	local desync = get_body_yaw(local_player_ent) / 1.7
	local offset = 24
	local color = menu.visuals_arrows:GetColor()
	local r,g,b,a = color:r(), color:g(), color:b(), color:a()
	local r2,g2,b2
	local anti_aim_text

	local side = 0 
	if isFreestanding then 
		if holdingE then
			anti_aim_text = "LEGIT"
		elseif menu.aa_body_yaw:GetBool(1) and safe_angles then
			anti_aim_text = "SAFE"
		elseif eschiva then 
			anti_aim_text = "EVASION"
		elseif anti_brute_FORCE then 
			anti_aim_text = "ANTI BF"
		elseif max_dsy then
			anti_aim_text = "MAXDSY"
		elseif fs_angle == 90 or fs_angle == -90 then
			anti_aim_text = menu.aa_edge_yaw:GetBool() and "DYNAMIC+" or "DYNAMIC"
		else
			anti_aim_text = "UPDATING..."
			r,g,b,a = 100/255, 100/255, 100/255, 100/255
		end

		if antiaim.GetInverterState() == true then
			side = holdingE and 2 or 1 
		elseif antiaim.GetInverterState() == false then
			side = holdingE and 1 or 2  
		end

		r2,g2,b2 = 230/255, 230/255, 200/255
	elseif isLeft or isRight then
		side = isLeft and 2 or 1
		anti_aim_text = "MANUAL"
		r2,g2,b2 = 255/255, 255/255, 255/255
	elseif isBack then
		side = 0
		anti_aim_text = "LOW DELTA"
		r2,g2,b2 = 230/255, 230/255, 200/255
	end

	if menu.visuals_arrows:GetBool() then 
		if menu.visuals_arrows_type:GetInt() == 2 then
			g_Render:PolyFilled(side == 1 and Color.new(r,g,b,a) or Color.new(100/255, 100/255, 100/255, 100/255), Vector2.new(center_x + 60, center_y), Vector2.new(center_x + 45, center_y + 10), Vector2.new(center_x + 45, center_y - 10))
			g_Render:PolyFilled(side == 2 and Color.new(r,g,b,a) or Color.new(100/255, 100/255, 100/255, 100/255), Vector2.new(center_x - 60, center_y), Vector2.new(center_x - 45, center_y + 10), Vector2.new(center_x - 45, center_y - 10))
		elseif menu.visuals_arrows_type:GetInt() == 1 then 
			g_Render:Text(">", Vector2.new(center_x + 45, center_y - 15), side == 1 and Color.new(r,g,b,a) or Color.new(100/255, 100/255, 100/255, 100/255), 30, true)
			g_Render:Text("<", Vector2.new(center_x - 60, center_y - 15), side == 2 and Color.new(r,g,b,a) or Color.new(100/255, 100/255, 100/255, 100/255), 30, true)
		end
	
		if menu.visuals_indicators:GetBool(0) then 
			draw_outline_text("PHOENIX", center_x, center_y + offset, color, 15, font)
			draw_outline_text(anti_aim_text, center_x, center_y + offset + 11, Color.new(r2,g2,b2), 15, font)
			offset = offset + 22
		end
	
		if ref.misc_doubletap:GetBool() and menu.visuals_indicators:GetBool(1) then
			if exploits.GetCharge() == 1 then
				draw_outline_text("DOUBLETAP", center_x, center_y + offset, Color.new(110/255, 210/255, 110/255), 15, font)
			else
				draw_outline_text("DOUBLETAP", center_x, center_y + offset, Color.new(220/255, 40/255, 40/255), 15, font)
			end
		end
	end
end

cheat.RegisterCallback("events", function(event)
	if not menu.enable_aa:GetBool() then return end
	if not local_player_ent then return end

	if event:GetName() == "bullet_impact" then	
		if menu.aa_body_yaw:GetBool(0) then
			user_id = event:GetInt("userid")
			event_x = event:GetInt("x")
			event_y = event:GetInt("y")
			event_z = event:GetInt("z")
			bullet_impact()
		end
	end

	if event:GetName() == "weapon_fire" then
		if not menu.aa_evasion:GetBool() then return end
		user_id = event:GetInt("userid")
		weapon_fire()
	end

	if event:GetName() == "bomb_beginplant" then
		if not menu.misc_legit_aa:GetBool() then return end
		user_id = event:GetInt("userid")
		local planting = g_EngineClient:GetPlayerForUserId(user_id)
		if planting == local_player then
			legit_aa_timer = -9999
		end
	end

	if event:GetName() == "bomb_begindefuse" then
		if not menu.misc_legit_aa:GetBool() then return end
		user_id = event:GetInt("userid")
		local planting = g_EngineClient:GetPlayerForUserId(user_id)
		if planting == local_player then
			legit_aa_timer = -9999
		end
	end

	if event:GetName() == "round_start" then	
		firedthistick = {}
		lastshottime = {}
		available_resolver_information = {}
		enemy_shot_angle = {}
		enemy_shot_time = {}
	end

	if event:GetName() == "cs_game_disconnected" then	
		firedthistick = {}
		lastshottime = {}
		available_resolver_information = {}
		enemy_shot_angle = {}
		enemy_shot_time = {}
	end

	if event:GetName() == "game_newmap" then	
		firedthistick = {}
		lastshottime = {}
		available_resolver_information = {}
		enemy_shot_angle = {}
		enemy_shot_time = {}
	end
end)

cheat.RegisterCallback("ragebot_shot", ragebot_shot)
cheat.RegisterCallback("pre_prediction", setup_command)
cheat.RegisterCallback("prediction", run_command)
cheat.RegisterCallback("draw", on_draw)

local menu_handle = function()
	local is_visible = cheat.IsMenuVisible()

	if is_visible then
		local evasion = menu.aa_evasion:GetBool()
		local arrow = menu.visuals_arrows:GetBool()
		local desync = menu.aa_set_limit:GetInt() < 58

		-- MENU 
		menu.aa_evasion_slider:SetVisible(evasion)
		menu.visuals_arrows_type:SetVisible(arrow)
		menu.visuals_indicators:SetVisible(arrow)
		menu.aa_max_dsy:SetVisible(desync)
	end
end
menu_handle()
menu.aa_evasion:RegisterCallback(menu_handle)
menu.visuals_arrows:RegisterCallback(menu_handle)
menu.aa_set_limit:RegisterCallback(menu_handle)

menu.misc_def_cfg:RegisterCallback(function()
	menu.enable_aa:SetBool(true)
	menu.enable_misc:SetBool(true)
	menu.enable_visauls:SetBool(true)
	menu.aa_freestand:SetInt(0)
	menu.aa_body_yaw:SetBool(0, true)
	menu.aa_body_yaw:SetBool(1, true)
	menu.aa_lby:SetInt(1)
	menu.aa_evasion:SetBool(true)
	menu.aa_evasion_slider:SetInt(50)
	menu.aa_set_limit:SetInt(45)
	menu.aa_max_dsy:SetBool(true)
	menu.aa_edge_yaw:SetBool(false)
	menu.aa_onshot:SetBool(true)
	menu.misc_legit_aa:SetBool(true)
	menu.misc_leg_movement:SetInt(2)
	menu.misc_clan_tag:SetBool(false)
	menu.visuals_arrows:SetBool(true)
	menu.visuals_arrows_type:SetInt(0)
	menu.visuals_indicators:SetBool(0, true)
	menu.visuals_indicators:SetBool(1, true)
end)
