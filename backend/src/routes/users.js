const router = require('express').Router();
const User = require('../models/User');
const Shop = require('../models/Shop');
const { auth } = require('../middleware/auth');

// GET /api/users/me/accessed-shops
router.get('/me/accessed-shops', auth, async (req, res) => {
  try {
    const user = await User.findById(req.user._id).populate('accessedShops');
    res.json(user.accessedShops);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// GET /api/users/me/shops - owner's shops
router.get('/me/shops', auth, async (req, res) => {
  try {
    const shops = await Shop.find({ ownerId: req.user._id });
    res.json(shops);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// PUT /api/users/me - update profile
router.put('/me', auth, async (req, res) => {
  try {
    const { name } = req.body;
    req.user.name = name || req.user.name;
    await req.user.save();
    res.json({ id: req.user._id, phone: req.user.phone, name: req.user.name, strikes: req.user.strikes });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

module.exports = router;
