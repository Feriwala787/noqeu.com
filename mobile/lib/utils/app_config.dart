class AppConfig {
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://noqeu-backend.onrender.com/api',
  );

  static const useMockApi = String.fromEnvironment(
    'USE_MOCK_API',
    defaultValue: 'false',
  ) == 'true';
}
