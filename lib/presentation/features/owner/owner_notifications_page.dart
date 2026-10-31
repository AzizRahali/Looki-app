import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../data/services/localization_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/loomea_tokens.dart';
import '../../core/widgets/loomea_ui.dart';

class OwnerNotificationsPage extends StatefulWidget {
  const OwnerNotificationsPage({super.key});

  @override
  State<OwnerNotificationsPage> createState() => _OwnerNotificationsPageState();
}

class _OwnerNotificationsPageState extends State<OwnerNotificationsPage> {
  bool _newBookingAlerts = true;
  bool _cancellationAlerts = true;
  bool _rescheduleAlerts = true;
  bool _reviewAlerts = true;
  bool _dailySummary = false;
  bool _pushNotifications = true;
  bool _emailNotifications = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: LoomeaAppBarLeading(onPressed: () => Navigator.of(context).pop()),
        title: Text(
          tr('notifications'),
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(LoomeaTokens.screenPaddingH),
        children: [
          const _SectionHeader(title: 'BOOKINGS'),
          _ToggleRow(
            icon: Icons.calendar_month_rounded,
            label: 'New Booking Requests',
            subtitle: 'Get alerted when a client books an appointment',
            value: _newBookingAlerts,
            onChanged: (v) => setState(() => _newBookingAlerts = v),
          ),
          _ToggleRow(
            icon: Icons.event_busy_rounded,
            label: 'Cancellations',
            subtitle: 'Be notified when a client cancels their booking',
            value: _cancellationAlerts,
            onChanged: (v) => setState(() => _cancellationAlerts = v),
          ),
          _ToggleRow(
            icon: Icons.update_rounded,
            label: 'Reschedule Requests',
            subtitle: 'Alerts when a client requests to reschedule',
            value: _rescheduleAlerts,
            onChanged: (v) => setState(() => _rescheduleAlerts = v),
          ),
          const SizedBox(height: 24),
          const _SectionHeader(title: 'REVIEWS'),
          _ToggleRow(
            icon: Icons.star_outline_rounded,
            label: 'New Review Alerts',
            subtitle: 'Know when a client leaves you a review',
            value: _reviewAlerts,
            onChanged: (v) => setState(() => _reviewAlerts = v),
          ),
          const SizedBox(height: 24),
          const _SectionHeader(title: 'REPORTS'),
          _ToggleRow(
            icon: Icons.bar_chart_rounded,
            label: 'Daily Summary',
            subtitle: 'End-of-day recap of bookings and revenue',
            value: _dailySummary,
            onChanged: (v) => setState(() => _dailySummary = v),
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
            subtitle: 'Receive alerts via email',
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
