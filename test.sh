#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
image="dotfiles-test:ubuntu"

docker build --tag "$image" "$repo_dir"
docker run --rm "$image"
