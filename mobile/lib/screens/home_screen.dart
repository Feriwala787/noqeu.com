import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import '../services/api.dart';
import '../theme/app_theme.dart';
import '../widgets/shop_card.dart';
import 'shop_detail_screen.dart';
import 'owner_home_screen.dart';
import 'profile_screen.dart';
import 'scan_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<dynamic> _shops = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try { _shops = await Api.getAccessedShops(); } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _scan() async {
    final shopId = await Navigator.push<String>(context, MaterialPageRoute(builder: (_) => const ScanScreen()));
    if (shopId == null || !mounted) return;
    try { await Api.scanShop(shopId); _load(); } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Shop not found')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppUser>();
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: CustomScrollView(slivers: [
            SliverToBoxAdapter(child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 0),
              child: Row(children: [
                Container(width: 38, height: 38, decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppTheme.primary, Color(0xFF9C8FFF)]), borderRadius: BorderRadius.circular(11)),
                  child: const Icon(Icons.timer_outlined, color: Colors.white, size: 19)),
                const SizedBox(width: 10),
                Text('NoQeu', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                const Spacer(),
                if (user.profile?['isOwner'] == true)
                  IconButton(icon: const Icon(Icons.store_outlined), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OwnerHomeScreen()))),
                IconButton(icon: const Icon(Icons.person_outline), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()))),
              ]),
            )),
            SliverToBoxAdapter(child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
              child: Text('Your Shops', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            )),
            if (_loading)
              SliverList(delegate: SliverChildBuilderDelegate((_, i) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                child: Container(height: 80, decoration: BoxDecoration(color: AppTheme.card, borderRadius: BorderRadius.circular(16)))
                    .animate(onPlay: (c) => c.repeat()).shimmer(duration: 1200.ms, color: AppTheme.surface),
              ), childCount: 3))
            else if (_shops.isEmpty)
              SliverFillRemaining(child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.qr_code_scanner, size: 56, color: AppTheme.primary.withOpacity(0.4)),
                const SizedBox(height: 14),
                Text('No shops yet', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 6),
                const Text('Scan a shop QR to get started', style: TextStyle(color: AppTheme.textSecondary)),
              ])))
            else
              SliverPadding(padding: const EdgeInsets.symmetric(horizontal: 20), sliver: SliverList(delegate: SliverChildBuilderDelegate((_, i) {
                final s = _shops[i] as Map<String, dynamic>;
                return ShopCard(shop: s, onTap: () async {
                  await Navigator.push(context, MaterialPageRoute(builder: (_) => ShopDetailScreen(shop: s)));
                  _load();
                }).animate().fadeIn(delay: Duration(milliseconds: i * 80)).slideY(begin: 0.05);
              }, childCount: _shops.length))),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ]),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _scan, backgroundColor: AppTheme.primary, foregroundColor: Colors.white,
        icon: const Icon(Icons.qr_code_scanner), label: const Text('Scan'),
      ),
    );
  }
}
