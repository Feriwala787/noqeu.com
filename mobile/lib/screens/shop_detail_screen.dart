import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../services/api.dart';
import '../theme/app_theme.dart';

class ShopDetailScreen extends StatefulWidget {
  final Map<String, dynamic> shop;
  final bool isWalkIn; // true when customer scanned QR at the physical shop
  const ShopDetailScreen({super.key, required this.shop, this.isWalkIn = false});
  @override
  State<ShopDetailScreen> createState() => _ShopDetailScreenState();
}

class _ShopDetailScreenState extends State<ShopDetailScreen> {
  Map<String, dynamic>? _slot;
  Map<String, dynamic>? _token;
  bool _loadingSlot = true;
  bool _booking = false;
  Timer? _timer;

  String get _id => (widget.shop['_id'] ?? widget.shop['id']) as String;

  @override
  void initState() { super.initState(); _loadSlot(); _checkActiveToken(); }
  @override
  void dispose() { _timer?.cancel(); super.dispose(); }

  Future<void> _loadSlot() async {
    setState(() => _loadingSlot = true);
    try { _slot = await Api.getNextSlot(_id); } catch (_) {}
    if (mounted) setState(() => _loadingSlot = false);
  }

  Future<void> _checkActiveToken() async {
    try {
      final active = await Api.getActiveToken();
      if (active != null && mounted) {
        final shopId = active['shopId'] is Map ? active['shopId']['_id'] : active['shopId'];
        if (shopId == _id) {
          setState(() => _token = active);
          _startTimer();
        }
      }
    } catch (_) {}
  }

