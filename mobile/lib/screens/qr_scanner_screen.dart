import 'package:flutter/material.dart';
import '../utils/deep_link_parser.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  bool _scanned = false;

  void _onDetect(String rawValue) {
    if (_scanned) return;
    final shopId = parseShopIdFromLink(rawValue);
    if (shopId != null) {
      _scanned = true;
      Navigator.pop(context, shopId);
    }
  }

  // Manual entry fallback
  Future<void> _manualEntry() async {
    final ctrl = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Enter Shop ID'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(hintText: 'Shop ID or noqeu://shop/<id>'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final shopId = parseShopIdFromLink(ctrl.text.trim()) ?? ctrl.text.trim();
              Navigator.pop(context, shopId);
            },
            child: const Text('Go'),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty && mounted) {
      Navigator.pop(context, result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR Code'),
        actions: [
          TextButton(onPressed: _manualEntry, child: const Text('Enter ID')),
        ],
      ),
      body: Stack(
        children: [
          // Camera scanner placeholder (mobile_scanner requires native setup)
          Container(
            color: Colors.black,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 240,
                    height: 240,
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFF6C63FF), width: 3),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Center(
                      child: Icon(Icons.qr_code_scanner, size: 80, color: Color(0xFF6C63FF)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text('Point camera at shop QR code', style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 32),
                  OutlinedButton.icon(
                    onPressed: _manualEntry,
                    icon: const Icon(Icons.keyboard_outlined),
                    label: const Text('Enter Shop ID manually'),
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white30)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
