import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../data/services/localization_service.dart';
import '../../../logic/blocs/password_reset/password_reset_bloc.dart';
import '../../../logic/blocs/password_reset/password_reset_event.dart';
import '../../../logic/blocs/password_reset/password_reset_state.dart';
import '../../core/routes/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/loomea_tokens.dart';
import '../../core/widgets/loomea_ui.dart';

class NewPasswordPage extends StatefulWidget {
  const NewPasswordPage({super.key});

  @override
  State<NewPasswordPage> createState() => _NewPasswordPageState();
}

class _NewPasswordPageState extends State<NewPasswordPage> {
  final _controller = TextEditingController();
  bool _obscure = true;
  bool _touched = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ── Strength scoring ───────────────────────────────────────────────────────

  static int _calcStrength(String p) {
    if (p.length < 8) return 0;
    int score = 1;
    if (p.length >= 12) score++;
    if (RegExp(r'[A-Z]').hasMatch(p)) score++;
    if (RegExp(r'[0-9]').hasMatch(p)) score++;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(p)) score++;
    return score.clamp(0, 4);
  }

  String _strengthLabel(int s) {
    switch (s) {
      case 1:
        return tr('strength_weak');
      case 2:
        return tr('strength_fair');
      case 3:
        return tr('strength_good');
      default:
        return tr('strength_strong');
    }
  }

  Color _strengthColor(int s) {
    switch (s) {
      case 1:
        return AppColors.error;
      case 2:
        return AppColors.warning;
      case 3:
        return AppColors.success;
      default:
        return const Color(0xFF22C55E);
    }
  }

  // ── Requirements ──────────────────────────────────────────────────────────

  bool get _hasLength => _controller.text.length >= 8;
  bool get _hasUpper => RegExp(r'[A-Z]').hasMatch(_controller.text);
  bool get _hasLower => RegExp(r'[a-z]').hasMatch(_controller.text);
  bool get _hasNumber => RegExp(r'[0-9]').hasMatch(_controller.text);
  bool get _isValid => _hasLength && _hasUpper && _hasLower && _hasNumber;

  void _submit(BuildContext context) {
    if (!_isValid) return;
    context
        .read<PasswordResetBloc>()
        .add(SubmitNewPassword(_controller.text));
  }

  @override
  Widget build(BuildContext context) {
    final password = _controller.text;
    final strength = password.isEmpty ? 0 : _calcStrength(password);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: LoomeaAppBarLeading(onPressed: () => context.pop()),
      ),
      body: BlocConsumer<PasswordResetBloc, PasswordResetState>(
        listener: (context, state) {
          if (state.status == PasswordResetStatus.success) {
            context.goNamed(AppRoute.resetSuccess.name);
          } else if (state.status == PasswordResetStatus.tokenReady &&
              state.errorMessage == 'same_password') {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(tr('req_different_from_current')),
              backgroundColor: AppColors.error,
            ));
          } else if (state.status == PasswordResetStatus.error) {
            final msg = state.errorMessage;
            if (msg == 'token_expired') {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(tr('link_expired_title')),
                backgroundColor: AppColors.error,
              ));
              context.goNamed(AppRoute.forgotPassword.name);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(
                    msg.isNotEmpty ? msg : tr('something_went_wrong')),
                backgroundColor: AppColors.error,
              ));
            }
          }
        },
        builder: (context, state) {
          final isSaving = state.status == PasswordResetStatus.saving;

          return SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: LoomeaTokens.screenPaddingH),
                child: ConstrainedBox(
                  constraints:
                      BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 24),
                        const Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: Icon(Icons.lock_outline_rounded,
                              size: 40, color: AppColors.primary),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          tr('new_password_title'),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.025 * 32,
                            height: 1.1,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          tr('make_it_memorable'),
                          style: const TextStyle(
                            fontSize: 15,
                            height: 1.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Password field
                        TextField(
                          controller: _controller,
                          obscureText: _obscure,
                          textInputAction: TextInputAction.done,
                          onTap: () {
                            if (!_touched) setState(() => _touched = true);
                          },
                          onChanged: (_) {
                            if (!_touched) setState(() => _touched = true);
                          },
                          style: const TextStyle(
                              fontSize: 16,
                              color: AppColors.textPrimary),
                          decoration: InputDecoration(
                            hintText: tr('create_password_hint'),
                            suffixIcon: IconButton(
                              onPressed: () =>
                                  setState(() => _obscure = !_obscure),
                              icon: Icon(
                                _obscure
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: AppColors.textSecondary,
                                size: 22,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Strength bar
                        if (_touched && password.isNotEmpty) ...[
                          Row(
                            children: List.generate(4, (i) {
                              final active = i < strength;
                              return Expanded(
                                child: AnimatedContainer(
                                  duration:
                                      const Duration(milliseconds: 300),
                                  height: 4,
                                  margin: EdgeInsets.only(
                                      right: i < 3 ? 4 : 0),
                                  decoration: BoxDecoration(
                                    color: active
                                        ? _strengthColor(strength)
                                        : AppColors.border,
                                    borderRadius:
                                        BorderRadius.circular(2),
                                  ),
                                ),
                              );
                            }),
                          ),
                          const SizedBox(height: 6),
                          if (strength > 0)
                            Text(
                              strength < 2
                                  ? tr('strength_too_short')
                                  : _strengthLabel(strength),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: strength == 0
                                    ? AppColors.textSecondary
                                    : _strengthColor(strength),
                              ),
                            ),
                          const SizedBox(height: 16),
                        ],

                        // Requirements checklist
                        if (_touched) ...[
                          _Requirement(
                              met: _hasLength,
                              label: tr('req_min_8_chars')),
                          const SizedBox(height: 6),
                          _Requirement(
                              met: _hasUpper,
                              label: tr('req_uppercase')),
                          const SizedBox(height: 6),
                          _Requirement(
                              met: _hasLower,
                              label: tr('req_lowercase')),
                          const SizedBox(height: 6),
                          _Requirement(
                              met: _hasNumber,
                              label: tr('req_number')),
                          const SizedBox(height: 24),
                        ],

                        const Spacer(),

                        // Encryption note
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.shield_outlined,
                                size: 14,
                                color: AppColors.textSecondary),
                            const SizedBox(width: 6),
                            Text(
                              tr('secured_encryption'),
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Save button
                        SizedBox(
                          height: LoomeaTokens.buttonHeight,
                          child: ElevatedButton(
                            onPressed:
                                (_isValid && !isSaving)
                                    ? () => _submit(context)
                                    : null,
                            child: isSaving
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: Colors.white),
                                  )
                                : Text(tr('save_password')),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Requirement extends StatelessWidget {
  const _Requirement({required this.met, required this.label});

  final bool met;
  final String label;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: Row(
        key: ValueKey(met),
        children: [
          Icon(
            met
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            size: 16,
            color: met ? AppColors.success : AppColors.textSecondary,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: met ? AppColors.textPrimary : AppColors.textSecondary,
              fontWeight: met ? FontWeight.w500 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
