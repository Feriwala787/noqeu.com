import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import '../theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  bool _isRegister = false;
  bool _loading = false;
  bool _obscure = true;

  Future<void> _submit() async {
    final phone = _phoneCtrl.text.trim();
    final pass = _passCtrl.text.trim();
    if (phone.length < 10) { _snack('Enter valid phone with country code'); return; }
    if (pass.length < 6) { _snack('Password must be at least 6 characters'); return; }

    setState(() => _loading = true);
    try {
      if (_isRegister) {
        await context.read<AppUser>().register(phone, pass, name: _nameCtrl.text.trim());
      } else {
        await context.read<AppUser>().login(phone, pass);
      }
    } catch (e) {
      String msg = 'Something went wrong';
      if (e.toString().contains('409')) msg = 'Phone already registered. Please login.';
      if (e.toString().contains('401')) msg = 'Invalid phone or password';
      _snack(msg);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _snack(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60),
              Container(
                width: 64, height: 64,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppTheme.primary, Color(0xFF9C8FFF)]),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.timer_outlined, color: Colors.white, size: 34),
              ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),
              const SizedBox(height: 28),
              Text(_isRegister ? 'Create Account' : 'Welcome Back',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800))
                  .animate().fadeIn(delay: 200.ms),
              const SizedBox(height: 6),
              Text(_isRegister ? 'Sign up to start using NoQeu' : 'Login to continue',
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 15))
                  .animate().fadeIn(delay: 300.ms),
              const SizedBox(height: 36),
              if (_isRegister) ...[
                TextField(
                  controller: _nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(hintText: 'Your Name', prefixIcon: Icon(Icons.person_outline, color: AppTheme.primary)),
                ).animate().fadeIn(delay: 350.ms),
                const SizedBox(height: 14),
              ],
              TextField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(hintText: '+91 98765 43210', prefixIcon: Icon(Icons.phone_outlined, color: AppTheme.primary)),
              ).animate().fadeIn(delay: 400.ms),
              const SizedBox(height: 14),
              TextField(
                controller: _passCtrl,
                obscureText: _obscure,
                decoration: InputDecoration(
                  hintText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.primary),
                  suffixIcon: IconButton(
                    icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppTheme.textSecondary),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
              ).animate().fadeIn(delay: 450.ms),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                    : Text(_isRegister ? 'Sign Up' : 'Login'),
              ).animate().fadeIn(delay: 500.ms),
              const SizedBox(height: 20),
              Center(
                child: TextButton(
                  onPressed: () => setState(() => _isRegister = !_isRegister),
                  child: Text(
                    _isRegister ? 'Already have an account? Login' : "Don't have an account? Sign Up",
                    style: const TextStyle(color: AppTheme.primary),
                  ),
                ),
              ).animate().fadeIn(delay: 600.ms),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
