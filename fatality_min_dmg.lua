

local globals = csgo.interface_handler:get_global_vars( );

local menu = fatality.menu;
local render = fatality.render;
local config = fatality.config;
local input = fatality.input;
local engine_client = csgo.interface_handler:get_engine_client()
local global_vars = csgo.interface_handler:get_global_vars()
local cvar = csgo.interface_handler:get_cvar( )
local entity_list = csgo.interface_handler:get_entity_list( )

local screensize = render:screen_size()

local mindmg_show = false

local dmgauto = config:get_weapon_setting("autosniper", "mindmg")
local dmgawp = config:get_weapon_setting("awp", "mindmg")
local dmgscout = config:get_weapon_setting("scout", "mindmg")
local dmgheavypistol = config:get_weapon_setting("heavy_pistol", "mindmg")
local dmgpistol = config:get_weapon_setting("pistol", "mindmg")
local dmgother = config:get_weapon_setting("other", "mindmg")

print ("lua made by bogdan#0007")

local min_dmg_keybind = config:add_item("min_dmg_keybind", 0)

local font = render:create_font('Arial', 30, 650, true)
local color = csgo.color(255,255,255,255)

local auto_cfg, awp_cfg, pistols_cfg, scout_cfg, heavyp_cfg, other_cfg =
    config:add_item( "auto_cfg", 0 ),
    config:add_item( "awp_cfg", 0 ),
    config:add_item( "scout_cfg", 0 ),
    config:add_item( "heavyp_cfg", 0 ),
    config:add_item( "pistols_cfg", 0 ),
    config:add_item( "other_cfg", 0 );

  local auto_cfg_backup, awp_cfg_backup, pistols_cfg_backup, scout_cfg_backup, heavyp_cfg_backup, other_cfg_backup =
      config:add_item( "auto_cfg_backup", 0 ),
      config:add_item( "awp_cfg_backup", 0 ),
      config:add_item( "scout_cfg_backup", 0 ),
      config:add_item( "heavyp_cfg_backup", 0 ),
      config:add_item( "pistols_cfg_backup", 0 ),
      config:add_item( "other_cfg_backup", 0 );

local buttonPres = menu:add_button('< Normal Damage >', "Rage", "Aimbot", "Aimbot")

local auto_menu_backup, awp_menu_backup, pistols_menu_backup, scout_menu_backup, heavyp_menu_backup, other_menu_backup =
      menu:add_slider( "Auto", "Rage", "Aimbot", "Aimbot", auto_cfg_backup, 0, 130, 1 ),
      menu:add_slider( "Awp", "Rage", "Aimbot", "Aimbot", awp_cfg_backup, 0, 130, 1 ),
	    menu:add_slider( "Scout", "Rage", "Aimbot", "Aimbot", scout_cfg_backup, 0, 130, 1 ),
      menu:add_slider( "Heavy pistol", "Rage", "Aimbot", "Aimbot", heavyp_cfg_backup, 0, 130, 1 ),
      menu:add_slider( "Pistol", "Rage", "Aimbot", "Aimbot", pistols_cfg_backup, 0, 130, 1 ),
      menu:add_slider( "Other", "Rage", "Aimbot", "Aimbot", other_cfg_backup, 0, 130, 1 );

local buttonPres = menu:add_button('< Override Damage >', "Rage", "Aimbot", "Aimbot")

local auto_menu, awp_menu, pistols_menu, scout_menu, heavyp_menu, other_menu =
       menu:add_slider( "Auto", "Rage", "Aimbot", "Aimbot", auto_cfg, 0, 130, 1 ),
       menu:add_slider( "Awp", "Rage", "Aimbot", "Aimbot", awp_cfg, 0, 130, 1 ),
	     menu:add_slider( "Scout", "Rage", "Aimbot", "Aimbot", scout_cfg, 0, 130, 1 ),
	     menu:add_slider( "Heavy pistol", "Rage", "Aimbot", "Aimbot", heavyp_cfg, 0, 130, 1 ),
       menu:add_slider( "Pistol", "Rage", "Aimbot", "Aimbot", pistols_cfg, 0, 130, 1 ),
       menu:add_slider( "Other", "Rage", "Aimbot", "Aimbot", other_cfg, 0, 130, 1 );


