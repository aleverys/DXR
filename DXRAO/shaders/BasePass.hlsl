
struct VertexIn{
    float3 PosL    : POSITION;
    float3 NormalL : NORMAL;
	float2 TexC    : TEXCOORD;
};

struct VertexOut{
    float4 PosH    : SV_POSITION;
    float4 Normal  : NORMAL;
};

struct PixelOut{
    float4 color   : COLOR;
    float4 normal  : NORMAL; 
};

cbuffer BassPassCB : register(b0) {
    float4x4 viewProj;
};

cbuffer BassPassPerObjectCB : register(b1) {
    float4x4 world;
    float4x4 worldTransposeInverse;
    int2 resolution;
};

//Texture2D<float4> albedo  : register(t1);

VertexOut vs(VertexIn v)
{
    VertexOut res = (VertexOut)0.0f;
    
    float4 posWorld = mul(float4(v.PosL,1.0f),world);
    res.PosH = mul(posWorld,viewProj);

    float3 normal=mul(v.NormalL,(float3x3)worldTransposeInverse);
    res.Normal=float4(normal,0);

    return res;
}

PixelOut ps(VertexOut v) : SV_Target 
{
    PixelOut res=(PixelOut)0.0f;
    
    float3 normal=normalize(v.Normal.xyz);

    res.color=float4(normal,1.0f);
    res.normal=float4(normal,1.0f);
    return res;
}
