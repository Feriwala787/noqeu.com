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

  // Auth
  static Future<Map<String, dynamic>> register(String phone, String password, {String? name}) async {
    final r = await _dio.post('/auth/register', data: {'phone': phone, 'password': password, if (name != null) 'name': name});
    await _storage.write(key: 'token', value: r.data['token']);
    return r.data['user'] as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> login(String phone, String password) async {
    final r = await _dio.post('/auth/login', data: {'phone': phone, 'password': password});
    await _storage.write(key: 'token', value: r.data['token']);
    return r.data['user'] as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>?> getMe() async {
    await _setAuth();
    try {
      final r = await _dio.get('/auth/me');
      return r.data as Map<String, dynamic>;
    } catch (_) { return null; }
  }

  static Future<void> logout() => _storage.delete(key: 'token');

  // Shops
  static Future<List<dynamic>> getAccessedShops() async {
    await _setAuth();
    final r = await _dio.get('/users/me/accessed-shops');
    return r.data as List<dynamic>;
  }

  static Future<List<dynamic>> getMyShops() async {
    await _setAuth();
    final r = await _dio.get('/users/me/shops');
    return r.data as List<dynamic>;
  }

  static Future<Map<String, dynamic>> getNextSlot(String shopId) async {
    final r = await _dio.get('/shops/$shopId/next-slot');
    return r.data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> scanShop(String shopId) async {
    await _setAuth();
    final r = await _dio.post('/shops/$shopId/scan');
    return r.data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> createShop(Map<String, dynamic> data) async {
    await _setAuth();
    final r = await _dio.post('/shops', data: data);
    return r.data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> updateShop(String id, Map<String, dynamic> data) async {
    await _setAuth();
    final r = await _dio.put('/shops/$id', data: data);
    return r.data as Map<String, dynamic>;
  }

  static Future<List<dynamic>> getShopQueue(String shopId) async {
    await _setAuth();
    final r = await _dio.get('/shops/$shopId/queue');
    return r.data as List<dynamic>;
  }

  // Appointments
  static Future<Map<String, dynamic>> book(String shopId) async {
    await _setAuth();
    final r = await _dio.post('/appointments/book', data: {'shopId': shopId});
    return (r.data['appointment'] ?? r.data) as Map<String, dynamic>;
  }

  static Future<void> cancel(String id) async {
    await _setAuth();
    await _dio.put('/appointments/$id/action', data: {'action': 'Cancelled'});
  }

  static Future<Map<String, dynamic>> addWalkIn(String shopId) async {
    await _setAuth();
    final r = await _dio.post('/appointments/offline', data: {'shopId': shopId});
    return (r.data['appointment'] ?? r.data) as Map<String, dynamic>;
  }

  static Future<void> ownerAction(String id, String action) async {
    await _setAuth();
    await _dio.put('/appointments/$id/action', data: {'action': action});
  }

  static Future<List<dynamic>> getMyAppointments() async {
    await _setAuth();
    final r = await _dio.get('/appointments/my');
    return r.data as List<dynamic>;
  }
}
