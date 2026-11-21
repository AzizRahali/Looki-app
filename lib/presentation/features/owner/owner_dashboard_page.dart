import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../data/models/owner_booking_model.dart';
import '../../../data/models/owner_dashboard_model.dart';
import '../../../data/models/owner_insights_model.dart';
import '../../../logic/blocs/owner_dashboard/owner_dashboard_bloc.dart';
import '../../../logic/blocs/owner_dashboard/owner_dashboard_event.dart';
import '../../../logic/blocs/owner_dashboard/owner_dashboard_state.dart';
import '../../../logic/blocs/owner_salon/owner_salon_bloc.dart';
import '../../../logic/blocs/owner_salon/owner_salon_state.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/loomea_tokens.dart';
import '../../core/widgets/loomea_ui.dart';
import '../../../data/services/localization_service.dart';

class OwnerDashboardPage extends StatelessWidget {
  const OwnerDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<OwnerSalonBloc, OwnerSalonState>(
      listenWhen: (prev, curr) =>
          prev.salon?.id != curr.salon?.id && curr.salon != null,
      listener: (context, state) {
        context
            .read<OwnerDashboardBloc>()
            .add(LoadDashboard(state.salon!.id));
      },
      child: SafeArea(
        child: BlocBuilder<OwnerDashboardBloc, OwnerDashboardState>(
          builder: (context, state) {
            if (state.status == OwnerDashboardStatus.loading ||
                state.status == OwnerDashboardStatus.initial) {
              return const Center(
                  child:
                      CircularProgressIndicator(color: AppColors.primary));
            }
            if (state.status == OwnerDashboardStatus.error) {
              return _DashboardError(
                error: state.error,
                onRetry: () {
                  final salon = context.read<OwnerSalonBloc>().state.salon;
                  if (salon != null) {
                    context.read<OwnerDashboardBloc>().add(LoadDashboard(salon.id));
                  }
                },
              );
            }
            final d = state.dashboard!;
            return RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async {
                final salon =
                    context.read<OwnerSalonBloc>().state.salon;
                if (salon != null) {
                  context
                      .read<OwnerDashboardBloc>()
                      .add(LoadDashboard(salon.id));
                }
              },
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                    LoomeaTokens.screenPaddingH, 24,
                    LoomeaTokens.screenPaddingH, 32),
                children: [
                  // — Greeting
                  Text(
                    tr('owner_greeting', args: [d.salonName]),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.025 * 30,
                      height: 1.15,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // — Navy revenue tile
                  _RevenueTile(
                    todayRevenue: d.todayRevenue,
                    monthlyRevenue: d.totalRevenue,
                  ),
                  const SizedBox(height: 12),
                  _StatsGrid(dashboard: d),
                  const SizedBox(height: 16),
                  _InsightsCard(
                    status: state.insightsStatus,
                    insights: state.insights,
                    onRetry: () => context.read<OwnerDashboardBloc>().add(
                        LoadInsights(d.salonId, AppLocalizations.instance.locale)),
                  ),
                  const SizedBox(height: 28),
                  _ScheduleHeader(count: d.todayBookings.length),
                  const SizedBox(height: 16),
                  if (d.todayBookings.isEmpty)
                    _EmptyTimeline()
                  else
                    _BookingTimeline(bookings: d.todayBookings),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  static String _formattedDate() {
    final now = DateTime.now();
    final day = tr('day_${now.weekday}');
    final month = tr('month_${now.month}');
    return '$day, ${now.day} $month';
  }
}

class _DashboardError extends StatelessWidget {
  const _DashboardError({required this.error, required this.onRetry});
  final String? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.errorBg,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.wifi_off_rounded, color: AppColors.error, size: 24),
          ),
          const SizedBox(height: 16),
          const Text(
            'Something went wrong',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 6),
          Text(error ?? '', style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
          const SizedBox(height: 20),
          OutlinedButton(
            onPressed: onRetry,
            style: OutlinedButton.styleFrom(minimumSize: const Size(140, 44)),
            child: Text(tr('retry')),
          ),
        ],
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.dashboard});
  final Dashboard dashboard;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            _MiniStat(
              value: dashboard.todayAppointments,
              label: tr('today'),
              icon: Icons.today_rounded,
              color: AppColors.primary,
            ),
            const SizedBox(width: 10),
            _MiniStat(
              value: dashboard.upcomingAppointments,
              label: tr('upcoming'),
              icon: Icons.schedule_rounded,
              color: AppColors.warning,
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _MiniStat(
              value: dashboard.completedAppointments,
              label: tr('status_completed'),
              icon: Icons.check_circle_outline_rounded,
              color: AppColors.success,
            ),
            const SizedBox(width: 10),
            _MiniStat(
              value: dashboard.cancelledAppointments,
              label: tr('status_cancelled'),
              icon: Icons.cancel_outlined,
              color: AppColors.error,
            ),
          ],
        ),
      ],
    );
  }
}

