/**
 * Citizen Report Controller
 * Handles business logic, status codes, and error responses for citizen reports/feed
 */

const CitizenReportModel = require('../models/citizenReport.model');

/**
 * @desc Get all citizen reports (feed)
 * @route GET /api/citizen-feed or GET /api/reports
 * @access Public
 */
const getCitizenFeed = async (req, res, next) => {
  try {
    console.log(`[CONTROLLER] ${req.method} ${req.originalUrl} fetch citizen feed`);
    const reports = await CitizenReportModel.findAll();
    return res.status(200).json({
      success: true,
      count: reports.length,
      data: reports,
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc Get single report by ID
 * @route GET /api/reports/:id
 * @access Public
 */
const getReportById = async (req, res, next) => {
  try {
    const report = await CitizenReportModel.findById(req.params.id);
    if (!report) {
      return res.status(404).json({
        success: false,
        message: `Report not found with id ${req.params.id}`,
      });
    }
    return res.status(200).json({
      success: true,
      data: report,
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc Create new citizen report
 * @route POST /api/reports
 * @access Public
 */
const createReport = async (req, res, next) => {
  try {
    console.log(`[CONTROLLER] ${req.method} ${req.originalUrl} create report`);
    const { title, location, has_image, hasImage, image_source, imageSource, audio_path, audioPath, audio_duration_ms, audioDurationMs } = req.body;

    const hasAnyContent = (title && title.trim().length > 0) || has_image || hasImage || audio_path || audioPath;
    if (!hasAnyContent) {
      return res.status(400).json({
        success: false,
        message: 'Report must include either a title description, an image, or a voice note',
      });
    }

    const report = await CitizenReportModel.create(req.body);
    return res.status(201).json({
      success: true,
      message: 'Report submitted successfully',
      data: report,
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc Upvote a report
 * @route POST /api/reports/:id/upvote or PATCH /api/reports/:id/upvote
 * @access Public
 */
const upvoteReport = async (req, res, next) => {
  try {
    const updated = await CitizenReportModel.upvote(req.params.id);
    if (!updated) {
      return res.status(404).json({
        success: false,
        message: `Report not found with id ${req.params.id}`,
      });
    }
    return res.status(200).json({
      success: true,
      message: 'Report upvoted successfully',
      data: updated,
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc Delete a report
 * @route DELETE /api/reports/:id
 * @access Public
 */
const deleteReport = async (req, res, next) => {
  try {
    const deleted = await CitizenReportModel.delete(req.params.id);
    if (!deleted) {
      return res.status(404).json({
        success: false,
        message: `Report not found with id ${req.params.id}`,
      });
    }
    return res.status(200).json({
      success: true,
      message: 'Report deleted successfully',
    });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  getCitizenFeed,
  getReportById,
  createReport,
  upvoteReport,
  deleteReport,
};
