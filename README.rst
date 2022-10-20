Tails offline-docs-bundle builder Dockerfile
============================================

A simple Dockerfile_ to build offline copy of documentation website for
Tails_ privacy-focused portable operating system.

.. _Tails: https://tails.boum.org/
.. _Dockerfile: https://docs.docker.com/engine/reference/builder/


.. contents::
  :backlinks: none

Repository URLs:

- https://github.com/mk-fg/tails-offline-docs-bundle-builder-dockerfile
- https://codeberg.org/mk-fg/tails-offline-docs-bundle-builder-dockerfile
- https://fraggod.net/code/git/tails-offline-docs-bundle-builder-dockerfile


Longer Description
------------------

Tails is a portable desktop linux distribution, packed with nice tools for
private and relatively censorship-resistant internet access, that is easy to
drop onto a USB stick and use with any arbitrary PC or laptop that one might
come across.

Being a specialized OS like that, it incorporates many design decisions - starting
from being portable to avoid possibility of storing persistent logs/data - which
might not be obvious and need some documentation to understand and use correctly.

Which is why it has good documentation on its website (see e.g. its
`Design Documents`_), and also available in the running Tails distribution
(under Documentation option in the main menu), which can be useful in
offline form as well, as a directory of html files (accessible via any
browser/device), and that's what script in this repository puts together.

Using Dockerfile allows for an easy one-command self-contained and
highly-reproducible build process, without needing to install anything except
for docker tools on the host (running any OS supported by docker), where this
documentation bundle will be produced.

Alternative can be to `follow official guidelines for how to do it on debian`_,
or copy documentation directory from e.g. Tails running in a local VM.

Some parts of the docs link to other online resources, but these are
usually not specific to Tails and its quirks, so are out of scope here.
If some limited subset of them is also needed for offline use, can recommend
`SingleFile browser extension`_ that easily saves those with all embedded
content into a single self-contained HTML file with one click.

.. _Design Documents: https://tails.boum.org/contribute/design/
.. _follow official guidelines for how to do it on debian: https://tails.boum.org/contribute/build/website/
.. _SingleFile browser extension: https://github.com/gildas-lormeau/SingleFile


How to use this
---------------

Dockerfile_ is kinda like a makefile - a script for docker builder tool to
run commands in order to create an output (a docker image or other artifact).

`Dockerfile in this repository`_ is intended to be used with first-party
`docker buildx`_ tool/plugin to produce "tails-website" directory,
by running the following command (in the same dir as Dockerfile)::

  docker buildx build --output type=local,dest=. .

Command does not need sudo/root permissions, only access to a running docker daemon socket.

It should go through all steps, finishing with "exporting to client / copying files",
creating "tails-website" directory under the current dir (according to ``dest=.`` option).

If running the command prints error with a long help message, make sure
docker-buildx plugin is installed (e.g. ``pacman -S docker-buildx``),
while any errors mentioning docker socket or permissions on it usually indicate
that either docker daemon is not running on the system (has to be started with
``systemctl start docker`` or such), or "docker buildx" command has no permission
to access its socket (often solved by proper group or something - see docker or
distro-specific docs for it).

Copy resulting "tails-website" dir somewhere portable (or whatever reader device),
open "index.html" file in it using any browser or an html reader app, and access
all documentation pages via links from there.

Dockerfile for the buld command above also supports some customization
via --build-arg option(s), for example ``--build-arg DEBIAN_TAG=bullseye-slim``
to use specific debian release for the build (see `dockerhub page for debian
image`_ for a list of these, default is "stable-slim" moving target),
or ``--build-arg BUILD_LANGS=yes`` to build all non-english language translations
(disabled by default for faster build and smaller resulting dir).
See Dockerfile itself for a full list of such supported customizations at the top.

.. _Dockerfile in this repository: Dockerfile
.. _docker buildx: https://github.com/docker/buildx
.. _dockerhub page for debian image: https://hub.docker.com/_/debian


Misc links, tips and tricks
---------------------------


- Tails can be run in a Virtual Machine from ISO file within some existing OS,
  producing an almost-certainly more private environment than general-purpose
  host OS with same things installed there, for a variety of good reasons.


- Modern USB sticks can have a lot of space, much more than 1-2G that Tails needs,
  and it is silly to only write/carry a single distribution image/iso on those.

  Easy way to cram as many of these there as one wants, with a space to spare
  for any normal files too, is to put a `Ventoy tool`_ on the USB drive itself,
  and drop distribution images/ISOs in there, which will all become bootable options.


- If Ventoy isn't your cup of tea for any reason (need custom partitioning/fs
  setup for example), modern GRUB bootloader also supports booting ISO files
  just fine, but has to be manually configured with regards to kernel/initrd
  paths in there, and their boot parameters.

  That way one can format/partition the USB drive in any way, run ``grub-install``
  on it as with any boot drive, with entries like these in grub.cfg file to have
  it boot specified iso file, with the usual debian live-boot/initramfs parameters
  (as of tails-amd64-5.5.iso)::

    # --- Tails
    # Auth: user:live
    # Useful args: toram debug=1 ip=[device]:[client_ip]:[netmask]:[gateway_ip]:[nameserver]
    # https://tails.boum.org/blueprint/usb_install_and_upgrade/archive/
    # https://manpages.debian.org/testing/live-boot-doc/live-boot.7.en.html
    set iso_tails=/images/tails.iso

    menuentry "tails.iso" {
      loopback loop $iso_tails
      linux (loop)/live/vmlinuz boot=live config live-media=removable \
        nopersistence noprompt timezone=Etc/UTC splash noautologin module=Tails \
        slab_nomerge slub_debug=FZ mce=0 vsyscall=none init_on_free=1 mds=full,nosmt \
        page_alloc.shuffle=1 findiso=$iso_tails  quiet
      initrd (loop)/live/initrd.img
    }

    menuentry "tails.iso [troubleshooting]" {
      loopback loop $iso_tails
      linux (loop)/live/vmlinuz boot=live config live-media=removable \
        nopersistence noprompt timezone=Etc/UTC splash noautologin module=Tails \
        slab_nomerge slub_debug=FZ mce=0 vsyscall=none init_on_free=1 mds=full,nosmt \
        page_alloc.shuffle=1 findiso=$iso_tails \
        noapic noapm nodma nomce nolapic nomodeset nosmp vga=normal
      initrd (loop)/live/initrd.img
    }

  More up-to-date cmdline opts can be copied from ``isolinux/live64.cfg``
  on the tails iso file itself, which it normally uses to start through
  isolinux bootloader there.


- Any MicroSD card can be easily formatted with MBR and normal first partition
  for windows/smartphone data, followed by e.g. ext4 with ISOs and GRUB2 in there,
  and used as a bootable media with any USB card-reader.


.. _Ventoy tool: https://www.ventoy.net/
