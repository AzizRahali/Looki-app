import 'package:equatable/equatable.dart';

/// A Stripe Checkout session created by the backend.
class PaymentCheckout extends Equatable {
  final String paymentRef;
  final String payUrl;

  /// What Stripe will charge, after the backend's currency conversion.
  final double amount;
  final String currency;

  const PaymentCheckout({
    required this.paymentRef,
    required this.payUrl,
    required this.amount,
    required this.currency,
  });

  factory PaymentCheckout.fromJson(Map<String, dynamic> json) {
    return PaymentCheckout(
      paymentRef: json['paymentRef'] as String? ?? '',
      payUrl: json['payUrl'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      currency: json['currency'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => [paymentRef, payUrl, amount, currency];
}

/// Current state of a payment, as polled from `/api/payments/status/{ref}`.
class PaymentStatusInfo extends Equatable {
  final String paymentRef;

  /// PENDING | COMPLETED | FAILED | CANCELLED | REFUNDED
  final String status;

  /// BOOKING | SUBSCRIPTION
  final String type;

  /// Appointment id for bookings, plan name for subscriptions.
  final String referenceId;
  final double amount;
  final String currency;

  const PaymentStatusInfo({
    required this.paymentRef,
    required this.status,
    required this.type,
    required this.referenceId,
    required this.amount,
    required this.currency,
  });

  factory PaymentStatusInfo.fromJson(Map<String, dynamic> json) {
    return PaymentStatusInfo(
      paymentRef: json['paymentRef'] as String? ?? '',
      status: json['status'] as String? ?? 'PENDING',
      type: json['type'] as String? ?? '',
      referenceId: json['referenceId'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      currency: json['currency'] as String? ?? '',
    );
  }

  bool get isPending => status == 'PENDING';
  bool get isCompleted => status == 'COMPLETED';
  bool get isCancelled => status == 'CANCELLED';

  /// Paid but couldn't be fulfilled (slot taken, booking expired) — refunded.
  bool get isRefunded => status == 'REFUNDED';
  bool get isFailed => status == 'FAILED';

  @override
  List<Object?> get props =>
      [paymentRef, status, type, referenceId, amount, currency];
}

/// One row of `/api/payments/history`.
class PaymentHistoryItem extends Equatable {
  final String paymentRef;

  /// BOOKING | SUBSCRIPTION
  final String type;

  /// COMPLETED | REFUNDED | FAILED
  final String status;
  final double amount;
  final String currency;
  final String description;
  final String referenceId;
  final String createdAt;

  const PaymentHistoryItem({
    required this.paymentRef,
    required this.type,
    required this.status,
    required this.amount,
    required this.currency,
    required this.description,
    required this.referenceId,
    required this.createdAt,
  });

  factory PaymentHistoryItem.fromJson(Map<String, dynamic> json) {
    return PaymentHistoryItem(
      paymentRef: json['paymentRef'] as String? ?? '',
      type: json['type'] as String? ?? '',
      status: json['status'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      currency: json['currency'] as String? ?? '',
      description: json['description'] as String? ?? '',
      referenceId: json['referenceId'] as String? ?? '',
      createdAt: json['createdAt'] as String? ?? '',
    );
  }

  bool get isSubscription => type == 'SUBSCRIPTION';
  bool get isRefunded => status == 'REFUNDED';
  bool get isFailed => status == 'FAILED';

  /// "15.00 USD" — the amount actually charged by Stripe.
  String get chargedText =>
      '${amount.toStringAsFixed(2)} ${currency.toUpperCase()}';

  @override
  List<Object?> get props => [
        paymentRef,
        type,
        status,
        amount,
        currency,
        description,
        referenceId,
        createdAt,
      ];
}
