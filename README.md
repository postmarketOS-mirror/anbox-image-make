# anbox-image-make

postmarketOS' Makefile for creating anbox images using a chroot.

## Requirements

I could build with 8GB RAM and 8GB swap. You may get away with less, especially
if you lower the amount of jobs (replace -j8 with -j1 in the Makefile).

You should have at least 100GB of disk free. Sources are 30GB when using bare
git repo (the default), chroot is 1GB and binaries varies between architectures
(20GB for armv7, 37GB for aarch64 and something else for x86\_64). The images
are 200-300MB.

## Dependencies
* GNU `make`;
* `debootstrap`;
* `arch-chroot`;
* `repo`;
* a network connection to prepare the chroot and to fetch the source.

`apt install make debootstrap arch-install-scripts repo`  
`apk add make debootstrap arch-install-scripts repo`

## Usage

tl;dr: `make image` and enjoy `./android*.img`.

Have a look at `make help`, it contains some explanations. Or look at the
Makefile itself.
