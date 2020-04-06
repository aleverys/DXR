
struct VertexIn{
    float3 PosL    : POSITION;
    float3 NormalL : NORMAL;
	float2 TexC    : TEXCOORD;
};

struct VertexOut{
    float4 PosH    : SV_POSITION;
    float4 Normal;
};

cbuffer BassPassCB : register(b0) {
    float4x4 viewProj;
};

cbuffer BassPassPerObjectCB : register(b1) {
    float4x4 world;
    float4x4 worldTransposeInverse;
    float2 dimision;
};

RWTexture2D<float4> normalBuffer : register(u0);

VertexOut vs(VertexIn v)
{
    VertexOut res = (VertexOut)0.0f;
    
    float4 posWorld = mul(float4(v.PosL,1.0f),world);
    res.PosH = mul(posWorld,viewProj);
    
    float3 normal=mul(v.NormalL.xyz,float3x3(worldTransposeInverse));
    res.Normal=float4(normal,0);

    return res;
}

float4 ps(VertexOut v) : SV_Target 
{
    uint2 positionInPixel=uint2(PosH.x*(float)dimision.x,PosH.y*(float)dimision.y);
    float3 normal=normalize(v.Normal.xyz);
    normalBuffer[positionInPixel]=float4(normal,0.f);
    return float4(normal,1.0f);
}
