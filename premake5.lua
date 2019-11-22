function GenerateCArray(srcFile, dstFile, arrayName, arraySizeName)
	local src = io.readfile(srcFile)
	if src == nil then return false end

	if arrayName == nil then
		arrayName = path.getbasename(dstFile)
	end

	if arraySizeName == nil then
		arraySizeName = arrayName .. "_size"
	end

	local dst = "const unsigned char " .. arrayName .. "[] = {\n"
	local line = ""

	for i = 1, #src do
		local byte = src:byte(i, i)
		line = line .. string.format("0x%02x, ", byte)

		if (#line >= 80) or (i == #src) then
			if i == #src then line = line:sub(1, #line - 2) end

			dst = dst .. "\t" .. line .. "\n"
			line = ""
		end
	end

	dst = dst .. "};\n\n"
	dst = dst .. string.format("const unsigned " .. arraySizeName .. " = %d;\n\n", #src)

	local oldDst = ""
	if os.isfile(dstFile) then oldDst = io.readfile(dstFile) end

	if oldDst ~= dst then
		io.writefile(dstFile, dst)
	end

	return true
end

-----------------------------------------------------------------------------------------------------------------------

workspace "quickjs-msvc"
	-- Premake output folder
	location(path.join(".build", _ACTION))

	-- Target architecture
	architecture "x86_64"

	-- Configuration settings
	configurations { "Debug", "Release" }

	-- Debug configuration
	filter { "configurations:Debug" }
		defines { "DEBUG" }
		symbols "On"
		optimize "Off"

	-- Release configuration
	filter { "configurations:Release" }
		defines { "NDEBUG" }
		optimize "Speed"
		inlining "Auto"

	filter { "language:not C#" }
		defines { "_CRT_SECURE_NO_WARNINGS" }
		characterset ("MBCS")
		buildoptions { "/std:c++latest" }

		if _ACTION == "vs2017" then
			systemversion("10.0.17763.0")
		end

	filter { }
		targetdir ".bin/%{cfg.longname}/"
		defines { "WIN32", "_AMD64_", "__x86_64__" }
		exceptionhandling "Off"
		rtti "Off"
		vectorextensions "AVX2"

-----------------------------------------------------------------------------------------------------------------------

project "quickjs"
	language "C"
	kind "StaticLib"
	files {
		"cutils.c",
		"libregexp.c",
		"libunicode.c",
		"quickjs.c",
		"quickjs-libc.c",
		"cutils.h",
		"libregexp.h",
		"libregexp-opcode.h",
		"libunicode.h",
		"libunicode-table.h",
		"list.h",
		"quickjs.h",
		"quickjs-atom.h",
		"quickjs-libc.h",
		"quickjs-opcode.h"
	}

-----------------------------------------------------------------------------------------------------------------------

project "qjsc"
	language "C"
	kind "ConsoleApp"
	links { "quickjs" }
	files {
		"qjsc.c"
	}

-----------------------------------------------------------------------------------------------------------------------

project "qjs"
	language "C"
	kind "ConsoleApp"
	links { "quickjs" }
	dependson { "qjsc" }
	files {
		"qjs.c",
		"repl.js",
		"repl.c"
	}

-- Compile repl.js and save bytecode into repl.c
prebuildcommands { "\"%{cfg.buildtarget.directory}/qjsc.exe\" -c -o \"../../repl.c\" -m \"../../repl.js\"" }
