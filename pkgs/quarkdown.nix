{ lib, stdenvNoCC, fetchzip }:

# Since v2.1.0, upstream releases are fully self-contained per-platform
# archives: a Gradle-style launcher script (bin/quarkdown) next to its own
# jars (lib/) AND its own bundled, minimal JRE (runtime/) - the launcher
# resolves APP_HOME/JAVA_HOME relative to its own location and auto-detects
# the bundled runtime, so this is just "unpack and preserve the directory
# layout", with no Nix-provided `jre` dependency, no custom launcher
# substitution, and no JVM/dependency version pinning to maintain - much
# simpler than the old per-jre-version-pinned setup this replaced.
stdenvNoCC.mkDerivation rec {
  pname = "quarkdown";
  version = "2.4.0";

  src = fetchzip {
    url = "https://github.com/iamgio/quarkdown/releases/download/v${version}/quarkdown-linux-x64.zip";
    hash = "sha256-zyOqC+XWl7aY8UugO1QhzP74htJjR61iH5tyEtwH+c8=";
    stripRoot = true;
  };

  dontBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out
    cp -r . $out/
    chmod +x $out/bin/quarkdown
    runHook postInstall
  '';

  meta = {
    description = "Markdown with superpowers: from ideas to papers, presentations, websites, books, and knowledge bases";
    homepage = "https://github.com/iamgio/quarkdown";
    license = lib.licenses.gpl3;
    mainProgram = "quarkdown";
    platforms = [ "x86_64-linux" ];
  };
}
