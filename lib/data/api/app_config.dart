/// App-wide configuration.
class AppConfig {
  /// Backend base URL. Override at build time without editing code:
  /// Web / Windows / iOS Simulator → http://localhost:8080 (default)
  /// Android Emulator              → http://10.0.2.2:8080
  /// Physical device on same Wi-Fi → http://YOUR-LAN-IP:8080
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://looki-service.onrender.com',
  );
}
