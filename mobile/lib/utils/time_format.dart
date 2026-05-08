import 'package:intl/intl.dart';

String formatSlotWindow(DateTime start, DateTime end) {
  final formatter = DateFormat('h:mm a');
  return '${formatter.format(start)} - ${formatter.format(end)}';
}

String formatClock(DateTime t) => DateFormat('h:mm a').format(t);

bool canCancelAppointment(DateTime slotStart, {DateTime? now}) {
  final referenceNow = now ?? DateTime.now();
  return slotStart.difference(referenceNow).inMinutes > 30;
}
