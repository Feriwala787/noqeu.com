require('dotenv').config();
const express = require('express');
const mongoose = require('mongoose');
const helmet = require('helmet');
const cors = require('cors');
const morgan = require('morgan');
const rateLimit = require('express-rate-limit');

const authRoutes = require('./routes/auth');
const { router: shopRoutes } = require('./routes/shops');
const appointmentRoutes = require('./routes/appointments');
const userRoutes = require('./routes/users');
const { startReminderJob } = require('./jobs/reminders');

const app = express();

app.use(helmet());
app.use(cors());
app.use(express.json());
app.use(morgan('combined'));

const limiter = rateLimit({ windowMs: 15 * 60 * 1000, max: 100 });
app.use('/api/', limiter);

app.use('/api/auth', authRoutes);
app.use('/api/shops', shopRoutes);
app.use('/api/appointments', appointmentRoutes);
app.use('/api/users', userRoutes);

app.get('/', (_, res) => res.json({ name: 'NoQeu API', version: '1.0.0', status: 'running' }));
app.get('/health', (_, res) => res.json({
  status: 'ok',
  timestamp: new Date(),
  db: mongoose.connection.readyState === 1 ? 'connected' : 'disconnected',
}));

app.use((err, req, res, _next) => {
  console.error(err);
  res.status(500).json({ error: 'Internal server error' });
});

const PORT = process.env.PORT || 3000;

// Start HTTP server immediately so Render health checks pass
app.listen(PORT, () => console.log(`[SERVER] Running on port ${PORT}`));

// Connect to MongoDB (retry-friendly)
const connectDB = async () => {
  try {
    await mongoose.connect(process.env.MONGODB_URI, {
      serverSelectionTimeoutMS: 10000,
    });
    console.log('[DB] Connected to MongoDB');
    startReminderJob();
  } catch (e) {
    console.error('[DB] Connection failed:', e.message);
    console.log('[DB] Retrying in 5s...');
    setTimeout(connectDB, 5000);
  }
};

connectDB();
