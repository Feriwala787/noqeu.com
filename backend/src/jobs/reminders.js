const cron = require('node-cron');
const Appointment = require('../models/Appointment');

// Runs every minute — sends reminder hints for slots starting in 30-31 mins
const startReminderJob = () => {
  cron.schedule('* * * * *', async () => {
    try {
      const now = new Date();
      const from = new Date(now.getTime() + 30 * 60000);
      const to = new Date(now.getTime() + 31 * 60000);

      const appointments = await Appointment.find({
        status: 'Pending',
        reminderSent: false,
        slotStart: { $gte: from, $lte: to },
      }).populate('shopId', 'name').populate('userId', 'fcmToken');

      for (const appt of appointments) {
        if (appt.userId?.fcmToken) {
          // FCM push notification (requires firebase-admin setup)
          console.log(`[REMINDER] Send FCM to ${appt.userId.fcmToken} for shop ${appt.shopId.name}`);
          // await sendFcmNotification(appt.userId.fcmToken, appt.shopId.name);
        }
        appt.reminderSent = true;
        await appt.save();
      }
    } catch (e) {
      console.error('[CRON] Reminder job error:', e.message);
    }
  });

  console.log('[CRON] Reminder job started');
};

module.exports = { startReminderJob };
