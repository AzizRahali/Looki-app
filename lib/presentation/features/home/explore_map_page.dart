import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../../../data/services/location_service.dart';
import '../../../data/models/salon_model.dart';
import '../../../logic/blocs/salon/salon_bloc.dart';
import '../../../logic/blocs/salon/salon_state.dart';
import '../../core/routes/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/loomea_tokens.dart';
import '../../../data/services/localization_service.dart';

class ExploreMapPage extends StatefulWidget {
  const ExploreMapPage({super.key});

  @override
  State<ExploreMapPage> createState() => _ExploreMapPageState();
}

class _ExploreMapPageState extends State<ExploreMapPage> {
  final MapController _mapController = MapController();
  final TextEditingController _searchCtrl = TextEditingController();

  Salon? _selectedSalon;
  bool _isGeocoding = false;
  String? _geocodeError;
  Timer? _debounce;

  static const _defaultCenter = LatLng(40.7480, -73.9857);
  static const _defaultZoom = 13.0;

  @override
  void initState() {
    super.initState();
    // After first frame the MapController is attached — center on user position.
    WidgetsBinding.instance.addPostFrameCallback((_) => _centerOnUser());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Location ────────────────────────────────────────────────────────────────

  Future<void> _centerOnUser() async {
    var pos = LocationService.instance.currentPosition;
    if (pos == null) {
      pos = await LocationService.instance.requestAndGetLocation();
    }
    if (pos != null && mounted) {
      _mapController.move(pos, _defaultZoom);
    }
  }

  // ── Place geocoding (Nominatim) ──────────────────────────────────────────────

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    if (query.trim().isEmpty) {
      setState(() => _geocodeError = null);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 700), () {
      _geocodeAndNavigate(query.trim());
    });
  }

  Future<void> _geocodeAndNavigate(String query) async {
    setState(() {
      _isGeocoding = true;
      _geocodeError = null;
      _selectedSalon = null;
    });
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/search'
        '?q=${Uri.encodeComponent(query)}&format=json&limit=1',
      );
      final response = await http
          .get(uri, headers: {'User-Agent': 'Loomea/1.0 (com.loomea.app)'})
          .timeout(const Duration(seconds: 8));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List<dynamic>;
        if (data.isNotEmpty) {
          final lat = double.parse(data[0]['lat'] as String);
          final lon = double.parse(data[0]['lon'] as String);
          _mapController.move(LatLng(lat, lon), _defaultZoom);
          setState(() => _isGeocoding = false);
          return;
        }
      }
      setState(() {
        _isGeocoding = false;
        _geocodeError = 'Place not found';
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _isGeocoding = false;
          _geocodeError = 'Search failed';
        });
      }
    }
  }

  void _clearSearch() {
    _debounce?.cancel();
    _searchCtrl.clear();
    setState(() {
      _geocodeError = null;
      _isGeocoding = false;
    });
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocBuilder<SalonBloc, SalonState>(
        builder: (context, state) {
          final salons = state.salons
              .where((s) => s.latitude != 0.0 && s.longitude != 0.0)
              .toList();

          return Stack(
            children: [
              // ── Map ────────────────────────────────────────────────────────
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: LocationService.instance.currentPosition ??
                      _defaultCenter,
                  initialZoom: _defaultZoom,
                  onTap: (_, __) => setState(() => _selectedSalon = null),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.loomea.app',
                    // Desaturate OSM tiles to a muted grey basemap.
                    tileBuilder: (context, tileWidget, tile) => ColorFiltered(
                      colorFilter: const ColorFilter.matrix(<double>[
                        0.2126, 0.7152, 0.0722, 0, 0,
                        0.2126, 0.7152, 0.0722, 0, 0,
                        0.2126, 0.7152, 0.0722, 0, 0,
                        0, 0, 0, 1, 0,
                      ]),
                      child: tileWidget,
                    ),
                  ),
                  // Salon markers
                  MarkerLayer(
                    markers: salons.map((salon) {
                      final isSelected = _selectedSalon?.id == salon.id;
                      return Marker(
                        point: LatLng(salon.latitude, salon.longitude),
                        width: isSelected ? 52 : 42,
                        height: isSelected ? 52 : 42,
                        child: GestureDetector(
                          onTap: () {
                            setState(() => _selectedSalon = salon);
                            _mapController.move(
                              LatLng(salon.latitude, salon.longitude),
                              14.0,
                            );
                          },
                          child: _SalonMarker(isSelected: isSelected),
                        ),
                      );
                    }).toList(),
                  ),
                  // User position marker
                  if (LocationService.instance.currentPosition != null)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: LocationService.instance.currentPosition!,
                          width: 22,
                          height: 22,
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.accent,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.accent.withValues(alpha: 0.4),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),

              // ── Top search bar ─────────────────────────────────────────────
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            // Back button
                            _MapIconButton(
                              icon: Icons.arrow_back_ios_new_rounded,
                              onTap: () => context.pop(),
                            ),
                            const SizedBox(width: 10),
                            // Search field
                            Expanded(
                              child: _SearchBar(
                                controller: _searchCtrl,
                                isGeocoding: _isGeocoding,
                                onChanged: _onSearchChanged,
                                onClear: _clearSearch,
                                salonCount: salons.length,
                              ),
                            ),
                          ],
                        ),
                        // Error hint
                        if (_geocodeError != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8, left: 52),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.error.withValues(alpha: 0.9),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _geocodeError!,
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              // ── My location FAB ────────────────────────────────────────────
              Positioned(
                right: 16,
                bottom: _selectedSalon != null ? 220 : 32,
                child: _MapIconButton(
                  icon: Icons.my_location_rounded,
                  onTap: _centerOnUser,
                ),
              ),

              // ── Salon popup ────────────────────────────────────────────────
              if (_selectedSalon != null)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: _SalonPopupCard(
                        salon: _selectedSalon!,
                        onClose: () => setState(() => _selectedSalon = null),
                        onViewProfile: () => context.pushNamed(
                          AppRoute.salonProfile.name,
                          extra: _selectedSalon!.name,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

// ── Widgets ───────────────────────────────────────────────────────────────────

class _MapIconButton extends StatelessWidget {
  const _MapIconButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: AppColors.background,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, size: 18, color: AppColors.textPrimary),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.isGeocoding,
    required this.onChanged,
    required this.onClear,
    required this.salonCount,
  });

  final TextEditingController controller;
  final bool isGeocoding;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final int salonCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(LoomeaTokens.radiusPill),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 14),
          if (isGeocoding)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: AppColors.primary),
            )
          else
            const Icon(Icons.search_rounded,
                size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              textInputAction: TextInputAction.search,
              style: const TextStyle(
                  fontSize: 14, color: AppColors.textPrimary),
              decoration: InputDecoration(
                isDense: true,
                filled: true,
                fillColor: Colors.transparent,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                hintText: controller.text.isEmpty
                    ? 'Search city, country...'
                    : null,
                hintStyle: const TextStyle(
                    fontSize: 14, color: AppColors.textSecondary),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (controller.text.isNotEmpty)
            GestureDetector(
              onTap: onClear,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Icon(Icons.close_rounded,
                    size: 16, color: AppColors.textSecondary),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Text(
                '$salonCount salons',
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary),
              ),
            ),
        ],
      ),
    );
  }
}

