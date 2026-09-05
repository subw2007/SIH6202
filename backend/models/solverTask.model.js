/**
 * Solver Task Model / Schema Definition & Data Access Layer
 * Matches frontend SolverTask structure and status transition requirements.
 */

const { db } = require('../config/db');

class SolverTaskModel {
  static formatTask(item) {
    if (!item) return null;
    return {
      id: item.id,
      title: item.title,
      timestamp: item.timestamp || item.timeAgo || 'Recently',
      timeAgo: item.timestamp || item.timeAgo || 'Recently',
      time_ago: item.timestamp || item.timeAgo || 'Recently',
      location: item.location,
      distance: item.distance || '1.0 km',
      upvotes: typeof item.upvotes === 'number' ? item.upvotes : (item.upvoteCount || 0),
      upvoteCount: typeof item.upvotes === 'number' ? item.upvotes : (item.upvoteCount || 0),
      teamCount: typeof item.teamCount === 'number' ? item.teamCount : (item.team_count || 1),
      team_count: typeof item.team_count === 'number' ? item.team_count : (item.teamCount || 1),
      priority: item.priority || 'medium',
      status: item.status || 'pending',
      category: item.category || 'infrastructure',
      description: item.description || '',
      createdAt: item.createdAt || new Date().toISOString(),
    };
  }

  static async findAll(filter = {}) {
    let tasks = [...db.solverTasks];

    if (filter.category && filter.category.toLowerCase() !== 'all') {
      tasks = tasks.filter(
        (t) => t.category.toLowerCase() === filter.category.toLowerCase()
      );
    }

    if (filter.status) {
      tasks = tasks.filter(
        (t) => t.status.toLowerCase() === filter.status.toLowerCase()
      );
    }

    if (filter.priority) {
      tasks = tasks.filter(
        (t) => t.priority.toLowerCase() === filter.priority.toLowerCase()
      );
    }

    return tasks.map(this.formatTask);
  }

  static async findById(id) {
    const task = db.solverTasks.find((t) => t.id === id);
    return task ? this.formatTask(task) : null;
  }

  static async create(data) {
    const newId = data.id || `task_${Date.now()}`;
    const newTask = {
      id: newId,
      title: data.title,
      timestamp: 'Just now',
      location: data.location || 'Local Area',
      distance: data.distance || '0.5 km',
      upvotes: data.upvotes || 0,
      teamCount: data.teamCount || data.team_count || 1,
      team_count: data.team_count || data.teamCount || 1,
      priority: data.priority || 'medium',
      status: data.status || 'pending',
      category: data.category || 'infrastructure',
      description: data.description || '',
      createdAt: new Date().toISOString(),
    };

    db.solverTasks.unshift(newTask);
    return this.formatTask(newTask);
  }

  static async updateStatus(id, newStatus) {
    const task = db.solverTasks.find((t) => t.id === id);
    if (!task) return null;

    task.status = newStatus;
    return this.formatTask(task);
  }

  static async joinTeam(id) {
    const task = db.solverTasks.find((t) => t.id === id);
    if (!task) return null;

    task.teamCount = (task.teamCount || task.team_count || 0) + 1;
    task.team_count = task.teamCount;
    return this.formatTask(task);
  }

  static async upvote(id) {
    const task = db.solverTasks.find((t) => t.id === id);
    if (!task) return null;

    task.upvotes = (task.upvotes || 0) + 1;
    return this.formatTask(task);
  }
}

module.exports = SolverTaskModel;
