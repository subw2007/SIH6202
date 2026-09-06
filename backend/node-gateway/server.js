const cors = require('cors');
const crypto = require('node:crypto');
require('dotenv').config();
const express = require('express');
const fs = require('node:fs');
const path = require('node:path');
const multer = require('multer');
const sqlite3 = require('sqlite3').verbose();
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { categorizeReport, generateReportSummary } = require('./utils/categorizer');

const app = express();
const port = Number(process.env.PORT || 5001);
const pythonMlServiceUrl = process.env.PYTHON_ML_SERVICE_URL;
const dataDirectory = path.join(__dirname, 'data');
const uploadsDirectory = path.join(__dirname, 'uploads');
const databasePath = path.join(dataDirectory, 'civicpulse.db');
const jwtSecret = process.env.JWT_SECRET;

if (!jwtSecret) throw new Error('JWT_SECRET environment variable is required');
if (!pythonMlServiceUrl) throw new Error('PYTHON_ML_SERVICE_URL environment variable is required');

fs.mkdirSync(dataDirectory, { recursive: true });
fs.mkdirSync(uploadsDirectory, { recursive: true });
const database = new sqlite3.Database(databasePath);
const resetRequested = process.argv.includes('--reset');
const allowedCategories = new Set([
  'Roads & Transport',
  'Water & Sewage',
  'Electricity & Lighting',
  'Waste & Sanitation',
  'Public Hazards & Safety',
  'Public Infrastructure',
]);

const databaseReady = new Promise((resolve, reject) => {
  database.serialize(() => {
    database.run(`
      CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        email TEXT UNIQUE,
        password_hash TEXT,
        role TEXT DEFAULT 'citizen',
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    `, (error) => {
      if (error) reject(error);
    });
    database.run(`
      CREATE TABLE IF NOT EXISTS reports (
        id TEXT PRIMARY KEY,
        title TEXT,
        description TEXT,
        description_source TEXT,
        category TEXT,
        severity TEXT,
        status TEXT DEFAULT 'PENDING',
        latitude REAL,
        longitude REAL,
        user_id TEXT,
        location_name TEXT,
        image_url TEXT,
        video_url TEXT,
        audio_url TEXT,
        translated_text TEXT,
        audio_transcript TEXT,
        priority TEXT,
        bundled_reports_count INTEGER DEFAULT 0,
        priority_boost REAL DEFAULT 0,
        ai_metadata TEXT,
        created_at TEXT
      )
    `, (error) => {
      if (error) reject(error);
    });
    database.all('PRAGMA table_info(reports)', async (error, columns) => {
      if (error) {
        reject(error);
        return;
      }
      const existingColumns = new Set(columns.map((column) => column.name));
      const missingColumns = [
        ['description_source', 'TEXT'],
        ['severity', 'TEXT'],
        ['user_id', 'TEXT'],
        ['location_name', 'TEXT'],
        ['image_url', 'TEXT'],
        ['video_url', 'TEXT'],
        ['audio_url', 'TEXT'],
        ['translated_text', 'TEXT'],
        ['audio_transcript', 'TEXT'],
        ['status', "TEXT DEFAULT 'PENDING'"],
        ['bundled_reports_count', 'INTEGER DEFAULT 0'],
        ['priority_boost', 'REAL DEFAULT 0'],
      ].filter(([name]) => !existingColumns.has(name));
      try {
        for (const [name, type] of missingColumns) {
          await runDatabase(`ALTER TABLE reports ADD COLUMN ${name} ${type}`);
        }
        const tableColumns = [
          ['comments', [['user_id', 'TEXT'], ['author_name', 'TEXT']]],
          ['team_members', [['user_id', 'TEXT'], ['role', 'TEXT']]],
        ];
        for (const [table, definitions] of tableColumns) {
          const currentColumns = await new Promise((resolveColumns, rejectColumns) => {
            database.all(`PRAGMA table_info(${table})`, (tableError, tableInfo) => {
              if (tableError) rejectColumns(tableError);
              else resolveColumns(new Set(tableInfo.map((column) => column.name)));
            });
          });
          for (const [name, type] of definitions) {
            if (!currentColumns.has(name)) await runDatabase(`ALTER TABLE ${table} ADD COLUMN ${name} ${type}`);
          }
        }
        if (resetRequested) {
          await runDatabase('BEGIN TRANSACTION');
          try {
            await runDatabase('DELETE FROM reports');
            await runDatabase('DELETE FROM comments');
            await runDatabase('DELETE FROM report_updates');
            await runDatabase('DELETE FROM teams');
            await runDatabase('DELETE FROM team_members');
            await runDatabase('DELETE FROM users');
            await runDatabase('COMMIT');
            console.log(`Reset SQLite database at ${databasePath}`);
          } catch (resetError) {
            await runDatabase('ROLLBACK');
            throw resetError;
          }
        }
        resolve();
      } catch (alterError) {
        reject(alterError);
      }
    });
    database.run(`
      CREATE TABLE IF NOT EXISTS comments (
        id TEXT PRIMARY KEY,
        report_id TEXT,
        user_id TEXT,
        author_name TEXT,
        text TEXT,
        user_name TEXT,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    `, (error) => {
      if (error) reject(error);
    });
    database.run(`
      CREATE TABLE IF NOT EXISTS teams (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        report_id TEXT,
        name TEXT,
        institution TEXT,
        lead_name TEXT,
        contact TEXT,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    `, (error) => {
      if (error) reject(error);
    });
    database.run(`
      CREATE TABLE IF NOT EXISTS team_members (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        team_id INTEGER,
        user_id TEXT,
        role TEXT
      )
    `, (error) => {
      if (error) reject(error);
    });
    database.run(`
      CREATE TABLE IF NOT EXISTS report_updates (
        id TEXT PRIMARY KEY,
        report_id TEXT,
        notes TEXT,
        image_url TEXT,
        video_url TEXT,
        audio_url TEXT,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    `, (error) => {
      if (error) reject(error);
    });
  });
});

