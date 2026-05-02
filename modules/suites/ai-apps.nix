{ config, lib, pkgs, inputs, alien, ... }:

let
  cfg = config.suites.ai-apps;

  grabcontextScript = ''
"""Gather context for AI - outputs valid GitHub-style markdown."""

import os
import sys
import argparse
import subprocess
import base64
import re
import io
import zipfile
from pathlib import Path
from datetime import datetime

try:
    from markitdown import MarkItDown

    MARKITDOWN_AVAILABLE = True
except ImportError:
    MARKITDOWN_AVAILABLE = False

DEFAULT_MAX_CHARS = 4190304
__version__ = "0.3"


class Logger:
    """Real-time logger with dual output support (stderr first, then file)."""

    def __init__(
        self,
        enabled=False,
        log_file=None,
        use_timestamp=False,
        debug_mode=False
    ):
        self.enabled = enabled or log_file or debug_mode
        self.log_file = log_file
        self.use_timestamp = use_timestamp
        self.debug_mode = debug_mode
        self.file_handle = None
        if log_file:
            try:
                self.file_handle = open(log_file, "w")
            except Exception as e:
                print(
                    f"ERROR: Cannot open log file ''${log_file}: {e}",
                    file=sys.stderr,
                )

    def _format_msg(self, level, action, target, status, size=0, details=""):
        """Format a log message."""
        parts = []
        if self.use_timestamp:
            parts.append(datetime.now().strftime("[%H:%M:%S]"))
        parts.append(f"''${level}:")
        parts.append(action)
        parts.append(target)
        parts.append(status)
        if size > 0:
            parts.append(f"''${size}B")
        if details:
            parts.append(details)
        return " ".join(parts)

    def _write(self, msg):
        """Write to stderr first, then file if configured."""
        # Always write to stderr for ERROR/WARN, or if logging enabled
        if self.enabled or msg.startswith("ERROR:") or msg.startswith("WARN:"):
            print(msg, file=sys.stderr)
        # Then write to file if configured
        if self.file_handle:
            self.file_handle.write(msg + "\\n")
            self.file_handle.flush()

    def error(self, msg, target=""):
        """Log error message."""
        full_msg = f"ERROR: ''${msg}"
        if target:
            full_msg += f" [''${target}]"
        self._write(full_msg)

    def warn(self, msg, target=""):
        """Log warning message."""
        full_msg = f"WARN: ''${msg}"
        if target:
            full_msg += f" [''${target}]"
        self._write(full_msg)

    def info(self, action, target, status, size=0, details=""):
        """Log info message."""
        if not self.enabled:
            return
        msg = self._format_msg("INFO", action, target, status, size, details)
        self._write(msg)

    def debug(self, step, target, status="", content=""):
        """Log debug message with optional content."""
        if not self.debug_mode:
            return
        parts = ["DEBUG:", "STEP", step, target]
        if status:
            parts.append(status)
        if content and self.debug_mode:
            # Only include content at debug level
            parts.append(f"[content=''${len(content)}chars]")
        msg = " ".join(parts)
        self._write(msg)

    def close(self):
        """Close log file handle."""
        if self.file_handle:
            self.file_handle.close()


