#!/bin/bash
# Lets an account upload documents (uploaders/{uid} in Firestore, written only from here).
# Run in Cloud Shell from the repository folder:
#   scripts/add-uploader.sh someone@example.com          add
#   scripts/add-uploader.sh someone@example.com --remove remove
# The person must have signed in to the app at least once.
set -euo pipefail
PROJECT=ispapp-9f09d
EMAIL="${1:?usage: scripts/add-uploader.sh EMAIL [--remove]}"
TOKEN=$(gcloud auth print-access-token)
H=(-H "Authorization: Bearer $TOKEN" -H "x-goog-user-project: $PROJECT" -H "Content-Type: application/json")

UID_=$(curl -sS -f -X POST "${H[@]}" \
  "https://identitytoolkit.googleapis.com/v1/projects/$PROJECT/accounts:lookup" \
  -d "{\"email\": [\"$EMAIL\"]}" | python3 -c 'import json,sys; u=json.load(sys.stdin).get("users") or []; print(u[0]["localId"] if u else "")')
if [ -z "$UID_" ]; then echo "no account with $EMAIL (sign in to the app once first)"; exit 1; fi

DOC="https://firestore.googleapis.com/v1/projects/$PROJECT/databases/(default)/documents/uploaders/$UID_"
if [ "${2:-}" = "--remove" ]; then
  curl -sS -f -X DELETE "${H[@]}" "$DOC" >/dev/null
  echo "$EMAIL ($UID_) can no longer upload"
else
  curl -sS -f -X PATCH "${H[@]}" "$DOC" -d "{\"fields\": {\"email\": {\"stringValue\": \"$EMAIL\"}, \"since\": {\"timestampValue\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}}}" >/dev/null
  echo "$EMAIL ($UID_) can upload documents"
fi
