# Architecture — Citizen UI (mobile)

## Directory map (`app/mobile/lib/`)

```
app/mobile/lib/
├── main.dart                          # UserModeProvider + MaterialApp + view switcher
├── providers/
│   ├── user_mode_provider.dart        # isCitizenMode, username
│   └── report_form_provider.dart      # report composer (route-scoped)
└── views/
    ├── citizen_view.dart              # Feed; opens report via openReportProblem()
    ├── report_problem_screen.dart     # Full-screen report modal
    ├── solver_view.dart               # Official issue feed and team actions
    ├── join_team_view.dart            # Active teams for a selected issue
    ├── create_team_view.dart          # New solver team registration form
    └── widgets/
        ├── citizen_problem_card.dart
        ├── audio_player_pill.dart
        ├── media_picker_box.dart      # Photo well
        ├── settings_bottom_sheet.dart # Shared Citizen/Solver settings and mode sheet
        └── voice_recorder_widget.dart # Mic + waveform
```

Tests: `app/mobile/test/widget_test.dart`. Package name: `mobile`.

## State flow (mode + feed)

```
main()
  └─ ChangeNotifierProvider<UserModeProvider>
       └─ CivicPulseApp (MaterialApp)
            └─ _RootSwitcher
                 ├─ isCitizenMode == true  → CitizenView
                 └─ isCitizenMode == false → SolverView

CitizenView
  watch UserModeProvider.username  → header
  settings → SettingsBottomSheet
  banner / FAB → openReportProblem()

SolverView
  settings → SettingsBottomSheet
  Join Team → Navigator.push → JoinTeamView(task)
  Work on This → Navigator.push → CreateTeamView(task)

JoinTeamView
  Request to Join → mock request snackbar

CreateTeamView
  valid form → Navigator.pop(true)
  SolverView receives result → updates task status and shows success snackbar

SettingsBottomSheet
  watch UserModeProvider.isCitizenMode
    → Account / Citizen Profile ("Registered Citizen")
    → Account / Officer Profile ("Officer ID: SOL-2024-001")
  mode tile → shared showModeToggleSheet
```

`SettingsBottomSheet` is opened by both view headers through the same
scrollable, safe-area-aware modal route. Its account tile reflects the active
mode, while mode switching continues to mutate the shared `UserModeProvider`.

Audio play on **feed cards** stays inside `AudioPlayerPill`. Upvotes remain stubbed.

## Report creation workflow

```
openReportProblem(context)
  Navigator.push fullscreenDialog
    ChangeNotifierProvider(
      create: ReportFormProvider()..startLocationDetection()
      child: ReportProblemScreen
    )

startLocationDetection
  locationState = detecting  ("Detecting Location...")
  after 900ms → ready ("Main St, Sector 4")

MediaPickerBox
  sheet: camera | gallery
    → pickImage(source)  { hasImage = true }

VoiceRecorderWidget
  idle --tap/hold--> recording (periodic 200ms, cap 60s)
  recording --release/tap--> recorded (if elapsed ≥ 400ms)
  recorded → Play / Pause | Re-record | Delete

Submit
  canSubmit = title.trim ≠ "" OR hasImage OR hasVoiceNote
  submit() delay 450ms → submitted
    AlertDialog "Report Submitted Successfully!"
      Back to feed → pop dialog → pop report route → CitizenView
```

`ReportFormProvider` is **not** app-global. Each open creates a fresh instance so drafts do not leak between visits.

## `ReportFormProvider` payload (`toPayload()`)

```json
{
  "title": "Deep pothole on Main St",
  "location": "Main St, Sector 4",
  "has_image": true,
  "image_source": "camera",
  "audio_path": "mock://voice_1710000000000.m4a",
  "audio_duration_ms": 15200
}
```

| Field | Type | Notes |
| --- | --- | --- |
| `title` | string | From “What is the issue?” |
| `location` | string | Mock GPS label until geocoder exists |
| `has_image` | bool | Preview is painted, not a real file |
| `image_source` | `camera` \| `gallery` \| null | Chosen in the source sheet |
| `audio_path` | string \| null | Mock URI; replace with device file path |
| `audio_duration_ms` | int | Elapsed while `voicePhase == recording` |

## Mock feed payload

`citizenFeedMock` in `citizen_view.dart` (`CitizenProblemPost.toMockJson()`):

```json
{
  "id": "rpt_001",
  "title": "Deep pothole causing accidents",
  "location": "Location",
  "time_ago": "2h ago",
  "upvote_count": 14,
  "audio_duration": "0:20",
  "is_verified": true,
  "image_url": null
}
```

Submitted reports are **not** appended to the feed in this sprint (no API).

## Solver Mode extension

`UserModeProvider.isCitizenMode == true` renders the existing `CitizenView`;
`false` renders `SolverView`. Both are children of the same `MultiProvider`
root, so the Citizen settings sheet and Solver settings action mutate the same
mode state. `SolverProvider` is app-scoped beside the mode provider and owns
the official feed independently of report-composer drafts.

The Solver component tree is:

```
SolverView
├── category filter chips
├── feed metrics header
└── SolverTaskCard*
    ├── PriorityBadge
    ├── thumbnail
    ├── category/title metadata
    ├── distance/team metadata
    └── status/join/work actions
```

`SolverProvider` owns the selected `SolverCategory`, visible category-filtered
tasks, and high-priority count. Each `SolverTaskCard` receives callbacks for
joining a team and creating a team; it does not own feed state. The card no
longer renders an upvote counter or details eye action.

Official task schema:

```json
{
  "id": "rpt_001",
  "title": "Deep pothole causing accidents",
  "timestamp": "2h ago",
  "location": "Sector 4, Main St",
  "distance": "1.2 km",
  "upvotes": 148,
  "team_count": 3,
  "priority": "high",
  "status": "pending",
  "category": "infrastructure",
  "description": "Large road damage is disrupting traffic."
}
```

Official actions navigate to the team selection and team creation routes.
Successful team creation updates `SolverProvider.updateStatus(taskId, status)`;
category and metric values are derived from the same task collection rather
than duplicated state.

## Integration seams (not implemented)

- `POST /reports` multipart: image bytes, audio file, title, lat/lng
- `image_picker` + camera permission; `record` / Bhashini STT
- YOLO on the captured still before upload
- Persist Solver category, details, team membership, and work status through
  the FastAPI backend
- Auth token; Official inbox under `lib/views/official/`
