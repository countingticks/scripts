const user = Cheat.GetUsername();
const user_list = {"RazvanDard" : "dev", "bogdan56" : "dev", "adriaN1" : "beta" , "Alex23Pvp" : "beta"};

var prefix = user_list[user];

if(prefix != "dev" && prefix != "beta")
	prefix = "";
//#region Fonts
var arrows_font = null;
var font = null;
var draggable_font = null;
var tab_selected = null;
var menu_font = null;
var logo_font = null;
//#endregion

const input_system = {
    pressed_keys: [ ],
    last_pressed_keys: [ ]
};

const cursor = {
    x: 0,
    y: 0,
    delta_x: 0,
    delta_y: 0,
    dragging: false
};

/* region: input_system */
input_system.update = function( ) {
	// loop thru all keys
	for ( var i = 1; i < 255; ++i ) {
		// save current pressed keys
		this.last_pressed_keys[ i ] = this.pressed_keys[ i ];

		// update pressed keys
		this.pressed_keys[ i ] = Input.IsKeyPressed( i );
	}

	// handle hotkeys

}

input_system.is_key_down = function( key ) {
    return this.pressed_keys[ key ];
}

input_system.is_key_pressed = function( key ) {
    return this.pressed_keys[ key ] && !this.last_pressed_keys[ key ];
}

input_system.is_key_released = function( key ) {
    return !this.pressed_keys[ key ] && this.last_pressed_keys[ key ];
}

input_system.cursor_in_bounds = function( x, y, w, h ) {
    return cursor.x > x && cursor.y > y && cursor.x < x + w && cursor.y < y + h;
}

input_system.enable_mouse_input = function (active) {
    Input.ForceCursor(+active)
}

input_system.fix_input = function () {
    // check if menu isn't open
    if (!menu.is_open)
        return;

    // override buttons so we don't shoot while in the menu
    UserCMD.SetButtons(UserCMD.GetButtons() & ~(1 << 0));
}

input_system.update_input = function()
{
	cursor.x = Input.GetCursorPosition()[0];
	cursor.y = Input.GetCursorPosition()[1];

	input_system.update( );
}

function contains(list, elem)
{
	for(var i = 0; i < list.length;i++)
		if(list[i] == elem)
			return true;

	return false;
}
function DraggableUI(x, y, w, h, render_function)
{
	this.x = x;
	this.y = y;
	this.w = w;
	this.h = h;

	this.delta_x = 0;
	this.delta_y = 0;
	this.dragging = false;
	
	this.render = function() 
	{
		render_function(this.x, this.y, this.w, this.h);

		if ( !input_system.is_key_down( 0x01 ) )
		{
			this.dragging = false;
			cursor.dragging = false;
		}
 
		// check if we're dragging the window
		if ( input_system.is_key_down( 0x01 ) && input_system.cursor_in_bounds( this.x, this.y, this.w, this.h ) || this.dragging ) {
			// update dragging state
			if(!this.dragging && cursor.dragging) return; // aka dragging something else

			this.dragging = true;
			cursor.dragging = true;
			// update menu position
			this.x = cursor.x - this.delta_x;
			this.y = cursor.y - this.delta_y;
		}

		else {
			// update cursor-menu delta
			this.delta_x = cursor.x - this.x;
			this.delta_y = cursor.y - this.y;
		}
	}

}


get_spectators = function()
{
	const spectators = [];

    const entities = Entity.GetPlayers();
    const local = Entity.GetLocalPlayer();

    const local_target = Entity.GetProp(local, "CBasePlayer", "m_hObserverTarget");

    if(!local) return spectators;

	const is_local_alive = Entity.IsAlive(local);

    for (i = 0; i < entities.length; i++) 
	{	
		if (!entities[i] || Entity.IsAlive(entities[i]) || Entity.IsDormant(entities[i])) 
			continue;

		var spectator = Entity.GetProp(entities[i], "CBasePlayer", "m_hObserverTarget");
		if (!spectator || spectator == "m_hObserverTarget") 
			continue;

		if(spectator == local && is_local_alive)
			spectators.push(Entity.GetName(entities[i]));

		else if(spectator == local_target && !is_local_alive)
			spectators.push(Entity.GetName(entities[i]));
	}

	return spectators;
}

get_keybinds = function()
{
    const paths = [
        ["Rage", "General", "General", "Key assignment"],
        ["Rage", "Exploits", "Keys", "Key assignment"],
        ["Rage", "Anti Aim", "General", "Key assignment"],
        ["Misc.", "Keys", "General", "Key assignment"],
        ["Config", "Scripts", "Keys", "JS Keybinds"]
    ];

    const hotkeys = [];

    for (var i = 0; i < paths.length; i++) {
        const children = UI.GetChildren(paths[i]);
        for (var x = 0; x < children.length; x++) {
            if (UI.GetValue(paths[i].concat(children[x]))) {
                const state = UI.GetHotkeyState(paths[i].concat(children[x]));
				if(children[x] == "Ragebot activation" || children[x] == "Thirdperson")
					continue;
				
				var str_end = children[x].length;
				if(children[x][str_end - 3] + children[x][str_end - 2] + children[x][str_end - 1]  == "key")
				{
					var str = "";
					for(var t = 0; t < str_end - 3;t++)
						str += children[x][t];

					hotkeys.push([str, state]);
				}
				else
                	hotkeys.push([children[x], state]);
            };
        };
    };

    return hotkeys;
};

const draw_outline_text = function(x, y, align, string, color, fontname) {
	if(string == undefined) return;

	Render.String(x - 1, y - 1, align, string, [0, 0, 0, 255], fontname);
	Render.String(x - 1, y, align, string, [0, 0, 0, 255], fontname);
	Render.String(x - 1, y + 1, align, string, [0, 0, 0, 255], fontname);

	Render.String(x, y + 1, align, string, [0, 0, 0, 255], fontname);
	Render.String(x, y - 1, align, string, [0, 0, 0, 255], fontname);

	Render.String(x + 1, y - 1, align, string, [0, 0, 0, 255], fontname);
	Render.String(x + 1, y, align, string, [0, 0, 0, 255], fontname);
	Render.String(x + 1, y + 1, align, string, [0, 0, 0, 255], fontname);

	Render.String(x, y, align, string, color, fontname);
}

var render_watermark = function(x, y, w, h)
{
	const delay = Math.floor(Local.Latency() * 1000);
	
	var text = "phoenix" + " | " + user + " | delay: " + delay + " ms";

	if(prefix != "")
		text = "phoenix [" + prefix + "] | " + user + " | delay: " + delay + " ms";

	const text_size = Render.TextSize(text, draggable_font);

	const width = text_size[0] + 8;

	Render.FilledRect( x - width, y, width, h, [30,30,30,180]);
	Render.FilledRect( x - width, y, width, 2, [230, 104, 44,255]);
	Render.Rect( x - 1 - width, y - 1, width + 1, h + 1, [10, 10, 10,255]);

    Render.String( x + 4 - width, y + 1, 0, text , [ 255, 255, 255, 255 ], draggable_font);
}

var render_spectator_list = function(x, y, w, h)
{
	Render.FilledRect( x, y, w, h, [30,30,30,180]);
	Render.FilledRect( x, y, w, 2, [230, 104, 44,255]);
	Render.Rect( x - 1, y - 1, w + 1, h + 1, [10, 10, 10,255]);

	const text_size = Render.TextSize("Spectators", draggable_font);

    Render.String( x + w / 2 - text_size[0] / 2, y + 1, 0, "Spectators", [ 255, 255, 255, 255 ], draggable_font);

	const spectators = get_spectators();
	var last_pos = y + h;

	for(var i = 0; i < spectators.length;i++)
	{
		draw_outline_text( x + w / 2, last_pos , 1, String(spectators[i]) , [ 255, 255, 255, 255 ], draggable_font);
		last_pos += 10;
	}
}

var render_keybinds = function(x, y, w, h)
{
	Render.FilledRect( x, y, w, h, [30,30,30,180]);
	Render.FilledRect( x, y, w, 2, [230, 104, 44,255]);
	Render.Rect( x - 1, y - 1, w + 1, h + 1, [10, 10, 10,255]);

	var text_size = Render.TextSize("Keybinds", draggable_font);

    Render.String( x + w / 2 - text_size[0] / 2, y + 1, 0, "Keybinds", [ 255, 255, 255, 255 ], draggable_font);

	var hotkeys = get_keybinds();
	var last_pos = y + h;

	for(var i = 0; i < hotkeys.length;i++)
	{
		if(hotkeys[i][1]) // if keybind is on
		{
			draw_outline_text( x + w / 2, last_pos , 1, String(hotkeys[i][0]) , [ 255, 255, 255, 255 ], draggable_font);
			last_pos += 10;
		}
	}
}


const MenuStyles = 
{
    theme : [230, 104, 44,255],
    theme_not_selected : [230, 104, 44, 155],
    background : [60,60,60,255]
}

const Colors = 
{
    black : [0, 0, 0, 255],
    grey : [30, 30, 30, 255],
    white : [255, 255, 255, 255],
    red : [255, 0, 0, 255],
    blue : [0, 255, 0, 255],
    green : [0, 0, 255, 255]
}

