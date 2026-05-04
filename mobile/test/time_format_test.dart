import 'package:flutter_test/flutter_test.dart';
import 'package:noqeu_mobile/utils/time_format.dart';

void main() {
  test('formats a slot window in 12-hour style', () {
    final start = DateTime(2026, 1, 1, 13, 30);
    final end = DateTime(2026, 1, 1, 14, 0);

    final output = formatSlotWindow(start, end);

    expect(output, '1:30 PM - 2:00 PM');
  });

  test('cancellation allowed only when more than 30 minutes remain', () {
    final now = DateTime(2026, 1, 1, 12, 0);

    expect(canCancelAppointment(DateTime(2026, 1, 1, 12, 31), now: now), isTrue);
    expect(canCancelAppointment(DateTime(2026, 1, 1, 12, 30), now: now), isFalse);
  });
}
