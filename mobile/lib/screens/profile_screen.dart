import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../models/appointment.dart';
import '../services/noqeu_service.dart';
import '../state/auth_provider.dart';
import '../utils/time_format.dart';
import 'otp_login_screen.dart';
import 'owner_dashboard_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  List<Appointment>? _appointments;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _loading = true);
    try {
      final appts = await context.read<NoQeuService>().getMyAppointments();
      setState(() => _appointments = appts);
    } catch (_) {} finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _logout() async {
    await context.read<AuthProvider>().logout();
    if (!mounted) return;
    Navigator.pop(context);
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Completed': return const Color(0xFF4CAF50);
      case 'No-Show': return const Color(0xFFCF6679);
      case 'Cancelled': return const Color(0xFF888888);
      default: return const Color(0xFF6C63FF);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!auth.loggedIn) ...[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E2E),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.person_outline, size: 48, color: Color(0xFF555555)),
                      const SizedBox(height: 12),
                      Text('Not signed in', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OtpLoginScreen())),
                        child: const Text('Sign In'),
                      ),
                    ],
                  ),
                ).animate().fadeIn(),
              ] else ...[
                // Profile card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF6C63FF), Color(0xFF9C8FFF)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        child: Text(
                          (auth.userProfile?['phone'] as String? ?? '?').substring(0, 1),
                          style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(auth.userProfile?['phone'] as String? ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16)),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.warning_amber_outlined, size: 14, color: Colors.white70),
                                const SizedBox(width: 4),
                                Text('${auth.userProfile?['strikes'] ?? 0} strikes', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (auth.userProfile?['isOwner'] == true)
                        TextButton(
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OwnerDashboardScreen())),
                          style: TextButton.styleFrom(foregroundColor: Colors.white),
                          child: const Text('Dashboard'),
                        ),
                    ],
                  ),
                ).animate().fadeIn(),

                const SizedBox(height: 24),

                // Strikes warning
                if ((auth.userProfile?['strikes'] as int? ?? 0) >= 1)
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFCF6679).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFCF6679).withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_outlined, color: Color(0xFFCF6679)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            (auth.userProfile?['strikes'] as int? ?? 0) >= 2
                                ? 'Online booking blocked (2+ strikes). Visit in person.'
                                : 'Warning: 1 strike. Another no-show will block online booking.',
                            style: const TextStyle(color: Color(0xFFCF6679), fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 100.ms),

                Text('Appointment History', style: theme.textTheme.titleMedium).animate().fadeIn(delay: 150.ms),
                const SizedBox(height: 12),

                if (_loading)
                  const Center(child: CircularProgressIndicator())
                else if (_appointments == null || _appointments!.isEmpty)
                  Text('No appointments yet.', style: theme.textTheme.bodyMedium).animate().fadeIn(delay: 200.ms)
                else
                  ..._appointments!.map((a) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E2E),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFF2E2E42)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(color: _statusColor(a.status), shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(a.shopInfo?['name'] as String? ?? 'Shop #${a.shopId.substring(0, 6)}', style: theme.textTheme.titleMedium),
                                  Text(formatSlotWindow(a.slotStart, a.slotEnd), style: theme.textTheme.bodyMedium),
                                ],
                              ),
                            ),
                            Text(a.status, style: TextStyle(color: _statusColor(a.status), fontSize: 12, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ).animate().fadeIn(delay: Duration(milliseconds: 200 + _appointments!.indexOf(a) * 50))),

                const SizedBox(height: 32),
                OutlinedButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout),
                  label: const Text('Sign Out'),
                  style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFFCF6679), side: const BorderSide(color: Color(0xFFCF6679))),
                ).animate().fadeIn(delay: 300.ms),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