function Menu(x, y, w, h)
{
	this.x = x;
	this.y = y;
	this.w = w;
	this.h = h;

	this.delta_x = 0;
	this.delta_y = 0;
	this.dragging = false;
	
    this.is_open = true;
    this.children = [];

    this.cur_tab = 0;
	this.focus = null;
	this.was_focus_opened = false;

	//this.dpi_scale = 1;

	this.update_dpi = function(scale)
	{
		this.w *= scale 
		this.h *= scale 
	}

	this.drag = function() 
	{
		if ( !input_system.is_key_down( 0x01 ) )
		{
			this.dragging = false;
			cursor.dragging = false;
		}
		if ( input_system.is_key_down( 0x01 ) && input_system.cursor_in_bounds( this.x, this.y, this.w, this.h * 0.05) || this.dragging ) {
			// update dragging state
			if(!this.dragging && cursor.dragging) return; // aka dragging something else

			this.dragging = true;
			cursor.dragging = true;
			// update menu position
			this.x = cursor.x - this.delta_x;
			this.y = cursor.y - this.delta_y;

			if(this.y < 0)
				this.y = 0;
		}

		else {
			// update cursor-menu delta
			this.delta_x = cursor.x - this.x;
			this.delta_y = cursor.y - this.y;
		}
	}

    this.render = function()
    {
        Render.FilledRect(this.x, this.y, this.w, this.h , [30,30,30, 200]);
        Render.FilledRect(this.x, this.y, this.w * 0.25, this.h , Colors.grey);
        Render.FilledRect(this.x, this.y, this.w, 2 , MenuStyles.theme);

        Render.Rect(this.x - 1, this.y - 1, this.w + 1, this.h + 1, Colors.black);

        draw_outline_text(this.x + 62, this.y + this.h * 0.1, 1 , "Project", MenuStyles.theme, logo_font)
        draw_outline_text(this.x + 62, this.y + this.h * 0.16, 1 , "Phoenix", MenuStyles.theme, logo_font)

        draw_outline_text(this.x + 62, this.y + this.h * 0.23, 1 , "[ " + String(user) + " ]", Colors.white, menu_font)
        
        var text_size = Render.TextSize("[ " + prefix + " ]" , menu_font);
		if(prefix != "")
        	draw_outline_text(this.x + this.w - text_size[0] * 1.1, this.y + this.h - text_size[1] * 1.35, 0 , "[ " + prefix + " ]" , Colors.white, menu_font)
    }

    this.add_tab = function(x, y, text)
    {
        this.children.push(new Tab(x, y, text, this.children.length));
    }

    this.add_checkbox = function(tab_name, name)
    {
        var chk = new Checkbox(tab_name, name);
        for(var i = 0; i < this.children.length;i++)
        {
            if(this.children[i].text == tab_name)
                this.children[i].children.push(chk);
        }
        return chk;
    }

	this.add_keybind = function(tab_name, name, default_key, allow_modes)
    {
        var keybind = new Keybind(tab_name, name, default_key, allow_modes);
        for(var i = 0; i < this.children.length;i++)
        {
            if(this.children[i].text == tab_name)
                this.children[i].children.push(keybind);
        }
        return keybind;
    }

    this.add_slider = function(tab_name, name, min_val, max_val, sign)
    {
        var slider = new Slider(tab_name, name, min_val, max_val, sign);
        for(var i = 0; i < this.children.length;i++)
        {
            if(this.children[i].text == tab_name)
                this.children[i].children.push(slider);
        }
        return slider;
    }

	this.add_combobox = function(tab_name, name, values, multi, deselectable)
    {
		
        var combo;

		if(multi)
			combo = new MultiBox(tab_name, name, values);
		else 
			combo = new ComboBox(tab_name, name, values, deselectable);

        for(var i = 0; i < this.children.length;i++)
        {
            if(this.children[i].text == tab_name)
                this.children[i].children.push(combo);
        }
        return combo;
    }

    this.handle_children = function()
    {
        for(var i = 0; i < this.children.length;i++)
        {
            this.children[i].setup_positions(this.x, this.y + i * 20);
            this.children[i].handle_input();
            this.children[i].render();

            if(i == this.cur_tab)
                this.children[i].handle_children();
        }
    }

}

function Tab(x, y, text, tab_index)
{
    this.x = 0;
    this.y = 0;

    this.offset_x = x;
    this.offset_y = y;

    this.text = text; 
    this.tab_index = tab_index;
    this.hovering = false;

    this.children = [];
	this.click_tick = null;

    this.setup_positions = function(x,y)
    {
        this.x = x;
        this.y = y;
    }

    this.render = function()
    {
        if(menu.cur_tab == this.tab_index)
        {
            var text_size = Render.TextSize(this.text, tab_selected)

            draw_outline_text(this.x + this.offset_x, this.y + this.offset_y, 1, text , MenuStyles.theme, tab_selected)
			
			var start = this.x + this.offset_x - text_size[0] / 2 - 5;
			var end = this.x + this.offset_x + text_size[0] / 2 + 5
			var middle = (start + end) / 2;

			var time_passed = Date.now() - this.click_tick;
			var time_needed = 200;
			var p = time_passed / time_needed;
			var dist = start - middle;
			
			if(time_needed > time_passed)
				Render.FilledRect(middle + dist * p, this.y + this.offset_y + text_size[1] + 5, Math.abs(dist * p * 2.1), 3, MenuStyles.theme)
			else 
				Render.FilledRect(this.x + this.offset_x - text_size[0] / 2 - 5, this.y + this.offset_y + text_size[1] + 5, text_size[0] + 15, 3, MenuStyles.theme)
        }
        else if(this.hovering)
            draw_outline_text(this.x + this.offset_x, this.y + this.offset_y, 1, text , MenuStyles.theme_not_selected, font)
        else
            draw_outline_text(this.x + this.offset_x, this.y + this.offset_y, 1, text , Colors.white, font)
    }

    this.handle_children = function()
    {
        var padding = 0;
        var adder_x = 135;
        var adder_y = 0
		menu.was_focus_opened = false;
		if(menu.focus && menu.focus.tab == this.text)
		{
			menu.was_focus_opened = menu.focus.is_open;
			menu.focus.handle_input();
		}
        for(var i = 0; i < this.children.length; i++)
        {
            if(menu.y + 10 + padding > menu.y + menu.h * 0.9)
            {
                adder_x = 270;
                adder_y = 20;
                padding = 0;
            }

            this.children[i].setup_positions(this.x + adder_x, menu.y + 15 + padding + adder_y)

			if(this.children[i].visible)
            {
                padding += this.children[i].padding;
            }

			if(this.children[i] != menu.focus)
            	this.children[i].handle_input()

            this.children[i].render()

        }
		if(menu.focus && menu.focus.tab == this.text)
		{
			menu.focus.render();
		}

    }

    this.handle_input = function()
    {
        var in_bounds = input_system.cursor_in_bounds(this.x, this.y + this.offset_y, 125, 20)

        if(input_system.is_key_pressed( 0x01 ) && in_bounds)
		{
			if(menu.cur_tab != this.tab_index)
			{
				menu.cur_tab = this.tab_index;
				this.click_tick = Date.now();
				menu.focus = null;
			}
		}
        else if(in_bounds)
            this.hovering = true;
        else
            this.hovering = false;
    }
}

function Checkbox(tab_name, name)
{
    this.tab = tab_name;
    this.name = name;
    this.value = false;

    this.x = 0;
    this.y = 0;

    this.w = 10;
    this.h = 10;

	this.type = "checkbox"
    this.hovering = false;
    this.text_size = 0;

    this.visible = true;
	this.cfg = false;

	
    this.padding = 20;
    this.padding_height = this.h;

    this.setup_positions = function(x, y)
    {
        this.x = x;
        this.y = y;
    }

    this.render = function()
    {
        if(!this.visible)
            return;

        this.text_size = Render.TextSize(name, menu_font);

        if(this.value)
            Render.FilledRect(this.x, this.y, this.w, this.h, MenuStyles.theme);
        else if(this.hovering)
            Render.FilledRect(this.x, this.y, this.w, this.h, MenuStyles.theme_not_selected);
        else
            Render.FilledRect(this.x, this.y, this.w, this.h, [90,90,90,200]);
        
        Render.Rect(this.x - 1, this.y - 1, this.w + 1, this.h + 1, Colors.black);

        draw_outline_text(this.x + this.w + 3, this.y - 2, 0, name, Colors.white, menu_font);
    }

    this.handle_input = function()
    {
        if(!this.visible || ((menu.focus && menu.focus.is_open) || menu.was_focus_opened)) return;

        var in_bounds = input_system.cursor_in_bounds(this.x, this.y, this.w + this.text_size[0] + 3, this.h)

        if(input_system.is_key_pressed(0x01) && in_bounds)
            this.value = !this.value;
        else if(in_bounds)
            this.hovering = true;
        else
            this.hovering = false;
		
		this.cfg = this.value;
		
    }

    this.set_visibility = function(visibility)
    {
        this.visible = visibility;
    }
}

function ComboBox(tab_name, name, values, deselectable)
{
    this.tab = tab_name;
    this.name = name;
    this.values = values;
	this.selected = null
	this.deselectable = deselectable;

	this.value_selected = "None";

	this.type = "combo"
    this.x = 0;
    this.y = 0;

    this.w = 90;
    this.h = 15;

    this.hovering = false;
	this.hovered_element = null;

    this.text_size = 0;
    this.padding = 35;

    this.visible = true;
	this.is_open = false;

	this.padding_height = this.h * 2;
	this.cfg;

    this.setup_positions = function(x, y)
    {
        this.x = x;
        this.y = y;
    }

    this.render = function()
    {
        if(!this.visible)
            return;

        this.text_size = Render.TextSize(name, menu_font);
		var y = this.y + this.h - this.text_size[1] / 2;
        Render.FilledRect(this.x, y, this.w, this.h, MenuStyles.background);

        Render.Rect(this.x - 1, y - 1, this.w + 1, this.h + 1, Colors.black);

        draw_outline_text(this.x, this.y - this.text_size[1] / 2, 0, name, Colors.white, menu_font);

		if(this.selected == null)
		{
			draw_outline_text(this.x + 2, y + 1, 0, "None", Colors.white, menu_font);
		}
		else 
			draw_outline_text(this.x + 2, y + 1, 0, this.values[this.selected], Colors.white, menu_font);

		if(this.is_open)
		{
			var padding = 0;
			for(var i = 0; i < this.values.length;i++)
			{
				padding += 15;
				Render.FilledRect(this.x, y + padding, this.w, this.h, MenuStyles.background);

				var color;
				if(this.selected == i)
					color = MenuStyles.theme
				else if(this.hovered_element == i) 
					color = MenuStyles.theme_not_selected
				else
					color = Colors.white

				draw_outline_text(this.x + 2, y + padding, 0, String(this.values[i]) , color, menu_font);
			}
			
			Render.Rect(this.x - 1, y + 15 - 1, this.w + 1, padding + 1, Colors.black);
			Render.Rect(this.x - 1, y - 1, this.w + 1, this.h + 1, MenuStyles.theme);
		}
    }

    this.handle_input = function()
    {
        if(!this.visible) return;

        var in_bounds = input_system.cursor_in_bounds(this.x, this.y + this.h - this.text_size[1] / 2, this.w, this.h)

        if(input_system.is_key_pressed(0x01) && in_bounds)
		{
            this.is_open = !this.is_open
			menu.focus = this;
		}

        if(!in_bounds && this.is_open)
		{
			if(input_system.is_key_pressed(0x01))
			{
				this.is_open = false;
				menu.focus = null;
			}

			var padding = 0;

			this.hovered_element = null;

			for(var i = 0; i < this.values.length;i++)
			{
				padding += 15;

				var in_bounds = input_system.cursor_in_bounds(this.x, this.y + this.h + padding - this.text_size[1] / 2, this.w, this.h)

				if(in_bounds && input_system.is_key_pressed(0x01))
				{
					if(this.selected == i && this.deselectable)
						this.selected = null;
					else 
						this.selected = i;

					this.value_selected = this.values[this.selected]
				}
				else if(in_bounds)
				{
					this.hovered_element = i;
				}

			}
		}
		this.cfg = this.selected;

    }

    this.set_visibility = function(visibility)
    {
        this.visible = visibility;
    }
}

