import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:xml/xml.dart';

class AppLocalizations extends ChangeNotifier {
  AppLocalizations._();
  static final AppLocalizations instance = AppLocalizations._();

  Map<String, String> _strings = {};
  String _locale = 'en';

  String get locale => _locale;

  /// Returns true when the active locale is RTL (Tunisian Darija).
  bool get isRtl => _locale == 'ar_TN';

  static const List<Map<String, String>> supportedLocales = [
    {'code': 'en',    'label': 'English',            'native': 'English',            'flag': '🇬🇧'},
    {'code': 'fr',    'label': 'French',             'native': 'Français',           'flag': '🇫🇷'},
    {'code': 'ar_TN', 'label': 'Tunisian Darija',    'native': 'الدارجة التونسية',   'flag': '🇹🇳'},
  ];

  Future<void> load(String locale) async {
    if (_locale == locale && _strings.isNotEmpty) return;
    _locale = locale;
    try {
      final content = await rootBundle.loadString('assets/l10n/$locale.xml');
      final document = XmlDocument.parse(content);
      _strings = {};
      for (final el in document.findAllElements('string')) {
        final name = el.getAttribute('name');
        if (name != null) {
          _strings[name] = el.innerText;
        }
      }
    } catch (_) {
      if (locale != 'en') await load('en');
    }
    notifyListeners();
  }

  /// Translate [key]. Optionally replace positional placeholders {0}, {1}...
  String tr(String key, {List<String>? args}) {
    String result = _strings[key] ?? key;
    if (args != null) {
      for (int i = 0; i < args.length; i++) {
        result = result.replaceAll('{$i}', args[i]);
      }
    }
    return result;
  }

  static String of(String key, {List<String>? args}) =>
      instance.tr(key, args: args);
}

/// Global shorthand — use `tr('key')` anywhere in the app.
String tr(String key, {List<String>? args}) =>
    AppLocalizations.of(key, args: args);

/// Formats a numeric amount as a localized price string (e.g. "120 TND").
String formatPrice(num amount) =>
    tr('price_amount', args: [amount.toStringAsFixed(0)]);
