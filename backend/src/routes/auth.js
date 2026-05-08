const router = require('express').Router();
const jwt = require('jsonwebtoken');
const { body, validationResult } = require('express-validator');
const User = require('../models/User');
const { auth } = require('../middleware/auth');

// Mock OTP store (replace with Firebase/Twilio in production)
const otpStore = new Map();

const generateOtp = () => Math.floor(100000 + Math.random() * 900000).toString();
const signToken = (userId) => jwt.sign({ userId }, process.env.JWT_SECRET, { expiresIn: '30d' });

// POST /api/auth/send-otp
router.post('/send-otp', [body('phone').isMobilePhone()], async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) return res.status(400).json({ errors: errors.array() });

  const { phone } = req.body;
  const otp = generateOtp();
  otpStore.set(phone, { otp, expiresAt: Date.now() + 5 * 60 * 1000 });

  // In production: send via Firebase Auth / Twilio
  console.log(`OTP for ${phone}: ${otp}`);
  res.json({ message: 'OTP sent', ...(process.env.NODE_ENV !== 'production' && { otp }) });
});

// POST /api/auth/verify-otp
router.post('/verify-otp', [body('phone').isMobilePhone(), body('otp').isLength({ min: 6, max: 6 })], async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) return res.status(400).json({ errors: errors.array() });

  const { phone, otp, fcmToken } = req.body;
  const stored = otpStore.get(phone);

  if (!stored || stored.otp !== otp || Date.now() > stored.expiresAt) {
    return res.status(400).json({ error: 'Invalid or expired OTP' });
  }
  otpStore.delete(phone);

  let user = await User.findOne({ phone });
  if (!user) user = await User.create({ phone });
  if (fcmToken) { user.fcmToken = fcmToken; await user.save(); }

  res.json({ token: signToken(user._id), user: { id: user._id, phone: user.phone, strikes: user.strikes, isOwner: user.isOwner } });
});

// GET /api/auth/me
router.get('/me', auth, (req, res) => {
  const u = req.user;
  res.json({ id: u._id, phone: u.phone, name: u.name, strikes: u.strikes, isOwner: u.isOwner });
});

// PUT /api/auth/fcm-token
router.put('/fcm-token', auth, async (req, res) => {
  const { fcmToken } = req.body;
  req.user.fcmToken = fcmToken;
  await req.user.save();
  res.json({ message: 'FCM token updated' });
});

module.exports = router;