function MultiBox(tab_name, name, values)
{
    this.tab = tab_name;
    this.name = name;
    this.values = values;
	this.selected = [];

	//this.value_selected = ["None"];

	this.type = "multi"
    this.x = 0;
    this.y = 0;

    this.w = 90;
    this.h = 15;

    this.hovering = 0;
	this.hovered_element = null;

    this.text_size = 0;
    this.padding = 35;

    this.visible = true;
	this.is_open = false;

	this.padding_height = this.h;

	this.text_start = 0;
	this.text_end = 16;
	this.last_update = 0;
	this.wait = false;
	
	this.cfg = [];
	this.str = "";
    this.setup_positions = function(x, y)
    {
        this.x = x;
        this.y = y;
    }

    this.render = function()
    {
        if(!this.visible)
            return;

        this.text_size = Render.TextSize(name, menu_font);
		var y = this.y + this.h - this.text_size[1] / 2;
        Render.FilledRect(this.x, y, this.w, this.h, MenuStyles.background);

        Render.Rect(this.x - 1, y - 1, this.w + 1, this.h + 1, Colors.black);

        draw_outline_text(this.x, this.y - this.text_size[1] / 2, 0, name, Colors.white, menu_font);

		if(this.selected.length == 0)
		{
			draw_outline_text(this.x + 2, y + 1, 0, "None", Colors.white, menu_font);
		}
		else 
		{		
			var str = String(this.selected).slice(this.text_start,this.text_end);
			if(this.hovering >= 32)
			{
				if(Date.now() - this.last_update > 250)
				{
					this.str = String(this.selected).slice(this.text_start,this.text_end);

					this.text_start += 1;
					this.text_end += 1;
					
					this.last_update = Date.now();

					
					if(this.text_start == 1 && this.text_end == 17)
						this.last_update = Date.now() + 1200;
				}
				if(this.text_end > String(this.selected).length)
				{
					this.text_start = 0;
					this.text_end = 16;
					this.last_update = Date.now() + 1200;
				}
				draw_outline_text(this.x + 2, y + 1, 0, this.str, Colors.white, menu_font);
			}
			else 
			{
				this.text_start = 0;
				this.text_end = 16;
				draw_outline_text(this.x + 2,y + 1, 0, str, Colors.white, menu_font);
			}

			
		}
		if(this.is_open)
		{
			var padding = 0;
			for(var i = 0; i < this.values.length;i++)
			{
				padding += 15;
				Render.FilledRect(this.x, y + padding, this.w, this.h, MenuStyles.background);

				var color;
				if(contains(this.selected,this.values[i]))
					color = MenuStyles.theme
				else if(this.hovered_element == i) 
					color = MenuStyles.theme_not_selected
				else
					color = Colors.white

				draw_outline_text(this.x + 2, y + padding, 0, String(this.values[i]) , color, menu_font);
			}
			
			Render.Rect(this.x - 1, y + 15 - 1, this.w + 1, padding + 1, Colors.black);
			Render.Rect(this.x - 1, y - 1, this.w + 1, this.h + 1, MenuStyles.theme);
		}
    }

    this.handle_input = function()
    {
        if(!this.visible) return;

        var in_bounds = input_system.cursor_in_bounds(this.x, this.y + this.h - this.text_size[1] / 2, this.w, this.h)

        if(input_system.is_key_pressed(0x01) && in_bounds)
		{
            this.is_open = !this.is_open
			menu.focus = this;
		}

		if(in_bounds && !this.open)
			this.hovering += 1
		else 
			this.hovering = 0;
			
        if(!in_bounds && this.is_open)
		{
			if(input_system.is_key_pressed(0x01))
			{
				this.is_open = false;
				menu.focus = null;
			}

			var padding = 0;

			this.hovered_element = null;

			for(var i = 0; i < this.values.length;i++)
			{
				padding += 15;

				var in_bounds = input_system.cursor_in_bounds(this.x, this.y + this.h + padding - this.text_size[1] / 2, this.w, this.h)

				if(in_bounds && input_system.is_key_pressed(0x01))
				{
					var valid = true;
					for(var t = 0; t < this.selected.length && valid;t++)
					{
						if(this.selected[t] == this.values[i])
						{
							this.selected.splice(t, 1);
							valid = false;
						}
					}
					if(valid)
						this.selected.push(this.values[i]);

					this.is_open = true;
					menu.focus = this;
				}
				else if(in_bounds)
				{
					this.hovered_element = i;
				}
				this.cfg = this.selected;
			}
		}
		this.cfg = this.selected;
	

    }

    this.set_visibility = function(visibility)
    {
        this.visible = visibility;
    }
}

function Slider(tab_name, name, min_val, max_val, sign)
{
    this.tab = tab_name;
    this.name = name;

    this.min_val = min_val;
    this.max_val = max_val;

    this.value = min_val;

    this.x = 0;
    this.y = 0;

    this.w = 90;
    this.h = 10;

	this.sign = sign;

	this.type = "slider"
    this.slider_x = this.x;

    this.hovering = false;
    this.text_size = 0;
    this.padding = 30;

	this.padding_height = this.h * 1.8;

    this.visible = true;
    this.dragging = false;
	this.cfg = min_val;
	this.text = String(this.value);

    this.setup_positions = function(x, y)
    {
        this.slider_x -= this.x - x;
        this.x = x;
        this.y = y;
        
    }

    this.render = function()
    {
        if(!this.visible)
            return;

        this.clamp_slider();
		
		this.text = String(this.value) + sign;
        this.text_size = Render.TextSize(name, menu_font);
        number_size = Render.TextSize(this.text, menu_font)

		var y = this.y + this.h;

        Render.FilledRect(this.x, y, this.w, this.h, MenuStyles.background);
		
        Render.FilledRect(this.x, y, this.slider_x - this.x, this.h, MenuStyles.theme)
        Render.Rect(this.x - 1, y - 1, this.w + 1, this.h + 1, Colors.black);

        Render.FilledRect(this.slider_x, y, 5, 10, Colors.white);
		
		var border = this.x + this.w;
		if(this.slider_x + 5 > this.x + this.w)
			border = this.slider_x + 5;

        draw_outline_text(this.x, this.y - this.text_size[1] / 2, 0, name, Colors.white, menu_font);
    
        draw_outline_text(border + 2, y - 2, 0, this.text, Colors.white, menu_font);
    }

    this.clamp_slider = function()
    {
        if(this.slider_x < this.x)
            this.slider_x = this.x;
        else if(this.slider_x > this.x + this.w)
            this.slider_x = this.x + this.w;
    }

    this.handle_input = function()
    {
        if(!this.visible || ((menu.focus && menu.focus.is_open) || menu.was_focus_opened)) return;

        var in_bounds = input_system.cursor_in_bounds(this.x, this.y + this.text_size[1], this.w, this.h)

		if(this.value != 0 && this.slider_x == this.x)
		{	
		
			this.slider_x = (this.value - this.min_val) / (this.max_val - this.min_val) * this.w + this.x
		}

        if ( !input_system.is_key_down( 0x01 ) )
		{
			this.dragging = false;
            cursor.dragging_sliders = false;
			cursor.dragging = false;
		}

        if((input_system.is_key_pressed( 0x01 ) && in_bounds))
        {
            cursor.dragging_sliders = true;
            this.dragging = true;
			cursor.dragging = true;
        }

		if (this.dragging) {
			// update dragging state
            if(cursor.dragging_sliders && !this.dragging)
                return;

			this.slider_x = cursor.x;
            this.clamp_slider();

            this.value = (this.min_val + ( (this.slider_x - this.x) / this.w ) * (this.max_val - this.min_val)).toFixed(0);
			this.cfg = this.value;
		}
    }
    this.set_visibility = function(visibility)
    {
        this.visible = visibility;
    }
}

