import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'screens/splash_screen.dart';
import 'state/app_state.dart';
import 'state/auth_provider.dart';
import 'services/api_client.dart';
import 'services/auth_service.dart';
import 'services/noqeu_service.dart';
import 'services/mock_noqeu_repository.dart';
import 'services/noqeu_repository.dart';
import 'theme/app_theme.dart';
import 'utils/deep_link_parser.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(const NoQeuApp());
}

class NoQeuApp extends StatelessWidget {
  const NoQeuApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final apiClient = ApiClient(authService: authService);
    final repo = NoQeuService(NoQeuRepository(apiClient), MockNoQeuRepository());

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider(authService)),
        ChangeNotifierProvider(create: (_) => AppState()),
        Provider<NoQeuService>.value(value: repo),
      ],
      child: MaterialApp(
        title: 'NoQeu',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        home: const SplashScreen(),
        onGenerateRoute: (settings) {
          if (settings.name == null) return null;
          final shopId = parseShopIdFromLink(settings.name!);
          if (shopId != null) {
            return MaterialPageRoute(
              builder: (ctx) {
                context.read<AuthProvider>().setPendingShop(shopId);
                return const HomeScreen();
              },
            );
          }
          return null;
        },
      ),
    );
  }
}
