import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/routes/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/loomea_tokens.dart';
import '../../core/widgets/looki_logo.dart';
import '../../../data/services/localization_service.dart';

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  Future<void> _markSeenAndGo(BuildContext context, String routeName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenOnboarding', true);
    if (context.mounted) context.goNamed(routeName);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: LoomeaTokens.screenPaddingH,
          ),
          child: LayoutBuilder(
            builder:
                (context, constraints) => SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Stack(
                        children: [
                          // ── Ambient glow blobs ──────────────────────────────
                          Positioned(
                            top: -60,
                            right: -80,
                            child: _GlowBlob(
                              size: 280,
                              color: AppColors.accent,
                              opacity: 0.10,
                            ),
                          ),
                          Positioned(
                            top: 120,
                            left: -100,
                            child: _GlowBlob(
                              size: 240,
                              color: AppColors.gold,
                              opacity: 0.22,
                            ),
                          ),
                          // ── Main content ────────────────────────────────────
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const SizedBox(height: 8),
                              // ── Header ────────────────────────────────────────────
                              Row(
                                children: [
                                  const LookiLogo(width: 32),
                                  const SizedBox(width: 8),
                                  Text(
                                    'looki',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w400,
                                      letterSpacing: -0.02 * 22,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const Spacer(),
                                  _PillButton(
                                    label: tr('skip'),
                                    onTap:
                                        () => _markSeenAndGo(
                                          context,
                                          AppRoute.signIn.name,
                                        ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 28),
                              // ── Stacked photo collage ─────────────────────────────
                              SizedBox(
                                height: 280,
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    // Card 1 — rose/pink, tilted left
                                    _PhotoCard(
                                      top: 0,
                                      left: 24,
                                      rotation: -8,
                                      gradientColors: const [
                                        Color(0xFFC9849C),
                                        Color(0xFFF2C8D1),
                                        Color(0xFFE8B0BE),
                                      ],
                                      tag: tr('tag_hair'),
                                    ),
                                    // Card 2 — sand/gold, tilted right
                                    _PhotoCard(
                                      top: 34,
                                      left: 160,
                                      rotation: 6,
                                      gradientColors: const [
                                        Color(0xFFA88A5E),
                                        Color(0xFFE8DCCB),
                                        Color(0xFFD9B382),
                                      ],
                                      tag: tr('tag_nails'),
                                    ),
                                    // Card 3 — navy, slight tilt
                                    _PhotoCard(
                                      top: 120,
                                      left: 60,
                                      rotation: -3,
                                      gradientColors: const [
                                        Color(0xFF0A2A6B),
                                        Color(0xFF16367A),
                                        Color(0xFF1E6FE8),
                                      ],
                                      tag: tr('tag_spa'),
                                    ),
                                    // Floating rating chip
                                    Positioned(
                                      bottom: -6,
                                      right: 8,
                                      child: _RatingChip(),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 36),
                              // ── Brand badge ───────────────────────────────────────
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      borderRadius: BorderRadius.circular(
                                        LoomeaTokens.radiusPill,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 6,
                                          height: 6,
                                          decoration: const BoxDecoration(
                                            color: AppColors.gold,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          "New · Spring '27",
                                          style: LoomeaTokens.eyebrowWith(
                                            color: Colors.white,
                                            fontSize: 11,
                                          ).copyWith(
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 0.06 * 11,
                                            textBaseline:
                                                TextBaseline.alphabetic,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              // ── Display headline ──────────────────────────────────
                              RichText(
                                text: TextSpan(
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 42,
                                    fontWeight: FontWeight.w900,
                                    height: 1.0,
                                    letterSpacing: -0.035 * 42,
                                    color: AppColors.textPrimary,
                                  ),
                                  children: [
                                    TextSpan(
                                      text:
                                          '${tr('onboarding_headline_prefix')}\n',
                                    ),
                                    TextSpan(
                                      text: tr('onboarding_headline_booked'),
                                      style: const TextStyle(
                                        color: AppColors.accent,
                                      ),
                                    ),
                                    TextSpan(
                                      text: tr('onboarding_headline_suffix'),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                tr('onboarding_subtext'),
                                style: const TextStyle(
                                  fontSize: 15,
                                  height: 1.5,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 22),
                              const Spacer(),
                              // ── CTAs ─────────────────────────────────────────────
                              SizedBox(
                                height: LoomeaTokens.buttonHeight,
                                child: ElevatedButton(
                                  onPressed:
                                      () => _markSeenAndGo(
                                        context,
                                        AppRoute.signUp.name,
                                      ),
                                  child: Text(tr('get_started')),
                                ),
                              ),
                              const SizedBox(height: 14),
                              Center(
                                child: GestureDetector(
                                  onTap:
                                      () => _markSeenAndGo(
                                        context,
                                        AppRoute.signIn.name,
                                      ),
                                  child: RichText(
                                    text: TextSpan(
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: AppColors.textSecondary,
                                      ),
                                      children: [
                                        TextSpan(
                                          text:
                                              '${tr('already_have_account')} ',
                                        ),
                                        TextSpan(
                                          text: tr('sign_in'),
                                          style: const TextStyle(
                                            color: AppColors.accent,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: LoomeaTokens.gapLg),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
          ),
        ),
      ),
    );
  }
}

// ── Supporting widgets ──────────────────────────────────────────────────────

class _GlowBlob extends StatelessWidget {
  const _GlowBlob({
    required this.size,
    required this.color,
    required this.opacity,
  });
  final double size;
  final Color color;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withAlpha((opacity * 255).round()),
          ),
        ),
      ),
    );
  }
}

class _PhotoCard extends StatelessWidget {
  const _PhotoCard({
    required this.top,
    required this.left,
    required this.rotation,
    required this.gradientColors,
    required this.tag,
  });
  final double top;
  final double left;
  final double rotation;
  final List<Color> gradientColors;
  final String tag;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      left: left,
      child: Transform.rotate(
        angle: rotation * 3.14159 / 180,
        child: Container(
          width: 168,
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradientColors,
            ),
            border: Border.all(color: Colors.white, width: 5),
            boxShadow: LoomeaTokens.stackedCardShadow,
          ),
          child: Stack(
            children: [
              // Stripe overlay
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(17),
                  child: CustomPaint(painter: _StripePainter()),
                ),
              ),
              // Tag pill
              Positioned(
                top: 10,
                left: 10,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(LoomeaTokens.radiusPill),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    color: Colors.white.withAlpha(235),
                    child: Text(
                      tag,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                        letterSpacing: 0.02 * 11,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StripePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.white.withAlpha(15)
          ..strokeWidth = 1;
    for (double x = -size.height; x < size.width + size.height; x += 19) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x + size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

class _RatingChip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(LoomeaTokens.radiusPill),
        border: Border.all(color: AppColors.border),
        boxShadow: LoomeaTokens.floatingShadow,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Avatar stack
          SizedBox(
            width: 56,
            height: 24,
            child: Stack(
              children: [
                _AvatarDot(color: AppColors.primary, left: 0),
                _AvatarDot(color: AppColors.gold, left: 16),
                _AvatarDot(color: const Color(0xFFC9849C), left: 32),
              ],
            ),
          ),
          const SizedBox(width: 8),
          RichText(
            text: TextSpan(
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              children: [
                const TextSpan(text: '12k+ '),
                TextSpan(
                  text: tr('booked_this_week'),
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarDot extends StatelessWidget {
  const _AvatarDot({required this.color, required this.left});
  final Color color;
  final double left;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
        ),
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  const _PillButton({required this.label, this.onTap});
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(LoomeaTokens.radiusPill),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