function Keybind(tab_name, name, default_key, allow_modes)
{
    this.tab = tab_name;
    this.name = name;

    this.key = default_key;
	this.allow_modes = allow_modes;

    this.x = 0;
    this.y = 0;

    this.w = 10;
    this.h = 10;

	this.type = "keybind"
    this.hovering = false;
	this.wait_for_key = false;

    this.text_size = 0;
    this.padding = 0;
    this.visible = true;

	this.cfg = default_key;
	this.padding_height = this.h;
    this.setup_positions = function(x, y)
    {
        this.x = x;
        this.y = y;
    }

    this.render = function()
    {
        if(!this.visible)
            return;

        this.text_size = Render.TextSize(name, menu_font);

        draw_outline_text(this.x, this.y - 2, 0, name, Colors.white, menu_font);

		if(this.wait_for_key)
		{
			var start_size = Render.TextSize("[ ", menu_font)
			var dot_size = Render.TextSize("...", menu_font)
			
			draw_outline_text(this.x + this.text_size[0] + 5, this.y - 2, 0, "[ ", Colors.white, menu_font);
			draw_outline_text(this.x + this.text_size[0] + 5 + start_size[0], this.y - 2, 0, "...", MenuStyles.theme, menu_font);
			draw_outline_text(this.x + this.text_size[0] + 5 + start_size[0] + dot_size[0], this.y - 2, 0, " ]", Colors.white, menu_font);
		}
		else 
		{
			if(this.key == null)
			{
				draw_outline_text(this.x + this.text_size[0] + 5, this.y - 2, 0, "[ - ]", Colors.white, menu_font);
			}
			else 
				draw_outline_text(this.x + this.text_size[0] + 5, this.y - 2, 0, "[ " + String(key_names[this.key]) + " ]", Colors.white, menu_font);
		}
		
    }

    this.handle_input = function()
    {
        if(!this.visible || ((menu.focus && menu.focus.is_open) || menu.was_focus_opened)) return;

		var text_size = Render.TextSize("[ ]", menu_font);
		if(this.key != null)
			text_size = Render.TextSize("[ " + String(key_names[this.key]) + " ]", menu_font);

        var in_bounds = input_system.cursor_in_bounds(this.x + this.text_size[0] + 5, this.y, text_size[0], this.h)
		
		if(this.wait_for_key)
		{
			if(input_system.is_key_pressed(0x27)) // aka esc
			{
				this.key = null;
				this.wait_for_key = false 
				return;
			}
			for(var i = 0; i < 255; i++)
			{
				if(input_system.is_key_pressed(i))
				{
					this.key = i;
					this.cfg = i;
					this.wait_for_key = false 
					break;
				}
			}
			return;	
		}

        if(input_system.is_key_pressed(0x01) && in_bounds)
            this.wait_for_key = true;
        else if(in_bounds)
            this.hovering = true;
        else
            this.hovering = false;

    }

    this.set_visibility = function(visibility)
    {
        this.visible = visibility;
    }
}


//#region Menu
var menu = new Menu(300,300,500, 400);

menu.add_tab(62, 170, "Ragebot");
menu.add_tab(62, 190, "Anti-Aim");
menu.add_tab(62, 210, "Playerlist");
menu.add_tab(62, 230, "Visuals");
menu.add_tab(62, 250, "Misc");

var improved_target_selection = menu.add_checkbox("Ragebot", "Improved target selection");
var dt_improvements = menu.add_combobox("Ragebot" , "DT Improvements" , ["Faster DT", "Better Recharge"], true)
var dt_recharge_delay = menu.add_slider("Ragebot" , "DT Recharge Delay" , 0, 20, " ticks");

var enable_aa = menu.add_checkbox("Anti-Aim", "Anti-Aim");
var aa_type = menu.add_combobox("Anti-Aim" , "Anti-Aim Type" , ["Eye yaw" , "Opposite", "Sway"], false, false)
var aa_dir = menu.add_combobox("Anti-Aim" , "Auto Direction Mode" , ["Freestand", "Reversed"], false, false)
var anti_bruteforce = menu.add_checkbox("Anti-Aim", "Anti-Bruteforce");
var aa_reset_chk = menu.add_checkbox("Anti-Aim", "Reset Anti-Aim");
var aa_reset_slider = menu.add_slider("Anti-Aim" , "Anti-Aim reset time" , 0, 10, "s");
var evasion = menu.add_checkbox("Anti-Aim", "Evasion");
var evasion_slider = menu.add_slider("Anti-Aim" , "Chance to block hit" , 40, 100, "%")
var aa_jitter = menu.add_combobox("Anti-Aim", "Jitter", ["Synced", "Full"], true)

var show_watermark = menu.add_checkbox("Visuals", "Watermark");
var show_spectator_list = menu.add_checkbox("Visuals", "Spectator List");
var show_keybinds = menu.add_checkbox("Visuals", "Show Keybinds");
var show_indicators = menu.add_checkbox("Visuals", "Show Indicators");

var menu_keybind = menu.add_keybind("Misc", "Menu hotkey", 0x24 , false); // 0x24 == home

aa_reset_chk.set_visibility(false);
aa_reset_slider.set_visibility(false);
evasion_slider.set_visibility(false);
dt_recharge_delay.set_visibility(false);


//#endregion
var menu_was_opened = false;

function render_menu()
{
	input_system.update_input();
	input_system.enable_mouse_input(menu.is_open);

    font = Render.GetFont("Arialbd.ttf", 20, true);
    menu_font = Render.GetFont("Arialbd.ttf", 10, true);
    tab_selected = Render.GetFont("Arialbd.ttf", 22, true);
    logo_font = Render.GetFont("Arialbd.ttf", 25, true);
	//Cheat.Print(menu_keybind.key)
    if((input_system.is_key_pressed( menu_keybind.key )) || (input_system.is_key_pressed( 0x24 ) && key_names[menu_keybind.key] == "-")) 
        menu.is_open = !menu.is_open;

    if(menu.is_open)
    {
        menu.drag();
        menu.render();
        menu.handle_children();
		menu_was_opened = true;
    }

	aa_reset_chk.set_visibility(anti_bruteforce.value);
	aa_reset_slider.set_visibility(aa_reset_chk.value && anti_bruteforce.value);
	evasion_slider.set_visibility(evasion.value);
	dt_recharge_delay.set_visibility(contains(dt_improvements.selected,"Better Recharge"));

	draggable_font = Render.GetFont("Arialbd.ttf", 10, true);
	arrows_font = Render.GetFont("Verdana.ttf", 20, true);

	if(show_watermark.value)
	{
		UI.SetValue(["Misc.", "Helpers", "General", "Watermark"], 0);
		watermark.render();
	}

	if(show_spectator_list.value)
	{
		UI.SetValue(["Misc.", "Helpers", "General", "Show spectators"], 0);
		spectator_list.render();
	}

	if(show_keybinds.value)
	{
		UI.SetValue(["Misc.", "Helpers", "General", "Show keybind states"], 0);
		keybinds.render();
	}

}

fix_input = function()
{
	input_system.fix_input();
}

var screen_size = Render.GetScreenSize();

const watermark = new DraggableUI(screen_size[0] - 2, 4, 240, 15, render_watermark);
const spectator_list = new DraggableUI(5, 500, 120, 15, render_spectator_list);
const keybinds = new DraggableUI(5, 400, 120, 15, render_keybinds);

const FREESTAND = 1;
const OPPOSITE = -1;

const STARTING_DESYNC = 60;
var STARTING_AUTO_DIRECTION = FREESTAND
const STARTING_SIDE = 1;

function AAState(auto_direction, side, desync)
{
	this.auto_direction = auto_direction;
	this.side = side;
	this.desync = desync;
}

function ShotData(auto_direction, side, desync, max_desync, tickcount, hit, hitgroup) // the hitbox it hit or null and hit = true or false 
{
	this.auto_direction = auto_direction;
	this.side = side;
	this.desync = desync;
	 
	this.max_desync = max_desync;
	this.hitgroup = hitgroup;
	this.hit = hit;
	this.tickcount = tickcount;

	this.is_main_target = false;

	this.cur_antiaim = 
	{
		auto_direction : null,
		side : null,
		desync : null
	}

}

function Player(ent_index)
{
	this.ent_index = ent_index;
	this.desync = STARTING_DESYNC;
	this.side = 1; // 1 or -1
	this.auto_direction = STARTING_AUTO_DIRECTION; // 1 or -1

	this.miss_logs = []; // desync : amount / ? 
						// side : 1 / -1
						// max_desync : get_max_desync()

	this.hit_logs = []; // same as miss_logs
	this.shot_logs = [];

	this.missed_us = 0; // times he missed us
	this.last_shot_time = 0;
	this.onshot_counter = 0;
	this.headshot_counter = 0;

	this.legit_aa_auto_direction = FREESTAND;
	this.legit_aa_desync = 60;
	this.legit_aa_side = 1;
	this.legit_aa_misses = 0;

	this.old_aa_states = [new AAState(STARTING_AUTO_DIRECTION, STARTING_SIDE, STARTING_DESYNC)]; 
	this.round_start_state = new AAState(STARTING_AUTO_DIRECTION, STARTING_SIDE, STARTING_DESYNC);

	this.evasion_timer = null;
	this.last_bullet_impact = null;
	this.last_shot_at_us = null;

	this.hits = 0; // amount of times we hit him
	this.misses = 0; // ammount of times we missed him
	// Playerlist data section
	this.detected_cheat = "onetap"; // assume onetap as it has the most amount of users

	// not used for now since we don't have playerlist and aa works great
	// this.resolver_stages = { // this would be how the resolvers work for each cheat used for auto detection
	// 	"skeet" : [ [60, FREESTAND], [60, OPPOSITE] , [30, FREESTAND] , [30, OPPOSITE] ], // i have no clue how they actually do it but i'm assumming the stages based on full misses
	// 	"onetap" : [ [60, OPPOSITE] , [30, FREESTAND] , [60, FREESTAND] , [30, OPPOSITE] ] // i have no clue how they actually do it but i'm assumming the stages based on full misses
	// 	// i think after 4 misses most cheats go for anti bruteforce i'm like 100% sure they start shooting same angles 
	// };


	this.whitelisted = false;
	this.priority_target = false;

	this.hitboxes = [];
	this.multipoints = [];
	this.static_pointscale = false;
	this.head_pointscale = 0;
	this.body_pointscale = 0;
	this.aa_type = "None"

}

player_list = [];

for(var i = 0; i <= 65;i++)
	player_list.push(new Player(i));

