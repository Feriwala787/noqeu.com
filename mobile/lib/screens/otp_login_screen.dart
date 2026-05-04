import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../state/session_controller.dart';

class OtpLoginScreen extends StatefulWidget {
  const OtpLoginScreen({super.key, required this.session, required this.authService});

  final SessionController session;
  final AuthService authService;

  @override
  State<OtpLoginScreen> createState() => _OtpLoginScreenState();
}

class _OtpLoginScreenState extends State<OtpLoginScreen> {
  final _phoneController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _mockOtpLogin() async {
    if (_phoneController.text.trim().isEmpty) return;
    setState(() => _loading = true);
    await widget.authService.loginWithOtpMock(_phoneController.text.trim());
    await widget.session.markLoggedIn();
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login with OTP')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Phone Number'),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _loading ? null : _mockOtpLogin,
              child: Text(_loading ? 'Verifying...' : 'Continue'),
            ),
          ],
        ),
      ),
    );
  }
}
