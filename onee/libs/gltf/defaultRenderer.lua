-- @class Renderer
-- @desc This is a reference rendering path for GLTF assets.
local Renderer = {}
local Renderer_mt = {__index = Renderer}

local base = (...):gsub("%.[^.]+$",".")
local shaderSource = require(base..'defaultShader')
local mat4 = require 'onee/libs/gltf/cpml.modules.mat4'
local vec3 = require 'onee/libs/gltf/cpml.modules.vec3'

function Renderer.new()
	local self = setmetatable({}, Renderer_mt)
	self.drawList = {}
	self.blendedDrawList = {}
	self.allDrawLists = {self.drawList, self.blendedDrawList}
	self.drawPool = {{}}
	self.shader = love.graphics.newShader(shaderSource)

	local w, h = love.graphics.getDimensions()
	local xmag = w / h
	local n = mat4.from_ortho(-xmag, xmag, 1, -1, .01, 10)
	n:translate(n, vec3.new(-.5, -.5, -1))
	self:setProjectionMatrix(n)
	return self
end

function Renderer:useExternalCanvas()
	self.usingCanvas = true
	self:setProjectionMatrix(self.projectionMatrix)
end

function Renderer:setCanvases(canvas, depthStencilCanvas)
	if canvas == nil then
		self.usingCanvas = false
		self.canvasSetup = nil
	else
		self.usingCanvas = true
		self.canvasSetup = {
			canvas,
			stencil = depthStencilCanvas ~= nil,
			depth = depthStencilCanvas ~= nil,
			depthStencil = depthStencilCanvas,
		}
	end
	self:setProjectionMatrix(self.projectionMatrix)
end

function Renderer:setShader(shader)
	self.shader = shader
	self:setProjectionMatrix(self.projectionMatrix)
end

function Renderer:setProjectionMatrix(projectionMatrix)
	self.projectionMatrix = projectionMatrix
	if self.usingCanvas then
		--[[
		per slime:
		> projection matrices in love are assumed to be 'native'/unflipped when
		> rendering to a canvas, and flipped on the y axis when rendering to the
		> screen (when opengl/opengl es is used). The mesh cull mode code assumes that
		> as well and internally inverts itself based on whether it's rendering to a
		> canvas, to accomodate that
		This flip replicates that behavior
		--]]
		local mat = mat4.new():scale(projectionMatrix, vec3.new(1, -1, 1))
		self.shader:send("projection", "column", mat)
	else
		self.shader:send("projection", "column", self.projectionMatrix)
	end
end

function Renderer:setViewMatrix(viewMatrix)
	self.shader:send("view", "column", viewMatrix)
end

function Renderer:addToDrawList(obj, worldTransform)
	if obj.isAssetInstance then
		return self:addAssetInstanceToDrawList(obj, worldTransform)
	else
		return self:addDrawableToDrawList(obj, worldTransform)
	end
end

