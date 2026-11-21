import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../data/models/payment_model.dart';
import '../../../data/repositories/loomea_repository.dart';
import '../../../data/services/localization_service.dart';
import '../../../logic/blocs/payment/payment_bloc.dart';
import '../../../logic/blocs/payment/payment_event.dart';
import '../../../logic/blocs/payment/payment_state.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/loomea_tokens.dart';
import '../../core/widgets/loomea_ui.dart';
import 'stripe_checkout_page.dart';

/// What [PaymentPage] pays for and how to describe it.
class PaymentArgs {
  final PaymentRequest request;
  final String title;
  final String subtitle;

  /// Price in the app's own currency, e.g. "15 TND".
  final String priceLabel;

  const PaymentArgs({
    required this.request,
    required this.title,
    required this.subtitle,
    required this.priceLabel,
  });

  bool get isSubscription => request is SubscriptionPaymentRequest;
}

/// Runs one Stripe Checkout payment. Pops with `true` once it succeeded.
class PaymentPage extends StatelessWidget {
  const PaymentPage({super.key, required this.args});

  final PaymentArgs args;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          PaymentBloc(repository: context.read<LoomeeaRepository>())
            ..add(StartPayment(args.request)),
      child: _PaymentView(args: args),
    );
  }
}

/// webview_flutter only runs on Android and iOS; web and desktop open
/// Checkout in the browser and rely on polling.
bool get _useInAppCheckout =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS);

String _chargedText(PaymentCheckout checkout) =>
    '${checkout.amount.toStringAsFixed(2)} ${checkout.currency.toUpperCase()}';

class _PaymentView extends StatefulWidget {
  const _PaymentView({required this.args});

  final PaymentArgs args;

  @override
  State<_PaymentView> createState() => _PaymentViewState();
}

