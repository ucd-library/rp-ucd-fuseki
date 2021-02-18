#! /bin/bash

# manually setting this... for now :(
TAG_NAME=1.2.1

ROOT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd $ROOT_DIR/..

gcloud config set project digital-ucdavis-edu

echo "Submitting build to Google Cloud..."
gcloud builds submit \
  --config ./cloudbuild.yaml \
  --substitutions=REPO_NAME=rp-ucd-fuseki,TAG_NAME=$TAG_NAME,BRANCH_NAME=$(git rev-parse --abbrev-ref HEAD),SHORT_SHA=$(git log -1 --pretty=%h) \
  .
