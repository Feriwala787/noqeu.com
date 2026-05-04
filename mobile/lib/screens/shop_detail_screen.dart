import 'package:flutter/material.dart';
import '../models/shop.dart';
import '../models/slot_estimate.dart';
import '../services/noqeu_service.dart';
import '../utils/time_format.dart';
import '../state/app_state.dart';
import 'active_token_screen.dart';

class ShopDetailScreen extends StatefulWidget {
  const ShopDetailScreen({super.key, required this.shop, required this.repo, required this.appState});

  final Shop shop;
  final NoQeuService repo;
  final AppState appState;

  @override
  State<ShopDetailScreen> createState() => _ShopDetailScreenState();
}

class _ShopDetailScreenState extends State<ShopDetailScreen> {
  late Future<SlotEstimate> _slotFuture;
  bool _booking = false;

  @override
  void initState() {
    super.initState();
    _slotFuture = widget.repo.getNextSlot(widget.shop.id);
  }

  void _retry() {
    setState(() {
      _slotFuture = widget.repo.getNextSlot(widget.shop.id);
    });
  }

  Future<void> _bookToken() async {
    if (_booking) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm Booking'),
        content: const Text('No-shows may lead to strike penalties. Continue?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirm')),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _booking = true);
    try {
      final appointment = await widget.repo.createBooking(widget.shop.id);
      await widget.appState.setActiveToken(appointment);
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ActiveTokenScreen(appointment: appointment, repo: widget.repo, appState: widget.appState),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Booking failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _booking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.shop.name)),
      body: FutureBuilder<SlotEstimate>(
        future: _slotFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Unable to load slot: ${snapshot.error}'),
                  const SizedBox(height: 10),
                  OutlinedButton(onPressed: _retry, child: const Text('Retry')),
                ],
              ),
            );
          }
          final slot = snapshot.data!;
          if (!slot.acceptingOnline) {
            return Center(
              child: Text(slot.message ?? 'Shop is currently taking walk-ins only.'),
            );
          }
          final cancellable = canCancelAppointment(slot.expectedStart);
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Expected Window', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(
                  formatSlotWindow(slot.expectedStart, slot.expectedEnd),
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text('Estimated wait: ${slot.waitTimeMinutes} minutes'),
                Text('People ahead: ${slot.peopleAhead} • Seats active: ${slot.seatsInService}'),
                Text('Estimate confidence: ${slot.confidenceLabel}'),
                Text('Updated at: ${formatClock(slot.calculatedAt)}'),
                const SizedBox(height: 8),
                Text(cancellable
                    ? 'You may cancel if needed (>30 mins before start).'
                    : 'Cancellation window may be closed for this slot.'),
                const Spacer(),
                FilledButton(
                  onPressed: _booking ? null : _bookToken,
                  child: Text(_booking ? 'Booking...' : 'Get Token'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