class _InsightsCard extends StatelessWidget {
  const _InsightsCard({
    required this.status,
    required this.insights,
    required this.onRetry,
  });

  final InsightsStatus status;
  final OwnerInsights? insights;
  final VoidCallback onRetry;

  static const _secondary = TextStyle(fontSize: 13, color: AppColors.textSecondary);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(LoomeaTokens.radiusCard),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded,
                  size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                tr('insights_title'),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              if (insights != null && status == InsightsStatus.loaded)
                Text(
                  tr('insights_period', args: ['${insights!.periodDays}']),
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
            ],
          ),
          const SizedBox(height: 12),
          ..._body(),
        ],
      ),
    );
  }

  List<Widget> _body() {
    switch (status) {
      case InsightsStatus.initial:
      case InsightsStatus.loading:
        return [
          Row(
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppColors.primary),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(tr('insights_loading'), style: _secondary)),
            ],
          ),
        ];
      case InsightsStatus.error:
        return [
          Row(
            children: [
              Expanded(child: Text(tr('insights_error'), style: _secondary)),
              TextButton(onPressed: onRetry, child: Text(tr('retry'))),
            ],
          ),
        ];
      case InsightsStatus.loaded:
        final i = insights!;
        if (!i.enoughData) {
          return [Text(tr('insights_not_enough_data'), style: _secondary)];
        }
        return [
          if (i.summary != null) ...[
            Text(
              i.summary!,
              style: const TextStyle(
                  fontSize: 14, height: 1.4, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 14),
          ],
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InsightMetric(
                label: tr('insights_bookings'),
                value: '${i.bookings}',
                changePercent: i.bookingsChangePercent,
              ),
              _InsightMetric(
                label: tr('insights_revenue'),
                value: formatPrice(i.revenue),
                changePercent: i.revenueChangePercent,
              ),
              if (i.cancellationRate != null)
                _InsightMetric(
                  label: tr('insights_cancellations'),
                  value: '${i.cancellationRate}%',
                ),
              if (i.noShowRate != null)
                _InsightMetric(
                  label: tr('insights_no_shows'),
                  value: '${i.noShowRate}%',
                ),
              if (i.returningClientRate != null)
                _InsightMetric(
                  label: tr('insights_returning_clients'),
                  value: '${i.returningClientRate}%',
                ),
            ],
          ),
          const SizedBox(height: 14),
          if (i.busiestSlot != null)
            _InsightLine(
              icon: Icons.trending_up_rounded,
              text: tr('insights_busiest', args: [_slot(i.busiestSlot!)]),
            ),
          if (i.quietestSlot != null)
            _InsightLine(
              icon: Icons.trending_down_rounded,
              text: tr('insights_quietest', args: [_slot(i.quietestSlot!)]),
            ),
          if (i.topServices.isNotEmpty)
            _InsightLine(
              icon: Icons.star_outline_rounded,
              text: tr('insights_top_services',
                  args: [i.topServices.map((s) => s.name).join(', ')]),
            ),
          if (i.suggestions.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              tr('insights_suggestions'),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            for (final suggestion in i.suggestions)
              _InsightLine(
                icon: Icons.lightbulb_outline_rounded,
                text: suggestion,
                color: AppColors.textPrimary,
              ),
          ] else if (!i.aiUsed) ...[
            const SizedBox(height: 6),
            Text(tr('insights_ai_unavailable'),
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary)),
          ],
        ];
    }
  }

  static String _slot(InsightSlot slot) => tr('insights_slot', args: [
        tr('day_${slot.dayOfWeek}'),
        tr('insights_${slot.partOfDay}'),
      ]);
}

class _InsightMetric extends StatelessWidget {
  const _InsightMetric({
    required this.label,
    required this.value,
    this.changePercent,
  });

  final String label;
  final String value;
  final int? changePercent;

  @override
  Widget build(BuildContext context) {
    final change = changePercent;
    final changeColor = change == null || change == 0
        ? AppColors.textSecondary
        : change > 0
            ? AppColors.success
            : AppColors.error;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textSecondary)),
          const SizedBox(height: 2),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              if (change != null) ...[
                const SizedBox(width: 6),
                Text(
                  '${change > 0 ? '+' : ''}$change%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: changeColor,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _InsightLine extends StatelessWidget {
  const _InsightLine({
    required this.icon,
    required this.text,
    this.color = AppColors.textSecondary,
  });

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(icon, size: 16, color: AppColors.primary),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: TextStyle(fontSize: 13, height: 1.35, color: color)),
          ),
        ],
      ),
    );
  }
}

class _ScheduleHeader extends StatelessWidget {
  const _ScheduleHeader({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          tr('todays_schedule'),
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
            color: AppColors.textPrimary,
          ),
        ),
        const Spacer(),
        if (count > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(LoomeaTokens.radiusPill),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              '$count chairs',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ),
      ],
    );
  }
}

