import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../data/services/localization_service.dart';

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

class OtpVerificationPage extends StatefulWidget {
  const OtpVerificationPage({
    super.key,
    required this.email,
    required this.role,
  });

  final String email;
  final String role;

  @override
  State<OtpVerificationPage> createState() => _OtpVerificationPageState();
}

class _OtpVerificationPageState extends State<OtpVerificationPage> {
  static const _digitCount = 6;
  final _controllers =
      List.generate(_digitCount, (_) => TextEditingController(), growable: false);
  final _focusNodes =
      List.generate(_digitCount, (_) => FocusNode(), growable: false);

  static const _cooldown = 60;
  static const _maxAttempts = 3;
  int _secondsLeft = _cooldown;
  int _attempts = 0;
  bool _locked = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNodes[0].requestFocus();
    });
  }

  void _startTimer() {
    _secondsLeft = _cooldown;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (_secondsLeft > 0) {
          _secondsLeft--;
        } else {
          _timer?.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _controllers) c.dispose();
    for (final f in _focusNodes) f.dispose();
    super.dispose();
  }

  String get _otp => _controllers.map((c) => c.text).join();
  bool get _isComplete => _otp.length == _digitCount;
  bool get _canResend => _secondsLeft == 0;

  void _onDigitChanged(int index, String value) {
    if (value.length == 1 && index < _focusNodes.length - 1) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    setState(() {});
  }

  void _clearOtp() {
    for (final c in _controllers) c.clear();
    _focusNodes[0].requestFocus();
    setState(() {});
  }

  void _resend(BuildContext ctx) {
    _clearOtp();
    _startTimer();
    setState(() {
      _attempts = 0;
      _locked = false;
    });
    ctx.read<AuthBloc>().add(
          SendOtpRequested(email: widget.email),
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
          if (state.status == AuthStatus.authenticated) {
            context.read<ProfileBloc>().add(LoadProfile());
            final isOwner =
                state.user?.isOwner == true || widget.role == 'SALON_OWNER';
            if (isOwner) {
              context.goNamed(AppRoute.ownerOnboarding.name);
            } else {
              context.read<BookingBloc>().add(LoadAppointments());
              context.goNamed(AppRoute.home.name);
            }
          } else if (state.status == AuthStatus.error) {
            _clearOtp();
            setState(() {
              _attempts++;
              if (_attempts >= _maxAttempts) _locked = true;
            });
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(_locked
                  ? tr('too_many_failed_attempts')
                  : state.error),
              backgroundColor: AppColors.error,
            ));
          }
        },
        builder: (context, state) {
          final isLoading = state.status == AuthStatus.loading;

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                  horizontal: LoomeaTokens.screenPaddingH),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 24),
                  Center(
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.mail_outline_rounded,
                          color: AppColors.primary, size: 30),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    tr('verify_email'),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text.rich(
                    TextSpan(
                      style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 15, color: AppColors.textSecondary),
                      children: [
                        TextSpan(text: '${tr('enter_email_otp')} '),
                        TextSpan(
                          text: widget.email,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 36),

                  // OTP boxes
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_digitCount, (index) {
                      final filled = _controllers[index].text.isNotEmpty;
                      return Container(
                        width: 48,
                        height: 56,
                        margin: EdgeInsets.only(right: index < _digitCount - 1 ? 8 : 0),
                        decoration: BoxDecoration(
                          color: filled
                              ? AppColors.primary.withOpacity(0.08)
                              : AppColors.surface,
                          borderRadius:
                              BorderRadius.circular(LoomeaTokens.radiusInput),
                          border: Border.all(
                            color: filled
                                ? AppColors.primary
                                : AppColors.border,
                            width: filled ? 1.5 : 1,
                          ),
                        ),
                        child: TextField(
                          controller: _controllers[index],
                          focusNode: _focusNodes[index],
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          maxLength: 1,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                          decoration: const InputDecoration(
                            counterText: '',
                            contentPadding: EdgeInsets.zero,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            fillColor: Colors.transparent,
                            filled: true,
                          ),
                          onChanged: (value) => _onDigitChanged(index, value),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 36),

                  if (_locked)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          const Icon(Icons.lock_outline_rounded,
                              size: 16, color: AppColors.error),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              tr('too_many_attempts_warning'),
                              style: const TextStyle(
                                  fontSize: 13, color: AppColors.error),
                            ),
                          ),
                        ],
                      ),
                    ),

                  SizedBox(
                    height: LoomeaTokens.buttonHeight,
                    child: ElevatedButton(
                      onPressed: _isComplete && !isLoading && !_locked
                          ? () => context.read<AuthBloc>().add(
                                VerifyOtpRequested(
                                    email: widget.email, otp: _otp),
                              )
                          : null,
                      child: isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2.5, color: Colors.white),
                            )
                          : Text(tr('verify')),
                    ),
                  ),
                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${tr('didnt_receive')} ',
                        style: const TextStyle(
                            fontSize: 14, color: AppColors.textSecondary),
                      ),
                      _canResend
                          ? GestureDetector(
                              onTap: isLoading ? null : () => _resend(context),
                              child: Text(
                                tr('resend_code'),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            )
                          : Text(
                              tr('resend_in', args: ['$_secondsLeft']),
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textSecondary),
                            ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.shield_outlined,
                          size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 6),
                      Text(
                        tr('check_spam_folder'),
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
