const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const rateLimit = require('express-rate-limit');
require('dotenv').config();

// Import Routes
const authRoutes = require('./routes/auth');
const usersRoutes = require('./routes/users');
const classesRoutes = require('./routes/classes');
const childrenRoutes = require('./routes/children');
const attendanceRoutes = require('./routes/attendance');
const subscriptionsRoutes = require('./routes/subscriptions');
const paymentsRoutes = require('./routes/payments');
const salaryRoutes = require('./routes/salary');
const activitiesRoutes = require('./routes/activities');
const expensesRoutes = require('./routes/expenses');

// Import Middleware
const { errorHandler } = require('./middleware/errorHandler');
const { verifyToken } = require('./middleware/auth');

const app = express();

// Security Middleware
app.use(helmet());
app.use(cors({
  origin: process.env.CORS_ORIGIN?.split(',') || 'http://localhost:3000',
  credentials: true
}));

// Rate Limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // limit each IP to 100 requests per windowMs
  message: 'Too many requests from this IP, please try again later.'
});
app.use('/api/', limiter);

// Logging
app.use(morgan('combined'));

// Body Parser Middleware
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ limit: '10mb', extended: true }));

// Health Check Route
app.get('/api/health', (req, res) => {
  res.json({
    status: 'OK',
    timestamp: new Date().toISOString(),
    uptime: process.uptime()
  });
});

// Public Routes (No Auth Required)
app.use('/api/auth', authRoutes);

// Protected Routes (Auth Required)
app.use('/api/users', verifyToken, usersRoutes);
app.use('/api/classes', verifyToken, classesRoutes);
app.use('/api/children', verifyToken, childrenRoutes);
app.use('/api/attendance', verifyToken, attendanceRoutes);
app.use('/api/subscriptions', verifyToken, subscriptionsRoutes);
app.use('/api/payments', verifyToken, paymentsRoutes);
app.use('/api/salary', verifyToken, salaryRoutes);
app.use('/api/activities', verifyToken, activitiesRoutes);
app.use('/api/expenses', verifyToken, expensesRoutes);

// 404 Handler
app.use('*', (req, res) => {
  res.status(404).json({
    success: false,
    message: 'Route not found'
  });
});

// Global Error Handler
app.use(errorHandler);

// Start Server
const PORT = process.env.PORT || 3001;
app.listen(PORT, () => {
  console.log(`
╔════════════════════════════════════════════╗
║   Kindergarten Management System Backend    ║
║            🎓 Server Running               ║
║          Server: http://localhost:${PORT}      ║
╚════════════════════════════════════════════╝
  `);
});

module.exports = app;
