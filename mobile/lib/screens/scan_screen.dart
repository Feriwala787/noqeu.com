import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ScanScreen extends StatelessWidget {
  const ScanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = TextEditingController();
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Shop')),
      body: Padding(padding: const EdgeInsets.all(24), child: Column(children: [
        const Spacer(),
        Container(width: 200, height: 200, decoration: BoxDecoration(border: Border.all(color: AppTheme.primary, width: 3), borderRadius: BorderRadius.circular(24)),
          child: const Center(child: Icon(Icons.qr_code_scanner, size: 72, color: AppTheme.primary))),
        const SizedBox(height: 20),
        const Text('Point camera at shop QR', style: TextStyle(color: AppTheme.textSecondary)),
        const SizedBox(height: 32),
        const Divider(),
        const SizedBox(height: 16),
        const Text('Or enter Shop ID manually', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
        const SizedBox(height: 12),
        TextField(controller: ctrl, decoration: const InputDecoration(hintText: 'Paste Shop ID here', prefixIcon: Icon(Icons.link))),
        const SizedBox(height: 14),
        FilledButton(onPressed: () {
          final id = ctrl.text.trim();
          if (id.isNotEmpty) Navigator.pop(context, id);
        }, child: const Text('Go')),
        const Spacer(),
      ])),
    );
  }
}
