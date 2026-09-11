FROM ubuntu:24.04 AS builder

RUN apt-get update && apt-get install -y \
    build-essential cmake git \
    libboost-all-dev libssl-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /src
COPY . .

RUN sed -i 's/set(Boost_USE_STATIC_RUNTIME ON)/set(Boost_USE_STATIC_RUNTIME OFF)/' CMakeLists.txt || true

RUN mkdir -p build && cd build && \
    cmake .. -DCMAKE_BUILD_TYPE=Release && \
    make -j$(nproc) TurtleCoind miner WalletService

FROM ubuntu:24.04

RUN apt-get update && apt-get install -y \
    libboost-system1.83.0 libboost-filesystem1.83.0 libboost-serialization1.83.0 \
    ca-certificates coreutils curl bash gosu \
    && rm -rf /var/lib/apt/lists/*

RUN groupadd -g 10001 meduz && useradd -u 10001 -g meduz -M -s /usr/sbin/nologin meduz

COPY --from=builder /src/build/src/meduzd /usr/local/bin/meduzd
COPY --from=builder /src/build/src/miner /usr/local/bin/miner
COPY --from=builder /src/build/src/meduz-service /usr/local/bin/meduz-service
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
COPY docker-entrypoint-root.sh /usr/local/bin/docker-entrypoint-root.sh
RUN chmod +x /usr/local/bin/entrypoint.sh /usr/local/bin/docker-entrypoint-root.sh

EXPOSE 27897 27898

ENTRYPOINT ["stdbuf", "-oL", "-eL", "/usr/local/bin/docker-entrypoint-root.sh"]
