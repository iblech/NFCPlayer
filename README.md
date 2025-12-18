# NFC Player

Based on [NFC Reader of mueller-ma](https://github.com/mueller-ma/NFCReader),
which in turn is based on [nfc-reader by nadam](https://github.com/mueller-ma/NFCReader).


## Compilation

Compile, from a checkout, with `nix-build`.

The compilation is hermetic (does not access the internet and is independent
from locally installed packages) and bit-for-bit reproducible. The resulting
APK file and booklet PDF will then reside in the `result` directory. In the
default configuration, the sha256 hashes are:

```
1c29e6a23c96181f3c88b770b4b1d8ea40bb1b597ea9f46048242b407b561c58  booklet.pdf
2719605edc381e1d50b94e662958a29fc1df5ced2746a0c5acc19e34d5233bac  nfcplayer.apk
```


## Customization

Put your favorite songs in `assets.nix`.


## Version pinning

This has been tested with the package collection from NixOS 25.11. To force
this collection to be used, use:

```
nix-build -I nixpkgs=https://nixos.org/channels/nixos-25.11/nixexprs.tar.xz
```


## Physical component

I used the NFC tags from
[here](https://www.berrybase.de/rfid-nfc-schluesselanhaenger-tags-ntag215-farbig-sortiert-10-stueck).
