FROM alpine:3.8 AS builder

RUN apk add --no-cache \
    autoconf \
    automake \
    boost-dev \
    build-base \
    openssl-dev \
    libevent-dev \
    libtool \
    zeromq-dev

RUN wget -qO- https://github.com/vertcoin-project/vertcoin-core/archive/0.13.2.tar.gz | tar xz
WORKDIR /vertcoin-core-0.13.2

RUN ./autogen.sh
RUN ./configure \
  --disable-shared \
  --disable-static \
  --disable-wallet \
  --disable-tests \
  --disable-bench \
  --enable-zmq \
  --with-utils \
  --without-libs \
  --without-gui
RUN make -j$(nproc)
RUN strip src/vertcoind src/vertcoin-cli


FROM alpine:3.8

RUN apk add --no-cache \
  boost \
  boost-program_options \
  openssl \
  libevent \
  zeromq

RUN addgroup -g 1000 vertcoind \
  && adduser -u 1000 -G vertcoind -s /bin/sh -D vertcoind

USER vertcoind

# P2P & RPC
EXPOSE 5889 5888

WORKDIR /home/vertcoind

COPY --chown=vertcoind:vertcoind --from=builder /vertcoin-core-0.13.2/src/vertcoind /vertcoin-core-0.13.2/src/vertcoin-cli ./

ENTRYPOINT ["./vertcoind"]
