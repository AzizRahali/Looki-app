import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/loomea_tokens.dart';

// ── Salon image gradient placeholder ─────────────────────────────────────────

/// Returns one of three branded gradients (from the onboarding cards) based on
/// the salon's id, so each salon consistently gets the same color.
LinearGradient salonPlaceholderGradient(String salonId) {
  const palettes = [
    [Color(0xFFC9849C), Color(0xFFF2C8D1), Color(0xFFE8B0BE)], // rose
    [Color(0xFFA88A5E), Color(0xFFE8DCCB), Color(0xFFD9B382)], // gold
    [Color(0xFF0A2A6B), Color(0xFF16367A), Color(0xFF1E6FE8)], // navy
  ];
  final idx = salonId.hashCode.abs() % palettes.length;
  return LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: palettes[idx],
  );
}

/// Full-bleed gradient placeholder for a salon with no image.
class SalonImagePlaceholder extends StatelessWidget {
  const SalonImagePlaceholder({super.key, required this.salonId});
  final String salonId;

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(gradient: salonPlaceholderGradient(salonId)),
      );
}

/// Standard horizontal padding for screens.
class LoomeaScreenPadding extends StatelessWidget {
  const LoomeaScreenPadding({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: LoomeaTokens.screenPaddingH),
        child: child,
      );
}

/// Circular back button — white surface, warm border.
class LoomeaAppBarLeading extends StatelessWidget {
  const LoomeaAppBarLeading({super.key, this.onPressed});
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    return Padding(
      padding: EdgeInsetsDirectional.only(start: 8),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.surface,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.border),
        ),
        child: IconButton(
          padding: EdgeInsets.zero,
          onPressed: onPressed ?? () => Navigator.of(context).maybePop(),
          style: IconButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: AppColors.textPrimary,
            shape: const CircleBorder(),
          ),
          icon: Icon(
            isRtl
                ? Icons.arrow_forward_ios_rounded
                : Icons.arrow_back_ios_new_rounded,
            size: 16,
          ),
        ),
      ),
    );
  }
}

/// "Or continue with" divider row — JetBrains Mono eyebrow style.
class LoomeaOrContinueDivider extends StatelessWidget {
  const LoomeaOrContinueDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Divider(color: AppColors.border, thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'or continue with',
            style: LoomeaTokens.eyebrow,
          ),
        ),
        Expanded(child: Divider(color: AppColors.border, thickness: 1)),
      ],
    );
  }
}

/// Google / Apple social login buttons — white fill, warm border.
class LoomeaSocialButtonRow extends StatelessWidget {
  const LoomeaSocialButtonRow({super.key, this.onGoogle, this.onApple});
  final VoidCallback? onGoogle;
  final VoidCallback? onApple;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SocialTile(
            label: 'Google',
            icon: Icons.g_mobiledata_rounded,
            onTap: onGoogle ?? () {},
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SocialTile(
            label: 'Apple',
            icon: Icons.apple,
            onTap: onApple ?? () {},
          ),
        ),
      ],
    );
  }
}

class _SocialTile extends StatelessWidget {
  const _SocialTile({
    required this.label,
    required this.icon,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(LoomeaTokens.radiusInput),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(LoomeaTokens.radiusInput),
        child: Container(
          height: LoomeaTokens.buttonHeight,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(LoomeaTokens.radiusInput),
            border: Border.all(color: AppColors.border),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 22, color: AppColors.textPrimary),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// White surface card with soft navy-tinted shadow.
class LoomeaSurfaceCard extends StatelessWidget {
  const LoomeaSurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.radius = LoomeaTokens.radiusCard,
    this.withShadow = false,
    this.withBorder = true,
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final bool withShadow;
  final bool withBorder;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(radius),
        border:
            withBorder ? Border.all(color: AppColors.border) : null,
        boxShadow: withShadow ? LoomeaTokens.cardShadow : null,
      ),
      child: child,
    );
  }
}

/// Labeled text field — label above input.
class LoomeaLabeledField extends StatelessWidget {
  const LoomeaLabeledField({
    super.key,
    required this.label,
    required this.child,
    this.icon,
  });
  final String label;
  final Widget child;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: AppColors.inkSoft),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.inkSoft,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}
