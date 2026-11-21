import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../data/api/api_client.dart';
import '../../../data/models/profile_model.dart';
import '../../../data/repositories/loomea_repository.dart';
import '../../../data/services/biometric_service.dart';
import '../../../logic/blocs/auth/auth_bloc.dart';
import '../../../logic/blocs/auth/auth_event.dart';
import '../../../logic/blocs/owner_profile/owner_profile_bloc.dart';
import '../../../logic/blocs/owner_profile/owner_profile_event.dart';
import '../../../logic/blocs/owner_profile/owner_profile_state.dart';

import '../../core/routes/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/loomea_tokens.dart';
import '../../core/utils/image_utils.dart';
import '../../core/widgets/country_phone_field.dart';
import '../../core/widgets/loomea_ui.dart';
import '../../../data/services/localization_service.dart';

class OwnerProfilePage extends StatelessWidget {
  const OwnerProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: BlocBuilder<OwnerProfileBloc, OwnerProfileState>(
        builder: (context, state) {
          if (state.status == OwnerProfileStatus.loading ||
              state.status == OwnerProfileStatus.initial) {
            return const Center(
                child: CircularProgressIndicator(color: AppColors.primary));
          }

          final profile = state.profile;
          return ListView(
            padding: const EdgeInsets.fromLTRB(
                LoomeaTokens.screenPaddingH, 24,
                LoomeaTokens.screenPaddingH, 40),
            children: [
              Text(tr('profile'),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.025 * 30,
                    height: 1.1,
                    color: AppColors.textPrimary,
                  )),
              const SizedBox(height: 28),

              _ProfileHeader(
                profile: profile,
                onEdit: () => _showEditSheet(context),
              ),
              const SizedBox(height: 32),

              // Account section
              const _SectionTitle('ACCOUNT'),
              const SizedBox(height: 12),
              LoomeaSurfaceCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _SettingsItem(
                      icon: Icons.mail_outline_rounded,
                      label: 'Email',
                      trailing: Text(
                        profile?.email ?? '',
                        style: const TextStyle(
                            fontSize: 14, color: AppColors.textSecondary),
                      ),
                    ),
                    const Divider(height: 1, indent: 52),
                    _SettingsItem(
                      icon: Icons.phone_outlined,
                      label: 'Phone',
                      trailing: Text(
                        profile?.phone.isNotEmpty == true
                            ? profile!.phone
                            : 'Not set',
                        style: const TextStyle(
                            fontSize: 14, color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              _SectionTitle(tr('preferences')),
              const SizedBox(height: 12),
              LoomeaSurfaceCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _SettingsItem(
                      icon: Icons.workspace_premium_outlined,
                      label: tr('subscription'),
                      onTap: () =>
                          context.pushNamed(AppRoute.ownerSubscription.name),
                    ),
                    const Divider(height: 1, indent: 52),
                    _SettingsItem(
                      icon: Icons.notifications_none_rounded,
                      label: tr('notifications'),
                      onTap: () => context.pushNamed(AppRoute.ownerNotifications.name),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              _SectionTitle(tr('support')),
              const SizedBox(height: 12),
              LoomeaSurfaceCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _SettingsItem(
                      icon: Icons.help_outline_rounded,
                      label: tr('help_support'),
                      onTap: () => context.pushNamed(AppRoute.supportChat.name, extra: true),
                    ),
                    const Divider(height: 1, indent: 52),
                    _SettingsItem(
                      icon: Icons.description_outlined,
                      label: tr('terms_of_service'),
                      onTap: () {},
                    ),
                    const Divider(height: 1, indent: 52),
                    _SettingsItem(
                      icon: Icons.shield_outlined,
                      label: tr('privacy_policy'),
                      onTap: () {},
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              LoomeaSurfaceCard(
                padding: EdgeInsets.zero,
                child: _SettingsItem(
                  icon: Icons.logout_rounded,
                  label: tr('log_out'),
                  isDestructive: true,
                  onTap: () => _confirmSignOut(context),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEditSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => BlocProvider.value(
        value: context.read<OwnerProfileBloc>(),
        child: const _EditProfileSheet(),
      ),
    );
  }

  void _confirmSignOut(BuildContext context) {
    final authBloc = context.read<AuthBloc>();
    final repo = context.read<LoomeeaRepository>();
    final router = GoRouter.of(context);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(tr('sign_out'),
            style: const TextStyle(
                fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        content: Text(tr('sign_out_confirm'),
            style: const TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(tr('cancel'),
                style: const TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              // clearToken() sets _accessToken = null synchronously as its
              // very first line, so isLoggedIn is already false before
              // goNamed fires — no need to await the SharedPreferences flush.
              repo.logout();
              BiometricService.instance.disable();
              authBloc.add(LogoutRequested());
              router.goNamed(AppRoute.signIn.name);
            },
            child: Text(tr('sign_out'),
                style: const TextStyle(
                    color: AppColors.error, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

// ── Widgets ──────────────────────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.profile, required this.onEdit});
  final Profile? profile;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          _OwnerAvatarPicker(profile: profile),
          const SizedBox(height: 14),
          Text(
            profile?.fullName ?? '',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            profile?.email ?? '',
            style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: onEdit,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(160, 40),
              padding: const EdgeInsets.symmetric(horizontal: 24),
            ),
            child: Text(tr('edit_profile')),
          ),
        ],
      ),
    );
  }
}

// ── Edit Profile Sheet ──────────────────────────────────────────────

class _EditProfileSheet extends StatefulWidget {
  const _EditProfileSheet();

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late Country _selectedCountry;

  @override
  void initState() {
    super.initState();
    final profile = context.read<OwnerProfileBloc>().state.profile;
    _nameCtrl = TextEditingController(text: profile?.fullName ?? '');
    final (country, local) = parseStoredPhone(profile?.phone ?? '');
    _selectedCountry = country;
    _phoneCtrl = TextEditingController(text: local);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    context.read<OwnerProfileBloc>().add(UpdateOwnerProfile(
          fullName: _nameCtrl.text.trim(),
          phone: _phoneCtrl.text.trim().isEmpty
              ? ''
              : CountryPhoneField.fullNumber(
                  _selectedCountry, _phoneCtrl.text.trim()),
        ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<OwnerProfileBloc, OwnerProfileState>(
      listenWhen: (prev, curr) =>
          prev.status == OwnerProfileStatus.updating &&
          (curr.status == OwnerProfileStatus.loaded ||
              curr.status == OwnerProfileStatus.error),
      listener: (context, state) {
        if (state.status == OwnerProfileStatus.loaded) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Profile updated'),
            backgroundColor: AppColors.success,
          ));
        } else if (state.status == OwnerProfileStatus.error) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(state.error ?? 'Update failed'),
            backgroundColor: AppColors.error,
          ));
        }
      },
      builder: (context, state) {
        final isUpdating = state.status == OwnerProfileStatus.updating;
        return Padding(
          padding: EdgeInsets.fromLTRB(
              LoomeaTokens.screenPaddingH, 16, LoomeaTokens.screenPaddingH,
              MediaQuery.of(context).viewInsets.bottom + 24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    const Icon(Icons.person_outline_rounded,
                        color: AppColors.textPrimary, size: 20),
                    const SizedBox(width: 10),
                    Text(tr('edit_profile'),
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary)),
                  ],
                ),
                const SizedBox(height: LoomeaTokens.gapLg),

                // Email (read-only)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.lock_outline_rounded,
                          color: AppColors.textSecondary, size: 18),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Email',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary)),
                            const SizedBox(height: 2),
                            Text(state.profile?.email ?? '',
                                style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 14)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                LoomeaLabeledField(
                  label: 'Full Name',
                  child: TextFormField(
                    controller: _nameCtrl,
                    decoration:
                        const InputDecoration(hintText: 'Enter your name'),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Name cannot be empty';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 12),
                LoomeaLabeledField(
                  label: 'Phone',
                  child: CountryPhoneField(
                    controller: _phoneCtrl,
                    selectedCountry: _selectedCountry,
                    onCountryChanged: (c) =>
                        setState(() => _selectedCountry = c),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(height: LoomeaTokens.gapLg),

                ElevatedButton(
                  onPressed: isUpdating ? null : _save,
                  child: isUpdating
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppColors.onPrimary))
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check_rounded, size: 18),
                            const SizedBox(width: 8),
                            Text(tr('save')),
                          ],
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Shared Widgets ──────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
            letterSpacing: 1));
  }
}

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool isDestructive;

  const _SettingsItem({
    required this.icon,
    required this.label,
    this.trailing,
    this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? AppColors.error : AppColors.textPrimary;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 16),
            Expanded(
              child: Text(label,
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: color)),
            ),
            if (trailing != null)
              trailing!
            else if (onTap != null)
              const Icon(Icons.chevron_right_rounded,
                  size: 20, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

class _OwnerAvatarPicker extends StatelessWidget {
  final Profile? profile;
  const _OwnerAvatarPicker({this.profile});

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
    context.read<OwnerProfileBloc>().add(UploadOwnerAvatar(base64Encode(bytes)));
  }

  @override
  Widget build(BuildContext context) {
    final avatarUrl = profile?.avatarUrl ?? '';
    // ApiClient is not provided in mock mode — read it defensively.
    String? token;
    try {
      token = context.read<ApiClient>().token;
    } catch (_) {}
    final initials = profile?.firstName.isNotEmpty == true
        ? profile!.firstName[0].toUpperCase()
        : 'O';
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
                ? Text(initials,
                    style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary))
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
