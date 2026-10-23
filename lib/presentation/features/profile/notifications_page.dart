import 'package:flutter/material.dart';

import '../../../data/services/localization_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/loomea_tokens.dart';
import '../../core/widgets/loomea_ui.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  bool _bookingConfirmations = true;
  bool _appointmentReminders = true;
  bool _promotions = false;
  bool _salonUpdates = true;
  bool _pushNotifications = true;
  bool _emailNotifications = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading:
            LoomeaAppBarLeading(onPressed: () => Navigator.of(context).pop()),
        title: Text(tr('notifications')),
      ),
      body: ListView(
        padding: const EdgeInsets.all(LoomeaTokens.screenPaddingH),
        children: [
          const _SectionHeader(title: 'BOOKING'),
          _ToggleRow(
            icon: Icons.check_circle_outline_rounded,
            label: 'Booking Confirmations',
            subtitle: 'Get notified when your booking is confirmed',
            value: _bookingConfirmations,
            onChanged: (v) => setState(() => _bookingConfirmations = v),
          ),
          _ToggleRow(
            icon: Icons.alarm_rounded,
            label: 'Appointment Reminders',
            subtitle: 'Reminders before your upcoming appointments',
            value: _appointmentReminders,
            onChanged: (v) => setState(() => _appointmentReminders = v),
          ),
          const SizedBox(height: 24),
          const _SectionHeader(title: 'MARKETING'),
          _ToggleRow(
            icon: Icons.local_offer_outlined,
            label: 'Promotions & Offers',
            subtitle: 'Deals and discounts from your favorite salons',
            value: _promotions,
            onChanged: (v) => setState(() => _promotions = v),
          ),
          _ToggleRow(
            icon: Icons.storefront_outlined,
            label: 'Salon Updates',
            subtitle: 'New services and availability changes',
            value: _salonUpdates,
            onChanged: (v) => setState(() => _salonUpdates = v),
          ),
          const SizedBox(height: 24),
          const _SectionHeader(title: 'CHANNELS'),
          _ToggleRow(
            icon: Icons.notifications_active_outlined,
            label: 'Push Notifications',
            subtitle: 'Receive push notifications on your device',
            value: _pushNotifications,
            onChanged: (v) => setState(() => _pushNotifications = v),
          ),
          _ToggleRow(
            icon: Icons.email_outlined,
            label: 'Email Notifications',
            subtitle: 'Receive notifications via email',
            value: _emailNotifications,
            onChanged: (v) => setState(() => _emailNotifications = v),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 1,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.surface, width: 1),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 22, color: AppColors.textPrimary),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}
