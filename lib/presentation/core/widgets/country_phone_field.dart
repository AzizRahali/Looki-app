import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../data/services/localization_service.dart';
import '../theme/app_theme.dart';
import '../theme/loomea_tokens.dart';

// ── Country model ─────────────────────────────────────────────────────────────

class Country {
  final String name;
  final String flag;
  final String dialCode;
  const Country(this.name, this.flag, this.dialCode);
}

const kCountries = [
  Country('Algeria', '🇩🇿', '+213'),
  Country('Argentina', '🇦🇷', '+54'),
  Country('Australia', '🇦🇺', '+61'),
  Country('Belgium', '🇧🇪', '+32'),
  Country('Brazil', '🇧🇷', '+55'),
  Country('Canada', '🇨🇦', '+1'),
  Country('China', '🇨🇳', '+86'),
  Country('Egypt', '🇪🇬', '+20'),
  Country('France', '🇫🇷', '+33'),
  Country('Germany', '🇩🇪', '+49'),
  Country('Ghana', '🇬🇭', '+233'),
  Country('India', '🇮🇳', '+91'),
  Country('Indonesia', '🇮🇩', '+62'),
  Country('Italy', '🇮🇹', '+39'),
  Country('Japan', '🇯🇵', '+81'),
  Country('Jordan', '🇯🇴', '+962'),
  Country('Kenya', '🇰🇪', '+254'),
  Country('Malaysia', '🇲🇾', '+60'),
  Country('Mexico', '🇲🇽', '+52'),
  Country('Morocco', '🇲🇦', '+212'),
  Country('Netherlands', '🇳🇱', '+31'),
  Country('New Zealand', '🇳🇿', '+64'),
  Country('Nigeria', '🇳🇬', '+234'),
  Country('Pakistan', '🇵🇰', '+92'),
  Country('Philippines', '🇵🇭', '+63'),
  Country('Poland', '🇵🇱', '+48'),
  Country('Portugal', '🇵🇹', '+351'),
  Country('Qatar', '🇶🇦', '+974'),
  Country('Saudi Arabia', '🇸🇦', '+966'),
  Country('Senegal', '🇸🇳', '+221'),
  Country('South Africa', '🇿🇦', '+27'),
  Country('South Korea', '🇰🇷', '+82'),
  Country('Spain', '🇪🇸', '+34'),
  Country('Sweden', '🇸🇪', '+46'),
  Country('Switzerland', '🇨🇭', '+41'),
  Country('Tunisia', '🇹🇳', '+216'),
  Country('Turkey', '🇹🇷', '+90'),
  Country('UAE', '🇦🇪', '+971'),
  Country('UK', '🇬🇧', '+44'),
  Country('USA', '🇺🇸', '+1'),
];

/// Parses a stored phone string (e.g. "+21612345678") into (Country, localDigits).
/// Falls back to Tunisia if no country code matches.
(Country, String) parseStoredPhone(String phone) {
  if (phone.isEmpty) {
    return (kCountries.firstWhere((c) => c.name == 'Tunisia'), '');
  }
  // Sort by dialCode length descending so longer codes win (e.g. +216 before +21)
  final sorted = [...kCountries]
    ..sort((a, b) => b.dialCode.length.compareTo(a.dialCode.length));
  for (final country in sorted) {
    if (phone.startsWith(country.dialCode)) {
      final local = phone
          .substring(country.dialCode.length)
          .replaceAll(RegExp(r'[\s\-]'), '');
      return (country, local);
    }
  }
  return (kCountries.firstWhere((c) => c.name == 'Tunisia'), phone);
}

// ── CountryPhoneField ─────────────────────────────────────────────────────────

/// Country-code picker button + digits-only text input in one row.
class CountryPhoneField extends StatelessWidget {
  const CountryPhoneField({
    super.key,
    required this.controller,
    required this.selectedCountry,
    required this.onCountryChanged,
    this.onChanged,
    this.autofocus = false,
    this.hintText = '555 123 4567',
  });

  final TextEditingController controller;
  final Country selectedCountry;
  final ValueChanged<Country> onCountryChanged;
  final ValueChanged<String>? onChanged;
  final bool autofocus;
  final String hintText;

  /// Combines dial code + local digits into a single phone string.
  static String fullNumber(Country country, String localDigits) =>
      '${country.dialCode}${localDigits.replaceAll(RegExp(r'\s'), '')}';

  void _pickCountry(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => CountryPickerSheet(
        selected: selectedCountry,
        onPick: (c) {
          onCountryChanged(c);
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: () => _pickCountry(context),
          child: Container(
            height: LoomeaTokens.inputHeight,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.inputBackground,
              borderRadius: BorderRadius.circular(LoomeaTokens.radiusInput),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(selectedCountry.flag,
                    style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 6),
                Text(
                  selectedCountry.dialCode,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.keyboard_arrow_down_rounded,
                    size: 18, color: AppColors.textSecondary),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: SizedBox(
            height: LoomeaTokens.inputHeight,
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              autofocus: autofocus,
              onChanged: onChanged,
              style: const TextStyle(fontSize: 16, color: AppColors.textPrimary),
              decoration: InputDecoration(hintText: hintText),
            ),
          ),
        ),
      ],
    );
  }
}

// ── CountryPickerSheet ────────────────────────────────────────────────────────

class CountryPickerSheet extends StatefulWidget {
  const CountryPickerSheet(
      {super.key, required this.selected, required this.onPick});
  final Country selected;
  final void Function(Country) onPick;

  @override
  State<CountryPickerSheet> createState() => _CountryPickerSheetState();
}

class _CountryPickerSheetState extends State<CountryPickerSheet> {
  final _search = TextEditingController();
  List<Country> _filtered = kCountries;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _onSearch(String q) {
    final lower = q.toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? kCountries
          : kCountries
              .where((c) =>
                  c.name.toLowerCase().contains(lower) ||
                  c.dialCode.contains(q))
              .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.92,
      minChildSize: 0.4,
      expand: false,
      builder: (_, scrollController) => Column(
        children: [
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            tr('select_country'),
            style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _search,
              autofocus: true,
              onChanged: _onSearch,
              decoration: InputDecoration(
                hintText: tr('search_country_hint'),
                prefixIcon: const Icon(Icons.search_rounded,
                    color: AppColors.textSecondary, size: 20),
                filled: true,
                fillColor: AppColors.inputBackground,
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(LoomeaTokens.radiusInput),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1, color: AppColors.border),
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              itemCount: _filtered.length,
              itemBuilder: (_, i) {
                final c = _filtered[i];
                final isSelected = c.dialCode == widget.selected.dialCode &&
                    c.name == widget.selected.name;
                return ListTile(
                  leading:
                      Text(c.flag, style: const TextStyle(fontSize: 24)),
                  title: Text(c.name,
                      style: const TextStyle(
                          fontSize: 15, color: AppColors.textPrimary)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(c.dialCode,
                          style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500)),
                      if (isSelected) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.check_rounded,
                            color: AppColors.primary, size: 18),
                      ],
                    ],
                  ),
                  onTap: () => widget.onPick(c),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
