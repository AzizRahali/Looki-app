import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../data/api/api_client.dart';
import '../../../data/models/owner_salon_model.dart';
import '../../../data/models/owner_service_model.dart';
import '../../../data/models/portfolio_model.dart';
import '../../../data/models/review_model.dart';
import '../../../data/models/working_hours_model.dart';
import '../../../logic/blocs/owner_salon/owner_salon_bloc.dart';
import '../../../logic/blocs/owner_salon/owner_salon_event.dart';
import '../../../logic/blocs/owner_salon/owner_salon_state.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/loomea_tokens.dart';
import '../../core/widgets/country_phone_field.dart';
import '../../core/widgets/loomea_ui.dart';
import '../../core/utils/image_utils.dart';
import 'owner_add_post_sheet.dart' show buildPortfolioImage, OwnerAddPostSheet;
import 'owner_add_service_sheet.dart';
import 'owner_edit_service_sheet.dart';
import '../../../data/services/localization_service.dart';

class OwnerMySalonPage extends StatelessWidget {
  const OwnerMySalonPage({super.key});

  void _pushEditPage(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<OwnerSalonBloc>(),
          child: const _EditSalonPage(),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, String salonId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(LoomeaTokens.radiusCard)),
        title: const Text('Delete Salon',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary)),
        content: const Text(
          'This will permanently delete your salon, all its services and bookings. This action cannot be undone.',
          style: TextStyle(
              fontSize: 14, color: AppColors.textSecondary, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(tr('cancel'),
                style: const TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(tr('delete'),
                style: const TextStyle(
                    color: AppColors.error, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      context.read<OwnerSalonBloc>().add(DeleteSalon(salonId));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: BlocBuilder<OwnerSalonBloc, OwnerSalonState>(
        builder: (context, state) {
          if (state.status == OwnerSalonStatus.loading ||
              state.status == OwnerSalonStatus.initial) {
            return const Center(
                child: CircularProgressIndicator(color: AppColors.primary));
          }

          if (state.salon == null) {
            return _NoSalonState(onCreateSalon: () => _pushEditPage(context));
          }

          final salon = state.salon!;
          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async {
              context.read<OwnerSalonBloc>().add(const LoadMySalons());
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                  LoomeaTokens.screenPaddingH, 24,
                  LoomeaTokens.screenPaddingH, 32),
              children: [
                _SalonPageHeader(
                  onEdit: () => _pushEditPage(context),
                  onDelete: () => _confirmDelete(context, salon.id),
                ),
                const SizedBox(height: 20),
                _SalonCoverImage(salon: salon),
                const SizedBox(height: 16),
                _SalonInfoCard(salon: salon),
                const SizedBox(height: LoomeaTokens.gapLg),
                _WorkingHoursSection(salonId: salon.id, hours: state.workingHours),
                const SizedBox(height: LoomeaTokens.gapLg),
                _ServicesSection(
                  salon: salon,
                  onAdd: () => _showAddService(context, salon.id),
                  onEdit: (svc) => _showEditService(context, salon.id, svc),
                  onDelete: (svc) => context
                      .read<OwnerSalonBloc>()
                      .add(DeleteService(salon.id, svc.id)),
                ),
                const SizedBox(height: LoomeaTokens.gapLg),
                _PortfolioSection(
                  salonId: salon.id,
                  onAdd: () => _showAddPost(context, salon.id),
                  onEdit: (post) => _showEditPost(context, salon.id, post),
                  onDelete: (post) => context
                      .read<OwnerSalonBloc>()
                      .add(DeletePortfolioPost(salon.id, post.id)),
                ),
                const SizedBox(height: LoomeaTokens.gapLg),
                const _ReviewsSection(),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showAddPost(BuildContext context, String salonId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => BlocProvider.value(
        value: context.read<OwnerSalonBloc>(),
        child: OwnerAddPostSheet(salonId: salonId),
      ),
    );
  }

  void _showEditPost(BuildContext context, String salonId, PortfolioPost post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => BlocProvider.value(
        value: context.read<OwnerSalonBloc>(),
        child: OwnerAddPostSheet(salonId: salonId, post: post),
      ),
    );
  }

  void _showAddService(BuildContext context, String salonId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => BlocProvider.value(
        value: context.read<OwnerSalonBloc>(),
        child: OwnerAddServiceSheet(salonId: salonId),
      ),
    );
  }

  void _showEditService(BuildContext context, String salonId, SalonServiceItem svc) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => BlocProvider.value(
        value: context.read<OwnerSalonBloc>(),
        child: OwnerEditServiceSheet(salonId: salonId, service: svc),
      ),
    );
  }
}

// ── Widgets ──────────────────────────────────────────────────────────────────

class _NoSalonState extends StatelessWidget {
  const _NoSalonState({required this.onCreateSalon});
  final VoidCallback onCreateSalon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.storefront_outlined,
                  size: 32, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            const Text(
              'No salon yet',
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            const Text(
              'Create your salon to start\nmanaging your business',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: onCreateSalon,
              style: ElevatedButton.styleFrom(minimumSize: const Size(200, 48)),
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text('Create Salon'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SalonPageHeader extends StatelessWidget {
  const _SalonPageHeader({required this.onEdit, required this.onDelete});
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tr('my_salon'),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.025 * 30,
                  height: 1.1,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: onEdit,
          style: IconButton.styleFrom(
            backgroundColor: AppColors.surface,
            shape: const CircleBorder(),
          ),
          icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.textPrimary),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: onDelete,
          style: IconButton.styleFrom(
            backgroundColor: AppColors.error.withValues(alpha: 0.08),
            shape: const CircleBorder(),
          ),
          icon: const Icon(Icons.delete_outline_rounded,
              size: 18, color: AppColors.error),
        ),
      ],
    );
  }
}

class _SalonCoverImage extends StatelessWidget {
  const _SalonCoverImage({required this.salon});
  final OwnerSalon salon;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(LoomeaTokens.radiusHero),
      child: SizedBox(
        height: 200,
        width: double.infinity,
        child: salon.imageUrl.isNotEmpty
            ? Image.network(
                resolveImageUrl(salon.imageUrl),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => SalonImagePlaceholder(salonId: salon.id),
              )
            : SalonImagePlaceholder(salonId: salon.id),
      ),
    );
  }
}

