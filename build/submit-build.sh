#! /bin/bash

# manually setting this... for now :(
TAG_NAME=jena-3.15.0-c-0.0.3

ROOT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd $ROOT_DIR/..

echo "Submitting build to Google Cloud..."
gcloud builds submit \
  --config ./cloudbuild.yaml \
  --substitutions=REPO_NAME=rp-ucd-fuseki,TAG_NAME=$TAG_NAME,BRANCH_NAME=$(git rev-parse --abbrev-ref HEAD),SHORT_SHA=$(git log -1 --pretty=%h) \
  .