const runDatabase = (sql, parameters = []) => new Promise((resolve, reject) => {
  database.run(sql, parameters, function onRun(error) {
    if (error) reject(error);
    else resolve(this);
  });
});

app.use(cors({ origin: '*' }));
app.use(express.json({ limit: '10mb' }));
app.use('/uploads', express.static(uploadsDirectory));

const upload = multer({
  storage: multer.diskStorage({
    destination: uploadsDirectory,
    filename: (_request, file, callback) => {
      const extension = path.extname(file.originalname).toLowerCase();
      callback(null, `${crypto.randomUUID()}${extension}`);
    },
  }),
  limits: { fileSize: 25 * 1024 * 1024 },
});

const run = (sql, parameters = []) => new Promise((resolve, reject) => {
  database.run(sql, parameters, function onRun(error) {
    if (error) reject(error);
    else resolve(this);
  });
});

const all = (sql, parameters = []) => new Promise((resolve, reject) => {
  database.all(sql, parameters, (error, rows) => {
    if (error) reject(error);
    else resolve(rows);
  });
});

const get = (sql, parameters = []) => new Promise((resolve, reject) => {
  database.get(sql, parameters, (error, row) => {
    if (error) reject(error);
    else resolve(row);
  });
});

const parseReport = (report) => ({
  ...report,
  ai_metadata: typeof report.ai_metadata === 'string'
    ? JSON.parse(report.ai_metadata)
    : report.ai_metadata || null,
});

const severityBaseScores = { critical: 50, high: 35, medium: 20, low: 10 };

const calculatePriorityScore = (report, now = Date.now()) => {
  const severity = String(report.priority || report.severity || 'low').toLowerCase();
  const baseScore = severityBaseScores[severity] || severityBaseScores.low;
  const commentsCount = Number(report.comment_count || 0);
  const bundledReportsCount = Number(report.bundled_reports_count || 0);
  const unresolvedHours = Math.max(0, (now - Date.parse(report.created_at)) / 3600000);
  const timeDecay = severity === 'high' || severity === 'critical'
    ? Math.floor(unresolvedHours) * 1.5
    : 0;
  return baseScore + commentsCount * 2 + bundledReportsCount * 5 + timeDecay + Number(report.priority_boost || 0);
};

