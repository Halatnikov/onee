imgui = {
	window = {},
	open = {},
}

-- init
local gui
if onee.libtype and debug_mode then
	if not files.exists("libs/cimgui."..onee.libtype) then
		local lib = love.filesystem.read("onee/debug/libs/cimgui-love/cimgui."..onee.libtype)
		love.filesystem.write("libs/cimgui."..onee.libtype, lib)
	end
	
	imgui_ = require("onee/debug/libs/cimgui-love")
	gui = imgui_
	
	gui.love.Init()
	gui.GetIO().ConfigFlags = gui.love.ConfigFlags("NavEnableKeyboard", "DockingEnable")
	
	imgui.open.menubar = true
	imgui.open.main = true
end

-- main loop
function imgui.update()
	if not gui then return end
	
	gui.love.Update(dt)
    gui.NewFrame()
end

function imgui.draw()
	if not gui then return end
	
	for k,v in pairs(imgui.open) do
		if imgui.open[k] then imgui.window[k]() end
	end
    
    gui.Render()
    gui.love.RenderDrawLists()
end

-- event redirection
onee.love("mousemoved", function(x, y, dx, dy, istouch)
	if not gui then return end
    gui.love.MouseMoved(x, y)
end)
onee.love("mousepressed", function(x, y, button, istouch, presses)
	if not gui then return end
    gui.love.MousePressed(button)
end)
onee.love("mousereleased", function(x, y, button, istouch)
	if not gui then return end
    gui.love.MouseReleased(button)
end)
onee.love("wheelmoved", function(x, y)
	if not gui then return end
    gui.love.WheelMoved(x, y)
end)
onee.love("keypressed", function(key, scancode, isrepeat)
	if not gui then return end
    gui.love.KeyPressed(key)
end)
onee.love("keyreleased", function(key, scancode)
	if not gui then return end
    gui.love.KeyReleased(key)
end)
onee.love("textinput", function(text)
	if not gui then return end
	gui.love.TextInput(text)
end)

-- data types conversion
local ffi = require("ffi")

