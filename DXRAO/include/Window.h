#pragma once

#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif

#include <Windows.h>

namespace Window
{
	HRESULT Create(LONG width, LONG height, HINSTANCE& instance, HWND &window, LPCWSTR title);
}