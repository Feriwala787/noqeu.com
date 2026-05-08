const mongoose = require('mongoose');

const userSchema = new mongoose.Schema({
  phone: { type: String, required: true, unique: true },
  password: { type: String, required: true },
  name: { type: String, default: '' },
  strikes: { type: Number, default: 0 },
  accessedShops: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Shop' }],
  fcmToken: { type: String, default: null },
  isOwner: { type: Boolean, default: false },
  createdAt: { type: Date, default: Date.now },
});

module.exports = mongoose.model('User', userSchema);
