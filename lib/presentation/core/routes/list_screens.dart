import 'package:flutter/material.dart';

/// Single stitched list of app screens for docs, QA, and Stitch/design handoff.
/// Keep in sync with [AppRoute] and [createAppRouter].
@immutable
class AppScreenInfo {
  const AppScreenInfo({
    required this.routeName,
    required this.path,
    required this.title,
    required this.group,
  });

  /// [AppRoute.name] string (GoRouter name).
  final String routeName;

  /// GoRouter path (leading slash).
  final String path;

  /// Human-readable label.
  final String title;

  /// Flow grouping for navigation diagrams.
  final String group;
}

/// All registered routes in stable order (onboarding → auth → main → booking).
const List<AppScreenInfo> kAppScreensAll = [
  AppScreenInfo(
    routeName: 'onboarding',
    path: '/onboarding',
    title: 'Onboarding / Welcome',
    group: 'Onboarding',
  ),
  AppScreenInfo(
    routeName: 'signIn',
    path: '/sign-in',
    title: 'Sign In',
    group: 'Auth',
  ),
  AppScreenInfo(
    routeName: 'signUp',
    path: '/sign-up',
    title: 'Create Account',
    group: 'Auth',
  ),
  AppScreenInfo(
    routeName: 'otpVerification',
    path: '/otp-verification',
    title: 'Email OTP Verification',
    group: 'Auth',
  ),
  AppScreenInfo(
    routeName: 'home',
    path: '/home',
    title: 'Home (shell + bottom nav)',
    group: 'Main',
  ),
  AppScreenInfo(
    routeName: 'search',
    path: '/search',
    title: 'Search (salons / services)',
    group: 'Discovery',
  ),
  AppScreenInfo(
    routeName: 'salonProfile',
    path: '/salon',
    title: 'Salon Profile (add services)',
    group: 'Booking',
  ),
  AppScreenInfo(
    routeName: 'selectTimeSlot',
    path: '/time-slot',
    title: 'Select Time Slot',
    group: 'Booking',
  ),
  AppScreenInfo(
    routeName: 'bookingReview',
    path: '/booking-review',
    title: 'Review & Confirmation',
    group: 'Booking',
  ),
  AppScreenInfo(
    routeName: 'bookingConfirmation',
    path: '/booking-confirmation',
    title: 'Booking Confirmed',
    group: 'Booking',
  ),
];

/// Auth path after sign-up (matches typical navigation).
const List<AppScreenInfo> kAuthFlowAfterSignUp = [
  AppScreenInfo(
    routeName: 'signUp',
    path: '/sign-up',
    title: 'Create Account',
    group: 'Auth',
  ),
  AppScreenInfo(
    routeName: 'otpVerification',
    path: '/otp-verification',
    title: 'Email OTP Verification',
    group: 'Auth',
  ),
  AppScreenInfo(
    routeName: 'home',
    path: '/home',
    title: 'Home',
    group: 'Main',
  ),
];

/// Core booking funnel (from discovery to confirmation).
const List<AppScreenInfo> kBookingFlow = [
  AppScreenInfo(
    routeName: 'home',
    path: '/home',
    title: 'Home',
    group: 'Main',
  ),
  AppScreenInfo(
    routeName: 'search',
    path: '/search',
    title: 'Search',
    group: 'Discovery',
  ),
  AppScreenInfo(
    routeName: 'salonProfile',
    path: '/salon',
    title: 'Salon Profile',
    group: 'Booking',
  ),
  AppScreenInfo(
    routeName: 'selectTimeSlot',
    path: '/time-slot',
    title: 'Select Time Slot',
    group: 'Booking',
  ),
  AppScreenInfo(
    routeName: 'bookingReview',
    path: '/booking-review',
    title: 'Review & Confirmation',
    group: 'Booking',
  ),
  AppScreenInfo(
    routeName: 'bookingConfirmation',
    path: '/booking-confirmation',
    title: 'Booking Confirmed',
    group: 'Booking',
  ),
];

/// Tabs inside [HomeShellPage] (not separate routes).
const List<String> kHomeShellTabs = [
  'Home',
  'My Appointments',
  'Saved',
  'Profile',
];
