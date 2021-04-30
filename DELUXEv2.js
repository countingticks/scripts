
const user = Cheat.GetUsername();
const user_list = {"RazvanDard" : "dev", "bogdan56" : "dev", "adriaN1" : "beta"};

var prefix = user_list[user]; // aka | beta | empty | trial

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
	
	var text = "phoenix v2" + " | " + user + " | delay: " + delay + " ms";

	if(prefix != "")
		text = "phoenix v2 [" + prefix + "] | " + user + " | delay: " + delay + " ms";

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

const draw_outline_text = function(x, y, align, string, color, fontname) {
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

function Menu(x, y, w, h)
{
	this.x = x;
	this.y = y;
	this.w = w;
	this.h = h;

	this.delta_x = 0;
	this.delta_y = 0;
	this.dragging = false;
	
    this.is_open = false;
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

	this.add_keybind = function(tab_name, name)
    {
        var keybind = new Keybind(tab_name, name);
        for(var i = 0; i < this.children.length;i++)
        {
            if(this.children[i].text == tab_name)
                this.children[i].children.push(keybind);
        }
        return keybind;
    }

    this.add_slider = function(tab_name, name, min_val, max_val)
    {
        var slider = new Slider(tab_name, name, min_val, max_val);
        for(var i = 0; i < this.children.length;i++)
        {
            if(this.children[i].text == tab_name)
                this.children[i].children.push(slider);
        }
        return slider;
    }

	this.add_combobox = function(tab_name, name, values, multi)
    {
		
        var combo;

		if(multi)
			combo = new MultiBox(tab_name, name, values);
		else 
			combo = new ComboBox(tab_name, name, values);

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
            if(this.children[i].visible)
            {
                padding += this.children[i].padding;
            }

            if(menu.y + 10 + padding > menu.y + menu.h * 0.9)
            {
                adder_x = 270;
                adder_y = 20;
                padding = 0;
            }

            this.children[i].setup_positions(this.x + adder_x, menu.y + 10 + padding + adder_y)

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
    this.padding = 20;
    this.visible = true;

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
    }

    this.set_visibility = function(visibility)
    {
        this.visible = visibility;
    }
}

function ComboBox(tab_name, name, values)
{
    this.tab = tab_name;
    this.name = name;
    this.values = values;
	this.selected = null

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

        Render.FilledRect(this.x, this.y, this.w, this.h, MenuStyles.background);

        Render.Rect(this.x - 1, this.y - 1, this.w + 1, this.h + 1, Colors.black);

        draw_outline_text(this.x, this.y - this.h, 0, name, Colors.white, menu_font);

		if(this.selected == null)
		{
			draw_outline_text(this.x + 2, this.y + 1, 0, "None", Colors.white, menu_font);
		}
		else 
			draw_outline_text(this.x + 2, this.y + 1, 0, this.values[this.selected], Colors.white, menu_font);

		if(this.is_open)
		{
			var padding = 0;
			for(var i = 0; i < this.values.length;i++)
			{
				padding += 15;
				Render.FilledRect(this.x, this.y + padding, this.w, this.h, MenuStyles.background);

				var color;
				if(this.selected == i)
					color = MenuStyles.theme
				else if(this.hovered_element == i) 
					color = MenuStyles.theme_not_selected
				else
					color = Colors.white

				draw_outline_text(this.x + 2, this.y + padding, 0, String(this.values[i]) , color, menu_font);
			}
			
			Render.Rect(this.x - 1, this.y + 15 - 1, this.w + 1, padding + 1, Colors.black);
			Render.Rect(this.x - 1, this.y - 1, this.w + 1, this.h + 1, MenuStyles.theme);
		}
    }

    this.handle_input = function()
    {
        if(!this.visible) return;

        var in_bounds = input_system.cursor_in_bounds(this.x, this.y, this.w, this.h)

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

				var in_bounds = input_system.cursor_in_bounds(this.x, this.y + padding, this.w, this.h)

				if(in_bounds && input_system.is_key_pressed(0x01))
				{
					if(this.selected == i)
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

	this.value_selected = [];

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

	this.text_start = 0;
	this.text_end = 15;
	this.last_update = 0;
	this.wait = false;
	
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

        Render.FilledRect(this.x, this.y, this.w, this.h, MenuStyles.background);

        Render.Rect(this.x - 1, this.y - 1, this.w + 1, this.h + 1, Colors.black);

        draw_outline_text(this.x, this.y - this.h, 0, name, Colors.white, menu_font);

		if(this.selected.length == 0)
		{
			draw_outline_text(this.x + 2, this.y + 1, 0, "None", Colors.white, menu_font);
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

					
					if(this.text_start == 1 && this.text_end == 16)
						this.last_update = Date.now() + 1200;
				}
				if(this.text_end > String(this.selected).length)
				{
					this.text_start = 0;
					this.text_end = 15;
					this.last_update = Date.now() + 1200;
				}
				draw_outline_text(this.x + 2, this.y + 1, 0, this.str, Colors.white, menu_font);
			}
			else 
			{
				this.text_start = 0;
				this.text_end = 15;
				draw_outline_text(this.x + 2, this.y + 1, 0, str, Colors.white, menu_font);
			}

			
		}
		if(this.is_open)
		{
			var padding = 0;
			for(var i = 0; i < this.values.length;i++)
			{
				padding += 15;
				Render.FilledRect(this.x, this.y + padding, this.w, this.h, MenuStyles.background);

				var color;
				if(contains(this.selected,this.values[i]))
					color = MenuStyles.theme
				else if(this.hovered_element == i) 
					color = MenuStyles.theme_not_selected
				else
					color = Colors.white

				draw_outline_text(this.x + 2, this.y + padding, 0, String(this.values[i]) , color, menu_font);
			}
			
			Render.Rect(this.x - 1, this.y + 15 - 1, this.w + 1, padding + 1, Colors.black);
			Render.Rect(this.x - 1, this.y - 1, this.w + 1, this.h + 1, MenuStyles.theme);
		}
    }

    this.handle_input = function()
    {
        if(!this.visible) return;

        var in_bounds = input_system.cursor_in_bounds(this.x, this.y, this.w, this.h)

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

				var in_bounds = input_system.cursor_in_bounds(this.x, this.y + padding, this.w, this.h)

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

			}
		}

    }

    this.set_visibility = function(visibility)
    {
        this.visible = visibility;
    }
}

