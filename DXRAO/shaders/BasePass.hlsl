
struct VertexIn{
    float3 PosL    : POSITION;
    float3 NormalL : NORMAL;
	float2 TexC    : TEXCOORD;
};

struct VertexOut{
    float4 PosH    : SV_POSITION;
    float4 Normal  : NORMAL;
};

cbuffer BassPassCB : register(b0) {
    float4x4 viewProj;
};

cbuffer BassPassPerObjectCB : register(b1) {
    float4x4 world;
    float4x4 worldTransposeInverse;
    float2 resolution;
};

RWTexture2D<float4> normalBuffer : register(u0);

VertexOut vs(VertexIn v)
{
    VertexOut res = (VertexOut)0.0f;
    
    //float4 posWorld = mul(float4(v.PosL,1.0f),world);
    //res.PosH = mul(posWorld,viewProj);
    //float3 c1=worldTransposeInverse[0].xyz;
    //float3 c2=worldTransposeInverse[1].xyz;
    //float3 c3=worldTransposeInverse[2].xyz;
    
    //float3 normal=mul(v.NormalL.xyz,float3x3(c1,c2,c3));
    //res.Normal=float4(normal,0);
    res.Normal=float4(v.NormalL.xyz,0);
    return res;
}

float4 ps(VertexOut v) : SV_Target 
{
    uint2 positionInPixel=uint2(v.PosH.x*(float)resolution.x,v.PosH.y*(float)resolution.y);
    float3 normal=normalize(v.Normal.xyz);
    normalBuffer[positionInPixel]=float4(normal,0.f);
    return float4(0.5f,0.5f,0.5f,1.0f);
    //return float4(normal,1.0f);
}
