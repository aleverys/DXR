struct HitInfo{
	float4 hitPointPosition;
	float4 hitPointNormal;
	bool isHit;
};

[shader("miss")]
void Miss(inout HitInfo payload)
{
	payload.isHit = false;
}
