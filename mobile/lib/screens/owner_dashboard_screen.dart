import 'package:flutter/material.dart';
import '../models/appointment.dart';
import '../services/noqeu_service.dart';

class OwnerDashboardScreen extends StatefulWidget {
  const OwnerDashboardScreen({super.key, required this.repo});

  final NoQeuService repo;

  @override
  State<OwnerDashboardScreen> createState() => _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends State<OwnerDashboardScreen> {
  bool _acceptingOnline = true;
  final List<Appointment> _queue = [];

  Future<void> _addWalkIn() async {
    try {
      final walkIn = await widget.repo.createOfflineWalkIn();
      setState(() => _queue.add(walkIn));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Walk-in failed: $e')));
    }
  }

  Future<void> _markAction(Appointment a, String action) async {
    final idx = _queue.indexWhere((x) => x.id == a.id);
    if (idx < 0) return;
    final removed = _queue[idx];

    setState(() => _queue.removeAt(idx));
    try {
      await widget.repo.ownerAction(a.id, action);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$action marked for token ${a.id.substring(0, 6)}'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () {
              setState(() => _queue.insert(idx, removed));
            },
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _queue.insert(idx, removed));
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Action failed: $e')));
    }
  }

  Future<bool> _confirmNoShow() async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Confirm No-Show'),
            content: const Text('This may apply a strike to customer. Continue?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
              FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirm')),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Owner Dashboard')),
      body: Column(
        children: [
          SwitchListTile(
            title: const Text('Pause Queue'),
            subtitle: const Text('Disable online booking temporarily'),
            value: _acceptingOnline,
            onChanged: (v) => setState(() => _acceptingOnline = v),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: FilledButton.icon(
              onPressed: _addWalkIn,
              icon: const Icon(Icons.add),
              label: const Text('+1 Walk-In'),
            ),
          ),
          const Divider(),
          Expanded(
            child: ListView.builder(
              itemCount: _queue.length,
              itemBuilder: (_, i) {
                final appt = _queue[i];
                return Dismissible(
                  key: ValueKey(appt.id),
                  background: Container(color: Colors.green, alignment: Alignment.centerLeft, child: const Padding(padding: EdgeInsets.only(left: 16), child: Text('Completed'))),
                  secondaryBackground: Container(color: Colors.red, alignment: Alignment.centerRight, child: const Padding(padding: EdgeInsets.only(right: 16), child: Text('No-Show'))),
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
                  child: ListTile(
                    title: Text('Token ${appt.id.substring(0, 6)}'),
                    subtitle: Text(appt.status),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
