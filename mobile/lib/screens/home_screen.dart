import 'package:flutter/material.dart';
import '../models/shop.dart';
import '../services/api_client.dart';
import '../services/mock_noqeu_repository.dart';
import '../services/noqeu_repository.dart';
import '../services/noqeu_service.dart';
import '../services/auth_service.dart';
import '../state/session_controller.dart';
import '../state/app_state.dart';
import '../widgets/shop_card.dart';
import 'otp_login_screen.dart';
import 'shop_detail_screen.dart';
import 'owner_dashboard_screen.dart';
import 'active_token_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.session, required this.appState, required this.authService});

  final SessionController session;
  final AppState appState;
  final AuthService authService;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _repo = NoQeuService(NoQeuRepository(ApiClient()), MockNoQeuRepository());
  late Future<List<Shop>> _shopsFuture;

  @override
  void initState() {
    super.initState();
    _shopsFuture = _repo.getAccessedShops();
    WidgetsBinding.instance.addPostFrameCallback((_) => _handlePendingDeepLink());
  }

  Future<void> _handlePendingDeepLink() async {
    final pendingShop = widget.session.consumePendingShop();
    if (pendingShop == null) return;

    if (!widget.session.loggedIn) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => OtpLoginScreen(session: widget.session, authService: widget.authService)),
      );
      if (!widget.session.loggedIn) return;
    }

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ShopDetailScreen(
          shop: Shop(
            id: pendingShop,
            name: 'Scanned Shop',
            occupation: 'Service',
            totalSeats: 1,
            avgTimePerCustomer: 30,
            isAcceptingOnline: true,
          ),
          repo: _repo,
          appState: widget.appState,
        ),
      ),
    );
  }

  Future<void> _refresh() async {
    setState(() {
      _shopsFuture = _repo.getAccessedShops();
    });
    await _shopsFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NoQeu - Your Shops'),
        actions: [
          IconButton(
            icon: const Icon(Icons.badge),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => OwnerDashboardScreen(repo: _repo)),
            ),
          ),
          if (widget.appState.activeToken != null)
            IconButton(
              icon: const Icon(Icons.timer),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ActiveTokenScreen(appointment: widget.appState.activeToken!, repo: _repo, appState: widget.appState),
                ),
              ),
            ),
        ],
      ),
      body: FutureBuilder<List<Shop>>(
        future: _shopsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Failed to load shops: ${snapshot.error}'),
                  const SizedBox(height: 12),
                  OutlinedButton(onPressed: _refresh, child: const Text('Retry')),
                ],
              ),
            );
          }
          final shops = snapshot.data ?? const [];
          if (shops.isEmpty) {
            return const Center(child: Text('Scan a shop QR to get started.'));
          }
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              itemCount: shops.length,
              itemBuilder: (_, index) => ShopCard(
                shop: shops[index],
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ShopDetailScreen(shop: shops[index], repo: _repo, appState: widget.appState),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