class _SalonInfoCard extends StatelessWidget {
  const _SalonInfoCard({required this.salon});
  final OwnerSalon salon;

  @override
  Widget build(BuildContext context) {
    return LoomeaSurfaceCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            salon.name,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          if (salon.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              salon.description,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 14, height: 1.5),
            ),
          ],
          if (salon.rating > 0) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.star_rounded, color: AppColors.warning, size: 18),
                const SizedBox(width: 4),
                Text(
                  '${salon.rating.toStringAsFixed(1)} (${salon.reviewCount} reviews)',
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
                ),
              ],
            ),
          ],
          const SizedBox(height: 18),
          _DetailRow(
              icon: Icons.location_on_outlined,
              text: salon.address.isNotEmpty ? salon.address : 'No address set'),
          const SizedBox(height: 10),
          _DetailRow(
              icon: Icons.phone_outlined,
              text: salon.phone.isNotEmpty ? salon.phone : 'No phone set'),
          const SizedBox(height: 10),
          _DetailRow(
              icon: Icons.schedule_outlined,
              text: salon.openingHours.isNotEmpty ? salon.openingHours : 'Hours not set'),
          if (salon.tags.isNotEmpty) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: salon.tags
                  .map((t) => Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          t,
                          style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w500),
                        ),
                      ))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _ServicesSection extends StatelessWidget {
  const _ServicesSection({
    required this.salon,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  final OwnerSalon salon;
  final VoidCallback onAdd;
  final void Function(SalonServiceItem svc) onEdit;
  final void Function(SalonServiceItem svc) onDelete;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionListHeader(title: tr('services'), count: salon.services.length, onAdd: onAdd),
        const SizedBox(height: 12),
        if (salon.services.isEmpty)
          const LoomeaSurfaceCard(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Column(
              children: [
                Icon(Icons.spa_outlined, color: AppColors.textSecondary, size: 28),
                SizedBox(height: 10),
                Text('No services yet',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
              ],
            ),
          )
        else
          ...salon.services.map((svc) => _ServiceTile(
                svc: svc,
                onEdit: () => onEdit(svc),
                onDelete: () => onDelete(svc),
              )),
      ],
    );
  }
}

