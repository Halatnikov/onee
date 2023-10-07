gui = {
	open = {},
	window = {},
}

-- event redirection
function gui.mousepressed(x, y, button)
    loveframes.mousepressed(x, y, button)
end
function gui.mousereleased(x, y, button)
    loveframes.mousereleased(x, y, button)
end
function gui.wheelmoved(x, y)
	loveframes.wheelmoved(x, y)
end
function gui.keypressed(key, scancode, isrepeat)
    loveframes.keypressed(key, isrepeat)
end
function love.keyreleased(key)
    loveframes.keyreleased(key)
end
function love.textinput(text)
    loveframes.textinput(text)
end

---------------------------------------------------------------- 

-- main loop
function gui.update()
	
	loveframes.update()
end

function gui.draw()
	
	loveframes.draw()
end

function gui.collumnlist_fix(arg)
	if frames%2 == 0 then
		arg:ResizeColumns()
		arg.internals[1]:GetVerticalScrollBody().width = 0
		arg.internals[1]:GetVerticalScrollBody().internals = {}
	end
	arg.internals[1].height = arg.height
end

---------------------------------------------------------------- 

function gui.open.debug()
	-- main window
	local window = loveframes.Create("frame")
	window:SetScreenLocked(true)
	window:SetResizable(true)
	window:ShowCloseButton(false)
	window:CenterWithinArea(0, 0, 800, 600)
	window:SetName(version)
	window:SetSize(220,220); window:SetMinSize(window.width,58)

	-- main container
	local container = loveframes.Create("list", window)
	container:SetPos(1, 24)
	container:SetPadding(4); container:SetSpacing(4)
	container.Update = function()
		container:SetSize(window.width-2, window.height-25)
	end
	
	-- object definitions ------------
    local top = loveframes.Create("text")
    local console = loveframes.Create("button")
    
	local grid_reset = loveframes.Create("grid")
    local reset = loveframes.Create("button")
    local reset_scene = loveframes.Create("button")
    
    local tree_input = loveframes.Create("collapsiblecategory")
	local container_input = loveframes.Create("list")
    local tree_input_inputlist = loveframes.Create("collapsiblecategory")
	local inputlist = loveframes.Create("columnlist")
	----------------------------------

	-- text: fps
    top.Update = function()
		if frames%2 == 0 then
		top:SetText("FPS: "..love.timer.getFPS().." "
						..math.round(fps,2).." "
						..math.round(1000*love.timer.getAverageDelta(),2).."ms"
					
					.."\n"..windowwidth.."x"..windowheight)
		end
    end
    
	-- button: open console
    console:SetText("Open console")
    console.OnClick = function()
		if gui.window.console then gui.window.console:Remove() end
		gui.open.console()
    end
    
    -- grid layout: reset | reset scene
	grid_reset:SetRows(1); grid_reset:SetColumns(2)
	grid_reset:SetCellPadding(0)
	grid_reset.Update = function()
		if frames%3 == 0 then
			grid_reset:SetCellSize(console.width/2, 24)
		end
	end
	
	---- start grid
	-- button: reset
    reset:SetText("Reload")
    reset.Update = function()
		if frames%3 == 0 then reset:SetSize(console.width/2,24) end
	end
    reset.OnClick = function()
		love.event.quit("restart")
    end
    
    -- button: reset scene
    reset_scene:SetText("Restart scene")
    reset_scene.Update = function()
		if frames%3 == 0 then reset_scene:SetSize(console.width/2,24) end
	end
    reset_scene.OnClick = function()
		scenes.set("init")
    end
    ---- end grid
    
    -- category button: input
    tree_input.padding = 0
	tree_input.Update = function()
		tree_input:SetText("Input: "..input.mode)
		tree_input.height = tree_input.open and container_input.height+25 or 25
    end
	-- category container
	container_input:SetPadding(4); container_input:SetSpacing(4)
	container_input.Update = function()
		container_input:SetSize(tree_input.width, tree_input_inputlist.height + (4 * 2))
	end
	
	---- start container
	-- sub category button: current inputs
	tree_input_inputlist.padding = 0
	tree_input_inputlist:SetOpen(true)
	tree_input_inputlist:SetText("Current inputs")
	tree_input_inputlist.Update = function()
		tree_input_inputlist.height = tree_input_inputlist.open and inputlist.height+25 or 25
    end
	
	-- collumn list: current inputs
	inputlist:AddColumn("")
	inputlist:AddColumn("Pressed")
	inputlist:AddColumn("Held time")
	for key in pairs(config.input.keyboard) do
		inputlist:AddRow(key, tostring(input[key]), input.time[key])
	end
	inputlist:SizeToChildren()
	inputlist.Update = function()
		for i=1, #inputlist.internals[1].children do
			inputlist.internals[1].children[i].height = 16
		end
		gui.collumnlist_fix(inputlist)
		--inputlist.height = inputlist.height - ((25 - inputlist.internals[1].children[1].height) * #inputlist.internals[1].children)
		
	end
	---- end container
    
    -- composition -------------------
    container:AddItem(top)
    container:AddItem(console)
    
    container:AddItem(grid_reset)
    grid_reset:AddItem(reset, 1, 1, "left")
    grid_reset:AddItem(reset_scene, 1, 2, "right")
    
	container:AddItem(tree_input)
    tree_input:SetObject(container_input)
	container_input:AddItem(tree_input_inputlist)
    tree_input_inputlist:SetObject(inputlist)
    ----------------------------------
	
	gui.window.debug = window
    
end

function gui.open.console()
	-- main window
	local window = loveframes.Create("frame")
	window:SetResizable(true)
	window:SetScreenLocked(true)
	window:CenterWithinArea(0, 0, 800, 600)
	window:SetName("Console")
	window:SetSize(350,200); window:SetMinSize(150,150)
	
	-- text field itself
	local console = loveframes.Create("textinput", window)
	console:SetPos(4, 30)
	console:SetMultiline(true)
	console:SetEditable(false)
	console.Update = function()
		console:SetSize(window.width-8, window.height-34)
		if frames%4 == 0 then
			console:SetText(love.version.." | onee "..version)
		end
	end
	
	gui.window.console = window

end
