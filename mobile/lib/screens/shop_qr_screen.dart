import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../theme/app_theme.dart';

class ShopQrScreen extends StatelessWidget {
  final Map<String, dynamic> shop;
  const ShopQrScreen({super.key, required this.shop});

  String get _shopId => (shop['_id'] ?? shop['id']) as String;
  String get _qrData => 'https://noqeu.com/shop/$_shopId';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Shop QR')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(shop['name'] ?? 'Shop', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text(shop['occupation'] ?? '', style: const TextStyle(color: AppTheme.textSecondary)),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: AppTheme.primary.withOpacity(0.2), blurRadius: 30, spreadRadius: 5)],
                ),
                child: QrImageView(
                  data: _qrData,
                  version: QrVersions.auto,
                  size: 220,
                  backgroundColor: Colors.white,
                  eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.roundedOuter, color: Color(0xFF1A1A2E)),
                  dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.roundedOutsideCorners, color: Color(0xFF1A1A2E)),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(12)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.link, size: 16, color: AppTheme.textSecondary),
                    const SizedBox(width: 8),
                    Flexible(child: Text(_qrData, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12), overflow: TextOverflow.ellipsis)),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text('Shop ID: $_shopId', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: _shopId));
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Shop ID copied!')));
                    },
                    icon: const Icon(Icons.copy, size: 18),
                    label: const Text('Copy ID'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: () => Share.share('Join my queue on NoQeu!\n\nShop: ${shop['name']}\nLink: $_qrData\n\nOr use Shop ID: $_shopId'),
                    icon: const Icon(Icons.share, size: 18),
                    label: const Text('Share'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text('Print this QR and display at your shop.\nCustomers scan it to join your queue.', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}
