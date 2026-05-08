import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthSession {
  final String token;
  final DateTime expiresAt;

  const AuthSession({required this.token, required this.expiresAt});

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

class AuthService {
  static const _tokenKey = 'auth_token';
  static const _expiryKey = 'auth_expiry';
  final _storage = const FlutterSecureStorage();

  Future<AuthSession?> getSession() async {
    final token = await _storage.read(key: _tokenKey);
    final expiry = await _storage.read(key: _expiryKey);
    if (token == null || expiry == null) return null;
    return AuthSession(token: token, expiresAt: DateTime.parse(expiry));
  }

  Future<String?> getToken() async {
    return _storage.read(key: _tokenKey);
  }

  Future<void> saveToken(String token) async {
    final expiresAt = DateTime.now().add(const Duration(days: 30));
    await _storage.write(key: _tokenKey, value: token);
    await _storage.write(key: _expiryKey, value: expiresAt.toIso8601String());
  }

  Future<void> loginWithOtpMock(String phone) async {
    final token = 'mock-token-$phone-${DateTime.now().millisecondsSinceEpoch}';
    await saveToken(token);
  }

  Future<void> refreshTokenIfNeeded() async {
    final session = await getSession();
    if (session == null) return;
    if (session.expiresAt.difference(DateTime.now()).inMinutes <= 5) {
      final refreshed = AuthSession(
        token: '${session.token}-r',
        expiresAt: DateTime.now().add(const Duration(days: 30)),
      );
      await _storage.write(key: _tokenKey, value: refreshed.token);
      await _storage.write(key: _expiryKey, value: refreshed.expiresAt.toIso8601String());
    }
  }

  Future<void> logout() async {
    await _storage.deleteAll();
  }
}
