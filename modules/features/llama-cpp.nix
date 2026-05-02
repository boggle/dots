{ config, lib, pkgs, ... }:

let
  cfg = config.features.llama-cpp;
  
  # Fixed install directory
  installDir = "$HOME/.local/share/llama-cpp-chromaden";
  
  # Generate the cmake command with all flags
  cmakeCommand = lib.concatStringsSep " " (map (f: "'" + lib.escape ["'"] f + "'") cfg.cmakeFlags);
  
  # Install command - run once manually
  installCommand = pkgs.writeShellScriptBin "install-llama-cpp" ''
    set -e
    
    INSTALL_DIR="$HOME/.local/share/llama-cpp-chromaden"
    BUILD_DIR="$INSTALL_DIR/build"
    
    # Use system paths
    OPENBLAS_PATH="/opt/aocl/gcc"
    CUDA_HOME="/opt/cuda"
    
    mkdir -p "$INSTALL_DIR/bin"
    mkdir -p "$BUILD_DIR"
    
    cd "$BUILD_DIR"
    
    # Check if repo exists
    if [ -d "llama.cpp/.git" ]; then
      read -p "llama.cpp exists. Rebuild? (y/N) " -n 1 -r
      echo
      if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Skipping build."
        exit 0
      fi
      echo "Updating llama.cpp (master branch)..."
      cd llama.cpp
      git pull origin master
      echo "Cleaning previous build..."
      rm -rf build
    else
      echo "Cloning llama.cpp (master branch)..."
      git clone --depth 1 --branch master https://github.com/ggml-org/llama.cpp.git
      cd llama.cpp
    fi
    
    echo "Building llama-cpp-chromaden..."
    echo "Build directory: $BUILD_DIR"
    echo "AOCL-BLIS: /opt/aocl/gcc"
    echo ""
    
    export CUDA_HOME=/opt/cuda
    export PATH=$CUDA_HOME/bin:$PATH
    export CC=${cfg.cc}
    export CXX=${cfg.cxx}
    
    echo "Configuring with CMake..."
    cmake -B build \
      -DCMAKE_BUILD_TYPE=Release \
      -DBUILD_SHARED_LIBS=OFF \
      -DLLAMA_BUILD_SERVER=ON \
      -DLLAMA_OPENSSL=ON \
      -DLLAMA_CURL=ON \
      -DGGML_CUDA=ON \
      -DCMAKE_CUDA_ARCHITECTURES=120 \
      -DGGML_CUDA_F16=ON \
      -DGGML_CUDA_FA_ALL_QUANTS=ON \
      -DGGML_VULKAN=ON \
      -DGGML_BLAS=ON \
      -DGGML_BLAS_VENDOR=AOCL \
      -DBLAS_INCLUDE_DIRS=/opt/aocl/gcc/include_LP64 \
      -DBLAS_LIBRARIES=/opt/aocl/gcc/lib_LP64/libblis-mt.so \
      -DGGML_AVX512=ON \
      -DGGML_AVX512_VNNI=ON \
      -DGGML_AVX512_BF16=ON \
      -DGGML_FMA=ON \
      -DGGML_F16C=ON \
      -DGGML_BMI2=ON \
      -DGGML_LTO=ON \
      -DGGML_NATIVE=OFF \
      -DCMAKE_C_FLAGS="-march=znver5 -O3 -flto" \
      -DCMAKE_CXX_FLAGS="-march=znver5 -O3 -flto -include omp.h" \
      -DCMAKE_CUDA_FLAGS="-Xcompiler='-march=znver5 -mtune=znver5'"
    
    echo "Building (this will take 10-30 minutes)..."
    cmake --build build --config Release -j$(nproc)
    
    echo "Installing..."
    cp build/bin/llama-* "$INSTALL_DIR/bin/"
    ln -sf llama-cli "$INSTALL_DIR/bin/llama"
    
    # Create wrapper scripts that set LD_LIBRARY_PATH for llama binaries only
    for bin in "$INSTALL_DIR/bin"/llama-*; do
      if [ -f "$bin" ] && [ ! -L "$bin" ] && [ ! -f "$bin.wrapped" ]; then
        mv "$bin" "$bin.wrapped"
        cat > "$bin" << EOF
#!/bin/bash
export LD_LIBRARY_PATH="/opt/aocl/gcc/lib_LP64:/opt/cuda/lib64:/usr/lib:/opt/aocl/lib:$LD_LIBRARY_PATH"
exec "$bin.wrapped" "\$@"
EOF
        chmod +x "$bin"
      fi
    done
    
    date > "$INSTALL_DIR/.build-date"
    
    echo ""
    echo "Build complete! Run 'llama-server --version' to verify."
    echo "Build files preserved at: $BUILD_DIR"
    echo ""
    echo "Set capabilities for GPU memory locking:"
    echo "  sudo setcap 'cap_ipc_lock=+ep' $HOME/.local/share/llama-cpp-chromaden/bin/llama-cli.wrapped"
    echo "  sudo setcap 'cap_ipc_lock=+ep' $HOME/.local/share/llama-cpp-chromaden/bin/llama-server.wrapped"
  '';

  uninstall-llama-cpp = pkgs.writeShellScriptBin "uninstall-llama-cpp" ''
    set -euo pipefail
    
    INSTALL_DIR="$HOME/.local/share/llama-cpp-chromaden"
    BUILD_DIR="$INSTALL_DIR/build"
    
    echo ">> Cleaning llama.cpp build for chromaden..."
    
    read -p "Remove build directory ($BUILD_DIR)? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
      echo "Cancelled."
      exit 0
    fi
    
    if [ -d "$BUILD_DIR" ]; then
      echo ">> Removing build directory..."
      rm -rf "$BUILD_DIR"
    fi
    
    if [ -d "$INSTALL_DIR" ]; then
      echo ">> Removing install directory..."
      rm -rf "$INSTALL_DIR"
    fi
    
    echo ">> Clean complete."
  '';

