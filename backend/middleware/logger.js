/**
 * Custom Request Logger Middleware
 */

const logger = (req, res, next) => {
  const startTime = Date.now();
  const { method, originalUrl, ip } = req;

  res.on('finish', () => {
    const elapsed = Date.now() - startTime;
    const statusCode = res.statusCode;
    const statusColor =
      statusCode >= 500
        ? '\x1b[31m' // Red
        : statusCode >= 400
        ? '\x1b[33m' // Yellow
        : statusCode >= 300
        ? '\x1b[36m' // Cyan
        : '\x1b[32m'; // Green
    const resetColor = '\x1b[0m';

    console.log(
      `[${new Date().toISOString()}] ${method} ${originalUrl} ${statusColor}${statusCode}${resetColor} - ${elapsed}ms - IP: ${ip || '::1'}`
    );
  });

  next();
};

module.exports = logger;
