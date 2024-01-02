imgui = {
	window = {},
	open = {},
}

-- init
if love._os == "Windows" and debug_mode then 
	gui = require("src/libs/cimgui")
	
	gui.love.Init()
	gui.love.ConfigFlags("NavEnableKeyboard", "DockingEnable")
	
	imgui.open.menubar = true
	imgui.open.main = true
	imgui.open.inspector = true
end

-- main loop
function imgui.update(dt)
	if not gui then return end
	
	gui.love.Update(dt)
    gui.NewFrame()
end

function imgui.draw()
	if not gui then return end
	
	imgui.main()
    
    gui.Render()
    gui.love.RenderDrawLists()
end

-- control function
function imgui.main()
	if imgui.open.menubar then imgui.window.menubar() end
	
	if imgui.open.main then imgui.window.main() end
	
	if imgui.open.inspector then imgui.window.inspector() end
	
	if imgui.open.demo then imgui.window.demo() end
	
end

-- event redirection
function imgui.mousemoved(x, y, dx, dy, istouch)
	if not gui then return end
    gui.love.MouseMoved(x, y)
end
function imgui.mousepressed(x, y, button, istouch, presses)
	if not gui then return end
    gui.love.MousePressed(button)
end
function imgui.mousereleased(x, y, button, istouch)
	if not gui then return end
    gui.love.MouseReleased(button)
end
function imgui.wheelmoved(x, y)
	if not gui then return end
    gui.love.WheelMoved(x, y)
end
function imgui.keypressed(key, scancode, isrepeat)
	if not gui then return end
    gui.love.KeyPressed(key)
end
function imgui.keyreleased(key, scancode)
	if not gui then return end
    gui.love.KeyReleased(key)
end
function imgui.textinput(text)
	if not gui then return end
	gui.love.TextInput(text)
end

-- data types conversion
local ffi = require("ffi")

local function _convert(arg, default, type)
	local var = ffi.new(type.."[1]")
	var[0] = arg or default
	return var
end
local function _bool(arg, default) -- bool* pointer
	if not arg then return _convert(0, default, "bool") end -- nil workaround
	return _convert(arg, default, "bool")
end
local function _float(arg, default) -- float* pointer
	return _convert(arg, default, "float")
