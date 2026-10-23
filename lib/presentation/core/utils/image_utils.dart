import '../../../data/api/app_config.dart';

/// Resolves a (possibly relative) image path against the API base URL.
/// Backend returns paths like `/api/portfolio/{id}/image`; those need the
/// host prepended before they can be fetched by [Image.network].
String resolveImageUrl(String raw) {
  if (raw.isEmpty) return raw;
  if (raw.startsWith('http://') || raw.startsWith('https://')) return raw;
  final base = AppConfig.apiBaseUrl;
  if (raw.startsWith('/')) return '$base$raw';
  return '$base/$raw';
}
