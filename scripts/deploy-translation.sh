#!/bin/bash
# Deploys the app's server side of document translation: Cloud Functions (all of them,
# Node.js 22) and the Firestore + Storage security rules in this repository.
# Run in Cloud Shell from the repository folder:   scripts/deploy-translation.sh
#
# Before it, once: the translation job exists (isp-doc-translate: deploy/setup.sh,
# deploy/release.sh) and config/translation is published (deploy/publish-config.sh).
#
# Identity isp-functions (no key file): what requestTranslation runs as. It may
# read/write Firestore and start the translation job, nothing else.
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
echo "isp-functions: Firestore + may start job $JOB"

say "function tests"
(cd functions && npm ci --no-audit --no-fund >/dev/null && npm test 2>&1 | grep -E "^# (tests|pass|fail)")

say "Firebase sign-in"
if ! npx -y "$FIREBASE_TOOLS" projects:list >/dev/null 2>&1; then
  echo "Sign in to the Firebase CLI once (open the link, sign in, paste the code back):"
  npx -y "$FIREBASE_TOOLS" login --no-localhost
fi

say "deploy functions + rules (~5 min)"
npx -y "$FIREBASE_TOOLS" deploy --project "$PROJECT" --only functions,firestore:rules,storage

say "done. Try it in the app: Home -> Documents"
