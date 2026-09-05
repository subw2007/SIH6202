/**
 * Citizen Report Model / Schema Definition & Data Access Layer
 * Matches frontend CitizenProblemPost and report submission payloads.
 */

const { db } = require('../config/db');

class CitizenReportModel {
  /**
   * Normalize an item to guarantee exact JSON keys expected by frontend components
   */
  static formatReport(item) {
    if (!item) return null;
    return {
      id: item.id,
      title: item.title || '',
      location: item.location || '',
      timeAgo: item.timeAgo || item.time_ago || 'Just now',
      time_ago: item.time_ago || item.timeAgo || 'Just now',
      upvoteCount: typeof item.upvoteCount === 'number' ? item.upvoteCount : (item.upvote_count || 0),
      upvote_count: typeof item.upvote_count === 'number' ? item.upvote_count : (item.upvoteCount || 0),
      audioDuration: item.audioDuration || item.audio_duration || '0:00',
      audio_duration: item.audio_duration || item.audioDuration || '0:00',
      isVerified: item.isVerified !== undefined ? Boolean(item.isVerified) : Boolean(item.is_verified),
      is_verified: item.is_verified !== undefined ? Boolean(item.is_verified) : Boolean(item.isVerified),
      imageUrl: item.imageUrl || item.image_url || null,
      image_url: item.image_url || item.imageUrl || null,
      audioPath: item.audioPath || item.audio_path || null,
      audio_path: item.audio_path || item.audioPath || null,
      imageSource: item.imageSource || item.image_source || null,
      image_source: item.image_source || item.imageSource || null,
      imageBase64: item.imageBase64 || item.image_base64 || null,
      image_base64: item.image_base64 || item.imageBase64 || null,
      createdAt: item.createdAt || new Date().toISOString(),
    };
  }

  static async findAll() {
    return [...db.citizenReports]
      .sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt))
      .map(this.formatReport);
  }

  static async findById(id) {
    const report = db.citizenReports.find((r) => r.id === id);
    return report ? this.formatReport(report) : null;
  }

  static async create(data) {
    const nextNumber = db.citizenReports.reduce((max, report) => {
      const number = Number.parseInt(String(report.id).replace('rpt_', ''), 10);
      return Number.isNaN(number) ? max : Math.max(max, number);
    }, 0) + 1;
    const newId = `rpt_${String(nextNumber).padStart(3, '0')}`;
    
    // Format duration helper if audio_duration_ms provided
    let audioDurationStr = '0:00';
    if (data.audio_duration_ms || data.audioDurationMs) {
      const ms = data.audio_duration_ms || data.audioDurationMs;
      const totalSec = Math.floor(ms / 1000);
      const m = Math.floor(totalSec / 60);
      const s = totalSec % 60;
      audioDurationStr = `${m}:${String(s).padStart(2, '0')}`;
    } else if (data.audioDuration || data.audio_duration) {
      audioDurationStr = data.audioDuration || data.audio_duration;
    }

    const newReport = {
      id: newId,
      title: (data.title || '').trim(),
      location: data.location || 'Main St, Sector 4',
      timeAgo: 'Just now',
      time_ago: 'Just now',
      upvoteCount: 0,
      upvote_count: 0,
      audioDuration: audioDurationStr,
      audio_duration: audioDurationStr,
      isVerified: false,
      is_verified: false,
      imageUrl: data.imageUrl || data.image_url || (data.has_image || data.hasImage ? 'https://images.unsplash.com/photo-1515162816999-a0c47dc192f7?auto=format&fit=crop&w=600&q=80' : null),
      image_url: data.imageUrl || data.image_url || (data.has_image || data.hasImage ? 'https://images.unsplash.com/photo-1515162816999-a0c47dc192f7?auto=format&fit=crop&w=600&q=80' : null),
      audioPath: data.audio_path || data.audioPath || null,
      audio_path: data.audio_path || data.audioPath || null,
      imageSource: data.image_source || data.imageSource || null,
      image_source: data.image_source || data.imageSource || null,
      imageBase64: data.image_base64 || data.imageBase64 || null,
      image_base64: data.image_base64 || data.imageBase64 || null,
      createdAt: new Date().toISOString(),
    };

    db.citizenReports.push(newReport);
    db.save();
    return this.formatReport(newReport);
  }

  static async upvote(id) {
    const report = db.citizenReports.find((r) => r.id === id);
    if (!report) return null;
    report.upvoteCount = (report.upvoteCount || report.upvote_count || 0) + 1;
    report.upvote_count = report.upvoteCount;
    db.save();
    return this.formatReport(report);
  }

  static async delete(id) {
    const index = db.citizenReports.findIndex((r) => r.id === id);
    if (index === -1) return false;
    db.citizenReports.splice(index, 1);
    db.save();
    return true;
  }
}

module.exports = CitizenReportModel;
