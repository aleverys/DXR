#include "AoCommon.hlsl"

// ---[ Closest Hit Shader ]---

[shader("closesthit")]
void ClosestHit(inout HitInfo payload, Attributes attrib)
{
	payload.isHit = true;
	
	uint triangleIndex = PrimitiveIndex();
	float3 barycentrics = float3((1.0f - attrib.uv.x - attrib.uv.y), attrib.uv.x, attrib.uv.y);
	VertexAttributes vertex = GetVertexAttributes(triangleIndex, barycentrics);

	payload.hitPointNormal = vertex.normal;
	payload.hitPointPosition = vertex.position;
	
}