class _PaymentViewState extends State<_PaymentView> {
  Future<void> _openCheckout(PaymentState state) async {
    final checkout = state.checkout;
    if (checkout == null) return;
    final bloc = context.read<PaymentBloc>();

    if (_useInAppCheckout) {
      final result = await Navigator.of(context).push<CheckoutResult>(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => StripeCheckoutPage(url: checkout.payUrl),
        ),
      );
      if (!mounted) return;
      bloc.add(CheckoutClosed(result ?? CheckoutResult.dismissed));
    } else {
      bool opened;
      try {
        opened = await launchUrl(
          Uri.parse(checkout.payUrl),
          mode: LaunchMode.externalApplication,
          webOnlyWindowName: '_blank',
        );
      } catch (_) {
        opened = false;
      }
      if (!opened && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('something_went_wrong'))),
        );
      }
    }
  }

  void _leave(PaymentState state) {
    final checkout = state.checkout;
    // Walking away from an unpaid checkout frees the booking's slot. If it was
    // paid after all, the backend keeps the payment instead.
    if (checkout != null && !state.isFinished) {
      unawaited(context
          .read<LoomeeaRepository>()
          .cancelPayment(checkout.paymentRef)
          .then((_) {}, onError: (_) {}));
    }
    Navigator.of(context).pop(state.status == PaymentFlowStatus.succeeded);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PaymentBloc, PaymentState>(
      listenWhen: (prev, curr) => prev.status != curr.status,
      listener: (context, state) {
        if (state.status == PaymentFlowStatus.awaitingCheckout) {
          _openCheckout(state);
        }
      },
      builder: (context, state) {
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) _leave(state);
          },
          child: Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              leading: LoomeaAppBarLeading(onPressed: () => _leave(state)),
            ),
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(LoomeaTokens.screenPaddingH,
                    8, LoomeaTokens.screenPaddingH, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      tr('payment_title'),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.025 * 30,
                        height: 1.1,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _SummaryCard(args: widget.args, checkout: state.checkout),
                    const SizedBox(height: 24),
                    Expanded(child: _body(context, state)),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _body(BuildContext context, PaymentState state) {
    final bloc = context.read<PaymentBloc>();
    switch (state.status) {
      case PaymentFlowStatus.initial:
      case PaymentFlowStatus.creating:
        return _Progress(message: tr('payment_preparing'));

      case PaymentFlowStatus.verifying:
        return _Progress(message: tr('payment_verifying'));

      case PaymentFlowStatus.awaitingCheckout:
        return _Outcome(
          icon: _useInAppCheckout
              ? Icons.lock_outline_rounded
              : Icons.open_in_new_rounded,
          color: AppColors.accent,
          title: _useInAppCheckout
              ? tr('pay_amount', args: [widget.args.priceLabel])
              : tr('payment_in_browser_title'),
          message: _useInAppCheckout
              ? tr('payment_secure_note')
              : tr('payment_in_browser_desc'),
          showSpinner: !_useInAppCheckout,
          primaryLabel: tr('payment_reopen'),
          onPrimary: () => _openCheckout(state),
          secondaryLabel: tr('payment_cancel'),
          onSecondary: () => bloc.add(const CancelPayment()),
        );

      case PaymentFlowStatus.succeeded:
        return _Outcome(
          icon: Icons.check_rounded,
          color: AppColors.success,
          title: tr('payment_success_title'),
          message: widget.args.isSubscription
              ? tr('payment_success_subscription')
              : tr('payment_success_booking'),
          primaryLabel: tr('continue_label'),
          onPrimary: () => _leave(state),
        );

      case PaymentFlowStatus.cancelled:
        return _Outcome(
          icon: Icons.close_rounded,
          color: AppColors.textSecondary,
          title: tr('payment_cancelled_title'),
          message: tr('payment_cancelled_desc'),
          primaryLabel: tr('retry'),
          onPrimary: () => bloc.add(StartPayment(widget.args.request)),
          secondaryLabel: tr('close'),
          onSecondary: () => _leave(state),
        );

      case PaymentFlowStatus.refunded:
        return _Outcome(
          icon: Icons.undo_rounded,
          color: AppColors.warning,
          title: tr('payment_refunded_title'),
          message: tr('payment_refunded_desc'),
          primaryLabel: tr('choose_another_time'),
          onPrimary: () => _leave(state),
        );

      case PaymentFlowStatus.failed:
        return _Outcome(
          icon: Icons.error_outline_rounded,
          color: AppColors.error,
          title: tr('payment_failed_title'),
          message: state.error.isNotEmpty
              ? state.error
              : tr('something_went_wrong'),
          primaryLabel: tr('retry'),
          onPrimary: () => bloc.add(StartPayment(widget.args.request)),
          secondaryLabel: tr('close'),
          onSecondary: () => _leave(state),
        );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Summary card
// ─────────────────────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.args, this.checkout});

  final PaymentArgs args;
  final PaymentCheckout? checkout;

  @override
  Widget build(BuildContext context) {
    return LoomeaSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      args.title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (args.subtitle.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        args.subtitle,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.4,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                args.priceLabel,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          if (checkout != null) ...[
            const SizedBox(height: 14),
            const Divider(height: 1, color: AppColors.divider),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.credit_card_rounded,
                    size: 16, color: AppColors.inkSoft),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    tr('payment_charged_as', args: [_chargedText(checkout!)]),
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.inkSoft),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// States
// ─────────────────────────────────────────────────────────────────────────────

class _Progress extends StatelessWidget {
  const _Progress({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(
          width: 36,
          height: 36,
          child: CircularProgressIndicator(strokeWidth: 3),
        ),
        const SizedBox(height: 20),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 15, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _Outcome extends StatelessWidget {
  const _Outcome({
    required this.icon,
    required this.color,
    required this.title,
    required this.message,
    required this.primaryLabel,
    required this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
    this.showSpinner = false,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String message;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;
  final bool showSpinner;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: 30, color: color),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (showSpinner) ...[
                    const SizedBox(height: 20),
                    const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        SizedBox(
          height: LoomeaTokens.buttonHeight,
          child: ElevatedButton(
            onPressed: onPrimary,
            child: Text(primaryLabel),
          ),
        ),
        if (secondaryLabel != null) ...[
          const SizedBox(height: 10),
          SizedBox(
            height: LoomeaTokens.buttonHeight,
            child: OutlinedButton(
              onPressed: onSecondary,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.border),
                shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(LoomeaTokens.radiusPill)),
              ),
              child: Text(
                secondaryLabel!,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
