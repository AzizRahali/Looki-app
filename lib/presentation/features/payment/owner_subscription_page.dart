import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../data/models/subscription_model.dart';
import '../../../data/repositories/loomea_repository.dart';
import '../../../data/services/localization_service.dart';
import '../../../logic/blocs/payment/payment_event.dart';
import '../../../logic/blocs/subscription/subscription_bloc.dart';
import '../../../logic/blocs/subscription/subscription_event.dart';
import '../../../logic/blocs/subscription/subscription_state.dart';
import '../../core/routes/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/loomea_tokens.dart';
import '../../core/widgets/loomea_ui.dart';
import 'payment_page.dart';

/// Owner's looki plan: current subscription, plan picker and Stripe checkout.
class OwnerSubscriptionPage extends StatelessWidget {
  const OwnerSubscriptionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          SubscriptionBloc(repository: context.read<LoomeeaRepository>())
            ..add(const LoadSubscription()),
      child: const _SubscriptionView(),
    );
  }
}

/// Plan prices have cents (29.99), which [formatPrice] would round away.
String _planPrice(double price) => tr('price_amount', args: [
      price == price.roundToDouble()
          ? price.toStringAsFixed(0)
          : price.toStringAsFixed(2),
    ]);

String _planName(SubscriptionPlanModel plan) =>
    plan.isYearly ? tr('plan_yearly') : tr('plan_monthly');

class _SubscriptionView extends StatefulWidget {
  const _SubscriptionView();

  @override
  State<_SubscriptionView> createState() => _SubscriptionViewState();
}

class _SubscriptionViewState extends State<_SubscriptionView> {
  String? _selectedPlan;

