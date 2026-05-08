const router = require('express').Router();
const jwt = require('jsonwebtoken');
const { body, validationResult } = require('express-validator');
const admin = require('firebase-admin');
const User = require('../models/User');
const { auth } = require('../middleware/auth');

const signToken = (userId) => jwt.sign({ userId }, process.env.JWT_SECRET, { expiresIn: '30d' });

// POST /api/auth/firebase-login
router.post('/firebase-login', async (req, res) => {
  const { token, fcmToken } = req.body;
  if (!token) return res.status(401).json({ error: 'Firebase token is required' });

  try {
    const decodedToken = await admin.auth().verifyIdToken(token);
    const { phone_number: phone } = decodedToken;

    let user = await User.findOne({ phone });
    if (!user) user = await User.create({ phone });
    if (fcmToken) { user.fcmToken = fcmToken; await user.save(); }

    res.json({ token: signToken(user._id), user: { id: user._id, phone: user.phone, strikes: user.strikes, isOwner: user.isOwner } });
  } catch (error) {
    console.error('Firebase auth error:', error);
    res.status(403).json({ error: 'Invalid Firebase token' });
  }
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
