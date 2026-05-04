import 'dart:async';
import 'package:flutter/material.dart';
import '../models/appointment.dart';
import '../services/noqeu_service.dart';
import '../utils/time_format.dart';
import '../state/app_state.dart';
import '../services/reminder_service.dart';

class ActiveTokenScreen extends StatefulWidget {
  const ActiveTokenScreen({super.key, required this.appointment, required this.repo, this.appState});

  final Appointment appointment;
  final NoQeuService repo;
  final AppState? appState;

  @override
  State<ActiveTokenScreen> createState() => _ActiveTokenScreenState();
}

class _ActiveTokenScreenState extends State<ActiveTokenScreen> {
  final _reminders = ReminderService();
  late Timer _timer;
  late Duration _remaining;
  bool _cancelling = false;

  @override
  void initState() {
    super.initState();
    _remaining = widget.appointment.slotStart.difference(DateTime.now());
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _remaining = widget.appointment.slotStart.difference(DateTime.now());
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  Future<void> _cancel() async {
    if (_cancelling) return;
    setState(() => _cancelling = true);
    try {
      await widget.repo.cancelBooking(widget.appointment.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Appointment cancelled.')));
      await widget.appState?.clearActiveToken();
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Cancel failed: $e')));
    } finally {
      if (mounted) setState(() => _cancelling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canCancel = canCancelAppointment(widget.appointment.slotStart);
    final mins = _remaining.inMinutes.clamp(0, 9999);
    final secs = (_remaining.inSeconds % 60).clamp(0, 59);

    return Scaffold(
      appBar: AppBar(title: const Text('Active Token')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Your slot window', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              formatSlotWindow(widget.appointment.slotStart, widget.appointment.slotEnd),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),
            Text('Starts in', style: Theme.of(context).textTheme.titleMedium),
            Text('$mins:${secs.toString().padLeft(2, '0')}', style: Theme.of(context).textTheme.displaySmall),
            const SizedBox(height: 12),
            ..._reminders.upcomingReminderHints(widget.appointment).map((e) => Text(e)).toList(),
            const Spacer(),
            if (canCancel)
              OutlinedButton(
                onPressed: _cancelling ? null : _cancel,
                child: Text(_cancelling ? 'Cancelling...' : 'Cancel Appointment'),
              )
            else
              const Text('Cancellation unavailable within 30 minutes of slot start.'),
          ],
        ),
      ),
    );
  }
}
