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
import '../../core/routes/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/loomea_tokens.dart';
import '../../core/utils/icon_mapper.dart';
import '../../core/widgets/loomea_ui.dart';
import '../../../data/services/localization_service.dart';

class BookingReviewPage extends StatefulWidget {
  const BookingReviewPage({super.key});

  @override
  State<BookingReviewPage> createState() => _BookingReviewPageState();
}

class _BookingReviewPageState extends State<BookingReviewPage> {
  final TextEditingController _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  String _formatShortDate(int year, int month, int day) {
    final dt = DateTime(year, month, day);
    return '${tr('day_abbr_${dt.weekday}')}, ${tr('month_abbr_$month')} $day';
  }

  String _to24h(String timeStr) {
    final parts = timeStr.trim().split(' ');
    if (parts.length < 2) return timeStr;
    final hm = parts[0].split(':');
    var h = int.tryParse(hm[0]) ?? 0;
    final m = int.tryParse(hm.length > 1 ? hm[1] : '0') ?? 0;
    final isPm = parts[1].toUpperCase() == 'PM';
    if (isPm && h != 12) h += 12;
    if (!isPm && h == 12) h = 0;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
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
            final salon = salonState.selectedSalon;
            final selectedServices = salon?.services
                    .where((s) => salonState.selectedServiceIds.contains(s.id))
                    .toList() ??
                [];

            return BlocBuilder<BookingBloc, BookingState>(
              builder: (context, bookingState) {
                final selectedTime = bookingState.selectedTime.isNotEmpty
                    ? bookingState.selectedTime
                    : '10:00 AM';
                final selectedDay = bookingState.selectedDay;
                final dateLabel = selectedDay > 0
                    ? _formatShortDate(bookingState.selectedYear,
                        bookingState.selectedMonth, selectedDay)
                    : tr('select_date');

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
                            Text(
                              tr('step_of', args: ['2', '2']),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              tr('almost_there'),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 30,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.025 * 30,
                                height: 1.1,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 20),
                            _SalonSummaryCard(
                              salonName: salon?.name ?? 'Luna Hair Studio',
                              salonImageUrl: salon?.imageUrl ?? '',
                              dateLabel: dateLabel,
                              selectedTime: selectedTime,
                              totalPrice: salonState.selectedServicesTotal,
                            ),
                            const SizedBox(height: 24),
                            ...selectedServices.map((s) =>
                                _ServiceBreakdownRow(service: s)),
                            const SizedBox(height: 8),
                            const Divider(color: AppColors.border),
                            const SizedBox(height: 28),
                            _NotesSection(controller: _notesController),
                            const SizedBox(height: 20),
                            const _CancellationPolicy(),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                    _BookingActionBar(
                      onBack: () => context.pop(),
                      onConfirm: () {
                        HapticFeedback.mediumImpact();
                        final note = _notesController.text.trim();
                        final month = bookingState.selectedMonth > 0
                            ? bookingState.selectedMonth
                            : DateTime.now().month;
                        final year = bookingState.selectedYear > 0
                            ? bookingState.selectedYear
                            : DateTime.now().year;
                        final day = bookingState.selectedDay > 0
                            ? bookingState.selectedDay
                            : DateTime.now().day;
                        final dateStr =
                            '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';

                        context.read<BookingBloc>().add(
                              ConfirmBooking(
                                salonId: salon?.id ?? '',
                                date: dateStr,
                                startTime: _to24h(bookingState.selectedTime),
                                serviceIds: salonState.selectedServiceIds,
                                paymentMethod: 'PAY_AT_SALON',
                                notes: note.isEmpty ? null : note,
                              ),
                            );
                        context.pushNamed(AppRoute.bookingConfirmation.name);
                      },
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
// Salon summary card
// ─────────────────────────────────────────────────────────────────────────────

class _SalonSummaryCard extends StatelessWidget {
  const _SalonSummaryCard({
    required this.salonName,
    required this.salonImageUrl,
    required this.dateLabel,
    required this.selectedTime,
    required this.totalPrice,
  });

  final String salonName;
  final String salonImageUrl;
  final String dateLabel;
  final String selectedTime;
  final double totalPrice;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(LoomeaTokens.radiusCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SalonImageBar(imageUrl: salonImageUrl),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        salonName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined,
                              size: 14, color: AppColors.textSecondary),
                          const SizedBox(width: 6),
                          Text(
                            '$dateLabel @ $selectedTime',
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                _PriceBadge(price: totalPrice),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SalonImageBar extends StatelessWidget {
  const _SalonImageBar({required this.imageUrl});
  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(LoomeaTokens.radiusCard),
        topRight: Radius.circular(LoomeaTokens.radiusCard),
      ),
      child: imageUrl.isNotEmpty
          ? Image.network(
              imageUrl,
              height: 160,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _placeholder(),
            )
          : _placeholder(),
    );
  }

  Widget _placeholder() => Container(
        height: 160,
        color: AppColors.inputBackground,
        child: const Center(
          child: Icon(Icons.image_rounded, size: 48, color: AppColors.textSecondary),
        ),
      );
}

class _PriceBadge extends StatelessWidget {
  const _PriceBadge({required this.price});

  final double price;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(LoomeaTokens.radiusPill),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        formatPrice(price),
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Service breakdown row
// ─────────────────────────────────────────────────────────────────────────────

class _ServiceBreakdownRow extends StatelessWidget {
  const _ServiceBreakdownRow({required this.service});

  final dynamic service;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(IconMapper.fromString(service.icon),
              size: 20, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(service.name,
                style: const TextStyle(
                    fontSize: 15, color: AppColors.textPrimary)),
          ),
          Text(service.priceText,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}


// ─────────────────────────────────────────────────────────────────────────────
// Notes section
// ─────────────────────────────────────────────────────────────────────────────

class _NotesSection extends StatelessWidget {
  const _NotesSection({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tr('notes'),
          style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(LoomeaTokens.radiusInput),
          ),
          child: TextField(
            controller: controller,
            minLines: 3,
            maxLines: 4,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: tr('special_requests_hint'),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Cancellation policy
// ─────────────────────────────────────────────────────────────────────────────

class _CancellationPolicy extends StatelessWidget {
  const _CancellationPolicy();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(LoomeaTokens.radiusInput),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded,
              size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              tr('cancellation_policy'),
              style: const TextStyle(
                  fontSize: 13, height: 1.5, color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom action bar
// ─────────────────────────────────────────────────────────────────────────────

class _BookingActionBar extends StatelessWidget {
  const _BookingActionBar({required this.onBack, required this.onConfirm});

  final VoidCallback onBack;
  final VoidCallback onConfirm;

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
      child: Row(
        children: [
          SizedBox(
            height: LoomeaTokens.buttonHeight,
            width: 120,
            child: OutlinedButton(
              onPressed: onBack,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                side: const BorderSide(color: AppColors.border),
                shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(LoomeaTokens.radiusPill)),
              ),
              child: Text(
                tr('back'),
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SizedBox(
              height: LoomeaTokens.buttonHeight,
              child: ElevatedButton(
                onPressed: onConfirm,
                child: Text(tr('confirm')),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


