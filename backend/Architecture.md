# CivicPulse Backend Architecture

## Local media storage

The Node gateway stores uploaded image, video, and audio files on disk in
`node-gateway/uploads/` using `multer`. Static files are available at
`http://localhost:5001/uploads/<filename>`. SQLite report records store the
corresponding URLs alongside reverse-geocoded `location_name` text.

The mobile client checks runtime microphone permission before recording and
reports denied access in the composer UI. Camera captures use the picker
`XFile.path`, then follow the multipart gateway upload path.

Audio recording uses Flutter `path_provider` to resolve an absolute temporary
directory before the file is uploaded to the gateway, avoiding Android EROFS
failures from relative or read-only working paths.

The same `multer` endpoint accepts video files, preserves their `.mp4` or
`.mov` extension in local storage, and returns both the generic upload URL and
`video_url` when the MIME type starts with `video/`.

## Services

The backend is a local two-service system:

| Service | Runtime | Address | Responsibility |
| --- | --- | --- | --- |
| Node Gateway | Express | `http://127.0.0.1:5001` | Public mobile API, SQLite persistence, CORS |
| Python ML Engine | FastAPI/Uvicorn | `http://127.0.0.1:8000` | Report severity and analysis metadata |

The Flutter client uses `http://localhost:5001/api` by default. Override it at
build time with `--dart-define=API_BASE_URL=<url>`.

## Storage

The gateway creates `node-gateway/data/civicpulse.db` on startup and ensures
the `reports` table exists:

```sql
CREATE TABLE reports (
  id TEXT PRIMARY KEY,
  title TEXT,
  description TEXT,
  category TEXT,
  latitude REAL,
  longitude REAL,
   location_name TEXT,
   image_url TEXT,
   video_url TEXT,
   audio_url TEXT,
  priority TEXT,
  ai_metadata TEXT,
   created_at TEXT,
   status TEXT DEFAULT 'PENDING'
);
```

`ai_metadata` is stored as JSON text in SQLite and decoded back into an object
in gateway responses. The local database file is runtime data and is ignored
by the backend Git ignore rules.

## Report Lifecycle

1. Flutter sends a report to `POST /api/reports` on the Node gateway.
2. The gateway forwards the JSON body to
   `http://127.0.0.1:8000/analyze-report`.
3. The ML engine calculates `severity`, a numeric `score`, normalized
   category, and diagnostic signals.
4. The gateway sets `priority` from the returned severity, creates an ID and
   UTC timestamp, then inserts the combined record using a parameterized
   SQLite statement.
5. The gateway returns the inserted record with parsed AI metadata.
6. Flutter refreshes its app-scoped citizen feed after a successful submit.

The feed path queries SQLite with `ORDER BY created_at DESC`, decodes metadata,
and returns the newest reports first.

## Solver Queue Lifecycle

`GET /api/solver-tasks` reads the report columns needed by Solver Mode and
maps them to task records. It returns the persisted status, defaulting legacy
rows to `PENDING`. The gateway orders tasks newest first and wraps the result
in `{ "success": true, "data": [...] }`.

`PATCH /api/solver-tasks/:id/status` accepts one of `PENDING`, `IN_PROGRESS`,
or `RESOLVED`, updates the matching SQLite row, and returns the updated task.
The gateway applies a startup migration so databases created before solver
status support receive the new `status` column automatically.

Citizen submissions insert `PENDING` rows into the same table. Solver Mode
therefore sees a newly submitted citizen report after its next initial fetch
or pull-to-refresh.

## Development Commands

From `backend/node-gateway`:

```sh
npm start
```

From `backend/python-ml`:

```sh
source venv/bin/activate
uvicorn main:app --host 127.0.0.1 --port 8000
```
