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
  String _role = 'customer'; // 'customer' or 'owner'

  Future<void> _submit() async {
    final phone = _phoneCtrl.text.trim();
    final pass = _passCtrl.text.trim();
    if (phone.length < 10) { _snack('Enter valid phone (min 10 digits)'); return; }
    if (pass.length < 6) { _snack('Password must be at least 6 characters'); return; }
    if (_isRegister && _nameCtrl.text.trim().isEmpty) { _snack('Name is required'); return; }

    setState(() => _loading = true);
    try {
      if (_isRegister) {
        await context.read<AppUser>().register(phone: phone, password: pass, name: _nameCtrl.text.trim(), role: _role);
      } else {
        await context.read<AppUser>().login(phone, pass);
      }
    } catch (e) {
      _snack(e.toString());
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
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(height: 50),
            Row(children: [
              Container(width: 52, height: 52, decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppTheme.primary, Color(0xFF9C8FFF)]), borderRadius: BorderRadius.circular(16)),
                child: const Icon(Icons.timer_outlined, color: Colors.white, size: 28)),
              const SizedBox(width: 14),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('NoQeu', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                const Text('Stop Waiting, Start Living', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              ]),
            ]).animate().fadeIn(),
            const SizedBox(height: 40),
            Text(_isRegister ? 'Create Account' : 'Welcome Back', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800))
                .animate().fadeIn(delay: 100.ms),
            const SizedBox(height: 6),
            Text(_isRegister ? 'Choose your account type' : 'Login to continue', style: const TextStyle(color: AppTheme.textSecondary))
                .animate().fadeIn(delay: 150.ms),
            const SizedBox(height: 28),

            // Role selector (only on register)
            if (_isRegister) ...[
              Row(children: [
                Expanded(child: _RoleCard(icon: Icons.person_outline, label: 'Customer', desc: 'Book tokens', selected: _role == 'customer', onTap: () => setState(() => _role = 'customer'))),
                const SizedBox(width: 12),
                Expanded(child: _RoleCard(icon: Icons.store_outlined, label: 'Shop Owner', desc: 'Manage queue', selected: _role == 'owner', onTap: () => setState(() => _role = 'owner'))),
              ]).animate().fadeIn(delay: 200.ms),
              const SizedBox(height: 20),
              TextField(controller: _nameCtrl, textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(hintText: _role == 'owner' ? 'Your Name' : 'Full Name', prefixIcon: const Icon(Icons.person_outline, color: AppTheme.primary))),
              const SizedBox(height: 14),
            ],

            TextField(controller: _phoneCtrl, keyboardType: TextInputType.phone,
              decoration: const InputDecoration(hintText: 'Phone Number', prefixIcon: Icon(Icons.phone_outlined, color: AppTheme.primary)))
                .animate().fadeIn(delay: 250.ms),
            const SizedBox(height: 14),
            TextField(controller: _passCtrl, obscureText: _obscure,
              decoration: InputDecoration(hintText: 'Password', prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.primary),
                suffixIcon: IconButton(icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppTheme.textSecondary), onPressed: () => setState(() => _obscure = !_obscure))))
                .animate().fadeIn(delay: 300.ms),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _loading ? null : _submit,
              child: _loading ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                  : Text(_isRegister ? 'Sign Up' : 'Login'),
            ).animate().fadeIn(delay: 350.ms),
            const SizedBox(height: 16),
            Center(child: TextButton(
              onPressed: () => setState(() { _isRegister = !_isRegister; _role = 'customer'; }),
              child: Text(_isRegister ? 'Already have an account? Login' : "Don't have an account? Sign Up", style: const TextStyle(color: AppTheme.primary)),
            )).animate().fadeIn(delay: 400.ms),
            const SizedBox(height: 40),
          ]),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon; final String label, desc; final bool selected; final VoidCallback onTap;
  const _RoleCard({required this.icon, required this.label, required this.desc, required this.selected, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(onTap: onTap, child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: selected ? AppTheme.primary.withOpacity(0.1) : AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: selected ? AppTheme.primary : Colors.transparent, width: 2),
      ),
      child: Column(children: [
        Icon(icon, color: selected ? AppTheme.primary : AppTheme.textSecondary, size: 28),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: selected ? AppTheme.primary : AppTheme.textPrimary, fontSize: 13)),
        Text(desc, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
      ]),
    ));
  }
}
