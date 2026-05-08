import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  static const _baseUrl = 'https://noqeu-backend.onrender.com/api';
  static const _storage = FlutterSecureStorage();

  final Dio _dio = Dio(BaseOptions(
    baseUrl: _baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  Future<String?> getToken() => _storage.read(key: 'jwt_token');

  Future<void> firebaseLogin(String idToken) async {
    final response = await _dio.post(
      '/auth/firebase-login',
      data: {'token': idToken},
    );
    final jwt = response.data['token'] as String;
    await _storage.write(key: 'jwt_token', value: jwt);
  }

  Future<void> logout() => _storage.delete(key: 'jwt_token');
}