class _RevenueTile extends StatelessWidget {
  const _RevenueTile({required this.todayRevenue, required this.monthlyRevenue});
  final double todayRevenue;
  final double monthlyRevenue;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(LoomeaTokens.radiusCard),
      ),
      child: Stack(
        children: [
          // Accent glow blob
          Positioned(
            top: -20,
            right: -20,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accent.withValues(alpha: 0.25),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tr('todays_revenue').toUpperCase(),
                      style: LoomeaTokens.eyebrowWith(
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      formatPrice(todayRevenue),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 48,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -2,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 56,
                color: Colors.white.withValues(alpha: 0.15),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tr('monthly').toUpperCase(),
                      style: LoomeaTokens.eyebrowWith(
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      formatPrice(monthlyRevenue),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -1,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final int value;
  final String label;
  final IconData icon;
  final Color color;
  const _MiniStat(
      {required this.value,
      required this.label,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(LoomeaTokens.radiusCard),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$value',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                        color: AppColors.textPrimary)),
                Text(label,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyTimeline extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LoomeaSurfaceCard(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.event_available_rounded,
                color: AppColors.textSecondary, size: 24),
          ),
          const SizedBox(height: 14),
          Text(tr('no_appointments_today'),
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          Text(tr('schedule_clear'),
              style:
                  const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _BookingTimeline extends StatelessWidget {
  final List<OwnerBooking> bookings;
  const _BookingTimeline({required this.bookings});

  @override
  Widget build(BuildContext context) {
    final sorted = List<OwnerBooking>.from(bookings)
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    final now = TimeOfDay.now();
    final nowMin = now.hour * 60 + now.minute;

    return Column(
      children: List.generate(sorted.length, (i) {
        final b = sorted[i];
        final isLast = i == sorted.length - 1;
        final start = _mins(b.startTime);
        final end = _mins(b.endTime);
        final isPast = end <= nowMin;
        final isCurrent = start <= nowMin && nowMin < end;

        return _TimelineEntry(
            booking: b,
            isLast: isLast,
            isPast: isPast,
            isCurrent: isCurrent);
      }),
    );
  }

  int _mins(String t) {
    if (t.length < 5) return 0;
    final p = t.substring(0, 5).split(':');
    return int.parse(p[0]) * 60 + int.parse(p[1]);
  }
}

class _TimelineEntry extends StatelessWidget {
  final OwnerBooking booking;
  final bool isLast;
  final bool isPast;
  final bool isCurrent;

  const _TimelineEntry({
    required this.booking,
    required this.isLast,
    required this.isPast,
    required this.isCurrent,
  });

  Color get _dotColor {
    if (booking.isCancelled) return AppColors.error;
    if (booking.isCompleted) return AppColors.success;
    if (isCurrent) return AppColors.primary;
    if (isPast) return AppColors.textSecondary;
    return AppColors.warning;
  }

  @override
  Widget build(BuildContext context) {
    final time = booking.startTime.length >= 5
        ? booking.startTime.substring(0, 5)
        : booking.startTime;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 48,
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(time,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight:
                        isCurrent ? FontWeight.w700 : FontWeight.w500,
                    color: isCurrent
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                  )),
            ),
          ),
          SizedBox(
            width: 24,
            child: Column(
              children: [
                Container(
                  width: isCurrent ? 14 : 10,
                  height: isCurrent ? 14 : 10,
                  margin: const EdgeInsets.only(top: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCurrent
                        ? _dotColor
                        : _dotColor.withValues(alpha: 0.4),
                    boxShadow: isCurrent
                        ? [
                            BoxShadow(
                                color: _dotColor.withValues(alpha: 0.3),
                                blurRadius: 8,
                                spreadRadius: 2)
                          ]
                        : null,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 1.5,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: AppColors.border,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Container(
              margin: EdgeInsets.only(bottom: isLast ? 0 : 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isCurrent
                    ? AppColors.primary.withValues(alpha: 0.08)
                    : AppColors.surface,
                borderRadius:
                    BorderRadius.circular(LoomeaTokens.radiusCard),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(booking.servicesText,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: isPast && !booking.isCompleted
                                  ? AppColors.textSecondary
                                  : AppColors.textPrimary,
                            )),
                      ),
                      _Badge(booking: booking, isCurrent: isCurrent),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.access_time_rounded,
                          size: 13, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(booking.timeRange,
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary)),
                      const Spacer(),
                      Text(booking.priceText,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: AppColors.textPrimary,
                          )),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final OwnerBooking booking;
  final bool isCurrent;
  const _Badge({required this.booking, required this.isCurrent});

  @override
  Widget build(BuildContext context) {
    final (label, color, bgColor) = switch (true) {
      _ when booking.isCancelled =>
        ('Cancelled', AppColors.error, AppColors.errorBg),
      _ when booking.isCompleted =>
        ('Done', AppColors.success, AppColors.successBg),
      _ when isCurrent => (
          'Now',
          AppColors.textPrimary,
          AppColors.primary.withValues(alpha: 0.2)
        ),
      _ => ('Upcoming', AppColors.warning, AppColors.warningBg),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }
}
