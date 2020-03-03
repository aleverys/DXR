
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
    res.PosH.y=0.5;
    res.PosH.z=1;
    return res;
}

float4 ps(VertexOut v) : SV_Target 
{
    float depth=v.PosH.z;
    //depth=saturate(depth);
    return float4(0.5,0.2,0.3,1.f);
}
