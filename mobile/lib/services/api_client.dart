import 'package:dio/dio.dart';
import '../utils/app_config.dart';
import 'auth_interceptor.dart';
import 'auth_service.dart';

class ApiClient {
  ApiClient({String? baseUrl, AuthService? authService})
      : _dio = Dio(BaseOptions(baseUrl: baseUrl ?? AppConfig.apiBaseUrl)) {
    _dio.interceptors.add(AuthInterceptor(authService ?? AuthService()));
  }

  final Dio _dio;

  Future<List<dynamic>> fetchAccessedShops() async {
    final response = await _dio.get('/users/me/accessed-shops');
    return response.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> fetchNextSlot(String shopId) async {
    final response = await _dio.get('/shops/$shopId/next-slot');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> bookAppointment(String shopId) async {
    final response = await _dio.post('/appointments/book', data: {'shopId': shopId});
    return response.data as Map<String, dynamic>;
  }

  Future<void> cancelAppointment(String appointmentId) async {
    await _dio.put('/appointments/$appointmentId/action', data: {'action': 'Cancelled'});
  }

  Future<Map<String, dynamic>> addOfflineWalkIn() async {
    final response = await _dio.post('/appointments/offline');
    return response.data as Map<String, dynamic>;
  }

  Future<void> ownerAction(String appointmentId, String action) async {
    await _dio.put('/appointments/$appointmentId/action', data: {'action': action});
  }
}
