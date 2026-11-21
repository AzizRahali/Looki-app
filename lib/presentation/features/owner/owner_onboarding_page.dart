import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import '../../../data/services/localization_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';

import '../../../data/repositories/loomea_repository.dart';
import '../../../data/services/location_service.dart';
import '../../../logic/blocs/owner_salon/owner_salon_bloc.dart';
import '../../../logic/blocs/owner_salon/owner_salon_event.dart' show LoadMySalons;
import '../../core/routes/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/loomea_tokens.dart';
import '../../core/widgets/country_phone_field.dart';
import '../../core/widgets/loomea_ui.dart';

/// 4-step owner onboarding: salon details → services → map → image
class OwnerOnboardingPage extends StatefulWidget {
  const OwnerOnboardingPage({super.key});

  @override
  State<OwnerOnboardingPage> createState() => _OwnerOnboardingPageState();
}

class _OwnerOnboardingPageState extends State<OwnerOnboardingPage> {
  int _step = 0;

  // Step 1 — Salon info
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  Country _selectedCountry =
      kCountries.firstWhere((c) => c.name == 'Tunisia');

  // Step 2 — Services
  final List<String> _allCategories = [
    'Hair',
    'Nails',
    'Spa',
    'Barber',
    'Grooming',
    'Lashes',
    'Brows',
    'Makeup',
    'Massage',
    'Waxing',
  ];
  final Set<String> _selectedCategories = {};

  // Step 3 — Location
  LatLng _pickedLocation = const LatLng(40.7128, -74.0060); // default: NYC
  final _mapController = MapController();
  bool _locationReady = false;