end
local function _char(arg, default) -- char* pointer
	if #arg == 0 then arg = "." end -- empty string workaround
	local var = ffi.new("char[?]", #arg+1)
	ffi.copy(var, arg or "")
	return var
end

---------------------------------------------------------------- "simple" table browser
function imgui.table(arg, name, level)
	local level = level or 0
	
	if level == 0 then
		if gui.CollapsingHeader_BoolPtr(name) then
			if gui.BeginChild_Str(name, nil, gui.love.ChildFlags("Border", "ResizeY")) then
				imgui.table_types(arg, name, 1)
				
				gui.EndChild()
			end
		end
	elseif level == 1 then
		if gui.CollapsingHeader_BoolPtr(name) then
			if gui.BeginChild_Str(name, nil, gui.love.ChildFlags("Border", "AutoResizeY")) then
				imgui.table_types(arg, name, 2)
				
				gui.EndChild()
			end
		end
	elseif level == 2 then
		if gui.TreeNodeEx_Str(name, gui.love.TreeNodeFlags("SpanAvailWidth")) then
			imgui.table_types(arg, name, 2)
			gui.Separator()
			
			gui.TreePop()
		end
	end
	
end

function imgui.table_types(arg, name, level)
	if table.length(arg) == 0 then gui.TextColored(gui.ImVec4_Float(0.5,0.5,0.5,1), "- empty :) -") return end
	
	for k,v in kpairs(arg) do
		if type(k) == "table" then imgui.table(k, tostring(k), level) end
		if type(k) ~= "table" then
			if not v then imgui.table_entry(k, nil, name) end
			if v then
				if type(v) == "table" then imgui.table(v, tostring(k), level) end
				if type(v) ~= "table" then imgui.table_entry(k, v, name) end
			end
		end
	end
end

function imgui.table_entry(k, v)
	if not v then gui.Text(tostring(k)) end
	if v then 
		if type(v) ~= "userdata" then gui.Text(tostring(k)..": "..tostring(v)) end
		if type(v) == "userdata" then
			-- attempt to make sure we're in assets
			if type(k) == "number" and v:type() == "Image" then
				gui.Image(v, gui.ImVec2_Float(v:getDimensions()))
			else
				gui.Text(tostring(k)..": "..tostring(v))
			end
		end
	end
end

---------------------------------------------------------------- MENU BAR

function imgui.window.menubar()
	
	if gui.BeginMainMenuBar() then
		
		------------------------------------------------ windows menu
		if gui.BeginMenu("Windows") then
			
			-- open main window
			if gui.MenuItem_Bool("Main window") then
				imgui.open.main = true
			end
			-- open inspector window
			if gui.MenuItem_Bool("Inspector") then
				imgui.open.inspector = true
			end
			-- open imgui demo
			if gui.MenuItem_Bool("ImGui demo") then
				imgui.open.demo = true
			end
			--
			gui.Separator()
			-- toggle debug mode
			local _v = _bool(debug_mode, true)
			gui.Checkbox("Debug mode", _v)
			debug_mode = _v[0]
			-- close the game
			if gui.MenuItem_Bool("Quit") then
				love.event.quit()
			end
			
			gui.EndMenu()
		end
		
		------------------------------------------------ about button
		if gui.MenuItem_Bool("?") then
			gui.SetNextWindowPos(gui.ImVec2_Float(windowwidth/2,windowheight/2), nil, gui.ImVec2_Float(0.5, 0.5))
			gui.OpenPopup_Str("")
		end
		
		-- about dialog
		if gui.BeginPopupModal("", nil, gui.love.WindowFlags("AlwaysAutoResize", "NoMove", "NoResize")) then
			gui.Text("i'm freaks")
			gui.Separator()
			if gui.Button("me too", gui.ImVec2_Float(120, 0)) then
				gui.CloseCurrentPopup()
			end
			
			gui.EndPopup()
		end
		
		------------------------------------------------ right corner fps and dt
		gui.SameLine(windowwidth-120)
		gui.Text(love.timer.getFPS().." FPS "..math.round(1000*love.timer.getAverageDelta(),2).."ms")
		
		gui.EndMainMenuBar()
	end
	
end

---------------------------------------------------------------- MAIN WINDOW

local freeze = false; local advance_frame = false; local old_frame

function imgui.window.main()
	local open = _bool(imgui.open.main)
	
	if gui.Begin(version, open) then
		
		------------------------------------------------ FIRST ROW
		-- reload button
		if gui.Button("Reload") then
			love.event.quit("restart")
		end
		-- reset scene button
		gui.SameLine()
		if gui.Button("Reset scene") then
			scenes.set("init")
		end
		-- advance frame controls
		gui.SameLine()
		if gui.Button(freeze and "|>" or "||") then
			freeze = not freeze
			allow_update = not allow_update
		end
		if freeze then -- (only show these when frozen)
			gui.SameLine()
			if gui.Button(">") then
				old_frame = frames
				advance_frame = true
			end
			gui.SameLine()
			gui.Text("FROZEN")
		end
		
		if advance_frame then -- (one frame forward)
			allow_update = true
			if frames > old_frame then
				allow_update = false
				advance_frame = false
			end
		end
		
		------------------------------------------------ CHECKBOXES AND MISC
		local _v = _bool(debug_draw_collisions, true)
		gui.Checkbox("Draw collisions", _v)
		debug_draw_collisions = _v[0]
		
		------------------------------------------------ GENERAL STATS HEADER
		if gui.CollapsingHeader_BoolPtr("General stats") then
			
			-- window size
			gui.Text("Window size: "..windowwidth.."x"..windowheight)
			gui.Separator()
			
			-- objects table
			if gui.BeginTable("scene_stats_objects", 2, gui.love.TableFlags("RowBg", "BordersInnerV")) then
				gui.TableSetupColumn("1")
				gui.TableSetupColumn("2")
				
				gui.TableNextRow()
				gui.TableSetColumnIndex(0); gui.Text("objects")
				gui.TableSetColumnIndex(1); gui.Text(tostring(table.length(objects)))
				
				gui.TableNextRow()
				gui.TableSetColumnIndex(0); gui.Text("instances")
				gui.TableSetColumnIndex(1); gui.Text(tostring(table.length(instances)))
				
				gui.EndTable()
			end
			gui.Separator()
			
			--assets table
			if gui.BeginTable("scene_stats_assets", 2, gui.love.TableFlags("RowBg", "BordersInnerV")) then
				gui.TableSetupColumn("1")
				gui.TableSetupColumn("2")
				
				gui.TableNextRow()
				gui.TableSetColumnIndex(0); gui.Text("assets")
				gui.TableSetColumnIndex(1); gui.Text(tostring(table.length(assets)))
				
				gui.TableNextRow()
				gui.TableSetColumnIndex(0); gui.Text("sprites")
				gui.TableSetColumnIndex(1); gui.Text(tostring(table.length(sprites)))
				
				gui.TableNextRow()
				gui.TableSetColumnIndex(0); gui.Text("models")
				gui.TableSetColumnIndex(1); gui.Text(tostring(table.length(models)))
				
				gui.EndTable()
			end
			
		end
		
		------------------------------------------------ PERFORMANCE HEADER
		if gui.CollapsingHeader_BoolPtr("Performance") then
			
			-- raw fps and dt table
			if gui.BeginTable("performance_fps", 2) then
				gui.TableSetupColumn("raw FPS")
				gui.TableSetupColumn("raw dt")
				gui.TableHeadersRow()
				
				gui.TableNextRow()
				gui.TableSetColumnIndex(0)
				gui.Text(tostring(math.round(fps,2)))
				gui.TableSetColumnIndex(1)
				gui.Text(math.round(1000*dt,2).."ms")
				
				gui.EndTable()
			end
			
			-- timers table
			if gui.BeginTable("performance_time", 3) then
				gui.TableSetupColumn("seconds")
				gui.TableSetupColumn("frames")
				gui.TableSetupColumn("elapsed")
				gui.TableHeadersRow()
				
				gui.TableNextRow()
				gui.TableSetColumnIndex(0)
				gui.Text(tostring(math.round(ms,2)))
				gui.TableSetColumnIndex(1)
				gui.Text(tostring(frames))
				gui.TableSetColumnIndex(2)
				gui.Text(tostring(math.round(love.timer.getTime(),2)))
				
				gui.EndTable()
			end
			
			-- ram and garbage collector table
			if gui.BeginTable("performance_ram", 2) then
				local stats = love.graphics.getStats()
				
				gui.TableSetupColumn("texture RAM")
				gui.TableSetupColumn("GC")
				gui.TableHeadersRow()
				
				gui.TableNextRow()
				gui.TableSetColumnIndex(0)
				gui.Text(math.round(stats.texturememory/1024/1024,2).."MB")
				gui.TableSetColumnIndex(1)
				gui.Text(math.round(collectgarbage("count")/1024,2).."MB")
				
				gui.EndTable()
			end
			
			------------------------ love.graphics.getStats() tree
			if gui.TreeNodeEx_Str("love.graphics.getStats()", gui.love.TreeNodeFlags("SpanAvailWidth")) then
				local stats = love.graphics.getStats()
				
				if gui.BeginTable("performance_stats", 2, gui.love.TableFlags("RowBg", "BordersInnerV")) then
					gui.TableSetupColumn("1")
					gui.TableSetupColumn("2")
					
					for k,v in kpairs(stats) do
						if k ~= "texturememory" then
							gui.TableNextRow()
							gui.TableSetColumnIndex(0)
							gui.Text(k)
							gui.TableSetColumnIndex(1)
							gui.Text(tostring(v))
						end
					end
					
					gui.EndTable()
				end
				gui.TreePop()
			end
			
			------------------------ love.graphics.getRendererInfo() tree
			if gui.TreeNodeEx_Str("love.graphics.getRendererInfo()", gui.love.TreeNodeFlags("SpanAvailWidth")) then
				local renderer = {}; renderer.name, renderer.version, renderer.vendor, renderer.device = love.graphics.getRendererInfo()
				
				if gui.BeginTable("performance_renderer", 2, gui.love.TableFlags("RowBg", "BordersInnerV", "Resizable")) then
					gui.TableSetupColumn("1")
					gui.TableSetupColumn("2")
					
					for k,v in kpairs(renderer) do
						gui.TableNextRow()
						gui.TableSetColumnIndex(0)
						gui.Text(k)
						gui.TableSetColumnIndex(1)
						gui.Text(tostring(v))
					end
					
					gui.EndTable()
				end
				gui.TreePop()
			end
			
			------------------------ love.graphics.getSystemLimits() tree
			if gui.TreeNodeEx_Str("love.graphics.getSystemLimits()", gui.love.TreeNodeFlags("SpanAvailWidth")) then
				local limits = love.graphics.getSystemLimits()
				
				if gui.BeginTable("performance_limits", 2, gui.love.TableFlags("RowBg", "BordersInnerV")) then
					gui.TableSetupColumn("1")
					gui.TableSetupColumn("2")
					
					for k,v in kpairs(limits) do
						gui.TableNextRow()
						gui.TableSetColumnIndex(0)
						gui.Text(k)
						gui.TableSetColumnIndex(1)
						gui.Text(tostring(v))
					end
					
					gui.EndTable()
				end
				gui.TreePop()
			end
			
		end
		
		------------------------------------------------ INPUT HEADER
		if gui.CollapsingHeader_BoolPtr("Input: "..input.mode) then
			
			-- mouse table
			if gui.BeginTable("input_mouse", 3) then
				gui.TableSetupColumn("mouse x")
				gui.TableSetupColumn("mouse y")
				gui.TableSetupColumn("wheel")
				gui.TableHeadersRow()
				
				gui.TableNextRow()
				gui.TableSetColumnIndex(0)
				gui.Text(tostring(mousex))
				gui.TableSetColumnIndex(1)
				gui.Text(tostring(mousey))
				gui.TableSetColumnIndex(2)
				gui.Text(tostring(input.mouse_wheel))
				
				gui.EndTable()
			end
			
			-- current inputs table
			if gui.BeginTable("input_keys", 3, gui.love.TableFlags("RowBg", "BordersInnerV")) then
				gui.TableSetupColumn("")
				gui.TableSetupColumn("pressed")
				gui.TableSetupColumn("held time")
				gui.TableHeadersRow()
				
				for k,v in kpairs(config.input.keyboard) do
					gui.TableNextRow()
					gui.TableSetColumnIndex(0)
					gui.Text(k)
					gui.TableSetColumnIndex(1)
					if input[k] then
						gui.TextColored(gui.ImVec4_Float(0,1,0,1),tostring(input[k]))
					else
						gui.TextColored(gui.ImVec4_Float(1,0,0,1),tostring(input[k]))
					end
					gui.TableSetColumnIndex(2)
					gui.Text(tostring(input.time[k]))
				end
				
				gui.EndTable()
			end
			
		end
		
		------------------------------------------------ GLOBAL VARIABLES
		imgui.table(_G, "Global variables")
		
		gui.End()
	end
	
	imgui.open.main = open[0]
end

---------------------------------------------------------------- INSPECTOR

local instance_selected
local asset_selected

function imgui.window.inspector()
	local open = _bool(imgui.open.inspector)
	
	if gui.Begin("Inspector", open) then
		
		if gui.BeginTabBar("", gui.love.TabBarFlags("TabListPopupButton")) then
			
			if gui.BeginTabItem("Instances") then
				
				if gui.BeginChild_Str("selector", nil, gui.love.ChildFlags("Border", "ResizeX")) then
					for k,v in kpairs(instances) do
						
						local children
						for ck,cv in pairs(instances[k]) do
							children = children or {}
							if type(cv) == "table"  then
								children[ck] = cv
							end
						end
						
						local flags
						if instance_selected == k then
							if children then
								flags = gui.love.TreeNodeFlags("SpanAvailWidth", "OpenOnArrow", "OpenOnDoubleClick", "Selected")
							else
								flags = gui.love.TreeNodeFlags("SpanAvailWidth", "OpenOnArrow", "OpenOnDoubleClick",  "Leaf", "Selected")
							end
						else
							if children then
								flags = gui.love.TreeNodeFlags("SpanAvailWidth", "OpenOnArrow", "OpenOnDoubleClick")
							else
								flags = gui.love.TreeNodeFlags("SpanAvailWidth", "OpenOnArrow", "OpenOnDoubleClick", "Leaf")
							end
						end
						
						if gui.TreeNodeEx_Str(tostring(k), flags) then
							
							if children and gui.IsItemClicked() then
								instance_selected = k
							end
							
							for ck,cv in kpairs(instances[k]) do
								if type(cv) == "table" then
									if gui.TreeNodeEx_Str(tostring(ck), gui.love.TreeNodeFlags("SpanAvailWidth", "Leaf")) then
										
										gui.TreePop()
									end
								end
							end
							
							gui.TreePop()
						end
						
						if gui.IsItemClicked() then
							instance_selected = k
						end
						
					end
					
					gui.EndChild()
				end
				
				gui.SameLine()
				if gui.BeginChild_Str("selected") then
					local current = instances[instance_selected] or {}
					
					gui.SeparatorText(tostring(instance_selected or "empty :)"))
					
					if gui.Button("Delete") and current.instance then
						instance_selected = nil
						instance.delete(current.id)
					end
					
					gui.Separator()
					if gui.BeginChild_Str("properties") then
						for k,v in kpairs(current) do
							if type(v) == "table" then
								imgui.table(v, tostring(k), 1)
								
							elseif type(v) == "boolean" then
								local _v = _bool(v)
								gui.Checkbox(tostring(k), _v)
								current[k] = _v[0]
								
							elseif type(v) == "number" then
								local _v = _float(v)
								gui.DragFloat(tostring(k), _v)
								current[k] = _v[0]
								
							elseif type(v) == "string" then
								local _v = _char(v)
								gui.InputText(tostring(k), _v, _v[0])
								current[k] = ffi.string(_v)
								
							elseif type(v) == "userdata" then
								
								-- attempt to make sure we're in assets
								if type(k) == "number" and v:type() == "Image" then
									gui.Image(v, gui.ImVec2_Float(v:getDimensions()))
									gui.SameLine()
									gui.Text(tostring(k))
									
								else
									gui.Text(tostring(k)..": "..tostring(v))
								end
								
							else
								gui.Text(tostring(k)..": "..tostring(v))
								
							end
						end
						
						gui.EndChild()
					end
					
					gui.EndChild()
				end
				
				gui.EndTabItem()
			end
			
			if gui.BeginTabItem("Assets") then
				
				if gui.BeginChild_Str("selector", nil, gui.love.ChildFlags("Border", "ResizeX")) then
					for k,v in kpairs(assets) do
						local flags
						if asset_selected == k then
							flags = gui.love.TreeNodeFlags("SpanAvailWidth", "OpenOnArrow", "OpenOnDoubleClick", "Selected")
						else
							flags = gui.love.TreeNodeFlags("SpanAvailWidth", "OpenOnArrow", "OpenOnDoubleClick")
						end
						
						if gui.TreeNodeEx_Str(tostring(k), flags) then
							for ck,cv in kpairs(assets[k]) do
								if gui.IsItemClicked() then
									asset_selected = k
								end
								
								if type(cv) == "table" then
									if gui.TreeNodeEx_Str(tostring(ck), gui.love.TreeNodeFlags("SpanAvailWidth", "Leaf")) then
										
										gui.TreePop()
									end
								end
							end
							
							gui.TreePop()
						end
						
						if gui.IsItemClicked() then
							asset_selected = k
						end
						
					end
					
					gui.EndChild()
				end
					
					gui.EndChild()
				end
				
				gui.EndTabItem()
			
			gui.EndTabBar()
		end
		
		gui.End()
	end
	
	imgui.open.inspector = open[0]
end

---------------------------------------------------------------- IMGUI DEMO

function imgui.window.demo()
	local open = _bool(imgui.open.demo)
	
	gui.ShowDemoWindow(open)
	
	imgui.open.demo = open[0]
end