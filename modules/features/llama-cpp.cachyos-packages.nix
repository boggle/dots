{
  # CUDA 13.2 toolkit for llama.cpp
  cuda-llama = {
    feature = "llama-cpp";
    packages = {
      pacman = [
        "cuda"           # CUDA 13.2 toolkit
      ];
    };
  };

  # Vulkan support for llama.cpp
  vulkan-llama = {
    feature = "llama-cpp";
    packages = {
      pacman = [
        "vulkan-headers"   # Vulkan development headers
        "vulkan-icd-loader"
        "vulkan-tools"
        "shaderc"          # Shader compiler
        "spirv-headers"    # SPIRV headers for Vulkan
      ];
    };
  };

  # AOCL (AMD Optimizing Compiler and Libraries) for Zen 5 optimization
  aocl-gcc = {
    feature = "llama-cpp";
    packages = {
      paru = [ "aocl-gcc" ];  # AOCL GCC toolchain
    };
  };

  aocl-utils = {
    feature = "llama-cpp";
    packages = {
      paru = [ "aocl-utils" ];  # AOCL utility libraries
    };
  };

  # gcc-15 toolchain, pinned as the CUDA host compiler
  # (see features/llama-cpp.nix cmakeFlags: -DCMAKE_CUDA_HOST_COMPILER=/usr/bin/g++-15)
  # Previously declared in alienPackages.enabledPackages with no matching spec
  # anywhere in the repo - silently never installed. Confirmed as an official
  # Arch `extra` repo package (not AUR) as of 2026-06: pacman, not paru.
  gcc15 = {
    feature = "llama-cpp";
    packages = {
      pacman = [ "gcc15" ];
    };
  };

  gcc15-libs = {
    feature = "llama-cpp";
    packages = {
      pacman = [ "gcc15-libs" ];
    };
  };
}
