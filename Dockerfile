FROM alpine:3 AS build

ARG VERSION="2.84"
ARG CHECKSUM="4caf385376f34fae5c55244a1f870dcf6f90e037bb7c4487210933dc497f9c36"

ADD http://www.thekelleys.org.uk/dnsmasq/dnsmasq-$VERSION.tar.gz /tmp/dnsmasq.tar.gz

RUN [ "$(sha256sum /tmp/dnsmasq.tar.gz | awk '{print $1}')" = "$CHECKSUM" ] && \
    apk add gcc linux-headers make musl-dev && \
    tar -C /tmp -xf /tmp/dnsmasq.tar.gz && \
    cd /tmp/dnsmasq-$VERSION && \
      make LDFLAGS="-static"

RUN mkdir -p /rootfs/bin && \
      cp /tmp/dnsmasq-$VERSION/src/dnsmasq /rootfs/bin/ && \
    mkdir -p /rootfs/etc && \
      echo "nogroup:*:10000:nobody" > /rootfs/etc/group && \
      echo "nobody:*:10000:10000:::" > /rootfs/etc/passwd


FROM scratch

COPY --from=build --chown=10000:10000 /rootfs /

USER 10000:10000
EXPOSE 1053/udp
ENTRYPOINT ["/bin/dnsmasq"]
CMD ["--keep-in-foreground", "--port=1053"]