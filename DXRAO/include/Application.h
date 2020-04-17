#pragma once

#include "Graphics.h"
#include "Utils.h"

#ifdef _DEBUG
#define _CRTDBG_MAP_ALLOC
#include <stdlib.h>
#include <crtdbg.h>
#endif

/*
** DXR Aplicaiton
*/
class DXRApplication
{
public:
	DXRApplication() {
		self = this;
	}

	static DXRApplication* GetApp() {
		return self;
	}
	static DXRApplication* self;

	friend LRESULT CALLBACK MainWndProc(HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam);

public:
	void Init(ConfigInfo& config);
	void Update();
	void Render();
	void Cleanup();

private:
	HWND window;
	Model model;
	Material material;
	Camera camera;

	DXRGlobal dxr = {};
	D3D12Global d3d = {};
	D3D12Resources resources = {};
	D3D12RenderGlobal d3dRender = {};
	D3D12ShaderCompilerInfo shaderCompiler;

private:
	HRESULT WinCreate(LONG width, LONG height, HINSTANCE& instance, HWND& window, LPCWSTR title);
	LRESULT CALLBACK WndProc(HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam);

	void OnMouseMove(WPARAM btnState, int x, int y);
	void OnMouseDown(WPARAM btnState, int x, int y);
	void OnMouseUp(WPARAM btnState, int x, int y);
	void UpdateCamera();

	int	frameIndexFromStart = 0;
	Point lastMousePos;
	float mTheta = 1.5f * Pi;
	float mPhi = 0.785398163f;
	float mRadius = 20.0f;
};
