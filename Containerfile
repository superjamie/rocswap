FROM docker.io/library/debian:trixie-slim AS build

WORKDIR /git

RUN DEBIAN_FRONTEND=noninteractive apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get -y install \
    build-essential cmake curl git hipcc libhipblas-dev librocblas-dev wget && \
    git clone https://github.com/ggerganov/llama.cpp /git && \
    mkdir -p /app && \
    HIPCXX=clang-17 cmake -H. -B/app \
    -DGGML_HIP=ON -DAMDGPU_TARGETS="gfx1010" \
    -DGGML_NATIVE=OFF -DBUILD_SHARED_LIBS=OFF \
    -DCMAKE_BUILD_TYPE=Release && \
    make -j $(nproc) -C /app llama-server && \
    wget https://github.com/mostlygeek/llama-swap/releases/download/v80/llama-swap_80_linux_amd64.tar.gz && \
    tar xf llama-swap_80_linux_amd64.tar.gz

FROM docker.io/library/debian:trixie-slim AS runtime

WORKDIR /app

COPY --from=build /git/llama-swap /app/
COPY --from=build /app/bin/llama-server /app/

# for LIB in $(ldd llama-server | cut -d' ' -f3); do dpkg -S "$(basename $LIB)"; done | cut -d':' -f1 | sort | uniq
RUN DEBIAN_FRONTEND=noninteractive apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get -y install \
    libamd-comgr2 libamdhip64-5 libbrotli1 libbsd0 libc6 libc6-dev libcom-err2 libcurl4t64 libdrm2 \
    libdrm-amdgpu1 libedit2 libelf1t64 libffi8 libfmt10 libgcc-s1 libgmp10 libgnutls30t64 libgomp1 \
    libgssapi-krb5-2 libhipblas0 libhogweed6t64 libhsakmt1 libhsa-runtime64-1 libicu72 libidn2-0 \
    libk5crypto3 libkeyutils1 libkrb5-3 libkrb5support0 libldap-2.5-0 libllvm17t64 liblzma5 libmd0 \
    libnettle8t64 libnghttp2-14 libnuma1 libp11-kit0 libpsl5t64 librocblas0 librocsolver0 librtmp1 \
    libsasl2-2 libssh2-1t64 libssl3t64 libstdc++6 libtasn1-6 libtinfo6 libunistring5 libxml2 \
    libz3-4 libzstd1 llvm-17-dev zlib1g

ENTRYPOINT [ "/app/llama-swap", "--config", "/config.yaml" ]
