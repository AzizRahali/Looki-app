import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../data/models/appointment_model.dart';
import '../../core/utils/image_utils.dart';
import '../../../data/models/waitlist_model.dart';
import '../../../logic/blocs/booking/booking_bloc.dart';
import '../../../logic/blocs/booking/booking_event.dart';
import '../../../logic/blocs/booking/booking_state.dart';
import '../../../logic/blocs/profile/profile_bloc.dart';
import '../../../logic/blocs/profile/profile_state.dart';
import '../../../logic/blocs/salon/salon_bloc.dart';
import '../../../logic/blocs/salon/salon_event.dart';
import '../../../logic/blocs/waitlist/waitlist_bloc.dart';
import '../../../logic/blocs/waitlist/waitlist_event.dart';
import '../../../logic/blocs/waitlist/waitlist_state.dart';
import '../../core/routes/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/loomea_tokens.dart';
import '../../../data/services/localization_service.dart';

class MyAppointmentsPage extends StatefulWidget {
  const MyAppointmentsPage({super.key});

  @override
  State<MyAppointmentsPage> createState() => _MyAppointmentsPageState();
}

class _MyAppointmentsPageState extends State<MyAppointmentsPage> {
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    context.read<BookingBloc>().add(LoadAppointments());
    context.read<WaitlistBloc>().add(LoadWaitlist());
  }

  void _reschedule(Appointment appointment) {
    context.read<SalonBloc>().add(LoadSalonByName(appointment.salonName));
    context.pushNamed(AppRoute.selectTimeSlot.name, extra: appointment.id);
  }

  void _cancel(Appointment appointment) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(LoomeaTokens.radiusCard),
        ),
        title: Text(tr('cancel_appointment')),
        content: Text(
          'Are you sure you want to cancel your appointment at ${appointment.salonName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(tr('keep'), style: const TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.read<BookingBloc>().add(CancelBooking(appointment.id));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Appointment at ${appointment.salonName} cancelled'),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              );
            },
            child: Text(tr('cancel_appointment'), style: const TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  void _bookAgain(Appointment appointment) {
    context.pushNamed(AppRoute.salonProfile.name, extra: appointment.salonName);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WaitlistBloc, WaitlistState>(
      builder: (context, waitlistState) => BlocBuilder<BookingBloc, BookingState>(
        builder: (context, state) {
          final appointments = _selectedTab == 0 ? state.upcoming : state.past;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: LoomeaTokens.screenPaddingH),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                Text(
                  tr('my_appointments'),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.025 * 32,
                    height: 1.1,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                BlocBuilder<ProfileBloc, ProfileState>(
                  buildWhen: (p, c) =>
                      p.profile?.reliabilityTier != c.profile?.reliabilityTier,
                  builder: (context, profileState) {
                    final tier = profileState.profile?.reliabilityTier;
                    if (tier == 'RISKY' || tier == 'RESTRICTED') {
                      return _ReliabilityBanner(tier: tier!);
                    }
                    return const SizedBox.shrink();
                  },
                ),
                _TabSelector(
                  selectedTab: _selectedTab,
                  onTabChanged: (i) => setState(() => _selectedTab = i),
                ),
                const SizedBox(height: 24),
                if (_selectedTab == 2) ...[
                  if (waitlistState.entries.isEmpty)
                    const _EmptyWaitlist()
                  else
                    ...waitlistState.entries.map((e) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _WaitlistCard(
                            entry: e,
                            onLeave: () =>
                                context.read<WaitlistBloc>().add(LeaveWaitlist(e.id)),
                            onBook: () => context.pushNamed(
                              AppRoute.salonProfile.name,
                              extra: e.salonName,
                            ),
                          ),
                        )),
                ] else if (state.status == BookingStatus.loading)
                  const Center(child: CircularProgressIndicator())
                else if (appointments.isEmpty)
                  _EmptyState(selectedTab: _selectedTab)
                else
                  Column(
                    children: appointments.map((apt) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _AppointmentCard(
                        appointment: apt,
                        onReschedule: () => _reschedule(apt),
                        onCancel: () => _cancel(apt),
                        onBookAgain: () => _bookAgain(apt),
                        onConfirmAttendance: apt.needsAttendanceConfirmation
                            ? () => context.read<BookingBloc>().add(ConfirmAttendance(apt.id))
                            : null,
                      ),
                    )).toList(),
                  ),
                if (_selectedTab == 0 && appointments.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _BookMoreCard(onBrowse: () => context.pushNamed(AppRoute.search.name)),
                ],
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Widgets ──────────────────────────────────────────────────────────────────

class _TabSelector extends StatelessWidget {
  const _TabSelector({required this.selectedTab, required this.onTabChanged});
  final int selectedTab;
  final ValueChanged<int> onTabChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(LoomeaTokens.radiusPill),
      ),
      child: Row(
        children: [
          _SegmentChip(
            label: tr('upcoming'),
            isSelected: selectedTab == 0,
            onTap: () => onTabChanged(0),
          ),
          _SegmentChip(
            label: tr('past'),
            isSelected: selectedTab == 1,
            onTap: () => onTabChanged(1),
          ),
          _SegmentChip(
            label: tr('waitlist'),
            isSelected: selectedTab == 2,
            onTap: () => onTabChanged(2),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.selectedTab});
  final int selectedTab;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 60),
        child: Column(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.calendar_today_outlined,
                size: 32,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              selectedTab == 0 ? tr('no_upcoming_appointments') : tr('no_past_appointments'),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookMoreCard extends StatelessWidget {
  const _BookMoreCard({required this.onBrowse});
  final VoidCallback onBrowse;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(LoomeaTokens.radiusCard),
      ),
      child: Column(
        children: [
          const Icon(Icons.calendar_today_outlined, size: 32, color: AppColors.textSecondary),
          const SizedBox(height: 12),
          Text(
            tr('book_next_session'),
            style: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 40,
            child: ElevatedButton(
              onPressed: onBrowse,
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24)),
              child: Text(tr('browse_salons')),
            ),
          ),
        ],
      ),
    );
  }
}

