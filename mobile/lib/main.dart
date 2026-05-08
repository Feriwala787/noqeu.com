import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'services/api.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(statusBarColor: Colors.transparent));
  runApp(ChangeNotifierProvider(create: (_) => AppUser(), child: const NoQeuApp()));
}

class AppUser extends ChangeNotifier {
  Map<String, dynamic>? profile;
  bool loading = true;

  Future<void> init() async {
    loading = true;
    notifyListeners();
    final t = await Api.token;
    if (t != null) profile = await Api.getMe();
    loading = false;
    notifyListeners();
  }

  Future<void> login(String phone, String password) async {
    profile = await Api.login(phone, password);
    notifyListeners();
  }

  Future<void> register(String phone, String password, {String? name}) async {
    profile = await Api.register(phone, password, name: name);
    notifyListeners();
  }

  Future<void> logout() async {
    await Api.logout();
    profile = null;
    notifyListeners();
  }

  bool get loggedIn => profile != null;
}

class NoQeuApp extends StatefulWidget {
  const NoQeuApp({super.key});
  @override
  State<NoQeuApp> createState() => _NoQeuAppState();
}

class _NoQeuAppState extends State<NoQeuApp> {
  @override
  void initState() {
    super.initState();
    context.read<AppUser>().init();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NoQeu',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: Consumer<AppUser>(
        builder: (_, user, __) {
          if (user.loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
          return user.loggedIn ? const HomeScreen() : const LoginScreen();
        },
      ),
    );
  }
}
