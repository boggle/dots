{
  # AI Apps - CachyOS native packages
  grabcontext = {
    feature = "ai-apps";
    packages = {
    };
  };

  opencode = {
    feature = "ai-apps";
    packages = {
      pacman = [ "opencode" ];
    };
  };

  github-copilot-cli = {
    feature = "ai-apps";
    packages = {
      pacman = [ "github-copilot-cli" ];
    };
  };

  # CUDA 13.2 toolkit for llama.cpp
  cuda-llama = {
    feature = "ai-apps";
    packages = {
      pacman = [
        "cuda"           # CUDA 13.2 toolkit
      ];
    };
  };

  # Vulkan support for llama.cpp
  vulkan-llama = {
    feature = "ai-apps";
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
    feature = "ai-apps";
    packages = {
      paru = [ "aocl-gcc" ];  # AOCL GCC toolchain
    };
  };

  aocl-utils = {
    feature = "ai-apps";
    packages = {
      paru = [ "aocl-utils" ];  # AOCL utility libraries
    };
  };

  # koboldcpp dependencies
  koboldcpp-deps = {
    feature = "ai-apps";
    packages = {
      pacman = [
        "tk"                 # Tkinter for GUI
        "python-psutil"      # System monitoring for koboldcpp
      ];
    };
  };
}
