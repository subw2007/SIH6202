/**
 * Solver Task Controller
 * Handles business logic, status codes, and queries for official solver feed
 */

const SolverTaskModel = require('../models/solverTask.model');

/**
 * @desc Get all solver tasks (with optional category, status, priority filters)
 * @route GET /api/solver-tasks
 * @access Public
 */
const getSolverTasks = async (req, res, next) => {
  try {
    const { category, status, priority } = req.query;
    const tasks = await SolverTaskModel.findAll({ category, status, priority });
    
    // Compute summary metrics matching UI requirements
    const totalCount = tasks.length;
    const highPriorityCount = tasks.filter(
      (t) => t.priority === 'high' || t.priority === 'critical'
    ).length;

    return res.status(200).json({
      success: true,
      count: totalCount,
      metrics: {
        total: totalCount,
        highPriority: highPriorityCount,
      },
      data: tasks,
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc Get single solver task by ID
 * @route GET /api/solver-tasks/:id
 * @access Public
 */
const getSolverTaskById = async (req, res, next) => {
  try {
    const task = await SolverTaskModel.findById(req.params.id);
    if (!task) {
      return res.status(404).json({
        success: false,
        message: `Solver task not found with id ${req.params.id}`,
      });
    }
    return res.status(200).json({
      success: true,
      data: task,
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc Update task work status ('pending' | 'inProgress' | 'resolved')
 * @route PATCH /api/solver-tasks/:id/status
 * @access Public
 */
const updateTaskStatus = async (req, res, next) => {
  try {
    const { status } = req.body;
    const validStatuses = ['pending', 'inProgress', 'in_progress', 'resolved'];

    if (!status || !validStatuses.includes(status)) {
      return res.status(400).json({
        success: false,
        message: `Invalid status. Allowed values: ${validStatuses.join(', ')}`,
      });
    }

    // Normalize 'in_progress' to 'inProgress' if passed
    const normalizedStatus = status === 'in_progress' ? 'inProgress' : status;

    const updatedTask = await SolverTaskModel.updateStatus(req.params.id, normalizedStatus);
    if (!updatedTask) {
      return res.status(404).json({
        success: false,
        message: `Solver task not found with id ${req.params.id}`,
      });
    }

    return res.status(200).json({
      success: true,
      message: 'Task status updated successfully',
      data: updatedTask,
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc Join solver team
 * @route POST /api/solver-tasks/:id/join
 * @access Public
 */
const joinSolverTeam = async (req, res, next) => {
  try {
    const updated = await SolverTaskModel.joinTeam(req.params.id);
    if (!updated) {
      return res.status(404).json({
        success: false,
        message: `Solver task not found with id ${req.params.id}`,
      });
    }
    return res.status(200).json({
      success: true,
      message: 'Joined solver team successfully',
      data: updated,
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc Upvote a solver task
 * @route POST /api/solver-tasks/:id/upvote
 * @access Public
 */
const upvoteSolverTask = async (req, res, next) => {
  try {
    const updated = await SolverTaskModel.upvote(req.params.id);
    if (!updated) {
      return res.status(404).json({
        success: false,
        message: `Solver task not found with id ${req.params.id}`,
      });
    }
    return res.status(200).json({
      success: true,
      message: 'Task upvoted successfully',
      data: updated,
    });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  getSolverTasks,
  getSolverTaskById,
  updateTaskStatus,
  joinSolverTeam,
  upvoteSolverTask,
};
