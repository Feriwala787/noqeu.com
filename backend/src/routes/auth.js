const router = require('express').Router();
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const { body, validationResult } = require('express-validator');
const User = require('../models/User');
const { auth } = require('../middleware/auth');

const signToken = (userId) => jwt.sign({ userId }, process.env.JWT_SECRET, { expiresIn: '30d' });

// POST /api/auth/register
router.post('/register', [
  body('phone').isMobilePhone(),
  body('password').isLength({ min: 6 }),
  body('name').optional().trim(),
], async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) return res.status(400).json({ errors: errors.array() });

  const { phone, password, name } = req.body;
  const existing = await User.findOne({ phone });
  if (existing) return res.status(409).json({ error: 'Phone already registered. Please login.' });

  const hash = await bcrypt.hash(password, 10);
  const user = await User.create({ phone, password: hash, name: name || '' });
  res.status(201).json({ token: signToken(user._id), user: { id: user._id, phone: user.phone, name: user.name, strikes: user.strikes, isOwner: user.isOwner } });
});

// POST /api/auth/login
router.post('/login', [
  body('phone').isMobilePhone(),
  body('password').notEmpty(),
], async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) return res.status(400).json({ errors: errors.array() });

  const { phone, password } = req.body;
  const user = await User.findOne({ phone });
  if (!user || !user.password) return res.status(401).json({ error: 'Invalid phone or password' });

  const match = await bcrypt.compare(password, user.password);
  if (!match) return res.status(401).json({ error: 'Invalid phone or password' });

  res.json({ token: signToken(user._id), user: { id: user._id, phone: user.phone, name: user.name, strikes: user.strikes, isOwner: user.isOwner } });
});

// GET /api/auth/me
router.get('/me', auth, (req, res) => {
  const u = req.user;
  res.json({ id: u._id, phone: u.phone, name: u.name, strikes: u.strikes, isOwner: u.isOwner });
});

module.exports = router;
