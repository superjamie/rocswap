# rocswap - llama.cpp + ROCm + llama-swap

A Linux container which builds llama.cpp with ROCm support, and uses llama-swap to serve models.

## Contents

I just put this together from other people's work listed below.

Comment from u/Slavik81 that Debian Bookworm Backports kernel contains ROCm kernel interface, and Debian Trixie contains the userspace:

- https://www.reddit.com/r/debian/comments/1hcve14/comment/m1s3xmz/

Instructions on Debian AI list to compile llama.cpp with ROCm:

- https://lists.debian.org/debian-ai/2024/07/msg00002.html

llama.cpp - efficient CPU and GPU inference server:

- https://github.com/ggerganov/llama.cpp

llama-swap - OpenAI-compatible server to serve models and swap/proxy inference servers:

- https://github.com/mostlygeek/llama-swap

## Instructions

Build container:

```
podman build . -t rocswap
```

Deploy container:

```
podman run -dit -p 8080:8080 --name rocswap \
  -v ./models:/models \
  -v ./config.yaml:/config.yaml \
  --device /dev/dri --device /dev/kfd \
  --group-add keep-groups \
  --user 1000:1000 \
  rocswap
```

## License

- [Creative Commons Zero 1.0 Universal](https://creativecommons.org/publicdomain/zero/1.0/)
