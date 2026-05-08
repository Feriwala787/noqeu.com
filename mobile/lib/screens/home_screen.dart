import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../models/shop.dart';
import '../services/noqeu_service.dart';
import '../state/auth_provider.dart';
import '../state/app_state.dart';
import '../widgets/shop_card.dart';
import '../widgets/active_token_banner.dart';
import 'otp_login_screen.dart';
import 'shop_detail_screen.dart';
import 'owner_dashboard_screen.dart';
import 'active_token_screen.dart';
import 'profile_screen.dart';
import 'qr_scanner_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Shop>> _shopsFuture;

  @override
  void initState() {
    super.initState();
    _shopsFuture = _loadShops();
    WidgetsBinding.instance.addPostFrameCallback((_) => _handlePendingDeepLink());
  }

  Future<List<Shop>> _loadShops() => context.read<NoQeuService>().getAccessedShops();

  Future<void> _handlePendingDeepLink() async {
    final auth = context.read<AuthProvider>();
    final pendingShop = auth.consumePendingShop();
    if (pendingShop == null) return;

    if (!auth.loggedIn) {
      final ok = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => const OtpLoginScreen()));
      if (ok != true || !mounted) return;
    }

    if (!mounted) return;
    final repo = context.read<NoQeuService>();
    try {
      final shop = await repo.scanShop(pendingShop);
      if (!mounted) return;
      _navigateToShop(shop);
      setState(() => _shopsFuture = _loadShops());
    } catch (_) {}
  }

  void _navigateToShop(Shop shop) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => ShopDetailScreen(shop: shop)));
  }

  Future<void> _scanQr() async {
    final auth = context.read<AuthProvider>();
    if (!auth.loggedIn) {
      final ok = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => const OtpLoginScreen()));
      if (ok != true || !mounted) return;
    }
    if (!mounted) return;
    final shopId = await Navigator.push<String>(context, MaterialPageRoute(builder: (_) => const QrScannerScreen()));
    if (shopId == null || !mounted) return;

    final repo = context.read<NoQeuService>();
    try {
      final shop = await repo.scanShop(shopId);
      if (!mounted) return;
      _navigateToShop(shop);
      setState(() => _shopsFuture = _loadShops());
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Shop not found: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appState = context.watch<AppState>();
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              snap: true,
              title: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF6C63FF), Color(0xFF9C8FFF)]),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.timer_outlined, size: 18, color: Colors.white),
                  ),
                  const SizedBox(width: 10),
                  const Text('NoQeu'),
                ],
              ),
              actions: [
                if (auth.loggedIn && (auth.userProfile?['isOwner'] == true))
                  IconButton(
                    icon: const Icon(Icons.store_outlined),
                    tooltip: 'Owner Dashboard',
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OwnerDashboardScreen())),
                  ),
                IconButton(
                  icon: const Icon(Icons.person_outline),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
                ),
              ],
            ),
            if (appState.activeToken != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: ActiveTokenBanner(
                    appointment: appState.activeToken!,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ActiveTokenScreen(appointment: appState.activeToken!))),
                  ),
                ).animate().fadeIn().slideY(begin: -0.2, end: 0),
              ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Your Shops', style: theme.textTheme.titleLarge),
                    TextButton.icon(
                      onPressed: () => setState(() => _shopsFuture = _loadShops()),
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('Refresh'),
                    ),
                  ],
                ),
              ),
            ),
            FutureBuilder<List<Shop>>(
              future: _shopsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => const _ShopCardSkeleton(),
                      childCount: 3,
                    ),
                  );
                }
                if (snapshot.hasError) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.wifi_off_outlined, size: 48, color: Color(0xFF555555)),
                          const SizedBox(height: 12),
                          Text('Could not load shops', style: theme.textTheme.titleMedium),
                          const SizedBox(height: 4),
                          Text('Check your connection', style: theme.textTheme.bodyMedium),
                          const SizedBox(height: 16),
                          OutlinedButton(
                            onPressed: () => setState(() => _shopsFuture = _loadShops()),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                final shops = snapshot.data ?? [];
                if (shops.isEmpty) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E1E2E),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: const Icon(Icons.qr_code_scanner, size: 40, color: Color(0xFF6C63FF)),
                          ),
                          const SizedBox(height: 20),
                          Text('No shops yet', style: theme.textTheme.titleLarge),
                          const SizedBox(height: 8),
                          Text('Scan a shop QR code to get started', style: theme.textTheme.bodyMedium, textAlign: TextAlign.center),
                          const SizedBox(height: 24),
                          FilledButton.icon(
                            onPressed: _scanQr,
                            icon: const Icon(Icons.qr_code_scanner),
                            label: const Text('Scan QR Code'),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => ShopCard(
                        shop: shops[i],
                        onTap: () => _navigateToShop(shops[i]),
                      ).animate().fadeIn(delay: Duration(milliseconds: i * 80)).slideY(begin: 0.1, end: 0),
                      childCount: shops.length,
                    ),
                  ),
                );
              },
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _scanQr,
        backgroundColor: const Color(0xFF6C63FF),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.qr_code_scanner),
        label: const Text('Scan QR'),
      ),
    );
  }
}

class _ShopCardSkeleton extends StatelessWidget {
  const _ShopCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Container(
        height: 88,
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E2E),
          borderRadius: BorderRadius.circular(16),
        ),
      ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 1200.ms, color: const Color(0xFF2E2E42)),
    );
  }
}
