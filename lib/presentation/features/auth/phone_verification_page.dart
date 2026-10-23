import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/services/localization_service.dart';
import '../../../logic/blocs/auth/auth_bloc.dart';
import '../../../logic/blocs/auth/auth_event.dart';
import '../../../logic/blocs/auth/auth_state.dart';
import '../../core/routes/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/loomea_tokens.dart';
import '../../core/widgets/country_phone_field.dart';
import '../../core/widgets/loomea_ui.dart';
import 'package:go_router/go_router.dart';

// ── Page ─────────────────────────────────────────────────────────────────────

class PhoneVerificationPage extends StatefulWidget {
  const PhoneVerificationPage({
    super.key,
    required this.email,
    required this.role,
  });

  final String email;
  final String role;

  @override
  State<PhoneVerificationPage> createState() => _PhoneVerificationPageState();
}

class _PhoneVerificationPageState extends State<PhoneVerificationPage> {
  final _phoneController = TextEditingController();
  Country _selectedCountry = kCountries.firstWhere((c) => c.name == 'Tunisia');

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  bool get _isValid => _phoneController.text.trim().length >= 6;

  void _pickCountry() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => CountryPickerSheet(
        selected: _selectedCountry,
        onPick: (c) {
          setState(() => _selectedCountry = c);
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: LoomeaAppBarLeading(onPressed: () => context.pop()),
      ),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state.status == AuthStatus.pendingVerification &&
              state.pendingPhone.isNotEmpty) {
            context.pushNamed(
              AppRoute.otpVerification.name,
              extra: {
                'email': widget.email,
                'phone': state.pendingPhone,
                'role': widget.role,
              },
            );
          } else if (state.status == AuthStatus.error) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(state.error),
              backgroundColor: AppColors.error,
            ));
          }
        },
        builder: (context, state) {
          final isLoading = state.status == AuthStatus.loading;
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: LoomeaTokens.screenPaddingH),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 8),
                  // ── Icon ─────────────────────────────────────────────────
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.phone_android_rounded,
                        color: AppColors.primary, size: 28),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    tr('add_phone_number'),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    tr('phone_desc'),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 15,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 32),
                  // ── Phone input ──────────────────────────────────────────
                  CountryPhoneField(
                    controller: _phoneController,
                    selectedCountry: _selectedCountry,
                    onCountryChanged: (c) => setState(() => _selectedCountry = c),
                    onChanged: (_) => setState(() {}),
                    autofocus: true,
                  ),
                  const SizedBox(height: 12),
                  // Preview of full number
                  if (_phoneController.text.trim().isNotEmpty)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(start: 2),
                      child: Text(
                        tr('will_send_to', args: ['${_selectedCountry.dialCode} ${_phoneController.text.trim()}']),
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ),
                  const SizedBox(height: 32),
                  SizedBox(
                    height: LoomeaTokens.buttonHeight,
                    child: ElevatedButton(
                      onPressed: _isValid && !isLoading
                          ? () {
                              final phone =
                                  '${_selectedCountry.dialCode} ${_phoneController.text.trim()}';
                              context.read<AuthBloc>().add(SendOtpRequested(
                                    email: widget.email,
                                    phone: phone,
                                  ));
                            }
                          : null,
                      child: isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : Text(tr('verify_phone')),
                    ),
                  ),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text.rich(
                      TextSpan(
                        text: '${tr('by_continuing')} ',
                        style: const TextStyle(
                            fontSize: 12,
                            height: 1.5,
                            color: AppColors.textSecondary),
                        children: [
                          TextSpan(
                            text: tr('terms_of_service'),
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}


