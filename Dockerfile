### Dockerfile for "docker buildx" to produce an offline bundle of Tails OS documentation
### docker buildx plugin - https://github.com/docker/buildx

### Official docs-build process info/steps - https://tails.boum.org/contribute/build/website/
### Use with: docker buildx build --output type=local,dest=. .

### Build parameters:

## Debian distribution image tag/version to use for the build process
## Using "-slim" tags is a good idea to save space/bandwidth, and is supported here
## See https://hub.docker.com/_/debian for the list of available tags
#ARG DEBIAN_TAG= -- defined before FROM block below

## Whether to build all non-english documentation pages
## Default is "no" to only build english stuff, to save time/space, use "yes" value to enable it
#ARG BUILD_LANGS= -- defined under FROM block below, cannot be set here


ARG DEBIAN_TAG=stable-slim
FROM debian:${DEBIAN_TAG} as build

ARG BUILD_LANGS=no

USER 0
RUN mkdir /build
WORKDIR /build

RUN echo >/usr/local/bin/aptx '#!/bin/sh' && chmod +x /usr/local/bin/aptx && \
	printf >>/usr/local/bin/aptx '%s \\\n' 'DEBIAN_FRONTEND=noninteractive exec apt-get' \
	-o=Dpkg::Options::=--force-confold -o=Dpkg::Options::=--force-confdef \
	-o=Dpkg::Options::=--force-unsafe-io -yqq --no-install-recommends '$@' ''

RUN aptx update
RUN aptx install git ca-certificates
RUN update-ca-certificates

RUN git clone --depth=1 https://gitlab.tails.boum.org/tails/tails.git
WORKDIR /build/tails

RUN install --owner root --group root --mode 644 \
	config/chroot_sources/tails.chroot.gpg /etc/apt/trusted.gpg.d/tails.asc
RUN echo >/etc/apt/sources.list.d/ikiwiki.list 'deb https://deb.tails.boum.org/ ikiwiki main'
RUN printf >/etc/apt/preferences.d/ikiwiki.pref \
	'Package: ikiwiki' 'Pin: origin deb.tails.boum.org' 'Pin-Priority: 1000'
RUN aptx update

RUN aptx install ikiwiki perlmagick po4a=0.62-1 \
	libyaml-perl libyaml-libyaml-perl libyaml-syck-perl \
	libxml-treebuilder-perl

# Disable non-english languages to speed-up/slim-down the build
RUN [ "$BUILD_LANGS" != yes ] || { awk \
	'$1=="po_slave_languages:" {print; s=1; next} s&&!/^ / {s=0} !s {print}' \
	<ikiwiki.setup >ikiwiki.setup.new && mv ikiwiki.setup.new ikiwiki.setup; }

RUN ./build-website
RUN [ "$BUILD_LANGS" = yes ] || { \
	cd config/chroot_local-includes/usr/share/doc/tails/website \
	&& { [ -e index.html ] || cp index.en.html index.html; } }


# docker buildx output image
FROM scratch as artifact
COPY --from=build /build/tails/config/chroot_local-includes/usr/share/doc/tails/website /tails-website