class _ServiceTile extends StatelessWidget {
  const _ServiceTile({required this.svc, required this.onEdit, required this.onDelete});
  final SalonServiceItem svc;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(LoomeaTokens.radiusCard),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.content_cut_rounded, color: AppColors.textPrimary, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(svc.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textPrimary)),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(svc.durationText,
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    Container(
                      width: 3,
                      height: 3,
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      decoration: const BoxDecoration(
                          color: AppColors.textSecondary, shape: BoxShape.circle),
                    ),
                    Text(svc.priceText,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary)),
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_horiz_rounded, color: AppColors.textSecondary, size: 20),
            onSelected: (action) {
              if (action == 'edit') onEdit();
              if (action == 'delete') onDelete();
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'edit',
                child: Row(children: [
                  const Icon(Icons.edit_outlined, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 10),
                  Text(tr('edit'), style: const TextStyle(fontSize: 14)),
                ]),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(children: [
                  const Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.error),
                  const SizedBox(width: 10),
                  Text(tr('delete'), style: const TextStyle(fontSize: 14, color: AppColors.error)),
                ]),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PortfolioSection extends StatelessWidget {
  const _PortfolioSection({
    required this.salonId,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  final String salonId;
  final VoidCallback onAdd;
  final void Function(PortfolioPost post) onEdit;
  final void Function(PortfolioPost post) onDelete;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BlocBuilder<OwnerSalonBloc, OwnerSalonState>(
          buildWhen: (p, c) => p.portfolioPosts.length != c.portfolioPosts.length,
          builder: (context, state) => _SectionListHeader(
            title: tr('portfolio'),
            count: state.portfolioPosts.length,
            onAdd: onAdd,
          ),
        ),
        const SizedBox(height: 12),
        BlocBuilder<OwnerSalonBloc, OwnerSalonState>(
          buildWhen: (p, c) => p.portfolioPosts != c.portfolioPosts,
          builder: (context, state) {
            if (state.portfolioPosts.isEmpty) {
              return LoomeaSurfaceCard(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Column(
                  children: [
                    const Icon(Icons.photo_library_outlined,
                        color: AppColors.textSecondary, size: 28),
                    const SizedBox(height: 10),
                    Text(tr('no_portfolio'),
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                    const SizedBox(height: 4),
                    const Text('Showcase your best work',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  ],
                ),
              );
            }
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.85,
              ),
              itemCount: state.portfolioPosts.length,
              itemBuilder: (context, index) {
                final post = state.portfolioPosts[index];
                return _PortfolioGridItem(
                  post: post,
                  onEdit: () => onEdit(post),
                  onDelete: () => onDelete(post),
                );
              },
            );
          },
        ),
      ],
    );
  }
}

class _PortfolioGridItem extends StatelessWidget {
  const _PortfolioGridItem({required this.post, required this.onEdit, required this.onDelete});
  final PortfolioPost post;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(LoomeaTokens.radiusCard),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                Builder(builder: (ctx) {
                  String? tok;
                  try {
                    tok = ctx.read<ApiClient>().token;
                  } catch (_) {}
                  return buildPortfolioImage(post.imageUrl, BoxFit.cover, token: tok);
                }),
                Positioned(
                  top: 6,
                  left: 6,
                  child: _PortfolioIconButton(
                    onTap: onEdit,
                    icon: Icons.edit_outlined,
                    iconColor: AppColors.textPrimary,
                  ),
                ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: _PortfolioIconButton(
                    onTap: onDelete,
                    icon: Icons.close_rounded,
                    iconColor: AppColors.error,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Text(
              post.caption,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

class _PortfolioIconButton extends StatelessWidget {
  const _PortfolioIconButton({required this.onTap, required this.icon, required this.iconColor});
  final VoidCallback onTap;
  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: AppColors.background.withValues(alpha: 0.85),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 14, color: iconColor),
      ),
    );
  }
}

