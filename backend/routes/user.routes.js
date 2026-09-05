const express = require('express');
const router = express.Router();
const {
  getUserProfile,
  updateUserMode,
  updateUsername,
} = require('../controllers/user.controller');

router.route('/')
  .get(getUserProfile);

router.route('/mode')
  .patch(updateUserMode)
  .put(updateUserMode);

router.route('/username')
  .patch(updateUsername)
  .put(updateUsername);

module.exports = router;
