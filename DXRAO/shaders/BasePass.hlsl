
struct VertexIn{
    float3 PosL    : POSITION;
    float3 NormalL : NORMAL;
	float2 TexC    : TEXCOORD;
};

struct VertexOut{
    float4 PosH    : SV_POSITION;
};

cbuffer BassPassCB : register(b0) {
    float4x4 viewProj;
};

cbuffer BassPassPerObjectCB : register(b1) {
    float4x4 world;
};

VertexOut vs(VertexIn v)
{
    VertexOut res = (VertexOut)0.0f;
    
    float4 posWorld = mul(float4(v.PosL,1.0f),world);
    res.PosH = mul(posWorld,viewProj);

    return res;
}

float4 ps(VertexOut v) : SV_Target 
{
    return float4(0.f,0.f,0.f,1.f);
}
