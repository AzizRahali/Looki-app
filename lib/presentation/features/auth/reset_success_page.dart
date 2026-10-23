import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../data/services/localization_service.dart';
import '../../../logic/blocs/password_reset/password_reset_bloc.dart';
import '../../../logic/blocs/password_reset/password_reset_event.dart';
import '../../core/routes/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/loomea_tokens.dart';

class ResetSuccessPage extends StatefulWidget {
  const ResetSuccessPage({super.key});

  @override
  State<ResetSuccessPage> createState() => _ResetSuccessPageState();
}

class _ResetSuccessPageState extends State<ResetSuccessPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _fadeAnim;

  static const _autoNavigateDelay = Duration(seconds: 4);
  Timer? _navTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _scaleAnim = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );

    _fadeAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
    );

    _controller.forward();

    _navTimer = Timer(_autoNavigateDelay, () {
      if (mounted) _navigateToSignIn();
    });
  }

  @override
  void dispose() {
    _navTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _navigateToSignIn() {
    _navTimer?.cancel();
    context.read<PasswordResetBloc>().add(ResetPasswordResetBloc());
    context.goNamed(AppRoute.signIn.name);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: LoomeaTokens.screenPaddingH),
            child: Column(
              children: [
                const Spacer(),

                // Animated check icon
                ScaleTransition(
                  scale: _scaleAnim,
                  child: Container(
                    width: 96,
                    height: 96,
                    decoration: const BoxDecoration(
                      color: AppColors.successBg,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      size: 52,
                      color: AppColors.success,
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Title + message
                FadeTransition(
                  opacity: _fadeAnim,
                  child: Column(
                    children: [
                      Text(
                        tr('youre_back'),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 36,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.025 * 36,
                          height: 1.1,
                          color: AppColors.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        tr('password_updated_msg'),
                        style: const TextStyle(
                          fontSize: 15,
                          height: 1.6,
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Auto-navigate progress bar
                FadeTransition(
                  opacity: _fadeAnim,
                  child: _AutoNavBar(duration: _autoNavigateDelay),
                ),
                const SizedBox(height: 24),

                // Sign in button
                FadeTransition(
                  opacity: _fadeAnim,
                  child: SizedBox(
                    height: LoomeaTokens.buttonHeight,
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _navigateToSignIn,
                      child: Text(tr('back_to_sign_in')),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Thin progress bar that depletes over [duration], signalling auto-navigation.
class _AutoNavBar extends StatefulWidget {
  const _AutoNavBar({required this.duration});
  final Duration duration;

  @override
  State<_AutoNavBar> createState() => _AutoNavBarState();
}

class _AutoNavBarState extends State<_AutoNavBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration)
      ..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Column(
        children: [
          Text(
            tr('back_to_sign_in'),
            style: const TextStyle(
                fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: 1 - _ctrl.value,
              backgroundColor: AppColors.border,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.primary),
              minHeight: 3,
            ),
          ),
        ],
      ),
    );
  }
}
