const express = require('express');
const router = express.Router();
const {
  getAllData,
  getCitizenFeed,
  getSolverTasks,
} = require('../controllers/dataController');

router.get('/', getAllData);
router.get('/feed', getCitizenFeed);
router.get('/tasks', getSolverTasks);

module.exports = router;
