-- asset loader
-- TODO: where possible, share resources between assets. This might not happen
-- that often, but maybe textures/bin files?
-- TODO: threaded loading? probably hard to do well
local base = (...):gsub("%.[^.]+$",".")
local mat4 = require 'onee/libs/gltf/cpml.modules.mat4'
local quat = require 'onee/libs/gltf/cpml.modules.quat'
local vec3 = require 'onee/libs/gltf/cpml.modules.vec3'

-- prefer cjson if available
local ok, json = pcall(require, "cjson")
-- if not ok then
	-- json = require(base..'dkjson')
-- end

-- @class Asset
-- @desc Each asset represents one .gltf/.glb file. This can, in turn, hold any
-- number of meshes, animations, scenes, or textures. It'll be up to your
-- application to decide what it wants to use from each asset and when.

local Asset = {isAsset = true}
local Asset_mt = {
	__index = Asset,
	__tostring = function(t)
		return string.format("Asset(%q)", t.filename)
	end,
}
Asset.attributes = {
	["POSITION"] = "VertexPosition",
	["TEXCOORD_0"] = "VertexTexCoord",
	["COLOR_0"] = "VertexColor",
	-- TODO: should we force consumers to opt-in to these?
	["TEXCOORD_1"] = "gltfVertexTexCoord1",
	["NORMAL"] = "gltfVertexNormal",
	["TANGENT"] = "gltfVertexTangent",
	["JOINTS_0"] = "gltfVertexJoint",
	["WEIGHTS_0"] = "gltfVertexWeight",
}

function Asset.new(filename)
	local self = setmetatable({}, Asset_mt)
	self.ready = false
	self.warnings = {}
	self.cachedTransforms = {}
	self.cachedWeights = {}
	self.animationChannels = {}
	self.maxTimeForAnimation = {}

	if type(filename) ~= "table" then
		self.filename = filename
		local file = assert(love.filesystem.newFile(filename, 'r'))
		local magic = file:read(4)
		assert(magic)
		if magic == "glTF" then
			self:loadGLB(file)
		else
			file:seek(0)
			local s = file:read()
			assert(s)
			self:loadGLTF(s)
		end
	else
		self.filename = 0
		self:loadGLTF(filename)
	end

	return self
end

function Asset.addAttribute(dataName, shaderName)
	Asset.attributes[dataName] = shaderName
end

local VALID_LOADING_STRATEGIES = {
	-- sync load strategy is the default, everything will be loaded eagerly within
	-- an asset and it's usable right away. you do not need to call continueLoading().
	sync = true,
	-- incremental load strategy can be used to split the work of loading the
	-- asset across multiple frames. Call Asset:continueLoading() periodically
	-- to continue the loading process.
	-- Until Asset:isReady() becomes true, trying to create a new asset
	-- instance will trigger an error.
	incremental = true,
}
Asset.loadingStrategy = "sync"

function Asset.setLoadingStrategy(loadingStrategy)
	if not VALID_LOADING_STRATEGIES[loadingStrategy] then
		error(string.format("Invalid load strategy: %s", tostring(loadingStrategy)), 2)
	end
	Asset.loadingStrategy = loadingStrategy
end

function Asset:warnf(objOrFmt, maybeFmt, ...)
	local s
	if type(objOrFmt) == "string" then
		s = string.format(objOrFmt, maybeFmt, ...)
	else
		s = tostring(objOrFmt) .. ": " .. string.format(maybeFmt, ...)
	end
	io.stderr:write(s, "\n")
	table.insert(self.warnings, s)
end

local function optionalTable(t, key)
	if not t[key] then
		t[key] = {}
	end
end

function Asset:isReady()
	return self.ready
end

function Asset:loadGLTF(jsonStr, is_decoded)
	if type(jsonStr) ~= "table" then
		self.json = json.decode(jsonStr)
	else
		self.json = jsonStr
	end
	assert(self.json, "failed to parse json")
	if self.json.asset == nil or self.json.asset.version ~= "2.0" then
		error("not a glTF 2.0 file")
	end
	optionalTable(self.json, "meshes")
	optionalTable(self.json, "scenes")
	optionalTable(self.json, "textures")
	optionalTable(self.json, "images")
	optionalTable(self.json, "extra")
	optionalTable(self.json, "buffers")
	optionalTable(self.json, "bufferViews")
	optionalTable(self.json, "animations")

	if self.loadingStrategy == "sync" then
		self:syncLoadAll()
	end
end

function Asset:syncLoadAll()
	for animIdx = 1, #self.json.animations do
		self:loadAnimation(animIdx)
	end

	for sceneIdx = 1, #self.json.scenes do
		self:buildTransformCacheForScene(sceneIdx)
	end

	for meshIdx = 1, #self.json.meshes do
		self:loadMesh(meshIdx)
	end
end

function Asset:continueLoading(timeout)
	if not self.ready then
		if not self.loadingCoroutine then
			self.loadingCoroutine = coroutine.create(function()
				for animIdx = 1, #self.json.animations do
					self:_loadAnimationIncremental(animIdx)
				end

				for sceneIdx = 1, #self.json.scenes do
					self:buildTransformCacheForScene(sceneIdx)
					coroutine.yield(false)
				end

				for meshIdx = 1, #self.json.meshes do
					self:loadMesh(meshIdx)
					coroutine.yield(false)
				end
				coroutine.yield(true)
			end)
		end

		local deadline = love.timer.getTime() + timeout
		local _
		repeat
			_, self.ready = coroutine.resume(self.loadingCoroutine)
		until self.ready or love.timer.getTime() > deadline

		if self.ready then
			self.loadingCoroutine = nil
		end
	end

	return self.ready
end

local GLB_CHUNK_TYPES = {
	[0x4E4F534A] = "json",
	[0x004E4942] = "bin",
}
function Asset:loadGLB(file)
	local _
	local header, hread = file:read(4*2)
	if hread ~= 4*2 then
		error("missing global header")
	end
	-- magic, version, length
	local version
	version, _ = love.data.unpack("<I4I4", header)
	if version ~= 2 then
		error("unsupported gltf version")
	end

	local gltfString
	while true do
		local chunkHeader, cread = file:read(4*2)
		if cread ~= 4*2 then
			-- last chunk, return
			break
		end
		local chunkLength, chunkTypeId
		chunkLength, chunkTypeId = love.data.unpack("<I4I4", chunkHeader)
		local chunkType = GLB_CHUNK_TYPES[chunkTypeId]
		if chunkType == "json" then
			gltfString = file:read(chunkLength)
		elseif chunkType == "bin" then
			self.glbData = file:read('data', chunkLength)
		else
			-- skip unknown chunks
			file:seek(file:tell()+chunkLength)
		end
	end
	assert(gltfString, "no json chunk found")
	self:loadGLTF(gltfString)
end

local ACCESSOR_COMPONENT_TYPES = {
	[5120] = "int8",
	[5121] = "uint8",
	[5122] = "int16",
	[5123] = "uint16",
	[5125] = "uint32",
	[5126] = "float",
}

local ACCESSOR_COMPONENT_BYTES = {
	[5120] = 1,
	[5121] = 1,
	[5122] = 2,
	[5123] = 2,
	[5125] = 4,
	[5126] = 4,
}

local TYPE_TO_CTYPE = {
	["int8"] = "int8_t",
	["uint8"] = "uint8_t",
	["int16"] = "int16_t",
	["uint16"] = "uint16_t",
	["uint32"] = "uint32_t",
	["float"] = "float",
}

