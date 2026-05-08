import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../services/api.dart';
import '../theme/app_theme.dart';

class OwnerScreen extends StatefulWidget {
  const OwnerScreen({super.key});
  @override
  State<OwnerScreen> createState() => _OwnerScreenState();
}

class _OwnerScreenState extends State<OwnerScreen> {
  List<dynamic> _shops = [];
  Map<String, dynamic>? _selected;
  List<dynamic> _queue = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _loadShops(); }

  Future<void> _loadShops() async {
    setState(() => _loading = true);
    try {
      _shops = await Api.getMyShops();
      if (_shops.isNotEmpty && _selected == null) _selected = _shops.first;
      if (_selected != null) await _loadQueue();
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadQueue() async {
    try { _queue = await Api.getShopQueue(_selected!['_id']); } catch (_) {}
    if (mounted) setState(() {});
  }

  Future<void> _addWalkIn() async {
    try {
      await Api.addWalkIn(_selected!['_id']);
      _loadQueue();
    } catch (e) { _snack('$e'); }
  }

  Future<void> _action(String id, String action) async {
    try { await Api.ownerAction(id, action); _loadQueue(); } catch (e) { _snack('$e'); }
  }

  Future<void> _togglePause() async {
    final current = _selected!['isAcceptingOnline'] as bool? ?? true;
    try {
      _selected = await Api.updateShop(_selected!['_id'], {'isAcceptingOnline': !current});
      setState(() {});
    } catch (e) { _snack('$e'); }
  }

  void _snack(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('h:mm a');
    final accepting = _selected?['isAcceptingOnline'] as bool? ?? true;
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard'), actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _loadQueue)]),
      body: _loading ? const Center(child: CircularProgressIndicator()) : _shops.isEmpty
          ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.store_outlined, size: 56, color: AppTheme.textSecondary),
              const SizedBox(height: 12), const Text('No shops yet'),
              const SizedBox(height: 16), FilledButton(onPressed: () => _createShop(), child: const Text('Create Shop')),
            ]))
          : Column(children: [
              // Controls
              Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), child: Row(children: [
                Expanded(child: GestureDetector(
                  onTap: _togglePause,
                  child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10), decoration: BoxDecoration(color: accepting ? AppTheme.success.withOpacity(0.15) : AppTheme.warning.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(accepting ? Icons.play_circle : Icons.pause_circle, color: accepting ? AppTheme.success : AppTheme.warning, size: 20),
                      const SizedBox(width: 8), Text(accepting ? 'Online' : 'Paused', style: TextStyle(color: accepting ? AppTheme.success : AppTheme.warning, fontWeight: FontWeight.w600)),
                    ])),
                )),
                const SizedBox(width: 12),
                FilledButton.icon(onPressed: _addWalkIn, icon: const Icon(Icons.add, size: 18), label: const Text('+1 Walk-In'), style: FilledButton.styleFrom(minimumSize: const Size(0, 44))),
              ])),
              Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4), child: Row(children: [
                Text('Queue: ${_queue.length}', style: const TextStyle(fontWeight: FontWeight.w600)),
                const Spacer(),
                Text('Pending: ${_queue.where((a) => a['status'] == 'Pending').length}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
              ])),
              const Divider(height: 1),
              Expanded(child: _queue.isEmpty
                  ? const Center(child: Text('Queue empty ✓', style: TextStyle(color: AppTheme.textSecondary)))
                  : ListView.builder(padding: const EdgeInsets.all(16), itemCount: _queue.length, itemBuilder: (_, i) {
                      final a = _queue[i];
                      final start = DateTime.parse(a['slotStart']);
                      return Dismissible(
                        key: ValueKey(a['_id']),
                        background: Container(margin: const EdgeInsets.only(bottom: 8), decoration: BoxDecoration(color: AppTheme.success, borderRadius: BorderRadius.circular(14)), alignment: Alignment.centerLeft, padding: const EdgeInsets.only(left: 20), child: const Icon(Icons.check, color: Colors.white)),
                        secondaryBackground: Container(margin: const EdgeInsets.only(bottom: 8), decoration: BoxDecoration(color: AppTheme.danger, borderRadius: BorderRadius.circular(14)), alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20), child: const Icon(Icons.person_off, color: Colors.white)),
                        confirmDismiss: (dir) async {
                          if (dir == DismissDirection.startToEnd) { _action(a['_id'], 'Completed'); return true; }
                          final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(title: const Text('Mark No-Show?'), content: const Text('This applies a strike.'), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(context, true), style: FilledButton.styleFrom(backgroundColor: AppTheme.danger), child: const Text('Confirm'))]));
                          if (ok == true) _action(a['_id'], 'No-Show');
                          return ok ?? false;
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(color: AppTheme.card, borderRadius: BorderRadius.circular(14)),
                          child: Row(children: [
                            Container(width: 40, height: 40, decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                              child: Center(child: Text('#${a['tokenNumber']}', style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w700, fontSize: 13)))),
                            const SizedBox(width: 12),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(a['isWalkIn'] == true ? 'Walk-in' : 'Online', style: const TextStyle(fontWeight: FontWeight.w500)),
                              Text(fmt.format(start), style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                            ])),
                            const Icon(Icons.swipe_outlined, size: 16, color: AppTheme.textSecondary),
                          ]),
                        ),
                      ).animate().fadeIn(delay: Duration(milliseconds: i * 60));
                    })),
            ]),
    );
  }

  Future<void> _createShop() async {
    final nameCtrl = TextEditingController();
    final occCtrl = TextEditingController();
    final result = await showModalBottomSheet<bool>(context: context, isScrollControlled: true, builder: (_) => Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Business Name')),
        const SizedBox(height: 12),
        TextField(controller: occCtrl, decoration: const InputDecoration(labelText: 'Service Type (Barber, Mechanic...)')),
        const SizedBox(height: 20),
        FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Create')),
      ]),
    ));
    if (result == true && nameCtrl.text.isNotEmpty) {
      try {
        await Api.createShop({'name': nameCtrl.text.trim(), 'occupation': occCtrl.text.trim(), 'totalSeats': 2, 'avgTimePerCustomer': 30});
        _loadShops();
      } catch (e) { _snack('$e'); }
    }
  }
}
