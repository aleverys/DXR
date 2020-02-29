#include "Common.hlsl"
// ---[ Closest Hit Shader ]---

[shader("closesthit")]
void ClosestHit(inout HitInfo payload, Attributes attrib)
{
	uint triangleIndex = PrimitiveIndex();
	float3 barycentrics = float3((1.0f - attrib.uv.x - attrib.uv.y), attrib.uv.x, attrib.uv.y);
	VertexAttributes vertex = GetVertexAttributes(triangleIndex, barycentrics);

	int2 coord = floor(vertex.uv * textureResolution.x);
	float3 color = albedo.Load(int3(coord, 0)).rgb;

	payload.ShadedColorAndHitT = float4(color, RayTCurrent());
}