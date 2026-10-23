import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/owner_booking_model.dart';
import '../../core/utils/image_utils.dart';
import '../../../logic/blocs/owner_booking/owner_booking_bloc.dart';
import '../../../logic/blocs/owner_booking/owner_booking_event.dart';
import '../../../logic/blocs/owner_booking/owner_booking_state.dart';
import '../../../logic/blocs/owner_salon/owner_salon_bloc.dart';
import '../../../logic/blocs/owner_salon/owner_salon_state.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/loomea_tokens.dart';
import '../../../data/services/localization_service.dart';

class OwnerBookingsPage extends StatelessWidget {
  const OwnerBookingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<OwnerSalonBloc, OwnerSalonState>(
      listenWhen: (prev, curr) =>
          prev.salon?.id != curr.salon?.id && curr.salon != null,
      listener: (context, state) {
        context
            .read<OwnerBookingBloc>()
            .add(LoadOwnerBookings(state.salon!.id));
      },
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  LoomeaTokens.screenPaddingH, 24,
                  LoomeaTokens.screenPaddingH, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tr('bookings'),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.025 * 30,
                        height: 1.1,
                        color: AppColors.textPrimary,
                      )),
                ],
              ),
            ),
            const SizedBox(height: 20),
            BlocBuilder<OwnerBookingBloc, OwnerBookingState>(
              buildWhen: (prev, curr) => prev.filter != curr.filter,
              builder: (context, state) {
                return Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: LoomeaTokens.screenPaddingH),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        _Tab(
                            label: tr('upcoming'),
                            selected: state.filter == 'upcoming',
                            onTap: () => _load(context, 'upcoming')),
                        _Tab(
                            label: tr('past'),
                            selected: state.filter == 'past',
                            onTap: () => _load(context, 'past')),
                        _Tab(
                            label: tr('all'),
                            selected: state.filter == 'all',
                            onTap: () => _load(context, 'all')),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            Expanded(
              child: BlocBuilder<OwnerBookingBloc, OwnerBookingState>(
                builder: (context, state) {
                  if (state.status == OwnerBookingStatus.loading ||
                      state.status == OwnerBookingStatus.initial) {
                    return const Center(
                        child: CircularProgressIndicator(
                            color: AppColors.primary));
                  }
                  if (state.bookings.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.event_busy_rounded,
                                color: AppColors.textSecondary, size: 24),
                          ),
                          const SizedBox(height: 14),
                          Text(tr('no_bookings_found'),
                              style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textSecondary)),
                        ],
                      ),
                    );
                  }
                  return RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: () async => _load(context, state.filter),
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(
                          LoomeaTokens.screenPaddingH, 0,
                          LoomeaTokens.screenPaddingH, 32),
                      itemCount: state.bookings.length,
                      itemBuilder: (_, i) =>
                          _BookingCard(booking: state.bookings[i]),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _load(BuildContext context, String filter) {
    final salon = context.read<OwnerSalonBloc>().state.salon;
    if (salon != null) {
      context
          .read<OwnerBookingBloc>()
          .add(LoadOwnerBookings(salon.id, filter: filter));
    }
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _Tab(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color:
                    selected ? AppColors.onPrimary : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final OwnerBooking booking;
  const _BookingCard({required this.booking});

  (String, Color, Color) get _statusStyle {
    if (booking.isPending)   return (tr('status_pending'),   AppColors.warning,            AppColors.warningBg);
    if (booking.isConfirmed) return (tr('status_confirmed'),  const Color(0xFF1D6BB8),      const Color(0xFFEBF3FD));
    if (booking.isCompleted) return (tr('status_completed'),  AppColors.success,            AppColors.successBg);
    if (booking.isCancelled) return (tr('status_cancelled'),  AppColors.error,              AppColors.errorBg);
    return (booking.status,  AppColors.warning,   AppColors.warningBg);
  }

  @override
  Widget build(BuildContext context) {
    final (label, color, bgColor) = _statusStyle;
    final clientInitial = booking.clientName.isNotEmpty
        ? booking.clientName[0].toUpperCase()
        : '?';
    final avatarUrl = booking.clientAvatarUrl.isNotEmpty
        ? resolveImageUrl(booking.clientAvatarUrl)
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(LoomeaTokens.radiusCard),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status accent bar
          Container(height: 3, color: color),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row: circular avatar + name + status badge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Circular avatar
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color.withValues(alpha: 0.12),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: avatarUrl != null
                          ? Image.network(
                              avatarUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Center(
                                child: Text(clientInitial,
                                    style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 22,
                                        color: color)),
                              ),
                            )
                          : Center(
                              child: Text(clientInitial,
                                  style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 22,
                                      color: color)),
                            ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            booking.clientName.isNotEmpty ? booking.clientName : 'Client',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 17,
                              color: AppColors.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            booking.servicesText,
                            style: const TextStyle(
                                fontSize: 13, color: AppColors.textSecondary),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Status badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        label.toUpperCase(),
                        style: TextStyle(
                          color: color,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1, color: AppColors.border),
                const SizedBox(height: 14),

                // Date + time chips
                Row(
                  children: [
                    _InfoChip(
                      icon: Icons.calendar_today_rounded,
                      text: booking.date,
                    ),
                    const SizedBox(width: 8),
                    _InfoChip(
                      icon: Icons.schedule_rounded,
                      text: booking.timeRange,
                    ),
                  ],
                ),
                if (booking.salonAddress.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          booking.salonAddress,
                          style: const TextStyle(
                              fontSize: 13, color: AppColors.textSecondary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
                if (booking.clientPhone.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.phone_outlined,
                          size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 6),
                      Text(booking.clientPhone,
                          style: const TextStyle(
                              fontSize: 13, color: AppColors.textSecondary)),
                    ],
                  ),
                ],
                const SizedBox(height: 14),

                // Price + payment + reliability
                Row(
                  children: [
                    Text(
                      booking.priceText,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _MetaChip(
                      icon: booking.paymentMethod == 'PAY_WITH_CARD'
                          ? Icons.credit_card_rounded
                          : Icons.payments_outlined,
                      text: booking.paymentMethod == 'PAY_WITH_CARD'
                          ? 'Card'
                          : 'On-site',
                    ),
                    const Spacer(),
                    _ReliabilityBadge(
                      score: booking.reliabilityScore,
                      tier: booking.reliabilityTier,
                    ),
                  ],
                ),
                if (booking.notes.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.inputBackground,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.sticky_note_2_outlined,
                            size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(booking.notes,
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                  fontStyle: FontStyle.italic)),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Action buttons
          if (booking.isPending || booking.isConfirmed)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _showRejectSheet(context, booking.id),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                        minimumSize: const Size(0, 46),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(
                        booking.isConfirmed ? tr('cancel') : tr('reject_booking'),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () => context.read<OwnerBookingBloc>().add(
                            booking.isConfirmed
                                ? CompleteBooking(booking.id)
                                : ConfirmBooking(booking.id),
                          ),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(0, 46),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            booking.isConfirmed
                                ? Icons.check_circle_rounded
                                : Icons.check_rounded,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            booking.isConfirmed ? tr('complete_booking') : tr('confirm_booking'),
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

void _showRejectSheet(BuildContext context, String bookingId) {
  final reasons = [
    ('DOUBLE_BOOKING',     tr('double_booking')),
    ('NO_AVAILABILITY',    tr('no_availability')),
    ('SERVICE_UNAVAILABLE',tr('service_unavailable')),
    ('CLIENT_RELIABILITY', tr('client_reliability')),
    ('OTHER',              tr('other')),
  ];

  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(tr('reason_for_rejection'),
                style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 4),
            const Text('This affects the client\'s reliability score.',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            ...reasons.map(((String, String) r) => ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(r.$2,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary)),
              trailing: const Icon(Icons.chevron_right_rounded,
                  color: AppColors.textSecondary, size: 20),
              onTap: () {
                Navigator.of(ctx).pop();
                context.read<OwnerBookingBloc>()
                    .add(RejectBooking(bookingId, reason: r.$1));
              },
            )),
          ],
        ),
      ),
    ),
  );
}

class _ReliabilityBadge extends StatelessWidget {
  final int score;
  final String tier;
  const _ReliabilityBadge({required this.score, required this.tier});

  @override
  Widget build(BuildContext context) {
    final (color, bg, icon) = switch (tier) {
      'TRUSTED'    => (AppColors.success,  AppColors.successBg, Icons.verified_rounded),
      'NORMAL'     => (AppColors.accent,   AppColors.accent.withValues(alpha: 0.12), Icons.check_circle_outline_rounded),
      'RISKY'      => (AppColors.warning,  AppColors.warningBg, Icons.warning_amber_rounded),
      'RESTRICTED' => (AppColors.error,    AppColors.errorBg,   Icons.block_rounded),
      _            => (AppColors.textSecondary, AppColors.surface, Icons.help_outline_rounded),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 3),
          Text('$score',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color)),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.inputBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String text;
  const _MetaChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.inputBackground,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.textSecondary),
          const SizedBox(width: 5),
          Text(text,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
