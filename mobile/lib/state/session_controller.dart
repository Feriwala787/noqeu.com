import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';

class SessionController extends ChangeNotifier {
  SessionController(this._authService);

  final AuthService _authService;
  bool _loggedIn = false;
  String? _pendingShopId;

  bool get loggedIn => _loggedIn;
  String? get pendingShopId => _pendingShopId;

  Future<void> initialize() async {
    final session = await _authService.getSession();
    _loggedIn = session != null && !session.isExpired;
    notifyListeners();
  }

  Future<void> markLoggedIn() async {
    final session = await _authService.getSession();
    _loggedIn = session != null && !session.isExpired;
    notifyListeners();
  }

  Future<void> logout() async {
    await _authService.logout();
    _loggedIn = false;
    notifyListeners();
  }

  void setPendingShop(String shopId) {
    _pendingShopId = shopId;
    notifyListeners();
  }

  String? consumePendingShop() {
    final value = _pendingShopId;
    _pendingShopId = null;
    notifyListeners();
    return value;
  }
}
