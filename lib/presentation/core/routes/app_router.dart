import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../data/api/api_client.dart';

import '../../features/onboarding/language_selection_page.dart';
import '../../features/onboarding/onboarding_page.dart';
import '../../features/onboarding/permissions_page.dart';
import '../../features/auth/sign_in_page.dart';
import '../../features/auth/sign_up_page.dart';
import '../../features/home/home_shell_page.dart';
import '../../features/auth/otp_verification_page.dart';
import '../../features/home/explore_map_page.dart';
import '../../features/home/search_page.dart';
import '../../features/salons/salon_profile_page.dart';
import '../../features/bookings/select_time_slot_page.dart';
import '../../features/bookings/booking_review_page.dart';
import '../../features/bookings/booking_confirmation_page.dart';
import '../../features/profile/notifications_page.dart';
import '../../features/profile/favorite_salons_page.dart';
import '../../features/owner/owner_shell_page.dart';
import '../../features/owner/owner_onboarding_page.dart';

import '../../features/owner/owner_notifications_page.dart';
import '../../features/auth/forgot_password_page.dart';
import '../../features/auth/email_sent_page.dart';
import '../../features/auth/new_password_page.dart';
import '../../features/auth/reset_success_page.dart';
import '../../features/payment/owner_subscription_page.dart';
import '../../features/payment/payment_history_page.dart';
import '../../features/payment/payment_page.dart';

enum AppRoute {
  languageSelection,
  permissions,
  onboarding,
  signIn,
  signUp,
  otpVerification,
  ownerOnboarding,
  search,
  salonProfile,
  selectTimeSlot,
  bookingReview,
  bookingConfirmation,
  exploreMap,
  home,
  ownerHome,
  notifications,
  ownerNotifications,
  favoriteSalons,
  forgotPassword,
  emailSent,
  newPassword,
  resetSuccess,
  payment,
  paymentHistory,
  ownerSubscription,
}