const priorityScoreSql = `(
  CASE LOWER(COALESCE(reports.priority, 'low'))
    WHEN 'critical' THEN 50
    WHEN 'high' THEN 35
    WHEN 'medium' THEN 20
    ELSE 10
  END
  + (SELECT COUNT(*) FROM comments WHERE comments.report_id = reports.id) * 2
  + COALESCE(reports.bundled_reports_count, 0) * 5
  + CASE WHEN LOWER(COALESCE(reports.priority, 'low')) IN ('high', 'critical')
      THEN CAST(MAX(0, (julianday('now') - julianday(reports.created_at)) * 24) AS INTEGER) * 1.5
      ELSE 0
    END
  + COALESCE(reports.priority_boost, 0)
)`;

const userProfile = (user) => ({
  id: user.id,
  name: user.name,
  email: user.email,
  role: user.role,
});

const signToken = (user) => jwt.sign(userProfile(user), jwtSecret, { expiresIn: '7d' });

const requireAuth = (request, response, next) => {
  const header = request.get('Authorization') || '';
  const token = header.startsWith('Bearer ') ? header.slice(7) : '';
  if (!token) return response.status(401).json({ error: 'Authentication required' });
  try {
    request.user = jwt.verify(token, jwtSecret);
    return next();
  } catch (_) {
    return response.status(401).json({ error: 'Invalid or expired token' });
  }
};

app.post('/api/auth/signup', async (request, response) => {
  const name = String(request.body?.name || '').trim();
  const email = String(request.body?.email || '').trim().toLowerCase();
  const password = String(request.body?.password || '');
  const role = request.body?.role === 'solver' ? 'solver' : 'citizen';
  if (!name || !email || password.length < 6) {
    return response.status(400).json({ error: 'Name, email, and a password of at least 6 characters are required' });
  }
  try {
    await databaseReady;
    const passwordHash = await bcrypt.hash(password, 10);
    const result = await run(
      'INSERT INTO users (name, email, password_hash, role) VALUES (?, ?, ?, ?)',
      [name, email, passwordHash, role],
    );
    const user = await get('SELECT id, name, email, role FROM users WHERE id = ?', [result.lastID]);
    return response.status(201).json({ jwt: signToken(user), user: userProfile(user) });
  } catch (error) {
    if (error.code === 'SQLITE_CONSTRAINT') return response.status(409).json({ error: 'Email is already registered' });
    return response.status(500).json({ error: 'Unable to create account' });
  }
});

app.post('/api/auth/login', async (request, response) => {
  const email = String(request.body?.email || '').trim().toLowerCase();
  const password = String(request.body?.password || '');
  try {
    await databaseReady;
    const user = await get('SELECT * FROM users WHERE email = ?', [email]);
    if (!user || !(await bcrypt.compare(password, user.password_hash))) {
      return response.status(401).json({ error: 'Invalid email or password' });
    }
    return response.json({ jwt: signToken(user), user: userProfile(user) });
  } catch (_) {
    return response.status(500).json({ error: 'Unable to log in' });
  }
});

app.get('/api/auth/me', requireAuth, async (request, response) => {
  try {
    await databaseReady;
    const user = await get('SELECT id, name, email, role FROM users WHERE id = ?', [request.user.id]);
    if (!user) return response.status(401).json({ error: 'User no longer exists' });
    return response.json(userProfile(user));
  } catch (_) {
    return response.status(500).json({ error: 'Unable to load user profile' });
  }
});

app.post('/api/upload', upload.single('file'), async (request, response) => {
  if (!request.file) {
    return response.status(400).json({ error: 'A file field is required' });
  }
  const url = `/uploads/${request.file.filename}`;
  const mediaResponse = {
    url,
    mime_type: request.file.mimetype,
    original_name: request.file.originalname,
  };
  if (request.file.mimetype.startsWith('video/')) mediaResponse.video_url = url;
  return response.status(201).json(mediaResponse);
});

