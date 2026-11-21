import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../data/api/api_client.dart';
import '../../../data/repositories/loomea_repository.dart';
import '../../../data/services/biometric_service.dart';
import '../../../logic/blocs/auth/auth_bloc.dart';
import '../../../logic/blocs/auth/auth_event.dart';
import '../../../logic/blocs/profile/profile_bloc.dart';
import '../../../logic/blocs/profile/profile_event.dart';
import '../../../logic/blocs/profile/profile_state.dart';
import '../../core/routes/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/loomea_tokens.dart';
import '../../core/utils/image_utils.dart';
import '../../../data/models/profile_model.dart';
import 'edit_profile_sheet.dart';
import '../../../data/services/localization_service.dart';

// ignore_for_file: use_build_context_synchronously

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  void _editProfile(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => BlocProvider.value(
        value: context.read<ProfileBloc>(),
        child: const EditProfileSheet(),
      ),
    );
  }

  void _logout(BuildContext context) {
    final authBloc = context.read<AuthBloc>();
    final profileBloc = context.read<ProfileBloc>();
    final repo = context.read<LoomeeaRepository>();
    final router = GoRouter.of(context);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(LoomeaTokens.radiusCard),
        ),
        title: Text(tr('sign_out')),
        content: Text(tr('sign_out_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              tr('cancel'),
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              // clearToken() sets _accessToken = null synchronously as its
              // very first line, so isLoggedIn is already false before
              // goNamed fires — no need to await the SharedPreferences flush.
              repo.logout();
              BiometricService.instance.disable();
              authBloc.add(LogoutRequested());
              profileBloc.add(ClearProfile());
              router.goNamed(AppRoute.signIn.name);
            },
            child: Text(
              tr('sign_out'),
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  void _deleteAccount(BuildContext context) {
    final profileBloc = context.read<ProfileBloc>();
    final confirmController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final canConfirm = confirmController.text == 'delete';
          return AlertDialog(
            backgroundColor: AppColors.background,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(LoomeaTokens.radiusCard),
            ),
            title: Text(tr('delete_account')),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr('delete_account_desc'),
                  style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: confirmController,
                  autofocus: true,
                  onChanged: (_) => setDialogState(() {}),
                  decoration: const InputDecoration(hintText: 'delete'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  confirmController.dispose();
                  Navigator.of(ctx).pop();
                },
                child: Text(
                  tr('cancel'),
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ),
              TextButton(
                onPressed: canConfirm
                    ? () {
                        Navigator.of(ctx).pop();
                        confirmController.dispose();
                        // Schedules deletion — does NOT log out.
                        // Profile reloads with isPendingDeletion = true.
                        profileBloc.add(DeleteAccount());
                      }
                    : null,
                child: Text(
                  tr('schedule_deletion'),
                  style: const TextStyle(color: AppColors.error),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showInfoSheet(BuildContext context, String title, String content) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (_, scrollController) => Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: LoomeaTokens.screenPaddingH),
          child: ListView(
            controller: scrollController,
            children: [
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textSecondary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                content,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.6,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileBloc, ProfileState>(
      builder: (context, state) {
        final profile = state.profile;

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
              horizontal: LoomeaTokens.screenPaddingH),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              Text(
                tr('profile'),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.025 * 32,
                  height: 1.1,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              if (profile != null && profile.isPendingDeletion)
                _PendingDeletionBanner(
                  daysLeft: profile.daysUntilDeletion,
                  onCancel: () =>
                      context.read<ProfileBloc>().add(CancelDeletion()),
                ),
              const SizedBox(height: 8),
              _ProfileCard(
                profile: profile,
                name: profile?.fullName ?? '',
                email: profile?.email ?? '',
                onEdit: () => _editProfile(context),
              ),
              const SizedBox(height: 28),
              if (profile != null && !profile.isOwner)
                _ReliabilityCard(profile: profile),
              const SizedBox(height: 32),
              _SettingsGroup(
                title: tr('account'),
                children: [
                  _SettingsItem(
                    icon: Icons.notifications_none_rounded,
                    label: tr('notifications'),
                    onTap: () =>
                        context.pushNamed(AppRoute.notifications.name),
                  ),
                  _SettingsItem(
                    icon: Icons.favorite_border_rounded,
                    label: tr('favorite_salons'),
                    onTap: () =>
                        context.pushNamed(AppRoute.favoriteSalons.name),
                  ),
                  _SettingsItem(
                    icon: Icons.receipt_long_outlined,
                    label: tr('payment_history'),
                    onTap: () =>
                        context.pushNamed(AppRoute.paymentHistory.name),
                  ),
                  const _BiometricToggle(),
                ],
              ),
              const SizedBox(height: 24),
              _SettingsGroup(
                title: tr('support'),
                children: [
                  _SettingsItem(
                    icon: Icons.help_outline_rounded,
                    label: tr('help_center'),
                    onTap: () => context.pushNamed(AppRoute.supportChat.name, extra: false),
                  ),
                  _SettingsItem(
                    icon: Icons.description_outlined,
                    label: tr('terms_of_service'),
                    onTap: () => _showInfoSheet(context, tr('terms_of_service'), tr('terms_of_service_content')),
                  ),
                  _SettingsItem(
                    icon: Icons.shield_outlined,
                    label: tr('privacy_policy'),
                    onTap: () => _showInfoSheet(context, tr('privacy_policy'), tr('privacy_policy_content')),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _SettingsItem(
                icon: Icons.logout_rounded,
                label: tr('log_out'),
                isDestructive: true,
                onTap: () => _logout(context),
              ),
              const SizedBox(height: 8),
              if (profile != null && profile.isPendingDeletion)
                _SettingsItem(
                  icon: Icons.restore_rounded,
                  label: tr('cancel_account_deletion'),
                  onTap: () =>
                      context.read<ProfileBloc>().add(CancelDeletion()),
                )
              else
                _SettingsItem(
                  icon: Icons.delete_forever_rounded,
                  label: tr('delete_account'),
                  isDestructive: true,
                  onTap: () => _deleteAccount(context),
                ),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }
}

// ── Profile card ─────────────────────────────────────────────────────────────

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.profile,
    required this.name,
    required this.email,
    required this.onEdit,
  });

  final Profile? profile;
  final String name;
  final String email;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          _AvatarPicker(profile: profile),
          const SizedBox(height: 12),
          Text(
            name,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            email,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: onEdit,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(140, 40),
              side: const BorderSide(color: AppColors.textSecondary),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              tr('edit_profile'),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Settings group ────────────────────────────────────────────────────────────

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(title: title),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }
}

// ── Reliability score card ────────────────────────────────────────────────────

class _ReliabilityCard extends StatelessWidget {
  const _ReliabilityCard({required this.profile});
  final Profile profile;

  Color get _tierColor {
    switch (profile.reliabilityTier) {
      case 'TRUSTED':
        return const Color(0xFF22C55E);
      case 'NORMAL':
        return const Color(0xFF3B82F6);
      case 'RISKY':
        return const Color(0xFFF59E0B);
      case 'RESTRICTED':
        return const Color(0xFFEF4444);
      default:
        return AppColors.primary;
    }
  }

  String get _tierDescription {
    switch (profile.reliabilityTier) {
      case 'TRUSTED':    return tr('tier_trusted_desc');
      case 'NORMAL':     return tr('tier_normal_desc');
      case 'RISKY':      return tr('tier_risky_desc');
      case 'RESTRICTED': return tr('tier_restricted_desc');
      default:           return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final double fraction = (profile.reliabilityScore / 120.0).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(LoomeaTokens.radiusCard),
        border: Border.all(color: _tierColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.verified_user_rounded,
                  size: 18, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              Text(
                tr('reliability_score'),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.4,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: _tierColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  profile.tierLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _tierColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${profile.reliabilityScore}',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: _tierColor,
                  height: 1,
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 4, left: 4),
                child: Text(
                  '/ 120',
                  style: TextStyle(
                      fontSize: 14, color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 6,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation<Color>(_tierColor),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _tierDescription,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            tr('reliability_score_rule'),
            style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
                height: 1.4,
                fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }
}

// ── Pending deletion banner ───────────────────────────────────────────────────

class _PendingDeletionBanner extends StatelessWidget {
  const _PendingDeletionBanner({
    required this.daysLeft,
    required this.onCancel,
  });

  final int daysLeft;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(LoomeaTokens.radiusCard),
        border: Border.all(color: const Color(0xFFF59E0B), width: 1),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              size: 18, color: Color(0xFFB45309)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              tr('pending_deletion_msg', args: ['$daysLeft']),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF92400E),
              ),
            ),
          ),
          GestureDetector(
            onTap: onCancel,
            child: const Text(
              'Cancel',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF92400E),
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 1,
        color: AppColors.textSecondary,
      ),
    );
  }
}

class _SettingsItem extends StatelessWidget {
  const _SettingsItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? AppColors.error : AppColors.textPrimary;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: AppColors.surface,
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ),
            if (!isDestructive)
              const Icon(
                Icons.chevron_right_rounded,
                size: 22,
                color: AppColors.textSecondary,
              ),
          ],
        ),
      ),
    );
  }
}

