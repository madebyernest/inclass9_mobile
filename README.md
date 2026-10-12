# In-Class 08 / Fall Festival Roster

**Student / course / pathway:** Ernest Fistik / Mobile App Development (CSC4360) / Undergraduate

**Flutter / Dart versions; device / OS:** Flutter 3.47.4 / Google Pixel 8

**Setup/run commands:** `flutter pub get` → `flutter run`

## Storage notes

* **Schema and initialization:** `my_table`: `_id INTEGER PRIMARY KEY`, `name TEXT NOT NULL`, `age INTEGER NOT NULL` (`MyDatabase.db`, version 1). The database is opened/initialized when the app starts.
* **Input policy, IDs, CRUD source locations:** Names must be trimmed and non-empty. Ages must be whole numbers from 0–130. SQLite generates unique IDs. CRUD operations use the database helper methods for insert, query, update, and delete.
* **Memory example / preference example / SQLite example:** The roster records are stored in SQLite, so they remain after the app is stopped and relaunched.

## Actual tests

| Test | Action/input                          | Expected                                         | Observed IDs/ages/count                                                       | Pass/fail |
| ---- | ------------------------------------- | ------------------------------------------------ | ----------------------------------------------------------------------------- | --------- |
| T1   | Refresh empty roster                  | Count 0, empty message                           | 0 rows; count 0; empty-state message shown                                    | PASS      |
| T2   | Add River 21, River 34                | Count 2, distinct IDs                            | A=1, B=2; count 2                                                             | PASS      |
| T3   | Edit B to 99, Cancel; edit B, Save 35 | Cancel: B=34. Save: 1 row, count 2, A=21, B=35   | Cancel left B=34; Save returned 1; count 2; A=21, B=35                        | PASS      |
| T4   | Stop and relaunch, data kept          | Same IDs/values/count                            | A=1 River 21; B=2 River 35; count 2                                           | PASS      |
| T5   | Cancel delete A; confirm; Refresh     | Cancel: count 2. Confirm: 1 row; only B, count 1 | Cancel left count 2; confirm returned 1; after Refresh only B (ID 2), count 1 | PASS      |
| T6   | Name `   `, age 21                    | Rejected, count 1                                | Rejected with feedback; count stayed 1; B unchanged                           | PASS      |
| T6   | Maple, `abc`                          | Rejected, count 1                                | Rejected with feedback; count stayed 1; B unchanged                           | PASS      |
| T6   | Maple, `1.5`                          | Rejected, count 1                                | Rejected with feedback; count stayed 1; B unchanged                           | PASS      |
| T6   | Maple, `-1`                           | Rejected, count 1                                | Rejected with feedback; count stayed 1; B unchanged                           | PASS      |
| T6   | Maple, `131`                          | Rejected, count 1                                | Rejected with feedback; count stayed 1; B unchanged                           | PASS      |
| T6   | Acorn, 0                              | Accepted, new ID                                 | ID 3; count 2                                                                 | PASS      |
| T6   | Oak, 130                              | Accepted, new ID, final count 3                  | ID 4; count 3                                                                 | PASS      |

**T4 stop/relaunch method:** Android emulator-5554. I stopped the Flutter debug session, opened the lab app's system App info, selected **Force stop** without clearing storage, and reopened the app from the launcher icon. The app was not uninstalled and the app identifier was not changed.

**Evidence:** `evidence/T4_before.png`, `evidence/T4_after.png`, `evidence/T6_invalid.png`, `evidence/analysis_output.txt`

**Analyzer command/result; known limitations:**
PS C:\Users\ernest\Documents\Mobile App Development (CSC4360)\ICW\INW_08\inc8> flutter analyze
Analyzing inc8...                                                       
No issues found! (ran in 3.4s)
PS C:\Users\ernest\Documents\Mobile App Development (CSC4360)\ICW\INW_08\inc8> 

## Short reflections

**1. Prediction (written BEFORE T4), then actual result/interpretation:**
I predicted that the two River records would remain after a full restart because they are stored in the SQLite database. After restarting, both records remained with the same IDs and values, confirming that persistence works.

**2. My two IDs and update result; why identity matters:**
The two River records had IDs 1 and 2. Editing by ID changed only the intended record. IDs matter because two records can have the same name while still being separate database records.

**3. My self-walkthrough observation and proposed improvement:**
I tested creating, editing, cancelling, deleting, restarting, and entering invalid values. The validation prevented bad input while allowing ages 0 and 130. I would improve the app by making validation messages more specific, such as “Age must be a whole number from 0 to 130.”

## Attribution

**Starter source / references / AI assistance used:** Starter lab source and course materials. AI assistance was used for code/help as applicable. testing, observations, and reflections were completed by me.
