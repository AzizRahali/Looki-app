import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../logic/blocs/auth/auth_bloc.dart';
import '../../../logic/blocs/auth/auth_event.dart';
import '../../../logic/blocs/auth/auth_state.dart';
import '../../core/routes/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/loomea_tokens.dart';
import '../../core/widgets/loomea_ui.dart';
import '../../core/widgets/looki_logo.dart';
import '../../../data/services/localization_service.dart';

class SignUpPage extends StatelessWidget {
  const SignUpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: LoomeaAppBarLeading(onPressed: () => context.goNamed(AppRoute.signIn.name)),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
              horizontal: LoomeaTokens.screenPaddingH),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              const Center(child: LookiLogo(width: 56)),
              const SizedBox(height: 24),
              Text(
                tr('join_tagline'),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.025 * 36,
                  height: 1.1,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                tr('enter_details'),
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 32),
              BlocConsumer<AuthBloc, AuthState>(
                listener: (context, state) {
                  if (state.status == AuthStatus.pendingVerification) {
                    context.pushNamed(
                      AppRoute.otpVerification.name,
                      extra: {
                        'email': state.pendingEmail,
                        'role': state.pendingRole,
                      },
                    );
                  } else if (state.status == AuthStatus.error) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.error.isNotEmpty
                            ? state.error
                            : tr('registration_failed')),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                },
                builder: (context, state) {
                  return _SignUpForm(
                    isLoading: state.status == AuthStatus.loading,
                  );
                },
              ),
              const SizedBox(height: 20),
              Text.rich(
                TextSpan(
                  text: '${tr('by_signing_up')} ',
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: AppColors.textSecondary,
                  ),
                  children: [
                    TextSpan(
                      text: tr('terms_of_service'),
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        color: AppColors.accent,
                      ),
                    ),
                    TextSpan(text: ' ${tr('and')} '),
                    TextSpan(
                      text: tr('privacy_policy'),
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        color: AppColors.accent,
                      ),
                    ),
                    const TextSpan(text: '.'),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }
}

class _SignUpForm extends StatefulWidget {
  const _SignUpForm({this.isLoading = false});

  final bool isLoading;

  @override
  State<_SignUpForm> createState() => _SignUpFormState();
}

class _SignUpFormState extends State<_SignUpForm> {
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  String _selectedRole = 'CLIENT';

  bool _nameTouched = false;
  bool _emailTouched = false;
  bool _passwordTouched = false;

