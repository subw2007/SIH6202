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
    └── widgets/
        ├── citizen_problem_card.dart
        ├── audio_player_pill.dart
        ├── media_picker_box.dart      # Photo well
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
                 └─ isCitizenMode == false → _OfficialPlaceholder

CitizenView
  watch UserModeProvider.username  → header
  settings → setCitizenMode
  banner / FAB → openReportProblem()
```

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

## Integration seams (not implemented)

- `POST /reports` multipart: image bytes, audio file, title, lat/lng
- `image_picker` + camera permission; `record` / Bhashini STT
- YOLO on the captured still before upload
- Solver Mode view & priority feed (next sprint)
- Auth token; Official inbox under `lib/views/official/`
