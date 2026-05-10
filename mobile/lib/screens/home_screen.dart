import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
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
  Map<String, dynamic>? _activeToken;
  bool _loading = true;
  Timer? _timer;

  @override
  void initState() { super.initState(); _load(); }
  @override
  void dispose() { _timer?.cancel(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _shops = await Api.getAccessedShops();
      _activeToken = await Api.getActiveToken();
      if (_activeToken != null) _startTimer();
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) { if (mounted) setState(() {}); });
  }

  Future<void> _scan() async {
    final shopId = await Navigator.push<String>(context, MaterialPageRoute(builder: (_) => const ScanScreen()));
    if (shopId == null || !mounted) return;
    try {
      final shop = await Api.scanShop(shopId);
      if (!mounted) return;
      await Navigator.push(context, MaterialPageRoute(builder: (_) => ShopDetailScreen(shop: shop, isWalkIn: true)));
      _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Shop not found')));
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
            // Header
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

            // Active token banner
            if (_activeToken != null)
              SliverToBoxAdapter(child: _ActiveTokenBanner(token: _activeToken!, onTap: () {
                final shopId = _activeToken!['shopId'] is Map ? _activeToken!['shopId']['_id'] : _activeToken!['shopId'];
                final shopName = _activeToken!['shopId'] is Map ? _activeToken!['shopId']['name'] : 'Shop';
                Navigator.push(context, MaterialPageRoute(builder: (_) => ShopDetailScreen(
                  shop: {'_id': shopId, 'name': shopName, 'occupation': '', 'totalSeats': 1, 'avgTimePerCustomer': 30},
                )));
              })),

            // Section title
            SliverToBoxAdapter(child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Text('Your Shops', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            )),

            // Shop list
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
                const Text('Scan a shop QR code to get started', style: TextStyle(color: AppTheme.textSecondary)),
                const SizedBox(height: 20),
                FilledButton.icon(onPressed: _scan, icon: const Icon(Icons.qr_code_scanner), label: const Text('Scan QR Code')),
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
        icon: const Icon(Icons.qr_code_scanner), label: const Text('Scan QR'),
      ),
    );
  }
}

class _ActiveTokenBanner extends StatelessWidget {
  final Map<String, dynamic> token;
  final VoidCallback onTap;
  const _ActiveTokenBanner({required this.token, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final start = DateTime.parse(token['slotStart']);
    final rem = start.difference(DateTime.now());
    final m = rem.inMinutes.clamp(0, 9999);
    final s = (rem.inSeconds % 60).clamp(0, 59);
    final isNow = rem.isNegative;
    final shopName = token['shopId'] is Map ? token['shopId']['name'] ?? 'Shop' : 'Shop';
    final fmt = DateFormat('h:mm a');

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: isNow ? [AppTheme.success, const Color(0xFF66BB6A)] : [AppTheme.primary, const Color(0xFF9C8FFF)]),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(children: [
            Container(width: 44, height: 44, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(12)),
              child: Center(child: Text('#${token['tokenNumber']}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)))),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(isNow ? 'Your turn now!' : 'Active Token', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
              Text('$shopName • ${fmt.format(start)}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ])),
            if (!isNow) Text('${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 20, fontFeatures: [FontFeature.tabularFigures()]))
            else const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 16),
          ]),
        ),
      ).animate().fadeIn().slideY(begin: -0.1),
    );
  }
}
