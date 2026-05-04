import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'state/session_controller.dart';
import 'services/auth_service.dart';
import 'state/app_state.dart';
import 'utils/deep_link_parser.dart';

void main() {
  runApp(const NoQeuApp());
}

class NoQeuApp extends StatefulWidget {
  const NoQeuApp({super.key});

  @override
  State<NoQeuApp> createState() => _NoQeuAppState();
}

class _NoQeuAppState extends State<NoQeuApp> {
  final authService = AuthService();
  late final session = SessionController(authService);
  final appState = AppState();

  @override
  Widget build(BuildContext context) {
    appState.hydrate();
    session.initialize();
    return MaterialApp(
      title: 'NoQeu',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: HomeScreen(session: session, appState: appState, authService: authService),
      onGenerateRoute: (settings) {
        if (settings.name == null) return null;
        final shopId = parseShopIdFromLink(settings.name!);
        if (shopId != null) {
          session.setPendingShop(shopId);
          return MaterialPageRoute(builder: (_) => HomeScreen(session: session, appState: appState, authService: authService));
        }
        return null;
      },
    );
  }
}
