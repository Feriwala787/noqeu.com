const router = require('express').Router();
const Appointment = require('../models/Appointment');
const Shop = require('../models/Shop');
const User = require('../models/User');
const { auth } = require('../middleware/auth');
const { calcNextSlot } = require('./shops');

const getNextTokenNumber = async (shopId) => {
  const today = new Date(); today.setHours(0, 0, 0, 0);
  const count = await Appointment.countDocuments({ shopId, createdAt: { $gte: today } });
  return count + 1;
};

// POST /api/appointments/book
router.post('/book', auth, async (req, res) => {
  try {
    const { shopId } = req.body;
    if (!shopId) return res.status(400).json({ error: 'shopId required' });

    const user = req.user;
    if (user.strikes >= 2) {
      return res.status(403).json({ error: 'Booking blocked due to 2+ strikes. Visit in person.' });
    }

    const shop = await Shop.findById(shopId);
    if (!shop) return res.status(404).json({ error: 'Shop not found' });
    if (!shop.isAcceptingOnline) return res.status(400).json({ error: 'Shop is walk-in only right now' });

    // Check for existing active booking at this shop
    const existing = await Appointment.findOne({ shopId, userId: user._id, status: 'Pending' });
    if (existing) return res.status(409).json({ error: 'You already have an active token at this shop' });

    const slot = await calcNextSlot(shop);
    const tokenNumber = await getNextTokenNumber(shopId);
    const expireAt = new Date(new Date(slot.expectedEndTime).getTime() + 24 * 60 * 60 * 1000);

    const appointment = await Appointment.create({
      shopId,
      userId: user._id,
      tokenNumber,
      slotStart: slot.expectedStartTime,
      slotEnd: slot.expectedEndTime,
      status: 'Pending',
      expireAt,
    });

    res.status(201).json({ appointment });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// POST /api/appointments/offline - owner adds walk-in
router.post('/offline', auth, async (req, res) => {
  try {
    const { shopId } = req.body;
    const shop = await Shop.findOne({ _id: shopId, ownerId: req.user._id });
    if (!shop) return res.status(403).json({ error: 'Unauthorized or shop not found' });

    const slot = await calcNextSlot(shop);
    const tokenNumber = await getNextTokenNumber(shopId);
    const expireAt = new Date(new Date(slot.expectedEndTime).getTime() + 24 * 60 * 60 * 1000);

    const appointment = await Appointment.create({
      shopId,
      userId: null,
      tokenNumber,
      slotStart: slot.expectedStartTime,
      slotEnd: slot.expectedEndTime,
      status: 'Pending',
      isWalkIn: true,
      expireAt,
    });

    res.status(201).json({ appointment });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// PUT /api/appointments/:id/action - owner marks Completed/No-Show
router.put('/:id/action', auth, async (req, res) => {
  try {
    const { action } = req.body;
    if (!['Completed', 'No-Show', 'Cancelled'].includes(action)) {
      return res.status(400).json({ error: 'Invalid action' });
    }

    const appointment = await Appointment.findById(req.params.id).populate('shopId');
    if (!appointment) return res.status(404).json({ error: 'Appointment not found' });

    // Owner action: must own the shop
    if (action !== 'Cancelled') {
      const shop = await Shop.findOne({ _id: appointment.shopId, ownerId: req.user._id });
      if (!shop) return res.status(403).json({ error: 'Unauthorized' });
    } else {
      // Customer cancel: must be the booking owner and within cancel window
      if (appointment.userId?.toString() !== req.user._id.toString()) {
        return res.status(403).json({ error: 'Unauthorized' });
      }
      const minsUntilSlot = (appointment.slotStart - Date.now()) / 60000;
      if (minsUntilSlot <= 30) {
        return res.status(400).json({ error: 'Cannot cancel within 30 minutes of slot start' });
      }
    }

    appointment.status = action;
    await appointment.save();

    if (action === 'No-Show' && appointment.userId) {
      await User.findByIdAndUpdate(appointment.userId, { $inc: { strikes: 1 } });
    }

    res.json({ appointment });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// GET /api/appointments/my - user's appointments
router.get('/my', auth, async (req, res) => {
  try {
    const appointments = await Appointment.find({ userId: req.user._id })
      .populate('shopId', 'name occupation address')
      .sort({ slotStart: -1 })
      .limit(20);
    res.json(appointments);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

module.exports = router;