function manage_menu( toggle )
    if ( toggle ) then
        config:get_weapon_setting("autosniper", "mindmg"):set_int( auto_cfg:get_int( ) );
        config:get_weapon_setting("awp", "mindmg"):set_int( awp_cfg:get_int( ) );
        config:get_weapon_setting("pistol", "mindmg"):set_int( pistols_cfg:get_int( ) );
        config:get_weapon_setting("scout", "mindmg"):set_int( scout_cfg:get_int( ) );
        config:get_weapon_setting("heavy_pistol", "mindmg"):set_int( heavyp_cfg:get_int( ) );
        config:get_weapon_setting("other", "mindmg"):set_int( other_cfg:get_int( ) );
    else
        config:get_weapon_setting("autosniper", "mindmg"):set_int( auto_cfg_backup:get_int( ) );
        config:get_weapon_setting("awp", "mindmg"):set_int( awp_cfg_backup:get_int( ) );
        config:get_weapon_setting("scout", "mindmg"):set_int( scout_cfg_backup:get_int( ) );
        config:get_weapon_setting("heavy_pistol", "mindmg"):set_int( heavyp_cfg_backup:get_int( ) );
		config:get_weapon_setting("pistol", "mindmg"):set_int( pistols_cfg_backup:get_int( ) );
        config:get_weapon_setting("other", "mindmg"):set_int( other_cfg_backup:get_int( ) );
    end
end

local key_combo = menu:add_combo("Override damage option", "Rage", "AIMBOT", "aimbot", min_dmg_keybind)
key_combo:add_item("Hold", min_dmg_keybind)
key_combo:add_item("Toggle", min_dmg_keybind)

local buttonPres = menu:add_button('< Indicator >', "Rage", "Aimbot", "Aimbot")
local mindmg_show_x = config:add_item( "mindmg_show_x", 10 )
local mindmg_show_y = config:add_item( "mindmg_show_y", 125 )

local mindmg_show_x = menu:add_slider( "Move X", "Rage", "Aimbot", "Aimbot", mindmg_show_x, 0, screensize.x, 1)
local mindmg_show_y = menu:add_slider( "Move Y", "Rage", "Aimbot", "Aimbot", mindmg_show_y, 0, screensize.y, 1)

local mindmg_show_x = menu:get_reference( "Rage", "Aimbot", "Aimbot", "Move X")
local mindmg_show_y = menu:get_reference( "Rage", "Aimbot", "Aimbot", "Move Y")

local key = 0x46; -- change here ( https://docs.microsoft.com/en-us/windows/desktop/inputdev/virtual-key-codes )
local last_timer = globals.tickcount;
local ins_key = 0x2D
local is_menu_opened = true
function on_paint()

	local localPlayer = entity_list:get_localplayer()


	if not engine_client:is_in_game( ) then
        return end



        if min_dmg_keybind:get_int() == 0 then
        if(input:is_key_down(key)) then
                mindmg_show = true
                manage_menu( true );
        else
                mindmg_show = false
                manage_menu( false );
        end


    end


	if min_dmg_keybind:get_int() == 1 then
        if(input:is_key_pressed(key)) then
            toggled = not toggled;
        end

        if ( toggled ) then
            mindmg_show = true
            manage_menu( true );
        else
            mindmg_show = false
            manage_menu( false );
        end
    end


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

		if currentWeapon == 'auto' then
			render:text( font, mindmg_show_x:get_int( ), mindmg_show_y:get_int( ), dmgauto:get_int(), color )
		elseif currentWeapon == 'awp' then
			render:text( font, mindmg_show_x:get_int( ), mindmg_show_y:get_int( ), dmgawp:get_int(), color )
		elseif currentWeapon == 'scout' then
			render:text( font, mindmg_show_x:get_int( ), mindmg_show_y:get_int( ), dmgscout:get_int(), color )
		elseif currentWeapon == 'heavy pistol' then
			render:text( font, mindmg_show_x:get_int( ), mindmg_show_y:get_int( ), dmgheavypistol:get_int(), color )
		elseif currentWeapon == 'pistol' then
			render:text( font, mindmg_show_x:get_int( ), mindmg_show_y:get_int( ), dmgpistol:get_int(), color )
		elseif currentWeapon == 'other' then
			render:text( font, mindmg_show_x:get_int( ), mindmg_show_y:get_int( ), dmgother:get_int(), color )
		elseif currentWeapon == 'knife' then
			render:text( font, mindmg_show_x:get_int( ), mindmg_show_y:get_int( ), '100', color )
		end
	end



local callbacks = fatality.callbacks;
callbacks:add( "paint", on_paint )