class _ReviewsSection extends StatelessWidget {
  const _ReviewsSection();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OwnerSalonBloc, OwnerSalonState>(
      buildWhen: (p, c) => p.reviews != c.reviews,
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(tr('reviews'),
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                const SizedBox(width: 8),
                if (state.reviews.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text('${state.reviews.length}',
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary)),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (state.reviews.isEmpty)
              LoomeaSurfaceCard(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Column(
                  children: [
                    const Icon(Icons.rate_review_outlined,
                        color: AppColors.textSecondary, size: 28),
                    const SizedBox(height: 10),
                    Text(tr('no_reviews'),
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                    const SizedBox(height: 4),
                    const Text('Reviews from clients will appear here',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  ],
                ),
              )
            else
              ...state.reviews.map((review) => _ReviewCard(review: review)),
          ],
        );
      },
    );
  }
}

class _SectionListHeader extends StatelessWidget {
  const _SectionListHeader({required this.title, required this.count, required this.onAdd});
  final String title;
  final int count;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title,
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        const SizedBox(width: 8),
        if (count > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text('$count',
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
          ),
        const Spacer(),
        TextButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('Add'),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.textPrimary,
            backgroundColor: AppColors.primary.withValues(alpha: 0.12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final Review review;
  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(LoomeaTokens.radiusCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.inputBackground,
                backgroundImage: review.userAvatar.isNotEmpty
                    ? NetworkImage(resolveImageUrl(review.userAvatar))
                    : null,
                onBackgroundImageError:
                    review.userAvatar.isNotEmpty ? (_, __) {} : null,
                child: review.userAvatar.isEmpty
                    ? Text(
                        review.userName.isNotEmpty
                            ? review.userName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                            fontSize: 15),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(review.userName,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: AppColors.textPrimary)),
                    const SizedBox(height: 2),
                    Text(
                      review.createdAt.length >= 10
                          ? review.createdAt.substring(0, 10)
                          : review.createdAt,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (i) {
                  return Icon(
                    i < review.rating
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: AppColors.warning,
                    size: 16,
                  );
                }),
              ),
            ],
          ),
          if (review.comment.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(review.comment,
                style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                    height: 1.4)),
          ],
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _DetailRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 17, color: AppColors.textSecondary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 14)),
        ),
      ],
    );
  }
}

// ─── Inline Edit Salon Page ────────────────────────────────────────────

class _EditSalonPage extends StatefulWidget {
  const _EditSalonPage();

  @override
  State<_EditSalonPage> createState() => _EditSalonPageState();
}

