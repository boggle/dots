{ lib, stdenvNoCC, fetchzip, jre }:

stdenvNoCC.mkDerivation rec {
  pname = "quarkdown";
  version = "2.0.0";

  src = fetchzip {
    url = "https://github.com/iamgio/quarkdown/releases/download/v${version}/quarkdown.zip";
    hash = "sha256-nZVZ23m/ODFp18otHxDy6LYWmu2wnN+e9Rnznr97DHE=";
  };

  installPhase = ''
    mkdir -p $out/share/quarkdown $out/bin

    # Copy the full distribution
    cp -r lib $out/share/quarkdown/

    # Rewrite the launcher to use the nix-provided java and correct APP_HOME
    substitute ${./quarkdown-launcher.sh} $out/bin/quarkdown \
      --subst-var-by JAVA_CMD ${jre}/bin/java \
      --subst-var-by APP_HOME $out/share/quarkdown

    chmod +x $out/bin/quarkdown
  '';

  meta = {
    description = "Markdown with superpowers: from ideas to papers, presentations, websites, books, and knowledge bases";
    homepage = "https://github.com/iamgio/quarkdown";
    license = lib.licenses.gpl3;
    mainProgram = "quarkdown";
  };
}
