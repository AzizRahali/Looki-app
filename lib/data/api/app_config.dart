/// App-wide configuration.
class AppConfig {
  /// Set to `true` to use local JSON mock data (no backend needed).
  /// Set to `false` to use the Spring Boot backend.
  static const bool useMockData = true;

  /// Backend base URL — pick the one that matches your setup:
  ///
  /// Web / iOS Simulator → localhost
  static const String apiBaseUrl = 'https://looki-backend.onrender.com';

  /// Android Emulator → 10.0.2.2 maps to host machine
  // static const String apiBaseUrl = 'http://10.0.2.2:8080';

  /// Physical device on same Wi-Fi → use your machine's LAN IP
  // static const String apiBaseUrl = 'looki-backend.onrender.com';
}
