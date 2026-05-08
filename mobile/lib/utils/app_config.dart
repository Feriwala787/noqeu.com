class AppConfig {
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000/api',
  );

  static const useMockApi = String.fromEnvironment(
    'USE_MOCK_API',
    defaultValue: 'true',
  ) == 'true';
}
