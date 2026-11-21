import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../data/services/location_service.dart';
import '../../../data/services/localization_service.dart';

import '../../../data/models/salon_model.dart';
import '../../../logic/blocs/booking/booking_bloc.dart';
import '../../../logic/blocs/booking/booking_event.dart';
import '../../../logic/blocs/booking/booking_state.dart';
import '../../../logic/blocs/waitlist/waitlist_bloc.dart';
import '../../../logic/blocs/waitlist/waitlist_event.dart';
import '../../../logic/blocs/profile/profile_bloc.dart';
import '../../../logic/blocs/profile/profile_event.dart';
import '../../../logic/blocs/profile/profile_state.dart';
import '../../../logic/blocs/salon/salon_bloc.dart';
import '../../../logic/blocs/salon/salon_event.dart';
import '../../../logic/blocs/salon/salon_state.dart';
import '../../core/routes/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/loomea_tokens.dart';
import '../../core/widgets/loomea_ui.dart' show SalonImagePlaceholder;
import '../bookings/my_appointments_page.dart';
import '../../core/utils/image_utils.dart';
import '../profile/profile_page.dart';

class HomeShellPage extends StatefulWidget {
  const HomeShellPage({super.key});

  @override
  State<HomeShellPage> createState() => _HomeShellPageState();
}

class _HomeShellPageState extends State<HomeShellPage> {
  int _currentIndex = 0;
  Timer? _pollTimer;
  Timer? _refreshTimer;
  String? _placeName;