local TYPE_POINTERS = {}
local TYPE_BYTES = {}
for k, atype in pairs(ACCESSOR_COMPONENT_TYPES) do
	TYPE_POINTERS[atype] = TYPE_TO_CTYPE[atype] .. "*"
	TYPE_BYTES[atype] = ACCESSOR_COMPONENT_BYTES[k]
end

local ACCESSOR_TYPE_SIZE = {
	["SCALAR"] = 1,
	["VEC2"] = 2,
	["VEC3"] = 3,
	["VEC4"] = 4,
	["MAT2"] = 4,
	["MAT3"] = 9,
	["MAT4"] = 16,
}

function Asset:path(rawpath)
	local basePath = self.filename:gsub("/[^/]*$", "/")
	return basePath .. rawpath
end

function Asset:getFileDataFromURI(uri, name)
	local fileData
	if uri:match("^data") then
		-- data uri
		local mimetype, datastring = uri:match("^data:([^,]*),(.*)$")
		assert(mimetype and datastring)
		name = name or ""
		if mimetype:match("base64") then -- TODO: not strictly correct
			local byteData = love.data.decode('string', 'base64', datastring)
			fileData = love.filesystem.newFileData(byteData, name)
		else
			fileData = love.filesystem.newFileData(datastring, name)
		end
	else
		-- normal uri
		fileData = love.filesystem.newFileData(self:path(uri))
	end
	return fileData
end

function Asset:getDataForBufferView(bufferViewIdx)
	local bufferView = self.json.bufferViews[bufferViewIdx]
	if not bufferView then
		return nil
	end
	if bufferView._data then
		return bufferView._data
	end

	local buffer = self.json.buffers[bufferView.buffer+1]
	assert(buffer)

	if not buffer._data then
		if buffer.uri == nil then
			assert(self.glbData)
			buffer._data = self.glbData
		else
			buffer._data = self:getFileDataFromURI(buffer.uri, buffer.name)
		end
	end

	local offset = bufferView.byteOffset or 0
	local size = assert(bufferView.byteLength)
	bufferView._data = love.data.newDataView(buffer._data, offset, size)

	return bufferView._data
end