  Future<void> _book() async {
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      title: const Text('Get Your Token'),
      content: Text(widget.isWalkIn
          ? 'You\'ll get a token number. Please wait for your turn.'
          : 'No-shows may result in strikes. Arrive on time!'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Get Token')),
      ],
    ));
    if (ok != true) return;
    setState(() => _booking = true);
    try {
      _token = await Api.book(_id, isWalkIn: widget.isWalkIn);
      _startTimer();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Token #${_token!['tokenNumber']} confirmed!')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _booking = false);
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) { if (mounted) setState(() {}); });
  }

  Future<void> _cancel() async {
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      title: const Text('Cancel Token?'),
      content: const Text('Your slot will be freed for others.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Keep')),
        OutlinedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Cancel Token')),
      ],
    ));
    if (ok != true) return;
    try { await Api.cancel(_token!['_id']); setState(() => _token = null); _timer?.cancel(); _loadSlot(); }
    catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'))); }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('h:mm a');
    return Scaffold(
      appBar: AppBar(title: Text(widget.shop['name'] ?? 'Shop')),
      body: Padding(padding: const EdgeInsets.all(20), child: _token != null ? _activeView(fmt) : _slotView(fmt)),
    );
  }

  Widget _slotView(DateFormat fmt) {
    if (_loadingSlot) return const Center(child: CircularProgressIndicator());
    if (_slot == null) return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.wifi_off, size: 48, color: AppTheme.textSecondary),
      const SizedBox(height: 12), const Text('Could not load shop info'),
      const SizedBox(height: 12), OutlinedButton(onPressed: _loadSlot, child: const Text('Retry')),
    ]));

    final accepting = _slot!['acceptingOnline'] as bool? ?? true;
    final wait = _slot!['waitTimeMinutes'] as int;
    final ahead = _slot!['peopleAhead'] as int;
    final seats = _slot!['seatsInService'] as int;
    final seatsNow = _slot!['seatsAvailableNow'] as int? ?? seats;
    final start = DateTime.parse(_slot!['expectedStartTime']);
    final end = DateTime.parse(_slot!['expectedEndTime']);
    final openTime = _slot!['openTime'] ?? '';
    final closeTime = _slot!['closeTime'] ?? '';
    final conf = wait <= 30 ? 'High' : wait <= 60 ? 'Medium' : 'Low';
    final cc = wait <= 30 ? AppTheme.success : wait <= 60 ? AppTheme.warning : AppTheme.danger;
    final message = _slot!['message'] as String?;

    // If shop closed or no slots
    if (message != null && !accepting && !widget.isWalkIn) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.schedule, size: 48, color: AppTheme.warning),
        const SizedBox(height: 16),
        Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 8),
        const Text('Visit the shop and scan QR to get a walk-in token', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.textSecondary)),
      ]));
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Shop info
      Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: AppTheme.card, borderRadius: BorderRadius.circular(16)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(_occIcon(widget.shop['occupation'] ?? ''), color: AppTheme.primary, size: 20),
            const SizedBox(width: 8),
            Text(widget.shop['occupation'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
            const Spacer(),
            if (openTime.isNotEmpty) Text('$openTime – $closeTime', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
          ]),
          if ((widget.shop['address'] ?? '').toString().isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(children: [const Icon(Icons.location_on_outlined, size: 14, color: AppTheme.textSecondary), const SizedBox(width: 4),
              Expanded(child: Text(widget.shop['address'], style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)))]),
          ],
        ]),
      ).animate().fadeIn(),

      const SizedBox(height: 16),

      // Slot estimation card
      Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: AppTheme.card, borderRadius: BorderRadius.circular(20)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(widget.isWalkIn ? 'Your Estimated Slot' : 'Next Available Slot', style: const TextStyle(fontWeight: FontWeight.w600)),
            Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: cc.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.circle, size: 8, color: cc), const SizedBox(width: 4), Text(conf, style: TextStyle(color: cc, fontSize: 12, fontWeight: FontWeight.w600))])),
          ]),
          const SizedBox(height: 14),
          Text('${fmt.format(start)} – ${fmt.format(end)}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppTheme.primary)),
          const SizedBox(height: 16),
          Row(children: [
            _StatBox(Icons.people_outline, '$ahead', 'In Queue'),
            const SizedBox(width: 12),
            _StatBox(Icons.event_seat_outlined, '$seatsNow/$seats', 'Seats Free'),
            const SizedBox(width: 12),
            _StatBox(Icons.hourglass_bottom, '${wait}m', 'Wait'),
          ]),
        ]),
      ).animate().fadeIn(delay: 150.ms),

      if (widget.isWalkIn) ...[
        const SizedBox(height: 12),
        Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppTheme.success.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
          child: const Row(children: [Icon(Icons.location_on, color: AppTheme.success, size: 18), SizedBox(width: 8),
            Expanded(child: Text('You\'re at the shop — get your token now!', style: TextStyle(color: AppTheme.success, fontSize: 13)))])),
      ],

      const Spacer(),

      // Book button
      FilledButton(
        onPressed: _booking ? null : _book,
        child: _booking
            ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
            : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.confirmation_number_outlined, size: 20),
                const SizedBox(width: 8),
                Text(widget.isWalkIn ? 'Get Walk-in Token' : 'Book Token  •  Est. ${fmt.format(start)}'),
              ]),
      ).animate().fadeIn(delay: 300.ms),
      const SizedBox(height: 8),
      Center(child: Text(widget.isWalkIn ? 'You\'ll be called when it\'s your turn' : 'Arrive on time to avoid strikes',
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12))),
    ]);
  }

  Widget _activeView(DateFormat fmt) {
    final start = DateTime.parse(_token!['slotStart']);
    final end = DateTime.parse(_token!['slotEnd']);
    final rem = start.difference(DateTime.now());
    final m = rem.inMinutes.clamp(0, 9999);
    final s = (rem.inSeconds % 60).clamp(0, 59);
    final isNow = rem.isNegative;
    final canCancel = rem.inMinutes > 30;
    final c = m <= 10 ? AppTheme.danger : m <= 30 ? AppTheme.warning : AppTheme.primary;

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      // Token card
      Container(padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
        decoration: BoxDecoration(color: AppTheme.card, borderRadius: BorderRadius.circular(24), border: Border.all(color: c.withOpacity(0.3), width: 2)),
        child: Column(children: [
          Container(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10), decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.15), borderRadius: BorderRadius.circular(30)),
            child: Text('TOKEN #${_token!['tokenNumber']}', style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w800, fontSize: 20, letterSpacing: 1))),
          const SizedBox(height: 24),
          Text(isNow ? 'YOUR TURN!' : 'STARTS IN', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, letterSpacing: 2)),
          const SizedBox(height: 8),
          isNow
              ? const Text('🎉 Go in now!', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: AppTheme.success))
              : Text('${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}',
                  style: TextStyle(fontSize: 56, fontWeight: FontWeight.w800, color: c, fontFeatures: const [FontFeature.tabularFigures()])),
          const SizedBox(height: 16),
          Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(12)),
            child: Text('${fmt.format(start)} – ${fmt.format(end)}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14))),
        ]),
      ).animate().fadeIn().scale(begin: const Offset(0.95, 0.95)),

      const SizedBox(height: 20),

      // Info
      Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: AppTheme.card, borderRadius: BorderRadius.circular(14)),
        child: Row(children: [
          Icon(isNow ? Icons.directions_walk : Icons.info_outline, size: 18, color: isNow ? AppTheme.success : AppTheme.textSecondary),
          const SizedBox(width: 10),
          Expanded(child: Text(
            isNow ? 'Please proceed to the counter now.' : m <= 10 ? 'Almost your turn! Be ready.' : 'We\'ll update you as your turn approaches.',
            style: TextStyle(color: isNow ? AppTheme.success : AppTheme.textSecondary, fontSize: 13))),
        ]),
      ),

      const Spacer(),

      if (canCancel)
        OutlinedButton(onPressed: _cancel, style: OutlinedButton.styleFrom(foregroundColor: AppTheme.danger, side: const BorderSide(color: AppTheme.danger)),
          child: const Text('Cancel Token'))
      else
        const Padding(padding: EdgeInsets.all(12), child: Text('Cannot cancel within 30 minutes of your slot', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.textSecondary, fontSize: 13))),
    ]);
  }

  IconData _occIcon(String o) {
    final l = o.toLowerCase();
    if (l.contains('barber') || l.contains('hair')) return Icons.content_cut;
    if (l.contains('mechanic') || l.contains('auto')) return Icons.car_repair;
    if (l.contains('doctor') || l.contains('clinic')) return Icons.local_hospital_outlined;
    if (l.contains('salon')) return Icons.spa_outlined;
    return Icons.store_outlined;
  }
}

class _StatBox extends StatelessWidget {
  final IconData icon; final String value, label;
  const _StatBox(this.icon, this.value, this.label);
  @override
  Widget build(BuildContext context) => Expanded(child: Container(
    padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(12)),
    child: Column(children: [
      Icon(icon, size: 18, color: AppTheme.primary),
      const SizedBox(height: 6),
      Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
      Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
    ]),
  ));
}
