import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../data/services/localization_service.dart';
import '../../../data/services/notification_service.dart';
import '../../../logic/blocs/owner_booking/owner_booking_bloc.dart';
import '../../../logic/blocs/owner_booking/owner_booking_event.dart';
import '../../../logic/blocs/owner_booking/owner_booking_state.dart';
import '../../../logic/blocs/owner_dashboard/owner_dashboard_bloc.dart';
import '../../../logic/blocs/owner_dashboard/owner_dashboard_event.dart';
import '../../../logic/blocs/owner_profile/owner_profile_bloc.dart';
import '../../../logic/blocs/owner_profile/owner_profile_event.dart';
import '../../../logic/blocs/owner_salon/owner_salon_bloc.dart';
import '../../../logic/blocs/owner_salon/owner_salon_event.dart';
import '../../../logic/blocs/owner_salon/owner_salon_state.dart';
import '../../core/theme/app_theme.dart';
import 'owner_dashboard_page.dart';
import 'owner_my_salon_page.dart';
import 'owner_bookings_page.dart';
import 'owner_profile_page.dart';

class OwnerShellPage extends StatefulWidget {
  const OwnerShellPage({super.key});

  @override
  State<OwnerShellPage> createState() => _OwnerShellPageState();
}

class _OwnerShellPageState extends State<OwnerShellPage> {
  int _currentIndex = 0;
  StreamSubscription? _notifSub;
  Timer? _pollTimer;
  String? _currentSalonId;

  static const _pages = <Widget>[
    OwnerDashboardPage(),
    OwnerMySalonPage(),
    OwnerBookingsPage(),
    OwnerProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    context.read<OwnerSalonBloc>().add(const LoadMySalons());
    context.read<OwnerProfileBloc>().add(const LoadOwnerProfile());

    _notifSub = NotificationService.instance.onTap.listen((payload) {
      if (payload == 'bookings' && mounted) {
        setState(() => _currentIndex = 2);
      }
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _notifSub?.cancel();
    super.dispose();
  }

  void _startPollingIfNeeded(String salonId) {
    if (_currentSalonId == salonId) return;
    _currentSalonId = salonId;
    _pollTimer?.cancel();
    _poll();
    _pollTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (!mounted || _currentSalonId == null) return;
      _poll();
    });
  }

  void _poll() {
    context.read<OwnerBookingBloc>().add(SilentRefreshBookings(_currentSalonId!));
    context.read<OwnerDashboardBloc>().add(RefreshDashboard(_currentSalonId!));
    context.read<OwnerSalonBloc>().add(LoadReviews(_currentSalonId!));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<OwnerSalonBloc, OwnerSalonState>(
      listenWhen: (prev, curr) => prev.salon?.id != curr.salon?.id,
      listener: (context, state) {
        if (state.salon != null) _startPollingIfNeeded(state.salon!.id);
      },
      child: Scaffold(
        body: IndexedStack(index: _currentIndex, children: _pages),
        bottomNavigationBar: BlocBuilder<OwnerBookingBloc, OwnerBookingState>(
          buildWhen: (prev, curr) {
            final prevPending = prev.bookings.any((b) => b.isPending);
            final currPending = curr.bookings.any((b) => b.isPending);
            return prevPending != currPending;
          },
          builder: (context, bookingState) {
            final hasPending = bookingState.bookings.any((b) => b.isPending);
            return Container(
              decoration: const BoxDecoration(
                color: AppColors.background,
                border: Border(
                  top: BorderSide(color: AppColors.border, width: 1),
                ),
              ),
              child: BottomNavigationBar(
                currentIndex: _currentIndex,
                onTap: (i) => setState(() => _currentIndex = i),
                items: [
                  BottomNavigationBarItem(
                    icon: const Icon(HugeIcons.strokeRoundedDashboardSquare01),
                    label: tr('tab_dashboard'),
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(HugeIcons.strokeRoundedStore01),
                    label: tr('tab_my_salon'),
                  ),
                  BottomNavigationBarItem(
                    icon: _BadgedIcon(showBadge: hasPending),
                    activeIcon: _BadgedIcon(showBadge: hasPending),
                    label: tr('tab_bookings'),
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
      ),
    );
  }
}

class _BadgedIcon extends StatelessWidget {
  const _BadgedIcon({required this.showBadge});
  final bool showBadge;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        const Icon(HugeIcons.strokeRoundedCalendar01),
        if (showBadge)
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