local function _convert(arg, default, ctype)
	if type(arg) ~= "table" then arg = {arg} end
	if type(default) ~= "table" then default = {default} end

	local var = ffi.new(ctype.."["..#arg.."]")
	for i=1, #arg do
		var[i-1] = arg[i] or default[i]
	end
	return var
end

local function _bool(arg, default) -- bool* pointer
	if not arg then return _convert(0, default, "bool") end -- nil workaround
	return _convert(arg, default, "bool")
end

local function _int(arg, default) -- int* pointer
	return _convert(arg, default, "int")
end

local function _float(arg, default) -- float* pointer
	return _convert(arg, default, "float")
end

local function _char(arg, default) -- char* pointer
	if #arg == 0 then arg = "." end -- empty string workaround
	local var = ffi.new("char[?]", #arg+1)
	ffi.copy(var, arg or default or ".")
	return var
end

-- right align hack
local function rightalign(name)
	if gui.BeginTable(name or "", 2, gui.love.TableFlags("SizingFixedFit"), gui.ImVec2_Float(-1, 0)) then
		gui.TableSetupColumn(name or "", gui.love.TableColumnFlags("WidthStretch"))
		gui.TableNextColumn()
		gui.TableNextColumn()
		return true
	else
		return false
	end
end
local rightalign_end = gui.EndTable

---------------------------------------------------------------- table browser
do--#region TABLE BROWSER
--!
function imgui.table(arg, name, settings, level)
	local level = level or 0
	local settings = settings or {
		fancy = false,
		nowindow = false,
		imagescale = 1,
	}
	
	if level == 0 then
		if not settings.nowindow then
			local header = gui.CollapsingHeader_BoolPtr(name.."##"..string.md5(arg)) 
			imgui.table_label(arg, settings)
			
			if header then
				if gui.BeginChild_Str(name.."##"..string.md5(arg), nil, gui.love.ChildFlags("Border", "ResizeY")) then
					imgui.table_entries(arg, settings, 1)
					
					gui.EndChild()
				end
			end
		else
			imgui.table_entries(arg, settings, 1)
		end
		
	elseif level == 1 then
		local header = gui.CollapsingHeader_BoolPtr(name.."##"..string.md5(arg)) 
		imgui.table_label(arg, settings)
		
		if header then
			if gui.BeginChild_Str(name.."##"..string.md5(arg), nil, gui.love.ChildFlags("Border", "AutoResizeY")) then
				imgui.table_entries(arg, settings, 2)
				
				gui.EndChild()
			end
		end
		
	elseif level == 2 then
		local header = gui.TreeNodeEx_Str(name.."##"..string.md5(arg), gui.love.TreeNodeFlags("SpanAvailWidth"))
		imgui.table_label(arg, settings)
		
		if header then
			imgui.table_entries(arg, settings, 2)
			gui.Separator()
			
			gui.TreePop()
		end
	end
	
end

function imgui.table_label(arg, settings)
	local mt = getmetatable(arg)
	
	if gui.BeginItemTooltip() then
		gui.Text(tostring(arg))
		gui.Text("size: "..table.length(arg))
		if mt then gui.Text("metatable: "..tostring(mt)) end
		gui.EndTooltip()
	end
	
	if settings.fancy then imgui.table_fancy_label(arg) end
end

function imgui.table_fancy_label(arg)
	-- TODO: resize through getfontsize*#string
	-- TODO: align values in subtables with setnextitemwidth(-100)
	if not arg.collision and not arg.sprite then return end
	
	local label
	if arg.collision == true then label = "collision \""..arg.name.."\"" end
	if arg.sprite == true then label = "sprite \""..arg.name.."\"" end
	
	gui.SameLine(200)
	gui.TextColored(gui.ImVec4_Float(0.5,0.5,0.5,1), label)
end

function imgui.table_entries(arg, settings, level)
	if table.length(arg) == 0 then gui.TextColored(gui.ImVec4_Float(0.5,0.5,0.5,1), "- empty :) -") end
	
	if not settings.fancy then
		for k,v in kpairs(arg) do
			if type(k) == "table" then
				imgui.table(k, tostring(k), settings, level)
			else
				if type(v) == "table" then
					imgui.table(v, tostring(k), settings, level)
				else
					v = v == noop and "function: noop" or v
					gui.TextWrapped(tostring(k)..": "..tostring(v))
				end
			end
		end
	end
	
	if settings.fancy then
		for k,v in kpairs(arg) do
			if imgui.table_fancy_block(arg, k, v) then
				if type(k) == "table" then
					imgui.table(k, tostring(k), settings, level)
				else
					if type(v) == "table" then
						imgui.table(v, tostring(k), settings, level)
					else
						imgui.table_fancy_entry(arg, k, v, settings)
					end
				end
			end
		end
		
		imgui.table_fancy_allow(arg)
		if settings.edit then imgui.table_fancy_edit(arg) end
	end
	
end

function imgui.table_fancy_entry(arg, k, v, settings)
	if type(v) == "boolean" then
		local _v = _bool(v)
		if gui.Checkbox(tostring(k), _v) then
			arg[k] = _v[0]
		end
		
	elseif type(v) == "number" then
		local _v = _float(v)
		if gui.DragFloat(tostring(k), _v) then
			arg[k] = _v[0]
		end
		
	elseif type(v) == "string" then
		local _v = _char(v)
		gui.InputText(tostring(k), _v, _v[0])
		if gui.IsItemDeactivatedAfterEdit() then
			arg[k] = (ffi.string(_v) == ".") and "" or ffi.string(_v)
		end
		
	elseif type(v) == "userdata" and string.left(tostring(v), 6) == "Image:" then
		gui.Image(v, gui.ImVec2_Float(v:getWidth()*settings.imagescale, v:getHeight()*settings.imagescale))
		gui.SameLine()
		gui.Text(tostring(k))
		
	else
		if gui.BeginTable(tostring(k), 2, gui.love.TableFlags("BordersInnerV")) then
			gui.TableSetupColumn("1")
			gui.TableSetupColumn("2")
			
			gui.TableNextRow()
			v = v == noop and "function: noop" or v
			gui.TableSetColumnIndex(0); gui.TextColored(gui.ImVec4_Float(0.5,0.5,0.5,1), tostring(v))
			gui.TableSetColumnIndex(1); gui.Text(tostring(k))
			
			gui.EndTable()
		end
	end
end

function imgui.table_fancy_block(arg, k, v)
	if (k == "x" and arg.y) then return end
	if (k == "y" and arg.x) then return end
	
	if (k == "width" and arg.height) then return end
	if (k == "height" and arg.width) then return end
	
	if k == "rgb" then return end
	
	return true
end

function imgui.table_fancy_allow(arg)
	
	if arg.x and arg.y then
		if not (type(arg.x) == "number" and type(arg.y) == "number") then return end 
		local _v = _float({arg.x, arg.y})
		gui.DragFloat2("x & y", _v)
		
		arg.x = _v[0]
		arg.y = _v[1]
	end
		
	if arg.width and arg.height then
		local _v = _float({arg.width, arg.height})
		gui.DragFloat2("width & height", _v)
		
		arg.width = _v[0]
		arg.height = _v[1]
	end
	
	if arg.rgb then
		if #arg.rgb == 3 then
			local _v = _float({arg.rgb[1], arg.rgb[2], arg.rgb[3]})
			gui.ColorEdit3("rgb", _v)
			
			arg.rgb[1] = _v[0]
			arg.rgb[2] = _v[1]
			arg.rgb[3] = _v[2]
		elseif #arg.rgb == 4 then
			local _v = _float({arg.rgb[1], arg.rgb[2], arg.rgb[3], arg.rgb[4]})
			gui.ColorEdit4("rgb", _v)
			
			arg.rgb[1] = _v[0]
			arg.rgb[2] = _v[1]
			arg.rgb[3] = _v[2]
			arg.rgb[4] = _v[3]
		end
	end
	
end

local add_type, add_key, add_value

function imgui.table_fancy_edit(arg)
	local mt = getmetatable(arg)
	if mt then imgui.table(mt, "metatable", {fancy = true, edit = true}, 1) end
	
	if gui.Button("+") then
		add_key = "key"
		add_type = "boolean"
		add_value = true
		add_raw = false
		gui.OpenPopup_Str("table_add")
	end
	
	if gui.BeginPopup("table_add") then
		gui.SeparatorText("Add field")
		
		local _v = _char(add_key)
		gui.InputText("name", _v, _v[0])
		if gui.IsItemDeactivatedAfterEdit() then
			add_key = ffi.string(_v)
		end
		
		if gui.BeginCombo("type", add_type) then
			if gui.Selectable_Bool("boolean") then add_type = "boolean"; add_value = true end
			if gui.Selectable_Bool("number") then add_type = "number"; add_value = 0 end
			if gui.Selectable_Bool("string") then add_type = "string"; add_value = "string" end
			if gui.Selectable_Bool("table") then add_type = "table"; add_value = {} end
			if gui.Selectable_Bool("raw") then add_type = "raw"; add_value = "{}" end
			if gui.Selectable_Bool("nil") then add_type = "nil"; add_value = nil end
			gui.EndCombo()
		end
		
		if add_type == "boolean" then
			local _v = _bool(add_value)
			gui.Checkbox("value", _v)
			add_value = _v[0]
		end
		
		if add_type == "number" then
			local _v = _float(add_value)
			gui.InputFloat("value", _v, 1)
			add_value = _v[0]
		end
		
		if add_type == "string" then
			local _v = _char(add_value)
			gui.InputText("value", _v, _v[0])
			if gui.IsItemDeactivatedAfterEdit() then
				add_value = ffi.string(_v)
			end
		end
		
		if add_type == "raw" then
			local _v = _char(add_value)
			gui.InputTextMultiline("", _v, _v[0])
			if gui.IsItemDeactivatedAfterEdit() then
				add_value = ffi.string(_v)
			end
		end
		
		if gui.Button("Add") then
			if add_type == "raw" then
				add_value = loadstring("return "..add_value)()
			end
			arg[add_key] = add_value
			
			gui.CloseCurrentPopup()
		end
		
		gui.EndPopup()
	end
	
end
end--#endregion

local stepframe, advance_frame = false, false; local old_frame

local instance_selected, object_selected, asset_selected, sprite_selected, model_selected

---------------------------------------------------------------- MENU BAR

function imgui.window.menubar()
	
	if gui.BeginMainMenuBar() then
		
		------------------------------------------------ main menu
		if gui.BeginMenu("Main") then
			
			-- reload shortcut
			if gui.MenuItem_Bool("Reload", "F2") then
				love.event.quit("restart")
			end
			-- reset scene shortcut
			if gui.MenuItem_Bool("Reset scene", "F3") then
				scene.set(scenes[1].path)
			end
			-- to init scene
			if gui.MenuItem_Bool("Re-init", "F4") then
				scene.set("init")
			end
			-- advance frame controls shortcut
			if gui.SmallButton(stepframe and "|>" or "||") then
				stepframe = not stepframe
				onee.allow_update = not onee.allow_update
			end
			if stepframe then -- (only show these when frozen)
				gui.SameLine()
				if gui.SmallButton(">") then
					old_frame = frames
					advance_frame = true
				end
				gui.SameLine()
				gui.Text("STEP FRAME")
			end
			
			if advance_frame then -- (one frame forward)
				onee.allow_update = true
				if frames > old_frame then
					onee.allow_update = false
					advance_frame = false
				end
			end
			
			gui.Separator()
			-- draw collisions
			if gui.MenuItem_Bool("Draw collisions", nil, debug_draw_collisions) then
				debug_draw_collisions = not debug_draw_collisions
			end
			-- draw sprite bboxes
			if gui.MenuItem_Bool("Draw sprite BBoxes", nil, debug_draw_sprites) then
				debug_draw_sprites = not debug_draw_sprites
			end
			-- draw yui debug
			if gui.MenuItem_Bool("yui debug", nil, debug_yui) then
				debug_yui = not debug_yui
			end
			
			gui.Separator()
			-- toggle debug mode
			if gui.MenuItem_Bool("Debug mode", nil, debug_mode) then
				debug_mode = not debug_mode
				debug.enable(debug_mode)
			end
			-- change target fps
			gui.AlignTextToFramePadding()
			gui.Text("Target framerate")
			gui.SameLine()
			gui.SetNextItemWidth(32)
			local _v = _char(tostring(framerate))
			gui.InputText("", _v, _v[0])
			if gui.IsItemDeactivatedAfterEdit() then
				framerate = tonumber(ffi.string(_v))
				tick = 1 / framerate
			end
			
			gui.Separator()
			-- toggle mobile mode
			if gui.MenuItem_Bool("Mobile mode", nil, mobile) then
				mobile = not mobile
			end
			-- toggle file hot reload
			if gui.MenuItem_Bool("File hotswap", nil, debug_hotswap) then
				debug_hotswap = not debug_hotswap
			end
			-- toggle profiling
			if gui.MenuItem_Bool("Profiling", nil, debug_profiler) then
				debug_profiler = not debug_profiler
				debug.profiler_enable(debug_profiler)
			end
			if gui.MenuItem_Bool("Tracing (slow)", nil, debug_profiler_deep) then
				debug_profiler_deep = not debug_profiler_deep
				debug.profiler_deep_enable(debug_profiler_deep)
			end
			
			gui.Separator()
			-- trigger a crash
			if gui.MenuItem_Bool("Crash!", "F9") then
				error("you did this to yourself")
			end
			-- close the game
			if gui.MenuItem_Bool("Quit") then
				love.event.quit()
			end
			
			gui.EndMenu()
		end
		
		------------------------------------------------ windows menu
		if gui.BeginMenu("Windows") then
			
			gui.SeparatorText("ImGui")
			-- open main window
			if gui.MenuItem_Bool("Main window", nil, imgui.open.main) then
				imgui.open.main = not imgui.open.main
			end
			-- open inspect overlay
			if gui.MenuItem_Bool("Inspect overlay", nil, imgui.open.overlay) then
				imgui.open.overlay = not imgui.open.overlay
			end
			-- open inspector window
			if gui.MenuItem_Bool("Inspector", nil, imgui.open.inspector) then
				imgui.open.inspector = not imgui.open.inspector
			end
			-- open tests runner window
			if gui.MenuItem_Bool("Tests runner", nil, imgui.open.tests) then
				imgui.open.tests = not imgui.open.tests
			end
			-- open profiler window
			if gui.MenuItem_Bool("Profiler", nil, imgui.open.profiler) then
				imgui.open.profiler = not imgui.open.profiler
			end
			-- open docs window
			if gui.MenuItem_Bool("Documentation", nil, imgui.open.docs) then
				imgui.open.docs = not imgui.open.docs
			end
			-- open game canvas window
			if gui.MenuItem_Bool("Game canvas", nil, imgui.open.game) then
				imgui.open.game = not imgui.open.game
			end
			
			gui.Separator()
			-- open imgui demo
			if gui.MenuItem_Bool("ImGui demo", nil, imgui.open.demo) then
				imgui.open.demo = not imgui.open.demo
			end
			
			gui.SeparatorText("yui")
			-- open debug menu button
			if gui.MenuItem_Bool("Debug menu button", nil, debug_yui_debug_button) then
				debug_yui_debug_button = not debug_yui_debug_button
			end
			
			gui.EndMenu()
		end
		
		------------------------------------------------ scenes menu
		if gui.BeginMenu("Scenes") then
			local list = files.listdir("scenes")
			for i=1, #list do
				local name = string.remove(list[i], "scenes/", ".lua")
				local open = table.find(scenes, "path", name) ~= nil
				
				if gui.MenuItem_Bool(name, nil, open) then
					scene.set(name)
				end
			end
			
			gui.EndMenu()
		end
		
		------------------------------------------------ about button
		if gui.MenuItem_Bool("?") then
			gui.SetNextWindowPos(gui.ImVec2_Float(windowwidth/2,windowheight/2), nil, gui.ImVec2_Float(0.5, 0.5))
			gui.OpenPopup_Str("onee "..onee.version)
		end
		
		-- about dialog
		if gui.BeginPopupModal("onee "..onee.version, nil, gui.love.WindowFlags("AlwaysAutoResize", "NoMove", "NoResize")) then
			gui.Text(string.format("love2d %s (%s, %s)\n\ni'm freaks", love._version, _VERSION, string.left(jit.version, 13)))
			gui.Separator()
			if gui.Button("me too", gui.ImVec2_Float(120, 0)) then
				gui.CloseCurrentPopup()
			end
			
			gui.EndPopup()
		end
		
		------------------------------------------------ right corner fps and dt
		if rightalign("fps") then
			gui.TextColored(gui.ImVec4_Float(0.5,0.5,0.5,1), "v"..onee.version)
			gui.SameLine()
			gui.Text(string.format("%d FPS %02.2fms", love.timer.getFPS(), 1000*love.timer.getAverageDelta()))
			if gui.BeginItemTooltip() then
				gui.Text(string.format("%02.2f FPS %02.2fms", 1/love.timer.getDelta(), 1000*love.timer.getDelta()))
				--gui.Text("v"..onee.version)
				local date = os.date("*t")
				gui.Text(string.format("%d-%02d-%02d %02d:%02d:%02d", date.year, date.month, date.day, date.hour, date.min, date.sec))
				
				gui.Text(string.format("internet time @%d", date.beats))
				gui.ProgressBar(date.beats - math.floor(date.beats), gui.ImVec2_Float(128,1),"")
				
				gui.EndTooltip()
			end
			
			rightalign_end()
		end
		
		gui.EndMainMenuBar()
	end
	
end

---------------------------------------------------------------- INSPECT OVERLAY
local collision_inspect = {}
local inspect_popup

function imgui.window.overlay()
	local open = _bool(imgui.open.overlay)
	
	------------------------------------------------ TOP RIGHT PANEL
	gui.SetNextWindowPos(gui.ImVec2_Float(windowwidth-8, 26), nil, gui.ImVec2_Float(1, 0))
	
	if gui.Begin("quick overlay", open, gui.love.WindowFlags("NoDecoration", "AlwaysAutoResize", "NoNav")) then
		
		-- make it above every window when hovered, right click to close
		if gui.IsWindowHovered(gui.love.HoveredFlags("RectOnly")) then 
			gui.SetWindowFocus_Nil()
			
			if gui.IsMouseClicked(1) then open[0] = false end
		end
		
		gui.Text("Mouse: "..love.mouse.getX()..", "..love.mouse.getY())
		gui.Text("Instances: "..table.length(instances))
		
		gui.End()
	end
	
	------------------------------------------------ TOOLTIPS FOR INSTANCE COLLISIONS
	local self = {collision = true, active = true, x = love.mouse.getX(), y = love.mouse.getY()}
	local check, col
	
	local function collisions_recursively(arg, id, object)
		for k, v in pairs(arg) do
			if type(v) == "table" then
				if v.collision == true then
					check, col = collision.check(self, object, v.name)
					if check then collision_inspect[col.instance..col.name] = col end
				-- skip 3d models, they cause a stack overflow
				elseif v.model ~= true then
					collisions_recursively(v, id, instances[id].object)
				end
			end
		end
	end
	
	-- TODO: maybe loop through objects instead?
	for id, instance in pairs(instances) do
		collisions_recursively(instance, id, instance.object)
	end
	
	-- the tooltip itself
	if table.length(collision_inspect) ~= 0 and not gui.IsWindowHovered(gui.love.HoveredFlags("AnyWindow")) then
		
		if gui.BeginTooltip() then
			for k,v in pairs(collision_inspect) do
				if v.collision == true then
					gui.Text(v.instance)
					gui.SameLine()
					gui.TextColored(gui.ImVec4_Float(0.5,0.5,0.5,1), "("..v.name..")")
				end
				
			end
			gui.EndTooltip()
		end
		
		if gui.IsMouseClicked(1) then
			inspect_popup = collision_inspect 
			gui.OpenPopup_Str("inspect_popup")
		end
	end
	
	-- pop-up menu on right click
	if gui.BeginPopup("inspect_popup") then
		for k,v in pairs(inspect_popup) do
			gui.SeparatorText(v.instance)
			gui.SameLine()
			gui.TextColored(gui.ImVec4_Float(0.5,0.5,0.5,1), "("..v.name..")")
			
			if gui.BeginTable("##"..string.md5(v), 1, gui.love.TableFlags("Borders")) then
				gui.TableSetupColumn("1")
				gui.TableNextRow()
				gui.TableSetColumnIndex(0)
				gui.TextColored(gui.ImVec4_Float(0.5,0.5,0.5,1), "x, y: "..math.floor(v.x)..", "..math.floor(v.y))
				gui.EndTable()
			end
			
			if gui.MenuItem_Bool("Open inspector") then
				instance_selected = v.instance
				imgui.open.inspector = true
			end
			if gui.MenuItem_Bool("Delete instance") then
				instance.delete(v.instance)
			end
			
		end
		gui.EndPopup()
	end
	
	collision_inspect = {}
	
	--check sprites like this too by checking nearest xy to cursor within range or maybe point in rect check
	
	imgui.open.overlay = open[0]
end

---------------------------------------------------------------- MAIN WINDOW
local graph_fps, graph_dt, graph_ram = table.fill(0, 60), table.fill(0, 60), table.fill(0, 100)
local graph_update = true

function imgui.window.main()
	local open = _bool(imgui.open.main)
	
	if gui.Begin(onee.version.."###main", open) then
		
		------------------------------------------------ FIRST ROW
		-- reload button
		if gui.Button("Reload") then
			love.event.quit("restart")
		end
		-- reset scene button
		gui.SameLine()
		if gui.Button("Reset scene") then
			scene.set(scenes[1].path)
		end
		-- to init scene
		gui.SameLine()
		if gui.Button("Re-init") then
			scene.set("init")
		end
		-- advance frame controls
		gui.SameLine()
		if gui.Button(stepframe and "|>" or "||") then
			stepframe = not stepframe
			onee.allow_update = not onee.allow_update
		end
		if stepframe then -- (only show these when frozen)
			gui.SameLine()
			if gui.Button(">") then
				old_frame = frames
				advance_frame = true
			end
			gui.SameLine()
			gui.Text("STEP FRAME")
		end
		
		if advance_frame then -- (one frame forward)
			onee.allow_update = true
			if frames > old_frame then
				onee.allow_update = false
				advance_frame = false
			end
		end
		
		------------------------------------------------ CHECKBOXES AND MISC
		local _v = _bool(debug_draw_collisions, true)
		gui.Checkbox("Draw collisions", _v)
		debug_draw_collisions = _v[0]
		
		local _v = _bool(debug_draw_sprites, true)
		gui.Checkbox("Draw sprite BBoxes", _v)
		debug_draw_sprites = _v[0]
		
		local _v = _bool(imgui.open.overlay)
		gui.Checkbox("Show inspect overlay", _v)
		imgui.open.overlay = _v[0]
		
		local _v = _bool(debug_yui)
		gui.Checkbox("yui debug", _v)
		debug_yui = _v[0]
		
		local _v = _bool(input.ignore)
		gui.Checkbox("Ignore input", _v)
		input.ignore = _v[0]
		
		------------------------------------------------ SETTINGS HEADER
		if gui.CollapsingHeader_BoolPtr("Settings") then
			gui.SeparatorText("Window")
			
			local _v = _float(window.scale)
			gui.SetNextItemWidth(128)
			if gui.InputFloat("scale", _v, 1, 1) then
				window.scale = _v[0]
			end
			
			local _v = _float(window.internal)
			gui.SetNextItemWidth(128)
			if gui.InputFloat("internal scale", _v, 1, 1) then
				window.internal = math.clamp(0.01, _v[0], inf)
				window.update()
			end
			
			gui.SetNextItemWidth(128)
			if gui.BeginCombo("scaling mode", string.lower(table.find(window.SCALING, window.mode))) then
				if gui.Selectable_Bool("none") then window.mode = window.SCALING.NONE; window.update() end
				if gui.Selectable_Bool("integer") then window.mode = window.SCALING.INTEGER; window.update() end
				gui.EndCombo()
			end
			
			gui.Separator()
			local _v = _int({onee.width, onee.height})
			gui.SetNextItemWidth(128+64)
			if gui.DragInt2("canvas width & height", _v) then
				onee.width = _v[0]
				onee.height = _v[1]
			end
			
			if gui.Button("Update window") then
				window.update()
			end
		end
		
		------------------------------------------------ SCENE STACK HEADER
		if gui.CollapsingHeader_BoolPtr("Scene stack") then
			
			-- objects table
			if gui.BeginTable("scene_stats_objects", 2) then
				gui.TableSetupColumn("instances")
				gui.TableSetupColumn("objects")
				gui.TableHeadersRow()
				
				gui.TableNextRow()
				gui.TableSetColumnIndex(0); gui.Text(tostring(table.length(instances)))
				gui.TableSetColumnIndex(1); gui.Text(tostring(table.length(objects)))
				
				gui.EndTable()
			end
			-- object summary tree
			if gui.TreeNodeEx_Str("Objects summary", gui.love.TreeNodeFlags("SpanAvailWidth")) then
				if gui.BeginTable("object_counts", 2, gui.love.TableFlags("RowBg", "BordersInnerV")) then
					gui.TableSetupColumn("k")
					gui.TableSetupColumn("count")
					
					for k,v in kpairs(objects) do
						gui.TableNextRow()
						gui.TableSetColumnIndex(0); gui.Text(tostring(k))
						gui.TableSetColumnIndex(1); gui.Text(tostring(v.instances))
					end
					
					gui.EndTable()
				end
				gui.TreePop()
			end
			gui.Separator()
			
			--assets table
			if gui.BeginTable("scene_stats_assets", 3) then
				gui.TableSetupColumn("assets")
				gui.TableSetupColumn("sprites")
				gui.TableSetupColumn("models")
				gui.TableHeadersRow()
				
				gui.TableNextRow()
				gui.TableSetColumnIndex(0); gui.Text(tostring(table.length(assets)))
				gui.TableSetColumnIndex(1); gui.Text(tostring(table.length(sprites)))
				gui.TableSetColumnIndex(2); gui.Text(tostring(table.length(models)))
				
				gui.EndTable()
			end
			
			gui.Separator()
			
		end
		
		------------------------------------------------ GENERAL STATS HEADER
		if gui.CollapsingHeader_BoolPtr("General stats") then
			
			-- window size
			gui.Text("Window size: "..windowwidth.."x"..windowheight)
			if gui.BeginItemTooltip() then
				gui.Text("including DPI: "..love.graphics.getPixelWidth().."x"..love.graphics.getPixelHeight().." x"..love.window.getDPIScale())
				gui.Text("Gamma correct: "..tostring(love.graphics.isGammaCorrect()))
				
				gui.EndTooltip()
			end
			
			------------------------ newly declared globals tree
			if gui.TreeNodeEx_Str("Newly declared globals", gui.love.TreeNodeFlags("SpanAvailWidth")) then
				if gui.BeginTable("stats_globals", 1, gui.love.TableFlags("RowBg", "BordersInnerV")) then
					gui.TableSetupColumn("k")
					
					for k,v in kpairs(debug.globals) do
						gui.TableNextRow()
						gui.TableSetColumnIndex(0)
						gui.Text(tostring(v))
					end
					
					gui.EndTable()
				end
				gui.TreePop()
			end
			
			------------------------ loaded requires tree
			if gui.TreeNodeEx_Str("package.loaded", gui.love.TreeNodeFlags("SpanAvailWidth")) then
				if gui.BeginTable("stats_package_loaded", 1, gui.love.TableFlags("RowBg", "BordersInnerV")) then
					gui.TableSetupColumn("k")
					
					for k in kpairs(package.loaded) do
						gui.TableNextRow()
						gui.TableSetColumnIndex(0)
						gui.Text(tostring(k))
					end
					
					gui.EndTable()
				end
				gui.TreePop()
			end
			
			------------------------ love.graphics.getRendererInfo() tree
			if gui.TreeNodeEx_Str("love.graphics.getRendererInfo()", gui.love.TreeNodeFlags("SpanAvailWidth")) then
				local renderer = {}
				renderer.name, renderer.version, renderer.vendor, renderer.device = love.graphics.getRendererInfo()
				
				if gui.BeginTable("stats_renderer", 2, gui.love.TableFlags("RowBg", "BordersInnerV", "Resizable")) then
					gui.TableSetupColumn("k")
					gui.TableSetupColumn("v")
					
					for k,v in kpairs(renderer) do
						gui.TableNextRow()
						gui.TableSetColumnIndex(0); gui.Text(k)
						gui.TableSetColumnIndex(1); gui.Text(tostring(v))
					end
					
					gui.EndTable()
				end
				gui.TreePop()
			end
			
			------------------------ love.graphics.getSystemLimits() tree
			if gui.TreeNodeEx_Str("love.graphics.getSystemLimits()", gui.love.TreeNodeFlags("SpanAvailWidth")) then
				if gui.BeginTable("stats_systemlimits", 2, gui.love.TableFlags("RowBg", "BordersInnerV")) then
					gui.TableSetupColumn("k")
					gui.TableSetupColumn("v")
					
					for k,v in kpairs(love.graphics.getSystemLimits()) do
						gui.TableNextRow()
						gui.TableSetColumnIndex(0); gui.Text(k)
						gui.TableSetColumnIndex(1); gui.Text(tostring(v))
					end
					
					gui.EndTable()
				end
				gui.TreePop()
			end
			
			------------------------ love.graphics.getSupported() tree
			if gui.TreeNodeEx_Str("love.graphics.getSupported()", gui.love.TreeNodeFlags("SpanAvailWidth")) then
				gui.SeparatorText("love.graphics.getSupported()")
				if gui.BeginTable("stats_graphicsfeatures", 2, gui.love.TableFlags("RowBg", "BordersInnerV")) then
					gui.TableSetupColumn("k")
					gui.TableSetupColumn("v")
					
					for k,v in kpairs(love.graphics.getSupported()) do
						gui.TableNextRow()
						gui.TableSetColumnIndex(0); gui.Text(k)
						gui.TableSetColumnIndex(1); gui.Text(tostring(v))
					end
					
					gui.EndTable()
				end
				
				gui.SeparatorText("love.graphics.getTextureTypes()")
				if gui.BeginTable("stats_texturetypes", 2, gui.love.TableFlags("RowBg", "BordersInnerV")) then
					gui.TableSetupColumn("k")
					gui.TableSetupColumn("v")
					
					for k,v in kpairs(love.graphics.getTextureTypes()) do
						gui.TableNextRow()
						gui.TableSetColumnIndex(0); gui.Text(k)
						gui.TableSetColumnIndex(1); gui.Text(tostring(v))
					end
					
					gui.EndTable()
				end
				
				gui.SeparatorText("love.graphics.getImageFormats()")
				if gui.BeginTable("stats_imageformats", 2, gui.love.TableFlags("RowBg", "BordersInnerV")) then
					gui.TableSetupColumn("k")
					gui.TableSetupColumn("v")
					
					for k,v in kpairs(love.graphics.getImageFormats()) do
						gui.TableNextRow()
						gui.TableSetColumnIndex(0); gui.Text(k)
						gui.TableSetColumnIndex(1); gui.Text(tostring(v))
					end
					
					gui.EndTable()
				end
				
				gui.SeparatorText("love.graphics.getCanvasFormats()")
				if gui.BeginTable("stats_canvasformats", 2, gui.love.TableFlags("RowBg", "BordersInnerV")) then
					gui.TableSetupColumn("k")
					gui.TableSetupColumn("v")
					
					for k,v in kpairs(love.graphics.getCanvasFormats()) do
						gui.TableNextRow()
						gui.TableSetColumnIndex(0); gui.Text(k)
						gui.TableSetColumnIndex(1); gui.Text(tostring(v))
					end
					
					gui.EndTable()
				end
				gui.TreePop()
			end
			
		end
		
		------------------------------------------------ PERFORMANCE HEADER
		if gui.CollapsingHeader_BoolPtr("Performance") then
			
			local _v = _bool(graph_update, true)
			gui.Checkbox("Update graphs", _v)
			graph_update = _v[0]
			
			-- raw fps and dt table
			if graph_update then
				table.remove(graph_fps, 1); table.insert(graph_fps, 1/love.timer.getDelta())
				table.remove(graph_dt, 1); table.insert(graph_dt, 1000*love.timer.getDelta())
			end
			
			if gui.BeginTable("performance_fps", 2) then
				gui.TableSetupColumn("raw FPS")
				gui.TableSetupColumn("raw dt")
				gui.TableHeadersRow()
				
				gui.TableNextRow()
				gui.TableSetColumnIndex(0)
				gui.PlotLines_FloatPtr("", _float(graph_fps), #graph_fps, 0, string.format("%.2f", 1/love.timer.getDelta()), framerate/2, framerate, gui.ImVec2_Float(-1,30))
				gui.TableSetColumnIndex(1)
				gui.PlotLines_FloatPtr("", _float(graph_dt), #graph_dt, 0, string.format("%.2fms", 1000*love.timer.getDelta()), nil, nil, gui.ImVec2_Float(-1,30))
				
				gui.EndTable()
			end
			
			-- ram table
			local texture = love.graphics.getStats().texturememory/1024/1024
			local gc = collectgarbage("count")/1024
			local total = texture + gc
			
			if graph_update then
				table.remove(graph_ram, 1); table.insert(graph_ram, total)
			end
			
			if gui.BeginTable("performance_ram", 2) then
				gui.TableSetupColumn("texture RAM")
				gui.TableSetupColumn("GC")
				gui.TableHeadersRow()
				
				gui.TableNextRow()
				gui.TableSetColumnIndex(0); gui.Text(string.format("%.2fMB", texture))
				gui.TableSetColumnIndex(1); gui.Text(string.format("%.2fMB", gc))
				
				gui.EndTable()
			end
			
			gui.PlotLines_FloatPtr("", _float(graph_ram), #graph_ram, 0, string.format("total %.2fMB\n max: %.2fMB", total, table.sortv(graph_ram)[#graph_ram]), nil, nil, gui.ImVec2_Float(-1,30))
			
			-- timers table
			if gui.BeginTable("performance_time", 3) then
				gui.TableSetupColumn("seconds")
				gui.TableSetupColumn("frames")
				gui.TableSetupColumn("elapsed")
				gui.TableHeadersRow()
				
				gui.TableNextRow()
				gui.TableSetColumnIndex(0); gui.Text(string.format("%.2f", ms))
				gui.TableSetColumnIndex(1); gui.Text(tostring(frames))
				gui.TableSetColumnIndex(2); gui.Text(string.format("%.2f", love.timer.getTime()))
				if gui.BeginItemTooltip() then
					local timer = love.timer.getTime()
					gui.Text(string.format("%dh %02dm %02ds %02dms", timer/3600, math.floor(timer/60)%60, math.floor(timer)%60, math.floor(timer*100)%100))
					gui.Text(tostring(love.timer.getTime()))
					gui.Text("unix timestamp: "..os.time())
					gui.Text("os.clock(): "..os.clock())
					gui.EndTooltip()
				end
				
				gui.EndTable()
			end
			
			gui.Separator()
			------------------------ love.graphics.getStats() tree
			if gui.TreeNodeEx_Str("love.graphics.getStats()", gui.love.TreeNodeFlags("SpanAvailWidth")) then
				if gui.BeginTable("performance_stats", 2, gui.love.TableFlags("RowBg", "BordersInnerV")) then
					gui.TableSetupColumn("k")
					gui.TableSetupColumn("v")
					
					for k,v in kpairs(love.graphics.getStats()) do
						if k ~= "texturememory" then
							gui.TableNextRow()
							gui.TableSetColumnIndex(0); gui.Text(k)
							gui.TableSetColumnIndex(1); gui.Text(tostring(v))
						end
					end
					
					gui.EndTable()
				end
				gui.TreePop()
			end
			
		end
		
		------------------------------------------------ INPUT HEADER
		if gui.CollapsingHeader_BoolPtr("Input: "..input.mode.."###input") then
			-- mouse table
			if gui.BeginTable("input_mouse", 3, gui.love.TableFlags("RowBg", "BordersInnerV")) then
				gui.TableSetupColumn("")
				gui.TableSetupColumn("mouse x")
				gui.TableSetupColumn("mouse y")
				gui.TableHeadersRow()
				
				gui.TableNextRow()
				gui.TableSetColumnIndex(0); gui.Text("window")
				gui.TableSetColumnIndex(1); gui.Text(tostring(mousex))
				gui.TableSetColumnIndex(2); gui.Text(tostring(mousey))
				
				local x, y = window.mouse()
				gui.TableNextRow()
				gui.TableSetColumnIndex(0); gui.Text("game canvas")
				gui.TableSetColumnIndex(1); gui.Text(tostring(x))
				gui.TableSetColumnIndex(2); gui.Text(tostring(y))
				
				gui.EndTable()
			end
			
			-- current inputs table
			gui.Separator()
			if gui.BeginTable("input_keys", 5, gui.love.TableFlags("RowBg", "BordersInnerV")) then
				gui.TableSetupColumn("")
				gui.TableSetupColumn("held")
				gui.TableSetupColumn("time")
				gui.TableSetupColumn("pressed")
				gui.TableSetupColumn("released")
				gui.TableHeadersRow()
				
				for k,v in kpairs(config.input.keyboard) do
					gui.TableNextRow()
					gui.TableSetColumnIndex(0)
					gui.Text(k)
					gui.TableSetColumnIndex(1)
					gui.TextColored(input[k] and gui.ImVec4_Float(0,1,0,1) or gui.ImVec4_Float(1,0,0,1),tostring(input[k]))
					gui.TableSetColumnIndex(2)
					gui.Text(tostring(input.time[k]))
					gui.TableSetColumnIndex(3)
					gui.TextColored(input.pressed[k] and gui.ImVec4_Float(0,1,0,1) or gui.ImVec4_Float(1,0,0,1),tostring(input.pressed[k]))
					gui.TableSetColumnIndex(4)
					gui.TextColored(input.released[k] and gui.ImVec4_Float(0,1,0,1) or gui.ImVec4_Float(1,0,0,1),tostring(input.released[k]))
				end
				
				gui.EndTable()
			end
			
		end
		
		------------------------------------------------ GLOBAL VARIABLES
		imgui.table(_G, "Global variables")
		imgui.table(debug.getregistry(), "debug.getregistry()")
		
		gui.SeparatorText("curse of the eternal placeholders")
		imgui.table(scenes, "scene stack")
		imgui.table(scenes, "scene stack 2!!", {fancy=true,imagescale=1})
		imgui.table(onee.persist, "persist scene", {fancy=true,imagescale=1})
		
		gui.End()
	end
	
	imgui.open.main = open[0]
end

---------------------------------------------------------------- INSPECTOR

local simple, edit
local asset_scale = 1
local new_object, new_data

function imgui.window.inspector()
	local open = _bool(imgui.open.inspector)
	local _simple = _bool(simple, false)
	local _edit = _bool(edit, false)
	
	if gui.Begin("Inspector", open) then
		
		if gui.BeginTabBar("", gui.love.TabBarFlags("TabListPopupButton", "Reorderable")) then
		
			-- (will still appear at the right side)
			if not simple then 
				gui.SameLine(gui.GetWindowWidth() - 170)
				gui.Checkbox("edit", _edit)
				edit = _edit[0]
			end
			gui.SameLine(gui.GetWindowWidth() - 110)
			gui.Checkbox("simple view", _simple)
			simple = _simple[0]
			
			------------------------------------------------ INSTANCES
			if gui.BeginTabItem("Instances") then
				if gui.BeginChild_Str("selector", nil, gui.love.ChildFlags("Border", "ResizeX")) then
					for k,v in kpairs(instances) do
						if gui.Selectable_Bool(tostring(k), instance_selected == k) then
							instance_selected = k
						end
					end
					
					gui.EndChild()
				end
				
				gui.SameLine()
				if gui.BeginChild_Str("selected") then
					local current = instances[instance_selected] or {}
					
					gui.SeparatorText(tostring(instance_selected or ""))
					
					if gui.Button("+") then
						new_object = ""
						new_data = {}
						gui.OpenPopup_Str("new_instance")
					end
					
					if gui.BeginPopup("new_instance") then
						gui.SeparatorText("Create instance")
						
						if gui.BeginCombo("object", new_object) then
							for k,v in kpairs(objects) do
								if gui.Selectable_Bool(tostring(k)) then new_object = k end
							end
							gui.EndCombo()
						end
						
						imgui.table(new_data, "instance data", {fancy = true, edit = true})
						
						if gui.Button("Add") and new_object ~= "" then
							instance.new(new_object, new_data)
							gui.CloseCurrentPopup()
						end
						
						gui.EndPopup()
					end
					
					gui.SameLine()
					if gui.Button("Delete") and current.instance then
						instance.delete(instance_selected)
						instance_selected = nil
					end
					
					gui.Separator()
					if gui.BeginChild_Str("properties") then
						imgui.table(current, "current", {fancy = not simple, nowindow = true, edit = edit})
						
						gui.EndChild()
					end
					
					gui.EndChild()
				end
				
				gui.EndTabItem()
			end
			
			------------------------------------------------ OBJECTS
			if gui.BeginTabItem("Objects") then
				if gui.BeginChild_Str("selector", nil, gui.love.ChildFlags("Border", "ResizeX")) then
					for k,v in kpairs(objects) do
						if gui.Selectable_Bool(tostring(k), object_selected == k) then
							object_selected = k
						end
					end
					
					gui.EndChild()
				end
					
				gui.SameLine()
				if gui.BeginChild_Str("selected") then
					local current = objects[object_selected] or {}
					
					gui.SeparatorText(tostring(object_selected or ""))
					
					if gui.Button("Delete") and current.object then
						object.delete(object_selected)
						object_selected = nil
					end
					
					gui.Separator()
					if gui.BeginChild_Str("properties") then
						imgui.table(current, "current", {fancy = not simple, nowindow = true, edit = edit})
						
						gui.EndChild()
					end
					
					gui.EndChild()
				end
				
				gui.EndTabItem()
			end
			
			------------------------------------------------ ASSETS
			if gui.BeginTabItem("Assets") then
				if gui.BeginChild_Str("selector", nil, gui.love.ChildFlags("Border", "ResizeX")) then
					for k,v in kpairs(assets) do
						if gui.Selectable_Bool(tostring(k), asset_selected == k) then
							asset_selected = k
						end
					end
					
					gui.EndChild()
				end
					
				gui.SameLine()
				if gui.BeginChild_Str("selected") then
					local current = assets[asset_selected] or {}
					
					gui.SeparatorText(tostring(asset_selected or ""))
					
					if gui.Button("Delete") and assets[asset_selected] then
						asset.delete(asset_selected)
						asset_selected = nil
					end
					
					gui.SameLine()
					local _v = _float(asset_scale)
					gui.SetNextItemWidth(140)
					gui.SliderFloat("", _v, 0.25, 5, "Image scale: "..math.floor((asset_scale*100)).."%%")
					asset_scale = _v[0]
					if gui.IsItemClicked(1) then asset_scale = 1 end
					
					gui.Separator()
					if gui.BeginChild_Str("properties") then
						imgui.table(current, "current", {fancy = not simple, nowindow = true, imagescale = asset_scale, edit = edit})
						
						gui.EndChild()
					end
					
					gui.EndChild()
				end
				
				gui.EndTabItem()
			end
			
			------------------------------------------------ SPRITES
			if gui.BeginTabItem("Sprites") then
				if gui.BeginChild_Str("selector", nil, gui.love.ChildFlags("Border", "ResizeX")) then
					for k,v in kpairs(sprites) do
						if gui.Selectable_Bool(tostring(k), sprite_selected == k) then
							sprite_selected = k
						end
					end
					
					gui.EndChild()
				end
					
				gui.SameLine()
				if gui.BeginChild_Str("selected") then
					local current = sprites[sprite_selected] or {}
					
					gui.SeparatorText(tostring(sprite_selected or ""))
					
					if gui.Button("Delete") and sprites[sprite_selected] then
						asset.delete(sprite_selected)
						sprite_selected = nil
					end
					
					gui.Separator()
					if gui.BeginChild_Str("properties") then
						imgui.table(current, "current", {fancy = not simple, nowindow = true, edit = edit})
						
						gui.EndChild()
					end
					
					gui.EndChild()
				end
				
				gui.EndTabItem()
			end
			
			------------------------------------------------ MODELS
			if gui.BeginTabItem("3D models") then
				if gui.BeginChild_Str("selector", nil, gui.love.ChildFlags("Border", "ResizeX")) then
					for k,v in kpairs(models) do
						if gui.Selectable_Bool(tostring(k), model_selected == k) then
							model_selected = k
						end
					end
					
					gui.EndChild()
				end
					
				gui.SameLine()
				if gui.BeginChild_Str("selected") then
					local current = models[model_selected] or {}
					
					gui.SeparatorText(tostring(model_selected or ""))
					
					if gui.Button("Delete") and models[model_selected] then
						asset.delete(model_selected)
						model_selected = nil
					end
					
					gui.Separator()
					if gui.BeginChild_Str("properties") then
						imgui.table(current, "current", {fancy = not simple, nowindow = true, edit = edit})
						
						gui.EndChild()
					end
					
					gui.EndChild()
				end
				
				gui.EndTabItem()
			end
			
			gui.EndTabBar()
		end
		
		gui.End()
	end
	
	imgui.open.inspector = open[0]
end

---------------------------------------------------------------- TEST SUITE

local test_current, test_last, test_success, test_summary, test_passes, test_errors, test_took

function imgui.window.tests()
	local open = _bool(imgui.open.tests)
	
	if gui.Begin("Tests runner", open) then
		-- test selector
		local tests = files.listdir("onee/_tests")
		if not test_current then 
			test_current = tests[1]
			test_current = string.remove(test_current, "onee/_tests/", ".lua")
		end
		if gui.BeginCombo("##tests", test_current) then
			for k, v in kpairs(tests) do
				v = string.remove(v, "onee/_tests/", ".lua")
				if gui.Selectable_Bool(v) then test_current = v end
			end
			gui.EndCombo()
		end
		
		-- run button
		gui.SameLine()
		if gui.Button("Run") and test_current then
			test_success, test_summary, test_passes, test_errors, test_took = debug.test(test_current)
			test_last = test_current
		end
		
		-- test overview
		if not test_last then gui.TextColored(gui.ImVec4_Float(0.5,0.5,0.5,1), "- :) -") end
		if test_last then
			gui.Text(test_last.." -"); gui.SameLine()
			if test_success then
				gui.TextColored(gui.ImVec4_Float(0,1,0,1), "PASSED")
			else
				gui.TextColored(gui.ImVec4_Float(1,0,0,1), "FAILED")
			end
			
			local ratio = (test_passes - test_errors) / test_passes
			gui.ProgressBar(ratio, gui.ImVec2_Float(gui.GetWindowWidth()-16,12), math.floor(ratio*100).."%")
			
			gui.TextColored(gui.ImVec4_Float(0,1,0,1), tostring(test_passes))
			gui.SameLine(); gui.Text("passes")
			gui.SameLine(); gui.TextColored(gui.ImVec4_Float(1,0,0,1), tostring(test_errors))
			gui.SameLine(); gui.Text("fails")
			gui.SameLine(); gui.TextColored(gui.ImVec4_Float(0.5,0.5,0.5,1), string.format("(took %.5f)", test_took))
			gui.Separator()
		end
		
		-- test summary
		if gui.BeginChild_Str("test summary") and test_last then
			for i=1, #test_summary do
				local test = test_summary[i]
				if not test.error then
					gui.Selectable_Bool(string.rep("    ", test.level-1)..test.name)
				else
					local message = string.tokenize(test.error, newline)
					local error, at = message[1], message[2] and string.trim(message[2]) or ""
					local filepath = string.tokenize(error, ":", 2)
					if string.find(filepath, test_last..".lua") then
						error = string.replace(error, filepath..":", " line ")
					end
					
					gui.TextColored(gui.ImVec4_Float(1,0,0,1), string.rep("  ", test.level)..test.name)
					gui.Text(string.rep("    ", test.level))
					gui.SameLine(); gui.TextWrapped(error)
					if at ~= "AT:" and at ~= "" then
						gui.Text(string.rep("    ", test.level))
						gui.SameLine(); gui.TextWrapped(at)
					end
				end
			end
			gui.EndChild()
		end
		gui.End()
	end
	
	imgui.open.tests = open[0]
end

---------------------------------------------------------------- DOCUMENTATION VIEWER

local file_current

function imgui.window.docs()
	local open = _bool(imgui.open.docs)
	
	if gui.Begin("Documentation", open) then
		
		if gui.Button("Generate") then
			docroc.all()
		end
		
		gui.SameLine()
		if gui.BeginCombo("##tests", file_current) then
			for k, v in kpairs(docs) do
				if gui.Selectable_Bool(k) then file_current = k end
			end
			gui.EndCombo()
		end
		
		gui.Separator()
		if file_current and gui.BeginChild_Str("docs") then
			for k,v in kpairs(docs[file_current]) do
				local current = v.tags
				
				if current["function"] then
					local func = current["function"][1]
					local params = current["param"]
					local returns = current["returns"]
					
					local label = func.name
					label = current["local"] and label.."  [local function]" or label.."  [function]"
					if gui.CollapsingHeader_BoolPtr(label) then
						local label = ""
						if params and #params ~= 0 then
							label = label.."("
							for i=1, #params do
								local param = params[i]
								label = param.optional and label.."["..param.name.."]" or label..param.name
								if i ~= #params then label = label..", " end
							end
							label = label..")"
						end
						if #label ~= 0 then gui.SeparatorText(label) end
						
						if (params and #params ~= 0) and gui.TreeNodeEx_Str("Parameters##"..func.name, gui.love.TreeNodeFlags("SpanAvailWidth")) then
							for i=1, #params do
								local param = params[i]
								local label = param.name
								label = param.type and label.."  ("..param.type..")" or label
								label = (param.optional and not param.default) and label.."  [optional]" or label
								label = (param.optional and param.default) and label.."  [optional : "..param.default.."]" or label
								
								gui.Bullet()
								gui.Text(label)
								if param.description then gui.TextWrapped(param.description) end
							end
							gui.Separator()
							gui.TreePop()
						end
						
						if (returns and #returns ~= 0) and gui.TreeNodeEx_Str("Returns##"..func.name, gui.love.TreeNodeFlags("SpanAvailWidth")) then
							for i=1, #returns do
								local ret = returns[i]
								local label = ret.name
								label = (ret.type and #ret.type ~= 0) and label.."  ("..ret.type..")" or label
								
								gui.Bullet()
								gui.Text(label)
								if ret.description then gui.TextWrapped(ret.description) end
							end
							gui.Separator()
							gui.TreePop()
						end
						
						if func.description then gui.TextWrapped(func.description) end
						
						gui.Separator()
					end
				
				elseif current["raw"] then
					local text = current["raw"]
					
					for i=1, #text do
						gui.TextWrapped(text[i]._raw)
					end
					gui.Separator()
				end
				
			end
			
			gui.EndChild()
		end
		
		gui.End()
	end
	
	imgui.open.docs = open[0]
end

---------------------------------------------------------------- PROFILER

local report, report_raw, deep_report = {}, {}, {}
local frame = 1; local root
local sorting, sortkey, sortdescending = "Time", "timer", true

function imgui.window.profiler()
	local open = _bool(imgui.open.profiler)
	
	if gui.Begin("Profiler", open) then
		if gui.BeginTabBar("", gui.love.TabBarFlags("Reorderable")) then
			
			------------------------------------------------ graph
			local flags = debug_profiler and gui.love.TabItemFlags("UnsavedDocument") or nil
			if gui.BeginTabItem("Graph", nil, flags) then
				local text = debug_profiler and "Stop" or "Record"
				if gui.Button(text) then
					debug_profiler = not debug_profiler
					debug.profiler_enable(debug_profiler)
					frame = 1
				end
				
				if not debug_profiler and #_prof.data_pretty == 0 then
					gui.TextColored(gui.ImVec4_Float(0.5,0.5,0.5,1), "- :) -")
				end
				if debug_profiler then
					gui.SameLine(); gui.Text("Recording...")
				end
				if not debug_profiler and #_prof.data_pretty ~= 0 then
					gui.SameLine()
					if gui.Button("Clear") then
						_prof.data, _prof.data_pretty = {}, {}
						report, report_raw = {}, {}
						collectgarbage()
						gui.EndChild()
					end
					gui.SameLine()
					gui.Text(string.format("Time spent: %.2f", _prof.stop - _prof.start))
					gui.SameLine()
					gui.TextColored(gui.ImVec4_Float(0.5,0.5,0.5,1), string.format("(%.2f to %.2f)", _prof.start, _prof.stop))
					
					report_raw = _prof.data
					report = _prof.data_pretty
					
					-- remove unfinished frames
					for i=1, #report do
						if report[i].name == "frame" then break end
						table.remove(report, 1)
					end
					for i=#report, 1, -1 do
						if report[i].name == "frame" and not report[i].stop then table.remove(report, i) break end
					end
					for i=1, #report do
						report[i].stop = report[i].stop or _prof.stop
						report[i].ramstop = report[i].ramstop or report[i].ramstart
					end
					
					root = root or report[frame]
					
					gui.Separator()
					if gui.Button("<-") then root = report[frame] end
					gui.SameLine(); gui.Text("...")
					
					gui.SetNextWindowBgAlpha(1)
					if gui.BeginChild_Str("frame", gui.ImVec2_Float(-1,-120), gui.love.ChildFlags("Border")) then
						
						local root_sorted = {}
						for i=root.id, #report_raw do
							if i > root.id and report_raw[i].level <= root.level then break end
							table.insert(root_sorted, report_raw[i])
						end
						root_sorted = table.sortby(root_sorted, "level")
						local max_level = root_sorted[#root_sorted] and root_sorted[#root_sorted].level or 0
						local min_level = root_sorted[1] and root_sorted[1].level or 0
						
						local maxx = gui.GetContentRegionMax().x + 10
						
						for i = min_level, max_level do
							gui.Text("")
							for j=root.id, #report_raw do
								if j > root.id and report_raw[j].level <= root.level then break end
								if report_raw[j].level == i then
									local node = report_raw[j]
									
									if node.type == "event" then
										local time = (node.stop - node.start)*1000
										local ram = (node.ramstop - node.ramstart)/1024
										
										ram = ram >= 0 and string.format("+%.4f", ram) or string.format("%.4f", ram)
										local label = string.format("%s (%.4fms %sMB)", node.name, time, ram)
										
										local maxx = gui.GetContentRegionMax().x + 10
										
										local w = math.map(node.stop, root.start, root.stop, -tick, maxx)
										local x = math.map(node.start, root.start, root.stop, -tick, maxx)
										w = w - x
										if w < 1.5 then w = 1.5 end
										
										gui.SameLine(maxx*(x/maxx))
										if gui.Button(node.name, gui.ImVec2_Float(maxx*(w/maxx),20)) then
											root = node
										end
										if gui.BeginItemTooltip() then
											gui.Text(node.name)
											gui.Separator()
											
											gui.EndTooltip()
										end
									end
									if node.type == "mark" then
										local x = math.map(node.start, root.start, root.stop, -tick, maxx)
										gui.SameLine(maxx*(x/maxx))
										gui.RadioButton_Bool("",true)
										if gui.BeginItemTooltip() then
											gui.Text(node.name)
											gui.Separator()
											gui.Text(string.format("at %.3f", node.start))
											
											gui.EndTooltip()
										end
									end
									
								end
							end
						end
						
						gui.EndChild()
					end
					
					if gui.BeginTabBar("frame graphs") then
						if gui.BeginTabItem("dt") then
							local graph = {}
							for i=1, #report do
								if report[i].type == "event" then
									table.insert(graph, (report[i].stop - report[i].start)*1000)
								end
							end
							gui.PlotLines_FloatPtr("", _float(graph), #graph, 0, string.format("min: %.3fms\navg: %.3fms\ncur: %.3fms", table.sortv(graph)[1], table.sortv(graph)[#graph], math.average(graph), graph[frame]), nil, nil, gui.ImVec2_Float(-1,64))
						gui.EndTabItem()
						end
						if gui.BeginTabItem("RAM") then
							local graph = {}
							for i=1, #report do
								if report[i].type == "event" then
									table.insert(graph, report[i].ramstop/1024)
								end
							end
							gui.PlotLines_FloatPtr("", _float(graph), #graph, 0, string.format("min: %.3fMB\navg: %.3fMB\ncur: %.3fMB", table.sortv(graph)[1], table.sortv(graph)[#graph], math.average(graph), graph[frame]), nil, nil, gui.ImVec2_Float(-1,64))
						gui.EndTabItem()
						end
					gui.EndTabBar()
					end
					
					gui.SetNextItemWidth(-48)
					local _v = _int(frame)
					gui.SliderInt("", _v, 1, #report, "frame "..frame.."/"..#report)
					if gui.IsItemEdited() then
						frame = _v[0]
						root = report[frame]
					end
					gui.SameLine(); if gui.Button("<") then 
						if frame > 1 then frame = frame - 1 end; root = report[frame]
					end
					gui.SameLine(); if gui.Button(">") then
						if frame < #report then frame = frame + 1 end; root = report[frame]
					end
				end
				
				gui.EndTabItem()
			end
			
			------------------------------------------------ tracing
			local flags = debug_profiler_deep and gui.love.TabItemFlags("UnsavedDocument") or nil
			if gui.BeginTabItem("Trace", nil, flags) then
				local text = debug_profiler_deep and "Stop" or "Record"
				if gui.Button(text) then
					debug_profiler_deep = not debug_profiler_deep
					debug.profiler_deep_enable(debug_profiler_deep)
				end
				
				if #profi.reports == 0 then
					gui.TextColored(gui.ImVec4_Float(0.5,0.5,0.5,1), "- :o -")
				end
				if debug_profiler_deep then
					gui.SameLine(); gui.Text("Recording...")
				end
				if not debug_profiler_deep and #profi.reports ~= 0 then
					gui.SameLine()
					gui.Text(string.format("Time spent: %.2f", profi.stopTime - profi.startTime))
					gui.SameLine()
					gui.TextColored(gui.ImVec4_Float(0.5,0.5,0.5,1), string.format("(%.2f to %.2f)", profi.startTime, profi.stopTime))
					
					gui.Separator()
					
					gui.AlignTextToFramePadding(); gui.Text("Sort by:")
					gui.SameLine(); gui.SetNextItemWidth(100)
					if gui.BeginCombo("##sort", sorting) then
						if gui.Selectable_Bool("File") then sorting = "File"; sortkey = "source" end
						if gui.Selectable_Bool("Function") then sorting = "Function"; sortkey = "name" end
						if gui.Selectable_Bool("Time") then sorting = "Time"; sortkey = "timer" end
						if gui.Selectable_Bool("Called") then sorting = "Called"; sortkey = "count" end
						gui.EndCombo()
					end
					gui.SameLine()
					local _v = _bool(sortdescending, true)
					gui.Checkbox("Descending", _v)
					sortdescending = _v[0]
					
					deep_report = copy(profi.reports)
					deep_report = table.sortby(deep_report, sortkey, sortdescending)
					
					gui.SetNextWindowBgAlpha(1)
					if gui.BeginTable("profiling_deep", 5, gui.love.TableFlags("BordersInnerV", "Resizable", "ScrollY", "ScrollX", "Reorderable")) then
						gui.TableSetupColumn("File")
						gui.TableSetupColumn("Function")
						gui.TableSetupColumn("Time")
						gui.TableSetupColumn("Relative")
						gui.TableSetupColumn("Called")
						gui.TableHeadersRow()

						for i=1, #deep_report do
							local report = deep_report[i]
							
							local file = report.source or "unknown"
							local line = (report.linedefined and report.linedefined ~= -1) and ":"..report.linedefined or ""
							local name = report.name or "unknown"
							local relative = report.relative or 0
							
							gui.TableNextRow()
							gui.TableSetColumnIndex(0)
							if file == "unknown" or file == "[C]" or string.find(file, "builtin") then
								gui.TextColored(gui.ImVec4_Float(0.5,0.5,0.5,1), file..line)
							else
								gui.Text(file..line)
							end
							gui.TableSetColumnIndex(1)
							if name == "anonymous" or name == "unknown" or name == "(for generator)" then
								gui.TextColored(gui.ImVec4_Float(0.5,0.5,0.5,1), name)
							else
								gui.Text(name)
							end
							gui.TableSetColumnIndex(2); gui.Text(string.format("%04.4fms", report.timer*1000))
							gui.TableSetColumnIndex(3); gui.Text(string.format("%.2f", relative).."%%")
							gui.TableSetColumnIndex(4); gui.Text(tostring(report.count))
						end
						gui.EndTable()
					end
				end
				gui.EndTabItem()
			end
			
			gui.EndTabBar()
		end
		gui.End()
	end
	
	imgui.open.profiler = open[0]
end

---------------------------------------------------------------- GAME CANVAS

function imgui.window.game()
	local open = _bool(imgui.open.game)
	
	if gui.Begin("the funny", open) then
		
		gui.Image(window.canvas, gui.ImVec2_Float(onee.width,onee.height))
		
		gui.End()
	end
	
	imgui.open.game = open[0]
end

---------------------------------------------------------------- IMGUI DEMO

function imgui.window.demo()
	local open = _bool(imgui.open.demo)
	
	gui.ShowDemoWindow(open)
	
	imgui.open.demo = open[0]
end

_prof.hook("imgui")