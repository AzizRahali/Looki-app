import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/owner_service_model.dart';
import '../../../data/services/localization_service.dart';
import '../../../logic/blocs/owner_salon/owner_salon_bloc.dart';
import '../../../logic/blocs/owner_salon/owner_salon_event.dart';
import '../../../logic/blocs/owner_salon/owner_salon_state.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/loomea_tokens.dart';
import '../../core/utils/icon_mapper.dart';
import '../../core/widgets/loomea_ui.dart';

class OwnerEditServiceSheet extends StatefulWidget {
  final String salonId;
  final SalonServiceItem service;
  const OwnerEditServiceSheet(
      {super.key, required this.salonId, required this.service});

  @override
  State<OwnerEditServiceSheet> createState() => _OwnerEditServiceSheetState();
}

class _OwnerEditServiceSheetState extends State<OwnerEditServiceSheet> {
  final _formKey     = GlobalKey<FormState>();
  late final TextEditingController _priceCtrl;
  late final TextEditingController _durationCtrl;

  @override
  void initState() {
    super.initState();
    _priceCtrl    = TextEditingController(
        text: widget.service.price.toStringAsFixed(0));
    _durationCtrl = TextEditingController(
        text: '${widget.service.durationMinutes}');
  }

  @override
  void dispose() {
    _priceCtrl.dispose();
    _durationCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    context.read<OwnerSalonBloc>().add(
          UpdateService(widget.salonId, widget.service.id, {
            'name':            widget.service.name,
            'category':        widget.service.category,
            'icon':            widget.service.icon,
            'price':           double.tryParse(_priceCtrl.text) ?? 0,
            'durationMinutes': int.tryParse(_durationCtrl.text) ?? 30,
          }),
        );
  }

  @override
  Widget build(BuildContext context) {
    final svc = widget.service;
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
        child: Form(
          key: _formKey,
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
                  const Icon(Icons.edit_outlined,
                      color: AppColors.textPrimary, size: 20),
                  const SizedBox(width: 10),
                  Text(tr('edit'),
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary)),
                ],
              ),
              const SizedBox(height: 16),

              // Service identity — read-only
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius:
                      BorderRadius.circular(LoomeaTokens.radiusCard),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Icon(iconFromName(svc.icon),
                        size: 18, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(svc.name,
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary)),
                        Text(svc.category,
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Editable fields
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
                    onPressed: saving ? null : _save,
                    child: saving
                        ? const SizedBox(
                            height: 20, width: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.onPrimary))
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.check_rounded, size: 18),
                              const SizedBox(width: 8),
                              Text(tr('save')),
                            ],
                          ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
