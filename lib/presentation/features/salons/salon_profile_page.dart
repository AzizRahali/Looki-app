import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../data/api/api_client.dart';
import '../../../data/models/portfolio_model.dart';
import '../../../data/models/review_model.dart';
import '../../../data/models/salon_model.dart';
import '../../../data/models/service_model.dart';
import '../../../data/repositories/loomea_repository.dart';
import '../../../logic/blocs/profile/profile_bloc.dart';
import '../../../logic/blocs/profile/profile_event.dart';
import '../../../logic/blocs/profile/profile_state.dart';
import '../../../logic/blocs/salon/salon_bloc.dart';
import '../../../logic/blocs/salon/salon_event.dart';
import '../../../logic/blocs/salon/salon_state.dart';
import '../../core/routes/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/loomea_tokens.dart';
import '../../core/utils/icon_mapper.dart';
import '../../core/widgets/loomea_ui.dart' show SalonImagePlaceholder;
import '../../core/utils/image_utils.dart';
import '../owner/owner_add_post_sheet.dart' show buildPortfolioImage;
import '../../../data/services/localization_service.dart';

class SalonProfilePage extends StatefulWidget {
  const SalonProfilePage({super.key, required this.salonName});

  final String salonName;

  @override
  State<SalonProfilePage> createState() => _SalonProfilePageState();
}

class _SalonProfilePageState extends State<SalonProfilePage> {
  /// Incremented each time a review is submitted to force _ReviewsList rebuild.
  int _reviewsRefreshKey = 0;

  @override
  void initState() {
    super.initState();
    context.read<SalonBloc>().add(LoadSalonByName(widget.salonName));
  }

