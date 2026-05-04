import '../models/appointment.dart';

class ReminderService {
  List<String> upcomingReminderHints(Appointment appt, {DateTime? now}) {
    final n = now ?? DateTime.now();
    final mins = appt.slotStart.difference(n).inMinutes;
    final hints = <String>[];
    if (mins <= 60 && mins > 30) hints.add('Reminder: your slot starts in less than 60 minutes.');
    if (mins <= 30 && mins > 10) hints.add('Reminder: your slot starts in less than 30 minutes.');
    if (mins <= 10 && mins >= 0) hints.add('Reminder: your slot starts soon. Please reach on time.');
    return hints;
  }
}