# Language detection mapping for markdown code blocks
LANG_MAP = {
    "py": "python",
    "python": "python",
    "js": "javascript",
    "javascript": "javascript",
    "ts": "typescript",
    "typescript": "typescript",
    "jsx": "jsx",
    "tsx": "tsx",
    "nix": "nix",
    "rs": "rust",
    "rust": "rust",
    "go": "go",
    "golang": "go",
    "sh": "bash",
    "bash": "bash",
    "zsh": "zsh",
    "fish": "fish",
    "ps1": "powershell",
    "yaml": "yaml",
    "yml": "yaml",
    "json": "json",
    "jsonc": "json",
    "toml": "toml",
    "ini": "ini",
    "cfg": "ini",
    "md": "markdown",
    "markdown": "markdown",
    "c": "c",
    "h": "c",
    "cpp": "cpp",
    "cc": "cpp",
    "cxx": "cpp",
    "hpp": "cpp",
    "rb": "ruby",
    "ruby": "ruby",
    "pl": "perl",
    "pm": "perl",
    "perl": "perl",
    "php": "php",
    "phtml": "php",
    "java": "java",
    "kt": "kotlin",
    "kts": "kotlin",
    "scala": "scala",
    "sc": "scala",
    "swift": "swift",
    "ex": "elixir",
    "exs": "elixir",
    "erl": "erlang",
    "hrl": "erlang",
    "hs": "haskell",
    "lhs": "haskell",
    "ml": "ocaml",
    "mli": "ocaml",
    "fs": "fsharp",
    "fsx": "fsharp",
    "fsi": "fsharp",
    "clj": "clojure",
    "cljs": "clojure",
    "cljc": "clojure",
    "edn": "edn",
    "sql": "sql",
    "vim": "vim",
    "vimrc": "vim",
    "lua": "lua",
    "r": "r",
    "R": "r",
    "m": "objectivec",
    "mm": "objectivec",
    "gradle": "groovy",
    "groovy": "groovy",
    "gvy": "groovy",
    "dart": "dart",
    "nim": "nim",
    "cr": "crystal",
    "hx": "haxe",
    "elm": "elm",
    "purs": "purescript",
    "v": "v",
    "vsh": "v",
    "zig": "zig",
    "odin": "odin",
    "carp": "carp",
    "glsl": "glsl",
    "vert": "glsl",
    "frag": "glsl",
    "hlsl": "hlsl",
    "wgsl": "wgsl",
    "dockerfile": "dockerfile",
    "Dockerfile": "dockerfile",
    "makefile": "makefile",
    "Makefile": "makefile",
    "mk": "makefile",
    "cmake": "cmake",
    "CMakeLists.txt": "cmake",
    "justfile": "just",
    "Justfile": "just",
    "env": "dotenv",
    "envrc": "bash",
    "gitignore": "gitignore",
    "gitattributes": "gitattributes",
    "editorconfig": "editorconfig",
    "svg": "svg",
    "xml": "xml",
    "xsl": "xml",
    "xslt": "xml",
    "html": "html",
    "htm": "html",
    "xhtml": "html",
    "css": "css",
    "scss": "scss",
    "sass": "sass",
    "less": "less",
    "diff": "diff",
    "patch": "diff",
    "log": "log",
    "conf": "conf",
}


def get_language(ext):
    """Get markdown language identifier from file extension."""
    ext = ext.lower().lstrip(".")
    return LANG_MAP.get(ext, "text")


def run_transform(content, cmd, logger=None, hard_fail=False, target=""):
    """Run content through external command.

    Args:
        content: String content to transform
        cmd: Shell command to run
        logger: Logger instance for output
        hard_fail: If True, exit with code 3 on failure
        target: Target file/command being processed
    """
    try:
        process = subprocess.Popen(
            cmd,
            shell=True,
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
        )
        stdout, stderr = process.communicate(input=content)
        if process.returncode != 0:
            msg = f"Transform ''${cmd[:30]}...' failed: ''${stderr[:50]}"
            if logger:
                logger.error(msg, target=target)
            else:
                print(f"ERROR: ''${msg} [''${target}]", file=sys.stderr)
            if hard_fail:
                if logger:
                    logger.close()
                sys.exit(3)
            return content
        return stdout
    except Exception as e:
        msg = f"Transform failed: ''${e}"
        if logger:
            logger.error(msg, target=target)
        else:
            print(f"ERROR: ''${msg} [''${target}]", file=sys.stderr)
        if hard_fail:
            if logger:
                logger.close()
            sys.exit(3)
        return content


def load_compress_maps():
    """Load path compression mappings from ~/.grabcontext."""
    maps = {}
    config_path = Path.home() / ".grabcontext"
    if config_path.exists():
        with open(config_path, "r") as f:
            for line in f:
                line = line.strip()
                if "=" in line and not line.startswith("#"):
                    key, val = line.split("=", 1)
                    maps[key.strip()] = val.strip()
    if "HOME" not in maps:
        maps["HOME"] = str(Path.home())
    return maps


def compress_path(path_str, maps):
    """Replace full paths with compressed ''${VAR} notation."""
    abs_p = os.path.abspath(path_str)
    sorted_items = sorted(
        maps.items(), key=lambda item: len(item[1]), reverse=True
    )
    for key, full_path in sorted_items:
        if full_path and abs_p.startswith(full_path):
            return abs_p.replace(full_path, f"''${{{key}}}", 1)
    return abs_p


