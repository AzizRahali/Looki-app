import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../logic/blocs/booking/booking_bloc.dart';
import '../../../logic/blocs/booking/booking_state.dart';
import '../../../logic/blocs/profile/profile_bloc.dart';
import '../../../logic/blocs/profile/profile_state.dart';
import '../../../logic/blocs/salon/salon_bloc.dart';
import '../../../logic/blocs/salon/salon_state.dart';
import '../../core/routes/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/loomea_tokens.dart';
import '../../core/widgets/loomea_ui.dart';
import '../../../data/services/localization_service.dart';

class BookingConfirmationPage extends StatefulWidget {
  const BookingConfirmationPage({super.key});

  @override
  State<BookingConfirmationPage> createState() =>
      _BookingConfirmationPageState();
}

class _BookingConfirmationPageState extends State<BookingConfirmationPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnim;
  bool _calendarAdded = false;

  String _formatFullDate(int year, int month, int day) {
    if (day == 0) return tr('select_date');
    final dt = DateTime(year, month, day);
    return '${tr('day_${dt.weekday}')}, ${tr('month_$month')} $day';
  }

  Future<void> _showCalendarAdded() async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 52),
            const SizedBox(height: 16),
            Text(
              tr('added_to_calendar_title'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              tr('calendar_saved_msg'),
              style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text(tr('ok'))),
        ],
      ),
    );
    if (mounted) {
      setState(() => _calendarAdded = true);
      context.goNamed(AppRoute.home.name);
    }
  }

  String _estimateEndTime(String startTime, int durationMinutes) {
    final parts = startTime.split(' ');
    if (parts.length != 2) return startTime;
    final timeParts = parts[0].split(':');
    if (timeParts.length != 2) return startTime;

    var hour = int.tryParse(timeParts[0]) ?? 10;
    var minute = int.tryParse(timeParts[1]) ?? 0;
    final isPm = parts[1].toUpperCase() == 'PM';

    if (isPm && hour != 12) hour += 12;
    if (!isPm && hour == 12) hour = 0;

    final totalMinutes = hour * 60 + minute + durationMinutes;
    var endHour = (totalMinutes ~/ 60) % 24;
    final endMinute = totalMinutes % 60;
    final endPm = endHour >= 12;
    if (endHour > 12) endHour -= 12;
    if (endHour == 0) endHour = 12;

    return '$endHour:${endMinute.toString().padLeft(2, '0')} ${endPm ? 'PM' : 'AM'}';
  }

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnim = CurvedAnimation(parent: _animController, curve: Curves.elasticOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SalonBloc, SalonState>(
      builder: (context, salonState) {
        return BlocBuilder<BookingBloc, BookingState>(
          builder: (context, bookingState) {
            return BlocBuilder<ProfileBloc, ProfileState>(
              builder: (context, profileState) {
                final salon = salonState.selectedSalon;
                final salonName = salon?.name ?? 'Loomea Studio';
                final salonAddress = salon?.fullAddress ?? 'Downtown District, NYC';
                final servicesNames = salonState.selectedServicesNames.isNotEmpty
                    ? salonState.selectedServicesNames
                    : 'Selected Services';
                final selectedTime = bookingState.selectedTime.isNotEmpty
                    ? bookingState.selectedTime
                    : '10:00 AM';
                final selectedDay = bookingState.selectedDay;
                final selectedMonth = bookingState.selectedMonth > 0
                    ? bookingState.selectedMonth
                    : DateTime.now().month;
                final selectedYear = bookingState.selectedYear > 0
                    ? bookingState.selectedYear
                    : DateTime.now().year;
                final payment = profileState.profile?.defaultPayment;
                final paymentDisplay = payment?.displayName ?? 'Visa ending in 4242';

                final selectedServices = salon?.services
                        .where((s) => salonState.selectedServiceIds.contains(s.id))
                        .toList() ??
                    [];
                final totalDuration = selectedServices.fold<int>(0, (sum, s) => sum + s.duration);

                return Scaffold(
                  backgroundColor: AppColors.background,
                  appBar: AppBar(
                    automaticallyImplyLeading: false,
                    title: Text(tr('booking_submitted')),
                  ),
                  body: SafeArea(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                          horizontal: LoomeaTokens.screenPaddingH),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(height: 40),
                          _SuccessAnimation(scaleAnim: _scaleAnim),
                          const SizedBox(height: 24),
                          Text(
                            tr('your_chair_is_held'),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 32,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.025 * 32,
                              height: 1.1,
                              color: AppColors.textPrimary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            tr('waiting_for_confirmation'),
                            style: const TextStyle(
                                fontSize: 15, height: 1.5, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 32),
                          _BookingDetailsCard(
                            salonName: salonName,
                            salonAddress: salonAddress,
                            servicesNames: servicesNames,
                            totalDuration: totalDuration,
                            dateLabel: _formatFullDate(selectedYear, selectedMonth, selectedDay),
                            timeRange: '$selectedTime — ${_estimateEndTime(selectedTime, totalDuration)}',
                            paymentDisplay: paymentDisplay,
                          ),
                          const SizedBox(height: 28),
                          _ActionButtons(
                            calendarAdded: _calendarAdded,
                            onCalendar: _showCalendarAdded,
                            onHome: () => context.goNamed(AppRoute.home.name),
                          ),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

// ── Widgets ──────────────────────────────────────────────────────────────────

class _SuccessAnimation extends StatelessWidget {
  const _SuccessAnimation({required this.scaleAnim});
  final Animation<double> scaleAnim;

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: scaleAnim,
      child: Container(
        width: 88,
        height: 88,
        decoration: BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.25),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Icon(Icons.check_rounded, color: Colors.white, size: 40),
      ),
    );
  }
}

class _BookingDetailsCard extends StatelessWidget {
  const _BookingDetailsCard({
    required this.salonName,
    required this.salonAddress,
    required this.servicesNames,
    required this.totalDuration,
    required this.dateLabel,
    required this.timeRange,
    required this.paymentDisplay,
  });

  final String salonName, salonAddress, servicesNames;
  final int totalDuration;
  final String dateLabel, timeRange, paymentDisplay;

  @override
  Widget build(BuildContext context) {
    return LoomeaSurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        children: [
          _DetailRow(
            icon: Icons.apartment_rounded,
            label: tr('salon').toUpperCase(),
            title: salonName,
            subtitle: salonAddress,
          ),
          const _DashedDivider(),
          _DetailRow(
            icon: Icons.edit_rounded,
            label: tr('services').toUpperCase(),
            title: servicesNames,
            subtitle: tr('minutes_duration', args: ['$totalDuration']),
          ),
          const _DashedDivider(),
          _DetailRow(
            icon: Icons.calendar_today_rounded,
            label: tr('date_and_time').toUpperCase(),
            title: dateLabel,
            subtitle: timeRange,
          ),
          const _DashedDivider(),
          _PaymentRow(paymentDisplay: paymentDisplay),
        ],
      ),
    );
  }
}

class _DashedDivider extends StatelessWidget {
  const _DashedDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          const dashWidth = 5.0;
          const dashSpace = 4.0;
          final dashCount = (constraints.maxWidth / (dashWidth + dashSpace)).floor();
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(dashCount, (_) {
              return const SizedBox(
                width: dashWidth,
                height: 1,
                child: DecoratedBox(decoration: BoxDecoration(color: AppColors.border)),
              );
            }),
          );
        },
      ),
    );
  }
}

