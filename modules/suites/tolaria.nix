{ config, lib, pkgs, ... }:

let
  cfg = config.suites.tolaria;
  tolariaDir = "$HOME/.local/share/tolaria";
in {
  options.suites.tolaria = {
    enable = lib.mkEnableOption "Tolaria - Markdown knowledge base manager";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      pkgs.pnpm
      pkgs.nodejs
      (pkgs.writeShellScriptBin "install-tolaria" ''
        set -euo pipefail

        REPO_DIR="$HOME/.local/share/tolaria"
        BIN_DIR="$HOME/.local/bin"

        echo ">> Cloning Tolaria source..."
        rm -rf "$REPO_DIR"
        git clone --depth 1 "https://github.com/refactoringhq/tolaria.git" "$REPO_DIR"

        cd "$REPO_DIR"

        echo ">> Installing dependencies..."
        pnpm install --frozen-lockfile

        echo ">> Building (this may take 10-30 minutes)..."
        pnpm tauri build

        # Find and link the binary
        TOLARIA_BIN=$(find "$REPO_DIR/src-tauri/target/release" -name "tolaria" -type f 2>/dev/null | head -1)
        if [ -n "$TOLARIA_BIN" ] && [ -x "$TOLARIA_BIN" ]; then
          ln -sf "$TOLARIA_BIN" "$BIN_DIR/tolaria"
          echo ">> Installed: $BIN_DIR/tolaria"
        else
          echo ">> Build complete. Binary at: $REPO_DIR/src-tauri/target/release/tolaria"
        fi
      '')

      (pkgs.writeShellScriptBin "uninstall-tolaria" ''
        set -euo pipefail

        REPO_DIR="$HOME/.local/share/tolaria"
        BIN_DIR="$HOME/.local/bin"

        echo ">> Uninstalling Tolaria..."

        read -p "Remove $REPO_DIR? (y/N) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
          echo "Cancelled."
          exit 0
        fi

        rm -rf "$REPO_DIR"
        rm -f "$BIN_DIR/tolaria"

        echo ">> Clean complete."
      '')
    ];
  };
}