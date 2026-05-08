import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../services/api_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  final _apiService = ApiService();

  String? _verificationId;
  bool _otpSent = false;
  bool _loading = false;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    final phone = _phoneCtrl.text.trim();
    if (phone.length < 10) {
      _snack('Enter a valid phone number with country code (e.g. +91...)');
      return;
    }
    setState(() => _loading = true);
    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phone,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-verification on Android
          await _signIn(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          _snack(e.message ?? 'Verification failed');
          setState(() => _loading = false);
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() {
            _verificationId = verificationId;
            _otpSent = true;
            _loading = false;
          });
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
      );
    } catch (e) {
      _snack('Error: $e');
      setState(() => _loading = false);
    }
  }

  Future<void> _verifyOtp() async {
    if (_verificationId == null) return;
    final otp = _otpCtrl.text.trim();
    if (otp.length != 6) { _snack('Enter 6-digit OTP'); return; }
    setState(() => _loading = true);
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otp,
      );
      await _signIn(credential);
    } on FirebaseAuthException {
      _snack('Invalid OTP. Please try again.');
      setState(() => _loading = false);
    }
  }

  Future<void> _signIn(PhoneAuthCredential credential) async {
    final userCredential =
        await FirebaseAuth.instance.signInWithCredential(credential);
    final idToken = await userCredential.user?.getIdToken();
    if (idToken != null) {
      await _apiService.firebaseLogin(idToken);
      if (mounted) {
        await context.read<UserProvider>().refreshJwt();
      }
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6C63FF), Color(0xFF9C8FFF)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.timer_outlined,
                        color: Colors.white, size: 26),
                  ),
                  const SizedBox(width: 12),
                  Text('NoQeu',
                      style: theme.textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w800)),
                ],
              ),
              const SizedBox(height: 40),
              Text(
                _otpSent ? 'Enter OTP' : 'Sign In',
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                _otpSent
                    ? 'Code sent to ${_phoneCtrl.text}'
                    : 'Enter your phone number to continue',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 32),
              if (!_otpSent) ...[
                TextField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    hintText: '+91 98765 43210',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _loading ? null : _sendOtp,
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('Send OTP'),
                ),
              ] else ...[
                TextField(
                  controller: _otpCtrl,
                  keyboardType: TextInputType.number,
                  autofocus: true,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(letterSpacing: 10),
                  decoration: const InputDecoration(
                    labelText: 'OTP Code',
                    counterText: '',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _loading ? null : _verifyOtp,
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('Verify & Continue'),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () =>
                      setState(() { _otpSent = false; _otpCtrl.clear(); }),
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
