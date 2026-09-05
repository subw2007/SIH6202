# CHANGES

## Live REST integration (2026-09-05)

- Rebuilt the Express backend around a file-backed JSON store at `backend/data/civicpulse.json` (configurable with `DB_FILE`), preserving seeded data on first boot and all report, task, and user mutations across restarts.
- Changed the Express default port from `5000` to `5001`; the API is available at `http://localhost:5001/api`.
- Added wildcard CORS for all supported REST methods, explicit pre-flight handling, and 50 MB JSON/urlencoded payload limits for image payloads.
- Replaced `citizenFeedMock` and `solverTasksMock` rendering with live provider state loaded from `GET /api/citizen-feed` and `GET /api/solver-tasks`.
- `ReportFormProvider` fetches the citizen feed on provider initialization and refreshes it after a successful `POST /api/reports`, so new reports appear immediately after submission.
- `SolverProvider` starts with an empty task collection and fetches live tasks during initialization; loading, empty, and request-error states are shown by `SolverView`.
- Replaced the custom Flutter `HttpClient` with `package:http`, dynamic `API_BASE_URL` configuration, structured non-2xx errors, and explicit socket/client diagnostics.

## Created files (`app/mobile/lib/`)

### Citizen feed (previous)

| File | Role |
| --- | --- |
| `lib/main.dart` | Root `CivicPulseApp`. Wraps `ChangeNotifierProvider<UserModeProvider>` and switches Citizen vs Official landing views. |
| `lib/providers/user_mode_provider.dart` | View-mode state (`isCitizenMode`) and username. |
| `lib/views/citizen_view.dart` | Citizen feed. Banner + FAB now call `openReportProblem()`. |
| `lib/views/widgets/citizen_problem_card.dart` | Feed card + `CitizenProblemPost` mock model. |
| `lib/views/widgets/audio_player_pill.dart` | Play/pause chip with waveform bars. |

### Report composer (this sprint)

| File | Role |
| --- | --- |
| `lib/providers/report_form_provider.dart` | Local form state: photo, voice, title, GPS pill, submit. Scoped per report route. |
| `lib/views/report_problem_screen.dart` | Full-screen modal: close (X), media, voice, title, location, submit + success dialog. |
| `lib/views/widgets/media_picker_box.dart` | Dashed camera well, source sheet (camera/gallery), preview + Remove / Retake. |
| `lib/views/widgets/voice_recorder_widget.dart` | Large mic, hold-or-tap record, live waveform, timer, Play / Re-record / Delete. |

Also updated: `app/mobile/test/widget_test.dart` (submit-and-return flow).

## `UserModeProvider` state

- `isCitizenMode` (`bool`, default `true`)
- `username` (`String`, default `"Username"`)
- Derived: `modeLabel`
- Mutations: `toggleMode()`, `setCitizenMode(bool)`, `setUsername(String)`

## `ReportFormProvider` state

- `title` (`String`)
- `locationLabel` / `locationState` (`detecting` → mock `"Main St, Sector 4"`)
- `hasImage`, `imageSource` (`camera` \| `gallery`)
- `recordedAudioPath` (mock `mock://voice_<epoch>.m4a`)
- `voicePhase` (`idle` \| `recording` \| `recorded` \| `playing`)
- `voiceElapsed`, `playbackElapsed` (cap `00:60`)
- `isSubmitting`, `submitted`
- Derived: `canSubmit`, `voiceTimerLabel`, `hasVoiceNote`, `toPayload()`
- Mutations: `startLocationDetection()`, `setTitle()`, `pickImage()`, `clearImage()`, `startRecording()`, `stopRecording()`, `deleteRecording()`, `reRecord()`, `togglePlayback()`, `submit()`

Photo and mic are **UI mocks** (no `image_picker` / recorder plugins yet).

## Solver Mode refactor (2026-09-04)

### Modified files

| File | Modification |
| --- | --- |
| `lib/main.dart` | Preserved the original Citizen app shell and connected `SolverView` through the existing `UserModeProvider`/`MultiProvider` root switcher. |
| `lib/providers/user_mode_provider.dart` | Kept the original `isCitizenMode`, username, and mode mutation API so Citizen settings and Solver switching share one state source. |
| `lib/providers/solver_provider.dart` | Added the mutable task collection, active `SolverFilter`, visible-task derivation, status counts, and status mutation state used by the official feed. |
| `lib/views/solver_view.dart` | Refined page background, surface, ink, primary blue, 20px margins, horizontal filter pills, summary cards, 16px feed gaps, and official navigation controls. |
| `lib/views/widgets/solver_task_card.dart` | Refined white 20px cards, 4px priority left border, exact design palette, AI insight wash, and action hierarchy. |
| `lib/views/widgets/priority_badge.dart` | Uses exact Critical/High `#E53935`, Medium `#FB8C00`, and Low `#4CAF50` colors with tinted fills and outlines. |
| `lib/test/widget_test.dart` | Covers the original Citizen-to-Official mode switch and Solver feed contract. |
| `Design.md` | Restored the Citizen design contract and documented the Solver palette/layout extension. |
| `Architecture.md` | Restored the Citizen architecture contract and documented Solver state/data flow. |

