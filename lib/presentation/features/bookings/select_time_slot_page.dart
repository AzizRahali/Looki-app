import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../logic/blocs/booking/booking_bloc.dart';
import '../../../logic/blocs/booking/booking_event.dart';
import '../../../logic/blocs/booking/booking_state.dart';
import '../../../logic/blocs/salon/salon_bloc.dart';
import '../../../logic/blocs/salon/salon_state.dart';
import '../../../logic/blocs/waitlist/waitlist_bloc.dart';
import '../../../logic/blocs/waitlist/waitlist_event.dart';
import '../../../logic/blocs/waitlist/waitlist_state.dart';
import '../../core/routes/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/loomea_tokens.dart';
import '../../core/widgets/loomea_ui.dart';
import '../../../data/services/localization_service.dart';

class SelectTimeSlotPage extends StatefulWidget {
  /// Non-null when arriving from "Reschedule".
  final String? bookingId;

  const SelectTimeSlotPage({super.key, this.bookingId});

  @override
  State<SelectTimeSlotPage> createState() => _SelectTimeSlotPageState();
}

class _SelectTimeSlotPageState extends State<SelectTimeSlotPage> {
  late int _displayedMonth;
  late int _displayedYear;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _displayedMonth = now.month;
    _displayedYear = now.year;
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  void _onConfirmTime(BuildContext context, BookingState bookingState) {
    HapticFeedback.mediumImpact();
    if (widget.bookingId != null) {
      final day = bookingState.selectedDay;
      final month = bookingState.selectedMonth;
      final year = bookingState.selectedYear;
      final date =
          '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
      context.read<BookingBloc>().add(RescheduleBooking(
            bookingId: widget.bookingId!,
            date: date,
            startTime: bookingState.selectedTime,
          ));
      context.pushNamed(AppRoute.bookingConfirmation.name);
    } else {
      context.pushNamed(AppRoute.bookingReview.name);
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (!mounted) return;
      context.read<BookingBloc>().add(const RefreshSlots());
    });
  }

  void _loadSlots(
      BuildContext context, String salonId, int day, int month, int year) {
    final date =
        '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
    context.read<BookingBloc>().add(LoadTimeSlots(salonId: salonId, date: date));
    _startPolling();
  }

  void _prevMonth() {
    final now = DateTime.now();
    if (_displayedYear == now.year && _displayedMonth <= now.month) return;
    setState(() {
      _displayedMonth--;
      if (_displayedMonth < 1) {
        _displayedMonth = 12;
        _displayedYear--;
      }
    });
  }

  void _nextMonth() {
    setState(() {
      _displayedMonth++;
      if (_displayedMonth > 12) {
        _displayedMonth = 1;
        _displayedYear++;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: LoomeaAppBarLeading(onPressed: () => context.pop()),
      ),
      body: SafeArea(
        child: BlocBuilder<SalonBloc, SalonState>(
          builder: (context, salonState) {
            final salonId = salonState.selectedSalon?.id ?? '';

            return BlocBuilder<BookingBloc, BookingState>(
              builder: (context, bookingState) {
                return Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                            horizontal: LoomeaTokens.screenPaddingH),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            if (widget.bookingId == null) ...[
                              Text(
                                tr('step_of', args: ['1', '2']),
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 6),
                            ],
                            Text(
                              tr('pick_a_day'),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 32,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.025 * 32,
                                height: 1.1,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 20),
                            _ServicesSummaryCard(
                              count: salonState.selectedServicesCount,
                              names: salonState.selectedServicesNames,
                              onEdit: () => context.pop(),
                            ),
                            const SizedBox(height: 24),
                            _MonthCalendar(
                              displayedMonth: _displayedMonth,
                              displayedYear: _displayedYear,
                              selectedDay: bookingState.selectedDay,
                              selectedMonth: bookingState.selectedMonth,
                              selectedYear: bookingState.selectedYear,
                              onPrevMonth: _prevMonth,
                              onNextMonth: _nextMonth,
                              onDayTap: (day) {
                                context.read<BookingBloc>().add(SelectDate(
                                    day, _displayedMonth, _displayedYear));
                                if (salonId.isNotEmpty) {
                                  _loadSlots(context, salonId, day,
                                      _displayedMonth, _displayedYear);
                                }
                              },
                            ),
                            const SizedBox(height: 28),
                            _SlotsHeader(
                                isLoading: bookingState.slotsLoading),
                            const SizedBox(height: 14),
                            _SlotList(
                              bookingState: bookingState,
                              onSelectSlot: (time) {
                                HapticFeedback.selectionClick();
                                context
                                    .read<BookingBloc>()
                                    .add(SelectTimeSlot(time));
                              },
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                    _SlotBottomCta(
                      bookingState: bookingState,
                      salonState: salonState,
                      isReschedule: widget.bookingId != null,
                      onConfirm: () => _onConfirmTime(context, bookingState),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Services summary card
// ─────────────────────────────────────────────────────────────────────────────

class _ServicesSummaryCard extends StatelessWidget {
  const _ServicesSummaryCard({
    required this.count,
    required this.names,
    required this.onEdit,
  });

  final int count;
  final String names;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return LoomeaSurfaceCard(
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: AppColors.inputBackground,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.content_cut_rounded,
                size: 20, color: AppColors.textPrimary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr('n_selected_services', args: ['$count']),
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  names.isNotEmpty ? names : tr('no_services_selected'),
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onEdit,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius:
                    BorderRadius.circular(LoomeaTokens.radiusPill),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(tr('edit'),
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Month calendar
// ─────────────────────────────────────────────────────────────────────────────

class _MonthCalendar extends StatelessWidget {
  const _MonthCalendar({
    required this.displayedMonth,
    required this.displayedYear,
    required this.selectedDay,
    required this.selectedMonth,
    required this.selectedYear,
    required this.onPrevMonth,
    required this.onNextMonth,
    required this.onDayTap,
  });

  final int displayedMonth;
  final int displayedYear;
  final int selectedDay;
  final int selectedMonth;
  final int selectedYear;
  final VoidCallback onPrevMonth;
  final VoidCallback onNextMonth;
  final ValueChanged<int> onDayTap;

  @override
  Widget build(BuildContext context) {
    final dayLabels = [
      tr('day_abbr_7'), tr('day_abbr_1'), tr('day_abbr_2'),
      tr('day_abbr_3'), tr('day_abbr_4'), tr('day_abbr_5'), tr('day_abbr_6'),
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(LoomeaTokens.radiusCard),
      ),
      child: Column(
        children: [
          _MonthNavRow(
            label: '${tr('month_$displayedMonth')} $displayedYear',
            onPrev: onPrevMonth,
            onNext: onNextMonth,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: dayLabels
                .map((d) => SizedBox(
                      width: 36,
                      child: Text(d,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary)),
                    ))
                .toList(),
          ),
          const SizedBox(height: 8),
          _CalendarGrid(
            displayedMonth: displayedMonth,
            displayedYear: displayedYear,
            selectedDay: selectedDay,
            selectedMonth: selectedMonth,
            selectedYear: selectedYear,
            onDayTap: onDayTap,
          ),
        ],
      ),
    );
  }
}

class _MonthNavRow extends StatelessWidget {
  const _MonthNavRow({
    required this.label,
    required this.onPrev,
    required this.onNext,
  });

  final String label;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: onPrev,
          child: const Icon(Icons.chevron_left_rounded,
              color: AppColors.textSecondary),
        ),
        Text(
          label,
          style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary),
        ),
        GestureDetector(
          onTap: onNext,
          child: const Icon(Icons.chevron_right_rounded,
              color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _CalendarGrid extends StatelessWidget {
  const _CalendarGrid({
    required this.displayedMonth,
    required this.displayedYear,
    required this.selectedDay,
    required this.selectedMonth,
    required this.selectedYear,
    required this.onDayTap,
  });

  final int displayedMonth;
  final int displayedYear;
  final int selectedDay;
  final int selectedMonth;
  final int selectedYear;
  final ValueChanged<int> onDayTap;

  int get _daysInMonth => DateTime(displayedYear, displayedMonth + 1, 0).day;
  int get _firstWeekday => DateTime(displayedYear, displayedMonth, 1).weekday % 7;

  @override
  Widget build(BuildContext context) {
    final daysInMonth = _daysInMonth;
    final firstWeekday = _firstWeekday;
    final rows = ((firstWeekday + daysInMonth) / 7).ceil();
    final today = DateTime.now();

    return Column(
      children: List.generate(rows, (row) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(7, (col) {
              final index = row * 7 + col;
              final day = index - firstWeekday + 1;

              if (day < 1 || day > daysInMonth) {
                return const SizedBox(width: 36, height: 36);
              }

              final isSelected = selectedDay == day &&
                  selectedMonth == displayedMonth &&
                  selectedYear == displayedYear;

              final isPast =
                  DateTime(displayedYear, displayedMonth, day).isBefore(
                      DateTime(today.year, today.month, today.day));

              return _CalendarDay(
                day: day,
                isSelected: isSelected,
                isPast: isPast,
                onTap: isPast ? null : () => onDayTap(day),
              );
            }),
          ),
        );
      }),
    );
  }
}

class _CalendarDay extends StatelessWidget {
  const _CalendarDay({
    required this.day,
    required this.isSelected,
    required this.isPast,
    required this.onTap,
  });

  final int day;
  final bool isSelected;
  final bool isPast;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Text(
          '$day',
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected
                ? AppColors.onPrimary
                : isPast
                    ? AppColors.textSecondary.withValues(alpha: 0.4)
                    : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Slots header
// ─────────────────────────────────────────────────────────────────────────────

class _SlotsHeader extends StatelessWidget {
  const _SlotsHeader({required this.isLoading});

  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const Icon(Icons.schedule_rounded, size: 18, color: AppColors.textPrimary),
            const SizedBox(width: 8),
            Text(tr('available_time_slots'),
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
          ],
        ),
        if (isLoading)
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: AppColors.primary),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Slot list
// ─────────────────────────────────────────────────────────────────────────────

class _SlotList extends StatelessWidget {
  const _SlotList({
    required this.bookingState,
    required this.onSelectSlot,
  });

  final BookingState bookingState;
  final ValueChanged<String> onSelectSlot;

  @override
  Widget build(BuildContext context) {
    if (bookingState.selectedDay == 0) {
      return _EmptySlotsPlaceholder(
          message: tr('select_date_to_see_times'));
    }
    if (bookingState.slotsLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }
    if (bookingState.slots.isEmpty) {
      return _EmptySlotsPlaceholder(
          message: tr('no_slots_available'));
    }

    final now = DateTime.now();
    final selectedDate = DateTime(
      bookingState.selectedYear,
      bookingState.selectedMonth,
      bookingState.selectedDay,
    );
    final isToday = selectedDate.year == now.year &&
        selectedDate.month == now.month &&
        selectedDate.day == now.day;

    final visibleSlots = isToday
        ? bookingState.slots.where((s) {
            final parts = s.time.split(':');
            if (parts.length < 2) return true;
            final slotTime = DateTime(
              now.year, now.month, now.day,
              int.tryParse(parts[0]) ?? 0,
              int.tryParse(parts[1]) ?? 0,
            );
            return slotTime.isAfter(now.add(const Duration(minutes: 29)));
          }).toList()
        : bookingState.slots;

    return Column(
      children: visibleSlots.map((slot) {
        final isBooked = slot.status.toUpperCase() == 'BOOKED';
        final isLimited = slot.status.toUpperCase() == 'LIMITED';
        final isSelected = bookingState.selectedTime == slot.time;

        return GestureDetector(
          onTap: isBooked ? null : () => onSelectSlot(slot.time),
          child: _TimeSlotTile(
            time: slot.time,
            isSelected: isSelected,
            isDisabled: isBooked,
            isLimited: isLimited,
          ),
        );
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom CTA
// ─────────────────────────────────────────────────────────────────────────────

class _SlotBottomCta extends StatelessWidget {
  const _SlotBottomCta({
    required this.bookingState,
    required this.salonState,
    required this.isReschedule,
    required this.onConfirm,
  });

  final BookingState bookingState;
  final SalonState salonState;
  final bool isReschedule;
  final VoidCallback onConfirm;

  bool get _allBooked =>
      bookingState.selectedDay != 0 &&
      bookingState.slots.isNotEmpty &&
      bookingState.slots.every((s) => s.status.toUpperCase() == 'BOOKED');

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
          LoomeaTokens.screenPaddingH, 12, LoomeaTokens.screenPaddingH, 16),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(
            top: BorderSide(color: AppColors.border.withValues(alpha: 0.5))),
      ),
      child: _allBooked && !isReschedule
          ? _WaitlistButton(
              bookingState: bookingState,
              salonState: salonState,
            )
          : _ConfirmButton(
              isEnabled: bookingState.selectedTime.isNotEmpty,
              isReschedule: isReschedule,
              onConfirm: onConfirm,
            ),
    );
  }
}

class _ConfirmButton extends StatelessWidget {
  const _ConfirmButton({
    required this.isEnabled,
    required this.isReschedule,
    required this.onConfirm,
  });

  final bool isEnabled;
  final bool isReschedule;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!isEnabled) ...[
          Text(
            tr('select_time_to_continue'),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
        ],
        SizedBox(
          width: double.infinity,
          height: LoomeaTokens.buttonHeight,
          child: ElevatedButton(
            onPressed: isEnabled ? onConfirm : null,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(isReschedule
                    ? tr('confirm_reschedule')
                    : tr('confirm_time')),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_rounded, size: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _WaitlistButton extends StatelessWidget {
  const _WaitlistButton({
    required this.bookingState,
    required this.salonState,
  });

  final BookingState bookingState;
  final SalonState salonState;

  @override
  Widget build(BuildContext context) {
    final salonId = salonState.selectedSalon?.id ?? '';
    final salonName = salonState.selectedSalon?.name ?? '';
    final date =
        '${bookingState.selectedYear}-${bookingState.selectedMonth.toString().padLeft(2, '0')}-${bookingState.selectedDay.toString().padLeft(2, '0')}';

    return BlocBuilder<WaitlistBloc, WaitlistState>(
      builder: (context, wState) {
        final alreadyJoined =
            wState.entries.any((e) => e.salonId == salonId && e.date == date);
        return SizedBox(
          width: double.infinity,
          height: LoomeaTokens.buttonHeight,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  alreadyJoined ? AppColors.surface : AppColors.primary,
              foregroundColor:
                  alreadyJoined ? AppColors.textSecondary : AppColors.onPrimary,
            ),
            onPressed: alreadyJoined
                ? null
                : () {
                    context.read<WaitlistBloc>().add(JoinWaitlist(
                          salonId: salonId,
                          salonName: salonName,
                          date: date,
                        ));
                    context.goNamed(AppRoute.home.name);
                  },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  alreadyJoined
                      ? Icons.check_rounded
                      : Icons.notifications_active_outlined,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(alreadyJoined ? tr('on_waitlist') : tr('join_waitlist')),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty slots placeholder
// ─────────────────────────────────────────────────────────────────────────────

class _EmptySlotsPlaceholder extends StatelessWidget {
  const _EmptySlotsPlaceholder({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Text(message,
            style: const TextStyle(
                fontSize: 14, color: AppColors.textSecondary)),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Time slot tile
// ─────────────────────────────────────────────────────────────────────────────

class _TimeSlotTile extends StatelessWidget {
  const _TimeSlotTile({
    required this.time,
    this.isSelected = false,
    this.isDisabled = false,
    this.isLimited = false,
  });

  final String time;
  final bool isSelected;
  final bool isDisabled;
  final bool isLimited;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: isDisabled ? AppColors.surface : AppColors.background,
        borderRadius: BorderRadius.circular(LoomeaTokens.radiusInput),
        border: Border.all(
          color: isSelected
              ? AppColors.primary
              : isDisabled
                  ? AppColors.surface
                  : AppColors.border,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            time,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isDisabled
                  ? AppColors.textSecondary.withValues(alpha: 0.5)
                  : AppColors.textPrimary,
            ),
          ),
          _SlotStatusLabel(
              isSelected: isSelected,
              isDisabled: isDisabled,
              isLimited: isLimited),
        ],
      ),
    );
  }
}

class _SlotStatusLabel extends StatelessWidget {
  const _SlotStatusLabel({
    required this.isSelected,
    required this.isDisabled,
    required this.isLimited,
  });

  final bool isSelected;
  final bool isDisabled;
  final bool isLimited;

  @override
  Widget build(BuildContext context) {
    if (isSelected) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(tr('slot_selected'),
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary)),
          const SizedBox(width: 6),
          const Icon(Icons.check_circle_rounded, size: 18, color: AppColors.primary),
        ],
      );
    }
    if (isDisabled) {
      return Text(tr('slot_booked'),
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary.withValues(alpha: 0.5)));
    }
    if (isLimited) {
      return Text(tr('slot_limited'),
          style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.error));
    }
    return Text(tr('slot_available'),
        style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary));
  }
}
