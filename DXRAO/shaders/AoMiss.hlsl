#include "Common.hlsl"

// ---[ Miss Shader ]---

[shader("miss")]
void Miss(inout HitInfo payload)
{
	payload.isHit = false;
}
