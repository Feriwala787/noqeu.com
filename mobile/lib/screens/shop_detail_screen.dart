import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../services/api.dart';
import '../theme/app_theme.dart';

class ShopDetailScreen extends StatefulWidget {
  final Map<String, dynamic> shop;
  const ShopDetailScreen({super.key, required this.shop});
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
  void initState() { super.initState(); _loadSlot(); }
  @override
  void dispose() { _timer?.cancel(); super.dispose(); }

  Future<void> _loadSlot() async {
    setState(() => _loadingSlot = true);
    try { _slot = await Api.getNextSlot(_id); } catch (_) {}
    if (mounted) setState(() => _loadingSlot = false);
  }

  Future<void> _book() async {
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      title: const Text('Get Token?'), content: const Text('No-shows may result in strikes.'),
      actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirm'))],
    ));
    if (ok != true) return;
    setState(() => _booking = true);
    try {
      _token = await Api.book(_id);
      _timer = Timer.periodic(const Duration(seconds: 1), (_) { if (mounted) setState(() {}); });
    } catch (e) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'))); }
    finally { if (mounted) setState(() => _booking = false); }
  }

  Future<void> _cancel() async {
    try { await Api.cancel(_token!['_id']); setState(() => _token = null); _timer?.cancel(); _loadSlot(); }
    catch (e) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'))); }
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
    if (_slot == null) return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [const Text('Could not load'), const SizedBox(height: 12), OutlinedButton(onPressed: _loadSlot, child: const Text('Retry'))]));
    final accepting = _slot!['acceptingOnline'] as bool? ?? true;
    final wait = _slot!['waitTimeMinutes'] as int;
    final ahead = _slot!['peopleAhead'] as int;
    final seats = _slot!['seatsInService'] as int;
    final start = DateTime.parse(_slot!['expectedStartTime']);
    final end = DateTime.parse(_slot!['expectedEndTime']);
    final conf = wait <= 30 ? 'High' : wait <= 60 ? 'Medium' : 'Low';
    final cc = wait <= 30 ? AppTheme.success : wait <= 60 ? AppTheme.warning : AppTheme.danger;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Wrap(spacing: 8, children: [
        Chip(avatar: const Icon(Icons.work_outline, size: 14), label: Text(widget.shop['occupation'] ?? '', style: const TextStyle(fontSize: 12))),
        Chip(avatar: const Icon(Icons.event_seat, size: 14), label: Text('${widget.shop['totalSeats']} seats', style: const TextStyle(fontSize: 12))),
        Chip(avatar: const Icon(Icons.timer_outlined, size: 14), label: Text('${widget.shop['avgTimePerCustomer']}m', style: const TextStyle(fontSize: 12))),
      ]).animate().fadeIn(),
      const SizedBox(height: 20),
      Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: AppTheme.card, borderRadius: BorderRadius.circular(20)),
        child: accepting ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Estimated Slot', style: TextStyle(fontWeight: FontWeight.w600)),
            Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: cc.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.circle, size: 8, color: cc), const SizedBox(width: 4), Text(conf, style: TextStyle(color: cc, fontSize: 12, fontWeight: FontWeight.w600))])),
          ]),
          const SizedBox(height: 14),
          Text('${fmt.format(start)} – ${fmt.format(end)}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppTheme.primary)),
          const SizedBox(height: 16),
          Row(children: [_S('Ahead', '$ahead'), const SizedBox(width: 24), _S('Seats', '$seats'), const SizedBox(width: 24), _S('Wait', '${wait}m')]),
        ]) : Row(children: [const Icon(Icons.pause_circle_outline, color: AppTheme.warning, size: 32), const SizedBox(width: 14), const Expanded(child: Text('Walk-ins only right now'))]),
      ).animate().fadeIn(delay: 200.ms),
      const Spacer(),
      if (accepting) FilledButton(
        onPressed: _booking ? null : _book,
        child: _booking ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
            : Text('Get Token  •  Est. ${fmt.format(start)}'),
      ).animate().fadeIn(delay: 400.ms),
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
      Container(padding: const EdgeInsets.all(32), decoration: BoxDecoration(color: AppTheme.card, borderRadius: BorderRadius.circular(24), border: Border.all(color: c.withOpacity(0.3), width: 2)),
        child: Column(children: [
          Text(isNow ? 'Your turn!' : 'Starts in', style: const TextStyle(color: AppTheme.textSecondary)),
          const SizedBox(height: 10),
          isNow ? Text('🎉 Go in!', style: TextStyle(fontSize: 36, fontWeight: FontWeight.w800, color: AppTheme.success))
              : Text('${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}', style: TextStyle(fontSize: 48, fontWeight: FontWeight.w800, color: c, fontFeatures: const [FontFeature.tabularFigures()])),
          const SizedBox(height: 14),
          Text('${fmt.format(start)} – ${fmt.format(end)}', style: const TextStyle(color: AppTheme.textSecondary)),
          const SizedBox(height: 8),
          Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6), decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
            child: Text('Token #${_token!['tokenNumber']}', style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w700))),
        ]),
      ).animate().fadeIn().scale(begin: const Offset(0.95, 0.95)),
      const Spacer(),
      if (canCancel) OutlinedButton(onPressed: _cancel, style: OutlinedButton.styleFrom(foregroundColor: AppTheme.danger, side: const BorderSide(color: AppTheme.danger)), child: const Text('Cancel Appointment'))
      else const Padding(padding: EdgeInsets.all(12), child: Text('Cannot cancel within 30 min', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.textSecondary, fontSize: 13))),
    ]);
  }
}

class _S extends StatelessWidget {
  final String l, v;
  const _S(this.l, this.v);
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(l, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)), Text(v, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
  ]);
}
