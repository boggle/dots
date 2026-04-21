{ config, lib, pkgs, ... }:

let
  cfg = config.features.koboldcpp;

  installDir = "$HOME/.local/share/koboldcpp-chromaden";

  # Build command - run once manually
  buildCommand = pkgs.writeShellScriptBin "build-koboldcpp" ''
    set -e

    INSTALL_DIR="${installDir}"
    BUILD_DIR="$INSTALL_DIR/build"

    mkdir -p "$INSTALL_DIR/bin"
    mkdir -p "$BUILD_DIR"

    cd "$BUILD_DIR"

    # Check if repo exists
    if [ -d "koboldcpp/.git" ]; then
      read -p "koboldcpp exists. Rebuild? (y/N) " -n 1 -r
      echo
      if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Skipping build."
        exit 0
      fi
      echo "Updating koboldcpp..."
      cd koboldcpp
      git pull origin concedo
      echo "Cleaning previous build..."
      make clean
    else
      echo "Cloning koboldcpp..."
      git clone --depth 1 --branch concedo https://github.com/LostRuins/koboldcpp.git
      cd koboldcpp
    fi

    echo "Building koboldcpp-chromaden..."
    echo "Build directory: $BUILD_DIR"
    echo ""

    # Set up environment for CachyOS CUDA
    export CUDA_HOME=/opt/cuda
    export PATH=$CUDA_HOME/bin:$PATH
    export LD_LIBRARY_PATH=/opt/cuda/lib64:$LD_LIBRARY_PATH

    echo "Setting up Python virtual environment..."
    VENV_DIR="$INSTALL_DIR/venv"
    if [ ! -d "$VENV_DIR" ]; then
      python3 -m venv "$VENV_DIR"
    fi
    source "$VENV_DIR/bin/activate"

    echo "Installing Python dependencies..."
    pip install --upgrade pip
    pip install customtkinter packaging
    pip install psutil

    echo "Patching Makefile for Zen 5 and Blackwell support..."
    
    # Simply replace -march=native with -march=znver5 in the architecture section
    # This is a direct replacement that preserves the Makefile structure
    sed -i 's/-march=native -mtune=native/-march=znver5 -mtune=znver5/g' Makefile
    
    # For CUDA: Replace -arch=native with -arch=sm_120 (Blackwell)
    sed -i 's/-arch=native/-arch=sm_120/g' Makefile
    
    echo "Building CPU library (fallback) with Zen 5 optimization..."
    make -j$(nproc) \
      LLAMA_AVX512=1 \
      koboldcpp_default

    echo "Building CUDA library (Blackwell sm_120)..."
    make -j$(nproc) \
      LLAMA_CUBLAS=1 \
      LLAMA_VULKAN=1 \
      LLAMA_AVX512=1 \
      LLAMA_CUDA_MMV=1 \
      NVCCFLAGS="--forward-unknown-to-host-compiler -use_fast_math -extended-lambda -arch=sm_120 -Xptxas=-v -D_FORCE_INLINES -Xcompiler='-march=znver5 -mtune=znver5'" \
      koboldcpp_cublas

    echo "Installing..."
    cp koboldcpp.py "$INSTALL_DIR/bin/koboldcpp.py"
    cp *.so "$INSTALL_DIR/bin/" 2>/dev/null || true
    cp embd_res/*.embd "$INSTALL_DIR/bin/" 2>/dev/null || true

    # Create wrapper script that uses venv Python directly
    cat > "$INSTALL_DIR/bin/koboldcpp" << 'EOF'
#!/bin/bash
# koboldcpp wrapper - uses venv Python directly
export LD_LIBRARY_PATH="/opt/cuda/lib64:/usr/lib:/opt/aocl/lib:$LD_LIBRARY_PATH"
exec "$HOME/.local/share/koboldcpp-chromaden/venv/bin/python3" "$HOME/.local/share/koboldcpp-chromaden/bin/koboldcpp.py" "$@"
EOF
    chmod +x "$INSTALL_DIR/bin/koboldcpp"

    date > "$INSTALL_DIR/.build-date"

    echo ""
    echo "Build complete! Run 'koboldcpp --help' to verify."
    echo "Build files preserved at: $BUILD_DIR"
  '';
in {
  options.features.koboldcpp = {
    enable = lib.mkEnableOption "koboldcpp with CUDA and Zen 5 optimization";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      buildCommand
    ];

    home.sessionPath = [
      "${installDir}/bin"
      "/opt/cuda/bin"
    ];

    home.sessionVariables = {
      CUDA_HOME = "/opt/cuda";
    };

    # Check on activation if koboldcpp is built
    home.activation.checkKoboldCpp = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      if [ ! -f "${installDir}/bin/koboldcpp.py" ]; then
        $DRY_RUN_CMD echo "⚠️  koboldcpp not built yet. Run: build-koboldcpp"
      fi
    '';

    alienPackages.enabledPackages = [
      "koboldcpp-deps"
    ];
  };
}
