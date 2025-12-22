# NFC Player

Based on [NFC Reader of mueller-ma](https://github.com/mueller-ma/NFCReader),
which in turn is based on [nfc-reader by nadam](https://github.com/mueller-ma/NFCReader).


## Compilation

Compilation requires the [Nix package manager](https://nixos.org/) (but not
NixOS). From a checkout, simply execute:

```
NIXPKGS_ALLOW_UNFREE=1 NIXPKGS_ACCEPT_ANDROID_SDK_LICENSE=1 nix-build
```

If you don't want to bother with a checkout, use:

```
NIXPKGS_ALLOW_UNFREE=1 NIXPKGS_ACCEPT_ANDROID_SDK_LICENSE=1 nix-build https://github.com/iblech/NFCPlayer/archive/main.tar.gz
```

The compilation is hermetic (does not access the internet and is independent
from locally installed packages) and bit-for-bit reproducible. The resulting
APK file and booklet PDF will then reside in the `result` directory. In the
default configuration, as of commit `6552e6e16fda126966653162e4380acb4016141e`
with the nixpkgs collection of NixOS 25.11.1948.c6f52ebd45e5, their sha256 hashes are:

```
1c26d6d694003af3cac3b0136daa3df92b38c4edc676e386fb77bb9c5bfc3971  booklet.pdf
ed86e1652a73de9fd090d53de39b5023f57b60126ac37e6a02b8ccdc98688c16  nfcplayer.apk
```


## Customization

Put your favorite songs in `assets.nix`.

If you want to avoid a Git checkout and still provide your own assets file, use:

```
NIXPKGS_ALLOW_UNFREE=1 NIXPKGS_ACCEPT_ANDROID_SDK_LICENSE=1 nix-build https://github.com/iblech/NFCPlayer/archive/main.tar.gz --arg assets "$(cat ./own-assets.nix)"
```


## Version pinning

This has been tested with the package collection from NixOS 25.11. To force
this collection to be used, use:

```
NIXPKGS_ALLOW_UNFREE=1 NIXPKGS_ACCEPT_ANDROID_SDK_LICENSE=1 nix-build -I nixpkgs=https://nixos.org/channels/nixos-25.11/nixexprs.tar.xz
```


## Physical component

I used the NFC tags from
[here](https://www.berrybase.de/rfid-nfc-schluesselanhaenger-tags-ntag215-farbig-sortiert-10-stueck).
