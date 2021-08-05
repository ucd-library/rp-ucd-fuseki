#! /bin/bash

repo=$(basename -s .git $(git config --get remote.origin.url))
branch=$(git rev-parse --abbrev-ref HEAD)

tag=$(git tag --points-at HEAD)

export DOCKER_BUILDKIT=1
docker build \
  --build-arg BUILDKIT_INLINE_CACHE=1 \
  -t local-dev/${repo} -t local-dev/${repo}:${branch}\
  $(git rev-parse --show-toplevel)