class _AvatarPicker extends StatelessWidget {
  final Profile? profile;
  const _AvatarPicker({this.profile});

  Future<void> _pick(BuildContext context) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take a Photo'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    final file = await ImagePicker()
        .pickImage(source: source, imageQuality: 80, maxWidth: 512);
    if (file == null) return;
    final Uint8List bytes = await file.readAsBytes();
    // ignore: use_build_context_synchronously
    context.read<ProfileBloc>().add(UploadAvatar(base64Encode(bytes)));
  }

  @override
  Widget build(BuildContext context) {
    final avatarUrl = profile?.avatarUrl ?? '';
    // ApiClient is not provided in mock mode — read it defensively.
    String? token;
    try {
      token = context.read<ApiClient>().token;
    } catch (_) {}
    return GestureDetector(
      onTap: () => _pick(context),
      child: Stack(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: AppColors.surface,
            backgroundImage: avatarUrl.isNotEmpty
                ? NetworkImage(
                    resolveImageUrl(avatarUrl),
                    headers: token != null
                        ? {'Authorization': 'Bearer $token'}
                        : const {},
                  )
                : null,
            child: avatarUrl.isEmpty
                ? const Icon(Icons.person_rounded,
                    size: 40, color: AppColors.textSecondary)
                : null,
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.camera_alt_rounded,
                  size: 14, color: AppColors.onPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Biometric toggle ──────────────────────────────────────────────────────────

class _BiometricToggle extends StatefulWidget {
  const _BiometricToggle();

  @override
  State<_BiometricToggle> createState() => _BiometricToggleState();
}

class _BiometricToggleState extends State<_BiometricToggle> {
  bool _available = false;
  bool _enabled = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final bio = BiometricService.instance;
    final available = await bio.isAvailable();
    final enabled = await bio.isEnabled();
    if (!mounted) return;
    setState(() {
      _available = available;
      _enabled = enabled;
    });
  }

  Future<void> _onChanged(bool value) async {
    if (_busy) return;
    setState(() => _busy = true);
    final bio = BiometricService.instance;
    try {
      if (value) {
        // Enabling from Profile only works when we already have stored creds
        // (i.e. user logged in via password earlier and skipped the prompt).
        // Without them we can't seed the keychain, so direct them to sign out.
        final ok = await bio.authenticate();
        if (!ok) return;
        final creds = await bio.readCredentials();
        if (creds == null) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(tr('biometric_need_relogin'))),
          );
          return;
        }
        await bio.enable(email: creds.email, password: creds.password);
        setState(() => _enabled = true);
      } else {
        await bio.disable();
        setState(() => _enabled = false);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_available) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.surface, width: 1),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.fingerprint_rounded,
              size: 22, color: AppColors.textPrimary),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              tr('biometric_sign_in'),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Switch.adaptive(
            value: _enabled,
            onChanged: _busy ? null : _onChanged,
            activeColor: AppColors.accent,
          ),
        ],
      ),
    );
  }
}
