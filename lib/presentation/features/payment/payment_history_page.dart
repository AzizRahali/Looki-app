import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../data/models/payment_model.dart';
import '../../../data/repositories/loomea_repository.dart';
import '../../../data/services/localization_service.dart';
import '../../../logic/blocs/payment_history/payment_history_bloc.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/loomea_tokens.dart';
import '../../core/widgets/loomea_ui.dart';

/// Completed, refunded and failed card payments of the signed-in user.
/// Clients see booking payments; owners see subscription billing.
class PaymentHistoryPage extends StatelessWidget {
  const PaymentHistoryPage({super.key, this.billing = false});

  /// Owner wording ("Billing history") instead of the client one.
  final bool billing;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          PaymentHistoryBloc(repository: context.read<LoomeeaRepository>())
            ..add(const LoadPaymentHistory()),
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(leading: const LoomeaAppBarLeading()),
        body: SafeArea(
          child: BlocBuilder<PaymentHistoryBloc, PaymentHistoryState>(
            builder: (context, state) {
              return RefreshIndicator(
                onRefresh: () async => context
                    .read<PaymentHistoryBloc>()
                    .add(const LoadPaymentHistory()),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                      LoomeaTokens.screenPaddingH,
                      8,
                      LoomeaTokens.screenPaddingH,
                      32),
                  children: [
                    Text(
                      tr(billing ? 'billing_history' : 'payment_history'),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.025 * 30,
                        height: 1.1,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ..._content(context, state),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  List<Widget> _content(BuildContext context, PaymentHistoryState state) {
    switch (state.status) {
      case PaymentHistoryStatus.initial:
      case PaymentHistoryStatus.loading:
        if (state.items.isEmpty) {
          return const [
            SizedBox(height: 80),
            Center(child: CircularProgressIndicator()),
          ];
        }
        return _list(state.items);

      case PaymentHistoryStatus.error:
        return [
          const SizedBox(height: 60),
          const Icon(Icons.cloud_off_rounded,
              size: 40, color: AppColors.textSecondary),
          const SizedBox(height: 12),
          Text(
            tr('something_went_wrong'),
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: () => context
                  .read<PaymentHistoryBloc>()
                  .add(const LoadPaymentHistory()),
              child: Text(tr('retry')),
            ),
          ),
        ];

      case PaymentHistoryStatus.loaded:
        if (state.items.isEmpty) {
          return [
            const SizedBox(height: 60),
            const Icon(Icons.receipt_long_outlined,
                size: 44, color: AppColors.textMutedSoft),
            const SizedBox(height: 14),
            Text(
              tr('payment_history_empty'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              tr(billing
                  ? 'billing_history_empty_desc'
                  : 'payment_history_empty_desc'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 14, color: AppColors.textSecondary),
            ),
          ];
        }
        return _list(state.items);
    }
  }

  List<Widget> _list(List<PaymentHistoryItem> items) => [
        LoomeaSurfaceCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var i = 0; i < items.length; i++) ...[
                if (i > 0) const Divider(height: 1, indent: 68),
                _PaymentRow(item: items[i]),
              ],
            ],
          ),
        ),
      ];
}

class _PaymentRow extends StatelessWidget {
  const _PaymentRow({required this.item});

  final PaymentHistoryItem item;

  String get _dateLabel {
    final d = DateTime.tryParse(item.createdAt)?.toLocal();
    if (d == null) return '';
    return '${tr('month_abbr_${d.month}')} ${d.day}, ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final (statusLabel, statusColor) = item.isRefunded
        ? (tr('payment_status_refunded'), AppColors.warning)
        : item.isFailed
            ? (tr('payment_status_failed'), AppColors.error)
            : (tr('payment_status_completed'), AppColors.success);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.backgroundDeep,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              item.isSubscription
                  ? Icons.workspace_premium_outlined
                  : Icons.content_cut_rounded,
              size: 20,
              color: AppColors.inkSoft,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _dateLabel,
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                item.chargedText,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  decoration:
                      item.isRefunded ? TextDecoration.lineThrough : null,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(LoomeaTokens.radiusPill),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
