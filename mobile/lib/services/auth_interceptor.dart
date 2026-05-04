import 'package:dio/dio.dart';
import 'auth_service.dart';

class AuthInterceptor extends Interceptor {
  final AuthService authService;

  AuthInterceptor(this.authService);

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    await authService.refreshTokenIfNeeded();
    final session = await authService.getSession();
    if (session != null && !session.isExpired) {
      options.headers['Authorization'] = 'Bearer ${session.token}';
    }
    handler.next(options);
  }
}
