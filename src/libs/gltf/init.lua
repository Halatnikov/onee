-- @module gltf
-- @desc This is glTF 2.0 asset importer.
-- Each asset is contained in a gltf.Asset object. These can be used totally on
-- their own, but gltf.Context provides a reference rendering path you can use
-- to draw them, as well.

-- implementation notes
-- spec:
-- https://github.com/KhronosGroup/glTF/tree/master/specification/2.0
-- quick reference:
-- https://raw.githubusercontent.com/KhronosGroup/glTF/master/specification/2.0/figures/gltfOverview-2.0.0b.png
-- sample models:
-- https://github.com/KhronosGroup/glTF-Sample-Models/tree/master/2.0

local base = (...) .. "."
local Asset   = require(base..'asset')
local DefaultRenderer = require(base..'defaultRenderer')

local gltf = {}

-- @function gltf.newAsset
-- @desc loads a new gltf asset from file. uses love.filesystem.
-- @see Asset
-- @param filename the name of the .gltf file or .glb file
-- @return asset
function gltf.newAsset(filename)
	return Asset.new(filename)
end

-- @function gltf.addCustomAttribute
-- @desc defines a custom attribute that meshes can support.
-- @param dataName the name of the attribute in the gltf source (eg. TEXCOORD_0)
-- @param shaderName the name the attribute should be bound to in glsl (eg. VertexTexCoord)
function gltf.addCustomAttribute(dataName, shaderName)
	return Asset.addAttribute(dataName, shaderName)
end

-- @function gltf.setLoadingStrategy
-- @desc defines the loading strategy for new gltf assets
-- @param loadingStrategy
function gltf.setLoadingStrategy(loadingStrategy)
	return Asset.setLoadingStrategy(loadingStrategy)
end

-- @function gltf.newRenderer
-- @desc Creates a new renderer. You can always create your own rendering
-- pipeline, but the default renderer provides a good jumping off point.
-- @see DefaultRenderer
-- @return renderer
function gltf.newRenderer()
	return DefaultRenderer.new()
end

return gltf
