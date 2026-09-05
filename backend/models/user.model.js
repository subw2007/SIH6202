/**
 * User / Mode Settings Model
 */

const { db } = require('../config/db');

class UserModel {
  static formatUser(user) {
    if (!user) return null;
    return {
      id: user.id,
      username: user.username,
      isCitizenMode: Boolean(user.isCitizenMode),
      role: user.role,
      email: user.email,
    };
  }

  static async getProfile() {
    return this.formatUser(db.user);
  }

  static async updateMode(isCitizenMode) {
    db.user.isCitizenMode = Boolean(isCitizenMode);
    db.save();
    return this.formatUser(db.user);
  }

  static async updateUsername(username) {
    if (username && typeof username === 'string') {
      db.user.username = username.trim();
      db.save();
    }
    return this.formatUser(db.user);
  }
}

module.exports = UserModel;
