# anbox-image-make

postmarketOS' Makefile for creating anbox images using a chroot.

## Usage

The targets are documented in the code: look for `#` at the begining
of a line for an explaination. tl;dr: `make image` and enjoy `./android*.img`.

Have a look at the first lines: those are variables that you will
probably want to set.

## Dependencies
* `debootstrap`;
* `arch-chroot`;
* `repo`;
* a network connection to prepare the chroot and to fetch the source.
