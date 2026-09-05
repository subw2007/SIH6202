/**
 * Health & Diagnostics Controller
 */

const getHealthStatus = (req, res) => {
  return res.status(200).json({
    status: 'ok',
    service: 'civicpulse-backend',
    environment: process.env.NODE_ENV || 'development',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    memoryUsage: process.memoryUsage(),
  });
};

module.exports = {
  getHealthStatus,
};
