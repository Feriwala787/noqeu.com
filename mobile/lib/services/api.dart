import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class Api {
  static const baseUrl = 'https://noqeu-backend.onrender.com/api';
  static const _storage = FlutterSecureStorage();
  static final _dio = Dio(BaseOptions(baseUrl: baseUrl, connectTimeout: const Duration(seconds: 15), receiveTimeout: const Duration(seconds: 15)));

  static Future<String?> get token => _storage.read(key: 'token');

  static Future<void> _setAuth() async {
    final t = await token;
    if (t != null) _dio.options.headers['Authorization'] = 'Bearer $t';
  }

  static String _errorMsg(dynamic e) {
    if (e is DioException && e.response?.data != null) {
      final d = e.response!.data;
      if (d is Map) return d['error'] ?? d['errors']?.toString() ?? 'Request failed';
    }
    return e.toString();
  }

  // Auth
  static Future<Map<String, dynamic>> register({required String phone, required String password, required String name, required String role}) async {
    try {
      final r = await _dio.post('/auth/register', data: {'phone': phone, 'password': password, 'name': name, 'role': role});
      await _storage.write(key: 'token', value: r.data['token']);
      return r.data['user'] as Map<String, dynamic>;
    } catch (e) { throw _errorMsg(e); }
  }

  static Future<Map<String, dynamic>> login(String phone, String password) async {
    try {
      final r = await _dio.post('/auth/login', data: {'phone': phone, 'password': password});
      await _storage.write(key: 'token', value: r.data['token']);
      return r.data['user'] as Map<String, dynamic>;
    } catch (e) { throw _errorMsg(e); }
  }

  static Future<Map<String, dynamic>?> getMe() async {
    await _setAuth();
    try { return (await _dio.get('/auth/me')).data as Map<String, dynamic>; } catch (_) { return null; }
  }

  static Future<void> logout() => _storage.delete(key: 'token');

  // Shops
  static Future<List<dynamic>> getAccessedShops() async { await _setAuth(); return (await _dio.get('/users/me/accessed-shops')).data as List; }
  static Future<List<dynamic>> getMyShops() async { await _setAuth(); return (await _dio.get('/users/me/shops')).data as List; }
  static Future<Map<String, dynamic>> getNextSlot(String id) async { return (await _dio.get('/shops/$id/next-slot')).data as Map<String, dynamic>; }
  static Future<Map<String, dynamic>> scanShop(String id) async { await _setAuth(); return (await _dio.post('/shops/$id/scan')).data as Map<String, dynamic>; }
  static Future<Map<String, dynamic>> createShop(Map<String, dynamic> data) async { await _setAuth(); return (await _dio.post('/shops', data: data)).data as Map<String, dynamic>; }
  static Future<Map<String, dynamic>> updateShop(String id, Map<String, dynamic> data) async { await _setAuth(); return (await _dio.put('/shops/$id', data: data)).data as Map<String, dynamic>; }
  static Future<List<dynamic>> getShopQueue(String id) async { await _setAuth(); return (await _dio.get('/shops/$id/queue')).data as List; }

  // Appointments
  static Future<Map<String, dynamic>> book(String shopId, {bool isWalkIn = false}) async { await _setAuth(); final r = await _dio.post('/appointments/book', data: {'shopId': shopId, 'isWalkIn': isWalkIn}); return (r.data['appointment'] ?? r.data) as Map<String, dynamic>; }
  static Future<void> cancel(String id) async { await _setAuth(); await _dio.put('/appointments/$id/action', data: {'action': 'Cancelled'}); }
  static Future<Map<String, dynamic>> addWalkIn(String shopId) async { await _setAuth(); final r = await _dio.post('/appointments/book', data: {'shopId': shopId, 'isWalkIn': true}); return (r.data['appointment'] ?? r.data) as Map<String, dynamic>; }
  static Future<void> ownerAction(String id, String action) async { await _setAuth(); await _dio.put('/appointments/$id/action', data: {'action': action}); }
  static Future<List<dynamic>> getMyAppointments() async { await _setAuth(); return (await _dio.get('/appointments/my')).data as List; }
  static Future<Map<String, dynamic>?> getActiveToken() async { await _setAuth(); final r = await _dio.get('/appointments/active'); return r.data as Map<String, dynamic>?; }
}