app.post('/api/transcribe', async (request, response) => {
  const audioUrl = String(request.body?.audio_url || '').trim();
  const uploadName = path.basename(audioUrl);
  if (!uploadName) return response.status(400).json({ error: 'audio_url is required' });

  try {
    const transcriptionResponse = await fetch(`${pythonMlServiceUrl}/transcribe-audio`, {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({ audio_path: path.join(uploadsDirectory, uploadName) }),
    });
    if (!transcriptionResponse.ok) {
      return response.status(502).json({ error: 'ML engine rejected the audio' });
    }
    return response.json(await transcriptionResponse.json());
  } catch (_) {
    return response.status(502).json({ error: 'Unable to transcribe audio' });
  }
});

app.get('/api/citizen-feed', async (request, response) => {
  try {
    await databaseReady;
    const reports = await all(`
      SELECT reports.*,
        users.name AS author_name,
        (SELECT COUNT(*) FROM comments WHERE comments.report_id = reports.id) AS comment_count
      FROM reports LEFT JOIN users ON reports.user_id = users.id
      ORDER BY created_at DESC
    `);
    response.json(reports.map(parseReport));
  } catch (error) {
    response.status(500).json({ error: 'Unable to load citizen feed' });
  }
});

app.get('/api/reports', requireAuth, async (request, response) => {
  try {
    await databaseReady;
    const userId = String(request.user.id);
    const { city, category, severity } = request.query;
    const sort = String(request.query.sort || request.query.sort_by || '').toLowerCase();
    const orderBy = sort === 'priority_score'
      ? 'ORDER BY priority_score DESC, created_at DESC'
      : 'ORDER BY created_at DESC';
    const filters = [];
    const parameters = [];
    if (city && city !== 'All') {
      filters.push('LOWER(COALESCE(location_name, \'\')) LIKE LOWER(?)');
      parameters.push(`%${city}%`);
    }
    if (category && category !== 'All') {
      filters.push('category = ?');
      parameters.push(category);
    }
    if (severity && severity !== 'All') {
      filters.push('UPPER(priority) = UPPER(?)');
      parameters.push(severity);
    }
    const whereClause = filters.length ? `WHERE ${filters.join(' AND ')}` : '';
    const reports = await all(`
      SELECT reports.*,
        users.name AS author_name,
        (SELECT COUNT(*) FROM comments WHERE comments.report_id = reports.id) AS comment_count,
        (SELECT COUNT(*) FROM teams WHERE teams.report_id = reports.id) AS team_count,
        ${priorityScoreSql} AS priority_score,
        (SELECT teams.name
         FROM teams INNER JOIN team_members ON team_members.team_id = teams.id
         WHERE teams.report_id = reports.id AND team_members.user_id = ?
         ORDER BY teams.created_at ASC LIMIT 1) AS user_joined_team_name
      FROM reports LEFT JOIN users ON reports.user_id = users.id
      ${whereClause}
      ${orderBy}
    `, [userId, ...parameters]);
    response.json(reports.map(parseReport));
  } catch (error) {
    response.status(500).json({ error: 'Unable to load reports' });
  }
});

