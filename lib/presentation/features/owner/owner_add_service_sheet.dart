import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/service_catalog_model.dart';
import '../../../data/services/localization_service.dart';
import '../../../data/repositories/loomea_repository.dart';
import '../../../logic/blocs/owner_salon/owner_salon_bloc.dart';
import '../../../logic/blocs/owner_salon/owner_salon_event.dart';
import '../../../logic/blocs/owner_salon/owner_salon_state.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/loomea_tokens.dart';
import '../../core/utils/icon_mapper.dart';
import '../../core/widgets/loomea_ui.dart';

class OwnerAddServiceSheet extends StatefulWidget {
  final String salonId;
  const OwnerAddServiceSheet({super.key, required this.salonId});

  @override
  State<OwnerAddServiceSheet> createState() => _OwnerAddServiceSheetState();
}

class _OwnerAddServiceSheetState extends State<OwnerAddServiceSheet> {
  // Catalog state
  List<CatalogCategory> _catalog = [];
  bool _catalogLoading = true;

  // Selection state
  CatalogCategory? _selectedCategory;
  CatalogService?  _selectedService;

  // Form
  final _priceCtrl    = TextEditingController();
  final _durationCtrl = TextEditingController();
  final _formKey      = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _loadCatalog();
  }

  Future<void> _loadCatalog() async {
    try {
      final catalog =
          await context.read<LoomeeaRepository>().getServiceCatalog();
      if (mounted) {
        setState(() {
          _catalog = catalog;
          _selectedCategory = catalog.isNotEmpty ? catalog.first : null;
          _catalogLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _catalogLoading = false);
    }
  }

  void _submit() {
    if (_selectedService == null) return;
    if (!_formKey.currentState!.validate()) return;

    context.read<OwnerSalonBloc>().add(AddService(widget.salonId, {
          'name':            _selectedService!.name,
          'category':        _selectedCategory!.category,
          'icon':            _selectedService!.icon,
          'price':           double.tryParse(_priceCtrl.text) ?? 0,
          'durationMinutes': int.tryParse(_durationCtrl.text) ?? 30,
        }));
  }

  @override
  void dispose() {
    _priceCtrl.dispose();
    _durationCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<OwnerSalonBloc, OwnerSalonState>(
      listenWhen: (prev, curr) =>
          prev.status == OwnerSalonStatus.saving &&
          curr.status == OwnerSalonStatus.loaded,
      listener: (_, __) => Navigator.pop(context),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          LoomeaTokens.screenPaddingH,
          16,
          LoomeaTokens.screenPaddingH,
          MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: _catalogLoading
            ? const SizedBox(
                height: 160,
                child: Center(child: CircularProgressIndicator()),
              )
            : _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
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
              children: [
                const Icon(Icons.add_rounded, color: AppColors.textPrimary, size: 20),
                const SizedBox(width: 10),
                Text(tr('add_service'),
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
              ],
            ),
            const SizedBox(height: 20),

            // ── Level 1: Category chips ───────────────────────────────────
            Text(tr('category'),
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _catalog.map((cat) {
                  final selected = _selectedCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(cat.category),
                      avatar: Icon(
                        iconFromName(cat.icon),
                        size: 14,
                        color: selected
                            ? AppColors.onPrimary
                            : AppColors.textSecondary,
                      ),
                      selected: selected,
                      onSelected: (_) => setState(() {
                        _selectedCategory = cat;
                        _selectedService  = null;
                      }),
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: selected
                            ? AppColors.onPrimary
                            : AppColors.textPrimary,
                      ),
                      backgroundColor: AppColors.surface,
                      side: BorderSide(
                        color: selected
                            ? AppColors.primary
                            : AppColors.border,
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // ── Level 2: Services in selected category ────────────────────
            if (_selectedCategory != null) ...[
              Text(
                'Services in ${_selectedCategory!.category}',
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius:
                      BorderRadius.circular(LoomeaTokens.radiusCard),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: _selectedCategory!.services
                      .asMap()
                      .entries
                      .map((entry) {
                    final i   = entry.key;
                    final svc = entry.value;
                    final isSelected = _selectedService == svc;
                    final isLast =
                        i == _selectedCategory!.services.length - 1;

                    return Column(
                      children: [
                        InkWell(
                          borderRadius: BorderRadius.vertical(
                            top: i == 0
                                ? const Radius.circular(
                                    LoomeaTokens.radiusCard)
                                : Radius.zero,
                            bottom: isLast
                                ? const Radius.circular(
                                    LoomeaTokens.radiusCard)
                                : Radius.zero,
                          ),
                          onTap: () =>
                              setState(() => _selectedService = svc),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                            child: Row(
                              children: [
                                Icon(iconFromName(svc.icon),
                                    size: 18,
                                    color: isSelected
                                        ? AppColors.primary
                                        : AppColors.textSecondary),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    svc.name,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                      color: isSelected
                                          ? AppColors.primary
                                          : AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  const Icon(Icons.check_circle_rounded,
                                      size: 18, color: AppColors.primary),
                              ],
                            ),
                          ),
                        ),
                        if (!isLast)
                          Divider(
                              height: 1,
                              color: AppColors.border.withValues(alpha: 0.5)),
                      ],
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // ── Price + Duration ──────────────────────────────────────────
            if (_selectedService != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.06),
                  borderRadius:
                      BorderRadius.circular(LoomeaTokens.radiusCard),
                  border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    Icon(iconFromName(_selectedService!.icon),
                        size: 16, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      _selectedService!.name,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: LoomeaLabeledField(
                      label: tr('service_price'),
                      child: TextFormField(
                        controller: _priceCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration:
                            const InputDecoration(hintText: '0'),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Required';
                          if (double.tryParse(v) == null) return 'Invalid';
                          return null;
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: LoomeaLabeledField(
                      label: tr('service_duration'),
                      child: TextFormField(
                        controller: _durationCtrl,
                        keyboardType: TextInputType.number,
                        decoration:
                            const InputDecoration(hintText: '30'),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Required';
                          if (int.tryParse(v) == null) return 'Invalid';
                          return null;
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              BlocBuilder<OwnerSalonBloc, OwnerSalonState>(
                builder: (context, state) {
                  final saving = state.status == OwnerSalonStatus.saving;
                  return ElevatedButton(
                    onPressed: saving ? null : _submit,
                    child: saving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.onPrimary),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.add_rounded, size: 18),
                              const SizedBox(width: 8),
                              Text(tr('add_service')),
                            ],
                          ),
                  );
                },
              ),
            ] else ...[
              // Placeholder when nothing selected yet
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius:
                      BorderRadius.circular(LoomeaTokens.radiusCard),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.touch_app_rounded,
                        size: 18, color: AppColors.textSecondary),
                    SizedBox(width: 10),
                    Text('Select a service above to set pricing',
                        style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
