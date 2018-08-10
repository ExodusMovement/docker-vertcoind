FROM ubuntu:18.04 AS builder

RUN apt update
RUN apt install -y --no-install-recommends \
  autoconf \
  automake \
  build-essential \
  ca-certificates \
  libboost-chrono-dev \
  libboost-filesystem-dev \
  libboost-program-options-dev \
  libboost-system-dev \
  libboost-thread-dev \
  libczmq-dev \
  libevent-dev \
  libssl-dev \
  libtool \
  pkg-config \
  wget

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


FROM ubuntu:18.04

RUN apt update \
  && apt-get install -y --no-install-recommends \
    libboost-chrono1.65.1 \
    libboost-filesystem1.65.1 \
    libboost-program-options1.65.1 \
    libboost-system1.65.1 \
    libboost-thread1.65.1 \
    libczmq-dev \
    libevent-dev \
    libssl-dev \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

RUN groupadd --gid 1000 vertcoind \
  && useradd --uid 1000 --gid vertcoind --shell /bin/bash --create-home vertcoind

USER vertcoind

RUN mkdir -p /home/vertcoind/.vertcoin

WORKDIR /home/vertcoind
COPY --chown=vertcoind:vertcoind --from=builder /vertcoin-core-0.13.2/src/vertcoind /vertcoin-core-0.13.2/src/vertcoin-cli ./

# P2P & RPC
EXPOSE 5889 5888

ENV \
  VERTCOIND_DBCACHE=450 \
  VERTCOIND_PAR=0 \
  VERTCOIND_PORT=5889 \
  VERTCOIND_RPC_PORT=5888 \
  VERTCOIND_RPC_THREADS=4 \
  VERTCOIND_ARGUMENTS=""

CMD exec ./vertcoind \
  -dbcache=$VERTCOIND_DBCACHE \
  -par=$VERTCOIND_PAR \
  -port=$VERTCOIND_PORT \
  -rpcport=$VERTCOIND_RPC_PORT \
  -rpcthreads=$VERTCOIND_RPC_THREADS \
  $VERTCOIND_ARGUMENTS
