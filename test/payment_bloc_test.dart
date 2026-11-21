import 'package:flutter_test/flutter_test.dart';
import 'package:loomea/data/models/payment_model.dart';
import 'package:loomea/data/repositories/loomea_repository.dart';
import 'package:loomea/logic/blocs/payment/payment_bloc.dart';
import 'package:loomea/logic/blocs/payment/payment_event.dart';
import 'package:loomea/logic/blocs/payment/payment_state.dart';

/// Scripted backend: each status poll returns the next queued status.
class _FakeRepository implements LoomeeaRepository {
  _FakeRepository({
    this.statuses = const ['PENDING'],
    this.cancelStatus = 'CANCELLED',
    this.startError,
  });

  final List<String> statuses;
  final String cancelStatus;
  final Exception? startError;
  int polls = 0;
  int cancels = 0;
  Map<String, Object?>? lastBooking;

  static const _checkout = PaymentCheckout(
    paymentRef: 'cs_test_1',
    payUrl: 'https://checkout.stripe.com/c/pay/cs_test_1',
    amount: 15,
    currency: 'usd',
  );

  PaymentStatusInfo _info(String status) => PaymentStatusInfo(
        paymentRef: 'cs_test_1',
        status: status,
        type: 'BOOKING',
        referenceId: 'appt-1',
        amount: 15,
        currency: 'usd',
      );

  @override
  Future<PaymentCheckout> startBookingPayment({
    required String salonId,
    required String date,
    required String startTime,
    required List<String> serviceIds,
    String? notes,
  }) async {
    if (startError != null) throw startError!;
    lastBooking = {
      'salonId': salonId,
      'date': date,
      'startTime': startTime,
      'serviceIds': serviceIds,
    };
    return _checkout;
  }

  @override
  Future<PaymentCheckout> startSubscriptionPayment(String plan) async =>
      _checkout;

  @override
  Future<PaymentStatusInfo> getPaymentStatus(String paymentRef) async {
    final status = statuses[polls.clamp(0, statuses.length - 1)];
    polls++;
    return _info(status);
  }

  @override
  Future<PaymentStatusInfo> cancelPayment(String paymentRef) async {
    cancels++;
    return _info(cancelStatus);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const _booking = BookingPaymentRequest(
  salonId: 'salon-1',
  date: '2026-11-24',
  startTime: '08:00',
  serviceIds: ['svc-1'],
);

Matcher _status(PaymentFlowStatus s) => isA<PaymentState>()
    .having((state) => state.status, 'status', s);

void main() {
  PaymentBloc build(_FakeRepository repo) => PaymentBloc(
        repository: repo,
        pollInterval: const Duration(milliseconds: 10),
      );

  test('creates the checkout, then polls until Stripe reports it paid',
      () async {
    final repo = _FakeRepository(statuses: ['PENDING', 'PENDING', 'COMPLETED']);
    final bloc = build(repo)..add(const StartPayment(_booking));

    await expectLater(
      bloc.stream,
      emitsThrough(_status(PaymentFlowStatus.succeeded)),
    );
    expect(repo.lastBooking!['startTime'], '08:00');
    expect(bloc.state.checkout!.paymentRef, 'cs_test_1');
    expect(repo.polls, 3);

    // Polling stops once the payment is final.
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(repo.polls, 3);
    await bloc.close();
  });

  test('success redirect verifies straight away', () async {
    final repo = _FakeRepository(statuses: ['COMPLETED']);
    final bloc = PaymentBloc(
      repository: repo,
      pollInterval: const Duration(hours: 1), // no background polls
    )..add(const StartPayment(_booking));

    await expectLater(
        bloc.stream, emitsThrough(_status(PaymentFlowStatus.awaitingCheckout)));
    bloc.add(const CheckoutClosed(CheckoutResult.success));
    await expectLater(
      bloc.stream,
      emitsInOrder([
        _status(PaymentFlowStatus.verifying),
        _status(PaymentFlowStatus.succeeded),
      ]),
    );
    await bloc.close();
  });

  test('closing checkout without paying cancels it', () async {
    final repo = _FakeRepository();
    final bloc = PaymentBloc(
      repository: repo,
      pollInterval: const Duration(hours: 1),
    )..add(const StartPayment(_booking));

    await expectLater(
        bloc.stream, emitsThrough(_status(PaymentFlowStatus.awaitingCheckout)));
    bloc.add(const CheckoutClosed(CheckoutResult.dismissed));
    await expectLater(
        bloc.stream, emitsThrough(_status(PaymentFlowStatus.cancelled)));
    expect(repo.cancels, 1);
    await bloc.close();
  });

  test('closing after paying keeps the payment (backend says COMPLETED)',
      () async {
    final repo = _FakeRepository(cancelStatus: 'COMPLETED');
    final bloc = PaymentBloc(
      repository: repo,
      pollInterval: const Duration(hours: 1),
    )..add(const StartPayment(_booking));

    await expectLater(
        bloc.stream, emitsThrough(_status(PaymentFlowStatus.awaitingCheckout)));
    bloc.add(const CheckoutClosed(CheckoutResult.cancel));
    await expectLater(
        bloc.stream, emitsThrough(_status(PaymentFlowStatus.succeeded)));
    await bloc.close();
  });

  test('a payment refunded because the slot was taken ends as refunded',
      () async {
    final repo = _FakeRepository(statuses: ['REFUNDED']);
    final bloc = build(repo)..add(const StartPayment(_booking));

    await expectLater(
        bloc.stream, emitsThrough(_status(PaymentFlowStatus.refunded)));
    await bloc.close();
  });

  test('a backend error while creating checkout fails with its message',
      () async {
    final repo = _FakeRepository(
        startError: Exception('You already have an appointment here'));
    final bloc = build(repo)..add(const StartPayment(_booking));

    await expectLater(
      bloc.stream,
      emitsThrough(isA<PaymentState>()
          .having((s) => s.status, 'status', PaymentFlowStatus.failed)
          .having((s) => s.error, 'error', contains('already have'))),
    );
    expect(repo.polls, 0);
    await bloc.close();
  });

  test('late status ticks after a final result are ignored', () async {
    final repo = _FakeRepository(statuses: ['COMPLETED']);
    final bloc = build(repo)..add(const StartPayment(_booking));

    await expectLater(
        bloc.stream, emitsThrough(_status(PaymentFlowStatus.succeeded)));
    bloc.add(const CheckoutClosed(CheckoutResult.dismissed));
    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect(repo.cancels, 0);
    expect(bloc.state.status, PaymentFlowStatus.succeeded);
    await bloc.close();
  });
}
