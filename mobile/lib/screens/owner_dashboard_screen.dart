import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../models/appointment.dart';
import '../models/shop.dart';
import '../services/noqeu_service.dart';
import '../utils/time_format.dart';
import 'create_shop_screen.dart';

class OwnerDashboardScreen extends StatefulWidget {
  const OwnerDashboardScreen({super.key});

  @override
  State<OwnerDashboardScreen> createState() => _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends State<OwnerDashboardScreen> {
  List<Shop> _shops = [];
  Shop? _selectedShop;
  List<Appointment> _queue = [];
  bool _loadingShops = true;
  bool _loadingQueue = false;

  @override
  void initState() {
    super.initState();
    _loadShops();
  }

  Future<void> _loadShops() async {
    setState(() => _loadingShops = true);
    try {
      final shops = await context.read<NoQeuService>().getMyShops();
      setState(() {
        _shops = shops;
        if (shops.isNotEmpty && _selectedShop == null) {
          _selectedShop = shops.first;
          _loadQueue();
        }
      });
    } catch (e) {
      _showSnack('Failed to load shops: $e');
    } finally {
      if (mounted) setState(() => _loadingShops = false);
    }
  }

  Future<void> _loadQueue() async {
    if (_selectedShop == null) return;
    setState(() => _loadingQueue = true);
    try {
      final queue = await context.read<NoQeuService>().getShopQueue(_selectedShop!.id);
      setState(() => _queue = queue);
    } catch (e) {
      _showSnack('Failed to load queue: $e');
    } finally {
      if (mounted) setState(() => _loadingQueue = false);
    }
  }

  Future<void> _addWalkIn() async {
    if (_selectedShop == null) return;
    try {
      final walkIn = await context.read<NoQeuService>().createOfflineWalkIn(_selectedShop!.id);
      setState(() => _queue.add(walkIn));
      _showSnack('Walk-in #${walkIn.tokenNumber} added');
    } catch (e) {
      _showSnack('Walk-in failed: $e');
    }
  }

  Future<void> _toggleQueue(bool value) async {
    if (_selectedShop == null) return;
    try {
      final updated = await context.read<NoQeuService>().updateShop(_selectedShop!.id, {'isAcceptingOnline': value});
      setState(() {
        _selectedShop = updated;
        final idx = _shops.indexWhere((s) => s.id == updated.id);
        if (idx >= 0) _shops[idx] = updated;
      });
    } catch (e) {
      _showSnack('Failed to update: $e');
    }
  }

  Future<void> _markAction(Appointment a, String action) async {
    final idx = _queue.indexWhere((x) => x.id == a.id);
    if (idx < 0) return;
    final removed = _queue[idx];
    setState(() => _queue.removeAt(idx));

    try {
      await context.read<NoQeuService>().ownerAction(a.id, action);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('$action — Token #${a.tokenNumber}'),
        action: SnackBarAction(label: 'Undo', onPressed: () => setState(() => _queue.insert(idx, removed))),
      ));
    } catch (e) {
      if (!mounted) return;
      setState(() => _queue.insert(idx, removed));
      _showSnack('Action failed: $e');
    }
  }

  Future<bool> _confirmNoShow() async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Mark No-Show?'),
            content: const Text('This will apply a strike to the customer. This action cannot be undone.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                style: FilledButton.styleFrom(backgroundColor: const Color(0xFFCF6679)),
                child: const Text('Confirm No-Show'),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Owner Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_business_outlined),
            tooltip: 'Create Shop',
            onPressed: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateShopScreen()));
              _loadShops();
            },
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadQueue),
        ],
      ),
      body: _loadingShops
          ? const Center(child: CircularProgressIndicator())
          : _shops.isEmpty
              ? _EmptyShopsView(onCreate: () async {
                  await Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateShopScreen()));
                  _loadShops();
                })
              : Column(
                  children: [
                    // Shop selector
                    if (_shops.length > 1)
                      SizedBox(
                        height: 48,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _shops.length,
                          itemBuilder: (_, i) {
                            final s = _shops[i];
                            final selected = s.id == _selectedShop?.id;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(s.name),
                                selected: selected,
                                onSelected: (_) => setState(() { _selectedShop = s; _loadQueue(); }),
                              ),
                            );
                          },
                        ),
                      ),

                    // Controls
                    if (_selectedShop != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: SwitchListTile(
                                title: Text(_selectedShop!.isAcceptingOnline ? 'Accepting Online' : 'Paused'),
                                value: _selectedShop!.isAcceptingOnline,
                                onChanged: _toggleQueue,
                                contentPadding: EdgeInsets.zero,
                                dense: true,
                              ),
                            ),
                            FilledButton.icon(
                              onPressed: _addWalkIn,
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('+1 Walk-In'),
                              style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
                            ),
                          ],
                        ),
                      ),

                    const Divider(height: 1),

                    // Queue stats
                    if (_queue.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        child: Row(
                          children: [
                            _QueueStat(label: 'Pending', value: '${_queue.where((a) => a.status == 'Pending').length}', color: const Color(0xFF6C63FF)),
                            const SizedBox(width: 16),
                            _QueueStat(label: 'Walk-ins', value: '${_queue.where((a) => a.isWalkIn).length}', color: const Color(0xFF03DAC6)),
                          ],
                        ),
                      ),

                    // Queue list
                    Expanded(
                      child: _loadingQueue
                          ? const Center(child: CircularProgressIndicator())
                          : _queue.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.check_circle_outline, size: 48, color: Color(0xFF4CAF50)),
                                      const SizedBox(height: 12),
                                      Text('Queue is empty', style: theme.textTheme.titleMedium),
                                      Text('No pending tokens', style: theme.textTheme.bodyMedium),
                                    ],
                                  ),
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  itemCount: _queue.length,
                                  itemBuilder: (_, i) {
                                    final appt = _queue[i];
                                    return Dismissible(
                                      key: ValueKey(appt.id),
                                      background: Container(
                                        margin: const EdgeInsets.only(bottom: 8),
                                        decoration: BoxDecoration(color: const Color(0xFF4CAF50), borderRadius: BorderRadius.circular(16)),
                                        alignment: Alignment.centerLeft,
                                        padding: const EdgeInsets.only(left: 20),
                                        child: const Row(children: [Icon(Icons.check, color: Colors.white), SizedBox(width: 8), Text('Done', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600))]),
                                      ),
                                      secondaryBackground: Container(
                                        margin: const EdgeInsets.only(bottom: 8),
                                        decoration: BoxDecoration(color: const Color(0xFFCF6679), borderRadius: BorderRadius.circular(16)),
                                        alignment: Alignment.centerRight,
                                        padding: const EdgeInsets.only(right: 20),
                                        child: const Row(mainAxisAlignment: MainAxisAlignment.end, children: [Text('No-Show', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)), SizedBox(width: 8), Icon(Icons.person_off_outlined, color: Colors.white)]),
                                      ),
                                      confirmDismiss: (dir) async {
                                        if (dir == DismissDirection.startToEnd) {
                                          await _markAction(appt, 'Completed');
                                          return true;
                                        }
                                        final ok = await _confirmNoShow();
                                        if (!ok) return false;
                                        await _markAction(appt, 'No-Show');
                                        return true;
                                      },
                                      child: _QueueItem(appointment: appt),
                                    ).animate().fadeIn(delay: Duration(milliseconds: i * 60)).slideX(begin: 0.05, end: 0);
                                  },
                                ),
                    ),
                  ],
                ),
    );
  }
}

