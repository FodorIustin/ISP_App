# CLAUDE.md — ISPapp (Flutter + Firebase)

App for the International School Project (ISP): a global platform for teachers.
Plan, decisions and progress live in the ISPapp Claude project (start with the project
instructions; translation: `claude/document-translation-feature.md`).

## Commands

```bash
flutter pub get
flutter run                      # iOS Simulator normally; physical iPhone for auth/presence
flutter analyze
flutter test
cd functions && npm test         # Cloud Functions tests (Node's test runner, no emulator)
scripts/deploy-translation.sh    # in Cloud Shell: functions + Firestore/Storage rules
```

## Conventions

- Targets: iOS and Android only.
- State: Riverpod (`lib/providers/`); navigation: GoRouter (`lib/main.dart`).
- Folders: `lib/screens/ widgets/ services/ models/ providers/`.
- Brand: Royal Blue `#003E6D`, Gold `#F9B625`, Teal `#3EB1C8`, Orange `#DD7D1B`.
- **Ask before adding any package** (Flutter or npm).
- UI first with hardcoded data, then wire to Firebase. Content (lessons) is data, not code.

## Firebase (project ispapp-9f09d, Firestore nam5, functions us-central1)

- **Security rules are versioned here** (`firestore.rules`, `storage.rules`) and deployed
  with the functions. Never edit them in the console (the next deploy overwrites it).
- Functions: Node.js 22 (`firebase.json`; Node 22 is retired for functions 2027-10-31).
  `functions/package-lock.json` is committed.
- Secrets never in the app or git (`scripts/serviceAccountKey.json` is ignored).

## Document translation

The translation engine is a separate repo (`FodorIustin/isp-doc-translate`, Cloud Run
Job `isp-translate`); **never put the Python pipeline in this project**. Here:
- `functions/translation/` + `functions/index.js`: `requestTranslation` (the only way to
  start a translation; the app never writes `translations/`), `publishDocument` /
  `deleteDocument` (uploads: the app puts the file in `uploads/{uid}/`, the function checks
  the uploader list `uploaders/{uid}` and the real file type, then publishes it).
- Uploaders are added with `scripts/add-uploader.sh EMAIL` (server-side list; becomes the
  leader/admin role later). During testing uploads are published at once
  (`documents.js` SETTINGS.initialStatus; `in_review` once approval exists).
- `lib/services/translation_service.dart`, `lib/providers/translation_providers.dart`,
  screens `documents_screen.dart`, `document_translate_screen.dart`,
  `upload_document_screen.dart`.
- Firestore: `documents/{id}` (published documents), `translations/{documentId}__{lang}`
  (status queued → running → ready / needs_review / refused / failed, files, cost),
  `config/translation` (languages offered; published by the engine repo).
- During testing, `needs_review` results are shown labelled "Not yet checked"; before
  real users they must be hidden until an admin approves them.