  void _showWriteReview(BuildContext context, String salonId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _WriteReviewSheet(
        onSubmit: (rating, comment) async {
          final repo = context.read<LoomeeaRepository>();
          await repo.createReview(
            salonId: salonId,
            rating: rating,
            comment: comment,
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Review submitted!'),
                behavior: SnackBarBehavior.floating,
                backgroundColor: AppColors.success,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            );
            context.read<SalonBloc>().add(LoadSalonByName(widget.salonName));
            setState(() => _reviewsRefreshKey++);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SalonBloc, SalonState>(
      buildWhen: (prev, curr) =>
          prev.selectedSalon != curr.selectedSalon ||
          prev.selectedServiceIds != curr.selectedServiceIds,
      builder: (context, state) {
        final salon = state.selectedSalon;

        if (salon == null) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return BlocBuilder<ProfileBloc, ProfileState>(
          buildWhen: (prev, curr) =>
              prev.isSalonSaved(salon.id) != curr.isSalonSaved(salon.id),
          builder: (context, profileState) {
            final isSaved = profileState.isSalonSaved(salon.id);
            final hasServices = state.selectedServicesCount > 0;

            return Scaffold(
              backgroundColor: AppColors.background,
              body: SafeArea(
                top: false,
                child: Column(
                  children: [
                    Expanded(
                      child: CustomScrollView(
                        slivers: [
                          _SalonHeroAppBar(
                            salon: salon,
                            isSaved: isSaved,
                            onToggleSave: () => context
                                .read<ProfileBloc>()
                                .add(ToggleSavedSalon(salon.id)),
                          ),
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: LoomeaTokens.screenPaddingH),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 16),
                                  _SalonInfoSection(salon: salon),
                                  const SizedBox(height: LoomeaTokens.gapLg),
                                  _SectionHeader(title: tr('services')),
                                  const SizedBox(height: 12),
                                  ...salon.services.map((service) =>
                                      _ServiceTile(
                                        service: service,
                                        isAdded: state.selectedServiceIds
                                            .contains(service.id),
                                        onToggle: () => context
                                            .read<SalonBloc>()
                                            .add(ToggleService(service.id)),
                                      )),
                                  const SizedBox(height: LoomeaTokens.gapLg),
                                  _SectionHeader(title: tr('portfolio')),
                                  const SizedBox(height: 12),
                                  _PortfolioGrid(salonId: salon.id),
                                  const SizedBox(height: LoomeaTokens.gapLg),
                                  _ReviewsHeader(
                                    rating: salon.rating,
                                    onWriteReview: () =>
                                        _showWriteReview(context, salon.id),
                                  ),
                                  const SizedBox(height: 12),
                                  _ReviewsList(
                                    key: ValueKey(_reviewsRefreshKey),
                                    salonId: salon.id,
                                  ),
                                  const SizedBox(height: 100),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    _BookingBar(
                      selectedCount: state.selectedServicesCount,
                      totalPrice: state.selectedServicesTotal,
                      hasServices: hasServices,
                      onBook: () =>
                          context.pushNamed(AppRoute.selectTimeSlot.name),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Hero app bar
// ─────────────────────────────────────────────────────────────────────────────

class _SalonHeroAppBar extends StatelessWidget {
  const _SalonHeroAppBar({
    required this.salon,
    required this.isSaved,
    required this.onToggleSave,
  });

  final Salon salon;
  final bool isSaved;
  final VoidCallback onToggleSave;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      leading: Padding(
        padding: const EdgeInsets.only(left: 8),
        child: Center(
          child: _CircleIconButton(
            onPressed: () => context.pop(),
            child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Center(
            child: _CircleIconButton(
              onPressed: onToggleSave,
              child: Icon(
                isSaved
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                size: 18,
                color: isSaved ? AppColors.error : AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: salon.imageUrl.isNotEmpty
            ? Image.network(
                resolveImageUrl(salon.imageUrl),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    SalonImagePlaceholder(salonId: salon.id),
              )
            : SalonImagePlaceholder(salonId: salon.id),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.onPressed, required this.child});

  final VoidCallback onPressed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.9),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: child,
        padding: EdgeInsets.zero,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Salon info
// ─────────────────────────────────────────────────────────────────────────────

class _SalonInfoSection extends StatelessWidget {
  const _SalonInfoSection({required this.salon});

  final Salon salon;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      salon.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.4,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  if (salon.isVerified) ...[
                    const SizedBox(width: 6),
                    const Icon(Icons.verified_rounded,
                        size: 18, color: AppColors.accent),
                  ],
                ],
              ),
              const SizedBox(height: 6),
              _InfoRow(
                icon: Icons.location_on_outlined,
                child: Text(salon.fullAddress,
                    style: const TextStyle(
                        fontSize: 14, color: AppColors.textSecondary)),
              ),
              const SizedBox(height: 4),
              _InfoRow(
                icon: Icons.schedule_rounded,
                child: Text(
                  '${salon.openTime} – ${salon.closeTime}',
                  style: const TextStyle(fontSize: 14, color: AppColors.success),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        _RatingBadge(rating: salon.rating),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.child});

  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Expanded(child: child),
      ],
    );
  }
}

class _RatingBadge extends StatelessWidget {
  const _RatingBadge({required this.rating});

  final double rating;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.textPrimary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, size: 14, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            rating.toString(),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section header
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reviews header
// ─────────────────────────────────────────────────────────────────────────────

class _ReviewsHeader extends StatelessWidget {
  const _ReviewsHeader({required this.rating, required this.onWriteReview});

  final double rating;
  final VoidCallback onWriteReview;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _SectionHeader(title: tr('reviews')),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.star_rounded,
                  size: 13, color: Color(0xFFFFC107)),
              const SizedBox(width: 3),
              Text(
                rating.toString(),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        TextButton.icon(
          onPressed: onWriteReview,
          icon: const Icon(Icons.rate_review_outlined, size: 16),
          label: Text(tr('write_review')),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.textPrimary,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            textStyle:
                const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom booking bar
// ─────────────────────────────────────────────────────────────────────────────

class _BookingBar extends StatelessWidget {
  const _BookingBar({
    required this.selectedCount,
    required this.totalPrice,
    required this.hasServices,
    required this.onBook,
  });

  final int selectedCount;
  final double totalPrice;
  final bool hasServices;
  final VoidCallback onBook;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
          LoomeaTokens.screenPaddingH, 12, LoomeaTokens.screenPaddingH, 16),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(
            top: BorderSide(color: AppColors.border.withValues(alpha: 0.5))),
      ),
      child: Row(
        children: [
          Expanded(child: _BookingBarInfo(
            selectedCount: selectedCount,
            totalPrice: totalPrice,
            hasServices: hasServices,
          )),
          IconButton(
            onPressed: hasServices ? onBook : null,
            icon: Icon(
              Icons.schedule_rounded,
              size: 28,
              color: hasServices
                  ? AppColors.textPrimary
                  : AppColors.textSecondary.withValues(alpha: 0.4),
            ),
            tooltip: tr('schedule'),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

class _BookingBarInfo extends StatelessWidget {
  const _BookingBarInfo({
    required this.selectedCount,
    required this.totalPrice,
    required this.hasServices,
  });

  final int selectedCount;
  final double totalPrice;
  final bool hasServices;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          hasServices
              ? tr(selectedCount > 1 ? 'n_services_selected' : 'n_service_selected', args: ['$selectedCount'])
              : tr('select_at_least_one_service'),
          style: TextStyle(
            fontSize: 13,
            color: hasServices
                ? AppColors.textSecondary
                : AppColors.textSecondary.withValues(alpha: 0.6),
          ),
        ),
        if (hasServices) ...[
          const SizedBox(height: 2),
          Text(
            '${formatPrice(totalPrice)} ${tr('total')}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Write review sheet
// ─────────────────────────────────────────────────────────────────────────────

class _WriteReviewSheet extends StatefulWidget {
  const _WriteReviewSheet({required this.onSubmit});

  final Future<void> Function(int rating, String comment) onSubmit;

  @override
  State<_WriteReviewSheet> createState() => _WriteReviewSheetState();
}

class _WriteReviewSheetState extends State<_WriteReviewSheet> {
  int _rating = 0;
  final _commentCtrl = TextEditingController();

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: LoomeaTokens.screenPaddingH,
        right: LoomeaTokens.screenPaddingH,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
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
          Text(
            tr('write_review'),
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary),
          ),
          const SizedBox(height: 20),
          _StarRatingRow(
            rating: _rating,
            onRate: (r) => setState(() => _rating = r),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _commentCtrl,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: tr('share_experience'),
              filled: true,
              fillColor: AppColors.inputBackground,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(LoomeaTokens.radiusInput),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: _rating > 0
                  ? () {
                      Navigator.of(context).pop();
                      widget.onSubmit(_rating, _commentCtrl.text.trim());
                    }
                  : null,
              child: Text(tr('submit')),
            ),
          ),
        ],
      ),
    );
  }
}

class _StarRatingRow extends StatelessWidget {
  const _StarRatingRow({required this.rating, required this.onRate});

  final int rating;
  final ValueChanged<int> onRate;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        5,
        (i) => GestureDetector(
          onTap: () => onRate(i + 1),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Icon(
              i < rating ? Icons.star_rounded : Icons.star_outline_rounded,
              size: 36,
              color: i < rating
                  ? const Color(0xFFFFC107)
                  : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Action button
// ─────────────────────────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(LoomeaTokens.radiusInput),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(LoomeaTokens.radiusInput),
          child: SizedBox(
            height: 44,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 18, color: AppColors.textPrimary),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Service tile
// ─────────────────────────────────────────────────────────────────────────────

class _ServiceTile extends StatelessWidget {
  const _ServiceTile({
    required this.service,
    required this.isAdded,
    required this.onToggle,
  });

  final Service service;
  final bool isAdded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(LoomeaTokens.radiusCard),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.inputBackground,
            child: Icon(IconMapper.fromString(service.icon),
                size: 20, color: AppColors.textPrimary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(service.name,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text('${service.durationText}  ·  ${service.priceText}',
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textSecondary)),
              ],
            ),
          ),
          _AddToggleButton(isAdded: isAdded, onToggle: onToggle),
        ],
      ),
    );
  }
}

class _AddToggleButton extends StatelessWidget {
  const _AddToggleButton({required this.isAdded, required this.onToggle});

  final bool isAdded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isAdded ? AppColors.primary : AppColors.background,
          borderRadius: BorderRadius.circular(LoomeaTokens.radiusPill),
          border: Border.all(
              color: isAdded ? AppColors.primary : AppColors.border),
        ),
        child: Text(
          isAdded ? 'ADDED' : 'ADD',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color:
                isAdded ? AppColors.onPrimary : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Portfolio
// ─────────────────────────────────────────────────────────────────────────────

class _PortfolioGrid extends StatefulWidget {
  const _PortfolioGrid({required this.salonId});

  final String salonId;

  @override
  State<_PortfolioGrid> createState() => _PortfolioGridState();
}

class _PortfolioGridState extends State<_PortfolioGrid> {
  List<PortfolioPost>? _posts;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final posts = await context
          .read<LoomeeaRepository>()
          .getPortfolioPosts(widget.salonId);
      if (mounted) setState(() => _posts = posts);
    } catch (_) {
      if (mounted) setState(() => _posts = []);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_posts == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_posts!.isEmpty) {
      return _EmptySection(
        icon: Icons.photo_library_outlined,
        label: tr('no_portfolio'),
      );
    }

    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _posts!.length,
        itemBuilder: (context, index) {
          final post = _posts![index];
          String? tok;
          try {
            tok = context.read<ApiClient>().token;
          } catch (_) {}
          return _PortfolioItem(
            post: post,
            token: tok,
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => _PortfolioImageViewer(
                imageUrl: post.imageUrl,
                caption: post.caption,
                token: tok,
              ),
            )),
          );
        },
      ),
    );
  }
}

class _PortfolioItem extends StatelessWidget {
  const _PortfolioItem({
    required this.post,
    required this.token,
    required this.onTap,
  });

  final PortfolioPost post;
  final String? token;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(LoomeaTokens.radiusCard),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child:
                  buildPortfolioImage(post.imageUrl, BoxFit.cover, token: token),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Text(
                post.caption,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PortfolioImageViewer extends StatelessWidget {
  const _PortfolioImageViewer({
    required this.imageUrl,
    required this.caption,
    this.token,
  });

  final String imageUrl;
  final String caption;
  final String? token;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: caption.isNotEmpty
            ? Text(caption,
                style: const TextStyle(fontSize: 14, color: Colors.white70),
                maxLines: 1,
                overflow: TextOverflow.ellipsis)
            : null,
      ),
      body: Center(
        child: InteractiveViewer(
          child: buildPortfolioImage(imageUrl, BoxFit.contain, token: token),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reviews
// ─────────────────────────────────────────────────────────────────────────────

class _ReviewsList extends StatefulWidget {
  const _ReviewsList({super.key, required this.salonId});

  final String salonId;

  @override
  State<_ReviewsList> createState() => _ReviewsListState();
}

class _ReviewsListState extends State<_ReviewsList> {
  List<Review>? _reviews;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final reviews =
          await context.read<LoomeeaRepository>().getReviews(widget.salonId);
      if (mounted) setState(() => _reviews = reviews);
    } catch (_) {
      if (mounted) setState(() => _reviews = []);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_reviews == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_reviews!.isEmpty) {
      return _EmptySection(
        icon: Icons.rate_review_outlined,
        label: tr('no_reviews'),
      );
    }

    return Column(
      children: _reviews!.map((r) => _ReviewCard(review: r)).toList(),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review});

  final Review review;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
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
                child: Text(
                  review.userName.isNotEmpty
                      ? review.userName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(review.userName,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary)),
                    const SizedBox(height: 2),
                    Text(review.createdAt,
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              _StarRow(rating: review.rating),
            ],
          ),
          if (review.comment.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              review.comment,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary, height: 1.4),
            ),
          ],
        ],
      ),
    );
  }
}

class _StarRow extends StatelessWidget {
  const _StarRow({required this.rating});

  final int rating;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        5,
        (i) => Icon(
          i < rating ? Icons.star_rounded : Icons.star_outline_rounded,
          size: 16,
          color: i < rating ? const Color(0xFFFFC107) : AppColors.textSecondary,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared empty-state placeholder
// ─────────────────────────────────────────────────────────────────────────────

class _EmptySection extends StatelessWidget {
  const _EmptySection({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(LoomeaTokens.radiusCard),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 28),
          const SizedBox(height: 8),
          Text(label,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 13)),
        ],
      ),
    );
  }
}