class _EditSalonPageState extends State<_EditSalonPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _hoursCtrl;
  late final TextEditingController _tagsCtrl;
  late Country _selectedCountry;
  bool _isNew = true;

  Uint8List? _pickedImageBytes;
  String? _pickedBase64;

  @override
  void initState() {
    super.initState();
    final salon = context.read<OwnerSalonBloc>().state.salon;
    _isNew = salon == null;
    _nameCtrl = TextEditingController(text: salon?.name ?? '');
    _descCtrl = TextEditingController(text: salon?.description ?? '');
    _addressCtrl = TextEditingController(text: salon?.address ?? '');
    final (country, local) = parseStoredPhone(salon?.phone ?? '');
    _selectedCountry = country;
    _phoneCtrl = TextEditingController(text: local);
    _hoursCtrl = TextEditingController(text: salon?.openingHours ?? '');
    _tagsCtrl = TextEditingController(text: salon?.tags.join(', ') ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    _hoursCtrl.dispose();
    _tagsCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final xFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 900,
      imageQuality: 85,
    );
    if (xFile == null) return;
    final bytes = await xFile.readAsBytes();
    setState(() {
      _pickedImageBytes = bytes;
      _pickedBase64 = base64Encode(bytes);
    });
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final data = <String, dynamic>{
      'name': _nameCtrl.text.trim(),
      'description': _descCtrl.text.trim(),
      'address': _addressCtrl.text.trim(),
      'phone': _phoneCtrl.text.trim().isEmpty
          ? ''
          : CountryPhoneField.fullNumber(
              _selectedCountry, _phoneCtrl.text.trim()),
      'openingHours': _hoursCtrl.text.trim(),
      'tags': _tagsCtrl.text
          .split(',')
          .map((t) => t.trim())
          .where((t) => t.isNotEmpty)
          .toList(),
    };
    final bloc = context.read<OwnerSalonBloc>();
    if (_isNew) {
      bloc.add(CreateSalon(data));
    } else {
      bloc.add(UpdateSalon(bloc.state.salon!.id, data));
      // For existing salon, queue the image upload immediately after the update
      if (_pickedBase64 != null) {
        bloc.add(UploadSalonImage(bloc.state.salon!.id, _pickedBase64!));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isNew ? tr('add_service') : tr('edit_salon')),
        leading: LoomeaAppBarLeading(onPressed: () => Navigator.pop(context)),
      ),
      body: BlocConsumer<OwnerSalonBloc, OwnerSalonState>(
        listenWhen: (prev, curr) =>
            prev.status == OwnerSalonStatus.saving &&
            (curr.status == OwnerSalonStatus.loaded ||
                curr.status == OwnerSalonStatus.error),
        listener: (context, state) {
          if (state.status == OwnerSalonStatus.loaded) {
            // For a newly-created salon, fire image upload now that we have the ID
            if (_isNew && _pickedBase64 != null && state.salon != null) {
              context
                  .read<OwnerSalonBloc>()
                  .add(UploadSalonImage(state.salon!.id, _pickedBase64!));
              return; // stay on page while image uploads; next loaded event will pop
            }
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Row(children: [
                const Icon(Icons.check_circle_rounded,
                    color: Colors.white, size: 18),
                const SizedBox(width: 10),
                Text(_isNew ? 'Salon created!' : 'Salon updated!'),
              ]),
              backgroundColor: AppColors.success,
            ));
            Navigator.pop(context);
          } else if (state.status == OwnerSalonStatus.error) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(state.error ?? 'Failed'),
              backgroundColor: AppColors.error,
            ));
          }
        },
        builder: (context, state) {
          final isSaving = state.status == OwnerSalonStatus.saving;
          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                  LoomeaTokens.screenPaddingH, 12,
                  LoomeaTokens.screenPaddingH, 40),
              children: [
                // ── Cover image picker ──
                _CoverImagePicker(
                  currentImageUrl: context
                      .read<OwnerSalonBloc>()
                      .state
                      .salon
                      ?.imageUrl,
                  pickedBytes: _pickedImageBytes,
                  onPick: _pickImage,
                ),
                const SizedBox(height: 20),
                LoomeaLabeledField(
                  label: 'Salon Name',
                  icon: Icons.storefront_outlined,
                  child: TextFormField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(
                        hintText: 'Enter salon name'),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Name is required'
                        : null,
                  ),
                ),
                const SizedBox(height: 12),
                LoomeaLabeledField(
                  label: 'Description',
                  icon: Icons.notes_rounded,
                  child: TextFormField(
                    controller: _descCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                        hintText: 'Describe your salon'),
                  ),
                ),
                const SizedBox(height: LoomeaTokens.gapLg),
                LoomeaLabeledField(
                  label: 'Address',
                  icon: Icons.location_on_outlined,
                  child: TextFormField(
                    controller: _addressCtrl,
                    decoration: const InputDecoration(
                        hintText: 'Enter address'),
                  ),
                ),
                const SizedBox(height: 12),
                LoomeaLabeledField(
                  label: 'Phone',
                  icon: Icons.phone_outlined,
                  child: CountryPhoneField(
                    controller: _phoneCtrl,
                    selectedCountry: _selectedCountry,
                    onCountryChanged: (c) =>
                        setState(() => _selectedCountry = c),
                    onChanged: (_) => setState(() {}),
                    hintText: '55 100 200',
                  ),
                ),
                const SizedBox(height: 12),
                LoomeaLabeledField(
                  label: 'Opening Hours',
                  icon: Icons.schedule_outlined,
                  child: TextFormField(
                    controller: _hoursCtrl,
                    decoration: const InputDecoration(
                        hintText: 'e.g. Mon-Fri 9:00-18:00'),
                  ),
                ),
                const SizedBox(height: LoomeaTokens.gapLg),
                LoomeaLabeledField(
                  label: 'Tags',
                  icon: Icons.local_offer_outlined,
                  child: TextFormField(
                    controller: _tagsCtrl,
                    decoration: const InputDecoration(
                        hintText: 'Comma separated, e.g. Hair, Nails'),
                  ),
                ),
                const SizedBox(height: 36),
                ElevatedButton(
                  onPressed: isSaving ? null : _save,
                  child: isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.onPrimary))
                      : Text(_isNew ? tr('add_service') : tr('save')),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Cover image picker widget ────────────────────────────────────────────────

