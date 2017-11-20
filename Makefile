CC:=g++

# Controls what config to build samples with. Valid values are "Debug" and "Release"
SAMPLE_CONFIG:=Release

INCLUDES = \
-I "Framework" \
-I "Framework/Source" \
-I "Framework/Externals/GLM" \
-I "Framework/Externals/OpenVR/headers" \
-I "Framework/Externals/RapidJson/include" \
-I "$(VULKAN_SDK)/include" \
$(shell pkg-config --cflags assimp gtk+-3.0 glfw3)

# freeimage has no pkg-config data, but should be in /usr/include
# glfw3 too

ADDITIONAL_LIB_DIRS = -L "Bin/" \
-L "Framework/Externals/OpenVR/lib" \
-L "Framework/Externals/FFMPEG/lib" \
-L "Framework/Externals/Slang/bin/linux-x86_64/release" \
-L "$(VULKAN_SDK)/lib"

LIBS = -lfalcor \
-lfreeimage -lslang -lslang-glslang -lopenvr_api \
$(shell pkg-config --libs assimp gtk+-3.0 glfw3) \
$(shell pkg-config --static --libs x11)\
-lvulkan -lstdc++fs -lrt -lm -ldl -lz
# ffmpeg stuff: -lavcodec -lavdevice -lavformat -lswscale -lavutil -lopus

# Compiler Flags
DEBUG_FLAGS:=-O0 -g -Wno-unused-variable
RELEASE_FLAGS:=-Og
#-fno-branch-count-reg -fno-if-conversion -fno-if-conversion2 -fno-inline-functions-called-once -fno-move-loop-invariants -fno-ssa-phiopt -fno-tree-bit-ccp -fno-tree-pta -fno-tree-sra
DISABLED_WARNINGS:=-Wno-unknown-pragmas -Wno-reorder -Wno-attributes -Wno-unused-function -Wno-switch -Wno-sign-compare -Wno-address -Wno-strict-aliasing -Wno-nonnull-compare \
-Wno-unused-but-set-variable -Wno-misleading-indentation
# Disabling "unused-but-set-variable and misleading-indentation" ignores warnings when compiling imgui, not Falcor
COMMON_FLAGS=-c -Wall -Werror -std=c++17 -m64 $(DISABLED_WARNINGS)

# Defines
DEBUG_DEFINES:=-D "_DEBUG"
RELEASE_DEFINES:=
COMMON_DEFINES:=-D "FALCOR_VK" -D "GLM_FORCE_DEPTH_ZERO_TO_ONE"

# Base source directory
SOURCE_DIR:=Framework/Source/

# All directories containing source code relative from the base Source folder. The "/" in the first line is to include the base Source directory
RELATIVE_DIRS:= / \
API/ API/LowLevel/ API/Vulkan/ API/Vulkan/LowLevel/ \
Effects/AmbientOcclusion/ Effects/NormalMap/ Effects/ParticleSystem/ Effects/Shadows/ Effects/SkyBox/ Effects/TAA/ Effects/ToneMapping/ Effects/Utils/ \
Graphics/ Graphics/Camera/ Graphics/Material/ Graphics/Model/ Graphics/Model/Loaders/ Graphics/Paths/ Graphics/Scene/  Graphics/Scene/Editor/ \
Utils/ Utils/Math/ Utils/Picking/ Utils/Psychophysics/ Utils/Platform/ Utils/Platform/Linux/ \
VR/ VR/OpenVR/ \
../Externals/dear_imgui/
# Utils/Video/

# RELATIVE_DIRS, but now with paths relative to Makefile
SOURCE_DIRS = $(addprefix $(SOURCE_DIR), $(RELATIVE_DIRS))
# All source files enumerated with paths relative to Makefile (base repo)
ALL_SOURCE_FILES = $(wildcard $(addsuffix *.cpp,$(SOURCE_DIRS)))
# All expected .o files with the same path as their corresponding .cpp. Output redirected to actual output folder during compilation recipe
ALL_OBJ_FILES = $(patsubst %.cpp,%.o,$(ALL_SOURCE_FILES))

OUT_DIR:=Bin/

