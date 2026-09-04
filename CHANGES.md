# CHANGES

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

## NEXT step

**Build Solver Mode View & Priority Feed** — municipal/solver inbox with severity ranking, claim/assign actions, and a priority-sorted problem list. After that: FastAPI `POST /reports` multipart (image + audio + title + lat/lng), Bhashini STT, and YOLO on the captured still.