const Hitboxes = { 
	head : 0,
	neck : 1,
	pelvis : 2,
	body : 3,
	thorax : 4,
	chest : 5, 
	upper_chest : 6, 
	left_thigh : 7,
	right_thigh : 8, 
	left_calf : 9,
	right_calf : 10,
	left_foot : 11, 
	right_foot : 12,
	left_hand : 13,
	right_hand : 14,
	left_arm : 15,
	right_arm : 17,
	max : 18
};

const Hitgroups = { 
	generic : 0,
	head : 1,
	chest : 2,
	stomach : 3,
	left_arm: 4,
	right_arm : 5, 
	left_leg : 6, 
	right_leg : 7,
	gear : 10, 
};
var hitgroup_names = ["body", "head", "chest", "stomach", "left arm", "right arm", "left leg", "right leg", "neck", "?", "gear" ]
Globals.TicksToTime = function(tick)
{
	return Globals.TickInterval() * tick;
}

Globals.TimeToTicks = function(tick)
{
	return Math.floor(0.5 + tick / Globals.TickInterval());
}

Entity.GetEntitiesByClassName = function(class_name) 
{
    const entities = Entity.GetEntities()
    var list = []
    for(i in entities) {
        var classid = Entity.GetClassName(entities[i])
        if(classid == class_name)
            list.push(entities[i])
    }
    return list
}

Entity.IsInAir = function(ent)
{
	return Entity.GetProp( ent, "CBasePlayer", "m_hGroundEntity");
}

Entity.GetMaxDesync = function(player) // not 100% accurate but it's not bad and it's the best i've got
{
    var velocity = Entity.GetProp( player, "CBasePlayer", "m_vecVelocity[0]" );
	var xv = velocity[0];
    var yv = velocity[1];

	var x_desync = Math.floor((1 - (Math.abs(xv) / 230)) * 29 + 29)
	var y_desync = Math.floor((1 - (Math.abs(yv) / 230)) * 29 + 29)
	var diag_desync = Math.floor(((1 - ((Math.abs(xv) + Math.abs(yv)) / 324)) * 28) + 29)

    var desync = Math.min(Math.min(x_desync,y_desync),diag_desync)
    
    if (desync >= 55)
        desync = 58

	desync = Math.max(29,Math.min(desync , 58))

	if(player == Entity.GetLocalPlayer())
	{
		var real_yaw = Local.GetRealYaw();
        var fake_yaw = Local.GetFakeYaw();

        var angle = Math.min(58,Math.abs(real_yaw - fake_yaw).toFixed(0));

		if(angle > desync)
			desync = angle;
	}
	return desync;
}

Entity.IsVisibleFrom = function(ent, from_pos) // if ent is visibile from pos
{	
	var pos , result;

	const local = Entity.GetLocalPlayer();
	const local_eye = from_pos;

	for(var hitbox = 0; hitbox < Hitboxes.max;hitbox++)
	{
		pos = Entity.GetHitboxPosition(ent, hitbox);
		result = Trace.Line(local, local_eye, pos);

		if(result[0] == ent)
			return true;
	}

	return false;
}

Entity.IsVisible = function(ent)
{	
	const local = Entity.GetLocalPlayer();
	const local_eye = Entity.GetEyePosition(local);

	return Entity.IsVisibleFrom(ent, local_eye);
}

// Vector and maths

const Vector = { };

Math.randomize = function(min, max) 
{
    min = Math.ceil(min);
    max = Math.floor(max) + 1;
    return Math.floor(Math.random() * (max - min)) + min;
}

Math.radian = function(degree) // degree to rad
{
    return degree * Math.PI / 180.0;
}

Math.clamp = function(arr, min, max) // clamps a whole array
{
    for(var i = 0; i < arr.length;i++)
    {
        if(arr[i] > max)
            arr[i] = max;
        if(arr[i] < min)
            arr[i] = min;
    }
    return arr;
}

Math.deg = function(rad)
{
  return rad * 180 / Math.PI;
}

Math.extrapolate = function(pos, velocity, ticks)
{
	return Vector.add(pos , Vector.multiply(velocity, ticks * Globals.TickInterval()));
}

Vector.extend = function(vector, angle, extension)
{
    const radian_angle = Math.radian(angle);
    return [extension * Math.cos(radian_angle) + vector[0], extension * Math.sin(radian_angle) + vector[1], vector[2]];
}

Vector.to_angle = function(a)
{
	var fwd = [];

	var yaw = [] , pitch = [];

	yaw[0] = Math.sin(Math.radian(a[1]));
	yaw[1] = Math.cos(Math.radian(a[1]));

	pitch[0] = Math.sin(Math.radian(a[0]));
	pitch[1] = Math.cos(Math.radian(a[0]));

	fwd[0] = yaw[1] * pitch[1];
	fwd[1] = pitch[1] * yaw[0];
	fwd[2] = -pitch[0];

	return fwd;
}

Vector.angle_to = function(source , destination)
{
	const delta_vector = [destination[0] - source[0], destination[1] - source[1], destination[2] - source[2]]
	const hyp = Math.sqrt(delta_vector[0] * delta_vector[0] + delta_vector[1] * delta_vector[1])

	const yaw = Math.deg(Math.atan2(delta_vector[1], delta_vector[0]))
	const pitch = Math.deg(Math.atan2(-delta_vector[2], hyp))

	return [pitch, yaw]
}

Vector.add = function(a, b)
{
    return [a[0] + b[0], a[1] + b[1], a[2] + b[2]];
}

Vector.sub = function(a, b)
{
    return [a[0] - b[0], a[1] - b[1], a[2] - b[2]];
}

Vector.multiply_vec = function(a, b)
{
    return [a[0] * b[0], a[1] * b[1], a[2] * b[2]];
}

Vector.multiply = function(a, b)
{
    return [a[0] * b, a[1] * b, a[2] * b]
}

Vector.div_vec = function(a, b)
{
    return [a[0] / b[0], a[1] / b[1], a[2] / b[2]];
}

Vector.div = function(a, b)
{
    return [a[0] / b, a[1] / b, a[2] / b]
}

Vector.length3D = function(a)
{
    return Math.sqrt(a[0] * a[0] + a[1] * a[1] + a[2] * a[2]);
}

Vector.length2D = function(a)
{
    return Math.sqrt(a[0] * a[0] + a[1] * a[1]);
}

Vector.normalize = function(vec)
{
    var length = Vector.length3D(vec);
    return Vector.div(vec, length);
}

Vector.dot = function(a, b)
{
    return a[0] * b[0] + a[1] * b[1] + a[2] * b[2];
}

Vector.distance = function(a, b)
{
    return Vector.length3D(Vector.sub(a, b));
}

Vector.distance2D = function(a, b)
{
    return Vector.length2D(Vector.sub(a, b));
}

Vector.closest_point_to_ray = function(target, ray_start, ray_end)
{
    var to = Vector.sub(target, ray_start);
    var dir = Vector.sub(ray_end, ray_start);
    var length = Vector.length3D(dir);
	
    dir = Vector.normalize(dir);

    var range_along = Vector.dot(dir, to);

    if (range_along < 0.0)
    {
        return ray_start;
    }
    else if(range_along > length)
    {
        return ray_end;
    }
	//Cheat.Print(String(dir) + "\n" )
    return Vector.add(ray_start, Vector.multiply(dir, range_along));
}

const antiaim = {
	auto_direction: null,
	side : null,
	desync : null,
	enemy : null,
	last_enemy : null,
	last_local_shot : null,
	last_bullet_impact : null,
	legit_aa_timer : 0,
	legit_aa : false
};

antiaim.set_aa = function(fake)
{
	opposite = aa_type.values[aa_type.selected] == "Opposite"

    AntiAim.SetFakeOffset(0);
    AntiAim.SetRealOffset(-fake);
	if(opposite)
		AntiAim.SetLBYOffset(fake);
	else 
    	AntiAim.SetLBYOffset(0);
}

antiaim.set_auto_direction = function()
{
	if(aa_dir.values[aa_dir.selected] == "Reversed")
		STARTING_AUTO_DIRECTION = OPPOSITE
	else
		STARTING_AUTO_DIRECTION = FREESTAND
}

antiaim.run_auto_direction = function(enemy)
{
	const local = Entity.GetLocalPlayer();

	const local_eye = Entity.GetEyePosition(local);
    const angle_to_enemy = Vector.angle_to(local_eye , Entity.GetEyePosition(enemy));
  

	var fraction_left = 0;
    var fraction_right = 0;
	var amount_left = 0;
    var amount_right = 0;

	for (var i = -60; i <= 60; i+= 1)
	{
		if (i != 0)
		{
			var fwd = Vector.to_angle([0, angle_to_enemy[1] + i, 0]);
			fwd = Vector.multiply(fwd, 50000)

			const trace = Trace.Line(local, local_eye, Vector.add(local_eye, fwd));
			const fraction = trace[1]

			if (i > 0)
			{
				fraction_left = fraction_left + fraction
				amount_left = amount_left + 1
			}
			else
			{
				fraction_right = fraction_right + fraction
				amount_right = amount_right + 1
			}
		}
	}

	const average_left = fraction_left / amount_left;
    const average_right = fraction_right / amount_right;

    var auto_direction = -1;

	if (average_left < average_right)
		auto_direction = 1;

    return auto_direction * player_list[enemy].auto_direction;
}

antiaim.get_enemies_by_crosshair = function()
{
	var enemies = Entity.GetEnemies();
	var enemy, enemy_pos, dist;
	var enemies_list = {};
	
	var view_angles = Local.GetViewAngles();

	for(var i = 0; i < enemies.length ;i++)
	{
		enemy = enemies[i];

		if(!enemy || !Entity.IsAlive(enemy) || Entity.IsDormant(enemy)) continue;

		enemy_pos = Entity.GetHitboxPosition(enemy,3);
		
		dist = Vector.angle_to(Entity.GetEyePosition(Entity.GetLocalPlayer()), enemy_pos)
		enemies_list[enemy] = Vector.distance2D(dist,view_angles);
	}

	var enemy_pairs = Object.keys(enemies_list).map(function(key) { return [key, enemies_list[key]]; } );
	enemy_pairs.sort(function(first, second) { return first[1] - second[1]; } );
	
	
	var enemies = [];
	for(var i = 0; i < enemy_pairs.length;i++)
		enemies[i] = parseInt(enemy_pairs[i][0]);
	
	return enemies;
}