class _SegmentChip extends StatelessWidget {
  const _SegmentChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 36,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.background : Colors.transparent,
            borderRadius: BorderRadius.circular(LoomeaTokens.radiusPill),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.textPrimary.withValues(alpha: 0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  const _AppointmentCard({
    required this.appointment,
    required this.onReschedule,
    required this.onCancel,
    required this.onBookAgain,
    this.onConfirmAttendance,
  });

  final Appointment appointment;
  final VoidCallback onReschedule;
  final VoidCallback onCancel;
  final VoidCallback onBookAgain;
  final VoidCallback? onConfirmAttendance;

  (String, Color) get _statusStyle {
    if (appointment.isPending) return (tr('status_pending'), const Color(0xFFE5A100));
    if (appointment.isConfirmed) return (tr('status_confirmed'), AppColors.success);
    if (appointment.isCancelled) return (tr('status_cancelled'), AppColors.error);
    if (appointment.isCompleted) return (tr('status_completed'), AppColors.textSecondary);
    return (appointment.statusLabel, AppColors.textSecondary);
  }

  @override
  Widget build(BuildContext context) {
    final isPast = appointment.isCompleted || appointment.isCancelled;
    final (statusText, statusColor) = _statusStyle;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(LoomeaTokens.radiusCard),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Salon image
          () {
            final rawUrl = appointment.salonImageUrl;
            final resolvedUrl = rawUrl.isEmpty ? '' : resolveImageUrl(rawUrl);
            return resolvedUrl.isNotEmpty
                ? Image.network(
                    resolvedUrl,
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        Container(height: 120, color: AppColors.inputBackground),
                  )
                : Container(height: 120, color: AppColors.inputBackground);
          }(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        appointment.salonName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    _StatusBadge(text: statusText, color: statusColor),
                  ],
                ),
                if (appointment.isPending) ...[
                  const SizedBox(height: 6),
                  const _PendingHint(),
                ],
                const SizedBox(height: 8),
                Text(
                  appointment.servicesText,
                  style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 6),
                _IconRow(
                  icon: Icons.calendar_today_outlined,
                  text: '${appointment.date}  ·  ${appointment.time}',
                ),
                const SizedBox(height: 4),
                _IconRow(icon: Icons.location_on_outlined, text: appointment.address, expand: true),
                if (appointment.needsAttendanceConfirmation) ...[
                  const SizedBox(height: 12),
                  _AttendanceBanner(onConfirm: onConfirmAttendance),
                ],
                if (appointment.isUpcoming && !isPast) ...[
                  const SizedBox(height: 16),
                  _AppointmentActionRow(
                    isConfirmed: appointment.isConfirmed,
                    onReschedule: onReschedule,
                    onCancel: onCancel,
                  ),
                ],
                if (isPast) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: onBookAgain,
                      style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(40)),
                      child: Text(tr('book_again')),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.text, required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(LoomeaTokens.radiusPill),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _PendingHint extends StatelessWidget {
  const _PendingHint();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.hourglass_top_rounded, size: 14, color: Color(0xFFE5A100)),
        const SizedBox(width: 6),
        Text(
          tr('waiting_for_confirmation'),
          style: const TextStyle(
            fontSize: 12,
            fontStyle: FontStyle.italic,
            color: Color(0xFFE5A100),
          ),
        ),
      ],
    );
  }
}

