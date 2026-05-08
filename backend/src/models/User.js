const mongoose = require('mongoose');

const userSchema = new mongoose.Schema({
  phone: { type: String, required: true, unique: true },
  password: { type: String, required: true },
  name: { type: String, default: '' },
  role: { type: String, enum: ['customer', 'owner'], default: 'customer' },
  strikes: { type: Number, default: 0 },
  accessedShops: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Shop' }],
  createdAt: { type: Date, default: Date.now },
});

module.exports = mongoose.model('User', userSchema);
