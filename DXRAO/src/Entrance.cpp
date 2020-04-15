#include "Window.h"
#include "Graphics.h"
#include "Utils.h"

#ifdef _DEBUG
#define _CRTDBG_MAP_ALLOC
#include <stdlib.h>
#include <crtdbg.h>
#endif

/**
 * Your ray tracing application!
 */
class DXRApplication
{
public:

	void Init(ConfigInfo& config)
	{
		// Create a new window
		HRESULT hr = Window::Create(config.width, config.height, config.instance, window, L"DirectX Raytracing Demo");
		Utils::Validate(hr, L"Error: failed to create window!");

		d3d.width = config.width;
		d3d.height = config.height;
		d3d.vsync = config.vsync;

		// Load a model
		//Utils::LoadModel(config.model, model, material);

		// Initialize the shader compiler
		D3DShaders::Init_Shader_Compiler(shaderCompiler);
		DXR::Create_RayGen_Program(d3d, dxr, shaderCompiler);
		DXR::Create_Miss_Program(d3d, dxr, shaderCompiler);
		DXR::Create_Closest_Hit_Program(d3d, dxr, shaderCompiler);
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
		D3DResources::Create_Texture(d3d, resources, material);
		D3DResources::Create_RayConfig_CB(d3d, resources, material);
		D3DResources::Create_View_CB(d3d, resources);

		// Create DirectX render resources
		D3D12Render::Create_Contant_Buffer(d3d, resources);
		D3D12Render::Create_Normal_Buffer(d3d, resources);
		D3D12Render::Create_Descriptor_Heaps(d3d, resources);
		D3D12Render::Create_Root_Signature(d3d, d3dRender);
		D3D12Render::Create_Shaders(d3d, d3dRender);
		D3D12Render::Create_Input_Layout(d3d, d3dRender);
		D3D12Render::Create_Pipeline_State(d3d, d3dRender);

		// Create DXR specific resources
		DXR::Create_Bottom_Level_AS(d3d, dxr, resources, model);
		DXR::Create_Top_Level_AS(d3d, dxr, resources);
		DXR::Create_DXR_Output(d3d, resources);
		DXR::Create_Descriptor_Heaps(d3d, dxr, resources, model);
		DXR::Create_RayGen_Program(d3d, dxr, shaderCompiler);
		DXR::Create_Miss_Program(d3d, dxr, shaderCompiler);
		DXR::Create_Closest_Hit_Program(d3d, dxr, shaderCompiler);
		DXR::Create_Pipeline_State_Object(d3d, dxr);
		DXR::Create_Shader_Table(d3d, dxr, resources);

		d3d.cmdList->Close();
		ID3D12CommandList* pGraphicsList = { d3d.cmdList };
		d3d.cmdQueue->ExecuteCommandLists(1, &pGraphicsList);

		D3D12::WaitForGPU(d3d);
		D3D12::Reset_CommandList(d3d);
	}

	void Update()
	{
		D3DResources::Update_View_CB(d3d, resources);
	}

	void Render()
	{
		D3D12Render::DrawBasePass(d3d, d3dRender, resources, model);
		DXR::Build_Command_List(d3d, dxr, resources);
		
		D3D12::Submit_CmdList(d3d);
		D3D12::WaitForGPU(d3d);

		D3D12::Present(d3d);
		D3D12::MoveToNextFrame(d3d);
		D3D12::Reset_CommandList(d3d);
	}

	void Cleanup()
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

private:
	HWND window;
	Model model;
	Material material;

	DXRGlobal dxr = {};
	D3D12Global d3d = {};
	D3D12Resources resources = {};
	D3D12RenderGlobal d3dRender = {};
	D3D12ShaderCompilerInfo shaderCompiler;
};

/**
 * Program entry point.
 */
int WINAPI wWinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, LPWSTR lpCmdLine, int nCmdShow)
{
	UNREFERENCED_PARAMETER(hPrevInstance);
	UNREFERENCED_PARAMETER(lpCmdLine);

	HRESULT hr = EXIT_SUCCESS;
	{
		MSG msg = { 0 };

		// Get the application configuration
		ConfigInfo config;
		hr = Utils::ParseCommandLine(lpCmdLine, config);
		if (hr != EXIT_SUCCESS) return hr;

		// Initialize
		DXRApplication app;
		app.Init(config);

		// Main loop
		while (WM_QUIT != msg.message)
		{
			if (PeekMessage(&msg, NULL, 0, 0, PM_REMOVE))
			{
				TranslateMessage(&msg);
				DispatchMessage(&msg);
			}

			app.Update();
			app.Render();
		}

		app.Cleanup();
	}

#if defined _CRTDBG_MAP_ALLOC
	_CrtDumpMemoryLeaks();
#endif

	return hr;
}