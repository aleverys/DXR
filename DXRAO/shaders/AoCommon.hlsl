#include "Random.hlsl"

#define PI 3.141592653

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

cbuffer RayConfig : register(b0)
{
	uint samplesPerPixel;
	float maxRayDistance;
	float intensity;
	float maxNormalBias;
};

cbuffer ViewCB : register(b1)
{
	float4 bufferSizeAndInvSize;
	float3 translatedWorldCameraOrigin;
	float padding01;
	float3 worldCameraOrigin;
	uint startFrameIndex;
    float4x4 svPositionToTranslatedWorld;
}

RWTexture2D<float> RWOcclusionMaskUAV : register(u0);

RWTexture2D<float> RWHitDistanceUAV : register(u1);

RaytracingAccelerationStructure TLAS : register(t0);

ByteAddressBuffer indices : register(t1);

ByteAddressBuffer vertices : register(t2);

Texture2D depthBuffer : register(t3);

Texture2D<float4> normalBuffer : register(t4);

SamplerState gsamPointWrap        : register(s0);
SamplerState gsamPointClamp       : register(s1);
SamplerState gsamLinearWrap       : register(s2);
SamplerState gsamLinearClamp      : register(s3);
SamplerState gsamAnisotropicWrap  : register(s4);
SamplerState gsamAnisotropicClamp : register(s5);
SamplerComparisonState gsamShadow : register(s6);

float4 CosineSampleHemisphere( float2 E )
{
	float Phi = 2 * PI * E.x;
	float CosTheta = sqrt( E.y );
	float SinTheta = sqrt( 1 - CosTheta * CosTheta );

	float3 H;
	H.x = SinTheta * cos( Phi );
	H.y = SinTheta * sin( Phi );
	H.z = CosTheta;

	float PDF = CosTheta * (1.0 /  PI);

	return float4( H, PDF );
}

float3x3 GetTangentBasis( float3 TangentZ )
{
	const float Sign = TangentZ.z >= 0 ? 1 : -1;
	const float a = -rcp( Sign + TangentZ.z );
	const float b = TangentZ.x * TangentZ.y * a;
	
	float3 TangentX = { 1 + Sign * a * pow( TangentZ.x,2), Sign * b, -Sign * TangentZ.x };
	float3 TangentY = { b,  Sign + a * pow( TangentZ.y,2 ), -TangentZ.y };

	return float3x3( TangentX, TangentY, TangentZ );
}

float3 TangentToWorld( float3 Vec, float3 TangentZ )
{
	return mul( Vec, GetTangentBasis( TangentZ ) );
}

void GenerateCosineNormalRay(
	float3 WorldPosition,
	float3 WorldNormal,
	inout RandomSequence RandSequence,
	out float3 RayOrigin,
	out float3 RayDirection,
	out float RayTMin,
	out float RayTMax
)
{

	float2 BufferSize = bufferSizeAndInvSize.xy;
	uint DummyVariable;
	float2 RandSample = RandomSequence_GenerateSample2D(RandSequence, DummyVariable);

	float4 Direction_Tangent = CosineSampleHemisphere(RandSample);
	float3 Direction_World = TangentToWorld(Direction_Tangent.xyz, WorldNormal);

	RayOrigin = WorldPosition;
	RayDirection = Direction_World;
	RayTMin = 0.0;
	RayTMax = maxRayDistance;
}

void ApplyPositionBias(inout RayDesc Ray, const float3 WorldNormal, const float maxNormalBias)
{
	const float MinBias = 0.01f;
	const float MaxBias = max(MinBias, maxNormalBias);
	const float NormalBias = lerp(MaxBias, MinBias, saturate(dot(WorldNormal, Ray.Direction)));

	Ray.Origin += WorldNormal * NormalBias;
}

float3 ReconstructWorldPositionFromDeviceZ(uint2 PixelCoord, float DeviceZ)
{
	float4 TranslatedWorldPosition = mul(float4(PixelCoord + 0.5, DeviceZ, 1), svPositionToTranslatedWorld);
	TranslatedWorldPosition.xyz /= TranslatedWorldPosition.w;
	return TranslatedWorldPosition.xyz + worldCameraOrigin;
}

float3 ReconstructTranslatedWorldPositionFromDeviceZ(uint2 PixelCoord, float DeviceZ)
{
	float4 TranslatedWorldPosition = mul(float4(PixelCoord + 0.5, DeviceZ, 1), svPositionToTranslatedWorld);
	TranslatedWorldPosition.xyz /= TranslatedWorldPosition.w;
	return TranslatedWorldPosition.xyz;
}

void ApplyCameraRelativeDepthBias(inout RayDesc Ray, uint2 PixelCoord, float DeviceZ, const float3 WorldNormal, const float AbsoluteNormalBias)
{
	float3 WorldPosition = ReconstructTranslatedWorldPositionFromDeviceZ(PixelCoord, DeviceZ);
	float3 CameraDirection = WorldPosition - translatedWorldCameraOrigin;
	float DistanceToCamera = length(CameraDirection);
	CameraDirection = normalize(CameraDirection);
	float Epsilon = 1.0e-4;
	float RelativeBias = DistanceToCamera * Epsilon;
	float RayBias = max(RelativeBias, AbsoluteNormalBias);
	Ray.Origin -= CameraDirection * RayBias;
	ApplyPositionBias(Ray, WorldNormal, RayBias);
}

uint calcLinearIndex(uint2 pixelCoord)
{
	return pixelCoord.y * bufferSizeAndInvSize.x + pixelCoord.x;
}

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

