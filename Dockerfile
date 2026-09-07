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
    make -j$(nproc) TurtleCoind

FROM ubuntu:24.04

RUN apt-get update && apt-get install -y \
    libboost-system1.83.0 libboost-filesystem1.83.0 libboost-serialization1.83.0 \
    ca-certificates coreutils \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /src/build/src/meduzd /usr/local/bin/meduzd

EXPOSE 27897 27898

ENTRYPOINT ["stdbuf", "-oL", "-eL", "/usr/local/bin/meduzd", "--data-dir", "/data", "--no-console", "--rpc-bind-ip", "0.0.0.0", "--p2p-bind-ip", "0.0.0.0"]