antiaim.set_legit_aa_state = function(state)
{
	if(state)
	{
		UI.SetValue(["Rage", "Anti Aim", "Directions", "At targets"],0)
		UI.SetValue(["Config","Cheat","General","Restrictions"],0);
		UI.SetValue(["Rage","Anti Aim","General","Pitch mode"],0);
		UI.SetValue(["Rage","Anti Aim","Directions","Yaw offset"],180);
	}
	else 
	{
		UI.SetValue(["Rage", "Anti Aim", "Directions", "At targets"],1)
		UI.SetValue(["Config","Cheat","General","Restrictions"],1);
		UI.SetValue(["Rage","Anti Aim","General","Pitch mode"],1);
		UI.SetValue(["Rage","Anti Aim","Directions","Yaw offset"],0);
	}
}

antiaim.run_legit_aa = function()
{
	var buttons = UserCMD.GetButtons();
	var local = Entity.GetLocalPlayer();

	var hostages = Entity.GetEntitiesByClassName("CHostage");
	var hostage_found = false;

	for(var i = 0 ; i < hostages.length;i++)
	{
		if(Vector.distance(Entity.GetRenderOrigin(hostages[i]) , Entity.GetRenderOrigin(local)) < 100)
			hostage_found = true;
	}

	if(buttons & (1 << 5) && !hostage_found)
	{
		antiaim.set_legit_aa_state(true)

		if(antiaim.legit_aa_timer >= 5) // if hold E for more than 5 ticks then use AA this is made so you can still defuse
		{
			
			UserCMD.SetButtons((buttons & ~(1 << 5))) // use = false 
			
			if(antiaim.enemy && Entity.IsAlive(antiaim.enemy))
			{
				antiaim.set_aa(player_list[antiaim.enemy].legit_aa_desync * player_list[antiaim.enemy].legit_aa_side);
			}

			antiaim.legit_aa = true;

		}
		antiaim.legit_aa_timer++;
	}
	else
	{
		antiaim.legit_aa_timer = 0; // reset tick timer
		antiaim.legit_aa = false;

		antiaim.set_legit_aa_state(false)
	}
}

antiaim.is_vulnerable = function()
{
	const enemies = Entity.GetEnemies();
	const local = Entity.GetLocalPlayer();
	const local_pos = Entity.GetHitboxPosition(local, 0);

	if(!local || !Entity.IsAlive(local)) return false;

	if(Ragebot.GetTarget() != 0) return true;

	for(var i = 0; i < enemies.length;i++)
	{
		const enemy = enemies[i];

		if(!Entity.IsValid(enemy) && !Entity.IsAlive(enemy) && Entity.IsDormant(enemy)) continue;

		const enemy_pos = Entity.GetEyePosition(enemy);

		const bullet_data = Trace.Bullet(enemy, local, enemy_pos, local_pos)

		if(bullet_data && bullet_data[1] > 15)
		{
			return true;
		}
	}

	return false;
}
var last_side = 1;
var last_invert = 0;
antiaim.run_antiaim = function()
{
	if(enable_aa.value)
		AntiAim.SetOverride(1);
	else 
	{
		return AntiAim.SetOverride(0);
	}
		
	const local = Entity.GetLocalPlayer();

	if(!local || !Entity.IsAlive(local)) return;

	var enemies = antiaim.get_enemies_by_crosshair() // this returns alive enemies by crosshair
	var found_enemy = false;
	
	for(var i = 0; i < enemies.length;i++)
	{
		var enemy = enemies[i];
		if(player_list[enemy].onshot_counter >= 2)
			Entity.DrawFlag(enemy, "ONSHOTTER", [255,255,255,255])
	}

	antiaim.set_auto_direction(); // this updates auto direction based on the value you have in the combobox

	for(var i = 0; i < enemies.length && !found_enemy;i++)
	{
		var enemy = enemies[i];
		if(enemy && Entity.IsAlive(enemy) && !Entity.IsDormant(enemy))
		{
			antiaim.enemy = enemy;
			antiaim.last_enemy = enemy;
			found_enemy = true;
		}
	}
	
	if(!found_enemy)
	{
		antiaim.enemy = null 
		return;
	}

	if(found_enemy && antiaim.enemy && Entity.IsAlive(antiaim.enemy) && !Entity.IsDormant(antiaim.enemy))
	{	
		Entity.DrawFlag(antiaim.enemy, "AA", [255,255,255,255])

		if(!Entity.IsVisible(antiaim.enemy))
		{
			player_list[antiaim.enemy].side = antiaim.run_auto_direction(antiaim.enemy);
			var enemy_data = player_list[antiaim.enemy];

			player_list[antiaim.enemy].legit_aa_side = enemy_data.side * player_list[antiaim.enemy].auto_direction * player_list[antiaim.enemy].legit_aa_auto_direction * -1 // we multiply by auto_direction to nullify when we multiplied by it in freestand

			if(antiaim.legit_aa)
			{
				antiaim.side = player_list[antiaim.enemy].legit_aa_side
				antiaim.desync = player_list[antiaim.enemy].legit_aa_desync
			}
			else 
			{
				antiaim.side = enemy_data.side;
				antiaim.desync = enemy_data.desync;
			}
			
			antiaim.set_aa(antiaim.side * antiaim.desync);
		}
		else 
		{
			var enemy_data = player_list[antiaim.enemy];

			antiaim.side = enemy_data.side;
			antiaim.desync = enemy_data.desync;
			
			antiaim.set_aa(antiaim.side * antiaim.desync)
		}

		antiaim.auto_direction = enemy_data.auto_direction;


		if(Globals.Tickcount() - enemy_data.last_shot_at_us >= 64 * aa_reset_slider.value) // dodge timer passed
		{
			if(contains(aa_jitter.selected,"Full") && antiaim.is_vulnerable())
			{
				antiaim.desync = 60;
				if(Globals.Tickcount() - last_invert > 3)
				{
					last_side = -last_side;
					last_invert = Globals.Tickcount();
				}
				antiaim.set_aa(last_side * antiaim.desync);
			//	Cheat.Print(String(last_side * antiaim.desync) + "\n")
				
			}
			else if(contains(aa_jitter.selected,"Synced"))
			{
				antiaim.desync = 60;
				if(Globals.Tickcount() - last_invert > 3)
				{
					if(antiaim.side == -1)
						antiaim.desync = antiaim.desync - 45;
					else
						antiaim.desync = antiaim.desync - 30;
					last_invert = Globals.Tickcount();
				}
				antiaim.set_aa(antiaim.side * antiaim.desync);
				// Cheat.Print("Synced\n")
			}
		}
		
		
	}

}

antiaim.on_player_hurt = function()
{
	if(!anti_bruteforce.value) return;
	
 	const attacker = Entity.GetEntityFromUserID(Event.GetInt("attacker"));
	const victim = Entity.GetEntityFromUserID(Event.GetInt("userid"));

	const dmg = Event.GetInt("dmg_health");
	const remaining_health = Event.GetInt("health");

    if (victim != Entity.GetLocalPlayer() || victim == attacker) return;

    const hitgroup = Event.GetInt('hitgroup');
	var enemy_data = player_list[attacker];

	const last_state = enemy_data.old_aa_states.length - 1;
	const last_shot = enemy_data.shot_logs.length - 1;

	const last_aa_state = enemy_data.old_aa_states[last_state];
	const local = victim;

	if(Globals.Tickcount() - antiaim.last_local_shot <= 15 && hitgroup == Hitgroups.head) // aka last time local shot
	{
		player_list[attacker].onshot_counter += 1;
		Cheat.PrintColor([230, 104, 44, 255], "[phoenix] ");
		Cheat.Print(Entity.GetName(attacker) + " onshotted us! \n")
		return; // we got onshotted hurray.. we don't care about other shit 
	}

	var found_shot = false;

	for(var i = 0; i < player_list[attacker].shot_logs.length && !found_shot;i++)
	{
		var shot = player_list[attacker].shot_logs[i];
		if(Globals.Tickcount() - shot.tickcount < 2 && !shot.hit)
		{
			player_list[attacker].shot_logs[i].hitgroup = hitgroup;
			player_list[attacker].shot_logs[i].hit = true;
			found_shot = true;
			
			player_list[attacker].desync = shot.cur_antiaim.desync;
			player_list[attacker].side = shot.cur_antiaim.side;
			player_list[attacker].auto_direction = shot.cur_antiaim.auto_direction;
			//Cheat.Print("Got this far\n");
			break;
		}
	}

	if(!found_shot)
	{
		var shot = new ShotData(enemy_data.auto_direction, enemy_data.side, enemy_data.desync, Entity.GetMaxDesync(local), Globals.Tickcount(), true, hitgroup);

		shot.cur_antiaim.auto_direction = antiaim.auto_direction
		shot.cur_antiaim.side = antiaim.side
		shot.cur_antiaim.desync = antiaim.desync
	
		shot.is_main_target = enemy_data.ent_index == antiaim.enemy;

		player_list[attacker].shot_logs.push(shot);
	}

	if(hitgroup != Hitgroups.generic)
	{
		Cheat.PrintColor([230, 104, 44, 255], "[phoenix] ");
		Cheat.Print(Entity.GetName(attacker) + " shot our " + hitgroup_names[hitgroup] + " | SIDE: " + antiaim.side + " | DESYNC: " + antiaim.desync + " | AUTO-DIRECTION: " + (antiaim.auto_direction == FREESTAND ? "FREESTAND" : "OPPOSITE") + "\n")
	}
	
    if (hitgroup == Hitgroups.head || hitgroup == Hitgroups.left_leg || hitgroup == Hitgroups.right_leg)  //head, both toe
    {
		//Cheat.Print("Works\n");
		if(hitgroup == Hitgroups.head)
			player_list[attacker].headshot_counter += 1;

        player_list[attacker].auto_direction = -player_list[attacker].auto_direction;
		player_list[attacker].side = -player_list[attacker].side;

	//	player_list[attacker].round_start_state = new AAState(player_list[attacker].auto_direction, player_list[attacker].side, player_list[attacker].desync)
    }
    else if(hitgroup != Hitgroups.generic)
    {
		// Cheat.Print("Works2\n");
		if(evasion.value && dmg > (remaining_health + dmg) * evasion_slider.value / 100) // if evasion checkbox run the shit
		{
			player_list[attacker].desync = 60;
			player_list[attacker].auto_direction = -player_list[attacker].auto_direction;
			player_list[attacker].side = -player_list[attacker].side;

			player_list[attacker].evasion_timer = Globals.Tickcount() + 64 * 10; // evasion for 10s for indicator
			//Cheat.Print("evasion\n")
		}
		//Cheat.Print(String(dmg) + "\n")
		//Cheat.Print(String((remaining_health + dmg) * evasion_slider.value / 100) + "\n")
    }

}