app.post('/api/reports', requireAuth, async (request, response) => {
  const report = request.body || {};
  if (!allowedCategories.has(report.category)) {
    return response.status(400).json({
      error: 'Category must be one of the six supported public issue categories',
    });
  }

  try {
    await databaseReady;
    const userId = String(request.user.id);
    const locationName = String(report.location_name || report.location || '').trim() || null;
    const latitude = report.latitude ?? null;
    const longitude = report.longitude ?? null;
    let candidateReports = [];
    if (latitude !== null && longitude !== null) {
      candidateReports = await all(
        `SELECT id, user_id, title, description, category, latitude, longitude,
                status, created_at, bundled_reports_count
         FROM reports
         WHERE latitude IS NOT NULL
           AND longitude IS NOT NULL
           AND COALESCE(UPPER(status), 'PENDING') != 'RESOLVED'
           AND 6371000 * 2 * ASIN(SQRT(
             SIN((RADIANS(latitude) - RADIANS(?)) / 2) *
             SIN((RADIANS(latitude) - RADIANS(?)) / 2) +
             COS(RADIANS(?)) * COS(RADIANS(latitude)) *
             SIN((RADIANS(longitude) - RADIANS(?)) / 2) *
             SIN((RADIANS(longitude) - RADIANS(?)) / 2)
           )) <= 100
         ORDER BY created_at DESC`,
        [latitude, latitude, latitude, longitude, longitude],
      );
    }

    const analysisResponse = await fetch(`${pythonMlServiceUrl}/analyze-report`, {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify(report),
    });

    if (!analysisResponse.ok) {
      return response.status(502).json({ error: 'ML engine rejected the report' });
    }

    const aiMetadata = await analysisResponse.json();
    const analysisSignals = aiMetadata.signals || {};
    const submittedDescription = String(report.description || '').trim();
    const fallbackDescription = String(
      analysisSignals.audio_transcript || analysisSignals.translated_description || '',
    ).trim();
    const description = submittedDescription || fallbackDescription;

    if (candidateReports.length > 0) {
      const evaluationResponse = await fetch(`${pythonMlServiceUrl}/evaluate-duplicate`, {
        method: 'POST',
        headers: { 'content-type': 'application/json' },
        body: JSON.stringify({
          new_submission: {
            title: report.title || '',
            description,
            category: report.category || '',
          },
          candidate_reports: candidateReports,
        }),
      });
      if (!evaluationResponse.ok) {
        return response.status(502).json({ error: 'Duplicate evaluation failed' });
      }
      const evaluation = await evaluationResponse.json();
      const matchedReportId = evaluation?.matched_report_id?.toString() || null;
      const matchedReport = candidateReports.find((candidate) => candidate.id === matchedReportId);
      if (evaluation?.is_duplicate === true && matchedReport) {
        if (String(matchedReport.user_id) === userId) {
          return response.status(409).json({
            error: 'active_report_exists',
            message: 'You already have an active report for this issue.',
            report_id: matchedReport.id,
          });
        }

        await run(
          `UPDATE reports
           SET bundled_reports_count = COALESCE(bundled_reports_count, 0) + 1
           WHERE id = ?`,
          [matchedReport.id],
        );
        return response.status(200).json({
          message: 'Report bundled into existing ticket',
          bundled: true,
          primary_report_id: matchedReport.id,
        });
      }
    }

    const createdAt = new Date().toISOString();
    const record = {
      id: crypto.randomUUID(),
      user_id: userId,
      title: report.title || '',
      description,
      category: report.category,
      latitude: report.latitude ?? null,
      longitude: report.longitude ?? null,
      location_name: report.location_name || report.location || null,
      image_url: report.image_url || null,
      video_url: report.video_url || report.videoUrl || report.video || null,
      audio_url: report.audio_url || null,
      translated_text: analysisSignals.combined_text ||
        analysisSignals.translated_description || null,
      audio_transcript: analysisSignals.audio_transcript || null,
      priority: aiMetadata.severity || 'low',
      ai_metadata: {
        ...aiMetadata,
        description_source: submittedDescription ? 'user' : description ? 'ai' : 'none',
      },
      created_at: createdAt,
      status: 'PENDING',
    };

    await run(
      `INSERT INTO reports
        (id, user_id, title, description, category, latitude, longitude, location_name,
         image_url, video_url, audio_url, translated_text, audio_transcript,
        priority, bundled_reports_count, priority_boost, ai_metadata, created_at, status)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        record.id,
        record.user_id,
        record.title,
        record.description,
        record.category,
        record.latitude,
        record.longitude,
        record.location_name,
        record.image_url,
        record.video_url,
        record.audio_url,
        record.translated_text,
        record.audio_transcript,
        record.priority,
        0,
        0,
        JSON.stringify(record.ai_metadata),
        record.created_at,
        record.status,
      ],
    );

    return response.status(201).json({ ...record, priority_score: calculatePriorityScore(record) });
  } catch (error) {
    return response.status(502).json({ error: 'Unable to analyze or save the report' });
  }
});

app.get('/api/reports/:id', requireAuth, async (request, response) => {
  try {
    await databaseReady;
    const report = await get(
      `SELECT reports.*,
        users.name AS author_name,
        (SELECT COUNT(*) FROM comments WHERE comments.report_id = reports.id) AS comment_count,
        (SELECT COUNT(*) FROM teams WHERE teams.report_id = reports.id) AS team_count,
        (SELECT teams.name
         FROM teams INNER JOIN team_members ON team_members.team_id = teams.id
         WHERE teams.report_id = reports.id AND team_members.user_id = ?
         ORDER BY teams.created_at ASC LIMIT 1) AS user_joined_team_name
       FROM reports LEFT JOIN users ON reports.user_id = users.id
       WHERE reports.id = ?`,
      [String(request.user.id), request.params.id],
    );
    if (!report) return response.status(404).json({ error: 'Report not found' });
    const timeline = await all(
      `SELECT id, report_id, notes, image_url, video_url, audio_url, created_at
       FROM report_updates WHERE report_id = ? ORDER BY created_at ASC`,
      [request.params.id],
    );
    return response.json({ ...parseReport(report), timeline });
  } catch (error) {
    return response.status(500).json({ error: 'Unable to load report' });
  }
});

app.post('/api/reports/categorize', async (request, response) => {
  const { description } = request.body || {};
  if (typeof description !== 'string') {
    return response.status(400).json({ error: 'Description must be a string' });
  }

  return response.json({ category: await categorizeReport(description) });
});

app.post('/api/reports/summarize', async (request, response) => {
  const { rawText } = request.body || {};
  if (typeof rawText !== 'string') {
    return response.status(400).json({ error: 'rawText must be a string' });
  }

  return response.json({ summary: await generateReportSummary(rawText) });
});

app.post('/api/reports/:id/comments', async (request, response) => {
  const text = String(request.body?.text || '').trim();
  const authorName = String(request.body?.author_name || '').trim() || null;
  if (!text) return response.status(400).json({ error: 'Comment text is required' });

  try {
    await databaseReady;
    const report = await get('SELECT id FROM reports WHERE id = ?', [request.params.id]);
    if (!report) return response.status(404).json({ error: 'Report not found' });
    const comment = {
      id: crypto.randomUUID(),
      report_id: request.params.id,
      text,
      authorName,
      created_at: new Date().toISOString(),
    };
    await run(
      `INSERT INTO comments (id, report_id, text, author_name, created_at)
       VALUES (?, ?, ?, ?, ?)`,
      [comment.id, comment.report_id, comment.text, comment.authorName, comment.created_at],
    );
    return response.status(201).json(comment);
  } catch (error) {
    return response.status(500).json({ error: 'Unable to save comment' });
  }
});

app.get('/api/reports/:id/comments', async (request, response) => {
  try {
    await databaseReady;
    const comments = await all(
      `SELECT id, report_id, text, author_name AS authorName, created_at
       FROM comments WHERE report_id = ? ORDER BY created_at ASC`,
      [request.params.id],
    );
    return response.json(comments);
  } catch (error) {
    return response.status(500).json({ error: 'Unable to load comments' });
  }
});

app.post('/api/reports/:id/teams', requireAuth, async (request, response) => {
  const name = String(request.body?.name || '').trim();
  const institution = String(request.body?.institution || '').trim();
  const leadName = String(request.body?.lead_name || '').trim();
  const contact = String(request.body?.contact || '').trim();
  const userId = String(request.user.id);
  if (!name || !institution || !leadName || !contact) {
    return response.status(400).json({ error: 'Team name, institution, lead name, and contact are required' });
  }

  try {
    await databaseReady;
    const report = await get('SELECT id FROM reports WHERE id = ?', [request.params.id]);
    if (!report) return response.status(404).json({ error: 'Report not found' });
    const team = await run(
      `INSERT INTO teams (report_id, name, institution, lead_name, contact)
       VALUES (?, ?, ?, ?, ?)`,
      [request.params.id, name, institution, leadName, contact],
    );
    await run(
      `INSERT INTO team_members (team_id, user_id, role) VALUES (?, ?, 'lead')`,
      [team.lastID, userId],
    );
    return response.status(201).json(await get(
      `SELECT teams.*, 1 AS member_count FROM teams WHERE teams.id = ?`,
      [team.lastID],
    ));
  } catch (error) {
    return response.status(500).json({ error: 'Unable to create team' });
  }
});

app.get('/api/reports/:id/teams', async (request, response) => {
  try {
    await databaseReady;
    const teams = await all(
      `SELECT teams.*, COUNT(team_members.id) AS member_count
       FROM teams LEFT JOIN team_members ON team_members.team_id = teams.id
       WHERE teams.report_id = ?
       GROUP BY teams.id ORDER BY teams.created_at ASC`,
      [request.params.id],
    );
    return response.json(teams);
  } catch (error) {
    return response.status(500).json({ error: 'Unable to load teams' });
  }
});

app.post('/api/teams/:id/join', requireAuth, async (request, response) => {
  const userId = String(request.user.id);
  try {
    await databaseReady;
    const team = await get('SELECT id FROM teams WHERE id = ?', [request.params.id]);
    if (!team) return response.status(404).json({ error: 'Team not found' });
    const existing = await get(
      'SELECT id FROM team_members WHERE team_id = ? AND user_id = ?',
      [request.params.id, userId],
    );
    if (!existing) {
      await run(
        `INSERT INTO team_members (team_id, user_id, role) VALUES (?, ?, 'member')`,
        [request.params.id, userId],
      );
    }
    return response.status(existing ? 200 : 201).json({ team_id: Number(request.params.id), user_id: userId });
  } catch (error) {
    return response.status(500).json({ error: 'Unable to join team' });
  }
});

app.get('/api/users/me/teams', requireAuth, async (request, response) => {
  const userId = String(request.user.id);
  try {
    await databaseReady;
    const teams = await all(
      `SELECT teams.id, teams.report_id, teams.name
       FROM teams INNER JOIN team_members ON team_members.team_id = teams.id
       WHERE team_members.user_id = ?`,
      [userId],
    );
    return response.json(teams);
  } catch (error) {
    return response.status(500).json({ error: 'Unable to load user teams' });
  }
});

app.get('/api/solver-tasks', async (request, response) => {
  try {
    await databaseReady;
    const reports = await all(`
            SELECT id, title, description, category, latitude, longitude, location_name,
              image_url, video_url, audio_url,
             priority, created_at, COALESCE(status, 'PENDING') AS status,
             (SELECT COUNT(*) FROM comments WHERE comments.report_id = reports.id) AS comment_count
      FROM reports
      ORDER BY created_at DESC
    `);
    const tasks = reports.map((report) => ({
      id: report.id,
      title: report.title,
      description: report.description,
      category: report.category,
      latitude: report.latitude,
      longitude: report.longitude,
      location_name: report.location_name,
      image_url: report.image_url,
      video_url: report.video_url,
      audio_url: report.audio_url,
      comment_count: report.comment_count,
      priority: report.priority,
      created_at: report.created_at,
      status: report.status || 'PENDING',
    }));
    response.json({ success: true, data: tasks });
  } catch (error) {
    response.status(500).json({ success: false, error: 'Unable to load solver tasks' });
  }
});

app.patch('/api/solver-tasks/:id/status', async (request, response) => {
  const status = String(request.body?.status || '').toUpperCase();
  const allowedStatuses = new Set(['PENDING', 'IN_PROGRESS', 'RESOLVED']);
  if (!allowedStatuses.has(status)) {
    return response.status(400).json({
      error: 'Status must be PENDING, IN_PROGRESS, or RESOLVED',
    });
  }

  try {
    await databaseReady;
    const result = await run(
      'UPDATE reports SET status = ? WHERE id = ?',
      [status, request.params.id],
    );
    if (result.changes === 0) {
      return response.status(404).json({ error: 'Solver task not found' });
    }
    const updatedTask = await get(
            `SELECT id, title, description, category, latitude, longitude, location_name,
              image_url, video_url, audio_url,
              priority, created_at, COALESCE(status, 'PENDING') AS status
       FROM reports WHERE id = ?`,
      [request.params.id],
    );
    return response.json(updatedTask);
  } catch (error) {
    return response.status(500).json({ error: 'Unable to update solver task' });
  }
});

app.listen(port, '0.0.0.0', () => {
  console.log(`Node gateway listening on port ${port}`);
});