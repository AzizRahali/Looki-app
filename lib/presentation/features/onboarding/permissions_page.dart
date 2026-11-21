import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../data/services/localization_service.dart';
import '../../../data/services/notification_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/loomea_tokens.dart';

class PermissionsPage extends StatefulWidget {
  final VoidCallback onDone;
  const PermissionsPage({super.key, required this.onDone});

  @override
  State<PermissionsPage> createState() => _PermissionsPageState();
}

class _PermissionsPageState extends State<PermissionsPage> {
  int _step = 0; // 0 = location, 1 = notifications
  bool _loading = false;

  Future<void> _allow() async {
    setState(() => _loading = true);
    try {
      if (_step == 0) {
        final status = await Geolocator.checkPermission();
        if (status == LocationPermission.denied ||
            status == LocationPermission.deniedForever) {
          await Geolocator.requestPermission();
        }
      } else {
        await NotificationService.instance.requestPermissions();
      }
    } catch (_) {}
    setState(() => _loading = false);
    _next();
  }

  void _skip() => _next();

  void _next() {
    if (_step == 0) {
      setState(() => _step = 1);
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenPermissions', true);
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    final isLocation = _step == 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: LoomeaTokens.screenPaddingH),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _StepDot(active: _step == 0, done: _step > 0),
                  const SizedBox(width: 8),
                  _StepDot(active: _step == 1, done: false),
                ],
              ),

              const Spacer(flex: 2),

              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isLocation
                      ? Icons.location_on_rounded
                      : Icons.notifications_rounded,
                  size: 52,
                  color: AppColors.primary,
                ),
              ),

              const SizedBox(height: 32),

              Text(
                isLocation
                    ? tr('perm_location_title')
                    : tr('perm_notifications_title'),
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              Text(
                isLocation
                    ? tr('perm_location_desc')
                    : tr('perm_notifications_desc'),
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.6,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),

              const Spacer(flex: 3),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _loading ? null : _allow,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          tr('allow'),
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                ),
              ),

              const SizedBox(height: 14),

              TextButton(
                onPressed: _loading ? null : _skip,
                child: Text(
                  tr('skip_for_now'),
                  style: const TextStyle(
                      fontSize: 15, color: AppColors.textSecondary),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepDot extends StatelessWidget {
  final bool active;
  final bool done;
  const _StepDot({required this.active, required this.done});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: active ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: (active || done) ? AppColors.primary : AppColors.border,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
