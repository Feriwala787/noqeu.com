const router = require('express').Router();
const { body, validationResult } = require('express-validator');
const Shop = require('../models/Shop');
const Appointment = require('../models/Appointment');
const User = require('../models/User');
const { auth, ownerAuth } = require('../middleware/auth');

const calcNextSlot = async (shop) => {
  const now = new Date();
  const todayStart = new Date(now); todayStart.setHours(0, 0, 0, 0);
  const todayEnd = new Date(now); todayEnd.setHours(23, 59, 59, 999);

  const pending = await Appointment.countDocuments({
    shopId: shop._id,
    status: 'Pending',
    slotStart: { $gte: todayStart, $lte: todayEnd },
  });

  const groupsAhead = Math.ceil(pending / shop.totalSeats);
  const waitTimeMinutes = groupsAhead * shop.avgTimePerCustomer;
  const expectedStart = new Date(now.getTime() + waitTimeMinutes * 60000);
  const expectedEnd = new Date(expectedStart.getTime() + shop.avgTimePerCustomer * 60000);

  return {
    acceptingOnline: shop.isAcceptingOnline,
    waitTimeMinutes,
    peopleAhead: pending,
    seatsInService: shop.totalSeats,
    expectedStartTime: expectedStart,
    expectedEndTime: expectedEnd,
    calculatedAt: now,
    message: shop.isAcceptingOnline ? null : 'Shop is currently taking walk-ins only.',
  };
};

// GET /api/shops/:id/next-slot
router.get('/:id/next-slot', async (req, res) => {
  try {
    const shop = await Shop.findById(req.params.id);
    if (!shop) return res.status(404).json({ error: 'Shop not found' });
    res.json(await calcNextSlot(shop));
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// GET /api/shops/:id
router.get('/:id', async (req, res) => {
  try {
    const shop = await Shop.findById(req.params.id).populate('ownerId', 'name phone');
    if (!shop) return res.status(404).json({ error: 'Shop not found' });
    res.json(shop);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// POST /api/shops - create shop (owner)
router.post('/', auth, [
  body('name').notEmpty().trim(),
  body('occupation').notEmpty().trim(),
  body('totalSeats').isInt({ min: 1 }),
  body('avgTimePerCustomer').isInt({ min: 1 }),
], async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) return res.status(400).json({ errors: errors.array() });

  try {
    const shop = await Shop.create({ ...req.body, ownerId: req.user._id });
    req.user.isOwner = true;
    await req.user.save();
    res.status(201).json(shop);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// PUT /api/shops/:id - update shop
router.put('/:id', auth, async (req, res) => {
  try {
    const shop = await Shop.findOne({ _id: req.params.id, ownerId: req.user._id });
    if (!shop) return res.status(404).json({ error: 'Shop not found or unauthorized' });
    Object.assign(shop, req.body);
    await shop.save();
    res.json(shop);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// GET /api/shops/:id/queue - owner view today's queue
router.get('/:id/queue', auth, async (req, res) => {
  try {
    const shop = await Shop.findOne({ _id: req.params.id, ownerId: req.user._id });
    if (!shop) return res.status(403).json({ error: 'Unauthorized' });

    const todayStart = new Date(); todayStart.setHours(0, 0, 0, 0);
    const todayEnd = new Date(); todayEnd.setHours(23, 59, 59, 999);

    const queue = await Appointment.find({
      shopId: shop._id,
      slotStart: { $gte: todayStart, $lte: todayEnd },
    }).populate('userId', 'phone name strikes').sort({ slotStart: 1 });

    res.json(queue);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// POST /api/shops/:id/scan - user scans QR, adds shop to accessedShops
router.post('/:id/scan', auth, async (req, res) => {
  try {
    const shop = await Shop.findById(req.params.id);
    if (!shop) return res.status(404).json({ error: 'Shop not found' });

    const user = req.user;
    if (!user.accessedShops.includes(shop._id)) {
      user.accessedShops.push(shop._id);
      await user.save();
    }
    res.json(shop);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

module.exports = { router, calcNextSlot };
