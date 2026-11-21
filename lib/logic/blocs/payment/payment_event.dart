import 'package:equatable/equatable.dart';

/// What is being paid for.
sealed class PaymentRequest extends Equatable {
  const PaymentRequest();
}

class BookingPaymentRequest extends PaymentRequest {
  final String salonId;
  final String date; // yyyy-MM-dd
  final String startTime; // HH:mm
  final List<String> serviceIds;
  final String? notes;

  const BookingPaymentRequest({
    required this.salonId,
    required this.date,
    required this.startTime,
    required this.serviceIds,
    this.notes,
  });

  @override
  List<Object?> get props => [salonId, date, startTime, serviceIds, notes];
}

class SubscriptionPaymentRequest extends PaymentRequest {
  final String plan; // MONTHLY | YEARLY

  const SubscriptionPaymentRequest({required this.plan});

  @override
  List<Object?> get props => [plan];
}

/// How the Stripe Checkout page was left.
enum CheckoutResult { success, cancel, dismissed }

abstract class PaymentEvent extends Equatable {
  const PaymentEvent();

  @override
  List<Object?> get props => [];
}

/// Creates a Checkout session (and, for bookings, the pending appointment).
class StartPayment extends PaymentEvent {
  final PaymentRequest request;
  const StartPayment(this.request);

  @override
  List<Object?> get props => [request];
}

/// The in-app WebView closed, or the user came back from the browser.
class CheckoutClosed extends PaymentEvent {
  final CheckoutResult result;
  const CheckoutClosed(this.result);

  @override
  List<Object?> get props => [result];
}

/// The user gave up on an unpaid checkout.
class CancelPayment extends PaymentEvent {
  const CancelPayment();
}

/// Internal: periodic status check while the payment is open.
class PaymentPollTick extends PaymentEvent {
  const PaymentPollTick();
}
