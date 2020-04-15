struct HitInfo{
	float4 hitPointPosition;
	float4 hitPointNormal;
	bool isHit;
};

struct Attributes 
{
	float2 uv;
};

struct VertexAttributes
{
	float3 position;
	float3 normal;
	float2 uv;
};

RaytracingAccelerationStructure TLAS : register(t0);

ByteAddressBuffer indices : register(t1);

ByteAddressBuffer vertices : register(t2);

uint3 GetIndices(uint triangleIndex)
{
	uint baseIndex = (triangleIndex * 3);
	int address = (baseIndex * 4);
	return indices.Load3(address);
}

VertexAttributes GetVertexAttributes(uint triangleIndex, float3 barycentrics)
{
	uint3 indices = GetIndices(triangleIndex);
	VertexAttributes v;
	v.position = float3(0, 0, 0);
	v.normal = float3(0,0,0);
	v.uv = float2(0, 0);

	for (uint i = 0; i < 3; i++)
	{
		int address = (indices[i] * 8) * 4;
		v.position += asfloat(vertices.Load3(address)) * barycentrics[i];
		address += (3 * 4);
		v.normal += asfloat(vertices.Load3(address))* barycentrics[i];
		address += (3*4);
		v.uv += asfloat(vertices.Load2(address)) * barycentrics[i];
	}
	return v;
}


[shader("closesthit")]
void ClosestHit(inout HitInfo payload, Attributes attrib)
{
	payload.isHit = true;
	
	uint triangleIndex = PrimitiveIndex();
	float3 barycentrics = float3((1.0f - attrib.uv.x - attrib.uv.y), attrib.uv.x, attrib.uv.y);
	VertexAttributes vertex = GetVertexAttributes(triangleIndex, barycentrics);

	payload.hitPointNormal = float4(vertex.normal,0.f);
	payload.hitPointPosition = float4(vertex.position,1.f);
	
}
