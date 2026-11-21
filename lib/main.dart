import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:device_preview/device_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/api/api_client.dart';
import 'data/api/app_config.dart';
import 'data/services/localization_service.dart';
import 'data/repositories/api_repository.dart';
import 'data/repositories/loomea_repository.dart';
import 'data/services/notification_service.dart';
import 'logic/blocs/auth/auth_bloc.dart';
import 'logic/blocs/booking/booking_bloc.dart';
import 'logic/blocs/owner_booking/owner_booking_bloc.dart';
import 'logic/blocs/owner_dashboard/owner_dashboard_bloc.dart';
import 'logic/blocs/owner_profile/owner_profile_bloc.dart';
import 'logic/blocs/owner_salon/owner_salon_bloc.dart';
import 'logic/blocs/profile/profile_bloc.dart';
import 'logic/blocs/salon/salon_bloc.dart';
import 'logic/blocs/salon/salon_event.dart';
import 'logic/blocs/search/search_bloc.dart';

import 'logic/blocs/waitlist/waitlist_bloc.dart';
import 'logic/blocs/password_reset/password_reset_bloc.dart';
import 'logic/blocs/password_reset/password_reset_event.dart';
import 'logic/blocs/password_reset/password_reset_state.dart';

import 'presentation/core/routes/app_router.dart';
import 'presentation/core/theme/app_theme.dart';
import 'presentation/core/widgets/app_error_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Run independent startup tasks in parallel to reduce cold-start latency.
  final results = await Future.wait([
    NotificationService.instance.initialize(),
    SharedPreferences.getInstance(),
  ]);
  final prefs = results[1] as SharedPreferences;

  final hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;
  final savedLanguage = prefs.getString('app_language');
  final hasSelectedLanguage = savedLanguage != null;
  final hasSeenPermissions = prefs.getBool('hasSeenPermissions') ?? false;

  // Session-only tokens (remember me = false) are cleared on cold start.
  final apiClient = ApiClient(baseUrl: AppConfig.apiBaseUrl);

  // Load locale strings and restore auth token in parallel.
  await Future.wait([
    AppLocalizations.instance.load(savedLanguage ?? 'en'),
    apiClient.restoreToken(),
  ]);

  // Catch Flutter widget-build errors and show the branded full-screen
  // error with a "try again" CTA. Wrapping in a Directionality keeps it
  // safe when the failing subtree is above MaterialApp.
  ErrorWidget.builder = (FlutterErrorDetails details) => Directionality(
        textDirection: TextDirection.ltr,
        child: AppErrorScreen(
          isRenderError: true,
          onRetry: () {
            // A rebuild will naturally clear the error widget if the
            // underlying cause was transient. For persistent failures the
            // user can navigate away / pull to refresh.
          },
        ),
      );

  runApp(
    DevicePreview(
      enabled: true,
      builder: (_) => LoomeaApp(
        apiClient: apiClient,
        hasSeenOnboarding: hasSeenOnboarding,
        hasSelectedLanguage: hasSelectedLanguage,
        hasSeenPermissions: hasSeenPermissions,
      ),
    ),
  );
}

class LoomeaApp extends StatefulWidget {
  final ApiClient apiClient;
  final bool hasSeenOnboarding;
  final bool hasSelectedLanguage;
  final bool hasSeenPermissions;

  const LoomeaApp({
    super.key,
    required this.apiClient,
    this.hasSeenOnboarding = false,
    this.hasSelectedLanguage = false,
    this.hasSeenPermissions = false,
  });

  @override
  State<LoomeaApp> createState() => _LoomeaAppState();
}

class _LoomeaAppState extends State<LoomeaApp> {
  late final LoomeeaRepository _repository;
  late final GoRouter _router;
  late final AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSub;
  late final PasswordResetBloc _passwordResetBloc;

