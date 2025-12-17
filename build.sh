#!/usr/bin/env nix-shell
#! nix-shell -I nixpkgs=https://nixos.org/channels/nixos-25.11/nixexprs.tar.xz -i bash -p gradle openjdk kotlin '(androidenv.composeAndroidPackages { platformVersions = [ "34" ]; buildToolsVersions = [ "34.0.0" ]; includeNDK = true; ndkVersions = [ "26.1.10909125" ]; }).androidsdk' 'texlive.combine { inherit (texlive) scheme-small pdftex; }'

set -e

export ANDROID_HOME=$(echo $PATH | tr : '\n' | grep androidsdk)/../libexec/android-sdk
export GRADLE="gradle -Dorg.gradle.project.android.aapt2FromMavenOverride=$ANDROID_HOME/build-tools/34.0.0/aapt2"

$GRADLE clean
rm -rf book.pdf app/src/main/res/raw tex nfcplayer.apk build .gradle

echo Finished cleaning.
read -t3 || true

mkdir -p app/src/main/res/raw

{
  cat <<EOF
package com.github.iblech.nfcplayer

fun tagToRawResource(key: String): Int? =
  when(key) {
EOF

  for i in entries/*; do
    cat $i/tags.txt | while read; do
      songhash=$(sha256sum $i/song.mp3 | cut -c1-64)
      cp --reflink=auto $i/song.mp3 app/src/main/res/raw/song_$songhash.mp3
      echo "    \"$REPLY\" -> R.raw.song_$songhash"
    done
  done

  echo "    else -> null"
  echo "  }"
} > app/src/main/java/com/github/iblech/nfcreader/Entries.kt

rm -rf tex
mkdir tex
{
  cat <<'EOF'
\documentclass[a4paper,landscape]{article}
\pagestyle{empty}
\usepackage{graphicx}
\usepackage[left=2cm,top=2cm,right=2cm,bottom=2cm]{geometry}
\begin{document}
\centering
EOF

  for i in entries/*; do
    echo "\\includegraphics[width=0.8\\textwidth]{../$i/image}"
    echo "\\par"
    echo "\\includegraphics[height=4cm]{../tag-images/$(cat $i/color.txt)}"
    echo "\\newpage"
    echo
  done

  echo '\end{document}'
} > tex/main.tex
(
  cd tex
  pdflatex main
  pdflatex main
)
mv tex/main.pdf book.pdf
rm -r tex

$GRADLE assemble --stacktrace

cp --reflink=auto app/build/outputs/apk/debug/app-debug.apk nfcplayer.apk
