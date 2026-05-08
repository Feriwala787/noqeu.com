import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/api_service.dart';

class UserProvider extends ChangeNotifier {
  final _apiService = ApiService();

  User? _firebaseUser;
  String? _jwtToken;
  bool _loading = false;

  User? get firebaseUser => _firebaseUser;
  String? get jwtToken => _jwtToken;
  bool get loading => _loading;
  bool get isLoggedIn => _firebaseUser != null && _jwtToken != null;

  UserProvider() {
    FirebaseAuth.instance.authStateChanges().listen(_onAuthStateChanged);
  }

  Future<void> _onAuthStateChanged(User? user) async {
    _firebaseUser = user;
    if (user != null) {
      _jwtToken = await _apiService.getToken();
    } else {
      _jwtToken = null;
    }
    notifyListeners();
  }

  Future<void> refreshJwt() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    _loading = true;
    notifyListeners();
    try {
      final idToken = await user.getIdToken(true);
      if (idToken != null) await _apiService.firebaseLogin(idToken);
      _jwtToken = await _apiService.getToken();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
    await _apiService.logout();
    _jwtToken = null;
    notifyListeners();
  }
}