### New SolverProvider state

- `_tasks`: mutable in-memory `List<SolverTask>` containing the current official inbox.
- `_filter`: active `SolverFilter`, defaulting to `all`.
- `SolverTask.status`: per-task `pending`, `inProgress`, or `resolved` status.
- `SolverTask.priority`: per-task `critical`, `high`, `medium`, or `low` severity.
- `visibleTasks`: derived list filtered by the active pill.
- `countFor()`: derived count for All, Pending, Urgent, In Progress, and Resolved.
- `countStatus()`: derived summary analytics count.
- `updateStatus()`: mutation used by Assign/Mark In Progress and confirmed Resolve actions.

## Solver Mode wireframe refactor (2026-09-04)

### Modified files

| File | Modification |
| --- | --- |
| `lib/providers/solver_provider.dart` | Replaced status-filter state with `SolverCategory`, category filtering, high-priority count, and expanded task metadata. |
| `lib/views/solver_view.dart` | Rebuilt the header, avatar, category chip row, metrics row, and feed; removed the distance slider/old analytics controls. |
| `lib/views/widgets/solver_task_card.dart` | Rebuilt cards with thumbnail, priority/category metadata, two-line title/description, distance/upvotes/team metadata, status pill, view, Join Team, and Work on This actions. |
| `lib/views/widgets/priority_badge.dart` | Changed to the solid red/orange/green dot priority pill used beside category metadata. |
| `Design.md` | Added the exact Solver wireframe layout, dimensions, and token usage. |
| `Architecture.md` | Updated the dual-view tree, Solver component tree, and official task schema. |
| `app/mobile/test/widget_test.dart` | Updated the integration assertions for the new Solver header, metrics, category filters, and card title. |

### New and changed Solver state

- `SolverCategory _category`: selected category chip, default `all`.
- `SolverTask.distance`: display distance metadata.
- `SolverTask.upvotes`: citizen support count.
- `SolverTask.teamCount`: assigned team count.
- `SolverTask.category`: task category used by filtering and icon labels.
- `SolverTask.description`: two-line card description.
- `SolverProvider.highPriorityCount`: derived high/critical count for the metrics pill.
- `SolverProvider.visibleTasks`: derived category-filtered feed.
- `SolverProvider.setCategory()`: category chip mutation.
- `SolverProvider.updateStatus()`: Work on This status mutation.

## Solver settings sheet refactor (2026-09-04)

### Modified files

| File | Modification |
| --- | --- |
| `lib/views/solver_view.dart` | Refactored the top-right settings gear icon to open a dedicated "Settings & Profile" bottom sheet instead of directly switching mode. The sheet now includes: (1) "Switch Mode (Citizen / Official)" tile that triggers `showModeToggleSheet()`, (2) "Language Selection (Bhashini)" placeholder for English/Hindi/Regional languages, (3) "Notification Preferences" toggle tile, (4) "Account / Officer Profile" tile with officer ID display. Tooltip updated from "Switch to Citizen Space" to "Settings". Added `import` for `Provider` and `citizen_view.showModeToggleSheet()`. |

### UI improvements

- Unified settings access point: All officer profile and preference settings are now consolidated in a single "Settings & Profile" bottom sheet.
- Enhanced mode switching: Mode toggle is now one option among multiple settings rather than the primary action.
- Added language selection placeholder: Prepared for Bhashini integration in the future.
- Added notification preferences control: Officers can now toggle notification settings directly from the settings sheet.
- Added officer profile display: Shows officer ID (mock: "SOL-2024-001") with expandable profile details (TODO).
- Fixed settings sheet bottom overflow by making the modal scrollable, draggable, and safe-area aware.
- Added shared `app/mobile/lib/views/widgets/settings_bottom_sheet.dart` for Citizen and Solver settings, with mode-aware account profile labels.

## Unified header layout (2026-09-04)

- Updated `lib/views/citizen_view.dart` and `lib/views/solver_view.dart` to use matching white header cards with padded content and a soft shadow for contrast against the page background.
- Updated Solver Mode to use the standard light-blue person avatar and the shared username title, with `Solver Mode` retained as the subtitle.

## Solver team flows (2026-09-04)

- Refactored `lib/views/widgets/solver_task_card.dart` to remove the details eye action and upvote metadata, and to display team counts as “X teams”.
- Added `lib/views/join_team_view.dart` with mock college teams, member/lead details, and Request to Join actions.
- Added `lib/views/create_team_view.dart` with validated team registration fields and a Create Team & Start Solver Mode flow.
- Solver card actions now navigate to the team selection or team creation screens.

## NEXT step

**Build Solver Mode View & Priority Feed** — municipal/solver inbox with severity ranking, claim/assign actions, and a priority-sorted problem list. After that: FastAPI `POST /reports` multipart (image + audio + title + lat/lng), Bhashini STT, and YOLO on the captured still.
