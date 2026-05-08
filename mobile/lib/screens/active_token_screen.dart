import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../models/appointment.dart';
import '../services/noqeu_service.dart';
import '../services/reminder_service.dart';
import '../state/app_state.dart';
import '../utils/time_format.dart';

class ActiveTokenScreen extends StatefulWidget {
  const ActiveTokenScreen({super.key, required this.appointment});
  final Appointment appointment;

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
      setState(() => _remaining = widget.appointment.slotStart.difference(DateTime.now()));
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  Future<void> _cancel() async {
    if (_cancelling) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancel Appointment?'),
        content: const Text('This will free your slot. No strike will be applied for timely cancellations.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Keep it')),
          OutlinedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Cancel Appointment')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _cancelling = true);
    try {
      await context.read<NoQeuService>().cancelBooking(widget.appointment.id);
      await context.read<AppState>().clearActiveToken();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Appointment cancelled.')));
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Cancel failed: $e')));
    } finally {
      if (mounted) setState(() => _cancelling = false);
    }
  }

  String _pad(int n) => n.toString().padLeft(2, '0');

  Color _timerColor() {
    final mins = _remaining.inMinutes;
    if (mins <= 10) return const Color(0xFFCF6679);
    if (mins <= 30) return const Color(0xFFFF9800);
    return const Color(0xFF6C63FF);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canCancel = canCancelAppointment(widget.appointment.slotStart);
    final mins = _remaining.inMinutes.clamp(0, 9999);
    final secs = (_remaining.inSeconds % 60).clamp(0, 59);
    final hints = _reminders.upcomingReminderHints(widget.appointment);
    final isStarted = _remaining.isNegative;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Active Token'),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF6C63FF).withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '#${widget.appointment.tokenNumber}',
              style: const TextStyle(color: Color(0xFF6C63FF), fontWeight: FontWeight.w700, fontSize: 16),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Countdown
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E2E),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: _timerColor().withOpacity(0.3), width: 2),
                ),
                child: Column(
                  children: [
                    Text(
                      isStarted ? 'Your turn!' : 'Starts in',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    if (!isStarted)
                      Text(
                        '${_pad(mins)}:${_pad(secs)}',
                        style: theme.textTheme.displaySmall?.copyWith(
                          color: _timerColor(),
                          fontWeight: FontWeight.w800,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ).animate(key: ValueKey(mins ~/ 1)).shimmer(
                            duration: 1000.ms,
                            color: _timerColor().withOpacity(0.3),
                          )
                    else
                      Text(
                        '🎉 Go in!',
                        style: theme.textTheme.displaySmall?.copyWith(color: const Color(0xFF4CAF50)),
                      ).animate().scale(duration: 400.ms, curve: Curves.elasticOut),
                    const SizedBox(height: 16),
                    Text(
                      formatSlotWindow(widget.appointment.slotStart, widget.appointment.slotEnd),
                      style: theme.textTheme.titleMedium?.copyWith(color: const Color(0xFF888888)),
                    ),
                  ],
                ),
              ).animate().fadeIn().scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1)),

              const SizedBox(height: 20),

              // Reminder hints
              if (hints.isNotEmpty)
                ...hints.map((h) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF9800).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFF9800).withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.notifications_outlined, color: Color(0xFFFF9800), size: 18),
                          const SizedBox(width: 10),
                          Expanded(child: Text(h, style: const TextStyle(color: Color(0xFFFF9800), fontSize: 13))),
                        ],
                      ),
                    ).animate().fadeIn()),

              const Spacer(),

              // Status info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E2E),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 18, color: Color(0xFF888888)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        canCancel
                            ? 'You can cancel up to 30 minutes before your slot.'
                            : 'Cancellation window closed. Please show up or a strike may be applied.',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              if (canCancel)
                OutlinedButton(
                  onPressed: _cancelling ? null : _cancel,
                  style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFFCF6679), side: const BorderSide(color: Color(0xFFCF6679))),
                  child: _cancelling
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Cancel Appointment'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