  @override
  void initState() {
    super.initState();
    _fullNameController.addListener(_onFieldChanged);
    _emailController.addListener(_onFieldChanged);
    _passwordController.addListener(_onFieldChanged);
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onFieldChanged() => setState(() {});

  static final _emailRegex = RegExp(r'^[\w\.\-\+]+@[\w\-]+\.\w{2,}$');

  String? get _nameError {
    if (!_nameTouched) return null;
    final v = _fullNameController.text.trim();
    if (v.isEmpty) return tr('full_name_required');
    if (v.length < 2) return tr('name_too_short');
    return null;
  }

  String? get _emailError {
    if (!_emailTouched) return null;
    final v = _emailController.text.trim();
    if (v.isEmpty) return tr('email_required');
    if (!_emailRegex.hasMatch(v)) return tr('email_invalid');
    return null;
  }

  String? get _passwordError {
    if (!_passwordTouched) return null;
    final v = _passwordController.text;
    if (v.isEmpty) return tr('password_required');
    if (v.length < 8) return tr('password_too_short_8');
    if (!v.contains(RegExp(r'[A-Z]'))) return tr('password_needs_upper');
    if (!v.contains(RegExp(r'[a-z]'))) return tr('password_needs_lower');
    if (!v.contains(RegExp(r'[0-9]'))) return tr('password_needs_number');
    return null;
  }

  bool get _isNameValid => _fullNameController.text.trim().length >= 2;
  bool get _isEmailValid => _emailRegex.hasMatch(_emailController.text.trim());
  bool get _isPasswordValid {
    final v = _passwordController.text;
    return v.length >= 8 &&
        v.contains(RegExp(r'[A-Z]')) &&
        v.contains(RegExp(r'[a-z]')) &&
        v.contains(RegExp(r'[0-9]'));
  }

  bool get _isFormValid => _isNameValid && _isEmailValid && _isPasswordValid;

  int get _passwordStrength {
    final v = _passwordController.text;
    if (v.isEmpty) return 0;
    int score = 0;
    if (v.length >= 8) score++;
    if (v.contains(RegExp(r'[A-Z]'))) score++;
    if (v.contains(RegExp(r'[a-z]'))) score++;
    if (v.contains(RegExp(r'[0-9]'))) score++;
    if (v.contains(RegExp(r'[!@#\$%\^&\*\(\)_\+\-=\[\]\{\};:,\.<>\?]'))) score++;
    return score;
  }

  Color _strengthColor(int strength) {
    if (strength <= 1) return AppColors.error;
    if (strength <= 2) return Colors.orange;
    if (strength <= 3) return const Color(0xFFFFC107);
    return AppColors.success;
  }

  String _strengthLabel(int strength) {
    if (strength <= 1) return tr('strength_weak');
    if (strength <= 2) return tr('strength_fair');
    if (strength <= 3) return tr('strength_good');
    return tr('strength_strong');
  }

  @override
  Widget build(BuildContext context) {
    final strength = _passwordStrength;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Role toggle
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(LoomeaTokens.radiusCard),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              _RoleTab(
                label: tr('role_client'),
                selected: _selectedRole == 'CLIENT',
                onTap: () => setState(() => _selectedRole = 'CLIENT'),
              ),
              _RoleTab(
                label: tr('role_salon_owner'),
                selected: _selectedRole == 'SALON_OWNER',
                onTap: () => setState(() => _selectedRole = 'SALON_OWNER'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // Full Name
        LoomeaLabeledField(
          label: tr('full_name'),
          child: TextField(
            controller: _fullNameController,
            textInputAction: TextInputAction.next,
            textCapitalization: TextCapitalization.words,
            onTap: () {
              if (!_nameTouched) setState(() => _nameTouched = true);
            },
            onChanged: (_) {
              if (!_nameTouched) setState(() => _nameTouched = true);
            },
            decoration: InputDecoration(
              hintText: 'John Doe',
              errorText: _nameError,
              errorStyle: const TextStyle(fontSize: 12),
              suffixIcon: _nameTouched && _isNameValid
                  ? const Icon(Icons.check_circle_rounded,
                      color: AppColors.success, size: 20)
                  : null,
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Email
        LoomeaLabeledField(
          label: tr('email'),
          child: TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            onTap: () {
              if (!_emailTouched) setState(() => _emailTouched = true);
            },
            onChanged: (_) {
              if (!_emailTouched) setState(() => _emailTouched = true);
            },
            decoration: InputDecoration(
              hintText: 'name@example.com',
              errorText: _emailError,
              errorStyle: const TextStyle(fontSize: 12),
              suffixIcon: _emailTouched && _isEmailValid
                  ? const Icon(Icons.check_circle_rounded,
                      color: AppColors.success, size: 20)
                  : null,
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Password
        LoomeaLabeledField(
          label: tr('password'),
          child: TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            onTap: () {
              if (!_passwordTouched) setState(() => _passwordTouched = true);
            },
            onChanged: (_) {
              if (!_passwordTouched) setState(() => _passwordTouched = true);
            },
            decoration: InputDecoration(
              hintText: tr('create_password_hint'),
              errorText: _passwordError,
              errorStyle: const TextStyle(fontSize: 12),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: AppColors.textSecondary,
                  size: 22,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
          ),
        ),
        if (_passwordTouched && _passwordController.text.isNotEmpty) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: strength / 5,
                    minHeight: 4,
                    backgroundColor: AppColors.border,
                    valueColor:
                        AlwaysStoppedAnimation(_strengthColor(strength)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                _strengthLabel(strength),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _strengthColor(strength),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          _RequirementRow(
            label: tr('req_min_8_chars'),
            met: _passwordController.text.length >= 8,
          ),
          _RequirementRow(
            label: tr('req_uppercase'),
            met: _passwordController.text.contains(RegExp(r'[A-Z]')),
          ),
          _RequirementRow(
            label: tr('req_lowercase'),
            met: _passwordController.text.contains(RegExp(r'[a-z]')),
          ),
          _RequirementRow(
            label: tr('req_number'),
            met: _passwordController.text.contains(RegExp(r'[0-9]')),
          ),
        ],
        const SizedBox(height: 28),
        SizedBox(
          height: LoomeaTokens.buttonHeight,
          child: ElevatedButton(
            onPressed: _isFormValid && !widget.isLoading
                ? () {
                    context.read<AuthBloc>().add(RegisterRequested(
                          fullName: _fullNameController.text.trim(),
                          email: _emailController.text.trim(),
                          password: _passwordController.text,
                          role: _selectedRole,
                        ));
                  }
                : null,
            child: widget.isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5, color: Colors.white),
                  )
                : Text(tr('continue_btn')),
          ),
        ),
        const SizedBox(height: 20),
        Center(
          child: GestureDetector(
            onTap: () => context.goNamed(AppRoute.signIn.name),
            child: Text.rich(
              TextSpan(
                text: '${tr('already_have_account')} ',
                style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                children: [
                  TextSpan(
                    text: tr('sign_in'),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.accent,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 28),
        const LoomeaOrContinueDivider(),
        const SizedBox(height: 20),
        const LoomeaSocialButtonRow(),
        const SizedBox(height: 20),
      ],
    );
  }
}

class _RoleTab extends StatelessWidget {
  const _RoleTab(
      {required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(LoomeaTokens.radiusCard - 2),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? AppColors.onPrimary : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RequirementRow extends StatelessWidget {
  const _RequirementRow({required this.label, required this.met});

  final String label;
  final bool met;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            met ? Icons.check_circle_rounded : Icons.circle_outlined,
            size: 14,
            color: met ? AppColors.success : AppColors.textSecondary,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: met ? AppColors.success : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
