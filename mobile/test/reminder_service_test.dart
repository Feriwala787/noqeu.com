import 'package:flutter_test/flutter_test.dart';
import 'package:noqeu_mobile/models/appointment.dart';
import 'package:noqeu_mobile/services/reminder_service.dart';

void main() {
  test('emits 30-minute reminder hint in window', () {
    final svc = ReminderService();
    final now = DateTime(2026, 1, 1, 10, 0);
    final appt = Appointment(
      id: 'a1',
      shopId: 's1',
      slotStart: now.add(const Duration(minutes: 25)),
      slotEnd: now.add(const Duration(minutes: 55)),
      status: 'Pending',
    );

    final hints = svc.upcomingReminderHints(appt, now: now);

    expect(hints.any((h) => h.contains('30 minutes')), isTrue);
  });
}
