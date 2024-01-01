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
	
	if imgui.open.demo then imgui.window.demo() end
	
end

-- data types conversion
local ffi = require("ffi")

local function _bool(arg, value) -- bool* pointer
	local bool = ffi.new("bool[1]")
	bool[0] = arg or value
	return bool
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

---------------------------------------------------------------- MENU BAR
local debugmode = _bool(true)

function imgui.window.menubar()
	
	if gui.BeginMainMenuBar() then
		
		------------------------------------------------ windows menu
		if gui.BeginMenu("Windows") then
			
			-- open main window
			if gui.MenuItem_Bool("Main window") then
				imgui.open.main = true
			end
			-- open imgui demo
			if gui.MenuItem_Bool("ImGui demo") then
				imgui.open.demo = true
			end
			--
			gui.Separator()
			-- toggle debug mode
			gui.Checkbox("Debug mode", debugmode)
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
	
	debug_mode = debugmode[0]
end

---------------------------------------------------------------- MAIN WINDOW

local freeze = false; local advance_frame = false; local old_frame
local draw_collisions = _bool(true)

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
		gui.Checkbox("Draw collisions", draw_collisions)
		
		gui.Text("Window size: "..windowwidth.."x"..windowheight)
		
		------------------------------------------------ PERFORMANCE HEADER
		if gui.CollapsingHeader_BoolPtr("Performance") then
			
			-- raw fps and dt table
			if gui.BeginTable("performance_fps",2) then
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
			if gui.BeginTable("performance_time",3) then
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
			if gui.BeginTable("performance_ram",2) then
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
			if gui.BeginTable("input_mouse",3) then
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
		
		gui.End()
	end
	
	imgui.open.main = open[0]
	debug_draw_collisions = draw_collisions[0]
end

---------------------------------------------------------------- IMGUI DEMO

function imgui.window.demo()
	local open = _bool(imgui.open.demo)
	
	gui.ShowDemoWindow(open)
	
	imgui.open.demo = open[0]
end