#! /bin/bash

TAG_NAME=jena-3.15.0-c-0.0.3

ROOT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd $ROOT_DIR/..

export DOCKER_BUILDKIT=1
docker build \
  --build-arg BUILDKIT_INLINE_CACHE=1 \
  -t ucdlib/rp-ucd-fuseki:$TAG_NAME \
  .