  // Step 4 — Gallery image
  Uint8List? _pickedImageBytes;
  String?    _pickedImageBase64;

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    final pos = LocationService.instance.currentPosition
        ?? await LocationService.instance.requestAndGetLocation();
    if (pos != null && mounted) {
      setState(() {
        _pickedLocation = pos;
        _locationReady = true;
      });
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
        source: ImageSource.gallery, imageQuality: 85, maxWidth: 1200);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() {
      _pickedImageBytes  = bytes;
      _pickedImageBase64 = base64Encode(bytes);
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  bool get _step1Valid =>
      _nameController.text.trim().length >= 2 &&
      _addressController.text.trim().isNotEmpty;

  bool get _step2Valid => _selectedCategories.isNotEmpty;

  bool get _step4Valid => true; // image is optional; owner can add it later

  void _next() {
    if (_step < 3) {
      final nextStep = _step + 1;
      setState(() => _step = nextStep);
      // When entering the map step, move to user's location
      if (nextStep == 2 && _locationReady) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _mapController.move(_pickedLocation, 15.0);
        });
      }
    } else {
      _submit();
    }
  }

  void _back() {
    if (_step > 0) setState(() => _step--);
  }

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);
    try {
      final repo = context.read<LoomeeaRepository>();
      final salon = await repo.createSalon({
        'name':        _nameController.text.trim(),
        'description': _descController.text.trim(),
        'address':     _addressController.text.trim(),
        'phone': _phoneController.text.trim().isEmpty
            ? ''
            : CountryPhoneField.fullNumber(
                _selectedCountry, _phoneController.text.trim()),
        'latitude':    _pickedLocation.latitude,
        'longitude':   _pickedLocation.longitude,
        'tags':        _selectedCategories.toList(),
      });
      // Upload image if one was picked
      if (_pickedImageBase64 != null) {
        await repo.uploadSalonImage(salon.id, _pickedImageBase64!);
      }
      if (mounted) {
        context.read<OwnerSalonBloc>().add(const LoadMySalons());
        context.goNamed(AppRoute.ownerHome.name);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppColors.error,
        ));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final steps = [tr('step_label_info'), tr('services'), tr('location'), tr('step_label_image')];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: _step > 0
            ? LoomeaAppBarLeading(onPressed: _back)
            : null,
        title: Text('${tr('setup_salon')} — Step ${_step + 1} of 4'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                children: List.generate(steps.length, (i) {
                  final active = i == _step;
                  final done = i < _step;
                  return Expanded(
                    child: Container(
                      margin: EdgeInsets.only(right: i < steps.length - 1 ? 6 : 0),
                      height: 4,
                      decoration: BoxDecoration(
                        color: done || active
                            ? AppColors.primary
                            : AppColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: steps.asMap().entries.map((e) {
                  final active = e.key == _step;
                  return Text(
                    e.value,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight:
                          active ? FontWeight.w600 : FontWeight.normal,
                      color: active
                          ? AppColors.primary
                          : AppColors.textSecondary,
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: LoomeaTokens.screenPaddingH),
                child: _buildStep(theme),
              ),
            ),
            // Bottom CTA
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: SizedBox(
                width: double.infinity,
                height: LoomeaTokens.buttonHeight,
                child: Builder(builder: (context) {
                  final canProceed = _step == 0
                      ? _step1Valid
                      : _step == 1
                          ? _step2Valid
                          : _step == 3
                              ? _step4Valid
                              : true;
                  return ElevatedButton(
                    onPressed: canProceed && !_isSubmitting ? _next : null,
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : Text(_step < 3 ? tr('continue_btn') : tr('done')),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(ThemeData theme) {
    switch (_step) {
      case 0:
        return _buildStep1(theme);
      case 1:
        return _buildStep2(theme);
      case 2:
        return _buildStep3(theme);
      case 3:
        return _buildStep4(theme);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildStep1(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(tr('step_salon_details'),
            style: theme.textTheme.titleLarge
                ?.copyWith(fontSize: 22, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text(tr('step_salon_details_desc'),
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 24),
        LoomeaLabeledField(
          label: tr('salon_name'),
          child: TextField(
            controller: _nameController,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(hintText: 'e.g. Luna Hair Studio'),
          ),
        ),
        const SizedBox(height: 16),
        LoomeaLabeledField(
          label: tr('description'),
          child: TextField(
            controller: _descController,
            maxLines: 3,
            decoration:
                const InputDecoration(hintText: 'Briefly describe your salon...'),
          ),
        ),
        const SizedBox(height: 16),
        LoomeaLabeledField(
          label: tr('address'),
          child: TextField(
            controller: _addressController,
            onChanged: (_) => setState(() {}),
            decoration:
                const InputDecoration(hintText: '123 Fashion Ave, New York, NY'),
          ),
        ),
        const SizedBox(height: 16),
        LoomeaLabeledField(
          label: tr('phone'),
          child: CountryPhoneField(
            controller: _phoneController,
            selectedCountry: _selectedCountry,
            onCountryChanged: (c) => setState(() => _selectedCountry = c),
            onChanged: (_) => setState(() {}),
            hintText: '55 100 200',
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildStep2(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(tr('step_services_offered'),
            style: theme.textTheme.titleLarge
                ?.copyWith(fontSize: 22, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text(tr('step_services_desc'),
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 24),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _allCategories.map((cat) {
            final selected = _selectedCategories.contains(cat);
            return GestureDetector(
              onTap: () => setState(() {
                if (selected) {
                  _selectedCategories.remove(cat);
                } else {
                  _selectedCategories.add(cat);
                }
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary : AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: selected ? AppColors.primary : AppColors.border,
                  ),
                ),
                child: Text(
                  cat,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: selected ? AppColors.onPrimary : AppColors.textPrimary,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildStep3(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(tr('step_salon_location'),
            style: theme.textTheme.titleLarge
                ?.copyWith(fontSize: 22, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text(tr('step_location_desc'),
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 12),
        if (LocationService.instance.currentPosition != null)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () {
                final pos = LocationService.instance.currentPosition!;
                setState(() => _pickedLocation = pos);
                _mapController.move(pos, 15.0);
              },
              icon: const Icon(Icons.my_location_rounded, size: 16),
              label: Text(tr('my_location')),
            ),
          ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(LoomeaTokens.radiusCard),
          child: SizedBox(
            height: 320,
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _pickedLocation,
                initialZoom: 13,
                onTap: (tapPos, latLng) {
                  setState(() => _pickedLocation = latLng);
                },
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
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _pickedLocation,
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.location_pin,
                        color: AppColors.primary,
                        size: 40,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const Icon(Icons.location_on_outlined,
                size: 16, color: AppColors.textSecondary),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                '${_pickedLocation.latitude.toStringAsFixed(5)}, '
                '${_pickedLocation.longitude.toStringAsFixed(5)}',
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildStep4(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(tr('step_salon_image'),
            style: theme.textTheme.titleLarge
                ?.copyWith(fontSize: 22, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text(tr('step_image_desc'),
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 24),

        // Image picker tap area
        GestureDetector(
          onTap: _pickImage,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(LoomeaTokens.radiusCard),
            child: _pickedImageBytes != null
                ? Stack(
                    children: [
                      Image.memory(
                        _pickedImageBytes!,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                      Positioned(
                        bottom: 10,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.edit_rounded,
                                  size: 14, color: Colors.white),
                              const SizedBox(width: 4),
                              Text(tr('change'),
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.white)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                : Container(
                    height: 200,
                    width: double.infinity,
                    color: AppColors.surface,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.add_photo_alternate_rounded,
                              size: 28, color: AppColors.primary),
                        ),
                        const SizedBox(height: 12),
                        Text(tr('tap_to_choose_gallery'),
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textPrimary)),
                        const SizedBox(height: 4),
                        Text(tr('image_format_hint'),
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(LoomeaTokens.radiusCard),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(tr('summary'),
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              _SummaryRow(
                  label: tr('salon_name'), value: _nameController.text.trim()),
              _SummaryRow(
                  label: tr('address'), value: _addressController.text.trim()),
              _SummaryRow(
                  label: tr('services'),
                  value: _selectedCategories.join(', ')),
              _SummaryRow(
                  label: tr('location'),
                  value:
                      '${_pickedLocation.latitude.toStringAsFixed(4)}, ${_pickedLocation.longitude.toStringAsFixed(4)}'),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : '—',
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