antiaim.on_bullet_impact = function()
{
	if(!anti_bruteforce.value) return;

    const tickcount = Globals.Tickcount();

    const enemy = Entity.GetEntityFromUserID(Event.GetInt("userid"));

	if(enemy == Entity.GetLocalPlayer())
		antiaim.last_local_shot = tickcount;

    if (tickcount - player_list[enemy].last_shot_at_us < 6) return; // aka we inverted less than 6 ticks ago so dont do it again 

    const impact = [Event.GetFloat("x"), Event.GetFloat("y"), Event.GetFloat("z")];

	const local = Entity.GetLocalPlayer();

    if (Entity.IsValid(enemy) && Entity.IsEnemy(enemy) && local && Entity.IsAlive(local))
    {
        const source = Entity.GetEyePosition(enemy);


		const head_pos = Entity.GetHitboxPosition(local, 0)
		const head_vec = Vector.closest_point_to_ray(head_pos, source, impact);
		const head_dist = Vector.distance(head_pos, head_vec);
        if (head_dist < 50.0)  // shot near us
        {
			var enemy_data = player_list[enemy];

			var shot = new ShotData(enemy_data.auto_direction, enemy_data.side, enemy_data.desync, Entity.GetMaxDesync(local), Globals.Tickcount(), false, -1);

			shot.cur_antiaim.auto_direction = antiaim.auto_direction
			shot.cur_antiaim.side = antiaim.side
			shot.cur_antiaim.desync = antiaim.desync
			
			shot.is_main_target = enemy_data.ent_index == antiaim.enemy;

			player_list[enemy].shot_logs.push(shot);

            player_list[enemy].old_aa_states.push(new AAState(enemy_data.auto_direction, enemy_data.side, enemy_data.desync));
		//	Cheat.Print("Am tras in mortii tai.\n")
			// arms get inversed due to being backwards
			if(!antiaim.legit_aa) // use this smart anti-bruteforce if we don't have legit aa 
			{
				player_list[enemy].side = -antiaim.side;
				player_list[enemy].auto_direction = -antiaim.auto_direction;

				enemy_data = player_list[enemy];
				//player_list[enemy].round_start_state = new AAState(enemy_data.auto_direction, enemy_data.side, enemy_data.desync)
			}
			player_list[enemy].last_shot_at_us = tickcount;

        }
        player_list[enemy].last_bullet_impact = tickcount;
    }
}
antiaim.reset_after = function()
{
	if(aa_reset_chk.value)
	{
		for(var i = 0; i < player_list.length;i++) 
		{
			var time_passed = Globals.TicksToTime(Globals.Tickcount() - player_list[i].last_shot_at_us).toFixed(1);
			if(time_passed > aa_reset_slider.value)
			{
				player_list[i].auto_direction = STARTING_AUTO_DIRECTION;
				player_list[i].side = STARTING_SIDE
				player_list[i].desync = STARTING_DESYNC;
			}
		}
	}
}
antiaim.on_round_start = function()
{
	for(var i = 0; i < player_list.length;i++) 
    {
		const state = player_list[i].round_start_state;

		player_list[i].auto_direction = state.auto_direction;
		player_list[i].side = state.side;
		player_list[i].desync = state.desync;
		player_list[i].evasion_timer = Globals.Tickcount();
    }
}

antiaim.bomb_begin_defuse = function()
{
    if(Entity.IsLocalPlayer(Entity.GetEntityFromUserID(Event.GetInt("userid"))))
        antiaim.legit_aa_timer = -9999
}
antiaim.bomb_abort_defuse = function()
{
    if(Entity.IsLocalPlayer(Entity.GetEntityFromUserID(Event.GetInt("userid"))))
        antiaim.legit_aa_timer = 0
}
antiaim.bomb_defused = function()
{
    if(Entity.IsLocalPlayer(Entity.GetEntityFromUserID(Event.GetInt("userid"))))
        antiaim.legit_aa_timer = 0
}

Cheat.RegisterCallback("bomb_begindefuse", "antiaim.bomb_begin_defuse");
Cheat.RegisterCallback("bomb_abortdefuse", "antiaim.bomb_abort_defuse");
Cheat.RegisterCallback("bomb_defused", "antiaim.bomb_defused");

antiaim.draw = function()
{	
	if(!enable_aa.value) return;

	const local = Entity.GetLocalPlayer();
	const center = Vector.div(Render.GetScreenSize(), 2);
    const color = [230, 104, 44,255]
	
	var side = antiaim.side;

	arrows_font = Render.GetFont("Tahoma.ttf", 25, true);
	draggable_font = Render.GetFont("Arialbd.ttf", 10, true);
	doubletap = UI.GetValue(["Rage", "Exploits", "Keys", "Key assignment", "Double tap"]);
	hideshots = UI.GetValue(["Rage", "Exploits", "Keys", "Key assignment", "Hide shots"]);

	if(antiaim.legit_aa)
		side = -side;

	if(show_indicators.value)
		if(antiaim.side != null && local && Entity.IsAlive(local) && antiaim.enemy && Entity.IsAlive(antiaim.enemy))
		{
			Render.String(center[0] - 40,center[1] - 17,1,"<", side == -1 ? [255,255,255,255] : color, arrows_font);
			Render.String(center[0] + 40,center[1] - 17,1,">", side == 1 ? [255,255,255,255] : color, arrows_font);

			draw_outline_text( center[0] , center[1] + 13, 1, "ideal" , [ 255, 255, 255, 255 ], draggable_font);
		}
		else if(local && Entity.IsValid(local) && Entity.IsAlive(local))
		{
			Render.String(center[0] - 40,center[1] - 17,1,"<",  [255,255,255,255], arrows_font);
			Render.String(center[0] + 40,center[1] - 17,1,">",  [255,255,255,255], arrows_font);

			draw_outline_text( center[0] , center[1] + 13, 1, "neutral" , [ 255, 255, 255, 255 ], draggable_font);
		}
		if(local && Entity.IsAlive(local))
		{
			var y = center[1] + 26;

			if(antiaim.legit_aa)
			{
				draw_outline_text( center[0] , center[1] + 26, 1, "legit aa" , [ 255, 255, 255, 255 ], draggable_font);
				y += 13;
			}

			if( antiaim.enemy && Entity.IsAlive(antiaim.enemy))
			{
				const last_shot_at_us = player_list[antiaim.enemy].last_shot_at_us;

				if(Globals.Tickcount() - last_shot_at_us <= 64 * aa_reset_slider.value) // slider's value
				{
					draw_outline_text( center[0] , y, 1, "dodge (" +  (aa_reset_slider.value - Globals.TicksToTime(Globals.Tickcount() - last_shot_at_us)).toFixed(1) + "s)", [ 255, 255, 255, 255 ], draggable_font);
					y += 13;
				}
		
				if(player_list[antiaim.enemy].evasion_timer >= Globals.Tickcount() && player_list[antiaim.enemy].evasion_timer != null) // evasion indicator hasn't expired so render it
				{
					draw_outline_text( center[0] , y, 1, "evasion (" +  (10 - Globals.TicksToTime(player_list[antiaim.enemy].evasion_timer - Globals.Tickcount())).toFixed(1) + "s)" , [ 255, 255, 255, 255 ], draggable_font);
					y += 13;
				}
			}

			if(doubletap)
			{
				draw_outline_text( center[0] , y, 1, "doubletap" , [ 255, 255, 255, 255 ], draggable_font);
				y += 13;
			}
			
			if(hideshots)
				draw_outline_text( center[0] , y, 1, "onshot" , [ 255, 255, 255, 255 ], draggable_font);	
		}

}

const ragebot = 
{
	started_recharging : false,
	last_recharge : 0,
	automatic_recharge : true
}

ragebot.faster_dt = function()
{
	if(contains(dt_improvements.selected, "Faster DT"))
	{
		Convar.SetInt("cl_clock_correction", 0);
		Convar.SetInt("sv_maxusrcmdprocessticks", 18);
		Exploit.OverrideTolerance(0);
		Exploit.OverrideShift(16);
	}
}

ragebot.can_shift_shot = function(ticks_to_shift) 
{
    var me = Entity.GetLocalPlayer();
    var wpn = Entity.GetWeapon(me);

    if (me == null || wpn == null)
        return false;

    var tickbase = Entity.GetProp(me, "CCSPlayer", "m_nTickBase");
    var curtime = Globals.TickInterval() * (tickbase-ticks_to_shift)

    if (curtime < Entity.GetProp(me, "CCSPlayer", "m_flNextAttack"))
        return false;

    if (curtime < Entity.GetProp(wpn, "CBaseCombatWeapon", "m_flNextPrimaryAttack"))
        return false;

    return true;
}