class _CoverImagePicker extends StatelessWidget {
  final String? currentImageUrl;
  final Uint8List? pickedBytes;
  final VoidCallback onPick;

  const _CoverImagePicker({
    required this.currentImageUrl,
    required this.pickedBytes,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    Widget imageChild;

    if (pickedBytes != null) {
      imageChild = Image.memory(pickedBytes!, fit: BoxFit.cover);
    } else if (currentImageUrl != null && currentImageUrl!.isNotEmpty) {
      imageChild = Image.network(
        resolveImageUrl(currentImageUrl!),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    } else {
      imageChild = _placeholder();
    }

    return GestureDetector(
      onTap: onPick,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(LoomeaTokens.radiusCard),
        child: Stack(
          children: [
            SizedBox(
              width: double.infinity,
              height: 180,
              child: imageChild,
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.45),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 12,
              right: 12,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.camera_alt_rounded,
                        size: 15, color: AppColors.onPrimary),
                    SizedBox(width: 6),
                    Text(
                      'Change photo',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
        color: AppColors.inputBackground,
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_photo_alternate_rounded,
                  size: 36, color: AppColors.textSecondary),
              SizedBox(height: 8),
              Text('Add cover photo',
                  style: TextStyle(
                      fontSize: 13, color: AppColors.textSecondary)),
            ],
          ),
        ),
      );
}

// ── Working Hours ─────────────────────────────────────────────────────────────

class _WorkingHoursSection extends StatelessWidget {
  final String salonId;
  final List<WorkingHoursModel> hours;
  const _WorkingHoursSection({required this.salonId, required this.hours});

  static const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  String _fmt(WorkingHoursModel h) {
    if (h.closed) return 'Closed';
    return '${h.openTime} – ${h.closeTime}';
  }

  @override
  Widget build(BuildContext context) {
    final display = hours.isNotEmpty
        ? hours
        : WorkingHoursModel.defaultSchedule();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(tr('working_hours'),
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary)),
            const Spacer(),
            GestureDetector(
              onTap: () => _showEdit(context),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.edit_outlined,
                        size: 14, color: AppColors.textPrimary),
                    const SizedBox(width: 6),
                    Text(tr('edit'),
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary)),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        LoomeaSurfaceCard(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            children: List.generate(display.length, (i) {
              final h = display[i];
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 11),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 36,
                          child: Text(_days[h.dayOfWeek],
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary)),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _fmt(h),
                          style: TextStyle(
                              fontSize: 13,
                              color: h.closed
                                  ? AppColors.textSecondary
                                  : AppColors.textPrimary),
                        ),
                      ],
                    ),
                  ),
                  if (i < display.length - 1)
                    const Divider(height: 1, indent: 16, endIndent: 16),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }

  void _showEdit(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => BlocProvider.value(
        value: context.read<OwnerSalonBloc>(),
        child: _WorkingHoursSheet(
          salonId: salonId,
          initial: hours.isNotEmpty
              ? hours
              : WorkingHoursModel.defaultSchedule(),
        ),
      ),
    );
  }
}

