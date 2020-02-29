#pragma once

#include "Structures.h"

namespace Utils
{
	HRESULT ParseCommandLine(LPWSTR lpCmdLine, ConfigInfo &config);

	std::vector<char> ReadFile(const std::string &filename);

	void LoadModel(std::string filepath, Model &model, Material &material);

	void Validate(HRESULT hr, LPWSTR message);

	TextureInfo LoadTexture(std::string filepath);
}