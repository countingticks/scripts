-- interfaces
local cvar = csgo.interface_handler:get_cvar( )
local render = fatality.render
local entity_list = csgo.interface_handler:get_entity_list( )
local global_vars = csgo.interface_handler:get_global_vars( )

-- config & menu access
local menu = fatality.menu
local config = fatality.config

-- adding developer cvar to set it to 0 in future
local developer = cvar:find_var("developer")

-- setting cvar to 0
developer:set_int(0)

-- creating logs variable to place the logs there
local logs = {}

-- creating function to take logs from on shot function
function add_log(text,r,g,b)
    table.insert(logs, {text = text, expiration = 18, fadein = 0, red = r, green = g, blue=b})
end

-- needed variables
local normal_font = render:create_font( 'Verdana Bold', 13, 800, true );
local screensize = render:screen_size();

-- on pain function
function on_paint()


    -- event log
    for i = 1, #logs do

        -- nil check
        if (logs[i] ~= nil) then

            -- variable of ratio
            local ratio = 1.5

            -- setting the time of animation
            if (logs[i].expiration <= 1.5) then
                ratio = (logs[i].expiration) / 1
            end


            -- smoothly animated alpha
            if (logs[i].expiration <= 2.5) then
                alpha = 240
            elseif (logs[i].expiration <= 2.4) then
                alpha = 180
            elseif (logs[i].expiration <= 2.3) then
                alpha = 140
            elseif (logs[i].expiration <= 2.2) then
                alpha = 120
            elseif (logs[i].expiration <= 2.1) then
                alpha = 100
            elseif (logs[i].expiration <= 2.0) then
                alpha = 60
            elseif (logs[i].expiration <= 1.9) then
                alpha = 0
            elseif (logs[i].expiration <= 1.8) then
                alpha = 80
            elseif (logs[i].expiration <= 1.7) then
                alpha = 60
            elseif (logs[i].expiration <= 1.6) then
                alpha = 40
            elseif (logs[i].expiration <= 1.5) then
                alpha = 20
            elseif (logs[i].expiration <= 1.4) then
                alpha = 0
            else
                alpha = 255
            end




            render:text(normal_font, 7, 7 * (i - 1) * 2 - ((1 - ratio) * 15),  logs[i].text, csgo.color(logs[i].red,logs[i].green,logs[i].blue, alpha))


            -- removes log if time is expired
            logs[i].expiration = logs[i].expiration - 0.01
            if (logs[i].expiration <= 1.2) then
                table.remove(logs, i)
            end

        end


    end

end


local function get_hitgroup(hitgroup)
  if hitgroup == 1 then
      return "head"
      elseif hitgroup == 2 then
      return "chest"
      elseif hitgroup == 3 then
      return "stomach"
      elseif hitgroup == 4 then
      return "hand"
      elseif hitgroup == 5 then
      return "arm"
      elseif hitgroup == 6 then
      return "leg"
      elseif hitgroup == 7 then
      return "feet"
      elseif hitgroup == 8 then
      return "neck"
      else
      return "unknown"
  end
end