class _WorkingHoursSheet extends StatefulWidget {
  final String salonId;
  final List<WorkingHoursModel> initial;
  const _WorkingHoursSheet({required this.salonId, required this.initial});

  @override
  State<_WorkingHoursSheet> createState() => _WorkingHoursSheetState();
}

class _WorkingHoursSheetState extends State<_WorkingHoursSheet> {
  late List<WorkingHoursModel> _hours;

  @override
  void initState() {
    super.initState();
    _hours = List.of(widget.initial);
  }

  Future<void> _pickTime(
      BuildContext context, int index, bool isOpen) async {
    final h = _hours[index];
    final parts = (isOpen ? h.openTime : h.closeTime).split(':');
    final initial = TimeOfDay(
        hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked == null) return;
    final str =
        '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    setState(() {
      _hours[index] = isOpen
          ? h.copyWith(openTime: str)
          : h.copyWith(closeTime: str);
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<OwnerSalonBloc, OwnerSalonState>(
      listenWhen: (prev, curr) =>
          prev.status == OwnerSalonStatus.saving &&
          curr.status == OwnerSalonStatus.loaded,
      listener: (_, __) => Navigator.pop(context),
      child: Padding(
        padding: const EdgeInsets.only(
            left: LoomeaTokens.screenPaddingH,
            right: LoomeaTokens.screenPaddingH,
            top: 16),
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36, height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  const Icon(Icons.schedule_rounded,
                      color: AppColors.textPrimary, size: 20),
                  const SizedBox(width: 10),
                  Text(tr('working_hours'),
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary)),
                ],
              ),
              const SizedBox(height: 20),
              ..._hours.map((h) {
                final i = h.dayOfWeek;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 40,
                        child: Text(h.dayName.substring(0, 3),
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: h.closed
                            ? Container(
                                height: 40,
                                decoration: BoxDecoration(
                                  color: AppColors.inputBackground,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Center(
                                  child: Text('Closed',
                                      style: TextStyle(
                                          fontSize: 13,
                                          color: AppColors.textSecondary)),
                                ),
                              )
                            : Row(
                                children: [
                                  Expanded(
                                    child: _TimeButton(
                                      label: h.openTime,
                                      onTap: () =>
                                          _pickTime(context, i, true),
                                    ),
                                  ),
                                  const Padding(
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 6),
                                    child: Text('–',
                                        style: TextStyle(
                                            color: AppColors.textSecondary)),
                                  ),
                                  Expanded(
                                    child: _TimeButton(
                                      label: h.closeTime,
                                      onTap: () =>
                                          _pickTime(context, i, false),
                                    ),
                                  ),
                                ],
                              ),
                      ),
                      const SizedBox(width: 8),
                      Switch(
                        value: !h.closed,
                        activeColor: AppColors.primary,
                        onChanged: (val) => setState(() {
                          _hours[i] = h.copyWith(closed: !val);
                        }),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 8),
              BlocBuilder<OwnerSalonBloc, OwnerSalonState>(
                builder: (context, state) {
                  final saving = state.status == OwnerSalonStatus.saving;
                  return ElevatedButton(
                    onPressed: saving
                        ? null
                        : () => context
                            .read<OwnerSalonBloc>()
                            .add(SaveWorkingHours(widget.salonId, _hours)),
                    child: saving
                        ? const SizedBox(
                            height: 20, width: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.onPrimary))
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_rounded, size: 18),
                              SizedBox(width: 8),
                              Text('Save Hours'),
                            ],
                          ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimeButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _TimeButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.inputBackground,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(label,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary)),
        ),
      ),
    );
  }
}