function Slider(tab_name, name, min_val, max_val)
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

	this.type = "slider"
    this.slider_x = this.x;

    this.hovering = false;
    this.text_size = 0;
    this.padding = 35;

    this.visible = true;
    this.dragging = false;

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
        this.text_size = Render.TextSize(name, menu_font);
        number_size = Render.TextSize(String(this.value), menu_font)
        Render.FilledRect(this.x, this.y, this.w, this.h, MenuStyles.background);
		
        Render.FilledRect(this.x, this.y, this.slider_x - this.x, this.h, MenuStyles.theme)
        Render.Rect(this.x - 1, this.y - 1, this.w + 1, this.h + 1, Colors.black);

        Render.FilledRect(this.slider_x, this.y, 5, 10, Colors.white);

        draw_outline_text(this.x, this.y - this.h - this.text_size[1] / 2, 0, name, Colors.white, menu_font);
        
        draw_outline_text(this.x + this.w + 2 + number_size[0] * 0.35, this.y - 2, 0, String(this.value), Colors.white, menu_font);
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

        var in_bounds = input_system.cursor_in_bounds(this.x, this.y, this.w, this.h)

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
		}
    }
    this.set_visibility = function(visibility)
    {
        this.visible = visibility;
    }
}

function Keybind(tab_name, name)
{
    this.tab = tab_name;
    this.name = name;

    this.key = null;

    this.x = 0;
    this.y = 0;

    this.w = 10;
    this.h = 10;

	this.type = "keybind"
    this.hovering = false;
	this.wait_for_key = false;

    this.text_size = 0;
    this.padding = 20;
    this.visible = true;

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

var enable_aa = menu.add_checkbox("Anti-Aim", "Anti-Aim");
var anti_bruteforce = menu.add_checkbox("Anti-Aim", "Anti-Bruteforce");
var evasion = menu.add_checkbox("Anti-Aim", "Evasion");
var combobox = menu.add_combobox("Anti-Aim" , "Anti-Aim Type" , ["Freestand" , "Opposite", "Wtf" ,"Advanced"], true)
var aa_reset = menu.add_slider("Anti-Aim" , "Anti-Aim Reset Time" , 0, 10)
var keybind = menu.add_keybind("Anti-Aim", "Menu hotkey");

anti_bruteforce.set_visibility(false);
evasion.set_visibility(false);

//#endregion

function render_menu()
{
	input_system.update_input();
	input_system.enable_mouse_input(menu.is_open);

    font = Render.GetFont("Arialbd.ttf", 20, true);
    menu_font = Render.GetFont("Arialbd.ttf", 10, true);
    tab_selected = Render.GetFont("Arialbd.ttf", 22, true);
    logo_font = Render.GetFont("Arialbd.ttf", 25, true);

    if(input_system.is_key_pressed( 0x24 )) 
        menu.is_open = !menu.is_open;

    if(menu.is_open)
    {
        menu.drag();
        menu.render();
        menu.handle_children();
    }

    anti_bruteforce.set_visibility(enable_aa.value);
    evasion.set_visibility(enable_aa.value);

	draggable_font = Render.GetFont("Arialbd.ttf", 10, true);
	arrows_font = Render.GetFont("Arialbd.ttf", 20, true);

	watermark.render();
	spectator_list.render();
	keybinds.render();
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

const STARTING_DESYNC = 20;
const STARTING_AUTO_DIRECTION = FREESTAND;
const STARTING_SIDE = 1;

function AAState(auto_direction, side, desync)
{
	this.auto_direction = auto_direction;
	this.side = side;
	this.desync = desync;
}

function ShotData(auto_direction, side, desync, max_desync, hit, hitgroup) // the hitbox it hit or null and hit = true or false 
{
	this.auto_direction = auto_direction;
	this.side = side;
	this.desync = desync;
	 
	this.max_desync = max_desync;
	this.hitgroup = hitgroup;
	this.hit = hit;

	if(this.hit == undefined)
	{
		this.hitgroup = null;
		this.hit = false;
	}
}

function Player(ent_index)
{
	this.ent_index = ent_index;
	this.desync = STARTING_DESYNC;
	this.side = 1; // 1 or -1
	this.auto_direction = FREESTAND; // 1 or -1

	this.miss_logs = []; // desync : amount / ? 
						// side : 1 / -1
						// max_desync : get_max_desync()

	this.hit_logs = []; // same as miss_logs
	this.shot_logs = [];

	this.missed_us = 0; // times he missed us
	this.last_shot_time = 0;
	this.onshot_counter = 0;
	this.headshot_counter = 0;

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

function set_aa(fake) 
{
    AntiAim.SetFakeOffset(0);
    AntiAim.SetRealOffset(-fake);
    AntiAim.SetLBYOffset(0);
}

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
	left_arm : 13,
	right_arm : 14,
	max : 15
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

Globals.TicksToTime = function(tick)
{
	return Globals.TickInterval() * tick;
}

Globals.TimeToTicks = function(tick)
{
	return Math.floor(0.5 + tick / Globals.TickInterval());
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
	autodirection: null,
	side : null,
	desync : null,
	enemy : null,
	last_enemy : null,
	last_local_shot : null,
	last_bullet_impact : null
};

antiaim.run_prediction_on_enemy = function(enemy, optimizations)
{ 
	const tick_limit = 45
	var tick_step = 15;

	if(optimizations > 0)
		tick_step = 30;

	const local = Entity.GetLocalPlayer();
	const velocity = Entity.GetProp(local, "CBasePlayer", "m_vecVelocity[0]");
	
	//var trace_bullet = Entity.GetName(Entity.GetWeapon(local)).search("knife") == -1 ? true : false; // if it's not a knife then trace

	const enemy_pos = Entity.GetHitboxPosition(enemy, 3);
	const local_pos = Entity.GetEyePosition(local);

	const direction = Math.clamp(Vector.sub(enemy_pos , local_pos), -255, 255) // closest way to get to the enemy clamped into max velocity

	var velocities;

	if(optimizations < 2) 
		velocities = [direction, velocity, [255,0], [0, 255], [-255, 0] , [0, -255]];
	else if(optimizations == 2)
		velocities = [direction, velocity];

	var cur_velocity, extrapolated_local, bullet_data;

	for(var ticks = tick_limit; ticks >= 15; ticks -= tick_step)
	{        
		for(var i = 0; i < velocities.length; i++)
		{
			cur_velocity = [velocities[i][0], velocities[i][1] , velocity[2]];
			extrapolated_local = Math.extrapolate(local_pos, cur_velocity, ticks)

			bullet_data = Trace.Bullet(local, enemy , extrapolated_local , enemy_pos);

			if(bullet_data && bullet_data[1] > 0)
			{
				return true;
			}

		}

	}

	return false;

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

	for (var i = -90; i <= 90; i+= 15)
	{
		if (i != 0)
		{
			var fwd = Vector.to_angle([0, angle_to_enemy[1] + i, 0]);
			fwd = Vector.multiply(fwd, 250)

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
	var enemy, enemy_pos, screen_pos, dist;
	var max_dist = 999999;
	var enemies_list = {};
	
	const screen_size = Vector.div(Render.GetScreenSize() , 2);

	for(var i = 0; i < enemies.length ;i++)
	{
		enemy = enemies[i];

		if(!enemy || !Entity.IsAlive(enemy) || Entity.IsDormant(enemy)) continue;

		enemy_pos = Entity.GetHitboxPosition(enemy,3);

		screen_pos = Render.WorldToScreen(enemy_pos), dist;

		if(screen_pos && screen_pos[2] == 1)
			dist = Vector.distance2D(screen_size , screen_pos);
		else 
		{
			dist = max_dist;
			max_dist -= 1;
		}

		enemies_list[enemy] = dist;
	}

	var enemy_pairs = Object.keys(enemies_list).map(function(key) { return [key, enemies_list[key]]; } );
	enemy_pairs.sort(function(first, second) { return second[1] - first[1]; } );
	
	
	var enemies = [];
	for(var i = 0; i < enemy_pairs.length;i++)
		enemies[i] = parseInt(enemy_pairs[i][0]);

	for(var i = 0; i < enemies.length; i++)
	{
		if(enemies[i] == antiaim.last_enemy)
		{
			const aux = enemies[0];
			enemies[0] = enemies[i]
			enemies[i] = aux;
			break;
		}
	}
	return enemies;
}

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
	
	const ragebot_target = Ragebot.GetTarget();
	const should_optimize = (enemies.length >= 4) + (enemies.length >= 8); // aka if more than 4 enemies optimize = 1 if more than or 8 enemies then == 2 so run more optimizations

	if(ragebot_target)
	{
		antiaim.enemy = ragebot_target;
		antiaim.last_enemy = ragebot_target;
		found_enemy = true;
	}
	else 
	{
		var enemy;
	
		for(var i = 0; i < enemies.length && !found_enemy;i++)
		{
			enemy = enemies[i];
			if(enemy && Entity.IsAlive(enemy) && !Entity.IsDormant(enemy))
			{
				
				hit_enemy = antiaim.run_prediction_on_enemy(enemy, should_optimize);

				if(hit_enemy)
				{
					antiaim.enemy = enemy;
					antiaim.last_enemy = enemy;
					found_enemy = true;
				}

			}
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

			antiaim.side = enemy_data.side;
			antiaim.desync = enemy_data.desync;
		}
		//Cheat.Print(antiaim.side + "\n")
		set_aa(antiaim.side * antiaim.desync)
	}

	for(var i = 0; i < enemies.length;i++)
	{
		enemy = enemies[i];
		if(player_list[enemy].onshot_counter >= 2)
			Entity.DrawFlag(antiaim.enemy, "ONSHOTTER", [255,255,255,255])
	}

}

antiaim.on_player_hurt = function()
{
	if(!anti_bruteforce.value) return;
	
 	const attacker = Entity.GetEntityFromUserID(Event.GetInt("attacker"));
	const victim = Entity.GetEntityFromUserID(Event.GetInt("userid"));

	const dmg = Entity.GetEntityFromUserID(Event.GetInt("dmg"));
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
		Cheat.Print(Entity.GetName(attacker) + " onshotted us! \n")
		return; // we got onshotted hurray.. we don't care about other shit 
	}

	if(remaining_health > 0 && player_list[attacker].shot_logs[last_shot]) // we're still alive so bullet_impact registered
	{
		player_list[attacker].shot_logs[last_shot].hit = true;
		player_list[attacker].shot_logs[last_shot].hitgroup = hitgroup;

		// set aa to the state before anti bruteforce because this shot hit
		player_list[attacker].desync = last_aa_state.desync;
		player_list[attacker].auto_direction = last_aa_state.auto_direction;
		player_list[attacker].side = last_aa_state.side;
	}
	else
	{
		player_list[attacker].shot_logs.push(new ShotData(enemy_data.auto_direction, enemy_data.side, enemy_data.desync, Entity.GetMaxDesync(local)), true, hitgroup);
	}


    if (hitgroup == Hitgroups.head || hitgroup == Hitgroups.left_leg || hitgroup == Hitgroups.right_leg)  //head, both toe
    {
		if(hitgroup == Hitgroups.head)
			player_list[attacker].headshot_counter += 1;

        player_list[attacker].auto_direction = -player_list[attacker].auto_direction;
		player_list[attacker].side = -player_list[attacker].side;

		if(player_list[attacker].desync < 47)
			player_list[attacker].desync = 60;
		else 
			player_list[attacker].desync = 20;

		//Cheat.Print(String(-old_aa_state.auto_direction) + "\n")
		player_list[attacker].round_start_state = new AAState(player_list[attacker].auto_direction, player_list[attacker].side, player_list[attacker].desync)
    }
    else 
    {
		if(dmg < 40)
		{
			player_list[attacker].desync = 3;
		}
		else if(evasion.value) // if evasion checkbox run the shit
		{
			player_list[attacker].desync = 60;
			player_list[attacker].auto_direction = -player_list[attacker].auto_direction;
			player_list[attacker].side = -player_list[attacker].auto_direction;

			player_list[attacker].evasion_timer = Globals.Tickcount() + 64 * 10; // evasion for 10s for indicator
		}
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

        const local_origin = Entity.GetProp(local, "CBaseEntity", "m_vecOrigin");
		const local_body = Entity.GetHitboxPosition(local, 3)

		const body_vec = Vector.closest_point_to_ray(local_body, source, impact);
        const body_dist = Vector.distance(local_body, body_vec);
		
		const left_arm_pos = Entity.GetHitboxPosition(local, Hitboxes.left_arm)
		const right_arm_pos = Entity.GetHitboxPosition(local, Hitboxes.right_arm)
      

        if (body_dist < 80.0)  // shot near us
        {
			const head_pos = Entity.GetHitboxPosition(local, 0)
            const head_vec = Vector.closest_point_to_ray(head_pos, source, impact);
            const head_dist = Vector.distance(head_pos, head_vec);

            const feet_vec = Vector.closest_point_to_ray(local_origin, source, impact);
            const feet_dist = Vector.distance(local_origin, feet_vec);

			const left_arm_vec = Vector.closest_point_to_ray(left_arm_pos, source, impact);
            const left_arm_dist = Vector.distance(left_arm_pos, left_arm_vec);

			const right_arm_vec = Vector.closest_point_to_ray(right_arm_pos, source, impact);
            const right_arm_dist = Vector.distance(right_arm_pos, right_arm_vec);


         //   var closest_ray_point = null;
			var enemy_data = player_list[enemy];

			player_list[enemy].shot_logs.push(new ShotData(enemy_data.auto_direction, enemy_data.side, enemy_data.desync, Entity.GetMaxDesync(local)));
			
            if (body_dist < head_dist && body_dist < feet_dist)     //that's a pelvis
            {                                                  
                closest_ray_point = body_vec;
				return;
			}

		//	antiaim.last_bullet_impact = tickcount;
			

            player_list[enemy].old_aa_states.push(new AAState(enemy_data.auto_direction, enemy_data.side, enemy_data.desync));
			

			// arms get inversed due to being backwards
            if(left_arm_dist < right_arm_dist) // right_arm is closer
			{
				if(antiaim.side == 1) // desync is right side
				{
					player_list[enemy].side = -player_list[enemy].side;
					player_list[enemy].auto_direction = -player_list[enemy].auto_direction;
				}
				else // desync is left side this means he shot near our real so change desync
				{
					if(antiaim.desync > 47)
						player_list[enemy].desync = 20 
					else 
						player_list[enemy].desync = 60;
				}
			}
			else // left_arm is closer
			{
				if(antiaim.side == 1) // desync is right side this means he shot near our real so swap sides
				{
					if(antiaim.desync > 47)
						player_list[enemy].desync = 20 
					else 
						player_list[enemy].desync = 60;
				}
				else // desync is left side 
				{
					player_list[enemy].side = -player_list[enemy].side;
					player_list[enemy].auto_direction = -player_list[enemy].auto_direction; 
				}
			}

			enemy_data = player_list[enemy];
			player_list[enemy].round_start_state = new AAState(enemy_data.auto_direction, enemy_data.side, enemy_data.desync)
			
			player_list[enemy].last_shot_at_us = tickcount;

        }
        player_list[enemy].last_bullet_impact = tickcount;
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
    }
}

antiaim.draw = function()
{	
	if(!enable_aa.value) return;

	const local = Entity.GetLocalPlayer();
	const center = Vector.div(Render.GetScreenSize(), 2);
    const color = [230, 104, 44,255]

	if(antiaim.side != null && local && Entity.IsAlive(local) && antiaim.enemy && Entity.IsAlive(antiaim.enemy))
	{
		Render.String(center[0] - 25,center[1] - 13,1,"<", antiaim.side == 1 ? [255,255,255,255] : color, arrows_font);
		Render.String(center[0] + 25,center[1] - 13,1,">", antiaim.side == -1 ? [255,255,255,255] : color, arrows_font);

		draw_outline_text( center[0] , center[1] + 13, 1, "ideal yaw" , [ 255, 255, 255, 255 ], draggable_font);

		const last_shot_at_us = player_list[antiaim.enemy].last_shot_at_us;

		var y = center[1] + 26;

		if(Globals.Tickcount() - last_shot_at_us <= 64 * 10) // 10s
		{
			draw_outline_text( center[0] , y, 1, "dodge (" +  (10 - Globals.TicksToTime(Globals.Tickcount() - last_shot_at_us)).toFixed(1) + "s)", [ 255, 255, 255, 255 ], draggable_font);
			y += 13;
		}

		if(player_list[antiaim.enemy].evasion_timer >= Globals.Tickcount() && player_list[antiaim.enemy].evasion_timer != null) // evasion indicator hasn't expired so render it
			draw_outline_text( center[0] , y, 1, "evasion (" +  (10 - Globals.TicksToTime(player_list[antiaim.enemy].evasion_timer - Globals.Tickcount())).toFixed(1) + "s)" , [ 255, 255, 255, 255 ], draggable_font);

	}
	else if(Entity.IsAlive(local))
	{
		Render.String(center[0] - 25,center[1] - 13,1,"<",  [255,255,255,255], arrows_font);
		Render.String(center[0] + 25,center[1] - 13,1,">",  [255,255,255,255], arrows_font);

		draw_outline_text( center[0] , center[1] + 13, 1, "dynamic" , [ 255, 255, 255, 255 ], draggable_font);
	}
}

//#region Callbacks
Cheat.RegisterCallback("CreateMove", "antiaim.run_antiaim");
Cheat.RegisterCallback("player_hurt", "antiaim.on_player_hurt");
Cheat.RegisterCallback("bullet_impact", "antiaim.on_bullet_impact");
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