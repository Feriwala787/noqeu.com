const router = require('express').Router();
const { body, validationResult } = require('express-validator');
const Shop = require('../models/Shop');
const Appointment = require('../models/Appointment');
const { auth } = require('../middleware/auth');

const calcNextSlot = async (shop) => {
  const now = new Date();
  const todayStart = new Date(now); todayStart.setHours(0, 0, 0, 0);
  const todayEnd = new Date(now); todayEnd.setHours(23, 59, 59, 999);

  // Check if shop is open today
  const dayOfWeek = now.getDay();
  if (!shop.workingDays.includes(dayOfWeek)) {
    return { acceptingOnline: false, message: 'Shop is closed today.', waitTimeMinutes: 0, peopleAhead: 0, seatsInService: shop.totalSeats, expectedStartTime: now, expectedEndTime: now, calculatedAt: now };
  }

  // Check if within open hours
  const [openH, openM] = shop.openTime.split(':').map(Number);
  const [closeH, closeM] = shop.closeTime.split(':').map(Number);
  const openMinutes = openH * 60 + openM;
  const closeMinutes = closeH * 60 + closeM;
  const nowMinutes = now.getHours() * 60 + now.getMinutes();

  if (nowMinutes >= closeMinutes) {
    return { acceptingOnline: false, message: 'Shop is closed for today.', waitTimeMinutes: 0, peopleAhead: 0, seatsInService: shop.totalSeats, expectedStartTime: now, expectedEndTime: now, calculatedAt: now };
  }

  const pending = await Appointment.countDocuments({
    shopId: shop._id, status: 'Pending', slotStart: { $gte: todayStart, $lte: todayEnd },
  });

  const groupsAhead = Math.ceil(pending / shop.totalSeats);
  const waitTimeMinutes = groupsAhead * shop.avgTimePerCustomer;

  // Start time is either now + wait, or shop open time (whichever is later)
  const baseStart = nowMinutes < openMinutes
    ? new Date(now.getFullYear(), now.getMonth(), now.getDate(), openH, openM)
    : now;
  const expectedStart = new Date(baseStart.getTime() + waitTimeMinutes * 60000);
  const expectedEnd = new Date(expectedStart.getTime() + shop.avgTimePerCustomer * 60000);

  // Check if slot exceeds close time
  const slotEndMinutes = expectedEnd.getHours() * 60 + expectedEnd.getMinutes();
  if (slotEndMinutes > closeMinutes) {
    return { acceptingOnline: false, message: 'No more slots available today.', waitTimeMinutes, peopleAhead: pending, seatsInService: shop.totalSeats, expectedStartTime: expectedStart, expectedEndTime: expectedEnd, calculatedAt: now };
  }

  // Available seats in current slot
  const currentSlotStart = new Date(expectedStart.getTime() - shop.avgTimePerCustomer * 60000);
  const inCurrentSlot = await Appointment.countDocuments({
    shopId: shop._id, status: 'Pending', slotStart: { $gte: currentSlotStart, $lte: expectedStart },
  });
  const seatsAvailableNow = Math.max(0, shop.totalSeats - (inCurrentSlot % shop.totalSeats));

  return {
    acceptingOnline: shop.isAcceptingOnline,
    waitTimeMinutes,
    peopleAhead: pending,
    seatsInService: shop.totalSeats,
    seatsAvailableNow,
    expectedStartTime: expectedStart,
    expectedEndTime: expectedEnd,
    calculatedAt: now,
    openTime: shop.openTime,
    closeTime: shop.closeTime,
    message: shop.isAcceptingOnline ? null : 'Shop is currently taking walk-ins only.',
  };
};

// GET /api/shops/:id/next-slot
router.get('/:id/next-slot', async (req, res) => {
  try {
    const shop = await Shop.findById(req.params.id);
    if (!shop) return res.status(404).json({ error: 'Shop not found' });
    res.json(await calcNextSlot(shop));
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// GET /api/shops/:id
router.get('/:id', async (req, res) => {
  try {
    const shop = await Shop.findById(req.params.id).populate('ownerId', 'name phone');
    if (!shop) return res.status(404).json({ error: 'Shop not found' });
    res.json(shop);
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// POST /api/shops - create shop (owner only)
router.post('/', auth, [
  body('name').notEmpty().trim(),
  body('occupation').notEmpty().trim(),
  body('totalSeats').isInt({ min: 1 }),
  body('avgTimePerCustomer').isInt({ min: 1 }),
], async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) return res.status(400).json({ errors: errors.array() });
  if (req.user.role !== 'owner') return res.status(403).json({ error: 'Only shop owners can create shops' });

  try {
    const shop = await Shop.create({ ...req.body, ownerId: req.user._id });
    res.status(201).json(shop);
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// PUT /api/shops/:id - update shop
router.put('/:id', auth, async (req, res) => {
  try {
    const shop = await Shop.findOne({ _id: req.params.id, ownerId: req.user._id });
    if (!shop) return res.status(404).json({ error: 'Shop not found or unauthorized' });
    Object.assign(shop, req.body);
    await shop.save();
    res.json(shop);
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// GET /api/shops/:id/queue
router.get('/:id/queue', auth, async (req, res) => {
  try {
    const shop = await Shop.findOne({ _id: req.params.id, ownerId: req.user._id });
    if (!shop) return res.status(403).json({ error: 'Unauthorized' });
    const todayStart = new Date(); todayStart.setHours(0, 0, 0, 0);
    const todayEnd = new Date(); todayEnd.setHours(23, 59, 59, 999);
    const queue = await Appointment.find({ shopId: shop._id, slotStart: { $gte: todayStart, $lte: todayEnd } })
      .populate('userId', 'phone name').sort({ slotStart: 1 });
    res.json(queue);
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// POST /api/shops/:id/scan - customer scans QR
router.post('/:id/scan', auth, async (req, res) => {
  try {
    const shop = await Shop.findById(req.params.id);
    if (!shop) return res.status(404).json({ error: 'Shop not found' });
    if (!req.user.accessedShops.includes(shop._id)) {
      req.user.accessedShops.push(shop._id);
      await req.user.save();
    }
    res.json(shop);
  } catch (e) { res.status(500).json({ error: e.message }); }
});

module.exports = { router, calcNextSlot };
