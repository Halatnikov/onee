return [[#pragma language glsl3
// vim: ft=glsl :
// The "official" reference shader is here, we're only implementing a part of this
// https://github.com/KhronosGroup/glTF-Sample-Viewer/tree/master/src/shaders

varying vec4 VaryingAltTexCoord;

#ifdef PIXEL
uniform float alphaCutoff;
uniform bool isBlended;

uniform bool useAltBaseTextureCoords;

vec2 getUV(bool useAltCoords) {
	if(useAltCoords) {
		return VaryingAltTexCoord.xy;
	}
	else
	{
		return VaryingTexCoord.xy;
	}
}

vec4 effect(vec4 baseColor, Image baseTex, vec2 unused, vec2 screen_coords) {
	vec4 color = Texel(baseTex, getUV(useAltBaseTextureCoords)) * baseColor;
	if (color.a < alphaCutoff) {
		discard;
	}
	if (!isBlended) {
		color.a = 1.0;
	}
	return color;
}
#endif

#ifdef VERTEX
uniform mat4 model;
uniform mat4 world;
uniform mat4 projection;
uniform mat4 view;

attribute vec4 gltfVertexNormal;
attribute vec4 gltfVertexTangent;

uniform bool useSkinning;
uniform bool useByteJoints;
uniform mat4 jointMatrices[12 * 4];
attribute vec4 gltfVertexJoint;
attribute vec4 gltfVertexWeight;

uniform int morphTargetConfig;
uniform float morphTargetWeights[6];
attribute vec3 gltfVertexMorphData0;
attribute vec3 gltfVertexMorphData1;
attribute vec3 gltfVertexMorphData2;
attribute vec3 gltfVertexMorphData3;
attribute vec3 gltfVertexMorphData4;
attribute vec3 gltfVertexMorphData5;

attribute vec4 gltfVertexTexCoord1;
const float uint8Max  = 0xFF;
const float uint16Max = 0xFFFF;

vec4 position(mat4 unused, vec4 vertex_position) {
	vec4 vertex_normal = gltfVertexNormal;
	vec4 vertex_tangent = gltfVertexTangent;

	switch(morphTargetConfig) {
		case 1:
		{
			// 6 pos
			vertex_position.xyz += morphTargetWeights[0] * gltfVertexMorphData0;
			vertex_position.xyz += morphTargetWeights[1] * gltfVertexMorphData1;
			vertex_position.xyz += morphTargetWeights[2] * gltfVertexMorphData2;
			vertex_position.xyz += morphTargetWeights[3] * gltfVertexMorphData3;
			vertex_position.xyz += morphTargetWeights[4] * gltfVertexMorphData4;
			vertex_position.xyz += morphTargetWeights[5] * gltfVertexMorphData5;
		}
		break;
		case 2:
		{
			// 3 pos, 3 normal
			vertex_position.xyz  += morphTargetWeights[0] * gltfVertexMorphData0;
			vertex_normal.xyz    += morphTargetWeights[0] * gltfVertexMorphData1;
			vertex_position.xyz  += morphTargetWeights[1] * gltfVertexMorphData2;
			vertex_normal.xyz    += morphTargetWeights[1] * gltfVertexMorphData3;
			vertex_position.xyz  += morphTargetWeights[2] * gltfVertexMorphData4;
			vertex_normal.xyz    += morphTargetWeights[2] * gltfVertexMorphData5;
		}
		break;
		case 3:
		{
			// 2 pos, 2 normal, 2 tangent
			vertex_position.xyz   += morphTargetWeights[0] * gltfVertexMorphData0;
			vertex_normal.xyz     += morphTargetWeights[0] * gltfVertexMorphData1;
			vertex_tangent.xyz    += morphTargetWeights[0] * gltfVertexMorphData2;
			vertex_position.xyz   += morphTargetWeights[1] * gltfVertexMorphData3;
			vertex_normal.xyz     += morphTargetWeights[1] * gltfVertexMorphData4;
			vertex_tangent.xyz    += morphTargetWeights[1] * gltfVertexMorphData5;
		}
		break;
	}

	if (useSkinning) {
		float jointFactor = useByteJoints ? uint8Max : uint16Max;
		mat4 skinMatrix =
			gltfVertexWeight.x * jointMatrices[int(jointFactor * gltfVertexJoint.x)] +
			gltfVertexWeight.y * jointMatrices[int(jointFactor * gltfVertexJoint.y)] +
			gltfVertexWeight.z * jointMatrices[int(jointFactor * gltfVertexJoint.z)] +
			gltfVertexWeight.w * jointMatrices[int(jointFactor * gltfVertexJoint.w)];
		vertex_position = skinMatrix * vertex_position;
	}

	VaryingAltTexCoord = gltfVertexTexCoord1;
	mat4 mvp = projection * view * world * model;
	return mvp * vertex_position;
}
#endif
]]
