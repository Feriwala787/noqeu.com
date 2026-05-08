import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider(this._authService);

  final AuthService _authService;
  bool _loggedIn = false;
  String? _pendingShopId;
  Map<String, dynamic>? _userProfile;

  bool get loggedIn => _loggedIn;
  String? get pendingShopId => _pendingShopId;
  Map<String, dynamic>? get userProfile => _userProfile;

  Future<void> initialize() async {
    final session = await _authService.getSession();
    _loggedIn = session != null && !session.isExpired;
    notifyListeners();
  }

  Future<void> markLoggedIn(Map<String, dynamic> profile) async {
    _loggedIn = true;
    _userProfile = profile;
    notifyListeners();
  }

  Future<void> logout() async {
    await _authService.logout();
    _loggedIn = false;
    _userProfile = null;
    notifyListeners();
  }

  void setPendingShop(String shopId) {
    _pendingShopId = shopId;
    notifyListeners();
  }

  String? consumePendingShop() {
    final value = _pendingShopId;
    _pendingShopId = null;
    return value;
  }

  AuthService get authService => _authService;
}