FeatureDemo : $(SAMPLE_CONFIG)
	$(eval DIR=Samples/FeatureDemo/)
	@$(CC) $(CXXFLAGS) $(DIR)FeatureDemo.cpp -o $(DIR)FeatureDemo.o
	@$(CC) $(CXXFLAGS) $(DIR)FeatureDemoControls.cpp -o $(DIR)FeatureDemoControls.o
	@$(CC) $(CXXFLAGS) $(DIR)FeatureDemoSceneRenderer.cpp -o $(DIR)FeatureDemoSceneRenderer.o
	@$(CC) -o $(OUT_DIR)FeatureDemo $(DIR)FeatureDemo.o $(DIR)FeatureDemoControls.o $(DIR)FeatureDemoSceneRenderer.o $(ADDITIONAL_LIB_DIRS) $(LIBS)
	@echo Built $@

Shadows : $(SAMPLE_CONFIG)
	$(eval DIR=Samples/Effects/Shadows/)
	@$(CC) $(CXXFLAGS) $(DIR)Shadows.cpp -o $(DIR)Shadows.o
	@$(CC) -o $(OUT_DIR)Shadows $(DIR)Shadows.o $(ADDITIONAL_LIB_DIRS) $(LIBS)
	@echo Built $@

ShaderToy : $(SAMPLE_CONFIG)
	$(eval DIR=Samples/Core/ShaderToy/)
	@$(CC) $(CXXFLAGS) $(DIR)ShaderToy.cpp -o $(DIR)ShaderToy.o
	@$(CC) -o $(OUT_DIR)ShaderToy $(DIR)ShaderToy.o $(ADDITIONAL_LIB_DIRS) $(LIBS)
	@echo Built $@

ComputeShader : $(SAMPLE_CONFIG)
	$(eval DIR=Samples/Core/ComputeShader/)
	@$(CC) $(CXXFLAGS) $(DIR)ComputeShader.cpp -o $(DIR)ComputeShader.o
	@$(CC) -o $(OUT_DIR)ComputeShader $(DIR)ComputeShader.o $(ADDITIONAL_LIB_DIRS) $(LIBS)
	@echo Built $@

MultiPassPostProcess : $(SAMPLE_CONFIG)
	$(eval DIR=Samples/Core/MultiPassPostProcess/)
	@$(CC) $(CXXFLAGS) $(DIR)MultiPassPostProcess.cpp -o $(DIR)MultiPassPostProcess.o
	@$(CC) -o $(OUT_DIR)MultiPassPostProcess $(DIR)MultiPassPostProcess.o $(ADDITIONAL_LIB_DIRS) $(LIBS)
	@echo Built $@

ModelViewer : $(SAMPLE_CONFIG)
	$(eval DIR=Samples/Utils/ModelViewer/)
	@$(CC) $(CXXFLAGS) $(DIR)ModelViewer.cpp -o $(DIR)ModelViewer.o
	@$(CC) -o $(OUT_DIR)ModelViewer $(DIR)ModelViewer.o $(ADDITIONAL_LIB_DIRS) $(LIBS)
	@echo Built $@

# Builds Falcor library in Release
Release : ReleaseConfig $(OUT_DIR)libfalcor.a

# Builds Falcor library in Debug
Debug : DebugConfig $(OUT_DIR)libfalcor.a

# Creates the lib
$(OUT_DIR)libfalcor.a : $(ALL_OBJ_FILES)
	@mkdir -p $(dir $(OUT_DIR))
	@echo Creating $@
	@ar rcs $@ $^

$(ALL_OBJ_FILES) : %.o : %.cpp
	@echo $^
	@$(CC) $(CXXFLAGS) $^ -o $@

.PHONY : DebugConfig
DebugConfig :
	$(eval CXXFLAGS=$(INCLUDES) $(DEBUG_FLAGS) $(DEBUG_DEFINES) $(COMMON_FLAGS) $(COMMON_DEFINES))

.PHONY : ReleaseConfig
ReleaseConfig :
	$(eval CXXFLAGS=$(INCLUDES) $(RELEASE_FLAGS) $(RELEASE_DEFINES) $(COMMON_FLAGS) $(COMMON_DEFINES))

.PHONY : clean
clean :
	@find . -name "*.o" -type f -delete
#	@rm -rf "Bin/"
#	@rm -f Falcor.a
