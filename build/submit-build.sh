#! /bin/bash

repo=$(basename -s .git $(git config --get remote.origin.url))
branch=$(git rev-parse --abbrev-ref HEAD)
tag=$(git tag --points-at HEAD)
base=$(git rev-parse --show-toplevel)

gcloud config set project digital-ucdavis-edu
USER=$(gcloud auth list --filter="-status:ACTIVE"  --format="value(account)")

if [[ -n $tag ]]; then
  echo "Submitting build to Google Cloud..."

  gcloud builds submit \
    --config $base/cloudbuild.yaml \
    --substitutions=_UCD_LIB_INITIATOR=$USER,REPO_NAME=${repo},TAG_NAME=$tag,BRANCH_NAME=$branch,SHORT_SHA=$(git log -1 --pretty=%h) \
  $base
else
  echo "There is no tag on the current HEAD. Do you really want to cloud build?"
fi
