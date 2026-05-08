import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../models/shop.dart';
import '../models/slot_estimate.dart';
import '../services/noqeu_service.dart';
import '../state/app_state.dart';
import '../state/auth_provider.dart';
import '../utils/time_format.dart';
import 'active_token_screen.dart';
import 'otp_login_screen.dart';

class ShopDetailScreen extends StatefulWidget {
  const ShopDetailScreen({super.key, required this.shop});
  final Shop shop;

  @override
  State<ShopDetailScreen> createState() => _ShopDetailScreenState();
}

class _ShopDetailScreenState extends State<ShopDetailScreen> {
  late Future<SlotEstimate> _slotFuture;
  bool _booking = false;

  @override
  void initState() {
    super.initState();
    _slotFuture = context.read<NoQeuService>().getNextSlot(widget.shop.id);
  }

  Future<void> _bookToken() async {
    final auth = context.read<AuthProvider>();
    if (!auth.loggedIn) {
      final ok = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => const OtpLoginScreen()));
      if (ok != true || !mounted) return;
    }

    if (auth.userProfile?['strikes'] != null && (auth.userProfile!['strikes'] as int) >= 2) {
      _showSnack('Booking blocked: 2+ strikes. Please visit in person.', isError: true);
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm Booking'),
        content: const Text('No-shows may lead to strike penalties that block future online bookings. Continue?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Get Token')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _booking = true);
    try {
      final repo = context.read<NoQeuService>();
      final appointment = await repo.createBooking(widget.shop.id);
      await context.read<AppState>().setActiveToken(appointment);
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => ActiveTokenScreen(appointment: appointment)));
    } catch (e) {
      if (!mounted) return;
      _showSnack('Booking failed: $e', isError: true);
    } finally {
      if (mounted) setState(() => _booking = false);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? const Color(0xFFCF6679) : null,
    ));
  }

  Color _confidenceColor(String label) {
    switch (label) {
      case 'High': return const Color(0xFF4CAF50);
      case 'Medium': return const Color(0xFFFF9800);
      default: return const Color(0xFFCF6679);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(widget.shop.name, style: const TextStyle(fontWeight: FontWeight.w700)),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF6C63FF), Color(0xFF13131F)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Center(
                  child: Icon(
                    _occupationIcon(widget.shop.occupation),
                    size: 64,
                    color: Colors.white.withOpacity(0.2),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _InfoChip(icon: Icons.work_outline, label: widget.shop.occupation),
                      const SizedBox(width: 8),
                      _InfoChip(icon: Icons.event_seat_outlined, label: '${widget.shop.totalSeats} seats'),
                      const SizedBox(width: 8),
                      _InfoChip(icon: Icons.timer_outlined, label: '${widget.shop.avgTimePerCustomer}m avg'),
                    ],
                  ),
                  if (widget.shop.address.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF888888)),
                        const SizedBox(width: 4),
                        Text(widget.shop.address, style: theme.textTheme.bodyMedium),
                      ],
                    ),
                  ],
                  if (widget.shop.description.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(widget.shop.description, style: theme.textTheme.bodyMedium),
                  ],
                  const SizedBox(height: 20),
                  FutureBuilder<SlotEstimate>(
                    future: _slotFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const _SlotSkeleton();
                      }
                      if (snapshot.hasError) {
                        return _ErrorCard(
                          message: 'Could not load slot info',
                          onRetry: () => setState(() => _slotFuture = context.read<NoQeuService>().getNextSlot(widget.shop.id)),
                        );
                      }
                      final slot = snapshot.data!;
                      if (!slot.acceptingOnline) {
                        return _WalkInOnlyCard(message: slot.message);
                      }
                      return _SlotCard(slot: slot, confidenceColor: _confidenceColor(slot.confidenceLabel));
                    },
                  ),
                ],
              ).animate().fadeIn(duration: 400.ms),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FutureBuilder<SlotEstimate>(
            future: _slotFuture,
            builder: (context, snapshot) {
              final canBook = snapshot.hasData && snapshot.data!.acceptingOnline;
              final slot = snapshot.data;
              return FilledButton(
                onPressed: (canBook && !_booking) ? _bookToken : null,
                child: _booking
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(
                        slot == null
                            ? 'Loading...'
                            : !slot.acceptingOnline
                                ? 'Walk-in Only'
                                : 'Get Token  •  Est. ${formatClock(slot.expectedStart)}',
                      ),
              );
            },
          ),
        ),
      ),
    );
  }

  IconData _occupationIcon(String occupation) {
    final o = occupation.toLowerCase();
    if (o.contains('barber') || o.contains('hair')) return Icons.content_cut;
    if (o.contains('mechanic') || o.contains('auto')) return Icons.car_repair;
    if (o.contains('doctor') || o.contains('clinic') || o.contains('derm')) return Icons.local_hospital_outlined;
    if (o.contains('salon') || o.contains('beauty')) return Icons.spa_outlined;
    return Icons.store_outlined;
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 14),
      label: Text(label),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

class _SlotCard extends StatelessWidget {
  const _SlotCard({required this.slot, required this.confidenceColor});
  final SlotEstimate slot;
  final Color confidenceColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF2E2E42)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Estimated Window', style: theme.textTheme.titleMedium),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: confidenceColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.circle, size: 8, color: confidenceColor),
                    const SizedBox(width: 4),
                    Text(slot.confidenceLabel, style: TextStyle(color: confidenceColor, fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            formatSlotWindow(slot.expectedStart, slot.expectedEnd),
            style: theme.textTheme.headlineSmall?.copyWith(color: const Color(0xFF6C63FF), fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),
          Row(
            children: [
              _StatItem(icon: Icons.people_outline, label: 'Ahead', value: '${slot.peopleAhead}'),
              const SizedBox(width: 24),
              _StatItem(icon: Icons.event_seat_outlined, label: 'Seats', value: '${slot.seatsInService}'),
              const SizedBox(width: 24),
              _StatItem(icon: Icons.hourglass_bottom_outlined, label: 'Wait', value: '${slot.waitTimeMinutes}m'),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Updated ${formatClock(slot.calculatedAt)}',
            style: theme.textTheme.bodyMedium?.copyWith(fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [Icon(icon, size: 14, color: const Color(0xFF888888)), const SizedBox(width: 4), Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF888888)))]),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _WalkInOnlyCard extends StatelessWidget {
  const _WalkInOnlyCard({this.message});
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFF9800).withOpacity(0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.pause_circle_outline, color: Color(0xFFFF9800), size: 32),
          const SizedBox(width: 16),
          Expanded(child: Text(message ?? 'Walk-ins only right now', style: Theme.of(context).textTheme.bodyLarge)),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFCF6679).withOpacity(0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFCF6679), size: 32),
          const SizedBox(width: 16),
          Expanded(child: Text(message, style: Theme.of(context).textTheme.bodyLarge)),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _SlotSkeleton extends StatelessWidget {
  const _SlotSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      decoration: BoxDecoration(color: const Color(0xFF1E1E2E), borderRadius: BorderRadius.circular(20)),
    ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 1200.ms, color: const Color(0xFF2E2E42));
  }
}
