import 'package:flutter/material.dart';
import '../models/shop.dart';

class ShopCard extends StatelessWidget {
  const ShopCard({super.key, required this.shop, required this.onTap});

  final Shop shop;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(shop.name),
        subtitle: Text('${shop.occupation} • ${shop.totalSeats} seats'),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
