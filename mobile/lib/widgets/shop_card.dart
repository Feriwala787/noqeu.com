import 'package:flutter/material.dart';
import '../models/shop.dart';

class ShopCard extends StatelessWidget {
  const ShopCard({super.key, required this.shop, required this.onTap});
  final Shop shop;
  final VoidCallback onTap;

  IconData _icon(String occupation) {
    final o = occupation.toLowerCase();
    if (o.contains('barber') || o.contains('hair')) return Icons.content_cut;
    if (o.contains('mechanic') || o.contains('auto')) return Icons.car_repair;
    if (o.contains('doctor') || o.contains('clinic') || o.contains('derm')) return Icons.local_hospital_outlined;
    if (o.contains('salon') || o.contains('beauty')) return Icons.spa_outlined;
    return Icons.store_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E2E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF2E2E42)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF6C63FF).withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(_icon(shop.occupation), color: const Color(0xFF6C63FF), size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(shop.name, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Text(
                    '${shop.occupation} • ${shop.totalSeats} seats • ${shop.avgTimePerCustomer}m avg',
                    style: theme.textTheme.bodyMedium,
                  ),
                  if (shop.address.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(shop.address, style: theme.textTheme.bodyMedium?.copyWith(fontSize: 11)),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: shop.isAcceptingOnline ? const Color(0xFF4CAF50).withOpacity(0.15) : const Color(0xFFFF9800).withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                shop.isAcceptingOnline ? 'Open' : 'Walk-in',
                style: TextStyle(
                  color: shop.isAcceptingOnline ? const Color(0xFF4CAF50) : const Color(0xFFFF9800),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
