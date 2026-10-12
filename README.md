# In-Class Activity 09

**Name:** Ernest Fistik  
**Student ID:** 002832382

**Pathway:** Undergraduate (Build & explain)

**Flutter version / target:** 3.47.4 (output of `flutter --version`) / Android (emulator: sdk gphone16k x86 64)

## Summary
Part I's roster app (`my_table`) was extended into a folder/card catalogue. Folders are parents and cards are children linked by `folder_id`. The existing database was upgraded from version 1 to 2 without losing any Part I rows.

## Setup, run, build, test
```
flutter pub get
flutter analyze > evidence/analysis_output.txt
flutter run
flutter build apk --release
```
Release APK: `build/app/outputs/flutter-apk/app-release.apk` submitted as `Activity09_Fistik_Ernest.apk`.

Dependencies: `sqflite`, `path`, `path_provider` (see `pubspec.yaml` and `pubspec.lock`).

Tests T1-T6 are manual (see below). `test/widget_test.dart` is only a placeholder so the analyzer is clean.

## Database
- File `MyDatabase.db` (unchanged), version **1 -> 2**
- Part I table `my_table` was not altered. **Baseline: 2 rows** (ID 1 River/21, ID 2 River/35).
- `onConfigure`: `PRAGMA foreign_keys = ON` (needed for the cascade).
- `onUpgrade`: creates `folders`, `cards` and an index on `cards(folder_id)`, then seeds once.
- `onCreate`: builds the full v2 schema for fresh installs.
- `cards.folder_id` references `folders.id` with **ON DELETE CASCADE**.
- Seed: "Sample Drawer" with one "Ace of Spades" card, inserted once during create/upgrade.
## Code layout
`database_helper.dart` (open/migrate), `folder.dart` + `playing_card.dart` (models), `catalogue_repository.dart` (all SQL, parameterized), `folders_screen.dart` / `cards_screen.dart` / `card_form_screen.dart` (UI), `card_image.dart` (image fallback), `main.dart` (Part I roster + button to the catalogue).
 
## Image reference
Nullable `image_ref` text (asset path or URL). If it is missing or broken, a suit-symbol placeholder shows and the stored value is kept.
 
## Tests
| Test | Observed (real IDs/counts) | Result |
|---|---|---|
| T1 Upgrade preservation | Guests 2, ID 1 River/21, ID 2 River/35 kept; Sample Drawer has 1 card | Pass |
| T2 Parent-child create | Card IDs 2, 3, 4; counts Sample 1, A 2, B 1 | Pass |
| T3 Edit identity | Edited card ID 3; cancel changed nothing | Pass |
| T4 Restart persistence | Same data after force-stop; seed not duplicated | Pass |
| T5 Delete behaviour | Cancel changed nothing; confirmed delete of folder ID 2 removed its cards | Pass |
| T6 Failure & image fallback | Blank title rejected; fallback shown for null/bad refs | Pass |
| Fresh install | Works as expected. | Pass |
| Release APK smoke test | Works as expected. | Pass |
 
## Evidence (`evidence/`)
`T1_before.png`, `T2_cards.png`, `T4_after.png`, `analysis_output.txt`
 
## Known limitations
- Cascade was only tested on disposable folders.
- No image picker; image references are not validated.
- Manual tests only.
 
## Credits / AI use
I used Claude to create this README and guide me through this assignment.
 