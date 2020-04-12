# Makefile for building the postmarketOS anbox image.
# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright 2020 Antoine Fontaine <antoine.fontaine@epfl.ch>

# configuration options
CHROOT_PATH ?= /var/chroot/$(RELEASE)/
ANBOX_SOURCE ?= ./source
ANBOX_OUT ?= ./out
ANBOX_IMAGE_OUT ?= .
CARCH ?= x86_64
# end of configuration options


RELEASE := xenial
MIRROR := http://archive.ubuntu.com/ubuntu/

# yay conventions
arch_aarch64 := arm64
arch_armv7 := armv7a_neon
arch_x86_64 := x86_64
ARCH := $(arch_${CARCH})

# yay not even following your convention
arch_dir_aarch64 := arm64
arch_dir_armv7 := armv7-a-neon
arch_dir_x86_64 := x86_64
ARCH_DIR := $(arch_dir_${CARCH})

.PHONY: remove-chroot
remove-chroot:
	sudo umount $(CHROOT_PATH)/home/build/source/out ||:
	sudo umount $(CHROOT_PATH)/home/build/source ||:
	sudo rm -rf $(CHROOT_PATH)

.PHONY: clean
clean:
	rm -rf $(ANBOX_OUT)/*

.PHONY: nuke
nuke: clean remove-chroot


# creates a chroot at $(CHROOT_PATH)
.ONESHELL: $(CHROOT_PATH)
$(CHROOT_PATH):
	export CHROOT_PATH=$(CHROOT_PATH) RELEASE=$(RELEASE) MIRROR=$(MIRROR)
	sudo debootstrap --variant=buildd --arch amd64 $$RELEASE $$CHROOT_PATH $$MIRROR
	sudo arch-chroot $$CHROOT_PATH <<EOT
	apt update
	apt install -y \
		git-core \
		gnupg \
		flex \
		bison \
		libgoogle-perftools4 \
		build-essential \
		zip \
		curl \
		zlib1g-dev \
		gcc-multilib \
		g++-multilib \
		libc6-dev-i386 \
		lib32ncurses5-dev \
		x11proto-core-dev \
		libx11-dev lib32z-dev \
		libgl1-mesa-dev \
		libxml2-utils \
		xsltproc \
		unzip \
		gawk \
		python \
		sudo \
		cpio \
		squashfs-tools \
		openjdk-8-jdk
	useradd build -m -s /bin/bash
	su build -c "mkdir ~/source"
	EOT

# alias for $(CHROOT_PATH), meant to be called from outside of the Makefile (`make chroot`)
.PHONY: chroot
chroot: $(CHROOT_PATH)


.PHONY: build
.ONESHELL: build
build: $(CHROOT_PATH)
	export CHROOT_PATH=$(CHROOT_PATH) ANBOX_SOURCE=$(ANBOX_SOURCE) \
		ANBOX_OUT=$(ANBOX_OUT) ARCH=$(ARCH)
	mountpoint -q $$CHROOT_PATH/home/build/source || \
		sudo mount $$ANBOX_SOURCE --bind -o ro \
			$$CHROOT_PATH/home/build/source
	mountpoint -q $$CHROOT_PATH/home/build/source/out || \
		sudo mount $$ANBOX_OUT --bind -o rw || \
			$$CHROOT_PATH/home/build/source/out \
			# building out of tree is broken
	mountpoint -q $$CHROOT_PATH/home/build/source || sudo mount $$ANBOX_SOURCE --bind -o ro $$CHROOT_PATH/home/build/source
	mountpoint -q $$CHROOT_PATH/home/build/source/out || sudo mount $$ANBOX_OUT --bind -o rw $$CHROOT_PATH/home/build/source/out # building out of tree is broken
	sudo arch-chroot $$CHROOT_PATH <<EOT2
	sudo -u build -i <<EOT
	export LC_ALL=C.UTF-8
	export _JAVA_OPTIONS="-Xmx3072m" # increase heap size
	cd /home/build/source
	. build/envsetup.sh
	lunch anbox_$$ARCH-userdebug
	make -j8
	EOT
	EOT2


.PHONY: image
image: build
	sudo arch-chroot $(CHROOT_PATH) sh -c \
		"cd /home/build/source/vendor/anbox && \
		scripts/create-package.sh \
			/home/build/source/out/target/product/x86_64/ramdisk.img \
			/home/build/source/out/target/product/x86_64/system.img \
			/home/build/source/out/android.img"
	mv $(CHROOT_PATH)/home/build/source/out/android.img \
		$(ANBOX_IMAGE_OUT)/android-$(CARCH).img
	@printf "Written $%s. Have a good day!" \
		"$(ANBOX_IMAGE_OUT)/android-$(CARCH).img"
