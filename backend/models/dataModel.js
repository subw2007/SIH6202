/**
 * Unified Data Model
 * Aggregates Citizen Reports and Solver Tasks models
 */

const CitizenReportModel = require('./citizenReport.model');
const SolverTaskModel = require('./solverTask.model');
const UserModel = require('./user.model');

class DataModel {
  static async getAllData() {
    const [citizenFeed, solverTasks, user] = await Promise.all([
      CitizenReportModel.findAll(),
      SolverTaskModel.findAll(),
      UserModel.getProfile(),
    ]);

    return {
      citizenFeed,
      solverTasks,
      user,
    };
  }

  static get citizenReports() {
    return CitizenReportModel;
  }

  static get solverTasks() {
    return SolverTaskModel;
  }

  static get user() {
    return UserModel;
  }
}

module.exports = DataModel;
