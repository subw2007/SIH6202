# CivicPulse Backend API Design

## Media and location contract

Flutter captures GPS, reverse-geocodes it, and lets the citizen edit the
resulting `location_name`. Media is uploaded first through `POST /api/upload`
and the returned local URL is sent with the report. The gateway persists and
returns `location_name`, `image_url`, `video_url`, and `audio_url` on citizen
feed, report, solver queue, and status responses.

### `POST /api/upload`

Accepts a multipart `file` field, stores it locally with `multer`, and returns
`{ "url": "/uploads/<filename>", "mime_type": "..." }`.

The mobile contract requires a runtime audio permission check before recording;
failures are presented as a snackbar. Camera media uses the picker-provided
local `XFile.path` for preview and upload rather than a mock asset.

The recorder writes to an absolute file path under
`getTemporaryDirectory()`, supplied by `path_provider`, before multipart
upload. This keeps local audio capture compatible with Android storage rules.

Video uploads use the multipart `file` field. For `video/mp4` and
`video/quicktime`, the gateway responds with `video_url: "/uploads/<filename>"`;
the Flutter client stores that URL in the report `video_url` field.

## Base URL

The mobile client targets `http://localhost:5001/api`. The gateway enables
CORS for all origins for local development.

## Gateway Endpoints

### `GET /api/citizen-feed`

Returns persisted reports ordered newest first.

Response `200 OK`:

```json
[
  {
    "id": "uuid",
    "title": "Broken streetlight",
    "description": "The light is out near the park.",
    "category": "lighting",
    "latitude": 12.34,
    "longitude": 56.78,
    "priority": "low",
    "ai_metadata": {
      "severity": "low",
      "score": 0.3,
      "category": "lighting",
      "model": "rule-based-v1"
    },
    "created_at": "2026-09-05T14:51:37.873Z"
  }
]
```

### `POST /api/reports`

Accepts JSON from the Flutter report composer. The current client sends
`title`, `location`, `has_image`, `image_source`, `audio_path`, and
`audio_duration_ms`; the gateway also accepts the persistence fields
`description`, `category`, `latitude`, and `longitude` when supplied.

The gateway calls the ML engine before writing the record.

Response `201 Created`: the newly persisted report, including `priority` and
the parsed `ai_metadata` object.

### `GET /api/solver-tasks`

Returns the report queue used by Solver Mode:

```json
{
  "success": true,
  "data": [
    {
      "id": "uuid",
      "title": "Broken streetlight",
      "description": "The light is out near the park.",
      "category": "lighting",
      "latitude": 12.34,
      "longitude": 56.78,
      "priority": "low",
      "created_at": "2026-09-05T14:51:37.873Z",
      "status": "PENDING"
    }
  ]
}
```

Response `200 OK`. Legacy rows without a status are returned as `PENDING`.

### `PATCH /api/solver-tasks/:id/status`

Request body:

```json
{"status":"IN_PROGRESS"}
```

Allowed statuses are `PENDING`, `IN_PROGRESS`, and `RESOLVED`. The response is
the updated task with `200 OK`; an unknown task returns `404`, and an invalid
status returns `400`.

## ML Engine Endpoints

### `GET /health`

Returns:

```json
{"status":"ok","service":"python-ml"}
```

### `POST /analyze-report`

Accepts `title`, `description`, `category`, and optional `image_data`. Extra
Flutter fields are tolerated by the current Pydantic model. The response
contains `severity`, `score`, normalized category, input signals, and model
name. Emergency-oriented categories receive high severity; an image or long
description receives medium severity; other reports receive low severity.

## Error Handling

- Gateway `502`: the ML engine is unavailable or rejects the analysis request,
  or the combined report cannot be saved.
- Gateway `500`: the citizen feed query fails.
- Flutter logs successful requests as `[API SUCCESS]` and failures as
  `[API ERROR]`, then exposes a retry action when the initial feed request
  fails.
- All SQLite writes use bound parameters. Report metadata is JSON encoded at
  write time and decoded at response time.

## Flutter State Integration

`CitizenFeedProvider` owns loading, error, and report-list state at app scope.
`CitizenView` triggers its first fetch with `addPostFrameCallback`, renders a
progress indicator while loading, and offers retry on failure.

`ReportFormProvider` remains route-scoped for draft state. Its `submit()`
method calls `ApiService.submitReport()` and awaits the feed provider callback
before reporting success, so returning to the citizen view shows the newly
persisted report.

`SolverProvider` is app-scoped beside the mode provider. It calls
`fetchSolverTasks()` on initialization, exposes loading and error state, and
re-fetches on pull-to-refresh. `updateStatus()` calls the PATCH endpoint and
updates the matching `SolverTask` only after a successful response. Switching
from Citizen Mode to Solver Mode uses the same gateway database, so a newly
submitted report appears in the queue after refresh.
