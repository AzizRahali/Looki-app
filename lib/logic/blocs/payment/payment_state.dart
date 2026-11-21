import 'package:equatable/equatable.dart';

import '../../../data/models/payment_model.dart';
import 'payment_event.dart';

enum PaymentFlowStatus {
  initial,

  /// Creating the Stripe Checkout session.
  creating,

  /// Checkout is open (WebView or browser); status is being polled.
  awaitingCheckout,

  /// Checkout was left with a success redirect; waiting for Stripe to confirm.
  verifying,
  succeeded,
  cancelled,

  /// Paid, but the booking could no longer be honoured — refunded automatically.
  refunded,
  failed,
}

class PaymentState extends Equatable {
  final PaymentFlowStatus status;
  final PaymentRequest? request;
  final PaymentCheckout? checkout;
  final PaymentStatusInfo? info;
  final String error;

  const PaymentState({
    this.status = PaymentFlowStatus.initial,
    this.request,
    this.checkout,
    this.info,
    this.error = '',
  });

  bool get isBusy =>
      status == PaymentFlowStatus.creating ||
      status == PaymentFlowStatus.verifying;

  bool get isFinished =>
      status == PaymentFlowStatus.succeeded ||
      status == PaymentFlowStatus.cancelled ||
      status == PaymentFlowStatus.refunded ||
      status == PaymentFlowStatus.failed;

  PaymentState copyWith({
    PaymentFlowStatus? status,
    PaymentRequest? request,
    PaymentCheckout? checkout,
    PaymentStatusInfo? info,
    String? error,
  }) {
    return PaymentState(
      status: status ?? this.status,
      request: request ?? this.request,
      checkout: checkout ?? this.checkout,
      info: info ?? this.info,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [status, request, checkout, info, error];
}