in {
  options.features.llama-cpp = {
    enable = lib.mkEnableOption "llama.cpp with CUDA and Zen 5 optimization";

    cc = lib.mkOption {
      type = lib.types.str;
      default = "gcc";
      description = "C compiler to use";
    };

    cxx = lib.mkOption {
      type = lib.types.str;
      default = "g++";
      description = "C++ compiler to use";
    };

    cudaArchitectures = lib.mkOption {
      type = lib.types.str;
      default = "120";
      description = "CUDA architectures (120 = Blackwell RTX 5080)";
    };

    cmakeFlags = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "-DCMAKE_BUILD_TYPE=Release"
        "-DBUILD_SHARED_LIBS=OFF"
        "-DLLAMA_BUILD_SERVER=ON"
        "-DLLAMA_OPENSSL=ON"
        "-DLLAMA_CURL=ON"
        "-DGGML_CUDA=ON"
        "-DCMAKE_CUDA_ARCHITECTURES=120"
        "-DGGML_CUDA_F16=ON"
        "-DGGML_CUDA_FA_ALL_QUANTS=ON"
        "-DGGML_VULKAN=ON"
        "-DGGML_BLAS=ON"
        "-DGGML_BLAS_VENDOR=AOCL"
        "-DBLAS_INCLUDE_DIRS=/opt/aocl/gcc/include_LP64"
        "-DBLAS_LIBRARIES=/opt/aocl/gcc/lib_LP64/libblis-mt.so"
        "-DGGML_AVX512=ON"
        "-DGGML_AVX512_VNNI=ON"
        "-DGGML_AVX512_BF16=ON"
        "-DGGML_FMA=ON"
        "-DGGML_F16C=ON"
        "-DGGML_BMI2=ON"
        "-DGGML_LTO=ON"
        "-DGGML_NATIVE=OFF"
        "-DCMAKE_C_FLAGS=-march=znver5 -O3 -flto"
        "-DCMAKE_CXX_FLAGS=-march=znver5 -O3 -flto"
        "-DCMAKE_CUDA_FLAGS=-Xcompiler='-march=znver5 -mtune=znver5 -flto'"
      ];
      description = "CMake flags for building llama.cpp";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ 
      installCommand
      uninstall-llama-cpp
      pkgs.python313Packages.huggingface-hub  # Provides 'hf' command
    ];

    home.sessionPath = [ 
      "${config.home.homeDirectory}/.local/bin"
      "$HOME/.local/share/llama-cpp-chromaden/bin"
      "/opt/cuda/bin"
    ];

    home.sessionVariables = {
      CUDA_HOME = "/opt/cuda";
      HF_HOME = "/opt/ai/hf_cache";  # Centralized HuggingFace cache
    };

    # Create AI directories and setup hf-get function
    home.activation.setupAiDirs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      $DRY_RUN_CMD mkdir -p /opt/ai/hf_cache /opt/ai/models
      $DRY_RUN_CMD echo "AI directories ready at /opt/ai"
    '';

    # hf-get function for easy model downloads
    programs.bash.initExtra = ''
      # Centralized AI Storage
      export HF_HOME="/opt/ai/hf_cache"

      hf-get() {
        if [ -z "$1" ]; then
          echo "Usage: hf-get <repo/id> [optional: --include \"*.gguf\"]"
          return 1
        fi

        local REPO_ID="$1"
        local MODEL_NAME="''${REPO_ID##*/}"
        local TARGET_DIR="/opt/ai/models/$MODEL_NAME"

        echo "🌱 Downloading $REPO_ID to $TARGET_DIR..."
        
        # Execute download with hf (2026 standard CLI)
        # --local-dir handles the readable folder
        # --local-dir-use-symlinks is deprecated in 2026; the tool now links by default
        hf download "$REPO_ID" \
          --local-dir "$TARGET_DIR" \
          "''${@:2}"
      }
    '';

    home.activation.checkLlamaCpp = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      if [ ! -f "$HOME/.local/share/llama-cpp-chromaden/bin/llama-server" ]; then
        $DRY_RUN_CMD echo "⚠️  llama-cpp not built yet. Run: build-llama-cpp"
      fi
    '';

    alienPackages.enabledPackages = [
      "cuda-llama"
      "vulkan-llama" 
      "aocl-gcc"
      "aocl-utils"
    ];
  };
}
