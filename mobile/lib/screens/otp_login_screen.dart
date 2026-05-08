import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/api_client.dart';
import '../state/auth_provider.dart';
import '../utils/app_config.dart';

class OtpLoginScreen extends StatefulWidget {
  const OtpLoginScreen({super.key, this.pendingShopId});
  final String? pendingShopId;

  @override
  State<OtpLoginScreen> createState() => _OtpLoginScreenState();
}

class _OtpLoginScreenState extends State<OtpLoginScreen> {
  final _phoneCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  bool _otpSent = false;
  bool _loading = false;
  String? _devOtp;

  late final ApiClient _apiClient;

  @override
  void initState() {
    super.initState();
    final authService = context.read<AuthProvider>().authService;
    _apiClient = ApiClient(authService: authService);
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    final phone = _phoneCtrl.text.trim();
    if (phone.length < 10) {
      _showSnack('Enter a valid phone number');
      return;
    }
    setState(() => _loading = true);
    try {
      if (AppConfig.useMockApi) {
        await context.read<AuthProvider>().authService.loginWithOtpMock(phone);
        await context.read<AuthProvider>().markLoggedIn({'phone': phone, 'strikes': 0, 'isOwner': false});
        if (!mounted) return;
        Navigator.pop(context, true);
        return;
      }
      final res = await _apiClient.sendOtp(phone);
      setState(() {
        _otpSent = true;
        _devOtp = res['otp'] as String?;
      });
    } catch (e) {
      _showSnack('Failed to send OTP: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _verifyOtp() async {
    final otp = _otpCtrl.text.trim();
    if (otp.length != 6) { _showSnack('Enter 6-digit OTP'); return; }
    setState(() => _loading = true);
    try {
      final res = await _apiClient.verifyOtp(_phoneCtrl.text.trim(), otp);
      await context.read<AuthProvider>().authService.saveToken(res['token'] as String);
      await context.read<AuthProvider>().markLoggedIn(res['user'] as Map<String, dynamic>);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      _showSnack('Invalid OTP. Try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Sign In')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Text(
                _otpSent ? 'Enter OTP' : 'Your Phone',
                style: theme.textTheme.headlineMedium,
              ).animate().fadeIn().slideX(begin: -0.1, end: 0),
              const SizedBox(height: 8),
              Text(
                _otpSent
                    ? 'We sent a 6-digit code to ${_phoneCtrl.text}'
                    : 'We\'ll send you a one-time password',
                style: theme.textTheme.bodyMedium,
              ).animate().fadeIn(delay: 100.ms),
              const SizedBox(height: 32),
              if (!_otpSent) ...[
                TextField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  autofocus: true,
                  style: theme.textTheme.bodyLarge,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    prefixIcon: Icon(Icons.phone_outlined),
                    hintText: '+1 234 567 8900',
                  ),
                ).animate().fadeIn(delay: 200.ms),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _loading ? null : _sendOtp,
                  child: _loading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Send OTP'),
                ).animate().fadeIn(delay: 300.ms),
              ] else ...[
                TextField(
                  controller: _otpCtrl,
                  keyboardType: TextInputType.number,
                  autofocus: true,
                  maxLength: 6,
                  style: theme.textTheme.headlineSmall?.copyWith(letterSpacing: 8),
                  textAlign: TextAlign.center,
                  decoration: const InputDecoration(
                    labelText: 'OTP Code',
                    counterText: '',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                ).animate().fadeIn(delay: 200.ms),
                if (_devOtp != null) ...[
                  const SizedBox(height: 8),
                  Text('Dev OTP: $_devOtp', style: theme.textTheme.bodyMedium?.copyWith(color: const Color(0xFF6C63FF))),
                ],
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _loading ? null : _verifyOtp,
                  child: _loading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Verify & Continue'),
                ).animate().fadeIn(delay: 300.ms),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => setState(() { _otpSent = false; _otpCtrl.clear(); }),
                  child: const Text('Change number'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
