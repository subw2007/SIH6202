/**
 * User / Mode Settings Controller
 */

const UserModel = require('../models/user.model');

const getUserProfile = async (req, res, next) => {
  try {
    const profile = await UserModel.getProfile();
    return res.status(200).json({
      success: true,
      data: profile,
    });
  } catch (error) {
    next(error);
  }
};

const updateUserMode = async (req, res, next) => {
  try {
    const { isCitizenMode } = req.body;
    if (typeof isCitizenMode !== 'boolean') {
      return res.status(400).json({
        success: false,
        message: 'isCitizenMode boolean value is required',
      });
    }

    const updated = await UserModel.updateMode(isCitizenMode);
    return res.status(200).json({
      success: true,
      message: `Mode updated to ${isCitizenMode ? 'Citizen' : 'Solver'}`,
      data: updated,
    });
  } catch (error) {
    next(error);
  }
};

const updateUsername = async (req, res, next) => {
  try {
    const { username } = req.body;
    if (!username || typeof username !== 'string') {
      return res.status(400).json({
        success: false,
        message: 'Valid username string is required',
      });
    }

    const updated = await UserModel.updateUsername(username);
    return res.status(200).json({
      success: true,
      message: 'Username updated successfully',
      data: updated,
    });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  getUserProfile,
  updateUserMode,
  updateUsername,
};
