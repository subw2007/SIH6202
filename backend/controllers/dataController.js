/**
 * Unified Data Controller
 */

const DataModel = require('../models/dataModel');
const CitizenReportModel = require('../models/citizenReport.model');
const SolverTaskModel = require('../models/solverTask.model');

const getAllData = async (req, res, next) => {
  try {
    const data = await DataModel.getAllData();
    return res.status(200).json({
      success: true,
      data,
    });
  } catch (error) {
    next(error);
  }
};

const getCitizenFeed = async (req, res, next) => {
  try {
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

const getSolverTasks = async (req, res, next) => {
  try {
    const { category, status, priority } = req.query;
    const tasks = await SolverTaskModel.findAll({ category, status, priority });
    return res.status(200).json({
      success: true,
      count: tasks.length,
      data: tasks,
    });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  getAllData,
  getCitizenFeed,
  getSolverTasks,
};
