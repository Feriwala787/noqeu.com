const mongoose = require('mongoose');

const shopSchema = new mongoose.Schema({
  ownerId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  name: { type: String, required: true, trim: true },
  occupation: { type: String, required: true, trim: true },
  description: { type: String, default: '' },
  address: { type: String, default: '' },
  phone: { type: String, default: '' },
  totalSeats: { type: Number, required: true, min: 1 },
  avgTimePerCustomer: { type: Number, required: true, min: 1 }, // minutes per slot
  isAcceptingOnline: { type: Boolean, default: true },
  openTime: { type: String, default: '09:00' }, // HH:mm
  closeTime: { type: String, default: '18:00' }, // HH:mm
  workingDays: { type: [Number], default: [1, 2, 3, 4, 5, 6] }, // 0=Sun, 1=Mon...6=Sat
  qrCodeString: { type: String },
  createdAt: { type: Date, default: Date.now },
});

shopSchema.pre('save', function (next) {
  if (!this.qrCodeString) this.qrCodeString = `noqeu://shop/${this._id}`;
  next();
});

module.exports = mongoose.model('Shop', shopSchema);
