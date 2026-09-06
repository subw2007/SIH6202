# Backend Changes

## Local media and report schema (2026-09-05)

- Added `multer` disk storage under `node-gateway/uploads/` and `POST /api/upload`.
- Served local files at `/uploads/<filename>` for Flutter clients.
- Added SQLite `location_name`, `image_url`, `video_url`, and `audio_url` columns; existing report rows were cleared during migration.
- Citizen feed, report creation, solver queue, and status responses now carry the new fields.
- Documented the Flutter runtime microphone permission guard and real camera path normalization used before uploads.
- Documented Flutter `path_provider` temporary-path resolution for writable audio recording files.
- Extended the local upload contract to return `video_url` for `video/*` MIME types, including `.mp4` and `.mov` files.

## 2026-09-05

- Created the dual local backend layout under `backend/`.
- Added the Express Node gateway on port `5001` with CORS enabled.
- Added the FastAPI ML engine on port `8000` with health and report analysis
  endpoints.
- Added SQLite initialization at `node-gateway/data/civicpulse.db`.
- Added the `reports` table and newest-first citizen feed query.
- Added gateway-to-ML HTTP analysis before report persistence.
- Added the Flutter `ApiService` with configurable `API_BASE_URL`, JSON GET and
  POST methods, and `[API SUCCESS]` / `[API ERROR]` diagnostics.
- Replaced the Flutter citizen mock feed with live provider-backed loading,
  retry, empty, and populated states.
- Connected successful Flutter report submission to the gateway and automatic
  citizen-feed refresh.
- Added `GET /api/solver-tasks` for the official task queue.
- Added `PATCH /api/solver-tasks/:id/status` with validation for `PENDING`,
  `IN_PROGRESS`, and `RESOLVED`.
- Added SQLite status migration and default `PENDING` behavior for legacy
  report rows.
- Replaced Flutter solver mock data with live API loading, pull-to-refresh,
  retry state, and persisted status mutations.
- Documented the Citizen-to-Solver lifecycle through the shared SQLite store.
- Verified the Flutter application with `flutter analyze` and no diagnostics.