import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import '../services/api.dart';
import '../theme/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  List<dynamic> _history = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try { _history = await Api.getMyAppointments(); } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Color _sc(String s) => s == 'Completed' ? AppTheme.success : s == 'No-Show' ? AppTheme.danger : s == 'Cancelled' ? AppTheme.textSecondary : AppTheme.primary;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppUser>();
    final strikes = user.profile?['strikes'] ?? 0;
    final fmt = DateFormat('MMM d, h:mm a');
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppTheme.primary, Color(0xFF9C8FFF)]), borderRadius: BorderRadius.circular(20)),
          child: Row(children: [
            CircleAvatar(radius: 24, backgroundColor: Colors.white24, child: Text((user.profile?['name'] ?? user.profile?['phone'] ?? '?').toString().substring(0, 1).toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700))),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(user.profile?['name'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16)),
              Text(user.profile?['phone'] ?? '', style: const TextStyle(color: Colors.white70, fontSize: 13)),
              Row(children: [const Icon(Icons.warning_amber, size: 13, color: Colors.white70), const SizedBox(width: 4), Text('$strikes strikes', style: const TextStyle(color: Colors.white70, fontSize: 12))]),
            ])),
          ]),
        ).animate().fadeIn(),
        if (strikes >= 2) ...[
          const SizedBox(height: 12),
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppTheme.danger.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: const Row(children: [Icon(Icons.block, color: AppTheme.danger, size: 18), SizedBox(width: 10), Expanded(child: Text('Online booking blocked (2+ strikes)', style: TextStyle(color: AppTheme.danger, fontSize: 13)))])),
        ],
        const SizedBox(height: 28),
        const Text('History', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
        const SizedBox(height: 12),
        if (_loading) const Center(child: CircularProgressIndicator())
        else if (_history.isEmpty) const Text('No appointments yet', style: TextStyle(color: AppTheme.textSecondary))
        else ..._history.map((a) {
          final shop = a['shopId'];
          final name = shop is Map ? shop['name'] : 'Shop';
          return Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: AppTheme.card, borderRadius: BorderRadius.circular(14)),
            child: Row(children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: _sc(a['status']), shape: BoxShape.circle)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w500)),
                Text(fmt.format(DateTime.parse(a['slotStart'])), style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              ])),
              Text(a['status'], style: TextStyle(color: _sc(a['status']), fontSize: 12, fontWeight: FontWeight.w600)),
            ]),
          );
        }),
        const SizedBox(height: 32),
        OutlinedButton.icon(onPressed: () => context.read<AppUser>().logout(), icon: const Icon(Icons.logout), label: const Text('Sign Out'),
          style: OutlinedButton.styleFrom(foregroundColor: AppTheme.danger, side: const BorderSide(color: AppTheme.danger))),
      ])),
    );
  }
}