class _QueueItem extends StatelessWidget {
  const _QueueItem({required this.appointment});
  final Appointment appointment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2E2E42)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: appointment.isWalkIn ? const Color(0xFF03DAC6).withOpacity(0.15) : const Color(0xFF6C63FF).withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                '#${appointment.tokenNumber}',
                style: TextStyle(
                  color: appointment.isWalkIn ? const Color(0xFF03DAC6) : const Color(0xFF6C63FF),
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appointment.isWalkIn ? 'Walk-in' : (appointment.userInfo?['phone'] as String? ?? 'Online'),
                  style: theme.textTheme.titleMedium,
                ),
                Text(
                  formatSlotWindow(appointment.slotStart, appointment.slotEnd),
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const Icon(Icons.swap_horiz_outlined, size: 16, color: Color(0xFF555555)),
        ],
      ),
    );
  }
}

class _QueueStat extends StatelessWidget {
  const _QueueStat({required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text('$value $label', style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}

class _EmptyShopsView extends StatelessWidget {
  const _EmptyShopsView({required this.onCreate});
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.store_outlined, size: 64, color: Color(0xFF555555)),
            const SizedBox(height: 16),
            Text('No shops yet', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text('Create your first shop to start managing your queue', style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            FilledButton.icon(onPressed: onCreate, icon: const Icon(Icons.add), label: const Text('Create Shop')),
          ],
        ),
      ),
    );
  }
}