-- on shot function
function on_registered_shot( shot )


    -- creating a variable of the enemy
    local enemy = entity_list:get_player( shot.victim )

    -- nil check
    if enemy == nil then
        return
    end

    -- getting shot info
    local shot_info_t = shot.shot_info

    -- returns the function if something goes wrong
    if not shot_info_t.has_info then
        return
    end

    -- creating a variable of default hitgroup
    local hitgroup=0

	local targetdamage = shot.target_damage
    local inaccuracy = shot.inaccuracy
    local targethitchance = shot.hitchance
    local backtrack1 = shot.shot_info
    local backtrack = backtrack1.backtrack_ticks

	local targethitgroup = get_hitgroup(shot.target_hitgroup)

    -- if we did a hit
    if shot.hurt then

        local getHealth = enemy:get_var_int("CBasePlayer->m_iHealth")

        --
        hitgroup=shot.hit_hitgroup

        -- hitgroup renaming from int to string
        if hitgroup == 1 then
            hitgroup = "head"
            elseif hitgroup == 2 then
            hitgroup = "chest"
            elseif hitgroup == 3 then
            hitgroup = "stomach"
            elseif hitgroup == 4 then
            hitgroup = "hand"
            elseif hitgroup == 5 then
            hitgroup = "arm"
            elseif hitgroup == 6 then
            hitgroup = "leg"
            elseif hitgroup == 7 then
            hitgroup = "feet"
            elseif hitgroup == 8 then
            hitgroup = "neck"
            else
            hitgroup = "unknown"
        end

         -- if the cheat did a hit, then render this line
        add_log( "[HURT] " .. enemy:get_name( ) .. " | Target Hitbox: " .. targethitgroup .. " | Hit Hitbox: " .. hitgroup .. " | Target Hitchance: " .. math.floor(targethitchance * 10) / 10 .. " | Target Damage: " .. targetdamage .. " | Damage: " .. shot.hit_damage .. " " .. "(" .. getHealth .. " health remaining)",255,255,255 )
        local info = enemy:get_name( ) .. " | Target Hitbox: " .. targethitgroup .. " | Hit Hitbox: " .. hitgroup .. " | Target Hitchance: " .. math.floor(targethitchance * 10) / 10 .. " | Backtrack: " .. backtrack .. " | Target Damage: " .. targetdamage .. " | Damage: " .. shot.hit_damage .. " " .. "(" .. getHealth .. " health remaining)" .. "\n"
        cvar:print_console( "[ HURT ] ", csgo.color( 252, 65, 3,255))
        cvar:print_console( info, csgo.color(255,255,255,255) )
    -- if the cheat did a miss because of the resolver problem
    elseif not shot.hurt and shot.hit then

        -- log that shows if we did a miss
        add_log("[RESOLVER] " .. enemy:get_name( ) .. " | Target Hitbox: " .. targethitgroup,240, 55, 58 )
        local info = "[ RESOLVER ] " .. enemy:get_name( ) .. " | Target Hitbox: " .. targethitgroup .. "\n"
        cvar:print_console( info, csgo.color(240, 55, 58,255) )
    -- miss due to accuracy
    else
        -- log that shows if we did a miss
        add_log("[SPREAD] " .. enemy:get_name( ) .. " | " .. "Target Hitbox: " .. targethitgroup .. " | Target Hitchance: " .. math.floor(targethitchance * 10) / 10 ,227,219,66 )
        local info = "[ SPREAD ] " .. enemy:get_name( ) .. " | " .. "Target Hitbox: " .. targethitgroup .. " | Target Hitchance: " .. math.floor(targethitchance * 10) / 10 .. " | Backtrack: " .. backtrack .. "\n"
        cvar:print_console( info, csgo.color(227,219,66,255) )
    end

end

function on_event( event )
	 local local_player = entity_list:get_localplayer( )

	 if not local_player then
		return end

	 local get_team_local = local_player:get_var_int( "CBaseEntity->m_iTeamNum" )

	 if event:get_name( ) == "item_purchase" then
		if event:get_int( "team" ) ~= get_team then
			local enemy = entity_list:get_player_from_id( event:get_int( "userid" ) )
			local weapon = event:get_string( "weapon" )

			if enemy:get_index( ) ~= local_player:get_index( ) then --we prolly dont want to see our things in buy log
				if weapon == "weapon_unknown" then
					return end

				if not weapon then
					return end

				local info = enemy:get_name( ) .. " bought " .. weapon .. "." .. "\n"
				cvar:print_console( "[ PURCHASE ] ", csgo.color( 3, 152, 252,255))
				cvar:print_console( info, csgo.color( 255, 255, 255,255) )
			end
		end
	end
end


-- callbacks
local callbacks = fatality.callbacks
callbacks:add( "registered_shot", on_registered_shot )
callbacks:add( "paint", on_paint )
callbacks:add( "events", on_event )

-- end of the code
