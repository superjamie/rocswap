FROM docker.io/library/debian:trixie-slim AS build

WORKDIR /git

RUN DEBIAN_FRONTEND=noninteractive apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get -y install \
    build-essential cmake curl git hipcc libhipblas-dev librocblas-dev wget && \
    git clone https://github.com/ggerganov/llama.cpp /git && \
    mkdir -p /app && \
    HIPCXX=clang-17 cmake -H. -B/app \
    -DGGML_HIP=ON -DGGML_HIPBLAS=ON \
    -DAMDGPU_TARGETS="gfx1010" -DCMAKE_HIP_ARCHITECTURES="gfx1010" \
    -DCMAKE_BUILD_TYPE=Release && \
    make -j $(nproc) -C /app llama-server && \
    wget https://github.com/mostlygeek/llama-swap/releases/download/v78/llama-swap_78_linux_amd64.tar.gz && \
    tar xf llama-swap_78_linux_amd64.tar.gz

FROM docker.io/library/debian:trixie-slim AS runtime

WORKDIR /app

COPY --from=build /git/llama-swap /app/
COPY --from=build /app/bin/llama-server /app/
COPY --from=build /app/src/libllama.so /app/src/libllama.so
COPY --from=build /app/ggml/src/libggml.so /app/ggml/src/libggml.so
COPY --from=build /app/ggml/src/libggml-base.so /app/ggml/src/libggml-base.so
COPY --from=build /app/ggml/src/libggml-cpu.so /app/ggml/src/libggml-cpu.so
COPY --from=build /app/ggml/src/ggml-hip/libggml-hip.so /app/ggml/src/ggml-hip/libggml-hip.so

RUN DEBIAN_FRONTEND=noninteractive apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get -y install \
    libamd-comgr2 libamdhip64-5 libbsd0 libc6 libc6-dev libdrm2 libdrm-amdgpu1 libedit2 libelf1t64 \
    libffi8 libfmt10 libgcc-s1 libgomp1 libhipblas0 libhsakmt1 libhsa-runtime64-1 libicu72 \
    libllvm17t64 liblzma5 libmd0 libnuma1 librocblas0 librocsolver0 libstdc++6 libtinfo6 libxml2 \
    libz3-4 libzstd1 llvm-17-dev zlib1g

ENTRYPOINT [ "/app/llama-swap", "--config", "/config.yaml" ]
