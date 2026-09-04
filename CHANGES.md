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

## NEXT step

**Build Solver Mode View & Priority Feed** — municipal/solver inbox with severity ranking, claim/assign actions, and a priority-sorted problem list. After that: FastAPI `POST /reports` multipart (image + audio + title + lat/lng), Bhashini STT, and YOLO on the captured still.
