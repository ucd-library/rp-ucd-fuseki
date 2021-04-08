#! /bin/bash

repo=$(basename -s .git $(git config --get remote.origin.url))
branch=$(git rev-parse --abbrev-ref HEAD)

tag=$(git tag --points-at HEAD)

if [[ -n $tag ]]; then
  t_tag="-t ucdlib/${repo}:$tag"
fi

export DOCKER_BUILDKIT=1
docker build \
  --build-arg BUILDKIT_INLINE_CACHE=1 \
  -t ucdlib/${repo}:$branch ${t_tag}\
  $(git rev-parse --show-toplevel)