ragebot.faster_recharge = function()
{
	if(!contains(dt_improvements.selected, "Better Recharge")) 
	{
		ragebot.automatic_recharge = true;
		Exploit.EnableRecharge(); return;
	}
	else if(ragebot.automatic_recharge)  
	{
		Exploit.DisableRecharge();
		ragebot.automatic_recharge = false;
	}

	const charge = Exploit.GetCharge()
	const is_charged = charge == 1;
	
	if(is_charged) 
	{
		ragebot.started_recharging = false; return;
	}

	const will_get_hit = ragebot.can_get_hit()
	if(will_get_hit || Ragebot.GetTarget() != 0) return;

	if(!ragebot.started_recharging && ragebot.can_shift_shot(dt_recharge_delay.value)) 
	{	
		
		Exploit.Recharge();

		ragebot.started_recharging = true;
		ragebot.last_recharge = Globals.Tickcount();
	}
	
}

ragebot.can_get_hit = function()
{
	const enemies = Entity.GetEnemies();
	const local = Entity.GetLocalPlayer();
	const body = Entity.GetHitboxPosition(local, 2);

	if(!local || !Entity.IsAlive(local)) return false;

	if(Ragebot.GetTarget() != 0) return true;

	for(var i = 0; i < enemies.length;i++)
	{
		const enemy = enemies[i];

		if(!Entity.IsValid(enemy) && !Entity.IsAlive(enemy) && Entity.IsDormant(enemy)) continue;

		const enemy_pos = Entity.GetEyePosition(enemy);
		const velocity = Entity.GetProp(local, "CBasePlayer", "m_vecVelocity[0]");
		const enemy_velocity = Entity.GetProp(enemy, "CBasePlayer", "m_vecVelocity[0]");

		const extrapolated_enemy = Math.extrapolate(enemy_pos, enemy_velocity, 14);
		const extrapolated_local = Math.extrapolate(body, velocity, 16);

		const bullet_data = Trace.RawLine(enemy,extrapolated_enemy,extrapolated_local,0x4600400b,0);

		if(bullet_data[0] == local)
		{
			return true;
		}
	}

	return false;
}

ragebot.improved_target_selection = function()
{
	if(!improved_target_selection.value) return;

	const enemies = Ragebot.GetTargets();

	const entities_in_air = [];
	var on_ground = 0;

	for(var i = 0; i < enemies.length;i++)
	{
		const enemy = enemies[i];

		if(Entity.IsInAir(enemy)) 
			entities_in_air.push(enemy);
		else 
			on_ground++;
	}

	if(on_ground)
	{
		for(var i = 0; i < entities_in_air.length;i++)
			Ragebot.IgnoreTarget(entities_in_air[i]);
	}

}

ragebot.run_ragebot = function()
{
	ragebot.faster_dt();
	ragebot.faster_recharge();
	ragebot.improved_target_selection();
}

// RAGEBOT
Cheat.RegisterCallback("CreateMove", "ragebot.run_ragebot");
//

//#region Callbacks ANTIAIM
Cheat.RegisterCallback("CreateMove", "antiaim.run_antiaim");
Cheat.RegisterCallback("CreateMove", "antiaim.reset_after");
Cheat.RegisterCallback("CreateMove", "antiaim.run_legit_aa");
Cheat.RegisterCallback("bullet_impact", "antiaim.on_bullet_impact");
Cheat.RegisterCallback("player_hurt", "antiaim.on_player_hurt");
Cheat.RegisterCallback("round_start", "antiaim.on_round_start");
Cheat.RegisterCallback("Draw", "antiaim.draw");
Cheat.RegisterCallback("Draw","render_menu");
Cheat.RegisterCallback("CreateMove","fix_input");
//#endregion


var key_names = ["-", "mouse1", "mouse2", "break", "mouse3", "mouse4", "mouse5",
    "-", "backspace", "tab", "-", "-", "-", "enter", "-", "-", "shift",
    "control", "alt", "pause", "capslock", "-", "-", "-", "-", "-", "-",
    "-", "-", "-", "-", "-", "space", "page up", "page down", "end", "home", "left",
    "up", "right", "down", "-", "Print", "-", "print screen", "insert", "delete", "-", "0", "1",
    "2", "3", "4", "5", "6", "7", "8", "9", "-", "-", "-", "-", "-", "-",
    "Error", "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u",
    "v", "w", "x", "y", "z", "left windows", "right windows", "-", "-", "-", "insert", "end",
    "down", "page down", "left", "numpad 5", "right", "home", "up", "page up", "*", "+", "_", "-", ".", "/", "f1", "f2", "f3",
    "f4", "f5", "f6", "f7", "f8", "f9", "f10", "f11", "f12", "f13", "f14", "f15", "f16", "f17", "f18", "f19", "f20", "f21",
    "f22", "f23", "f24", "-", "-", "-", "-", "-", "-", "-", "-",
    "number lock", "scroll lock", "-", "-", "-", "-", "-", "-", "-",
    "-", "-", "-", "-", "-", "-", "-", "shift", "right shift", "control",
    "right control", "menu", "right menu", "-", "-", "-", "-", "-", "-", "-",
    "-", "-", "-", "next", "previous", "stop", "toggle", "-", "-",
    "-", "-", "-", "-", ";", "+", ",", "-", ".", "/?", "~", "-", "-",
    "-", "-", "-", "-", "-", "-", "-", "-", "-",
    "-", "-", "-", "-", "-", "-", "-", "-", "-",
    "-", "-", "-", "-", "-", "-", "[{", "\\|", "}]", "'\"", "-",
    "-", "-", "-", "-", "-", "-", "-", "-", "-",
    "-", "-", "-", "-", "-", "-", "-", "-", "-",
    "-", "-", "-", "-", "-", "-", "-", "-", "-",
    "-", "-"];

	
/* region: config */
const config = {};

config.save = function () {

    // loop thru all config variables
	for(var i = 0; i < menu.children.length;i++)
	{
		for(var j = 0; j < menu.children[i].children.length;j++)
		{
			DataFile.SetKey("config.Phoenix", menu.children[i].text + " " + menu.children[i].children[j].name , JSON.stringify(String(menu.children[i].children[j].cfg)));
		}
	}
    // save/create file
    DataFile.Save("config.Phoenix");

    // log
	Cheat.PrintColor([230, 104, 44, 255], "[phoenix]");
    Cheat.Print(" Configuration saved.\n");
}
config.load = function () {

    // load the file
    DataFile.Load("config.Phoenix");

    // loop thru all config variables
	for(var i = 0; i < menu.children.length;i++)
	{
		for(var j = 0; j < menu.children[i].children.length;j++)
		{
			var string = DataFile.GetKey("config.Phoenix", menu.children[i].text + " " + menu.children[i].children[j].name);
			if (!string)
            	continue;

			// parse JSON
			
			var data = JSON.parse(string);

			var obj = menu.children[i].children[j];
			
			if(data == "undefined")
				data = null;

		//	Cheat.Print(menu.children[i].children[j].name + " " + data + "\n")
			if(obj.type == "checkbox" || obj.type == "slider")
			{
				if(obj.type == "checkbox")
				{
					if(data == "true")
						menu.children[i].children[j].value = true;
					else 
						menu.children[i].children[j].value = false;
					
					menu.children[i].children[j].cfg = menu.children[i].children[j].value;
				}
				else 
				{
					menu.children[i].children[j].value = parseInt(data);
					menu.children[i].children[j].cfg = parseInt(data);
				}
			}
			else if(obj.type == "combo")
			{
				if(data != "null")
				{
					menu.children[i].children[j].selected = parseInt(data);
				}
				else 
				{
					menu.children[i].children[j].selected = null;
				}
				menu.children[i].children[j].cfg = menu.children[i].children[j].selected;
			}
			else if(obj.type == "multi")
			{
				//Cheat.Print(data + '\n')
				if(data == "") continue;
				
				if(data[0] == ",")
					menu.children[i].children[j].selected = data.slice(1,data.length).split(",");
				else
					menu.children[i].children[j].selected = data.split(",");

				menu.children[i].children[j].cfg = menu.children[i].children[j].selected
			}
			else if(obj.type == "keybind")
			{
				if(data == "null")
					menu.children[i].children[j].key = null;
				else 
				{
					menu.children[i].children[j].key = parseInt(data);
					menu.children[i].children[j].cfg = menu.children[i].children[j].key;
				}
				
				
			}
			
		
		}
	}

}

config.dump_aa_data = function()
{
	for(var i = 0; i < player_list.length;i++)
	{
		var ent = player_list[i].ent_index;
		var shots = player_list[i].shot_logs;
		
		if(Entity.IsValid(ent) && Entity.IsEnemy(ent))
		{
			//Cheat.Print(Entity.GetName(ent) + ":\n")
			for(var j = 0; j < shots.length;j++)
			{
				var shot = shots[j];
				var shot_aa = shot.cur_antiaim;
				//Cheat.Print(shot.hit + " " + shot.hitgroup + "\n")

				var auto_dir = shot_aa.auto_direction == FREESTAND ? "FREESTAND" : "OPPOSITE";
				var side = shot_aa.side;
				var desync = shot_aa.desync;
				var max_desync = shot.max_desync;

				if(shot.hit && shot.hitgroup == Hitgroups.head)
				{
					Cheat.Print(Entity.GetName(ent) + " hit our head | Auto Direction: " + auto_dir + " | Side: " + side + " | Desync: " + desync + " | Max Desync: " + max_desync + "\n");
				}
				else if(!shot.hit)
				{
					Cheat.Print(Entity.GetName(ent) + " missed our head | Auto Direction: " + auto_dir + " | Side: " + side + " | Desync: " + desync + " | Max Desync: " + max_desync + "\n");
				}
			}
			if(shots.length > 0)
			{
				Cheat.Print("\n");
				Cheat.Print('-------------------------');
				Cheat.Print("\n");
			}
			
		}
	}
}
function on_unload()
{
	Exploit.EnableRecharge();
	if(menu_was_opened)
    	config.save();
	
	//config.dump_aa_data();
	
}

config.load();


Cheat.RegisterCallback("Unload", "on_unload")
