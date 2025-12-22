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

  fetchFromYouTube-raw = video: pkgs.stdenv.mkDerivation {
    name = "nfcplayer-asset-raw-${builtins.hashString "sha256" video.url}";
    nativeBuildInputs = with pkgs; [ yt-dlp ];
    unpackPhase = ":";
    outputHashMode = "recursive";
    outputHashAlgo = "sha256";
    outputHash = video.hash;

    buildPhase = ''
      mkdir $out
      cd $out
      export HOME=$(mktemp -d)
      yt-dlp -o song.m4a --write-thumbnail -f 140 --fixup never ${pkgs.lib.escapeShellArg video.url}
    '';
  };

  fetchFromYouTube = video: pkgs.stdenv.mkDerivation {
    name = "nfcplayer-asset-converted-${builtins.hashString "sha256" video.url}";
    src = fetchFromYouTube-raw video;
    nativeBuildInputs = with pkgs; [ imagemagick ffmpeg ];
    buildPhase = ''
      mkdir $out
      ffmpeg -fflags +bitexact -flags:a +bitexact -i song.m4a $out/song.mp3
      magick song.webp $out/cover.jpeg
      echo ${pkgs.lib.escapeShellArg video.url} > $out/url.txt
    '';
  };

  berryIcons = pkgs.lib.genAttrs [
    "black"
    "blue"
    "darkgreen"
    "gray"
    "lightgreen"
    "purple"
    "red"
    "white"
    "yellow"
  ] (color: ./berry-icons + "/${color}.jpeg");

  prepareAsset = asset:
    let id = builtins.hashString "sha256" (builtins.toJSON asset);
    in pkgs.stdenv.mkDerivation {
      name = "nfcplayer-asset-full-${id}";
      src = [ asset.src ];
      buildPhase = ''
        songhash=$(sha256sum song.mp3 | cut -c1-64)
        outdir=$out/$songhash
        mkdir -p $outdir
        cp --reflink=auto song.mp3 cover.jpeg $outdir/
        if [ -e url.txt ]; then
          cp --reflink=auto url.txt $outdir/
        fi
        cp --reflink=auto ${asset.icon} $outdir/icon.jpeg
        echo ${pkgs.lib.escapeShellArg (builtins.concatStringsSep " " asset.tags)} > $outdir/tags.txt
      '';
    };

  entries = pkgs.symlinkJoin {
    name = "nfcplayer-entries";
    paths = map prepareAsset (assets { inherit fetchFromYouTube berryIcons; });
  };
in

pkgs.stdenv.mkDerivation {
  name = "nfcplayer";

  src = pkgs.runCommandLocal "nfcplayer-src" {} ''
    mkdir $out
    for i in ${./app} ${./build.gradle} ${./gradle.properties} ${./settings.gradle} ${./tex} ${entries}; do
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
        if [ -e "$i/url.txt" ]; then
          echo "\\href{$(cat $i/url.txt)}{\\includegraphics[width=0.8\\textwidth]{$i/cover}}"
        else
          echo "\\includegraphics[width=0.8\\textwidth]{$i/cover}"
        fi
        echo "\\par"
        echo "\\includegraphics[height=4cm]{$i/icon}"
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
    (texlive.combine { inherit (pkgs.texlive) scheme-small pdftex; })
  ];

  ANDROID_HOME = "${androidPkgs.androidsdk}/libexec/android-sdk";

  buildPhase = ''
    (
      cd tex
      SOURCE_DATE_EPOCH=0 pdflatex booklet
      SOURCE_DATE_EPOCH=0 pdflatex booklet
    )

    base64 -d ${./debug.keystore.b64} > debug.keystore
    gradle \
      -Dorg.gradle.project.android.aapt2FromMavenOverride=$ANDROID_HOME/build-tools/34.0.0/aapt2 \
      -I ${gradle-init-script} \
      assembleDebug
  '';

  installPhase = ''
    mkdir -p $out
    cp app/build/outputs/apk/debug/app-debug.apk $out/nfcplayer.apk
    cp tex/booklet.pdf $out/
  '';
}
