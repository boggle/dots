# Single source of truth for the package-tuning system's default
# compiler/language flags, per march (CPU microarchitecture).
# modules/core/tune-support.nix (home-level, local/wrapped scopes) and
# modules/flake/package-tuning.nix (flake-level, global scope via overlay)
# both import this file instead of each maintaining their own copy.
#
# `dotsLocal.tune.flags.<lang>.<mode>` overrides can still override any of
# these per-machine (see modules/dots-local/schema.nix) - this file is
# just the fallback when no override is set.
{ march }:
{
  c = {
    safe    = "-O2 -pipe";
    default = "-O3 -march=${march} -pipe";
    fast    = "-Ofast -march=${march} -pipe -flto=auto -ffast-math";
  };
  "c++" = {
    safe    = "-O2 -pipe";
    default = "-O3 -march=${march} -pipe";
    fast    = "-Ofast -march=${march} -pipe -flto=auto -ffast-math";
  };
  rust = {
    safe    = "-C opt-level=2";
    default = "-C target-cpu=${march} -C opt-level=3";
    fast    = "-C target-cpu=${march} -C opt-level=3 -C codegen-units=1";
  };
  go = {
    safe    = "";
    default = "-gcflags=all=-march=${march}";
    fast    = "-gcflags=all=-march=${march} -ldflags=-s -w -gcflags=all=-ffast-math";
  };
  haskell = {
    safe    = "--ghc-options=-O1";
    default = "--ghc-options=-O2 --ghc-options=-march=${march}";
    fast    = "--ghc-options=-O2 --ghc-options=-march=${march} --ghc-options=-fllvm --ghc-options=-fexcess-precision";
  };
  zig = {
    safe    = "-Doptimize=ReleaseSafe";
    default = "-Doptimize=ReleaseFast";
    fast    = "-Doptimize=ReleaseFast";
  };
}
