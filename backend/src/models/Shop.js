const mongoose = require('mongoose');

const shopSchema = new mongoose.Schema({
  ownerId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  name: { type: String, required: true, trim: true },
  occupation: { type: String, required: true, trim: true },
  description: { type: String, default: '' },
  address: { type: String, default: '' },
  totalSeats: { type: Number, required: true, min: 1 },
  avgTimePerCustomer: { type: Number, required: true, min: 1 },
  isAcceptingOnline: { type: Boolean, default: true },
  qrCodeString: { type: String },
  openTime: { type: String, default: '09:00' },
  closeTime: { type: String, default: '18:00' },
  createdAt: { type: Date, default: Date.now },
});

shopSchema.pre('save', function (next) {
  if (!this.qrCodeString) {
    this.qrCodeString = `noqeu://shop/${this._id}`;
  }
  next();
});

module.exports = mongoose.model('Shop', shopSchema);
