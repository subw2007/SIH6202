const express = require('express');
const router = express.Router();
const {
  getSolverTasks,
  getSolverTaskById,
  updateTaskStatus,
  joinSolverTeam,
  upvoteSolverTask,
} = require('../controllers/solver.controller');

router.route('/')
  .get(getSolverTasks);

router.route('/:id')
  .get(getSolverTaskById);

router.route('/:id/status')
  .patch(updateTaskStatus)
  .put(updateTaskStatus);

router.route('/:id/join')
  .post(joinSolverTeam);

router.route('/:id/upvote')
  .post(upvoteSolverTask);

module.exports = router;