class _SalonMarker extends StatelessWidget {
  const _SalonMarker({required this.isSelected});
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primary : AppColors.background,
        shape: BoxShape.circle,
        border: Border.all(
          color: isSelected ? AppColors.primary : AppColors.border,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(
        Icons.content_cut_rounded,
        size: isSelected ? 22 : 18,
        color: isSelected ? AppColors.onPrimary : AppColors.textPrimary,
      ),
    );
  }
}

class _SalonPopupCard extends StatelessWidget {
  const _SalonPopupCard({
    required this.salon,
    required this.onClose,
    required this.onViewProfile,
  });

  final Salon salon;
  final VoidCallback onClose;
  final VoidCallback onViewProfile;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(LoomeaTokens.radiusCard),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.content_cut_rounded,
                    size: 22, color: AppColors.textPrimary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            salon.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (salon.isVerified) ...[
                          const SizedBox(width: 4),
                          const Icon(Icons.verified_rounded,
                              size: 16, color: AppColors.accent),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      salon.address,
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: onClose,
                child: const Icon(Icons.close_rounded,
                    size: 20, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Meta row
          Row(
            children: [
              _PopupChip(
                icon: Icons.star_rounded,
                label: '${salon.rating}',
                color: AppColors.primary,
                textColor: AppColors.onPrimary,
              ),
              const SizedBox(width: 8),
              _PopupChip(
                icon: Icons.near_me_outlined,
                label: salon.distanceText,
              ),
              const SizedBox(width: 8),
              _PopupChip(
                icon: Icons.schedule_rounded,
                label: salon.openUntil,
                color: AppColors.successBg,
                textColor: AppColors.success,
              ),
            ],
          ),
          if (salon.tags.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: salon.tags
                  .map((tag) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius:
                              BorderRadius.circular(LoomeaTokens.radiusPill),
                        ),
                        child: Text(
                          tag,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ],
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: LoomeaTokens.buttonHeight,
            child: ElevatedButton(
              onPressed: onViewProfile,
              child: const Text('View Salon'),
            ),
          ),
        ],
      ),
    );
  }
}

class _PopupChip extends StatelessWidget {
  const _PopupChip({
    required this.icon,
    required this.label,
    this.color,
    this.textColor,
  });

  final IconData icon;
  final String label;
  final Color? color;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    final bg = color ?? AppColors.inputBackground;
    final fg = textColor ?? AppColors.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600, color: fg)),
        ],
      ),
    );
  }
}
