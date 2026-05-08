import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ShopCard extends StatelessWidget {
  final Map<String, dynamic> shop;
  final VoidCallback onTap;
  const ShopCard({super.key, required this.shop, required this.onTap});

  IconData _icon(String occ) {
    final o = occ.toLowerCase();
    if (o.contains('barber') || o.contains('hair')) return Icons.content_cut;
    if (o.contains('mechanic') || o.contains('auto')) return Icons.car_repair;
    if (o.contains('doctor') || o.contains('clinic')) return Icons.local_hospital_outlined;
    if (o.contains('salon')) return Icons.spa_outlined;
    return Icons.store_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final accepting = shop['isAcceptingOnline'] as bool? ?? true;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppTheme.card, borderRadius: BorderRadius.circular(16)),
        child: Row(children: [
          Container(width: 48, height: 48, decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.15), borderRadius: BorderRadius.circular(14)),
            child: Icon(_icon(shop['occupation'] ?? ''), color: AppTheme.primary, size: 22)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(shop['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            const SizedBox(height: 2),
            Text('${shop['occupation'] ?? ''} • ${shop['totalSeats']} seats', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
          ])),
          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: (accepting ? AppTheme.success : AppTheme.warning).withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
            child: Text(accepting ? 'Open' : 'Paused', style: TextStyle(color: accepting ? AppTheme.success : AppTheme.warning, fontSize: 11, fontWeight: FontWeight.w600))),
        ]),
      ),
    );
  }
}
