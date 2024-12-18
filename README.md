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

## Requirements

Linux with the `amdgpu` driver ROCm interface enabled. Debian Bookworm Backports and Debian Trixie/Sid come with this already done. Maybe Ubuntu 24.04 (let me know?). For other distros you might need to use the `amdgpu-install` script from the AMD website.

If using Debian, make sure your GPU is on the [supported GPU list](https://salsa.debian.org/rocm-team/community/team-project/-/wikis/Supported-GPU-list) in Trixie/Sid. The Bookworm Backports kernel has the same support level as Trixie.

Add your user to the `video` and `render` groups on your system: `usermod -aG video,render "$USER"`. Log out and log in again. Confirm with the `groups` command.

## Instructions

Look up your GPU in the [LLVM amdgpu targets](https://llvm.org/docs/AMDGPUUsage.html#processors) and replace my `gfx1010` in the `Containerfile` with your GPU's architecture name.

Build the container:

```
podman build . -t rocswap
```

Deploy the container:

```
podman run -dit -p 8080:8080 --name rocswap \
  -v ./models:/models \
  -v ./config.yaml:/config.yaml \
  --device /dev/dri --device /dev/kfd \
  --group-add keep-groups \
  --user 1000:1000 \
  rocswap
```

If you have models which are smaller than your VRAM (minus about 1 GiB for other allocations) then you can keep `-ngl 99` in the server config to load all layers on the GPU.

However, if you are running a model larger than your GPU's VRAM, then use the llama-swap llama.cpp log output (<http://localhost:8080/logs>) and the `radeontop` commandline program to load as many layers as you can with the llama.cpp `-ngl` option without overflowing VRAM. The other layers will run on the CPU.

For example, I have a Radeon RX 5600 XT 6Gb. I can load all of small models like Gemma-2-2B-It or Phi-3.5-mini-instruct (4B) on the GPU. To load a larger model like Llama-3.1-8B-Q6KL, I can only load 24 layers of the model's 33 layers so I use `-ngl 24`.

## License

- [Creative Commons Zero 1.0 Universal](https://creativecommons.org/publicdomain/zero/1.0/)
