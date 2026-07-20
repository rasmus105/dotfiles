#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
image="dotfiles-test:ubuntu"
platform="linux/amd64"

docker build --platform "$platform" --tag "$image" "$repo_dir"
docker run --platform "$platform" --rm "$image"
