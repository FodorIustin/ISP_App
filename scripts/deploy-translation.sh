#!/bin/bash
# Deploys the app's server side of document translation: Cloud Functions (all of them,
# Node.js 22) and the Firestore + Storage security rules in this repository.
# Run in Cloud Shell from the repository folder:   scripts/deploy-translation.sh
#
# Before it, once: the translation job exists (isp-doc-translate: deploy/setup.sh,
# deploy/release.sh) and config/translation is published (deploy/publish-config.sh).
#
# Identity isp-functions (no key file): what the translation and document functions run
# as. It may read/write Firestore and the Firebase bucket and start the translation job.
set -euo pipefail
cd "$(dirname "$0")/.."

PROJECT=ispapp-9f09d
REGION=us-central1
JOB=isp-translate
FN_SA="isp-functions@$PROJECT.iam.gserviceaccount.com"
FIREBASE_TOOLS=firebase-tools@15.33.0          # pinned: the CLI version this was tested with
say() { printf '\n== %s\n' "$*"; }

gcloud config set project "$PROJECT" >/dev/null

say "identity isp-functions"
if ! gcloud iam service-accounts describe "$FN_SA" >/dev/null 2>&1; then
  gcloud iam service-accounts create isp-functions --display-name "ISPapp functions (translation requests)"
  sleep 15
fi
gcloud projects add-iam-policy-binding "$PROJECT" --member "serviceAccount:$FN_SA" \
  --role roles/datastore.user --condition None >/dev/null
gcloud run jobs add-iam-policy-binding "$JOB" --region "$REGION" --member "serviceAccount:$FN_SA" \
  --role roles/run.jobsExecutorWithOverrides >/dev/null
BUCKET="$PROJECT.firebasestorage.app"
gcloud storage buckets add-iam-policy-binding "gs://$BUCKET" --member "serviceAccount:$FN_SA" \
  --role roles/storage.objectAdmin >/dev/null
echo "isp-functions: Firestore, the Firebase bucket, may start job $JOB"

say "abandoned uploads (uploads/) deleted after 1 day"
current=$(gcloud storage buckets describe "gs://$BUCKET" --format="value(lifecycle_config)")
if [ -z "$current" ] || echo "$current" | grep -q "uploads/"; then
  printf '{"rule":[{"action":{"type":"Delete"},"condition":{"age":1,"matchesPrefix":["uploads/"]}}]}' \
    > /tmp/isp-uploads-lifecycle.json
  gcloud storage buckets update "gs://$BUCKET" --lifecycle-file /tmp/isp-uploads-lifecycle.json >/dev/null
  echo "lifecycle rule set"
else
  echo "the bucket already has other lifecycle rules; not changed (add the uploads/ rule by hand)"
fi

say "function tests"
# pass/fail is the test runner's exit code (its text format differs between Node versions)
(cd functions && npm ci --no-audit --no-fund --loglevel=error && npm test --silent)

say "Firebase sign-in"
if ! npx -y "$FIREBASE_TOOLS" projects:list >/dev/null 2>&1; then
  echo "Sign in to the Firebase CLI once (open the link, sign in, paste the code back):"
  npx -y "$FIREBASE_TOOLS" login --no-localhost
fi

say "deploy functions + rules (~5 min)"
npx -y "$FIREBASE_TOOLS" deploy --project "$PROJECT" --only functions,firestore:rules,storage

say "done. Try it in the app: Home -> Documents"