  @override
  void initState() {
    super.initState();
    AppLocalizations.instance.addListener(_onLocaleChanged);
    final apiClient = widget.apiClient;
    _repository = ApiRepository(client: apiClient);
    _passwordResetBloc = PasswordResetBloc(repository: _repository);
    _router = createAppRouter(
      apiClient: apiClient,
      hasSeenOnboarding: widget.hasSeenOnboarding,
      hasSelectedLanguage: widget.hasSelectedLanguage,
      hasSeenPermissions: widget.hasSeenPermissions,
    );

    _appLinks = AppLinks();
    _initDeepLinks();
  }

  Future<void> _initDeepLinks() async {
    // Handle link that opened the app (cold start)
    final initialUri = await _appLinks.getInitialLink();
    if (initialUri != null) _handleDeepLink(initialUri);

    // Handle links while app is running (warm start)
    _linkSub = _appLinks.uriLinkStream.listen(_handleDeepLink);
  }

  void _handleDeepLink(Uri uri) {
    // Match: https://looki.tn/reset?token=... OR looki://reset?token=...
    if (uri.path == '/reset' || uri.path.startsWith('/reset')) {
      final token = uri.queryParameters['token'];
      if (token != null && token.isNotEmpty) {
        _passwordResetBloc.add(ValidateEmailToken(token));
        // Listen for the result and navigate accordingly.
        late final StreamSubscription<PasswordResetState> sub;
        sub = _passwordResetBloc.stream.listen((state) {
          if (state.status == PasswordResetStatus.tokenReady) {
            sub.cancel();
            _router.goNamed('newPassword');
          } else if (state.status == PasswordResetStatus.error) {
            sub.cancel();
            _router.goNamed('forgotPassword');
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _linkSub?.cancel();
    _passwordResetBloc.close();
    AppLocalizations.instance.removeListener(_onLocaleChanged);
    super.dispose();
  }

  void _onLocaleChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final apiClient = widget.apiClient;

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<LoomeeaRepository>.value(value: _repository),
        RepositoryProvider<ApiClient>.value(value: apiClient),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) => AuthBloc(repository: _repository),
          ),
          BlocProvider(
            create: (_) =>
                SalonBloc(repository: _repository)..add(LoadSalons()),
          ),
          BlocProvider(
            create: (_) => ProfileBloc(repository: _repository),
          ),
          BlocProvider(
            create: (_) => BookingBloc(repository: _repository),
          ),
          BlocProvider(
            create: (_) => SearchBloc(repository: _repository),
          ),
          // Owner blocs
          BlocProvider(
            create: (_) => OwnerSalonBloc(repository: _repository),
          ),
          BlocProvider(
            create: (_) => OwnerBookingBloc(repository: _repository),
          ),
          BlocProvider(
            create: (_) => OwnerDashboardBloc(repository: _repository),
          ),
          BlocProvider(
            create: (_) => OwnerProfileBloc(repository: _repository),
          ),
          BlocProvider(
            create: (_) => WaitlistBloc(repository: _repository),
          ),
          BlocProvider.value(value: _passwordResetBloc),
        ],
        child: MaterialApp.router(
          title: 'looki',
          debugShowCheckedModeBanner: false,
          useInheritedMediaQuery: true,
          locale: DevicePreview.locale(context),
          theme: buildLoomeaTheme(
            textTheme: GoogleFonts.plusJakartaSansTextTheme(),
          ),
          routerConfig: _router,
          builder: (context, child) {
            child = DevicePreview.appBuilder(context, child);
            final content = child ?? const SizedBox.shrink();
            final textDirection = AppLocalizations.instance.isRtl
                ? TextDirection.rtl
                : TextDirection.ltr;
            final client = apiClient;
            return Directionality(
              textDirection: textDirection,
              child: ValueListenableBuilder<bool>(
                valueListenable: client.connectivityError,
                builder: (context, hasError, _) {
                  return Stack(
                    children: [
                      content,
                      if (hasError)
                        AppErrorScreen(
                          onRetry: () =>
                              client.connectivityError.value = false,
                        ),
                    ],
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
