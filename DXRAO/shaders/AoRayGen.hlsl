
#include"AoCommon.hlsl"

[shader("raygeneration")]
void AmbientOcclusionRGS()
{
	uint2 PixelCoord = DispatchRaysIndex().xy + View.ViewRectMin;

	RandomSequence RandSequence;
	uint LinearIndex = CalcLinearIndex(PixelCoord);
	RandomSequence_Initialize(RandSequence, LinearIndex, View.StateFrameIndex);

	// Get G-Buffer surface data
	float2 InvBufferSize = View.BufferSizeAndInvSize.zw;
	float2 UV = (float2(PixelCoord) + 0.5) * InvBufferSize;
	FGBufferData GBufferData = GetGBufferDataFromSceneTextures(UV);	
	float Depth = GBufferData.Depth;
	float DeviceZ = SceneDepthBuffer.Load(int3(PixelCoord, 0)).r;
	float3 WorldPosition = ReconstructWorldPositionFromDeviceZ(PixelCoord, DeviceZ);
	float3 WorldNormal = GBufferData.WorldNormal;

	float RayCount = 0.0;
	float Visibility = 0.0;
	float ClosestRayHitDistance = 1.#INF;
	// Declaring intensity as a local variable is a workaround for a shader compiler bug with NV drivers 430.39 and 430.64.
	const float IntensityLocal = Intensity;
	uint SamplesPerPixelLocal = SamplesPerPixel;
	
	// Mask out depth values beyond far plane
	bool IsFiniteDepth = DeviceZ > 0.0;
	bool bTraceRay = (IsFiniteDepth && GBufferData.ShadingModelID != SHADINGMODELID_UNLIT);
	if (!bTraceRay)
	{
		Visibility = 1.0;
		RayCount = SamplesPerPixel;
		SamplesPerPixelLocal = 0.0;
	}

	for (uint SampleIndex = 0; SampleIndex < SamplesPerPixelLocal; ++SampleIndex)
	{
		RayDesc Ray;
		GenerateCosineNormalRay(WorldPosition, WorldNormal, RandSequence, Ray.Origin, Ray.Direction, Ray.TMin, Ray.TMax);
		ApplyCameraRelativeDepthBias(Ray, PixelCoord, DeviceZ, WorldNormal, MaxNormalBias);

		if (dot(WorldNormal, Ray.Direction) <= 0.0) // TODO: does it needs to be handled by the denoiser?
			continue;
		
		uint RayFlags = 0;
#if !ENABLE_MATERIALS
		RayFlags |= RAY_FLAG_FORCE_OPAQUE;
#endif
#if !ENABLE_TWO_SIDED_GEOMETRY
		RayFlags |= RAY_FLAG_CULL_BACK_FACING_TRIANGLES;
#endif

		FPackedMaterialClosestHitPayload Payload = (FPackedMaterialClosestHitPayload)0;
		Payload.SetMinimalPayloadMode(); // Only HitT will be filled by closest hit shader, skipping full material evaluation.

		TraceRay(
			TLAS,
			RayFlags,
			RAY_TRACING_MASK_SHADOW,          // InstanceInclusionMask
			RAY_TRACING_SHADER_SLOT_SHADOW,   // RayContributionToHitGroupIndex
			RAY_TRACING_NUM_SHADER_SLOTS,     // MultiplierForGeometryContributionToShaderIndex
			0,    // MissShaderIndex
			Ray,
			Payload
		);
		
		RayCount += 1;
		Visibility += Payload.IsMiss() ? 1.0 : 1.0 - IntensityLocal;
		if (Payload.IsHit())
		{
			ClosestRayHitDistance = min(ClosestRayHitDistance, Payload.HitT);
		}
	}

	// Output.
	{
		float2 RawOutput = 1;

		if (SamplesPerPixelLocal == 0)
		{
			RawOutput.x = 1;
			RawOutput.y = -2;
		}
		else if (RayCount == 0)
		{
			RawOutput.x = 1;
			RawOutput.y = -1;
		}
		else
		{
			RawOutput.x = Visibility / RayCount;
			RawOutput.y = ClosestRayHitDistance;
		}

		RWOcclusionMaskUAV[PixelCoord] = RawOutput.x;
		RWHitDistanceUAV[PixelCoord] = RawOutput.y;
	}
}