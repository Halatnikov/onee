files = urfs -- extend

files.mount(love.filesystem.getSaveDirectory(), "savedata") -- TODO

--! @function files.exists
files.exists = love.filesystem.getInfo

--!
function files.resetWriteDir()
	urfs.setWriteDir(love.filesystem.getSaveDirectory())
end

--! recursively list a folder
function files.listdir(arg)
	local t = {}
	local function recursive(arg)
		local list = love.filesystem.getDirectoryItems(arg)
		for i=1, #list do
			local entry = arg ~= "" and arg.."/"..list[i] or list[i]
			local info = love.filesystem.getInfo(entry)
			if info.type == "directory" and list[i] ~= ".git" then
				recursive(entry)
			elseif info.type == "file" then
				table.insert(t, entry)
			end
		end
	end
	recursive(arg)
	return t
end