class _PaymentRow extends StatelessWidget {
  const _PaymentRow({required this.paymentDisplay});
  final String paymentDisplay;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            color: AppColors.inputBackground,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.credit_card_outlined, size: 18, color: AppColors.textPrimary),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tr('payment_method').toUpperCase(),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Flexible(
                    child: Text(
                      paymentDisplay,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(LoomeaTokens.radiusPill),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      tr('paid'),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({
    required this.calendarAdded,
    required this.onCalendar,
    required this.onHome,
  });

  final bool calendarAdded;
  final VoidCallback onCalendar;
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: LoomeaTokens.buttonHeight,
          child: ElevatedButton.icon(
            onPressed: calendarAdded ? null : onCalendar,
            icon: Icon(
              calendarAdded ? Icons.check_circle_rounded : Icons.calendar_today_outlined,
              size: 18,
            ),
            label: Text(calendarAdded ? tr('added_to_calendar') : tr('add_to_calendar')),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: LoomeaTokens.buttonHeight,
          child: OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none_rounded, size: 18),
            label: Text(tr('set_reminder')),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.border),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(LoomeaTokens.radiusPill),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: onHome,
          child: Text(
            tr('back_home'),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String label, title, subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            color: AppColors.inputBackground,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 18, color: AppColors.textPrimary),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
