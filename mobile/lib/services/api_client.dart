import 'package:dio/dio.dart';
import '../utils/app_config.dart';
import 'auth_interceptor.dart';
import 'auth_service.dart';

class ApiClient {
  ApiClient({String? baseUrl, AuthService? authService})
      : _dio = Dio(BaseOptions(
          baseUrl: baseUrl ?? AppConfig.apiBaseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        )) {
    _dio.interceptors.add(AuthInterceptor(authService ?? AuthService()));
  }

  final Dio _dio;

  // Auth
  Future<Map<String, dynamic>> sendOtp(String phone) async {
    final r = await _dio.post('/auth/send-otp', data: {'phone': phone});
    return r.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> verifyOtp(String phone, String otp, {String? fcmToken}) async {
    final r = await _dio.post('/auth/verify-otp', data: {'phone': phone, 'otp': otp, if (fcmToken != null) 'fcmToken': fcmToken});
    return r.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getMe() async {
    final r = await _dio.get('/auth/me');
    return r.data as Map<String, dynamic>;
  }

  // Shops
  Future<List<dynamic>> fetchAccessedShops() async {
    final r = await _dio.get('/users/me/accessed-shops');
    return r.data as List<dynamic>;
  }

  Future<List<dynamic>> fetchMyShops() async {
    final r = await _dio.get('/users/me/shops');
    return r.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> fetchNextSlot(String shopId) async {
    final r = await _dio.get('/shops/$shopId/next-slot');
    return r.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> fetchShop(String shopId) async {
    final r = await _dio.get('/shops/$shopId');
    return r.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createShop(Map<String, dynamic> data) async {
    final r = await _dio.post('/shops', data: data);
    return r.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateShop(String shopId, Map<String, dynamic> data) async {
    final r = await _dio.put('/shops/$shopId', data: data);
    return r.data as Map<String, dynamic>;
  }

  Future<List<dynamic>> fetchShopQueue(String shopId) async {
    final r = await _dio.get('/shops/$shopId/queue');
    return r.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> scanShop(String shopId) async {
    final r = await _dio.post('/shops/$shopId/scan');
    return r.data as Map<String, dynamic>;
  }

  // Appointments
  Future<Map<String, dynamic>> bookAppointment(String shopId) async {
    final r = await _dio.post('/appointments/book', data: {'shopId': shopId});
    return r.data as Map<String, dynamic>;
  }

  Future<void> cancelAppointment(String appointmentId) async {
    await _dio.put('/appointments/$appointmentId/action', data: {'action': 'Cancelled'});
  }

  Future<Map<String, dynamic>> addOfflineWalkIn(String shopId) async {
    final r = await _dio.post('/appointments/offline', data: {'shopId': shopId});
    return r.data as Map<String, dynamic>;
  }

  Future<void> ownerAction(String appointmentId, String action) async {
    await _dio.put('/appointments/$appointmentId/action', data: {'action': action});
  }

  Future<List<dynamic>> fetchMyAppointments() async {
    final r = await _dio.get('/appointments/my');
    return r.data as List<dynamic>;
  }
}
