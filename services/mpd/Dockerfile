ARG MPD_VERSION="0.23.15"

FROM alpine:edge as builder

ARG MPD_VERSION
ENV MPD_VERSION=$MPD_VERSION

RUN apk add --no-cache build-base boost ninja boost-dev meson curl
RUN apk add --no-cache alsa-lib-dev sqlite-dev ffmpeg-dev opus-dev libogg-dev flac-dev libvorbis-dev curl-dev

RUN set -o pipefail && curl https://www.musicpd.org/download/mpd/${MPD_VERSION:0:4}/mpd-${MPD_VERSION}.tar.xz | tar xJ

WORKDIR mpd-${MPD_VERSION}

RUN meson setup . output/release \
  --prefix=/usr \
  --sysconfdir=/etc \
  --mandir=/usr/share/man \
  --localstatedir=/var \
  --buildtype=release \
  -Dcue=true \
  -Ddaemon=false \
  -Ddatabase=true \
  -Depoll=true \
  -Deventfd=true \
  -Dfifo=true \
  -Dinotify=true \
  -Dlocal_socket=false \
  -Dpipe=true \
  -Dsignalfd=true \
  -Dtcp=true \
  -Dalsa=enabled \
  -Dffmpeg=enabled \
  -Dipv6=enabled \
  -Dsqlite=enabled \
  -Dsyslog=disabled \
  -Ddocumentation=disabled \
  -Ddsd=false \
  -Dhttpd=true \
  -Dneighbor=false \
  -Drecorder=false \
  -Dtest=false \
  -Dwave_encoder=false \
  -Dadplug=disabled \
  -Dao=disabled \
  -Daudiofile=disabled \
  -Dbzip2=disabled \
  -Dcdio_paranoia=disabled \
  -Dchromaprint=disabled \
  -Dcurl=enabled \
  -Ddbus=disabled \
  -Dexpat=disabled \
  -Dfaad=disabled \
  -Dflac=enabled \
  -Dfluidsynth=disabled \
  -Dgme=disabled \
  -Diconv=disabled \
  -Dicu=disabled \
  -Did3tag=disabled \
  -Diso9660=disabled \
  -Djack=disabled \
  -Dlame=disabled \
  -Dlibmpdclient=disabled \
  -Dlibsamplerate=disabled \
  -Dmad=disabled \
  -Dmikmod=disabled \
  -Dmms=disabled \
  -Dmodplug=disabled \
  -Dmpcdec=disabled \
  -Dmpg123=disabled \
  -Dnfs=disabled \
  -Dopenal=disabled \
  -Dopus=enabled \
  -Doss=disabled \
  -Dpcre=disabled \
  -Dpulse=disabled \
  -Dqobuz=disabled \
  -Dshine=disabled \
  -Dshout=disabled \
  -Dsidplay=disabled \
  -Dsmbclient=disabled \
  -Dsndfile=disabled \
  -Dsndio=disabled \
  -Dsolaris_output=disabled \
  -Dsoundcloud=disabled \
  -Dsoxr=disabled \
  -Dsystemd=disabled \
  -Dtremor=disabled \
  -Dtwolame=disabled \
  -Dudisks=disabled \
  -Dupnp=disabled \
  -Dvorbis=disabled \
  -Dvorbisenc=disabled \
  -Dwavpack=disabled \
  -Dwebdav=disabled \
  -Dwildmidi=disabled \
  -Dyajl=disabled \
  -Dzeroconf=disabled \
  -Dzlib=enabled \
  -Dzzip=disabled

RUN meson configure output/release
RUN ninja -C output/release


FROM ghcr.io/linuxserver/baseimage-alpine:edge
ARG MPD_VERSION
RUN apk add --no-cache sqlite-libs alsa-lib alsa-utils ffmpeg opus libogg flac libvorbis curl zlib libstdc++ libgcc
COPY --from=builder /mpd-${MPD_VERSION}/output/release/mpd /usr/bin/mpd
CMD ["/usr/bin/mpd", "--no-daemon", "--stdout", "/config/mpd.conf"]
