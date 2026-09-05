const express = require('express');
const router = express.Router();

const citizenRoutes = require('./citizen.routes');
const solverRoutes = require('./solver.routes');
const userRoutes = require('./user.routes');
const healthRoutes = require('./health.routes');
const dataRoutes = require('./dataRoutes');

// Mount routes
router.use('/citizen-feed', citizenRoutes);
router.use('/reports', citizenRoutes);
router.use('/solver-tasks', solverRoutes);
router.use('/user', userRoutes);
router.use('/health', healthRoutes);
router.use('/data', dataRoutes);

module.exports = router;
