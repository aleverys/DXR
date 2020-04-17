#include "Application.h"


DXRApplication* DXRApplication::self = nullptr;

void DXRApplication::Init(ConfigInfo& config)
{
#ifdef _DEBUG  
	{
		ID3D12Debug* pD3D12Debug;
		if (SUCCEEDED(D3D12GetDebugInterface(IID_PPV_ARGS(&pD3D12Debug))))
		{
			pD3D12Debug->EnableDebugLayer();
		}
		pD3D12Debug->Release();
	}
#endif
	// Create a new window
	HRESULT hr = WinCreate(config.width, config.height, config.instance, window, L"DirectX Raytracing Demo");
	Utils::Validate(hr, L"Error: failed to create window!");

	d3d.width = config.width;
	d3d.height = config.height;
	d3d.vsync = config.vsync;

	// Load a model
	Utils::LoadModel(config.model, model, material);

	// Initialize the shader compiler
	D3DShaders::Init_Shader_Compiler(shaderCompiler);

	// Initialize D3D12
	D3D12::Create_Device(d3d);
	D3D12::Create_Command_Queue(d3d);
	D3D12::Create_Command_Allocator(d3d);
	D3D12::Create_Fence(d3d);
	D3D12::Create_SwapChain(d3d, window);
	D3D12::Create_CommandList(d3d);
	D3D12::Reset_CommandList(d3d);

	// Create common resources
	D3DResources::Create_RTV_Descriptor_Heaps(d3d, resources);
	D3DResources::Create_BackBuffer_RTV(d3d, resources);

	D3DResources::Create_DSV_Descriptor_Heaps(d3d, resources);
	D3DResources::Create_DepthStencilBuffer_DSV(d3d, resources);

	D3DResources::Create_Vertex_Buffer(d3d, resources, model);
	D3DResources::Create_Index_Buffer(d3d, resources, model);
	//D3DResources::Create_Texture(d3d, resources, material);
	//D3DResources::Create_RayConfig_CB(d3d, resources, material);
	//D3DResources::Create_View_CB(d3d, resources);

	// Create DirectX render resources
	D3D12Render::Create_Contant_Buffer(d3d, resources);
	D3D12Render::Create_Normal_Buffer(d3d, resources);
	D3D12Render::Create_Descriptor_Heaps(d3d, resources);
	D3D12Render::Create_Root_Signature(d3d, d3dRender);
	D3D12Render::Create_Shaders(d3d, d3dRender);
	D3D12Render::Create_Input_Layout(d3d, d3dRender);
	D3D12Render::Create_Pipeline_State(d3d, d3dRender);

	// Create DXR specific resources
	/*DXR::Create_Bottom_Level_AS(d3d, dxr, resources, testModel);
	DXR::Create_Top_Level_AS(d3d, dxr, resources);
	DXR::Create_DXR_Output(d3d, resources);
	DXR::Create_Descriptor_Heaps(d3d, dxr, resources, testModel);
	DXR::Create_RayGen_Program(d3d, dxr, shaderCompiler);
	DXR::Create_Miss_Program(d3d, dxr, shaderCompiler);
	DXR::Create_Closest_Hit_Program(d3d, dxr, shaderCompiler);
	DXR::Create_Pipeline_State_Object(d3d, dxr);
	DXR::Create_Shader_Table(d3d, dxr, resources);*/

	d3d.cmdList->Close();
	ID3D12CommandList* pGraphicsList = { d3d.cmdList };
	d3d.cmdQueue->ExecuteCommandLists(1, &pGraphicsList);

	D3D12::WaitForGPU(d3d);
	D3D12::Reset_CommandList(d3d);
}

void DXRApplication::Update()
{
	frameIndexFromStart;
	D3DResources::Update_BasePass_CB(d3d, resources,camera);
	//D3DResources::Update_DXR_CB(d3d, resources);
}

void DXRApplication::Render()
{
	D3D12Render::DrawBasePass(d3d, d3dRender, resources, model);
	//DXR::Build_Command_List(d3d, dxr, resources);

	D3D12::Submit_CmdList(d3d);
	D3D12::WaitForGPU(d3d);

	D3D12::Present(d3d);
	D3D12::MoveToNextFrame(d3d);
	D3D12::Reset_CommandList(d3d);
}

void DXRApplication::Cleanup()
{
	D3D12::WaitForGPU(d3d);
	CloseHandle(d3d.fenceEvent);

	DXR::Destroy(dxr);
	D3D12Render::Destroy(d3dRender);
	D3DResources::Destroy(resources);
	D3DShaders::Destroy(shaderCompiler);
	D3D12::Destroy(d3d);

	DestroyWindow(window);
}

void DXRApplication::UpdateCamera() {
	camera.x = mRadius * sinf(mPhi) * cosf(mTheta);
	camera.z = mRadius * sinf(mPhi) * sinf(mTheta);
	camera.y = mRadius * cosf(mPhi);
}

void DXRApplication::OnMouseDown(WPARAM btnState, int x, int y)
{
	lastMousePos.x = x;
	lastMousePos.y = y;

	SetCapture(window);
}

void DXRApplication::OnMouseUp(WPARAM btnState, int x, int y)
{
	ReleaseCapture();
}

void DXRApplication::OnMouseMove(WPARAM btnState, int x, int y)
{
	if ((btnState & MK_LBUTTON) != 0)
	{
		// Make each pixel correspond to a quarter of a degree.
		float dx = DirectX::XMConvertToRadians(0.25f * static_cast<float>(x - lastMousePos.x));
		float dy = DirectX::XMConvertToRadians(0.25f * static_cast<float>(y - lastMousePos.y));

		// Update angles based on input to orbit camera around box.
		mTheta += dx;
		mPhi += dy;

		// Restrict the angle mPhi.
		mPhi = Math::Clamp(mPhi, 0.1f, Pi - 0.1f);
	}

	else if ((btnState & MK_RBUTTON) != 0)
	{
		// Make each pixel correspond to 0.005 unit in the scene.
		float dx = 0.005f * static_cast<float>(x - lastMousePos.x);
		float dy = 0.005f * static_cast<float>(y - lastMousePos.y);

		// Update the camera radius based on input.
		mRadius += dx - dy;

		// Restrict the radius.
		mRadius = Math::Clamp(mRadius, 3.0f, 15.0f);
	}

	lastMousePos.x = x;
	lastMousePos.y = y;
}
