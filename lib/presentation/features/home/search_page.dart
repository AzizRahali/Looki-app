import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../data/services/localization_service.dart';

import '../../../data/models/salon_model.dart';
import '../../../data/models/smart_search_model.dart';
import '../../core/utils/image_utils.dart';
import '../../../logic/blocs/profile/profile_bloc.dart';
import '../../../logic/blocs/profile/profile_event.dart';
import '../../../logic/blocs/profile/profile_state.dart';
import '../../../logic/blocs/search/search_bloc.dart';
import '../../../logic/blocs/search/search_event.dart';
import '../../../logic/blocs/search/search_state.dart';

// ignore_for_file: use_build_context_synchronously
import '../../core/routes/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/loomea_tokens.dart';
import '../../core/widgets/loomea_ui.dart';

enum _SortMode { none, priceLow, priceHigh, distance, rating }

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _controller = TextEditingController();
  _SortMode _sortMode = _SortMode.none;

  // Active filters
  double _minRating = 0;   // 0 = no filter
  double _maxPrice = 0;    // 0 = no filter
  final Set<String> _selectedCategories = {};

  @override
  void initState() {
    super.initState();
    context.read<SearchBloc>().add(const SearchSalons(''));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int get _activeFilterCount =>
      (_minRating > 0 ? 1 : 0) +
      (_maxPrice > 0 ? 1 : 0) +
      _selectedCategories.length;

  List<Salon> _applyFilters(List<Salon> salons) {
    return salons.where((s) {
      if (_minRating > 0 && s.rating < _minRating) return false;
      if (_maxPrice > 0) {
        final minPrice = s.services.isEmpty
            ? 0.0
            : s.services.map((sv) => sv.price).reduce((a, b) => a < b ? a : b);
        if (minPrice > _maxPrice) return false;
      }
      if (_selectedCategories.isNotEmpty) {
        final hasCat = s.categories.any(_selectedCategories.contains) ||
            s.tags.any(_selectedCategories.contains);
        if (!hasCat) return false;
      }
      return true;
    }).toList();
  }

  void _openFilterSheet(BuildContext context, List<Salon> allResults) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _FilterSheet(
        allSalons: allResults,
        minRating: _minRating,
        maxPrice: _maxPrice,
        selectedCategories: Set.from(_selectedCategories),
        onApply: (rating, price, cats) {
          setState(() {
            _minRating = rating;
            _maxPrice = price;
            _selectedCategories
              ..clear()
              ..addAll(cats);
          });
        },
      ),
    );
  }

  List<Salon> _applySorting(List<Salon> salons) {
    final sorted = List<Salon>.from(salons);
    switch (_sortMode) {
      case _SortMode.priceLow:
        sorted.sort((a, b) {
          final aMin = a.services.isEmpty
              ? 0.0
              : a.services.map((s) => s.price).reduce((a, b) => a < b ? a : b);
          final bMin = b.services.isEmpty
              ? 0.0
              : b.services.map((s) => s.price).reduce((a, b) => a < b ? a : b);
          return aMin.compareTo(bMin);
        });
      case _SortMode.priceHigh:
        sorted.sort((a, b) {
          final aMin = a.services.isEmpty
              ? 0.0
              : a.services.map((s) => s.price).reduce((a, b) => a < b ? a : b);
          final bMin = b.services.isEmpty
              ? 0.0
              : b.services.map((s) => s.price).reduce((a, b) => a < b ? a : b);
          return bMin.compareTo(aMin);
        });
      case _SortMode.distance:
        sorted.sort((a, b) => a.distance.compareTo(b.distance));
      case _SortMode.rating:
        sorted.sort((a, b) => b.rating.compareTo(a.rating));
      case _SortMode.none:
        break;
    }
    return sorted;
  }

  Future<void> _pickAvailability(BuildContext context) async {
    final now = DateTime.now();
    // Pick time
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: now.hour, minute: 0),
    );
    if (picked == null) return;
    final date =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final time =
        '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    context.read<SearchBloc>().add(SearchAvailability(date: date, time: time));
  }

  void _clearAvailability(BuildContext context) {
    context.read<SearchBloc>().add(SearchSalons(_controller.text));
  }

  void _runSmartSearch(BuildContext context) {
    final query = _controller.text.trim();
    if (query.isEmpty) return;
    FocusScope.of(context).unfocus();
    context.read<SearchBloc>().add(SmartSearch(query));
  }

  void _onFilterTap(String label) {
    setState(() {
      switch (label) {
        case 'Price':
          if (_sortMode == _SortMode.priceLow) {
            _sortMode = _SortMode.priceHigh;
          } else if (_sortMode == _SortMode.priceHigh) {
            _sortMode = _SortMode.none;
          } else {
            _sortMode = _SortMode.priceLow;
          }
        case 'Distance':
          _sortMode =
              _sortMode == _SortMode.distance ? _SortMode.none : _SortMode.distance;
        case 'Rating':
          _sortMode =
              _sortMode == _SortMode.rating ? _SortMode.none : _SortMode.rating;
      }
    });
  }

  String _filterSublabel(String label) {
    switch (label) {
      case 'Price':
        if (_sortMode == _SortMode.priceLow) return 'Low–High';
        if (_sortMode == _SortMode.priceHigh) return 'High–Low';
        return '';
      case 'Distance':
        return _sortMode == _SortMode.distance ? 'Nearest' : '';
      case 'Rating':
        return _sortMode == _SortMode.rating ? 'Highest' : '';
      default:
        return '';
    }
  }

  bool _isFilterActive(String label) {
    switch (label) {
      case 'Price':
        return _sortMode == _SortMode.priceLow ||
            _sortMode == _SortMode.priceHigh;
      case 'Distance':
        return _sortMode == _SortMode.distance;
      case 'Rating':
        return _sortMode == _SortMode.rating;
      default:
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: LoomeaAppBarLeading(onPressed: () => context.pop()),
        title: Text(
          tr('search'),
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search input
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: LoomeaTokens.screenPaddingH),
              child: TextField(
                controller: _controller,
                autofocus: true,
                textInputAction: TextInputAction.search,
                onChanged: (value) {
                  context.read<SearchBloc>().add(SearchSalons(value));
                },
                onSubmitted: (_) => _runSmartSearch(context),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search_rounded,
                      color: AppColors.textSecondary),
                  suffixIcon: IconButton(
                    tooltip: tr('smart_search'),
                    icon: const Icon(Icons.auto_awesome_rounded,
                        color: AppColors.primary),
                    onPressed: () => _runSmartSearch(context),
                  ),
                  hintText: tr('smart_search_hint'),
                ),
              ),
            ),
            BlocBuilder<SearchBloc, SearchState>(
              builder: (context, searchState) => _SmartSearchSummary(
                state: searchState,
                onClear: () => context
                    .read<SearchBloc>()
                    .add(SearchSalons(_controller.text)),
              ),
            ),
            const SizedBox(height: LoomeaTokens.gapMd),
            // Filter chips
            BlocBuilder<SearchBloc, SearchState>(
              builder: (context, searchState) => SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                    horizontal: LoomeaTokens.screenPaddingH),
                child: Row(
                  children: [
                    _FiltersButton(
                      count: _activeFilterCount,
                      onTap: () => _openFilterSheet(context, searchState.results),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Price',
                      sublabel: _filterSublabel('Price'),
                      isActive: _isFilterActive('Price'),
                      onTap: () => _onFilterTap('Price'),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Distance',
                      sublabel: _filterSublabel('Distance'),
                      isActive: _isFilterActive('Distance'),
                      onTap: () => _onFilterTap('Distance'),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Rating',
                      sublabel: _filterSublabel('Rating'),
                      isActive: _isFilterActive('Rating'),
                      onTap: () => _onFilterTap('Rating'),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Available at',
                      sublabel: searchState.isAvailabilityMode
                          ? searchState.availabilityTime ?? ''
                          : '',
                      isActive: searchState.isAvailabilityMode,
                      onTap: () => searchState.isAvailabilityMode
                          ? _clearAvailability(context)
                          : _pickAvailability(context),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: LoomeaTokens.gapLg),
            // Results
            Expanded(
              child: BlocBuilder<SearchBloc, SearchState>(
                builder: (context, state) {
                  if (state.status == SearchStatus.loading) {
                    if (state.isSmartMode) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(),
                            const SizedBox(height: LoomeaTokens.gapMd),
                            Text(
                              tr('smart_search_loading'),
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state.results.isEmpty && state.status == SearchStatus.loaded) {
                    return Center(
                      child: Text(
                        state.isAvailabilityMode
                            ? 'No salons available at ${state.availabilityTime}'
                            : tr('no_results'),
                        style: const TextStyle(
                          fontSize: 16,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    );
                  }

                  final sorted = _applySorting(_applyFilters(state.results));

                  return BlocBuilder<ProfileBloc, ProfileState>(
                    builder: (context, profileState) {
                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(
                            horizontal: LoomeaTokens.screenPaddingH),
                        itemCount: sorted.length,
                        itemBuilder: (context, index) {
                          final salon = sorted[index];
                          final isSaved =
                              profileState.isSalonSaved(salon.id);
                          return _SearchResultCard(
                            salon: salon,
                            isSaved: isSaved,
                            onFavorite: () => context
                                .read<ProfileBloc>()
                                .add(ToggleSavedSalon(salon.id)),
                            onTap: () => context.pushNamed(
                              AppRoute.salonProfile.name,
                              extra: salon.name,
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SmartSearchSummary extends StatelessWidget {
  const _SmartSearchSummary({required this.state, required this.onClear});

  final SearchState state;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    if (!state.isSmartMode || state.status != SearchStatus.loaded) {
      return const SizedBox.shrink();
    }
    final filters = state.smartFilters;
    if (!state.aiUsed || filters == null || filters.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(LoomeaTokens.screenPaddingH, 8,
            LoomeaTokens.screenPaddingH, 0),
        child: Text(
          tr(state.aiUsed ? 'smart_search_no_filters' : 'smart_search_fallback'),
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      );
    }

    final chips = <(IconData, String)>[
      if (filters.service != null || filters.category != null)
        (Icons.spa_outlined, (filters.service ?? filters.category)!),
      if (filters.location != null) (Icons.place_outlined, filters.location!),
      if (filters.maxPrice != null)
        (
          Icons.payments_outlined,
          tr('smart_filter_max_price', args: [formatPrice(filters.maxPrice!)])
        ),
      if (filters.date != null)
        (Icons.event_outlined, _formatWhen(filters)),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          LoomeaTokens.screenPaddingH, 10, LoomeaTokens.screenPaddingH, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Icon(Icons.auto_awesome_rounded,
                size: 16, color: AppColors.primary),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final (icon, label) in chips)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius:
                          BorderRadius.circular(LoomeaTokens.radiusPill),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon, size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          label,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          TextButton(
            onPressed: onClear,
            child: Text(tr('smart_search_clear')),
          ),
        ],
      ),
    );
  }

  static String _formatWhen(SmartSearchFilters filters) {
    final date = DateTime.tryParse(filters.date!);
    final today = DateUtils.dateOnly(DateTime.now());
    String day;
    if (date == null) {
      day = filters.date!;
    } else if (date == today) {
      day = tr('smart_today');
    } else if (date == today.add(const Duration(days: 1))) {
      day = tr('smart_tomorrow');
    } else {
      day =
          '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
    }
    final from = filters.timeFrom;
    final to = filters.timeTo;
    if (from == null) return day;
    return from == to ? '$day · $from' : '$day · $from–$to';
  }
}

class _FiltersButton extends StatelessWidget {
  const _FiltersButton({required this.count, required this.onTap});
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isActive = count > 0;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(LoomeaTokens.radiusPill),
          border: Border.all(color: isActive ? AppColors.primary : AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.tune_rounded,
                size: 15, color: isActive ? AppColors.onPrimary : AppColors.textPrimary),
            const SizedBox(width: 6),
            Text(
              isActive ? 'Filters ($count)' : 'Filters',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isActive ? AppColors.onPrimary : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroStack extends StatelessWidget {
  const _HeroStack({
    required this.salonId,
    required this.imageUrl,
    required this.isSaved,
    required this.rating,
    required this.reviewCount,
    required this.onFavorite,
  });

  final String salonId;
  final String imageUrl;
  final bool isSaved;
  final double rating;
  final int reviewCount;
  final VoidCallback onFavorite;

  @override
  Widget build(BuildContext context) {
    final resolvedUrl = imageUrl.isEmpty ? '' : resolveImageUrl(imageUrl);

    return SizedBox(
      height: 160,
      child: Stack(
        fit: StackFit.expand,
        children: [
          resolvedUrl.isNotEmpty
              ? Image.network(
                  resolvedUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      SalonImagePlaceholder(salonId: salonId),
                )
              : SalonImagePlaceholder(salonId: salonId),
          Positioned(
            top: 10,
            right: 10,
            child: GestureDetector(
              onTap: onFavorite,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.background.withValues(alpha: 0.9),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isSaved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  size: 18,
                  color: isSaved ? AppColors.error : AppColors.textPrimary,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 10,
            left: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.background.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star_rounded, size: 14, color: Color(0xFFFFC107)),
                  const SizedBox(width: 2),
                  Text(
                    '$rating ($reviewCount)',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TagsRow extends StatelessWidget {
  const _TagsRow({required this.tags, required this.onTap});
  final List<String> tags;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Wrap(
            spacing: 6,
            children: tags
                .map((t) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.inputBackground,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        t,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ))
                .toList(),
          ),
        ),
        Container(
          width: 36,
          height: 35,
          decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
          child: IconButton(
            onPressed: onTap,
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.arrow_forward_rounded, size: 18, color: AppColors.onPrimary),
          ),
        ),
      ],
    );
  }
}

class _OptionChip extends StatelessWidget {
  const _OptionChip({required this.label, required this.isActive, required this.onTap});
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(LoomeaTokens.radiusPill),
          border: Border.all(color: isActive ? AppColors.primary : AppColors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isActive ? AppColors.onPrimary : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    this.sublabel = '',
    this.isActive = false,
    this.onTap,
  });

  final String label;
  final String sublabel;
  final bool isActive;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(LoomeaTokens.radiusPill),
          border: Border.all(
            color: isActive ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              sublabel.isNotEmpty ? '$label: $sublabel' : label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isActive ? AppColors.onPrimary : AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              isActive
                  ? Icons.close_rounded
                  : Icons.keyboard_arrow_down_rounded,
              size: 16,
              color: isActive ? AppColors.onPrimary : AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchResultCard extends StatelessWidget {
  const _SearchResultCard({
    required this.salon,
    required this.isSaved,
    required this.onFavorite,
    required this.onTap,
  });

  final Salon salon;
  final bool isSaved;
  final VoidCallback onFavorite;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final servicesSummary =
        salon.services.take(2).map((s) => s.name).join(', ');
    final tags =
        salon.services.take(3).map((s) => s.category).toSet().toList();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(LoomeaTokens.radiusCard),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _HeroStack(
                  salonId: salon.id,
                  imageUrl: salon.imageUrl,
                  isSaved: isSaved,
                  rating: salon.rating,
                  reviewCount: salon.reviewCount,
                  onFavorite: onFavorite,
                ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            salon.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.location_on_outlined,
                                size: 14, color: AppColors.textSecondary),
                            const SizedBox(width: 2),
                            Text(
                              salon.distanceText,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      servicesSummary,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _TagsRow(tags: tags, onTap: onTap),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Filter bottom sheet ───────────────────────────────────────────────────────

class _FilterSheet extends StatefulWidget {
  final List<Salon> allSalons;
  final double minRating;
  final double maxPrice;
  final Set<String> selectedCategories;
  final void Function(double rating, double price, Set<String> cats) onApply;

  const _FilterSheet({
    required this.allSalons,
    required this.minRating,
    required this.maxPrice,
    required this.selectedCategories,
    required this.onApply,
  });

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late double _minRating;
  late double _maxPrice;
  late Set<String> _selectedCategories;

  static const _ratingOptions = [0.0, 3.0, 4.0, 4.5];
  static const _priceOptions = [0.0, 50.0, 100.0, 200.0];
  static const _priceLabels = ['Any', 'Under \$50', 'Under \$100', 'Under \$200'];

  @override
  void initState() {
    super.initState();
    _minRating = widget.minRating;
    _maxPrice = widget.maxPrice;
    _selectedCategories = Set.from(widget.selectedCategories);
  }

  Set<String> get _allCategories {
    final cats = <String>{};
    for (final s in widget.allSalons) {
      cats.addAll(s.categories);
      cats.addAll(s.tags);
    }
    return cats;
  }

  @override
  Widget build(BuildContext context) {
    final cats = _allCategories.toList()..sort();
    return Padding(
      padding: EdgeInsets.only(
        left: LoomeaTokens.screenPaddingH,
        right: LoomeaTokens.screenPaddingH,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Filters',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              TextButton(
                onPressed: () => setState(() {
                  _minRating = 0;
                  _maxPrice = 0;
                  _selectedCategories.clear();
                }),
                child: const Text('Reset',
                    style: TextStyle(color: AppColors.textSecondary)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Minimum Rating',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: _ratingOptions.map((r) {
              final label = r == 0 ? 'Any' : '$r★+';
              return _OptionChip(
                label: label,
                isActive: _minRating == r,
                onTap: () => setState(() => _minRating = r),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          const Text('Max Price',
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: List.generate(_priceOptions.length, (i) {
              return _OptionChip(
                label: _priceLabels[i],
                isActive: _maxPrice == _priceOptions[i],
                onTap: () => setState(() => _maxPrice = _priceOptions[i]),
              );
            }),
          ),
          if (cats.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(tr('category'),
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: cats.map((c) {
                final active = _selectedCategories.contains(c);
                return _OptionChip(
                  label: c,
                  isActive: active,
                  onTap: () => setState(() {
                    if (active) {
                      _selectedCategories.remove(c);
                    } else {
                      _selectedCategories.add(c);
                    }
                  }),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: LoomeaTokens.buttonHeight,
            child: ElevatedButton(
              onPressed: () {
                widget.onApply(_minRating, _maxPrice, _selectedCategories);
                Navigator.pop(context);
              },
              child: const Text('Apply Filters'),
            ),
          ),
        ],
      ),
    );
  }
}