function Renderer:addAssetInstanceToDrawList(assetInstance, worldTransform)
	local asset = assetInstance:getAsset()
	assetInstance:updateTransformCache()

	local n = #self.drawPool
	--TODO: this code has been aggressively inlined for performance: maybe there's a way
	--we can still provide a public API without losing the performance
	--associated with doing this?
	--[[
	for _, nodeIdx in assetInstance:iterateMeshNodes() do
		local meshIdx = asset:getMeshIndexForNode(nodeIdx)
		local mesh = asset:loadMesh(meshIdx)
		local modelTransform = assetInstance:getTransformForNode(nodeIdx)
		local jointMatrices = assetInstance:getJointMatricesForNode(nodeIdx)
		local morphWeights = assetInstance:getMorphWeightsForNode(nodeIdx)
		for _, primitive in ipairs(mesh:getPrimitives()) do
	]]--
	for _, nodeIdx in ipairs(asset.json.scenes[assetInstance.sceneIndex]._meshNodes) do
		local meshIdx = asset.json.nodes[nodeIdx].mesh + 1
		local mesh = asset.json.meshes[meshIdx]._meshObject
		local modelTransform = assetInstance.cachedTransforms[nodeIdx]
		local jointMatrices = assetInstance.cachedJointMatrices[nodeIdx]
		local morphWeights = assetInstance.cachedWeights[nodeIdx]
		for _, primitive in ipairs(mesh.primitives) do
			local drawList = self.drawList
			--if primitive:getMaterial():isBlended() then
			if primitive.material.alphaMode == 'BLEND' then
				drawList = self.blendedDrawList
			end
			local t = self.drawPool[n]
			if t then
				self.drawPool[n] = nil
				n = n - 1
			else
				t = {}
			end
			t.primitive = primitive
			t.worldTransform = worldTransform
			t.modelTransform = modelTransform
			t.jointMatrices = jointMatrices
			t.morphWeights = morphWeights
			drawList[#drawList + 1] = t
		end
	end
end

-- use for non-mesh things
function Renderer:addDrawableToDrawList(drawable, worldTransform)
	local n = #self.drawPool
	local t = self.drawPool[n] or {}
	t.drawable = drawable
	t.worldTransform = worldTransform
	self.drawPool[n] = nil
	table.insert(self.drawList, t)
end

local function bindMorphTargets(primitive, shader, morphWeights)
	-- TODO: we allocate two tables and a sort function, don't do that
	local targets = {}
	for i = 1, #morphWeights do
		-- filter out unused targets
		if morphWeights[i] > .0000001 then
			table.insert(targets, i)
		end
	end

	-- TODO: allow users to pick targetConfig 2/3
	local targetConfig = 1
	shader:send("morphTargetConfig", targetConfig)
	-- 1 -> 6, 2 -> 3, 3 -> 2
	local maxTargets = 6 / targetConfig

	-- because we supply morph targets as attributes, we have a fixed number we
	-- can support at one time. cull the least important to keep us under the cap
	if #targets > maxTargets then
		table.sort(targets, function(leftidx, rightidx)
			return morphWeights[leftidx] > morphWeights[rightidx]
		end)
		for i = 1, #targets - maxTargets do
			table.remove(targets)
		end
	end

	local sortedMorphWeights = { 0, 0, 0, 0, 0, 0 }
	local rootMesh = primitive:getLoveMesh()
	local dataIdx = 0
	for sortedIdx, targetIdx in ipairs(targets) do
		sortedMorphWeights[sortedIdx] = morphWeights[targetIdx]

		local targetData = primitive:getMorphTargetData(targetIdx)

		do -- position
			local meshData = targetData["VertexPosition"]
			local shaderAttribute = "gltfVertexMorphData" .. dataIdx
			rootMesh:attachAttribute(shaderAttribute, meshData.mesh, 'pervertex', meshData.key)
			dataIdx = dataIdx + 1
		end
		if targetConfig > 1 then -- normals
			local meshData = targetData["VertexNormal"]
			local shaderAttribute = "gltfVertexMorphData" .. dataIdx
			rootMesh:attachAttribute(shaderAttribute, meshData.mesh, 'pervertex', meshData.key)
			dataIdx = dataIdx + 1
		end
		if targetConfig > 2 then -- tangents
			local meshData = targetData["VertexTangent"]
			local shaderAttribute = "gltfVertexMorphData" .. dataIdx
			rootMesh:attachAttribute(shaderAttribute, meshData.mesh, 'pervertex', meshData.key)
			dataIdx = dataIdx + 1
		end
	end

	shader:send("morphTargetWeights", unpack(sortedMorphWeights))
end

local IDENTITY_MATRIX = mat4.identity()
function Renderer:draw()
	love.graphics.push('all')
	if self.canvasSetup then
		love.graphics.setCanvas(self.canvasSetup)
		love.graphics.clear()
	end
	love.graphics.setMeshCullMode('back')
	love.graphics.setDepthMode('lequal', true)
	love.graphics.setShader(self.shader)

	for _, drawList in ipairs(self.allDrawLists) do
		if drawList == self.blendedDrawList then
			-- TODO: Z-sort. this means pulling world pos out of the model matrix,
			-- which should be affine anyways so it's cool
			self.shader:send("isBlended", true)
			love.graphics.setBlendMode('alpha', 'alphamultiply')
		else
			self.shader:send("isBlended", false)
			love.graphics.setBlendMode('replace', 'alphamultiply')
		end

		for _, cmd in ipairs(drawList) do
			self.shader:send('world', "column", cmd.worldTransform or IDENTITY_MATRIX)
			self.shader:send('model', "column", cmd.modelTransform or IDENTITY_MATRIX)
			if cmd.jointMatrices then
				self.shader:send("useSkinning", true)
				self.shader:send("jointMatrices", "column", unpack(cmd.jointMatrices))
			else
				self.shader:send("useSkinning", false)
			end

			if cmd.morphWeights then
				bindMorphTargets(cmd.primitive, self.shader, cmd.morphWeights)
			else
				self.shader:send("morphTargetConfig", 0)
			end

			if cmd.drawable then
				love.graphics.draw(cmd.drawable)
			else
				local material = cmd.primitive:getMaterial()
				self.shader:send("alphaCutoff", material:getAlphaCutoff())
				local _, baseTexCoord = material:getBaseTexture()
				self.shader:send("useAltBaseTextureCoords", baseTexCoord == 1)
				love.graphics.setColor(material:getBaseColor())

				self.shader:send("useByteJoints", cmd.primitive:hasByteJoints())
				if material:isDoubleSided() then
					love.graphics.setMeshCullMode('none')
					love.graphics.draw(cmd.primitive:getLoveMesh())
					love.graphics.setMeshCullMode('back')
				else
					love.graphics.draw(cmd.primitive:getLoveMesh())
				end
			end
		end

		for i = #drawList, 1, -1 do
			local t = drawList[i]
			t.modelTransform = nil
			t.drawable = nil
			t.primitive = nil
			t.jointMatrices = nil
			t.morphWeights = nil
			table.insert(self.drawPool, t)
			drawList[i] = nil
		end
	end

	love.graphics.pop()
end

return Renderer
