/**
 * Express Application Bootstrap & Entry Point
 * Production-ready MVC setup with CORS, JSON parsing, logging, router mounting, and error handling.
 */

const express = require('express');
const cors = require('cors');
const dotenv = require('dotenv');

// Load environment variables
dotenv.config();

const { connectDB } = require('./config/db');
const logger = require('./middleware/logger');
const notFound = require('./middleware/notFound');
const errorHandler = require('./middleware/errorHandler');
const apiRoutes = require('./routes');

const app = express();
const PORT = process.env.PORT || 5000;
const API_PREFIX = process.env.API_PREFIX || '/api';

// Initialize Database connection
connectDB();

// Global Middleware
const corsOrigin = process.env.CORS_ORIGIN || '*';
app.use(
  cors({
    origin: corsOrigin === '*' ? '*' : corsOrigin.split(','),
    methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization'],
    credentials: true,
  })
);

app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Custom Request Logger
app.use(logger);

// Root Welcome Route
app.get('/', (req, res) => {
  res.status(200).json({
    name: 'CivicPulse API',
    version: '1.0.0',
    status: 'online',
    documentation: {
      health: `${API_PREFIX}/health`,
      citizenFeed: `${API_PREFIX}/citizen-feed`,
      reports: `${API_PREFIX}/reports`,
      solverTasks: `${API_PREFIX}/solver-tasks`,
      user: `${API_PREFIX}/user`,
    },
  });
});

// Mount Modular API Routes
app.use(API_PREFIX, apiRoutes);

// 404 Handler & Global Error Middleware
app.use(notFound);
app.use(errorHandler);

// Start Server
if (process.env.NODE_ENV !== 'test') {
  app.listen(PORT, () => {
    console.log(`========================================`);
    console.log(` CivicPulse Backend Server Running `);
    console.log(` Environment : ${process.env.NODE_ENV || 'development'}`);
    console.log(` Port        : ${PORT}`);
    console.log(` Base URL    : http://localhost:${PORT}${API_PREFIX}`);
    console.log(`========================================`);
  });
}

module.exports = app;
