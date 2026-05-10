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
// Both online customers and walk-in customers use this endpoint
// Walk-in customers scan QR at shop and book even if isAcceptingOnline=false
router.post('/book', auth, async (req, res) => {
  try {
    const { shopId, isWalkIn } = req.body;
    if (!shopId) return res.status(400).json({ error: 'shopId required' });

    const user = req.user;
    if (user.strikes >= 2) {
      return res.status(403).json({ error: 'Booking blocked due to 2+ strikes. Please contact the shop.' });
    }

    const shop = await Shop.findById(shopId);
    if (!shop) return res.status(404).json({ error: 'Shop not found' });

    // If shop is paused and this is NOT a walk-in scan, block
    if (!shop.isAcceptingOnline && !isWalkIn) {
      return res.status(400).json({ error: 'Online booking paused. Visit the shop and scan QR to get a token.' });
    }

    // Check for existing active booking at this shop
    const existing = await Appointment.findOne({ shopId, userId: user._id, status: 'Pending' });
    if (existing) return res.status(409).json({ error: 'You already have an active token at this shop', appointment: existing });

    const slot = await calcNextSlot(shop);
    if (!slot.acceptingOnline && !isWalkIn) {
      return res.status(400).json({ error: slot.message || 'No slots available' });
    }

    const tokenNumber = await getNextTokenNumber(shopId);
    const expireAt = new Date(new Date(slot.expectedEndTime).getTime() + 24 * 60 * 60 * 1000);

    const appointment = await Appointment.create({
      shopId,
      userId: user._id,
      tokenNumber,
      slotStart: slot.expectedStartTime,
      slotEnd: slot.expectedEndTime,
      status: 'Pending',
      isWalkIn: isWalkIn || false,
      expireAt,
    });

    res.status(201).json({ appointment, position: slot.peopleAhead + 1 });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// PUT /api/appointments/:id/action
router.put('/:id/action', auth, async (req, res) => {
  try {
    const { action } = req.body;
    if (!['Completed', 'No-Show', 'Cancelled'].includes(action)) {
      return res.status(400).json({ error: 'Invalid action' });
    }

    const appointment = await Appointment.findById(req.params.id);
    if (!appointment) return res.status(404).json({ error: 'Appointment not found' });

    if (action === 'Cancelled') {
      // Customer cancel
      if (appointment.userId?.toString() !== req.user._id.toString()) {
        return res.status(403).json({ error: 'Unauthorized' });
      }
      const minsUntilSlot = (appointment.slotStart - Date.now()) / 60000;
      if (minsUntilSlot <= 30) {
        return res.status(400).json({ error: 'Cannot cancel within 30 minutes of slot start' });
      }
    } else {
      // Owner action
      const shop = await Shop.findOne({ _id: appointment.shopId, ownerId: req.user._id });
      if (!shop) return res.status(403).json({ error: 'Unauthorized' });
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

// GET /api/appointments/my
router.get('/my', auth, async (req, res) => {
  try {
    const appointments = await Appointment.find({ userId: req.user._id })
      .populate('shopId', 'name occupation address')
      .sort({ slotStart: -1 }).limit(20);
    res.json(appointments);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// GET /api/appointments/active - get user's current active token
router.get('/active', auth, async (req, res) => {
  try {
    const appointment = await Appointment.findOne({ userId: req.user._id, status: 'Pending' })
      .populate('shopId', 'name occupation address');
    res.json(appointment);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

module.exports = router;
