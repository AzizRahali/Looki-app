/// App-wide configuration.
class AppConfig {
  /// Override with `--dart-define=USE_MOCK_DATA=false` to use the backend.
  static const bool useMockData =
      bool.fromEnvironment('USE_MOCK_DATA', defaultValue: true);

  /// Override with `--dart-define=API_BASE_URL=<backend URL>`.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://looki-backend.onrender.com',
  );
}
