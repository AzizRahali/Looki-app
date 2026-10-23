import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../data/services/biometric_service.dart';
import '../../../logic/blocs/auth/auth_bloc.dart';
import '../../../logic/blocs/auth/auth_event.dart';
import '../../../logic/blocs/auth/auth_state.dart';
import '../../../logic/blocs/booking/booking_bloc.dart';
import '../../../logic/blocs/booking/booking_event.dart';
import '../../../logic/blocs/profile/profile_bloc.dart';
import '../../../logic/blocs/profile/profile_event.dart';
import '../../core/routes/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/loomea_tokens.dart';
import '../../core/widgets/loomea_ui.dart';
import '../../core/widgets/looki_logo.dart';
import '../../../data/services/localization_service.dart';

/// Holds the credentials of the last manual login attempt so the post-login
/// "enable biometric?" prompt knows what to persist. Cleared after use.
class _PendingCredentials {
  static String? email;
  static String? password;
}

Future<void> _maybeOfferBiometric(BuildContext context) async {
  final email = _PendingCredentials.email;
  final password = _PendingCredentials.password;
  _PendingCredentials.email = null;
  _PendingCredentials.password = null;
  if (email == null || password == null) return;

  final bio = BiometricService.instance;
  if (await bio.isEnabled()) return;
  if (await bio.hasPrompted()) return;
  if (!await bio.isAvailable()) return;
  await bio.markPrompted();

  if (!context.mounted) return;
  final enable = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(LoomeaTokens.radiusCard),
      ),
      title: Text(tr('biometric_enable_title')),
      content: Text(tr('biometric_enable_desc')),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(
            tr('not_now'),
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(
            tr('enable'),
            style: const TextStyle(
              color: AppColors.accent,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
  if (enable == true) {
    final ok = await bio.authenticate(reason: tr('biometric_enable_reason'));
    if (ok) await bio.enable(email: email, password: password);
  }
}

class SignInPage extends StatelessWidget {
  const SignInPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.symmetric(
                  horizontal: LoomeaTokens.screenPaddingH),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 48),
                      const Center(child: LookiLogo(width: 56)),
                      const SizedBox(height: 32),
                      Text(
                        '${tr('welcome_back')}.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 38,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.025 * 38,
                          height: 1.1,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        tr('sign_in_subtitle'),
                        style: const TextStyle(
                          fontSize: 15,
                          height: 1.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 36),
                      BlocConsumer<AuthBloc, AuthState>(
                        listener: (context, state) async {
                          if (state.status == AuthStatus.authenticated) {
                            context.read<ProfileBloc>().add(LoadProfile());
                            await _maybeOfferBiometric(context);
                            if (!context.mounted) return;
                            if (state.user?.isOwner == true) {
                              context.goNamed(AppRoute.ownerHome.name);
                            } else {
                              context.read<BookingBloc>().add(LoadAppointments());
                              context.goNamed(AppRoute.home.name);
                            }
                          } else if (state.status ==
                              AuthStatus.pendingVerification) {
                            context.pushNamed(
                              AppRoute.otpVerification.name,
                              extra: {
                                'email': state.pendingEmail,
                                'role': '',
                              },
                            );
                          } else if (state.status == AuthStatus.error) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(state.error.isNotEmpty
                                    ? state.error
                                    : tr('invalid_credentials')),
                                backgroundColor: AppColors.error,
                              ),
                            );
                          }
                        },
                        builder: (context, state) {
                          return _SignInForm(
                            isLoading: state.status == AuthStatus.loading,
                          );
                        },
                      ),
                      const Spacer(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SignInForm extends StatefulWidget {
  const _SignInForm({this.isLoading = false});

  final bool isLoading;

  @override
  State<_SignInForm> createState() => _SignInFormState();
}

class _SignInFormState extends State<_SignInForm> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  bool _emailTouched = false;
  bool _passwordTouched = false;
  bool _biometricReady = false;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_onFieldChanged);
    _passwordController.addListener(_onFieldChanged);
    _checkBiometric();
  }

  Future<void> _checkBiometric() async {
    final bio = BiometricService.instance;
    final ready = await bio.isEnabled() && await bio.isAvailable();
    if (mounted && ready != _biometricReady) {
      setState(() => _biometricReady = ready);
    }
  }

  Future<void> _signInWithBiometric() async {
    final bio = BiometricService.instance;
    final ok = await bio.authenticate();
    if (!ok || !mounted) return;
    final creds = await bio.readCredentials();
    if (creds == null || !mounted) return;
    _PendingCredentials.email = creds.email;
    _PendingCredentials.password = creds.password;
    context.read<AuthBloc>().add(LoginRequested(
          email: creds.email,
          password: creds.password,
        ));
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onFieldChanged() => setState(() {});

  static final _emailRegex = RegExp(r'^[\w\.\-\+]+@[\w\-]+\.\w{2,}$');

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
    if (v.length < 6) return tr('password_too_short_6');
    return null;
  }

  bool get _isFormValid {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    return _emailRegex.hasMatch(email) && password.length >= 6;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
            style: const TextStyle(fontSize: 16, color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'name@example.com',
              errorText: _emailError,
              errorStyle: const TextStyle(fontSize: 12),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Password label row
        Row(
          children: [
            Text(
              tr('password'),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.inkSoft,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () => context.pushNamed(AppRoute.forgotPassword.name),
              child: Text(
                tr('forgot_password'),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.accent,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          textInputAction: TextInputAction.done,
          onTap: () {
            if (!_passwordTouched) setState(() => _passwordTouched = true);
          },
          onChanged: (_) {
            if (!_passwordTouched) setState(() => _passwordTouched = true);
          },
          style: const TextStyle(fontSize: 16, color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: '••••••••',
            errorText: _passwordError,
            errorStyle: const TextStyle(fontSize: 12),
            suffixIcon: IconButton(
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: AppColors.textSecondary,
                size: 22,
              ),
            ),
          ),
        ),
        const SizedBox(height: 28),
        SizedBox(
          height: LoomeaTokens.buttonHeight,
          child: ElevatedButton(
            onPressed: _isFormValid && !widget.isLoading
                ? () {
                    final email = _emailController.text.trim();
                    final password = _passwordController.text;
                    _PendingCredentials.email = email;
                    _PendingCredentials.password = password;
                    context.read<AuthBloc>().add(LoginRequested(
                          email: email,
                          password: password,
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
                : Text(tr('sign_in')),
          ),
        ),
        if (_biometricReady) ...[
          const SizedBox(height: 16),
          Center(
            child: InkWell(
              onTap: widget.isLoading ? null : _signInWithBiometric,
              borderRadius: BorderRadius.circular(36),
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.accent, width: 1.5),
                ),
                child: const Icon(
                  Icons.fingerprint_rounded,
                  size: 32,
                  color: AppColors.accent,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              tr('sign_in_with_biometric'),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
        const SizedBox(height: 28),
        const LoomeaOrContinueDivider(),
        const SizedBox(height: 20),
        const LoomeaSocialButtonRow(),
        const SizedBox(height: 28),
        Center(
          child: GestureDetector(
            onTap: () => context.goNamed(AppRoute.signUp.name),
            child: Text.rich(
              TextSpan(
                text: '${tr('new_here')} ',
                style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                children: [
                  TextSpan(
                    text: tr('create_account'),
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
      ],
    );
  }
}
