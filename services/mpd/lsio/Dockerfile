FROM ghcr.io/linuxserver/baseimage-ubuntu:noble

RUN --mount=type=cache,target=/var/cache/apt \
    --mount=type=cache,target=/var/lib/apt \
    apt-get update && apt-get install -y mpd

CMD ["/usr/bin/mpd", "--no-daemon", "--stdout", "/config/mpd.conf"]