GoRouter createAppRouter({
  ApiClient? apiClient,
  bool hasSeenOnboarding = false,
  bool hasSelectedLanguage = false,
  bool hasSeenPermissions = false,
}) {
  String _initialLocation() {
    if (!hasSelectedLanguage) return '/language';
    if (!hasSeenPermissions) return '/permissions';
    if (!hasSeenOnboarding) return '/onboarding';
    return '/sign-in';
  }

  return GoRouter(
    initialLocation: _initialLocation(),
    redirect: (context, state) {
      if (apiClient == null || !apiClient.isLoggedIn) return null;
      final guestRoutes = ['/onboarding', '/sign-in', '/sign-up'];
      if (guestRoutes.contains(state.matchedLocation)) {
        if (apiClient.userRole == 'SALON_OWNER') return '/owner-home';
        return '/home';
      }
      return null;
    },
    routes: [
      GoRoute(
        name: AppRoute.languageSelection.name,
        path: '/language',
        pageBuilder: (context, state) => MaterialPage(
          child: LanguageSelectionPage(
            onLanguageSelected: () => context.go('/permissions'),
          ),
        ),
      ),
      GoRoute(
        name: AppRoute.permissions.name,
        path: '/permissions',
        pageBuilder: (context, state) => MaterialPage(
          child: PermissionsPage(
            onDone: () => context.go('/onboarding'),
          ),
        ),
      ),
      GoRoute(
        name: AppRoute.onboarding.name,
        path: '/onboarding',
        pageBuilder: (context, state) => const MaterialPage(
          child: OnboardingPage(),
        ),
      ),
      GoRoute(
        name: AppRoute.signIn.name,
        path: '/sign-in',
        pageBuilder: (context, state) => const MaterialPage(
          child: SignInPage(),
        ),
      ),
      GoRoute(
        name: AppRoute.signUp.name,
        path: '/sign-up',
        pageBuilder: (context, state) => const MaterialPage(
          child: SignUpPage(),
        ),
      ),
      GoRoute(
        name: AppRoute.otpVerification.name,
        path: '/otp-verification',
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return MaterialPage(
            child: OtpVerificationPage(
              email: extra['email'] as String? ?? '',
              role: extra['role'] as String? ?? 'CLIENT',
            ),
          );
        },
      ),
      GoRoute(
        name: AppRoute.ownerOnboarding.name,
        path: '/owner-onboarding',
        pageBuilder: (context, state) => const MaterialPage(
          child: OwnerOnboardingPage(),
        ),
      ),
      GoRoute(
        name: AppRoute.home.name,
        path: '/home',
        pageBuilder: (context, state) => const MaterialPage(
          child: HomeShellPage(),
        ),
      ),
      GoRoute(
        name: AppRoute.search.name,
        path: '/search',
        pageBuilder: (context, state) => const MaterialPage(
          child: SearchPage(),
        ),
      ),
      GoRoute(
        name: AppRoute.salonProfile.name,
        path: '/salon',
        pageBuilder: (context, state) {
          final salonName = state.extra as String? ?? 'Luna Hair Studio';
          return MaterialPage(
            child: SalonProfilePage(salonName: salonName),
          );
        },
      ),
      GoRoute(
        name: AppRoute.selectTimeSlot.name,
        path: '/time-slot',
        pageBuilder: (context, state) {
          final bookingId = state.extra as String?;
          return MaterialPage(child: SelectTimeSlotPage(bookingId: bookingId));
        },
      ),
      GoRoute(
        name: AppRoute.bookingReview.name,
        path: '/booking-review',
        pageBuilder: (context, state) => const MaterialPage(
          child: BookingReviewPage(),
        ),
      ),
      GoRoute(
        name: AppRoute.bookingConfirmation.name,
        path: '/booking-confirmation',
        pageBuilder: (context, state) => const MaterialPage(
          child: BookingConfirmationPage(),
        ),
      ),
      GoRoute(
        name: AppRoute.exploreMap.name,
        path: '/explore-map',
        pageBuilder: (context, state) => const MaterialPage(
          child: ExploreMapPage(),
        ),
      ),
      GoRoute(
        name: AppRoute.ownerHome.name,
        path: '/owner-home',
        pageBuilder: (context, state) => const MaterialPage(
          child: OwnerShellPage(),
        ),
      ),
      GoRoute(
        name: AppRoute.notifications.name,
        path: '/notifications',
        pageBuilder: (context, state) => const MaterialPage(
          child: NotificationsPage(),
        ),
      ),
      GoRoute(
        name: AppRoute.favoriteSalons.name,
        path: '/favorite-salons',
        pageBuilder: (context, state) => const MaterialPage(
          child: FavoriteSalonsPage(),
        ),
      ),
      GoRoute(
        name: AppRoute.ownerNotifications.name,
        path: '/owner-notifications',
        pageBuilder: (context, state) => const MaterialPage(
          child: OwnerNotificationsPage(),
        ),
      ),
      GoRoute(
        name: AppRoute.forgotPassword.name,
        path: '/forgot-password',
        pageBuilder: (context, state) => const MaterialPage(
          child: ForgotPasswordPage(),
        ),
      ),
      GoRoute(
        name: AppRoute.emailSent.name,
        path: '/email-sent',
        pageBuilder: (context, state) => const MaterialPage(
          child: EmailSentPage(),
        ),
      ),
      GoRoute(
        name: AppRoute.newPassword.name,
        path: '/new-password',
        pageBuilder: (context, state) => const MaterialPage(
          child: NewPasswordPage(),
        ),
      ),
      GoRoute(
        name: AppRoute.resetSuccess.name,
        path: '/reset-success',
        pageBuilder: (context, state) => const MaterialPage(
          child: ResetSuccessPage(),
        ),
      ),
      // extra: PaymentArgs. Pops with true once the payment succeeded.
      GoRoute(
        name: AppRoute.payment.name,
        path: '/payment',
        pageBuilder: (context, state) => MaterialPage(
          child: PaymentPage(args: state.extra as PaymentArgs),
        ),
      ),
      // extra: true for the owner's billing wording.
      GoRoute(
        name: AppRoute.paymentHistory.name,
        path: '/payment-history',
        pageBuilder: (context, state) => MaterialPage(
          child: PaymentHistoryPage(billing: state.extra as bool? ?? false),
        ),
      ),
      GoRoute(
        name: AppRoute.ownerSubscription.name,
        path: '/owner-subscription',
        pageBuilder: (context, state) => const MaterialPage(
          child: OwnerSubscriptionPage(),
        ),
      ),
    ],
  );
}