local function destrideData(targetData, sourceData, byteOffset, byteSize, byteStride, count)
	local ffi = require 'ffi'
	local targetPtr = ffi.cast("uint8_t*", targetData:getFFIPointer())
	local sourcePtr = ffi.cast("uint8_t*", sourceData:getFFIPointer())
	local targetIdx = 0
	local sourceIdx = byteOffset
	-- my math seems to be off :(
	--local maxIdx = byteOffset + (byteStride * count)
	--assert(maxIdx < sourceData:getSize(), "predicted buffer overrun")
	for _=0, count-1 do
		for b=0, byteSize-1 do
			targetPtr[targetIdx+b] = sourcePtr[sourceIdx+b]
		end
		targetIdx = targetIdx + byteSize
		sourceIdx = sourceIdx + byteStride
	end
end

function Asset:getDataForAccessor(accessorIdx)
	local accessor = self.json.accessors[accessorIdx]
	assert(accessor)
	if accessor._data then
		return accessor._data
	end

	if accessor.bufferView then
		local bufferViewIdx = accessor.bufferView+1
		local bufferView = self.json.bufferViews[bufferViewIdx]
		local bufferViewData = self:getDataForBufferView(bufferViewIdx)

		local byteOffset = accessor.byteOffset or 0
		local bytesPerElement = ACCESSOR_COMPONENT_BYTES[accessor.componentType]
		local numElements = ACCESSOR_TYPE_SIZE[accessor.type]
		local bytesPerAttribute = bytesPerElement * numElements
		local accessorByteLength = bytesPerAttribute * accessor.count
		if bufferView.byteStride and bufferView.byteStride ~= bytesPerAttribute then
			--NOTE on strided data: so we can't actually express a data view of
			--strided data, so for the most general case the correct approach is to
			--allocate a new buffer and destride the data. this is unfortunate,
			--because the most natural way to express a mesh in love is strided.
			--Ideally if we know a mesh is made up of a bunch of strided accessors
			--we should be able to skip the data object and just give it the buffer
			--and the description format and let it do its thing
			self:warnf("accessor %d: destriding data, this may affect performance", accessorIdx)
			accessor._data = love.data.newByteData(accessorByteLength)
			destrideData(
				accessor._data,
				bufferViewData,
				byteOffset,
				bytesPerAttribute,
				bufferView.byteStride,
				accessor.count
			)
		else
			accessor._data = love.data.newDataView(bufferViewData, byteOffset, accessorByteLength)
		end
	else
		-- initialize to zeros, used for sparse accessors
		local bytesPerElement = ACCESSOR_COMPONENT_BYTES[accessor.componentType]
		local numElements = ACCESSOR_TYPE_SIZE[accessor.type]
		local bytesPerAttribute = bytesPerElement * numElements
		local accessorByteLength = bytesPerAttribute * accessor.count
		accessor._data = love.data.newByteData(accessorByteLength)
	end

	if accessor.sparse then
		local ffi = require 'ffi'
		local sparse = accessor.sparse

		local dataComponentType = ACCESSOR_COMPONENT_TYPES[accessor.componentType]
		local dataNumElements = ACCESSOR_TYPE_SIZE[accessor.type]
		local dataArray = ffi.cast(TYPE_POINTERS[dataComponentType], accessor._data:getFFIPointer())

		local valueBufferData = self:getDataForBufferView(sparse.values.bufferView + 1)
		local valueByteOffset = sparse.values.byteOffset
		local valueData = love.data.newDataView(valueBufferData, valueByteOffset, valueBufferData:getSize() - valueByteOffset)
		local valueArray = ffi.cast(TYPE_POINTERS[dataComponentType], valueData:getFFIPointer())

		local indexComponentType = ACCESSOR_COMPONENT_TYPES[sparse.indices.componentType]
		local indexBufferData = self:getDataForBufferView(sparse.indices.bufferView + 1)
		local indexByteOffset = sparse.indices.byteOffset
		local indexData = love.data.newDataView(indexBufferData, indexByteOffset, indexBufferData:getSize() - indexByteOffset)
		local indexArray = ffi.cast(TYPE_POINTERS[indexComponentType], indexData:getFFIPointer())

		-- 0-indexed all around
		for i = 0, sparse.count - 1 do
			local dataIdx = indexArray[i] * dataNumElements
			local valueIdx = i * dataNumElements
			for j = 0, dataNumElements - 1 do
				dataArray[dataIdx + j] = valueArray[valueIdx + j]
			end
		end
	end

	return accessor._data
end

function Asset:debugPrintAccessorInfo(accessorIdx)
	local accessor = self.json.accessors[accessorIdx]
	local numElements = ACCESSOR_TYPE_SIZE[accessor.type]
	local componentType = ACCESSOR_COMPONENT_TYPES[accessor.componentType]
	print("numElements", numElements)
	print("componentType", componentType)
end

function Asset:debugPrintAccessorData(accessorIdx)
	local array, len, numElements = self:getFFIArrayForAccessor(accessorIdx)
	for i = 0, len - 1, numElements do
		local tmp = {}
		for j = 0, numElements - 1 do
			table.insert(tmp, string.format("%.2f", array[i+j]))
		end
		print(table.concat(tmp, ",\t"))
	end
end

-- Returns an FFI array of type component*
-- I would like to make a version that dumps directly into cpml vec3/mat4/etc
-- but consider that one TODO
function Asset:getFFIArrayForAccessor(accessorIdx)
	local ffi = require 'ffi'
	local accessor = self.json.accessors[accessorIdx]
	local data = self:getDataForAccessor(accessorIdx)

	local numElements = ACCESSOR_TYPE_SIZE[accessor.type]
	local componentType = ACCESSOR_COMPONENT_TYPES[accessor.componentType]

	local ptr = ffi.cast(TYPE_POINTERS[componentType], data:getFFIPointer())
	return ptr, accessor.count, numElements
end

local MINMAG_FILTER_MODE = {
	[9728] = "nearest",
	[9729] = "linear",
	[9984] = "nearest",
	[9985] = "linear",
	[9986] = "nearest",
	[9987] = "linear",
}
local MINMAG_MIPMAP_FILTER_MODE = {
	[9728] = false,
	[9729] = false,
	[9984] = "nearest",
	[9985] = "nearest",
	[9986] = "linear",
	[9987] = "linear",
}
local WRAP_MODE = {
	[33071] = "clamp",
	[33648] = "mirroredrepeat",
	[10497] = "repeat",
}
local DONT_USE_MIPMAPS_FLAG = {mipmaps=true}
local USE_MIPMAPS_FLAG = {mipmaps=true}

-- @function Asset:getNumTextures
-- @desc returns the number of textures in the asset.
-- @return numTextures
function Asset:getNumTextures(textureIdx)
	return #self.json.textures
end

-- @function Asset:loadTexture
-- @desc loads a love texture, including eagerly loading the underlying image
-- and generating mipmaps if necessary
-- @param textureIdx
-- @return texture
-- @see https://love2d.org/wiki/Texture
function Asset:loadTexture(textureIdx)
	local textureJson = self.json.textures[textureIdx]
	if not textureJson then
		return nil
	end

	if textureJson._texture then
		return textureJson._texture
	end

	local isCompressed = false
	local sourceIdx = nil
	if textureJson.source then
		sourceIdx = textureJson.source + 1
	end
	if textureJson.extensions then
		local ddsJson = textureJson.extensions["MSFT_texture_dds"]
		if ddsJson then
			isCompressed = true
			sourceIdx = ddsJson.source + 1
		end
	end
	assert(sourceIdx)

	local imageJson = self.json.images[sourceIdx]
	if not imageJson._data then
		if imageJson.uri then
			imageJson._data = self:getFileDataFromURI(imageJson.uri, imageJson.name)
		elseif imageJson.bufferView then
			imageJson._data = self:getDataForBufferView(imageJson.bufferView+1)
		end

		if isCompressed then
			imageJson._data = love.image.newCompressedData(imageJson._data)
		else
			imageJson._data = love.image.newImageData(imageJson._data)
		end
	end

	if textureJson.sampler then
		local sampler = self.json.samplers[textureJson.sampler+1]
		local mipmapFilter = sampler.minFilter and MINMAG_MIPMAP_FILTER_MODE[sampler.minFilter]
		local flags = mipmapFilter and USE_MIPMAPS_FLAG or DONT_USE_MIPMAPS_FLAG
		local texture = love.graphics.newImage(imageJson._data, flags)
		if mipmapFilter then
			texture:setMipmapFilter(mipmapFilter)
		end
		if sampler.minFilter or sampler.magFilter then
			local min = sampler.minFilter and MINMAG_FILTER_MODE[sampler.minFilter] or "linear"
			local mag = sampler.magFilter and MINMAG_FILTER_MODE[sampler.magFilter] or "linear"
			texture:setFilter(min, mag)
		end
		local wrapS = sampler.wrapS and WRAP_MODE[sampler.wrapS] or "repeat"
		local wrapT = sampler.wrapT and WRAP_MODE[sampler.wrapT] or "repeat"
		texture:setWrap(wrapS, wrapT)
		textureJson._texture = texture
	else
		local texture = love.graphics.newImage(imageJson._data)
		texture:setWrap("repeat", "repeat")
		textureJson._texture = texture
	end

	return textureJson._texture
end

-- @function Asset:loadMaterialByName
-- @param materialName
-- @return material
-- @see GLTFMaterial
function Asset:loadMaterialByName(materialName)
	if not self.materialsByName then
		self.materialsByName = {}
		for materialIdx, material in ipairs(self.json.materials) do
			if material.name then
				self.materialsByName[material.name] = materialIdx
			end
		end
	end
	local materialIdx = self.materialsByName[materialName]
	if not materialIdx then
		return nil
	end
	return self:loadMaterial(materialIdx)
end

-- @function Asset:getNumMaterials
-- @desc returns the number of materials in the asset
-- @return numMaterials
function Asset:getNumMaterials()
	return #self.json.materials
end

-- @function Asset:loadDefaultMaterial
-- @desc when a mesh primitive doesn't specify a material, this material is
-- used instead. It is a simple, untextured, grey color.
-- @return material
-- @see GLTFMaterial
local GLTFMaterial_mt
function Asset:loadDefaultMaterial()
	if self.defaultMaterial then
		return self.defaultMaterial
	end
	local materialObject = setmetatable({}, GLTFMaterial_mt)
	materialObject.name = "__default_material"
	materialObject.index = -1
	materialObject.baseColor = {.7, .7, .7, 1}
	materialObject.baseColorTexture = nil
	materialObject.alphaCutoff = 0
	self.defaultMaterial = materialObject
	return materialObject
end

-- @function Asset:loadMaterial
-- @desc loads a gltf material.
-- @param materialIdx
-- @return material
-- @see GLTFMaterial
local DEFAULT_COLOR = {1, 1, 1, 1}
local DEFAULT_EMISSIVE = {0, 0, 0}
function Asset:loadMaterial(materialIdx)
	local materialJson = self.json.materials[materialIdx]
	if not materialJson then
		return nil
	end
	if materialJson._materialObject then
		return materialJson._materialObject
	end

	local pbr = materialJson.pbrMetallicRoughness
	local materialObject = setmetatable({}, GLTFMaterial_mt)
	materialObject.json = materialJson
	materialObject.name = materialJson.name
	materialObject.index = materialIdx

	materialObject.doubleSided = materialJson.doubleSided
	materialObject.alphaMode = materialJson.alphaMode or "OPAQUE"
	if materialObject.alphaMode == "MASK" then
		materialObject.alphaCutoff = materialJson.alphaCutoff or .5
	else
		materialObject.alphaCutoff = 0
	end

	materialObject.baseColor = pbr.baseColorFactor or DEFAULT_COLOR
	if pbr.baseColorTexture then
		local texInfo = pbr.baseColorTexture
		materialObject.baseColorTexture = self:loadTexture(texInfo.index+1)
		materialObject.baseColorTexCoord = texInfo.texCoord
	end

	if materialJson.extensions and materialJson.extensions["KHR_materials_unlit"] then
		materialObject.materialModel = "unlit"
	else
		materialObject.materialModel = "metallicRoughness"

		-- TODO: Are all these parameters really exclusive to the PBR pipeline?
		materialObject.metallicFactor = pbr.metallicFactor or 1
		materialObject.roughnessFactor = pbr.roughnessFactor or 1
		if pbr.metallicRoughnessTexture then
			local texInfo = pbr.metallicRoughnessTexture
			materialObject.metallicRoughnessTexture = self:loadTexture(texInfo.index+1)
			materialObject.metallicRoughnessTexCoord = texInfo.texCoord
		end

		if materialJson.normalTexture then
			local texInfo = materialJson.normalTexture
			materialObject.normalTexture = self:loadTexture(texInfo.index+1)
			materialObject.normalTexCoord = texInfo.texCoord
			materialObject.normalTexScale = texInfo.scale
		end

		if materialJson.occlusionTexture then
			local texInfo = materialJson.occlusionTexture
			materialObject.occlusionTexture = self:loadTexture(texInfo.index+1)
			materialObject.occlusionTexCoord = texInfo.texCoord
			materialObject.occlusionTexStrength = texInfo.strength
		end

		materialObject.emissiveColor = materialJson.emissiveFactor or DEFAULT_EMISSIVE
		if materialJson.emissiveTexture then
			local texInfo = materialJson.emissiveTexture
			materialObject.emissiveTexture = self:loadTexture(texInfo.index+1)
			materialObject.emissiveTexCoord = texInfo.texCoord
		end
	end

	materialJson._materialObject = materialObject
	return materialObject
end

local PRIMITIVE_MODES =
{
	[0] = "points",
	-- The following are unsupported by love
	-- TODO: skip primitives with these defined instead of blowing up
	-- [1] = "lines",
	-- [2] = "line_loop",
	-- [3] = "line_strip",
	[4] = "triangles",
	[5] = "strip",
	[6] = "fan",
}

local INDEX_COMPONENT_TYPES = {
	["uint16"] = "uint16",
	["uint32"] = "uint32",
}

local ATTRIBUTE_COMPONENT_TYPES = {
	["uint8"] = "byte",
	["uint16"] = "unorm16",
	["float"] = "float",
}

-- @function Asset:loadMeshByName
-- @param meshName the string name of the mesh
-- @return mesh
-- @see GLTFMesh
function Asset:loadMeshByName(meshName)
	if not self.meshesByName then
		self.meshesByName = {}
		for meshIdx, mesh in ipairs(self.json.meshes) do
			if mesh.name then
				self.meshesByName[mesh.name] = meshIdx
			end
		end
	end
	local meshIdx = self.meshesByName[meshName]
	if not meshIdx then
		return nil
	end
	return self:loadMesh(meshIdx)
end

function Asset:_convertPackedData(sourceData, sourceType, targetType)
	local ffi = require 'ffi'
	local sourcePtr = ffi.cast(TYPE_POINTERS[sourceType], sourceData:getFFIPointer())
	local numValues = sourceData:getSize() / TYPE_BYTES[sourceType]
	local targetData = love.data.newByteData(numValues * TYPE_BYTES[targetType])
	local targetPtr = ffi.cast(TYPE_POINTERS[targetType], targetData:getFFIPointer())
	for i = 0, numValues - 1 do
		targetPtr[i] = sourcePtr[i]
	end
	return targetData
end

-- @function Asset:getNumMeshes
-- @desc Returns the number of meshes in the asset. Note that there's no
-- requirement that every mesh be used by every scene, or that meshes get used
-- at all.
-- @return numMeshes
function Asset:getNumMeshes()
	return #self.json.meshes
end

-- @function Asset:loadMesh
-- @param meshIdx the mesh index
-- @return mesh
-- @see GLTFMesh
local GLTFMesh_mt
local GLTFPrimitive_mt
function Asset:loadMesh(meshIdx)
	local meshJson = self.json.meshes[meshIdx]
	if not meshJson then
		return nil
	end

	if meshJson._meshObject then
		return meshJson._meshObject
	end

	local meshObject = setmetatable({}, GLTFMesh_mt)
	meshObject.name = meshJson.name
	meshObject.index = meshIdx
	meshObject.loader = self
	meshObject.json = meshJson
	meshObject.primitives = {}
	for primitiveIdx, primitive in ipairs(meshJson.primitives) do
		local primitiveObject = setmetatable({}, GLTFPrimitive_mt)
		primitiveObject.index = primitiveIdx
		primitiveObject.mesh = meshObject
		primitiveObject._hasByteJoints = false
		primitiveObject.morphTargets = {}
		table.insert(meshObject.primitives, primitiveObject)

		local mode, usage = "triangles", "static"
		if primitive.mode then
			mode = assert(PRIMITIVE_MODES[primitive.mode], "invalid primitive mode")
		end

		local vertexMap, vertexMapType = nil, nil
		if primitive.indices then
			local accessorIdx = primitive.indices + 1
			local accessor = self.json.accessors[accessorIdx]
			vertexMap = self:getDataForAccessor(accessorIdx)
			local componentType = ACCESSOR_COMPONENT_TYPES[accessor.componentType]
			if componentType == "uint8" then
				self:warnf(primitiveObject, "uint8 indices are not natively supported, manually converting to uint16", primitiveIdx)
				vertexMap = self:_convertPackedData(vertexMap, "uint8", "uint16")
				vertexMapType = "uint16"
			else
				vertexMapType = INDEX_COMPONENT_TYPES[componentType]
			end
			if not vertexMapType then
				error(("unsupportedVertexMapType: %s"):format(componentType))
			end
		end

		assert(primitive.attributes, "missing attributes")
		for rawattrib, accessorIdx in pairs(primitive.attributes) do
			accessorIdx = accessorIdx + 1
			local accessor = self.json.accessors[accessorIdx]
			local attrib = Asset.attributes[rawattrib]
			if attrib then
				local componentType = ACCESSOR_COMPONENT_TYPES[accessor.componentType]
				local datatype = ATTRIBUTE_COMPONENT_TYPES[componentType]
				local datacount = ACCESSOR_TYPE_SIZE[accessor.type]
				if attrib == "gltfVertexJoint" and componentType == "uint8" then
					primitiveObject._hasByteJoints = true
				end

				local attributeData = self:getDataForAccessor(accessorIdx)
				local fmt = {{attrib, datatype, datacount}}
				local vertexcount = accessor.count

				local attributeMesh = love.graphics.newMesh(fmt, vertexcount, mode, usage)
				attributeMesh:setVertices(attributeData)
				if vertexMap then
					attributeMesh:setVertexMap(vertexMap, vertexMapType)
				end

				if not primitiveObject.rootMesh then
					primitiveObject.rootMesh = attributeMesh
					local material
					if primitive.material then
						material = self:loadMaterial(primitive.material+1)
					else
						material = self:loadDefaultMaterial()
					end
					primitiveObject.material = material
					primitiveObject.rootMesh:setTexture(material.baseColorTexture)
				else
					primitiveObject.rootMesh:attachAttribute(attrib, attributeMesh)
				end
			else
				self:warnf(meshObject, "unknown attribute %q, ignoring", rawattrib)
			end
		end

		if primitive.targets then
			for targetIdx, targetData in ipairs(primitive.targets) do
				local targetMeshes = {}
				for rawattrib, accessorIdx in pairs(targetData) do
					accessorIdx = accessorIdx + 1
					local accessor = self.json.accessors[accessorIdx]
					local attrib = Asset.attributes[rawattrib]
					if attrib then
						local attribKey = string.format("morphTarget_%d_%s", targetIdx, attrib)
						local componentType = ACCESSOR_COMPONENT_TYPES[accessor.componentType]
						local datatype = ATTRIBUTE_COMPONENT_TYPES[componentType]
						local datacount = ACCESSOR_TYPE_SIZE[accessor.type]

						local attributeData = self:getDataForAccessor(accessorIdx)
						local fmt = {{attribKey, datatype, datacount}}
						local vertexcount = accessor.count

						local attributeMesh = love.graphics.newMesh(fmt, vertexcount, mode, usage)
						attributeMesh:setVertices(attributeData)
						if vertexMap then
							attributeMesh:setVertexMap(vertexMap, vertexMapType)
						end
						targetMeshes[attrib] = {
							key = attribKey,
							targetAttribute = attrib,
							mesh = attributeMesh,
						}
					else
						self:warnf(meshObject, "unknown attribute %q, ignoring", rawattrib)
					end
				end
				primitiveObject.morphTargets[targetIdx] = targetMeshes
			end
		end
	end

	meshJson._meshObject = meshObject
	return meshObject
end

-- @function Asset:getNumScenes
-- @desc Returns the number of scenes in the asset
-- @return numScenes
function Asset:getNumScenes()
	return #self.json.scenes
end

function Asset:getMeshIndexForNode(nodeIdx)
	local nodeJson = self.json.nodes[nodeIdx]
	if nodeJson and nodeJson.mesh then
		return nodeJson.mesh + 1
	end
	return nil
end

local AnimationChannel_mt
function Asset:getOrCreateChannel(animIdx, nodeIdx)
	self.animationChannels[nodeIdx] = self.animationChannels[nodeIdx] or {}
	self.animationChannels[nodeIdx][animIdx] = self.animationChannels[nodeIdx][animIdx] or setmetatable({
		asset = self,
		animIdx = animIdx,
		nodeIdx = nodeIdx,
		pathData = {},
	}, AnimationChannel_mt)
	return self.animationChannels[nodeIdx][animIdx]
end

-- @function Asset:loadAnimation
function Asset:loadAnimation(animIdx)
	local animJson = self.json.animations[animIdx]
	for _, channelJson in ipairs(animJson.channels) do
		local nodeIdx = channelJson.target.node + 1
		local samplerIdx = channelJson.sampler + 1
		local channel = self:getOrCreateChannel(animIdx, nodeIdx)
		local samplerJson = animJson.samplers[samplerIdx]
		channel:addPathToChannel(channelJson, samplerJson)
	end
end

function Asset:_loadAnimationIncremental(animIdx)
	local animJson = self.json.animations[animIdx]
	for _, channelJson in ipairs(animJson.channels) do
		local nodeIdx = channelJson.target.node + 1
		local samplerIdx = channelJson.sampler + 1
		local channel = self:getOrCreateChannel(animIdx, nodeIdx)
		local samplerJson = animJson.samplers[samplerIdx]
		channel:addPathToChannel(channelJson, samplerJson)
		coroutine.yield(false)
	end
end

-- @function Asset:getNumAnimations
function Asset:getNumAnimations()
	return #self.json.animations
end

-- @function Asset:getAnimationName
-- @desc
function Asset:getAnimationName(animationIndex)
	local anim = self.json.animations[animationIndex]
	return anim and anim.name
end

-- @function Asset:getAnimationIndexByName
-- @desc
function Asset:getAnimationIndexByName(animationName)
	if not self.animationsByName then
		self.animationsByName = {}
		for animIdx, anim in ipairs(self.json.animations) do
			if anim.name then
				self.animationsByName[anim.name] = animIdx
			end
		end
	end
	return self.animationsByName[animationName]
end

-- @function Asset:getMaxTimeForAnimation
-- @desc
function Asset:getMaxTimeForAnimation(animIdx)
	return self.maxTimeForAnimation[animIdx]
end

-- @function Asset:updateMaxTimeForAnimation
-- @desc
function Asset:updateMaxTimeForAnimation(animIdx, newTime)
	local t = self.maxTimeForAnimation[animIdx]
	if t == nil or t < newTime then
		t = newTime
	end
	self.maxTimeForAnimation[animIdx] = t
end

local ROOT_MATRIX = mat4.identity()
local DEFAULT_TRANSLATION = vec3.new(0, 0, 0)
local DEFAULT_ROTATION = quat.new(0, 0, 0, 0)
local DEFAULT_SCALE = vec3.new(1, 1, 1)
function Asset:_calculateTransform(cachedTransforms, nodeIdx, animChannel, time)
	local nodeJson = self.json.nodes[nodeIdx]
	local parentTransform = ROOT_MATRIX
	if nodeJson._parent then
		parentTransform = cachedTransforms[nodeJson._parent]
	end
	local outTransform = rawget(cachedTransforms, nodeIdx)
	if not outTransform then
		outTransform = cachedTransforms[nodeIdx]:clone()
	end

	if nodeJson.matrix then
		outTransform:mul(nodeJson.matrix, parentTransform)
	else
		local translation = nodeJson._translation or DEFAULT_TRANSLATION
		local rotation = nodeJson._rotation or DEFAULT_ROTATION
		local scale = nodeJson._scale or DEFAULT_SCALE

		if animChannel then
			translation, rotation, scale = animChannel:replace(time, translation, rotation, scale)
		end

		outTransform:translate(parentTransform, translation)
		outTransform:rotate(outTransform, rotation)
		outTransform:scale(outTransform, scale)
	end
end

function Asset:_calculateMorphWeights(cachedWeights, nodeIdx, animChannel, time)
	local nodeJson = self.json.nodes[nodeIdx]
	local weights = nodeJson.weights
	if weights == nil and nodeJson.mesh then
		local meshJson = self.json.meshes[nodeJson.mesh + 1]
		weights = meshJson.weights
	end

	if animChannel then
		weights = animChannel:evalWeights(time, weights)
	end
	cachedWeights[nodeIdx] = weights
end

-- @function Asset:buildTransformCacheForScene
-- @desc visits every node in the provided scene and calculates what its current
-- model transformation should be. This must be called before using
-- Asset:getTransformForNode, and (right now) happens eagerly at construction
-- time.
-- @param sceneIdx the scene index
function Asset:buildTransformCacheForScene(sceneIdx)
	local scene = self.json.scenes[sceneIdx]
	-- list of all node indexes that should update every frame
	scene._animatedNodes = {}
	-- list of all node indexes that need to be drawn
	scene._meshNodes = {}
	-- list of all node indexes that are skinned
	scene._skinnedMeshNodes = {}

	local function visit(parentIdx, nodeIdx, hasAnimatedAncestor)
		local nodeJson = self.json.nodes[nodeIdx]

		-- initialize node data
		nodeJson._parent = parentIdx
		if nodeJson.translation then
			nodeJson._translation = vec3.new(nodeJson.translation)
		end
		if nodeJson.rotation then
			nodeJson._rotation = quat.new(nodeJson.rotation)
		end
		if nodeJson.scale then
			nodeJson._scale = vec3.new(nodeJson.scale)
		end
		self.cachedTransforms[nodeIdx] = mat4.identity()

		local isAnimated = self.animationChannels[nodeIdx] or hasAnimatedAncestor
		if isAnimated then
			-- this is naturally sorted such that all children nodes come after
			-- their parent node
			table.insert(scene._animatedNodes, nodeIdx)
		else
			-- calculate static transform, will only happen once
			self:_calculateTransform(self.cachedTransforms, nodeIdx, nil, 0)
			self:_calculateMorphWeights(self.cachedWeights, nodeIdx, nil, 0)
		end

		if nodeJson.mesh then
			table.insert(scene._meshNodes, nodeIdx)

			if nodeJson.skin then
				table.insert(scene._skinnedMeshNodes, nodeIdx)
				local skinJson = self.json.skins[nodeJson.skin + 1]

				if skinJson.inverseBindMatrices then
					local raw, len, elements = self:getFFIArrayForAccessor(skinJson.inverseBindMatrices + 1)
					local idx = 1
					local inverseBindMatrices = {}
					for i = 0, len-1 do
						local start = i * elements
						inverseBindMatrices[idx] = mat4.new({
							raw[start+0],  raw[start+1],  raw[start+2],  raw[start+3],
							raw[start+4],  raw[start+5],  raw[start+6],  raw[start+7],
							raw[start+8],  raw[start+9],  raw[start+10], raw[start+11],
							raw[start+12], raw[start+13], raw[start+14], raw[start+15]
						})
						idx = idx + 1
					end
					nodeJson._inverseBindMatrices = inverseBindMatrices
				end
			end
		end

		if nodeJson.children then
			for _, childIdx in ipairs(nodeJson.children) do
				visit(nodeIdx, childIdx + 1, isAnimated)
			end
		end
	end

	for _, rootIdx in ipairs(scene.nodes) do
		visit(nil, rootIdx + 1, false)
	end
	-- cache lengths for extra super optimization
	scene._animatedNodes.n = #scene._animatedNodes
	scene._meshNodes.n = #scene._meshNodes
	scene._skinnedMeshNodes.n = #scene._skinnedMeshNodes
end

-- @function Asset:isNodeSkinned
-- @desc Returns true if the given scene node represents a skinned mesh.
-- @param nodeIdx
-- @param isSkinned
function Asset:isNodeSkinned(nodeIdx)
	return self.json.nodes[nodeIdx].skin ~= nil
end

-- @function Asset:newInstance
-- @desc Creates and returns a new instance object.
-- @param sceneIdx the scene this instance represents
-- @param assetInstance
local AssetInstance_mt
function Asset:newInstance(sceneIdx)
	if not self.ready then
		error("Attempted to create instance from non-ready asset.", 2)
	end
	local instance = setmetatable({}, AssetInstance_mt)
	instance.sceneIndex = sceneIdx
	instance.asset = self
	instance.cachedTransforms = setmetatable({}, {__index = self.cachedTransforms})
	instance.cachedJointMatrices = {}
	instance.cachedWeights = {}
	instance.activePlayHeads = {}
	instance.dirty = true

	instance:_buildJointMatrices()

	return instance
end

-- @class AssetInstance
-- @desc holds instance-specific data for an asset.
local AssetInstance = {isAssetInstance = true}
AssetInstance_mt = {
	__index = AssetInstance,
	__tostring = function(t)
		return string.format("instance(%s)", tostring(t.asset))
	end,
}
Asset.AssetInstance = AssetInstance

-- @function AssetInstance:getAsset
-- @desc
function AssetInstance:getAsset()
	return self.asset
end

-- @function AssetInstance:playAnimation
-- @desc plays the given animation from its start. The animation will stop once
-- it reaches the end, other directions/looping TODO
-- @param animIndex
function AssetInstance:playAnimation(animIndex)
	-- TODO: playheads should be object pooled, or maybe made static?
	self.activePlayHeads[animIndex] = {
		state = "active",
		time = 0,
		maxTime = self.asset:getMaxTimeForAnimation(animIndex),
	}
	self.dirty = true
end

-- @function AssetInstance:stopAnimation
-- @desc stops the given animation, resetting it to 0
-- @param animIndex
function AssetInstance:stopAnimation(animIndex)
	self.activePlayHeads[animIndex] = nil
	self.dirty = true
end

-- @function AssetInstance:getAnimationPlayhead
-- @desc stops the given animation, resetting it to 0
-- @param animIndex
local STOPPED_PLAYHEAD = { state = "inactive", time = 0, maxTime = 0 }
function AssetInstance:getAnimationPlayhead(animIndex)
	return self.activePlayHeads[animIndex] or STOPPED_PLAYHEAD
end

-- @function AssetInstance:updateAnimation
-- @desc Updates the internal timer of the given animation. To pause an
-- animation, you can choose to not call this, or pass in a value of 0.
-- @param animIndex
-- @param dt
function AssetInstance:updateAnimation(animIndex, dt)
	local playHead = self.activePlayHeads[animIndex]
	if playHead then
		playHead.time = playHead.time + dt
		if playHead.time >= playHead.maxTime then
			self:stopAnimation(animIndex)
		end
	end
	self.dirty = true
end

-- @function AssetInstance:playAllAnimations
-- @desc plays all animations from the beginning
function AssetInstance:playAllAnimations()
	for animIndex = 1, self.asset:getNumAnimations() do
		self:playAnimation(animIndex)
	end
end

-- @function AssetInstance:stopAllAnimations
-- @desc stops all animations, losing progress
function AssetInstance:stopAllAnimations()
	for animIndex = 1, self.asset:getNumAnimations() do
		self:stopAnimation(animIndex)
	end
end

-- @function Asset:updateAllAnimations
-- @param dt
function AssetInstance:updateAllAnimations(dt)
	for animIndex = 1, self.asset:getNumAnimations() do
		self:updateAnimation(animIndex, dt)
	end
end

-- @function AssetInstance:updateTransformCacheForScene
-- @desc recalculates the transforms for every animated node in the scene.
-- Should be called at least once after animation state updates to correctly
-- reflect that.
-- @param sceneIdx the scene index
function AssetInstance:updateTransformCache()
	if not self.dirty then
		return
	end
	self.dirty = false
	-- TODO: this needs optimizing
	local asset = self.asset
	local scene = asset.json.scenes[self.sceneIndex]
	for i = 1, scene._animatedNodes.n do
		local nodeIdx = scene._animatedNodes[i]
		local animated = false
		local channelsOnNode = asset.animationChannels[nodeIdx]
		if channelsOnNode then
			for animIdx, channel in pairs(channelsOnNode) do
				local activeAnimation = self.activePlayHeads[animIdx]
				-- TODO: we take the first active animation and and apply it.
				-- if there is more than one active animation, should we be
				-- mixing them together instead?
				if activeAnimation then
					animated = true
					local time = activeAnimation.time
					asset:_calculateTransform(self.cachedTransforms, nodeIdx, channel, time)
					asset:_calculateMorphWeights(self.cachedWeights, nodeIdx, channel, time)
					break
				end
			end
		end

		if not animated then
			asset:_calculateTransform(self.cachedTransforms, nodeIdx)
			asset:_calculateMorphWeights(self.cachedWeights, nodeIdx)
		end
	end

	for i = 1, scene._skinnedMeshNodes.n do
		self:_calculateJointMatrices(scene._skinnedMeshNodes[i])
	end
end

function AssetInstance:_buildJointMatrices()
	local asset = self.asset
	local scene = asset.json.scenes[self.sceneIndex]
	for skinIdx = 1, scene._skinnedMeshNodes.n do
		local nodeIdx = scene._skinnedMeshNodes[skinIdx]
		local nodeJson = asset.json.nodes[nodeIdx]
		local skinJson = asset.json.skins[nodeJson.skin + 1]

		local jointMatrices = {}
		for jointIdx = 1, #skinJson.joints do
			jointMatrices[jointIdx] = mat4.new()
		end

		self.cachedJointMatrices[nodeIdx] = jointMatrices
	end
end

do
	local tmpMatrix = mat4.new()
	function AssetInstance:_calculateJointMatrices(nodeIdx)
		local asset = self.asset
		local nodeJson = asset.json.nodes[nodeIdx]
		local skinJson = asset.json.skins[nodeJson.skin + 1]
		local rootIdx = skinJson.skeleton and skinJson.skeleton + 1 or nodeIdx
		local rootTransform = self.cachedTransforms[rootIdx]

		local inverseBindMatrices = nodeJson._inverseBindMatrices
		local jointMatrices = self.cachedJointMatrices[nodeIdx]
		local inverseRootTransform = tmpMatrix:invert(rootTransform)
		for jointIdx, jointNodeJsonIdx in ipairs(skinJson.joints) do
			local jointTransform = self.cachedTransforms[jointNodeJsonIdx + 1]

			local outMatrix = jointMatrices[jointIdx]
			outMatrix:identity()
			outMatrix:mul(inverseRootTransform, outMatrix)
			outMatrix:mul(jointTransform, outMatrix)
			if inverseBindMatrices then
				outMatrix:mul(inverseBindMatrices[jointIdx], outMatrix)
			end
		end
	end
end

-- @function Asset:iterateSceneMeshNodes
-- @desc iterates over the index of every scene node that has a mesh
-- associated. This can be used to draw every mesh in a scene
-- @return iterator, data, initalIndex
function AssetInstance:iterateMeshNodes()
	local scene = self.asset.json.scenes[self.sceneIndex]
	if not scene then
		return nil
	end

	return ipairs(scene._meshNodes)
end

-- @function AssetInstance:getTransformForNode
-- @desc returns the cached model transformation for the given scene node. The
-- returned transform will _only_ be valid if the transform cache has been
-- built and updated for this instance
-- @see Asset:buildTransformCacheForScene
-- @see Asset:updateTransformCacheForScene
-- @param nodeIdx the node index
-- @return mat4
function AssetInstance:getTransformForNode(nodeIdx)
	return self.cachedTransforms[nodeIdx]
end

-- @function AssetInstance:getJointMatricesForNode
-- @desc Returns a list of calculated joint matrices, for use with skinned
-- meshes. If the given node isn't skinned, returns nil.
-- @param jointMatrices
function AssetInstance:getJointMatricesForNode(nodeIdx)
	return self.cachedJointMatrices[nodeIdx]
end

-- @function AssetInstance:getMorphWeightsForNode
-- @desc Returns a list of morph target weights for the given node
-- meshes. If the given node isn't a morph target, returns nil.
-- @param weights
function AssetInstance:getMorphWeightsForNode(nodeIdx)
	return self.cachedWeights[nodeIdx]
end

-- @class GLTFMaterial
-- @desc Materials hold the color/texture/etc of a given mesh primitive.
-- Materials can be reused across primitives. API calls tbd
local GLTFMaterial = {}
GLTFMaterial_mt = {
	__index = GLTFMaterial,
	__tostring = function(t)
		if t.name then
			return string.format("material %d(%q)", t.index, t.name)
		else
			return string.format("material %d", t.index)
		end
	end,
}

-- @function GLTFMaterial:getBaseColor
-- @desc returns the base color of the material. This should be passed to
-- love.graphics.setColor().
-- @return baseColor
function GLTFMaterial:getBaseColor()
	return self.baseColor
end

-- @function GLTFMaterial:getBaseTexture
-- @desc returns the base texture of the material. the texture itself should
-- already be applied to the mesh.
-- @return baseTexture, baseTexCoord
function GLTFMaterial:getBaseTexture()
	return self.baseColorTexture, self.baseColorTexCoord
end

-- @function GLTFMaterial:getMetallicRoughnessFactors
-- @desc returns parameters defining the metallic-roughness of the the model.
-- This should be used in conjunction with the asset:getMetallicRoughnessTexture().
-- The metallic factor is 0 for non metallic, and 1 for metallic.
-- The roughness factor is 0 for perfectly smooth, and 1 for perfectly rough.
-- @return metallicFactor, roughnessFactor
function GLTFMaterial:getMetallicRoughnessFactors()
	return self.metallicFactor, self.roughnessFactor
end

-- @function GLTFMaterial:getMetallicRoughnessTexture
-- @desc returns a texture defining changes in metallic-roughness across a
-- surface. should be used in conjunction with
-- Asset:getMetallicRoughnessFactors().
-- Within the texture, the blue channel should be used for metalness, and the
-- green channel should be used for roughness.
-- @return metallicRoughnessTexture, metallicRoughnessTexCoord
function GLTFMaterial:getMetallicRoughnessTexture()
	return self.metallicRoughnessTexture, self.metallicRoughnessTexCoord
end

-- @function GLTFMaterial:getNormalMapInfo
-- @desc returns a texture defining normals across a surface, as well as a
-- scale to be applied uniformly.
-- For details on how to use normalMapTexture, see the
-- [glTF spec](https://github.com/KhronosGroup/glTF/tree/master/specification/2.0#materialnormaltexture).
-- For details on how to apply the normal map scale, see
-- [this](https://github.com/KhronosGroup/glTF/tree/master/specification/2.0#materialnormaltexture).
-- @return normalMapScale, normalMapTexture, normalMapTexCoord
function GLTFMaterial:getNormalMapInfo()
	return self.normalTexScale, self.normalTexture, self.normalTexCoord
end

-- @function GLTFMaterial:getOcclusionInfo
-- @desc returns a texture defining occlusion across a surface.
-- Within the texture, the red channel should be used for occluded-ness. 0 is
-- fully occluded, and 1 is not occluded.
-- @return occlusionMapStrength, occlusionMapTexture, occlusionMapTexCoord
function GLTFMaterial:getOcclusionMapInfo()
	return self.occlusionTexStrength, self.occlusionTexture, self.occlusionTexCoord
end

-- @function GLTFMaterial:getEmissiveInfo
-- @desc returns a texture defining emissiveness across a surface. For
-- interpretation, see the
-- [spec](https://github.com/KhronosGroup/glTF/blob/master/specification/2.0/README.md).
-- @return emissiveMapColor, emissiveMapTexture, emissiveMapTexCoord
function GLTFMaterial:getEmissiveInfo()
	return self.emissiveColor, self.emissiveTexture, self.emissiveTexCoord
end

-- @function GLTFMaterial:isBlended
-- @desc returns whether or not the given primitive uses the BLEND alpha mode.
-- This means that its material is semi-translucent and will probably need
-- special support to render correctly.
-- @return isBlended
function GLTFMaterial:isBlended()
	return self.alphaMode == "BLEND"
end

-- @function GLTFMaterial:isDoubleSided
-- @desc returns true if mesh culling should be turned off for this material.
-- This effectively allows the material to render both sides of its geometry.
-- By default, every other material should cull backfaces with a clockwise
-- winding order.
-- @return isBlended
function GLTFMaterial:isDoubleSided()
	return self.doubleSided
end

-- @function GLTFMaterial:getAlphaCutoff
-- @desc returns a cutoff value, 0-1. Texels with an alpha value below the
-- cutoff should be discarded in the fragment shader when drawing this primitive.
-- @return cutoff
function GLTFMaterial:getAlphaCutoff()
	return self.alphaCutoff
end

-- @function GLTFMaterial:getMaterialModel
-- @desc returns the type of material definition that this object provides.
-- These can be "unlit" for materials that don't have a defined PBR pipeline,
-- or "metallicRoughness" for PBR metallic roughness.
-- @return materialModel
function GLTFMaterial:getMaterialModel()
	return self.materialModel
end

-- @class GLTFPrimitive
-- @desc Each GLTF mesh is made up of multiple primitives. A primitive is
-- closer to a `love.graphics` Mesh, in that it has attribute data and a
-- material and can be drawn in a single draw call.
local GLTFPrimitive = {}
GLTFPrimitive_mt = {
	__index = GLTFPrimitive,
	__tostring = function(t)
		if not t.index then return "?" end
		return string.format("%s, primitive %d", tostring(t.mesh), t.index)
	end,
}
Asset.GLTFPrimitve = GLTFPrimitive

-- @function GLTFPrimitive:getMaterial
-- @desc returns the material object associated with this primitive
-- @return material
function GLTFPrimitive:getMaterial()
	return self.material
end

-- @function GLTFPrimitive:getLoveMesh
-- @desc returns the love.graphics mesh associated with this primitive. passing
-- this to love.graphics.draw() will draw the primitive.
-- @return loveMesh
function GLTFPrimitive:getLoveMesh()
	return self.rootMesh
end

-- @function GLTFPrimitive:getNumMorphTargets
-- @return numTargets
-- @return loveMesh
function GLTFPrimitive:getNumMorphTargets(targetIdx)
	return #self.morphTargets
end

-- @function GLTFPrimitive:getMorphTargetLoveMesh
-- @desc returns the love.graphics mesh associated with the given morph target
-- index. In your renderer you should attach these as vertex attributes.
-- @argument targetIdx
-- @return loveMesh
function GLTFPrimitive:getMorphTargetData(targetIdx)
	return self.morphTargets[targetIdx]
end

-- @function GLTFPrimitive:hasByteJoints
-- @desc returns whether or not the given primitive represents joint indices
-- using normalized byte values. When false, the primitive either does not have
-- joints, or uses unorm16 joints. This information can be used to denormalize
-- these indices in the vertex shader.
-- @return hasByteJoints
function GLTFPrimitive:hasByteJoints()
	return self._hasByteJoints
end

-- @class GLTFMesh
-- @desc A GLTF mesh is a simple composite object: it is made up of primitives,
-- and each primitive is the thing that will actually submit a
-- `love.graphics.draw()` call etc.
local GLTFMesh = {}
GLTFMesh_mt = {
	__index = GLTFMesh,
	__tostring = function(t)
		if t.name then
			return string.format("mesh %d(%q)", t.index, t.name)
		else
			return string.format("mesh %d", t.index)
		end
	end,
}
Asset.GLTFMesh = GLTFMesh

-- @function GLTFMesh:getPrimitives
-- @desc Returns a list of GLTFPrimitive objects
-- @return primitives
function GLTFMesh:getPrimitives()
	return self.primitives
end

-- AnimationChannels are not exposed via the API, yet.
local AnimationChannel = {}
AnimationChannel_mt = {
	__index = AnimationChannel,
	__tostring = function(t)
		if t.name then
			return string.format("animation %d(%q)", t.index, t.name)
		else
			return string.format("animation %d", t.index)
		end
	end,
}
Asset.AnimationChannel = AnimationChannel

function AnimationChannel:addPathToChannel(channelJson, samplerJson)
	local pathData = {}
	pathData.path = channelJson.target.path
	pathData.tween = samplerJson.interpolation or "LINEAR"
	if pathData.tween == "CUBICSPLINE" then
		self:warnf("Cubic spline tweening not yet implmented, degrading to STEP")
		pathData.tween = "STEP"
	end
	self:buildFrames(pathData, samplerJson)
	self.pathData[pathData.path] = pathData
end

local function normalizeInt(input, componentType)
	if componentType == "int8" then
		return math.max(input / 127, -1)
	elseif componentType == "uint8" then
		return input / 255
	elseif componentType == "int16" then
		return math.max(input / 32767, -1)
	elseif componentType == "uint16" then
		return input / 65535
	end
end

function AnimationChannel:buildFrames(pathData, samplerJson)
	local timeline, len = self.asset:getFFIArrayForAccessor(samplerJson.input + 1)
	local keyFrameData, len2, elements = self.asset:getFFIArrayForAccessor(samplerJson.output + 1)
	if pathData.path == 'weights' then
		-- note that we are guessing number of elements based on number of input keyframes
		-- I do not know if this is spec compliant? but it seems to work
		elements = math.floor(len2 / len)
		len2 = math.floor(len2 / elements)
	end

	if len ~= len2 then
		self.asset:warnf("animation: input keyframes(%d) don't match up with output keyframes(%d)?", len, len2)
		len = math.min(len, len2)
	end

	local accessor = self.asset.json.accessors[samplerJson.output + 1]
	local componentType = ACCESSOR_COMPONENT_TYPES[accessor.componentType]

	pathData.frames = {}
	local frameIdx = 0
	self.asset:updateMaxTimeForAnimation(self.animIdx, timeline[len - 1])
	for i = 0, len - 1 do
		local keyFrame = {}
		if componentType ~= "float" then
			for j = 1, elements do
				keyFrame[j] = normalizeInt(keyFrameData[frameIdx], componentType)
				frameIdx = frameIdx + 1
			end
		else
			for j = 1, elements do
				keyFrame[j] = keyFrameData[frameIdx]
				frameIdx = frameIdx + 1
			end
		end

		if pathData.path == "rotation" then
			keyFrame = quat.new(keyFrame)
		elseif pathData.path == "translation" or pathData.path == "scale" then
			keyFrame = vec3.new(keyFrame)
		elseif pathData.path == "weights" then
			keyFrame = keyFrame
		end

		local frame = { time = timeline[i], keyFrame = keyFrame }
		pathData.frames[i + 1] = frame
	end
end

-- TODO: pass in last valid frame index
function AnimationChannel:findFramesForTime(pathData, globalTime)
	for frameIdx, frame in ipairs(pathData.frames) do
		if frame.time > globalTime then
			return math.max(1, frameIdx - 1), frameIdx
		end
	end
	local frameIdx = #pathData.frames
	return frameIdx, frameIdx
end

local function arrayLerp(a1, a2, t)
	local out = {}
	for i = 1, #a1 do
		out[i] = a1[i] + (a2[i] - a1[i]) * t
	end
	return out
end

function AnimationChannel:eval(pathData, globalTime, parentValue)
	local frameIdx1, frameIdx2 = self:findFramesForTime(pathData, globalTime)
	local keyFrame1 = pathData.frames[frameIdx1].keyFrame
	if pathData.tween == "STEP" or frameIdx1 == frameIdx2 then
		return keyFrame1
	end

	local keyFrame2 = pathData.frames[frameIdx2].keyFrame
	local time1 = pathData.frames[frameIdx1].time
	local time2 = pathData.frames[frameIdx2].time
	local t = (globalTime - time1) / (time2 - time1)
	-- TODO: this makes a new keyframe object every frame. we should reuse a
	-- single mutable object instead
	if pathData.tween == "LINEAR" then
		if pathData.path == "rotation" then
			return quat.slerp(keyFrame1, keyFrame2, t)
		elseif pathData.path == "weights" then
			return arrayLerp(keyFrame1, keyFrame2, t)
		else
			return vec3.lerp(keyFrame1, keyFrame2, t)
		end
	end

	-- fallthrough for unrecognized/unimplemented tweens
	return keyFrame1
end

function AnimationChannel:replace(globalTime, translation, rotation, scale)
	if self.pathData.translation then
		translation = self:eval(self.pathData.translation, globalTime, translation)
	end

	if self.pathData.rotation then
		rotation = self:eval(self.pathData.rotation, globalTime, rotation)
	end

	if self.pathData.scale then
		scale = self:eval(self.pathData.scale, globalTime, scale)
	end

	return translation, rotation, scale
end

function AnimationChannel:evalWeights(globalTime, weights)
	if self.pathData.weights then
		return self:eval(self.pathData.weights, globalTime, weights)
	end
end

return Asset
