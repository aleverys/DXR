
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

VertexOut vs(VertexIn in){
    VertexOut out = (VertexOut)0.0f;
    
    float4 posWorld = mul(float4(in.PosL,1.0f),world);
    out.PosH = mul(posWorld,viewProj);

    return out;
}

float4 ps(VertexOut in) : SV_Target {
    return in.posH;
}
