# Flutter import complete

This marker is authoritative only when all of the following are true:

1. this file exists on `main`;
2. `pubspec.yaml` and `lib/main.dart` exist on `main`;
3. `IMPORT_STATUS.md` contains `Conclusion: success`;
4. the latest `Flutter CI` run for the containing `main` commit succeeds;
5. temporary bootstrap chunks, trigger files, heartbeat artifacts, and one-shot restoration workflows are absent.

The import replaces the staged source archive with the tracked Flutter source tree, native Android/iOS bridges, tests, product documentation, and normal read-only CI. Platform compilation coverage is recorded in `IMPORT_STATUS.md`.