def format_file_size(size):
    """Format file size in human readable format."""
    if size < 1024:
        return f"''${size} B"
    elif size < 1024 * 1024:
        return f"''${size / 1024:.1f} KB"
    elif size < 1024 * 1024 * 1024:
        return f"''${size / (1024 * 1024):.1f} MB"
    else:
        return f"''${size / (1024 * 1024 * 1024):.1f} GB"


def get_file_metadata(path):
    """Get file metadata for markdown comments."""
    try:
        stat = path.stat()
        size = format_file_size(stat.st_size)
        mtime = datetime.fromtimestamp(
            stat.st_mtime
        ).strftime("%Y-%m-%d %H:%M")
        return f"Size: ''${size}, Modified: ''${mtime}"
    except Exception:
        return ""


def main():
    parser = argparse.ArgumentParser(
        description=(
            "Gather context for AI - outputs valid GitHub-style markdown."
        ),
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""Examples:
  Basic usage:
    grabcontext -f file.py                    # Single file
    grabcontext -f src/*.py -f tests/*.py    # Multiple files
    grabcontext -p .                          # Directory tree

  With command output:
    grabcontext -f main.py -x "git diff HEAD~1"
    grabcontext -f test.py -x "pytest -v"

  With autoformatting:
    grabcontext -f messy.py -F py=black
    grabcontext -f config.nix -F nix=nixfmt

  Harvest mode (convert docs/PDFs to text):
    grabcontext -f report.pdf -f README.md -H

  Force base64 encoding (after harvest):
    grabcontext -f secret.pdf -H -B        # Harvest then base64
    grabcontext -f binary.dat -B           # Force base64 encoding

  No processing (disable harvest and base64):
    grabcontext -f raw.bin -N            # Raw content, no base64
    grabcontext -f file.pdf -H -N        # -N disables -H

  Transform/filter content:
    grabcontext -f data.json -t json="jq '.items[]'"
    grabcontext -f file.py -t py="sed '/^#/d'"

  Complete workflow:
    grabcontext -p . -f src/ -x "git log -10" -o context.md

Path Compression:
  Create ~/.grabcontext with path shortcuts:
    HOME=/home/user
    DOTS=/home/user/dots
    NIXCFG=/etc/nixos

  Then paths appear as ''${HOME}/file

Output Format:
  GitHub-style markdown with code blocks:
    ## FILE: ''${HOME}/project/main.py
    <!-- Size: 2.4 KB, Modified: 2024-03-05 -->

    ```python
    def hello():
        print("world")
    ```

Language Detection:
  Auto-detected for 40+ languages
  Falls back to 'text' for unknown extensions.

Notes:
  - Use -d for dry-run to check file sizes before processing
  - Use -m to limit total output size (default: ~4MB)
  - ANSI colors are automatically stripped
  - Binary files are base64 encoded
  - MarkItDown requires 'harvest' option enabled
""",
    )
    parser.add_argument(
        "--version",
        "-v",
        action="version",
        version=f"%(prog)s ''${__version__}",
    )
    parser.add_argument("--files", "-f", nargs="+", help="Files to include")
    parser.add_argument(
        "--harvest",
        "-H",
        action="store_true",
        help=("Enable MarkItDown conversion (requires markitdown package)"),
    )
    parser.add_argument(
        "--extensions",
        "-X",
        nargs="*",
        help="Restrict harvest conversion to these extensions",
    )
    parser.add_argument(
        "--base64",
        "-B",
        action="store_true",
        help="Force base64 encoding after harvest",
    )
    parser.add_argument(
        "--no-process",
        "-N",
        action="store_true",
        help="Disable harvest (-H) and base64 (-B) processing",
    )
    parser.add_argument(
        "--raw",
        "-r",
        action="store_true",
        help="Strip \\r characters from text files",
    )
    parser.add_argument(
        "--transform",
        "-t",
        action="append",
        help="Transform content: -t ext=cmd or -t =cmd for all",
    )
    parser.add_argument(
        "--format-code",
        "-F",
        action="append",
        help="Autoformat code: -F py=black -F nix=nixfmt",
    )
    parser.add_argument(
        "--exec",
        "-x",
        action="append",
        help="Include command output: -x 'git diff' -x 'pytest -v'",
    )
    parser.add_argument(
        "--dry-run",
        "-d",
        action="store_true",
        help="List files with sizes without reading content",
    )
    parser.add_argument(
        "--skip",
        "-s",
        type=int,
        default=0,
        help="Skip N lines from start of each file",
    )
    parser.add_argument(
        "--limit",
        type=int,
        default=None,
        help="Limit to N lines per file",
    )
    parser.add_argument(
        "--log",
        "-l",
        action="store_true",
        help="Enable logging to stderr",
    )
    parser.add_argument(
        "--log-file",
        "-L",
        help="Log to file (implies -l)",
    )
    parser.add_argument(
        "--timestamp",
        "-T",
        action="store_true",
        help="Add timestamps to log entries",
    )
    parser.add_argument(
        "--debug",
        action="store_true",
        help="Enable debug logging (implies -l)",
    )
    parser.add_argument(
        "--max-chars",
        "-m",
        type=int,
        default=DEFAULT_MAX_CHARS,
        help="Maximum output size in characters",
    )
    parser.add_argument(
        "--format",
        choices=["text", "zip"],
        default="text",
        help="Output format (text=markdown, zip=compressed)",
    )
    parser.add_argument(
        "-o", "--output", default="-", help="Output file (default: stdout)"
    )
    parser.add_argument(
        "--cd",
        default=".",
        help="Change to directory before processing",
    )
    parser.add_argument(
        "--git",
        action="store_true",
        help="Include git status",
    )
    parser.add_argument(
        "--path",
        "-p",
        action="append",
        help="Include tree-style directory listing",
    )
    parser.add_argument(
        "--tree-depth",
        type=int,
        default=None,
        help="Max depth for tree listings (default: unlimited)",
    )

    args = parser.parse_args()

    # Initialize logger
    logger = Logger(
        enabled=args.log,
        log_file=args.log_file,
        use_timestamp=args.timestamp,
        debug_mode=args.debug,
    )

    # Helper function to check if a path is absolute
    def is_abs_path(path):
        return path.startswith("/") or path.startswith("~")

    # Check if directory change is needed and handle errors
    try:
        os.chdir(args.cd)
    except Exception as e:
        # Check if all paths are absolute
        all_paths_absolute = True

        # Check files
        if args.files:
            for f in args.files:
                if not is_abs_path(f):
                    all_paths_absolute = False
                    break

        # Check paths
        if all_paths_absolute and args.path:
            for p in args.path:
                if not is_abs_path(p):
                    all_paths_absolute = False
                    break

        if all_paths_absolute:
            logger.warn(
                f"Ignored --cd ''${args.cd} (absolute paths used): {e}",
                target=args.cd,
            )
        else:
            logger.error(
                f"--cd ''${args.cd} failed and relative paths detected: {e}",
                target=args.cd,
            )
            logger.close()
            sys.exit(1)

    # Parse harvest extensions
    harvest_exts = None
    if args.extensions:
        harvest_exts = {
            e if e.startswith(".") else f".{e}"
            for e in args.extensions
        }

    # Parse transform commands
    transform_map = {}
    for t in args.transform or []:
        if "=" in t:
            parts = t.split("=", 1)
            if len(parts) == 2:
                key = parts[0].lstrip(".") if parts[0] else "*"
                transform_map[key] = parts[1]

    # Parse format commands
    format_map = {}
    for f in args.format_code or []:
        if "=" in f:
            parts = f.split("=", 1)
            if len(parts) == 2:
                format_map[parts[0].lstrip(".")] = parts[1]

    maps = load_compress_maps()
    sections = []

    # Directory listings
    if args.path:
        for p_dir in args.path:
            depth_flag = (
                f"--depth ''${args.tree_depth}" if args.tree_depth else ""
            )
            tree_cmd = (
                f"lsd --tree ''${depth_flag} ''${p_dir} 2>/dev/null || "
                f"tree ''${p_dir} 2>/dev/null || "
                f"find ''${p_dir} -maxdepth 2 -print | head -100"
            )
            tree_out = subprocess.getoutput(tree_cmd)
            compressed_path = compress_path(p_dir, maps)
            depth_str = (
                f" (depth ''${args.tree_depth})" if args.tree_depth else ""
            )
            sections.append(
                (
                    f"## DIRECTORY: ''${compressed_path}''${depth_str}",
                    tree_out,
                    "tree",
                    "",
                )
            )

    # Command outputs
    if args.exec:
        for cmd in args.exec:
            result = subprocess.run(
                cmd, shell=True, capture_output=True, text=True
            )
            exit_code = result.returncode
            output = result.stdout + result.stderr
            header = f"## COMMAND: ''${cmd} (exit: ''${exit_code})"
            sections.append((header, output, "command", ""))

    # Files
    if args.files:
        md = None
        if args.harvest and MARKITDOWN_AVAILABLE:
            md = MarkItDown()

        for f_path in args.files:
            p = Path(f_path)
            if not p.exists():
                logger.warn(f"File not found: ''${f_path}", target=f_path)
                continue

            if args.dry_run:
                size = p.stat().st_size
                print(
                    f"''${compress_path(f_path, maps):<50} | "
                    f"''${format_file_size(size)}"
                )
                continue

            try:
                content = ""
                cp = compress_path(str(p), maps)
                header = f"## FILE: ''${cp}"
                is_b64 = False
                meta = get_file_metadata(p)

                # MarkItDown conversion (disabled by -N)
                should_harvest = (
                    args.harvest and not args.no_process
                    and MARKITDOWN_AVAILABLE
                )
                if should_harvest and md is not None:
                    if (
                        harvest_exts is None
                        or p.suffix.lower() in harvest_exts
                    ):
                        try:
                            content = md.convert(str(p)).text_content
                        except Exception as e:
                            logger.warn(
                                f"MarkItDown failed: {e}",
                                target=f_path,
                            )

                # Raw file reading
                if not content:
                    raw_data = p.read_bytes()
                    # Auto-detect binary or force base64 with -B
                    # (unless -N disables all processing)
                    should_b64 = not args.no_process and (
                        b"\\x00" in raw_data or args.base64
                    )
                    if should_b64:
                        content = base64.b64encode(raw_data).decode("utf-8")
                        is_b64 = True
                    else:
                        content = raw_data.decode("utf-8", errors="replace")

                # Autoformatting
                ext = p.suffix.lstrip(".")
                if not is_b64 and ext in format_map:
                    cmd = format_map[ext]
                    content = run_transform(content, cmd)

                # User transforms
                if not is_b64:
                    trans_cmd = (
                        transform_map.get(ext)
                        or transform_map.get("*")
                    )
                    if trans_cmd:
                        content = run_transform(content, trans_cmd)

                # Skip/limit lines
                if not is_b64:
                    # Use splitlines() with -r to strip \\r, else preserve
                    if args.raw:
                        lines = content.splitlines()
                    else:
                        lines = content.split("\\n")
                    skp = max(0, args.skip)
                    lim = (skp + args.limit) if args.limit else None
                    content = "\\n".join(lines[skp:lim])
                    # Strip ANSI
                    content = re.sub(
                        r"\x1B(?:\x5B[0-?]*[ -/]*[@-~]"
                        r"|[@-Z\\-_])",
                        "",
                        content,
                    )

                lang = "base64" if is_b64 else get_language(ext)
                sections.append((header, content, lang, meta))
            except Exception as e:
                logger.error(
                    f"Processing failed: {e}",
                    target=f_path,
                )

    if args.dry_run:
        return

    # Git status
    if args.git:
        git_out = subprocess.getoutput("git status --short")
        if git_out.strip():
            sections.append(("## GIT STATUS", git_out, "diff", ""))

    # Build output
    out = io.BytesIO() if args.format == "zip" else io.StringIO()

    def check_limit():
        if args.format == "zip":
            if out.tell() > args.max_chars:
                print(
                    f"ABORT: Size limit ''${args.max_chars} bytes exceeded.",
                    file=sys.stderr,
                )
                sys.exit(2)
        else:
            if len(out.getvalue()) > args.max_chars:
                print(
                    f"ABORT: Character limit ''${args.max_chars} exceeded.",
                    file=sys.stderr,
                )
                sys.exit(2)

    if args.format == "zip":
        with zipfile.ZipFile(out, "w", zipfile.ZIP_DEFLATED) as zf:
            for i, (h, c, _, _) in enumerate(sections):
                safe_h = re.sub(r"[^\\w]", "_", h)
                zf.writestr(f"''${safe_h}_''${i}.txt", c)
                check_limit()
    else:
        # Markdown output
        for h, c, lang, meta in sections:
            out.write(f"''${h}\\n")
            if meta:
                out.write(f"<!-- ''${meta} -->\\n")
            out.write(f"\\n```''${lang}\\n''${c}\\n```\\n\\n")
            check_limit()

    res = out.getvalue()
    if args.output == "-":
        if args.format == "zip":
            sys.stdout.buffer.write(res)
        else:
            sys.stdout.write(res)
    else:
        mode = "wb" if args.format == "zip" else "w"
        with open(args.output, mode) as f:
            f.write(res)

    # Close logger
    logger.close()


if __name__ == "__main__":
    main()
  '';

  grabcontext = pkgs.writers.writePython3Bin "grabcontext" {
    libraries = [ pkgs.python3Packages.markitdown ];
    makeWrapperArgs = [
      "--prefix PATH : ${lib.makeBinPath [ pkgs.git pkgs.iproute2 pkgs.coreutils pkgs.lsd pkgs.glow pkgs.bat pkgs.jq pkgs.delta ]}"
    ];
  } grabcontextScript;

  graphifyBootstrap = pkgs.writeShellScriptBin "graphify-bootstrap" ''
    set -euo pipefail

    REPO_URL="https://github.com/safishamsi/graphify.git"
    REPO_DIR="''${XDG_DATA_HOME:-$HOME/.local/share}/dots/graphify"
    VENV_DIR="$REPO_DIR/.venv"
    BIN_DIR="''${XDG_BIN_HOME:-$HOME/.local/bin}"

    mkdir -p "$(dirname "$REPO_DIR")" "$BIN_DIR"

    if [ ! -d "$REPO_DIR/.git" ]; then
      ${pkgs.git}/bin/git clone --branch v3 --depth 1 "$REPO_URL" "$REPO_DIR"
    fi

    if [ ! -x "$VENV_DIR/bin/graphify" ]; then
      ${pkgs.python3}/bin/python3 -m venv "$VENV_DIR"
      "$VENV_DIR/bin/pip" install --upgrade pip
      "$VENV_DIR/bin/pip" install "$REPO_DIR"
    fi

    ln -sf "$VENV_DIR/bin/graphify" "$BIN_DIR/graphify"

    "$BIN_DIR/graphify" install --platform opencode || true
  '';
in
{
  options.suites.ai-apps = {
    enable = lib.mkEnableOption "Enable AI assistant tools";

    grabcontext = lib.mkEnableOption "grabcontext (gather code context for AI) - outputs markdown";
    opencode = lib.mkEnableOption "opencode (AI coding assistant)";
    copilot = lib.mkEnableOption "GitHub Copilot CLI";
    pi = lib.mkEnableOption "pi (terminal coding agent - pi.dev)";
    piPackages = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Pi packages to auto-install via 'pi install npm:<pkg>'. Names are npm package names.";
      example = [ "pi-web-access" "pi-btw" "@juicesharp/rpiv-todo" ];
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = builtins.filter (p: p != null) [
      (alien.mkEntry cfg.grabcontext "grabcontext" grabcontext)
      (alien.mkEntry cfg.opencode "opencode" pkgs.opencode)
      (alien.mkEntry cfg.copilot "github-copilot-cli" pkgs.github-copilot-cli)
    ] ++ (lib.optional cfg.opencode graphifyBootstrap)
      ++ (lib.optionals cfg.pi [
        pkgs.nodejs
        (pkgs.writeShellScriptBin "pi-update" ''
          set -euo pipefail
          export NPM_CONFIG_PREFIX="''${XDG_DATA_HOME:-$HOME/.local/share}/npm-global"
          echo "Updating pi via npm..."
          ${pkgs.nodejs}/bin/npm install -g --no-fund --no-audit --loglevel=error @mariozechner/pi-coding-agent
          echo "Done. Version: $(pi --version)"
        '')
      ]);

    home.sessionVariables = lib.mkIf cfg.pi {
      NPM_CONFIG_PREFIX = "${config.home.homeDirectory}/.local/share/npm-global";
      PI_PACKAGE_DIR = "${config.home.homeDirectory}/.local/share/npm-global/lib/node_modules/@mariozechner/pi-coding-agent";
    };

    home.sessionPath = lib.mkIf cfg.pi [
      "${config.home.homeDirectory}/.local/share/npm-global/bin"
    ];

    home.activation.installPi = lib.mkIf cfg.pi (lib.hm.dag.entryAfter ["writeBoundary"] ''
      export NPM_CONFIG_PREFIX="$HOME/.local/share/npm-global"
      export PI_PACKAGE_DIR="$HOME/.local/share/npm-global/lib/node_modules/@mariozechner/pi-coding-agent"
      export PATH="${pkgs.nodejs}/bin:$NPM_CONFIG_PREFIX/bin:$PATH"
      mkdir -p "$NPM_CONFIG_PREFIX/bin"
      # Keep npm symlink up to date so pi install/update can find it
      ln -sf "${pkgs.nodejs}/bin/npm" "$NPM_CONFIG_PREFIX/bin/npm"
      if [ ! -x "$NPM_CONFIG_PREFIX/bin/pi" ]; then
        echo "Installing pi via npm..."
        ${pkgs.nodejs}/bin/npm install -g --no-fund --no-audit --loglevel=error @mariozechner/pi-coding-agent
      fi
      _PI="$NPM_CONFIG_PREFIX/bin/pi"
      ${lib.optionalString (cfg.piPackages != []) ''
        _PI_INSTALLED=$("$_PI" list 2>/dev/null || true)
        ${lib.concatMapStrings (pkg: ''
          if ! echo "$_PI_INSTALLED" | grep -qF "npm:${pkg}"; then
            echo "Installing pi package: ${pkg}"
            "$_PI" install npm:${pkg} || true
          fi
        '') cfg.piPackages}
      ''}
    '');

    home.file.".grabcontext" = lib.mkIf cfg.grabcontext {
      text = ''
        # Format: VAR=PATH
        NIXCFG=/etc/nixos
        HOME=''${config.home.homeDirectory}
        HOME_DOTS=''${config.home.homeDirectory}/dots
        HOME_CONF=''${config.home.homeDirectory}/.config
        HOME_LOCAL=''${config.home.homeDirectory}/.local
      '';
    };

    home.file.".config/opencode/opencode.json" = lib.mkIf cfg.opencode {
      text = builtins.toJSON {
        "$schema" = "https://opencode.ai/config.json";
        plugin = [
          "${config.home.homeDirectory}/.config/opencode/plugins/graphify.js"
        ];
      };
    };

    home.file.".config/opencode/plugins/graphify.js" = lib.mkIf cfg.opencode {
      text = ''
        // graphify OpenCode plugin
        // Injects a knowledge graph reminder before bash tool calls when the graph exists.
        import { existsSync } from "fs";
        import { join } from "path";

        export const GraphifyPlugin = async ({ directory }) => {
          let reminded = false;

          return {
            "tool.execute.before": async (input, output) => {
              if (reminded) return;
              if (!existsSync(join(directory, "graphify-out", "graph.json"))) return;

              if (input.tool === "bash") {
                output.args.command =
                  'echo "[graphify] Knowledge graph available. Read graphify-out/GRAPH_REPORT.md for god nodes and architecture context before searching files." && ' +
                  output.args.command;
                reminded = true;
              }
            },
          };
        };
      '';
    };

    home.activation.setupGraphifyForOpenCode = lib.mkIf cfg.opencode (lib.hm.dag.entryAfter ["writeBoundary"] ''
      BOOTSTRAP="${graphifyBootstrap}/bin/graphify-bootstrap"
      GRAPHIFY_BIN="''${XDG_BIN_HOME:-$HOME/.local/bin}/graphify"

      if [ ! -x "$GRAPHIFY_BIN" ] && [ -x "$BOOTSTRAP" ]; then
        "$BOOTSTRAP"
      fi

      if [ -x "$GRAPHIFY_BIN" ]; then
        "$GRAPHIFY_BIN" install --platform opencode || true
      fi
    '');

    # Declare which alien packages are enabled
    alienPackages.enabledPackages = 
      (lib.optional cfg.grabcontext "grabcontext") ++
      (lib.optional cfg.opencode "opencode") ++
      (lib.optional cfg.copilot "github-copilot-cli");
  };
}
