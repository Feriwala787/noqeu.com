const mongoose = require('mongoose');

const appointmentSchema = new mongoose.Schema({
  shopId: { type: mongoose.Schema.Types.ObjectId, ref: 'Shop', required: true },
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', default: null },
  tokenNumber: { type: Number, required: true },
  slotStart: { type: Date, required: true },
  slotEnd: { type: Date, required: true },
  status: {
    type: String,
    enum: ['Pending', 'Completed', 'No-Show', 'Cancelled'],
    default: 'Pending',
  },
  isWalkIn: { type: Boolean, default: false },
  reminderSent: { type: Boolean, default: false },
  expireAt: { type: Date, required: true },
  createdAt: { type: Date, default: Date.now },
});

appointmentSchema.index({ expireAt: 1 }, { expireAfterSeconds: 0 });
appointmentSchema.index({ shopId: 1, status: 1, slotStart: 1 });
appointmentSchema.index({ userId: 1, status: 1 });

module.exports = mongoose.model('Appointment', appointmentSchema);
