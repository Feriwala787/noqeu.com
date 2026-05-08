const router = require('express').Router();
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const { body, validationResult } = require('express-validator');
const User = require('../models/User');
const { auth } = require('../middleware/auth');

const signToken = (userId) => jwt.sign({ userId }, process.env.JWT_SECRET, { expiresIn: '30d' });

const userResponse = (u) => ({
  id: u._id, phone: u.phone, name: u.name, role: u.role, strikes: u.strikes, isOwner: u.role === 'owner',
});

// POST /api/auth/register
router.post('/register', [
  body('phone').isLength({ min: 10 }),
  body('password').isLength({ min: 6 }),
  body('name').notEmpty().trim(),
  body('role').optional().isIn(['customer', 'owner']),
], async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) return res.status(400).json({ errors: errors.array() });

  try {
    const { phone, password, name, role } = req.body;
    const existing = await User.findOne({ phone });
    if (existing) return res.status(409).json({ error: 'Phone already registered. Please login.' });

    const hash = await bcrypt.hash(password, 10);
    const user = await User.create({ phone, password: hash, name, role: role || 'customer' });
    res.status(201).json({ token: signToken(user._id), user: userResponse(user) });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// POST /api/auth/login
router.post('/login', [
  body('phone').isLength({ min: 10 }),
  body('password').notEmpty(),
], async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) return res.status(400).json({ errors: errors.array() });

  try {
    const { phone, password } = req.body;
    const user = await User.findOne({ phone });
    if (!user) return res.status(401).json({ error: 'Invalid phone or password' });

    const match = await bcrypt.compare(password, user.password);
    if (!match) return res.status(401).json({ error: 'Invalid phone or password' });

    res.json({ token: signToken(user._id), user: userResponse(user) });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// GET /api/auth/me
router.get('/me', auth, (req, res) => {
  res.json(userResponse(req.user));
});

module.exports = router;
