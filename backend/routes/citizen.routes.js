const express = require('express');
const router = express.Router();
const {
  getCitizenFeed,
  getReportById,
  createReport,
  upvoteReport,
  deleteReport,
} = require('../controllers/citizen.controller');

// Feed and reports routes
router.route('/')
  .get(getCitizenFeed)
  .post(createReport);

router.route('/:id')
  .get(getReportById)
  .delete(deleteReport);

router.route('/:id/upvote')
  .post(upvoteReport)
  .patch(upvoteReport);

module.exports = router;