  Future<void> _pay(SubscriptionPlanModel plan) async {
    final bloc = context.read<SubscriptionBloc>();
    final paid = await context.pushNamed<bool>(
      AppRoute.payment.name,
      extra: PaymentArgs(
        request: SubscriptionPaymentRequest(plan: plan.plan),
        title: '${tr('subscription')} · ${_planName(plan)}',
        subtitle: tr('subscription_title'),
        priceLabel: _planPrice(plan.price),
      ),
    );
    if (paid == true && mounted) bloc.add(const LoadSubscription());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(leading: const LoomeaAppBarLeading()),
      body: SafeArea(
        child: BlocBuilder<SubscriptionBloc, SubscriptionState>(
          builder: (context, state) {
            if (state.status == SubscriptionLoadStatus.error &&
                state.plans.isEmpty) {
              return _ErrorView(
                onRetry: () => context
                    .read<SubscriptionBloc>()
                    .add(const LoadSubscription()),
              );
            }
            if (state.plans.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            final selected = state.plans.firstWhere(
              (p) => p.plan == _selectedPlan,
              orElse: () => state.plans.firstWhere(
                (p) => p.plan == state.subscription?.plan,
                orElse: () => state.plans.first,
              ),
            );
            final monthly =
                state.plans.where((p) => !p.isYearly).firstOrNull;

            return Column(
              children: [
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async => context
                        .read<SubscriptionBloc>()
                        .add(const LoadSubscription()),
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(
                          LoomeaTokens.screenPaddingH,
                          8,
                          LoomeaTokens.screenPaddingH,
                          24),
                      children: [
                        Text(
                          tr('subscription_title'),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 30,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.025 * 30,
                            height: 1.1,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          tr('subscription_subtitle'),
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _CurrentPlanCard(subscription: state.subscription),
                        const SizedBox(height: 28),
                        Text(
                          tr('choose_plan'),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        for (final plan in state.plans) ...[
                          _PlanOption(
                            plan: plan,
                            monthly: monthly,
                            selected: plan.plan == selected.plan,
                            onTap: () =>
                                setState(() => _selectedPlan = plan.plan),
                          ),
                          const SizedBox(height: 10),
                        ],
                        if (state.hasActiveSubscription) ...[
                          const SizedBox(height: 4),
                          Text(
                            tr('subscription_extend_note'),
                            style: const TextStyle(
                              fontSize: 13,
                              height: 1.4,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),
                        Center(
                          child: TextButton.icon(
                            onPressed: () => context.pushNamed(
                              AppRoute.paymentHistory.name,
                              extra: true,
                            ),
                            icon: const Icon(Icons.receipt_long_outlined,
                                size: 18),
                            label: Text(tr('billing_history')),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(
                      LoomeaTokens.screenPaddingH,
                      12,
                      LoomeaTokens.screenPaddingH,
                      16),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    border: Border(
                        top: BorderSide(
                            color: AppColors.border.withValues(alpha: 0.5))),
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: LoomeaTokens.buttonHeight,
                    child: ElevatedButton(
                      onPressed: () => _pay(selected),
                      child: Text(
                        '${tr(state.hasActiveSubscription ? 'extend_cta' : 'subscribe_cta')}'
                        ' · ${_planPrice(selected.price)}',
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Current plan
// ─────────────────────────────────────────────────────────────────────────────

class _CurrentPlanCard extends StatelessWidget {
  const _CurrentPlanCard({required this.subscription});

  final SubscriptionModel? subscription;

  @override
  Widget build(BuildContext context) {
    final sub = subscription;
    final active = sub?.isActive == true;
    final end = sub?.endDateTime;

    final (statusLabel, statusColor) = active
        ? (tr('subscription_active'), AppColors.success)
        : sub != null
            ? (tr('subscription_expired'), AppColors.warning)
            : (tr('subscription_none'), AppColors.textSecondary);

    return LoomeaSurfaceCard(
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.backgroundDeep,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.workspace_premium_outlined,
                color: AppColors.inkSoft),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sub == null
                      ? tr('subscription')
                      : (sub.plan == 'YEARLY'
                          ? tr('plan_yearly')
                          : tr('plan_monthly')),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (active && end != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    '${tr('subscription_valid_until', args: [
                          '${tr('month_abbr_${end.month}')} ${end.day}, ${end.year}'
                        ])} · ${tr('subscription_days_left', args: [
                          '${sub!.daysRemaining}'
                        ])}',
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textSecondary),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(LoomeaTokens.radiusPill),
            ),
            child: Text(
              statusLabel,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Plan option
// ─────────────────────────────────────────────────────────────────────────────

class _PlanOption extends StatelessWidget {
  const _PlanOption({
    required this.plan,
    required this.monthly,
    required this.selected,
    required this.onTap,
  });

  final SubscriptionPlanModel plan;
  final SubscriptionPlanModel? monthly;
  final bool selected;
  final VoidCallback onTap;

  /// Yearly saving compared with paying monthly for a year.
  int? get _savingPercent {
    final m = monthly;
    if (!plan.isYearly || m == null || m.price <= 0) return null;
    final yearOfMonthly = m.price * 365 / m.durationDays;
    final saving = (1 - plan.price / yearOfMonthly) * 100;
    return saving >= 1 ? saving.round() : null;
  }

  @override
  Widget build(BuildContext context) {
    final saving = _savingPercent;
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(LoomeaTokens.radiusCard),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(LoomeaTokens.radiusCard),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(LoomeaTokens.radiusCard),
            border: Border.all(
              color: selected ? AppColors.accent : AppColors.border,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                color: selected ? AppColors.accent : AppColors.textMutedSoft,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Row(
                  children: [
                    Text(
                      _planName(plan),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (saving != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.successBg,
                          borderRadius:
                              BorderRadius.circular(LoomeaTokens.radiusPill),
                        ),
                        child: Text(
                          tr('plan_save', args: ['$saving']),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.successDark,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: _planPrice(plan.price),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    TextSpan(
                      text: ' ${tr(plan.isYearly ? 'per_year' : 'per_month')}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: LoomeaTokens.screenPaddingH),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded,
                size: 40, color: AppColors.textSecondary),
            const SizedBox(height: 12),
            Text(
              tr('something_went_wrong'),
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            TextButton(onPressed: onRetry, child: Text(tr('retry'))),
          ],
        ),
      ),
    );
  }
}
