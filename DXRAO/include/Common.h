#pragma once

#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN			// Exclude rarely-used items from Windows headers.
#endif

#include <Windows.h>
#include <DirectXMath.h>
#include <DirectXPackedVector.h>

#include <dxgi1_6.h>
#include <d3d12.h>
#include "d3dx12.h"
#include <dxc/dxcapi.h>
#include <dxc/dxcapi.use.h>

#include <string>
#include <vector>

//--------------------------------------------------------------------------------------
// Macro Defines
//--------------------------------------------------------------------------------------

#define NAME_D3D_RESOURCES 1
#define SAFE_RELEASE( x ) { if ( x ) { x->Release(); x = NULL; } }
#define SAFE_DELETE( x ) { if( x ) delete x; x = NULL; }
#define SAFE_DELETE_ARRAY( x ) { if( x ) delete[] x; x = NULL; }
#define ALIGN(_alignment, _val) (((_val + _alignment - 1) / _alignment) * _alignment)