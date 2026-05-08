import 'dart:async';
import 'package:flutter/material.dart';
import '../models/appointment.dart';
import '../utils/time_format.dart';

class ActiveTokenBanner extends StatefulWidget {
  const ActiveTokenBanner({super.key, required this.appointment, required this.onTap});
  final Appointment appointment;
  final VoidCallback onTap;

  @override
  State<ActiveTokenBanner> createState() => _ActiveTokenBannerState();
}

class _ActiveTokenBannerState extends State<ActiveTokenBanner> {
  late Timer _timer;
  late Duration _remaining;

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

  @override
  Widget build(BuildContext context) {
    final mins = _remaining.inMinutes.clamp(0, 9999);
    final secs = (_remaining.inSeconds % 60).clamp(0, 59);
    final isUrgent = mins <= 10;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isUrgent
                ? [const Color(0xFFCF6679), const Color(0xFFFF8A80)]
                : [const Color(0xFF6C63FF), const Color(0xFF9C8FFF)],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Icon(Icons.timer, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Active Token', style: TextStyle(color: Colors.white70, fontSize: 11)),
                  Text(
                    formatSlotWindow(widget.appointment.slotStart, widget.appointment.slotEnd),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ],
              ),
            ),
            Text(
              '$mins:${secs.toString().padLeft(2, '0')}',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18, fontFeatures: [FontFeature.tabularFigures()]),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: Colors.white70),
          ],
        ),
      ),
    );
  }
}
