{ pkgs ? import <nixpkgs> {}, assets ? import ./assets.nix }:

let
  androidPkgs = pkgs.androidenv.composeAndroidPackages {
    platformVersions = [ "34" ];
    buildToolsVersions = [ "34.0.0" ];
  };

  gradle-dot-nix = pkgs.fetchFromGitHub {
    owner = "CrazyChaoz";
    repo = "gradle-dot-nix";
    rev = "3de6aa22716cd852f31632f617ef37b3df14df40";
    hash = "sha256-orvfEgiu/pcK0PUWAQUAR8ltz1rYHk1NwUiwkvy0Vaw=";
  };

  gradle-init-script = (import gradle-dot-nix {
    inherit pkgs;
    # Can be generated using gradle -M sha256 build
    gradle-verification-metadata-file = ./gradle/verification-metadata.xml;
  }).gradle-init;

  fetch-from-youtube = asset: pkgs.stdenv.mkDerivation {
    name = "asset-raw-${builtins.hashString "sha256" asset.url}";
    nativeBuildInputs = with pkgs; [ yt-dlp ];
    unpackPhase = ":";
    outputHashMode = "recursive";
    outputHashAlgo = "sha256";
    outputHash = asset.hash;

    buildPhase = ''
      mkdir $out
      cd $out
      export HOME=$(mktemp -d)
      yt-dlp -o song.m4a --write-thumbnail -f 140 ${pkgs.lib.escapeShellArg asset.url}
    '';
  };

  use-from-youtube = asset: pkgs.stdenv.mkDerivation {
    name = "asset-full-${builtins.hashString "sha256" asset.url}";
    src = fetch-from-youtube asset;
    nativeBuildInputs = with pkgs; [ imagemagick ffmpeg ];
    buildPhase = ''
      outdir=$out/${builtins.hashString "sha256" asset.url}
      mkdir -p $outdir
      ffmpeg -i song.m4a $outdir/song.mp3
      magick song.webp $outdir/image.jpeg
      echo ${pkgs.lib.escapeShellArg asset.color} > $outdir/color.txt
      echo ${pkgs.lib.escapeShellArg (builtins.concatStringsSep " " asset.tags)} > $outdir/tags.txt
    '';
  };

  entries = pkgs.symlinkJoin {
    name = "entries";
    paths = map use-from-youtube assets;
  };
in

pkgs.stdenv.mkDerivation {
  name = "nfcplayer";

  src = pkgs.runCommandLocal "nfcplayer-src" {} ''
    mkdir $out
    for i in ${./app} ${./build.gradle} ${./gradle.properties} ${./settings.gradle} ${./tag-images} ${./tex} ${entries}; do
      cp --reflink=auto -r $i $out/''${i:44}
    done

    chmod u+w $out/app/src/main/res
    mkdir $out/app/src/main/res/raw
    chmod u+w $out/app/src/main/res/raw $out/app/src/main/java/com/github/iblech/nfcreader $out/tex

    {
      for i in ${entries}/*; do
        songhash=$(sha256sum $i/song.mp3 | cut -c1-64)
        cp --reflink=auto $i/song.mp3 $out/app/src/main/res/raw/song_$songhash.mp3
        for t in $(cat $i/tags.txt); do
          echo "    \"$t\" -> R.raw.song_$songhash"
        done
      done
    } | sed -i -e '/AUTO-INSERT HERE/ r /dev/stdin' $out/app/src/main/java/com/github/iblech/nfcreader/Entries.kt

    {
      for i in ${entries}/*; do
        echo "\\includegraphics[width=0.8\\textwidth]{$i/image}"
        echo "\\par"
        echo "\\includegraphics[height=4cm]{../tag-images/$(cat $i/color.txt)}"
        echo "\\newpage"
        echo
      done
    } | sed -i -e '/AUTO-INSERT HERE/ r /dev/stdin' $out/tex/booklet.tex
  '';

  nativeBuildInputs = with pkgs; [
    gradle
    openjdk
    kotlin
    androidPkgs.androidsdk
    strip-nondeterminism
    (texlive.combine { inherit (pkgs.texlive) scheme-small pdftex; })
  ];

  ANDROID_HOME = "${androidPkgs.androidsdk}/libexec/android-sdk";

  buildPhase = ''
    export SOURCE_DATE_EPOCH=0

    (
      cd tex
      pdflatex booklet
      pdflatex booklet
    )

    base64 -d ${./debug.keystore.b64} > debug.keystore
    gradle \
      -Dorg.gradle.project.android.aapt2FromMavenOverride=$ANDROID_HOME/build-tools/34.0.0/aapt2 \
      -I ${gradle-init-script} \
      assembleDebug
  '';

  postFixup = ''
    strip-nondeterminism app/build/outputs/apk/debug/app-debug.apk
  '';

  installPhase = ''
    mkdir -p $out
    cp app/build/outputs/apk/debug/app-debug.apk $out/nfcplayer.apk
    cp tex/booklet.pdf $out/
  '';
}
