import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import '../services/api.dart';
import '../theme/app_theme.dart';
import 'setup_shop_screen.dart';
import 'profile_screen.dart';

class OwnerHomeScreen extends StatefulWidget {
  const OwnerHomeScreen({super.key});
  @override
  State<OwnerHomeScreen> createState() => _OwnerHomeScreenState();
}

class _OwnerHomeScreenState extends State<OwnerHomeScreen> {
  List<dynamic> _shops = [];
  Map<String, dynamic>? _shop;
  List<dynamic> _queue = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _loadShops(); }

  Future<void> _loadShops() async {
    setState(() => _loading = true);
    try {
      _shops = await Api.getMyShops();
      if (_shops.isNotEmpty) { _shop = _shops.first as Map<String, dynamic>; await _loadQueue(); }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadQueue() async {
    if (_shop == null) return;
    try { _queue = await Api.getShopQueue(_shop!['_id']); } catch (_) {}
    if (mounted) setState(() {});
  }

  Future<void> _addWalkIn() async {
    try { await Api.addWalkIn(_shop!['_id']); _loadQueue(); } catch (e) { _snack('$e'); }
  }

  Future<void> _togglePause() async {
    final current = _shop!['isAcceptingOnline'] as bool? ?? true;
    try { _shop = await Api.updateShop(_shop!['_id'], {'isAcceptingOnline': !current}); setState(() {}); } catch (e) { _snack('$e'); }
  }

  Future<void> _action(String id, String action) async {
    try { await Api.ownerAction(id, action); _loadQueue(); } catch (e) { _snack('$e'); }
  }

  void _snack(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppUser>();
    final fmt = DateFormat('h:mm a');
    final accepting = _shop?['isAcceptingOnline'] as bool? ?? true;
    final pending = _queue.where((a) => a['status'] == 'Pending').toList();

    return Scaffold(
      body: SafeArea(child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _shops.isEmpty ? _noShopView() : _dashboardView(user, fmt, accepting, pending)),
    );
  }

  Widget _noShopView() => Center(child: Padding(padding: const EdgeInsets.all(32), child: Column(mainAxisSize: MainAxisSize.min, children: [
    const Icon(Icons.store_outlined, size: 64, color: AppTheme.textSecondary),
    const SizedBox(height: 16),
    Text('Set Up Your Shop', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
    const SizedBox(height: 8),
    const Text('Create your shop to start managing your queue', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.textSecondary)),
    const SizedBox(height: 24),
    FilledButton.icon(onPressed: () async { await Navigator.push(context, MaterialPageRoute(builder: (_) => const SetupShopScreen())); _loadShops(); },
      icon: const Icon(Icons.add), label: const Text('Create Shop')),
  ])));

  Widget _dashboardView(AppUser user, DateFormat fmt, bool accepting, List pending) {
    return RefreshIndicator(onRefresh: () async { await _loadQueue(); }, child: CustomScrollView(slivers: [
      SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(20, 16, 12, 0), child: Row(children: [
        Container(width: 38, height: 38, decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppTheme.primary, Color(0xFF9C8FFF)]), borderRadius: BorderRadius.circular(11)),
          child: const Icon(Icons.store, color: Colors.white, size: 19)),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_shop!['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          Text(_shop!['occupation'] ?? '', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
        ])),
        IconButton(icon: const Icon(Icons.settings_outlined), onPressed: () async { await Navigator.push(context, MaterialPageRoute(builder: (_) => SetupShopScreen(shop: _shop))); _loadShops(); }),
        IconButton(icon: const Icon(Icons.person_outline), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()))),
      ]))),

      // Stats row
      SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(20, 20, 20, 0), child: Row(children: [
        _StatCard('Pending', '${pending.length}', AppTheme.primary),
        const SizedBox(width: 10),
        _StatCard('Seats', '${_shop!['totalSeats']}', AppTheme.success),
        const SizedBox(width: 10),
        _StatCard('Slot', '${_shop!['avgTimePerCustomer']}m', AppTheme.warning),
      ]).animate().fadeIn())),

      // Controls
      SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(20, 16, 20, 0), child: Row(children: [
        Expanded(child: GestureDetector(onTap: _togglePause, child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(color: (accepting ? AppTheme.success : AppTheme.warning).withOpacity(0.12), borderRadius: BorderRadius.circular(14)),
          child: Row(children: [
            Icon(accepting ? Icons.wifi : Icons.wifi_off, color: accepting ? AppTheme.success : AppTheme.warning, size: 20),
            const SizedBox(width: 8),
            Text(accepting ? 'Online' : 'Paused', style: TextStyle(color: accepting ? AppTheme.success : AppTheme.warning, fontWeight: FontWeight.w600)),
          ])))),
        const SizedBox(width: 10),
        FilledButton.icon(onPressed: _addWalkIn, icon: const Icon(Icons.person_add_outlined, size: 18), label: const Text('Walk-In'),
          style: FilledButton.styleFrom(minimumSize: const Size(0, 48))),
      ]).animate().fadeIn(delay: 100.ms))),

      // Hours info
      SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
        child: Text('Hours: ${_shop!['openTime']} – ${_shop!['closeTime']}  •  ${_shop!['totalSeats']} seats  •  ${_shop!['avgTimePerCustomer']}min/slot',
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)))),

      SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(20, 8, 20, 8), child: Row(children: [
        Text("Today's Queue", style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
        const Spacer(),
        IconButton(icon: const Icon(Icons.refresh, size: 20), onPressed: _loadQueue),
      ]))),

      if (pending.isEmpty)
        const SliverFillRemaining(child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.check_circle_outline, size: 48, color: AppTheme.success),
          SizedBox(height: 10), Text('Queue empty', style: TextStyle(color: AppTheme.textSecondary)),
        ])))
      else
        SliverPadding(padding: const EdgeInsets.symmetric(horizontal: 20), sliver: SliverList(delegate: SliverChildBuilderDelegate((_, i) {
          final a = pending[i] as Map<String, dynamic>;
          final start = DateTime.parse(a['slotStart']);
          return Dismissible(
            key: ValueKey(a['_id']),
            background: Container(margin: const EdgeInsets.only(bottom: 8), decoration: BoxDecoration(color: AppTheme.success, borderRadius: BorderRadius.circular(14)), alignment: Alignment.centerLeft, padding: const EdgeInsets.only(left: 20), child: const Row(children: [Icon(Icons.check, color: Colors.white), SizedBox(width: 6), Text('Done', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600))])),
            secondaryBackground: Container(margin: const EdgeInsets.only(bottom: 8), decoration: BoxDecoration(color: AppTheme.danger, borderRadius: BorderRadius.circular(14)), alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20), child: const Row(mainAxisAlignment: MainAxisAlignment.end, children: [Text('No-Show', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)), SizedBox(width: 6), Icon(Icons.person_off, color: Colors.white)])),
            confirmDismiss: (dir) async {
              if (dir == DismissDirection.startToEnd) { _action(a['_id'], 'Completed'); return true; }
              final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(title: const Text('Mark No-Show?'), content: const Text('This applies a strike to the customer.'), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(context, true), style: FilledButton.styleFrom(backgroundColor: AppTheme.danger), child: const Text('Confirm'))]));
              if (ok == true) _action(a['_id'], 'No-Show');
              return ok ?? false;
            },
            child: Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: AppTheme.card, borderRadius: BorderRadius.circular(14)),
              child: Row(children: [
                Container(width: 42, height: 42, decoration: BoxDecoration(color: (a['isWalkIn'] == true ? AppTheme.warning : AppTheme.primary).withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                  child: Center(child: Text('#${a['tokenNumber']}', style: TextStyle(color: a['isWalkIn'] == true ? AppTheme.warning : AppTheme.primary, fontWeight: FontWeight.w700, fontSize: 14)))),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(a['isWalkIn'] == true ? 'Walk-in' : (a['userId'] is Map ? a['userId']['name'] ?? 'Customer' : 'Online'), style: const TextStyle(fontWeight: FontWeight.w500)),
                  Text(fmt.format(start), style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                ])),
                const Icon(Icons.swipe_outlined, size: 16, color: AppTheme.textSecondary),
              ]),
            ),
          ).animate().fadeIn(delay: Duration(milliseconds: i * 50));
        }, childCount: pending.length))),
      const SliverToBoxAdapter(child: SizedBox(height: 40)),
    ]));
  }

  Widget _StatCard(String label, String value, Color color) => Expanded(child: Container(
    padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
    child: Column(children: [Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color)), Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary))]),
  ));
}
