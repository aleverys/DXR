
#include "AoCommon.hlsl"

[shader("raygeneration")]
void AmbientOcclusionRGS()
{
	uint2 pixelCoord = DispatchRaysIndex().xy;

	RandomSequence RandSequence;
	uint linearIndex = calcLinearIndex(pixelCoord);
	RandomSequence_Initialize(RandSequence, linearIndex, stateFrameIndex);

	//Get surface data from triditional pass
	float2 InvBufferSize = bufferSizeAndInvSize.zw;
	float2 uv = (float2(pixelCoord) + 0.5) * InvBufferSize;
	float depth = depthBuffer.SampleLevel(gsamPointClamp,uv,0.f).r;
	float3 worldPosition = ReconstructWorldPositionFromDeviceZ(pixelCoord, depth);
	float3 worldNormal = normalBuffer.SampleLevel(gsamPointClamp,uv,0.f).xyz;

	float rayCount = 0.0;
	float visibility = 0.0;
	float closestRayHitDistance = 1.#INF;

	// Declaring intensity as a local variable is a workaround for a shader compiler bug with NV drivers 430.39 and 430.64.
	const float intensityLocal = intensity;
	uint samplesPerPixelLocal = samplesPerPixel;
	
	// Mask out depth values beyond far plane
	bool IsFiniteDepth = depth > 0.0;
	bool bTraceRay = IsFiniteDepth;
	if (!bTraceRay)
	{
		visibility = 1.0;
		rayCount = samplesPerPixel;
		samplesPerPixelLocal = 0.0;
	}

	for (uint SampleIndex = 0; SampleIndex < samplesPerPixelLocal; ++SampleIndex)
	{
		RayDesc Ray;
		GenerateCosineNormalRay(worldPosition, worldNormal, RandSequence, Ray.Origin, Ray.Direction, Ray.TMin, Ray.TMax);
		ApplyCameraRelativeDepthBias(Ray, pixelCoord, depth, worldNormal, maxNormalBias);

		if (dot(worldNormal, Ray.Direction) <= 0.0) // TODO: does it needs to be handled by the denoiser?
			continue;
		
		uint rayFlags = RAY_FLAG_NONE;

		HitInfo payload;
		TraceRay(
			TLAS,
			rayFlags,
			0xFF,   // InstanceInclusionMask
			0,   	// RayContributionToHitGroupIndex
			0,      // MultiplierForGeometryContributionToShaderIndex
			0,      // MissShaderIndex
			Ray,
			payload
		);
		
		rayCount += 1;
		visibility += !payload.isHit ? 1.0 : 1.0 - intensityLocal;
		
		float3 rayOrigin = Ray.Origin;
		if (payload.isHit)
		{
			float3 vec = payload.hitPointPosition.xyz - rayOrigin;
			float distance = sqrt(vec.x * vec.x+vec.y * vec.y+ vec.z * vec.z);
			closestRayHitDistance = min(closestRayHitDistance, distance);
		}
	}

	// Output.
	float2 RawOutput = 1;

	if (samplesPerPixelLocal == 0)
	{
		RawOutput.x = 1;
		RawOutput.y = -2;
	}
	else if (rayCount == 0)
	{
		RawOutput.x = 1;
		RawOutput.y = -1;
	}
	else
	{
		RawOutput.x = visibility / rayCount;
		RawOutput.y = closestRayHitDistance;
	}

	RWOcclusionMaskUAV[pixelCoord] = RawOutput.x;
	RWHitDistanceUAV[pixelCoord] = RawOutput.y;
}