class _IconRow extends StatelessWidget {
  const _IconRow({required this.icon, required this.text, this.expand = false});
  final IconData icon;
  final String text;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final label = Text(
      text,
      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
    );
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        expand ? Expanded(child: label) : label,
      ],
    );
  }
}

class _AttendanceBanner extends StatelessWidget {
  const _AttendanceBanner({required this.onConfirm});
  final VoidCallback? onConfirm;

  static const _amber = Color(0xFFF59E0B);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _amber.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _amber.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, size: 15, color: _amber),
              const SizedBox(width: 6),
              Text(
                tr('attendance_required'),
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _amber),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Please confirm you will attend, otherwise your '
            'booking may be automatically cancelled.',
            style: TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 34,
            child: ElevatedButton(
              onPressed: onConfirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: _amber,
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              child: Text(tr('confirm_attendance'), style: const TextStyle(fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }
}

class _AppointmentActionRow extends StatelessWidget {
  const _AppointmentActionRow({
    required this.isConfirmed,
    required this.onReschedule,
    required this.onCancel,
  });
  final bool isConfirmed;
  final VoidCallback onReschedule;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (isConfirmed) ...[
          Expanded(
            child: OutlinedButton(
              onPressed: onReschedule,
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(40)),
              child: Text(tr('reschedule')),
            ),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: OutlinedButton(
            onPressed: onCancel,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(40),
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.error),
            ),
            child: Text(tr('cancel')),
          ),
        ),
      ],
    );
  }
}

class _WaitlistCard extends StatelessWidget {
  final WaitlistEntry entry;
  final VoidCallback onLeave;
  final VoidCallback onBook;
  const _WaitlistCard({required this.entry, required this.onLeave, required this.onBook});

  @override
  Widget build(BuildContext context) {
    final isNotified = entry.isNotified;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(LoomeaTokens.radiusCard),
        border: isNotified ? Border.all(color: AppColors.primary, width: 1.5) : null,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isNotified
                  ? AppColors.primary.withValues(alpha: 0.12)
                  : AppColors.inputBackground,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isNotified ? Icons.notifications_active_rounded : Icons.hourglass_top_rounded,
              color: isNotified ? AppColors.primary : AppColors.textSecondary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.salonName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  entry.date,
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
                if (isNotified) ...[
                  const SizedBox(height: 4),
                  Text(
                    tr('slot_opened'),
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (isNotified)
            ElevatedButton(
              onPressed: onBook,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(tr('book'), style: const TextStyle(fontSize: 13)),
            )
          else
            TextButton(
              onPressed: onLeave,
              child: Text(tr('leave_waitlist'), style: const TextStyle(color: AppColors.error, fontSize: 13)),
            ),
        ],
      ),
    );
  }
}

class _EmptyWaitlist extends StatelessWidget {
  const _EmptyWaitlist();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.hourglass_empty_rounded, size: 48, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            Text(
              tr('no_waitlist'),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              tr('no_waitlist_desc'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReliabilityBanner extends StatelessWidget {
  const _ReliabilityBanner({required this.tier});
  final String tier;

  @override
  Widget build(BuildContext context) {
    final isRestricted = tier == 'RESTRICTED';
    final color = isRestricted ? const Color(0xFFEF4444) : const Color(0xFFF59E0B);
    final icon = isRestricted ? Icons.block_rounded : Icons.warning_amber_rounded;
    final message = isRestricted
        ? 'Your booking access is restricted due to missed appointments. '
          'Complete existing appointments and maintain a good attendance record to recover.'
        : 'Your reliability score is low due to missed appointments. '
          'Attendance confirmation is required for new bookings.';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(LoomeaTokens.radiusCard),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(fontSize: 13, height: 1.45, color: color.withValues(alpha: 0.9)),
            ),
          ),
        ],
      ),
    );
  }
}
