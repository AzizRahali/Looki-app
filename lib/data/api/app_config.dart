/// App-wide configuration.
class AppConfig {
  /// Backend base URL — pick the one that matches your setup:
  ///
  /// Web / Windows / iOS Simulator → localhost
  static const String apiBaseUrl = 'http://localhost:8080';

  /// Android Emulator → 10.0.2.2 maps to host machine
  // static const String apiBaseUrl = 'http://10.0.2.2:8080';

  /// Physical device on same Wi-Fi → use your machine's LAN IP
  // static const String apiBaseUrl = 'http://192.168.1.x:8080';
}