  @override
  void initState() {
    super.initState();
    // Load profile and appointments on every entry (covers login + app restart)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ProfileBloc>().add(LoadProfile());
      context.read<BookingBloc>().add(LoadAppointments());
    });
    // Poll appointments every 3 seconds for status updates
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      context.read<BookingBloc>().add(const RefreshAppointments());
      context.read<WaitlistBloc>().add(const RefreshWaitlist());
    });
    // Refresh profile (reliability score) and salon list every 30 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!mounted) return;
      context.read<ProfileBloc>().add(LoadProfile());
      context.read<SalonBloc>().add(LoadSalons());
    });
    _requestLocation();
  }

  Future<void> _requestLocation() async {
    await LocationService.instance.requestAndGetLocation();
    if (mounted) {
      setState(() => _placeName = LocationService.instance.placeName);
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _HomePage(
        onProfileTap: () => setState(() => _currentIndex = 3),
        placeName: _placeName,
      ),
      const MyAppointmentsPage(),
      const _SavedPage(),
      const ProfilePage(),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(child: pages[_currentIndex]),
      bottomNavigationBar: BlocBuilder<BookingBloc, BookingState>(
        buildWhen: (prev, curr) =>
            prev.hasStatusUpdate != curr.hasStatusUpdate,
        builder: (context, bookingState) {
          return Container(
            decoration: const BoxDecoration(
              color: AppColors.background,
              border: Border(
                top: BorderSide(color: AppColors.border, width: 1),
              ),
            ),
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (index) => setState(() => _currentIndex = index),
              items: [
                BottomNavigationBarItem(
                  icon: const Icon(HugeIcons.strokeRoundedHome01),
                  label: tr('tab_home'),
                ),
                BottomNavigationBarItem(
                  icon: _BookingIcon(
                    showDot: bookingState.hasStatusUpdate,
                  ),
                  activeIcon: _BookingIcon(
                    showDot: bookingState.hasStatusUpdate,
                  ),
                  label: tr('tab_bookings'),
                ),
                BottomNavigationBarItem(
                  icon: const Icon(HugeIcons.strokeRoundedFavourite),
                  label: tr('saved_salons'),
                ),
                BottomNavigationBarItem(
                  icon: const Icon(HugeIcons.strokeRoundedUser),
                  label: tr('tab_profile'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Home tab — editorial greeting, search, categories, nearby salons.
class _HomePage extends StatefulWidget {
  const _HomePage({this.onProfileTap, this.placeName});

  final VoidCallback? onProfileTap;
  final String? placeName;

  @override
  State<_HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<_HomePage> {
  String? _selectedCategory;

  static String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return tr('good_morning');
    if (hour < 18) return tr('good_afternoon');
    return tr('good_evening');
  }

  void _onCategoryTap(String category) {
    setState(() {
      if (_selectedCategory == category) {
        _selectedCategory = null;
        context.read<SalonBloc>().add(LoadSalons());
      } else {
        _selectedCategory = category;
        context.read<SalonBloc>().add(FilterByCategory(category));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileBloc, ProfileState>(
      builder: (context, profileState) {
        final placeName = widget.placeName;

        return BlocBuilder<SalonBloc, SalonState>(
          builder: (context, salonState) {
            final salons = salonState.salons;

            return CustomScrollView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    LoomeaTokens.screenPaddingH,
                    24,
                    LoomeaTokens.screenPaddingH,
                    0,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // — Header row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.location_on_outlined,
                                        size: 13,
                                        color: AppColors.textSecondary),
                                    const SizedBox(width: 4),
                                    Text(
                                      placeName ?? 'Locating...',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.textSecondary,
                                        letterSpacing: 0.1,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  _greeting(),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                    color: AppColors.textSecondary,
                                    height: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  tr('glow_up_time', args: [profileState.profile?.firstName.isNotEmpty == true ? profileState.profile!.firstName : tr('you')]),
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.7,
                                    height: 1.15,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: widget.onProfileTap,
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.border),
                              ),
                              child: const Icon(
                                Icons.person_outline_rounded,
                                color: AppColors.textPrimary,
                                size: 22,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // — Search pill
                      GestureDetector(
                        onTap: () => context.pushNamed(AppRoute.search.name),
                        child: Container(
                          height: 50,
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(
                                LoomeaTokens.radiusPill),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.search_rounded,
                                  size: 20, color: AppColors.textSecondary),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  tr('search_hint'),
                                  style: const TextStyle(
                                    fontSize: 15,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                              const Icon(Icons.tune_rounded,
                                  size: 18, color: AppColors.textSecondary),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // — Category pill chips row
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _CategoryPill(
                              label: 'Haircut',
                              icon: Icons.content_cut_rounded,
                              isSelected: _selectedCategory == 'Haircut',
                              onTap: () => _onCategoryTap('Haircut'),
                            ),
                            const SizedBox(width: 8),
                            _CategoryPill(
                              label: 'Nails',
                              icon: Icons.brush_outlined,
                              isSelected: _selectedCategory == 'Nails',
                              onTap: () => _onCategoryTap('Nails'),
                            ),
                            const SizedBox(width: 8),
                            _CategoryPill(
                              label: 'Massage',
                              icon: Icons.spa_rounded,
                              isSelected: _selectedCategory == 'Massage',
                              onTap: () => _onCategoryTap('Massage'),
                            ),
                            const SizedBox(width: 8),
                            _CategoryPill(
                              label: 'Shave',
                              icon: Icons.face_retouching_natural_outlined,
                              isSelected: _selectedCategory == 'Shave',
                              onTap: () => _onCategoryTap('Shave'),
                            ),
                            const SizedBox(width: 8),
                            _CategoryPill(
                              label: 'Lashes',
                              icon: Icons.visibility_rounded,
                              isSelected: _selectedCategory == 'Lashes',
                              onTap: () => _onCategoryTap('Lashes'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      // — Editor's pick
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(tr('featured_salons'),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.3,
                                color: AppColors.textPrimary,
                              )),
                          GestureDetector(
                            onTap: () =>
                                context.pushNamed(AppRoute.search.name),
                            child: Text(tr('see_all'),
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textSecondary,
                                )),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (salons.isNotEmpty)
                        _EditorialSalonCard(
                          salon: salons.first,
                          isSaved: profileState.isSalonSaved(salons.first.id),
                          onFavorite: () => context
                              .read<ProfileBloc>()
                              .add(ToggleSavedSalon(salons.first.id)),
                          onTap: () => context.pushNamed(
                            AppRoute.salonProfile.name,
                            extra: salons.first.name,
                          ),
                        )
                      else if (salonState.status == SalonStatus.loading)
                        const SizedBox(
                          height: 200,
                          child: Center(child: CircularProgressIndicator()),
                        ),
                      const SizedBox(height: 24),
                      // — Explore nearby
                      const _ExploreNearbyCard(),
                      const SizedBox(height: 24),
                      // — Near You
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(tr('near_you'),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.3,
                                color: AppColors.textPrimary,
                              )),
                          GestureDetector(
                            onTap: () =>
                                context.pushNamed(AppRoute.search.name),
                            child: Text(tr('see_all'),
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textSecondary,
                                )),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ]),
                  ),
                ),
                // — Horizontal salon cards
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 280,
                    child: salonState.salons.isEmpty &&
                            salonState.status == SalonStatus.loading
                        ? const Center(child: CircularProgressIndicator())
                        : ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.only(
                              left: LoomeaTokens.screenPaddingH,
                              right: LoomeaTokens.screenPaddingH - 12,
                            ),
                            physics: const BouncingScrollPhysics(),
                            itemCount: salons.length,
                            itemBuilder: (context, index) {
                              final salon = salons[index];
                              final isSaved =
                                  profileState.isSalonSaved(salon.id);
                              return _NearYouSalonCard(
                                salon: salon,
                                isSaved: isSaved,
                                onFavorite: () => context
                                    .read<ProfileBloc>()
                                    .add(ToggleSavedSalon(salon.id)),
                                onBook: () => context.pushNamed(
                                  AppRoute.salonProfile.name,
                                  extra: salon.name,
                                ),
                              );
                            },
                          ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],
            );
          },
        );
      },
    );
  }
}

class _CategoryPill extends StatelessWidget {
  const _CategoryPill({
    required this.label,
    required this.icon,
    this.isSelected = false,
    this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(LoomeaTokens.radiusPill),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 15,
                color: isSelected ? AppColors.onPrimary : AppColors.textPrimary),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isSelected ? AppColors.onPrimary : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditorialSalonCard extends StatelessWidget {
  const _EditorialSalonCard({
    required this.salon,
    required this.isSaved,
    required this.onFavorite,
    required this.onTap,
  });

  final Salon salon;
  final bool isSaved;
  final VoidCallback onFavorite;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(LoomeaTokens.radiusHero),
        child: SizedBox(
          height: 200,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background — image or navy gradient
              if (salon.imageUrl.isNotEmpty)
                Image.network(
                  resolveImageUrl(salon.imageUrl),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _gradientFallback(),
                )
              else
                _gradientFallback(),
              // Gradient overlay
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Color(0xCC0A2A6B)],
                    stops: [0.4, 1.0],
                  ),
                ),
              ),
              // Favorite
              Positioned(
                top: 14,
                right: 14,
                child: GestureDetector(
                  onTap: onFavorite,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isSaved
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              // Info
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      salon.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded,
                            size: 13, color: Color(0xFFD9B382)),
                        const SizedBox(width: 3),
                        Text('${salon.rating}',
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white)),
                        const SizedBox(width: 10),
                        const Icon(Icons.near_me_outlined,
                            size: 13, color: Colors.white70),
                        const SizedBox(width: 3),
                        Text(salon.distanceText,
                            style: const TextStyle(
                                fontSize: 12, color: Colors.white70)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _gradientFallback() =>
      SalonImagePlaceholder(salonId: salon.id);
}

class _ExploreNearbyCard extends StatelessWidget {
  const _ExploreNearbyCard();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.pushNamed(AppRoute.exploreMap.name),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(LoomeaTokens.radiusCard),
        child: SizedBox(
          height: 170,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Real map tile background (NYC area), desaturated to grey.
              ColorFiltered(
                colorFilter: const ColorFilter.matrix(<double>[
                  0.2126, 0.7152, 0.0722, 0, 0,
                  0.2126, 0.7152, 0.0722, 0, 0,
                  0.2126, 0.7152, 0.0722, 0, 0,
                  0, 0, 0, 1, 0,
                ]),
                child: Image.network(
                  'https://tile.openstreetmap.org/13/2412/3078.png',
                  fit: BoxFit.cover,
                  color: Colors.white.withValues(alpha: 0.15),
                  colorBlendMode: BlendMode.lighten,
                  errorBuilder: (_, __, ___) => Container(
                    color: AppColors.surface,
                    child: CustomPaint(painter: _MapFallbackPainter()),
                  ),
                ),
              ),
              // Subtle gradient overlay for readability
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: 0.3),
                      Colors.white.withValues(alpha: 0.6),
                    ],
                  ),
                ),
              ),
              // Pin markers scattered on the map
              Positioned(
                top: 30,
                left: 60,
                child: _MapPin(color: AppColors.primary),
              ),
              Positioned(
                top: 55,
                right: 80,
                child: _MapPin(color: AppColors.error),
              ),
              Positioned(
                bottom: 60,
                left: 120,
                child: _MapPin(color: AppColors.primary),
              ),
              // CTA button
              Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius:
                        BorderRadius.circular(LoomeaTokens.radiusInput),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.map_outlined,
                          size: 20, color: AppColors.textPrimary),
                      const SizedBox(width: 8),
                      Text(
                        tr('explore_nearby'),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
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

class _MapPin extends StatelessWidget {
  const _MapPin({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Icon(Icons.location_on, size: 28, color: color);
  }
}

class _MapFallbackPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.textSecondary.withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;
    const spacing = 14.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _NearYouSalonCard extends StatelessWidget {
  const _NearYouSalonCard({
    required this.salon,
    required this.isSaved,
    required this.onFavorite,
    required this.onBook,
  });

  final Salon salon;
  final bool isSaved;
  final VoidCallback onFavorite;
  final VoidCallback onBook;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: SizedBox(
        width: 260,
        child: Material(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(LoomeaTokens.radiusCard),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onBook,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 130,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (salon.imageUrl.isNotEmpty)
                        Image.network(
                          resolveImageUrl(salon.imageUrl),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              SalonImagePlaceholder(salonId: salon.id),
                        )
                      else
                        SalonImagePlaceholder(salonId: salon.id),
                      // Rating badge
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.background.withOpacity(0.92),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star_rounded,
                                  size: 14, color: Color(0xFFFFC107)),
                              const SizedBox(width: 2),
                              Text(
                                salon.rating.toString(),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Favorite
                      Positioned(
                        top: 10,
                        left: 10,
                        child: GestureDetector(
                          onTap: onFavorite,
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: AppColors.background.withOpacity(0.85),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isSaved
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              size: 16,
                              color: isSaved
                                  ? AppColors.error
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              salon.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            salon.distanceText,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.schedule_rounded,
                              size: 14, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            salon.openUntil,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.success,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: salon.tags
                            .take(2)
                            .map((tag) => Padding(
                                  padding: const EdgeInsets.only(right: 6),
                                  child: _TagChip(label: tag),
                                ))
                            .toList(),
                      ),
                    ],
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

/// Bookings nav icon with an optional notification dot.
class _BookingIcon extends StatelessWidget {
  const _BookingIcon({required this.showDot});

  final bool showDot;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        const Icon(HugeIcons.strokeRoundedCalendar01),
        if (showDot)
          Positioned(
            top: -2,
            right: -4,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppColors.error,
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.inputBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.6,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _SavedPage extends StatelessWidget {
  const _SavedPage();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileBloc, ProfileState>(
      builder: (context, state) {
        final savedSalons = state.savedSalons;

        return Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: LoomeaTokens.screenPaddingH),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              Text(tr('saved_salons'),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.025 * 28,
                    height: 1.1,
                    color: AppColors.textPrimary,
                  )),
              const SizedBox(height: 24),
              if (savedSalons.isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: const BoxDecoration(
                            color: AppColors.surface,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.favorite_border_rounded,
                            size: 32,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          tr('no_saved_salons'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Save your favorite salons to quickly\nfind them later.',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    itemCount: savedSalons.length,
                    itemBuilder: (context, index) {
                      final salon = savedSalons[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Material(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(
                              LoomeaTokens.radiusCard),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: () => context.pushNamed(
                              AppRoute.salonProfile.name,
                              extra: salon.name,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius:
                                        BorderRadius.circular(12),
                                    child: SizedBox(
                                      width: 56,
                                      height: 56,
                                      child: salon.imageUrl.isNotEmpty
                                          ? Image.network(
                                              resolveImageUrl(salon.imageUrl),
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) =>
                                                  SalonImagePlaceholder(salonId: salon.id),
                                            )
                                          : SalonImagePlaceholder(salonId: salon.id),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          salon.name,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(Icons.star_rounded,
                                                size: 14,
                                                color: Color(0xFFFFC107)),
                                            const SizedBox(width: 2),
                                            Text(
                                              '${salon.rating} (${salon.reviewCount})',
                                              style: const TextStyle(
                                                fontSize: 13,
                                                color:
                                                    AppColors.textSecondary,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Text(
                                              salon.distanceText,
                                              style: const TextStyle(
                                                fontSize: 13,
                                                color:
                                                    AppColors.textSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => context
                                        .read<ProfileBloc>()
                                        .add(ToggleSavedSalon(salon.id)),
                                    child: const Icon(
                                      Icons.favorite_rounded,
                                      color: AppColors.error,
                                      size: 22,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
